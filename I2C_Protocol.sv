`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/12 19:48:36
// Design Name: 
// Module Name: I2C_Protocol
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


module I2C_Protocol(
    // Global Signals
    input  logic       clk,
    input  logic       reset,
    // AXI Control Signals
    input  logic [7:0] write_length,
    input  logic [7:0] read_length,
    input  logic       ENABLE,
    // I2C Signals
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic       tx_ready,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       ack_err,
    output logic       busy,
    // FND Slave Output
    output logic [7:0] fnd_data,
    output logic [3:0] fnd_com,
    // I2C Signals
    output logic SCL,
    inout  logic SDA
    );

    wire SCL_w, SDA_w;

    assign SCL = SCL_w;
    assign SDA = SDA_w;

    I2C_Master U_I2C_MASTER(
        .clk(clk),
        .reset(reset),
        .write_length(write_length),
        .read_length(read_length),
        .ENABLE(ENABLE),
        .SCL(SCL_w),
        .SDA(SDA_w),
        .tx_data(tx_data),
        .tx_done(tx_done),
        .tx_ready(tx_ready),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .ack_err(ack_err),
        .busy(busy)
    );

    I2C_Slave U_I2C_SLAVE(
        .clk(clk),
        .reset(reset),
        .SCL(SCL_w),
        .SDA(SDA_w),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com)
    );
endmodule
