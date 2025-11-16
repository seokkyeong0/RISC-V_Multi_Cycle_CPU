`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/14 01:28:02
// Design Name: 
// Module Name: MEM
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


module MEM(
    input  logic       clk,
    input  logic       w_en,
    input  logic       r_en,
    input  logic       l_en,
    input  logic [7:0] addr,
    input  logic [7:0] w_data,
    output logic [7:0] r_data
);

    logic [7:0] mem [0:255];
    logic [7:0] addr_reg;

    logic [7:0] page_base;
    logic [2:0] page_offset;

    assign page_base   = addr_reg & 8'hF8;
    assign page_offset = addr_reg[2:0];

    always_ff @(posedge clk) begin
        if (l_en) begin
            addr_reg <= addr;
        end else if (w_en) begin
            if (page_offset == 3'd7)
                addr_reg <= page_base;
            else
                addr_reg <= addr_reg + 1;
        end else if (r_en) begin
            addr_reg <= addr_reg + 1;
        end
    end

    assign r_data = mem[addr_reg];

    always_ff @(posedge clk) begin
        if (w_en) begin
            mem[addr_reg] <= w_data;
        end
    end
endmodule
