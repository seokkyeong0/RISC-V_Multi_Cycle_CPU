`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/25 11:30:21
// Design Name: 
// Module Name: TIMER
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

module TIMER_Periph(
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,

    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,

    // External Ports
    output logic        irq
);

    // Internal Signals
    logic enable;
    logic direction;

    logic [31:0] period;
    logic [31:0] cnt_data;

    APB_SlaveIntf_TIMER u_APB_Slave (.*);
    TIMER u_TIMER (.*);
endmodule

module TIMER(
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic        enable,
    input  logic        direction,
    input  logic [31:0] period,
    output logic [31:0] cnt_data,
    output logic        irq
);
    logic [31:0] cnt_reg;
    logic irq_reg;

    assign cnt_data   = cnt_reg;
    assign irq        = irq_reg;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            cnt_reg   <= 32'd0;
            irq_reg   <= 1'b0;
        end else if (enable) begin
            irq_reg <= 1'b0;

            if (direction == 1'b0) begin
                cnt_reg <= cnt_reg + 1;
            end else begin
                cnt_reg <= cnt_reg - 1;
            end

            if (direction == 1'b0 && cnt_reg > (period - 1) / 2) begin
                irq_reg <= 1'b1;
                if (cnt_reg > period - 1) begin
                    cnt_reg <= 0;
                    irq_reg <= 1'b0;
                end
            end
            else if (direction == 1'b1 && cnt_reg == 0) begin
                cnt_reg <= period - 1;
                irq_reg <= 1'b1;
            end
        end
    end
endmodule

module APB_SlaveIntf_TIMER (
    // Global Signals
    input  logic        PCLK,
    input  logic        PRESET,

    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,

    // External Ports
    input  logic        irq,
    input  logic [31:0] cnt_data,
    output logic        enable,
    output logic        direction,
    output logic [31:0] period
);

    logic [31:0] slv_reg0; // Control Signals (Timer Enable, Up/Down)
    logic [31:0] slv_reg1; // IRQ Signal
    logic [31:0] slv_reg2; // Timer Period
    logic [31:0] slv_reg3; // Current Value

    assign enable    = slv_reg0[0];  // TIMER Enable
    assign direction = slv_reg0[1];  // Up/Down Direction
    assign period    = slv_reg2;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 32'd0;
            slv_reg1 <= 32'd0;
            slv_reg2 <= 32'd0;
            slv_reg3 <= 32'd0;
            PRDATA   <= 32'd0;
            PREADY   <= 1'b0;
        end else begin
            PREADY <= 1'b0;

            // Signal Latching
            if(irq) slv_reg1[0] <= 1'b1;

            // Return Signal
            if(PREADY) begin
                if(!irq & slv_reg1[0]) slv_reg1[0] <= 1'b0;
            end

            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd2: slv_reg2 <= PWDATA;
                        2'd3: slv_reg3 <= cnt_data;
                    endcase
                end else begin
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end
        end
    end
endmodule