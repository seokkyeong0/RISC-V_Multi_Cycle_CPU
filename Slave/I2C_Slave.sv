`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/12 19:42:45
// Design Name: 
// Module Name: I2C_Slave
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module I2C_Slave(
    // Global Signals
    input logic clk,
    input logic reset,
    // I2C Signals
    input logic SCL,
    inout logic SDA,
    // External Signals
    output logic [15:0] led,
    output logic [7:0] fnd_data,
    output logic [3:0] fnd_com
    );

    logic [15:0] slv_data;
    logic write, read, load;
    logic [7:0] addr, mem_wdata, mem_rdata;

    // I2C LED Slave Device
    // write : 0
    // read  : 2
    // addr  : 7'b1100100
    I2C_Slave_LED #(.read_length(2), .address(7'b1100100)) U_I2C_SLAVE_LED(
        .clk(clk),
        .reset(reset),
        .SCL(SCL),
        .SDA(SDA),
        .led_data(led),
        .rx_done()
    );
 
    // I2C FND Slave Device
    // write : 0
    // read  : 2
    // addr  : 7'b1100101
    I2C_Slave_FND #(.read_length(2), .address(7'b1100101)) U_I2C_SLAVE_FND(
        .clk(clk),
        .reset(reset),
        .SCL(SCL),
        .SDA(SDA),
        .fnd_data(slv_data),
        .rx_done()
    );

    FND U_FND(
        .clk(clk),
        .reset(reset),
        .data(slv_data),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com)
    );

    // I2C Memory Slave Device
    // addr  : 7'b1100110
    I2C_Slave_MEM #(.address(7'b1100110)) U_I2C_SLAVE_MEM(
        .clk(clk),
        .reset(reset),
        .SCL(SCL),
        .SDA(SDA),
        .tx_data(mem_rdata),
        .tx_done(read),
        .rx_data(mem_wdata),
        .rx_done(write),
        .mm_addr(addr),
        .ld(load)
    );

    MEM U_MEM(
        .clk(clk),
        .w_en(write),
        .r_en(read),
        .l_en(load),
        .addr(addr),
        .w_data(mem_wdata),
        .r_data(mem_rdata)
    );

endmodule
