`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/11 14:56:47
// Design Name: 
// Module Name: tb_I2C_Master
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


module tb_I2C_Master();

    // Global Signals
    logic       clk;
    logic       reset;  
    logic [7:0] write_length;
    logic [7:0] read_length;

    // I2C Signals
    logic       ENABLE;
    logic       SCL;
    tri         SDA;

    // Internal Signals
    logic [7:0] tx_data;
    logic       tx_done;
    logic       tx_ready;
    logic [7:0] rx_data;
    logic       rx_done;
    logic       ack_err;
    logic       busy;

    // FND Signals
    logic [7:0] fnd_data;
    logic [3:0] fnd_com;

    I2C_Protocol DUT(
        .*
    );

    always #5 clk = ~clk;

    task i2c_start(byte data);
        tx_data = data;
        ENABLE  = 1'b1;
        @(posedge clk);
        ENABLE  = 1'b0;
        wait(tx_done);
    endtask

    task i2c_restart(byte data);
        tx_data = data;
        repeat(1000) @(posedge clk);
        wait(tx_done);
    endtask

    task i2c_write(byte data);
        tx_data = data;
        repeat(1000) @(posedge clk);
        wait(tx_done);
    endtask

    task i2c_read();
        repeat (1000) @(posedge clk);
        wait(rx_done);
    endtask

    initial begin
        #00 clk = 0; reset = 1; write_length = 9; read_length = 0;
        #10 reset = 0;

        // IDLE -> START
        #1000;
        //i2c_start(8'b1100110_0);
        //i2c_write(8'b00000100);   // Addr 1

        // MEM Burst Simulation
        //i2c_write(8'b00000001);   // Data 1
        //i2c_write(8'b00000010);   // Data 2
        //i2c_write(8'b00000100);   // Data 3
        //i2c_write(8'b00001000);   // Data 4
        //i2c_write(8'b00010000);   // Data 5
        //i2c_write(8'b00100000);   // Data 6
        //i2c_write(8'b01000000);   // Data 7
        //i2c_write(8'b10000000);   // Data 8

        #100;
        write_length = 0; read_length = 1;
        i2c_start(8'b1100110_1);
    end
endmodule
