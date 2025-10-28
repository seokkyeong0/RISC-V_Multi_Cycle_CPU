`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/24 16:02:15
// Design Name: 
// Module Name: UART
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


module UART_Periph (
    // Global signals
    input logic PCLK,
    input logic PRESET,

    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,

    // External ports
    input  logic rx_in,
    output logic tx_out
);

    // Internal Ports
    logic [ 7:0] rx_data;
    logic        rx_done;
    logic        rx_busy;

    logic        tx_done;
    logic        tx_busy;
    logic [ 7:0] tx_data;
    logic        tx_start;

    logic [31:0] baud_rate;

    logic        tx_empty;
    logic        tx_full;
    logic        rx_empty;
    logic        rx_full;

    logic        loop_mode;

    APB_SlaveIntf_UART U_APB_SlaveInterf_UART (.*);
    UART U_UART (.*);
endmodule

module UART (
    // Global Signals
    input logic PCLK,
    input logic PRESET,

    // TX Signals
    input  logic [7:0] tx_data,
    input  logic       tx_start,
    output logic       tx_busy,
    output logic       tx_done,
    output logic       tx_out,

    // RX Signals
    input  logic       rx_in,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       rx_busy,

    // Baud Rate
    input logic [31:0] baud_rate,

    // FIFO Signals
    output logic tx_empty,
    output logic tx_full,
    output logic rx_empty,
    output logic rx_full,

    // Control Signals
    input logic loop_mode
);
    // Internal Wires
    logic       baud_clk;
    logic [7:0] fifo_rx_in;
    logic [7:0] fifo_tx_data;
    logic [7:0] fifo_rx_out;
    wire  [7:0] lb_data = (loop_mode) ? fifo_rx_out : tx_data;
    wire        lb_start = (loop_mode) ? !rx_empty : tx_start;

    assign rx_data = fifo_rx_out;

    BAUD_GENERATOR U_BAUD_GENERATOR (
        .clk      (PCLK),
        .rst      (PRESET),
        .baud_rate(baud_rate),
        .baud_clk (baud_clk)
    );

    UART_RX U_UART_RX (
        .clk    (PCLK),
        .rst    (PRESET),
        .baud   (baud_clk),
        .rx_in  (rx_in),
        .rx_data(fifo_rx_in),
        .rx_done(rx_done),
        .rx_busy(rx_busy)
    );

    FIFO U_FIFO_RX (
        .clk(PCLK),
        .rst(PRESET),
        .wr(rx_done & !rx_full),
        .rd(!rx_empty),
        .wdata(fifo_rx_in),
        .rdata(fifo_rx_out),
        .full(rx_full),
        .empty(rx_empty)
    );

    FIFO U_FIFO_TX (
        .clk(PCLK),
        .rst(PRESET),
        .wr(lb_start & !tx_full),
        .rd(!tx_empty),
        .wdata(lb_data),
        .rdata(fifo_tx_data),
        .full(tx_full),
        .empty(tx_empty)
    );

    UART_TX U_UART_TX (
        .clk     (PCLK),
        .rst     (PRESET),
        .baud    (baud_clk),
        .tx_start(!tx_empty),
        .tx_data (fifo_tx_data),
        .tx_out  (tx_out),
        .tx_done (tx_done),
        .tx_busy (tx_busy)
    );
endmodule

module APB_SlaveIntf_UART (
    // global signals
    input logic PCLK,
    input logic PRESET,

    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,

    // External Ports (UART)
    input  logic [ 7:0] rx_data,
    input  logic        rx_done,
    input  logic        rx_busy,
    input  logic        tx_busy,
    input  logic        tx_done,
    output logic [ 7:0] tx_data,
    output logic        tx_start,
    output logic [31:0] baud_rate,

    // External Ports (FIFO)
    input logic tx_empty,
    input logic tx_full,
    input logic rx_empty,
    input logic rx_full,

    // External Ports (Control)
    output logic loop_mode
);
    logic [31:0] slv_reg0;  // TX / RX Data
    logic [31:0] slv_reg1;  // Status Register (TX_EMPTY, TX_FULL, RX_EMPTY, RX_FULL, TX_BUSY, TX_DONE, RX_BUSY, RX_DONE)
    logic [31:0] slv_reg2;  // Control (tx_start, LOOP_MODE)
    logic [31:0] slv_reg3;  // Baud Rate

    assign tx_data   = slv_reg0[7:0];
    assign tx_start  = slv_reg2[0];
    assign loop_mode = slv_reg2[1];
    assign baud_rate = slv_reg3;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 32'h0;
            slv_reg1 <= 32'h0;
            slv_reg2 <= 32'h0;
            slv_reg3 <= 32'd9600;
        end else begin
            PREADY <= 1'b0;

            // 1-tick Signals Latching
            if (!rx_empty) slv_reg0[15:8] <= rx_data;
            if (tx_done)   slv_reg1[1] <= 1'b1;
            if (rx_done)   slv_reg1[3] <= 1'b1;
            if (rx_full)   slv_reg1[4] <= 1'b1;
            if (!rx_empty) slv_reg1[5] <= 1'b1;
            if (tx_full)   slv_reg1[6] <= 1'b1;
            if (!tx_empty) slv_reg1[7] <= 1'b1;

            // Return Holded Signals
            if (PREADY) begin
                if(slv_reg1[1]) slv_reg1[1] <= 1'b0;
                if(slv_reg1[3]) slv_reg1[3] <= 1'b0;
                if(slv_reg1[4]) slv_reg1[4] <= 1'b0;
                if(slv_reg1[5]) slv_reg1[5] <= 1'b0;
                if(slv_reg1[6]) slv_reg1[6] <= 1'b0;
                if(slv_reg1[7]) slv_reg1[7] <= 1'b0;
            end

            // No Latching
            slv_reg1[0] <= tx_busy;
            slv_reg1[2] <= rx_busy;
            
            if ((PSEL && PENABLE)) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:0])
                        4'h0: slv_reg0 <= PWDATA[7:0];
                        4'h8: slv_reg2 <= PWDATA;
                        4'hc: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    case (PADDR[3:0])
                        4'h0: PRDATA <= {16'h0, slv_reg0[15:0]};
                        4'h4: PRDATA <= slv_reg1;
                        4'h8: PRDATA <= slv_reg2;
                        4'hc: PRDATA <= slv_reg3;
                        default: PRDATA <= 32'h0;
                    endcase
                end
            end
        end
    end
endmodule

module BAUD_GENERATOR (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] baud_rate,
    output logic        baud_clk
);
    logic [31:0] DIV;

    always_comb begin
        DIV = 651;
        case (baud_rate)
            32'd1200:   DIV = 5208;
            32'd2400:   DIV = 2604;
            32'd4800:   DIV = 1302;
            32'd9600:   DIV = 651;
            32'd14400:  DIV = 434;
            32'd19200:  DIV = 326;
            32'd38400:  DIV = 163;
            32'd57600:  DIV = 108;
            32'd115200: DIV = 54;
            32'd230400: DIV = 27;
            32'd460800: DIV = 14;
            32'd921600: DIV = 7;
        endcase
    end

    // count register
    logic [$clog2(5208)-1:0] b_cnt_reg;
    logic b_tick_reg;

    // assign output
    assign baud_clk = b_tick_reg;

    // sequential logic
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            b_cnt_reg  <= 0;
            b_tick_reg <= 1'b0;
        end else begin
            if (b_cnt_reg == DIV - 1) begin
                b_cnt_reg  <= 0;
                b_tick_reg <= 1'b1;
            end else begin
                b_cnt_reg  <= b_cnt_reg + 1;
                b_tick_reg <= 1'b0;
            end
        end
    end
endmodule

module UART_RX (
    input  logic       clk,
    input  logic       rst,
    input  logic       baud,
    input  logic       rx_in,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       rx_busy
);

    // state parameter
    localparam [1:0] IDLE = 0, START = 1, DATA = 2, STOP = 3;

    // state register
    logic [1:0] state_reg, state_next;

    // output register
    logic [7:0] rx_reg, rx_next;
    logic rd_reg, rd_next;
    logic rb_reg, rb_next;

    // count register
    logic [3:0] tc_reg, tc_next;
    logic [2:0] bc_reg, bc_next;

    // assign output
    assign rx_data = rx_reg;
    assign rx_done = rd_reg;
    assign rx_busy = rb_reg;

    // sequential logic
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            rx_reg <= 8'h00;
            rd_reg <= 1'b0;
            rb_reg <= 1'b0;
            tc_reg <= 0;
            bc_reg <= 0;
        end else begin
            state_reg <= state_next;
            rx_reg <= rx_next;
            rd_reg <= rd_next;
            rb_reg <= rb_next;
            tc_reg <= tc_next;
            bc_reg <= bc_next;
        end
    end

    // combinational logic
    always_comb begin
        state_next = state_reg;
        rx_next = rx_reg;
        rd_next = rd_reg;
        rb_next = rb_reg;
        tc_next = tc_reg;
        bc_next = bc_reg;
        case (state_reg)
            IDLE: begin
                rd_next = 1'b0;
                rb_next = 1'b0;
                tc_next = 0;
                bc_next = 0;
                if (!rx_in) begin
                    state_next = START;
                    rb_next = 1'b1;
                end
            end
            START: begin
                if (baud) begin
                    if (tc_reg == 7) begin
                        state_next = DATA;
                        tc_next = 0;
                    end else begin
                        tc_next = tc_reg + 1;
                    end
                end
            end
            DATA: begin
                if (baud) begin
                    if (tc_reg == 15) begin
                        rx_next = {rx_in, rx_reg[7:1]};
                        tc_next = 0;
                        if (bc_reg == 7) begin
                            state_next = STOP;
                            tc_next = 0;
                            bc_next = 0;
                        end else begin
                            bc_next = bc_reg + 1;
                        end
                    end else begin
                        tc_next = tc_reg + 1;
                    end
                end
            end
            STOP: begin
                if (baud) begin
                    if (tc_reg == 15) begin
                        state_next = IDLE;
                        rd_next = 1'b1;
                        rb_next = 1'b0;
                        tc_next = 0;
                    end else begin
                        tc_next = tc_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

module UART_TX (
    input  logic       clk,
    input  logic       rst,
    input  logic       baud,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx_out,
    output logic       tx_done,
    output logic       tx_busy
);

    // state parameter
    localparam [1:0] IDLE = 0, START = 1, DATA = 2, STOP = 3;

    // state register
    logic [1:0] state_reg, state_next;

    // data register
    logic [7:0] db_reg, db_next;

    // output register
    logic tx_reg, tx_next;
    logic td_reg, td_next;
    logic tb_reg, tb_next;

    // count register
    logic [3:0] tc_reg, tc_next;
    logic [2:0] bc_reg, bc_next;

    // assign output
    assign tx_out  = tx_reg;
    assign tx_done = td_reg;
    assign tx_busy = tb_reg;

    // sequential logic
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            db_reg <= 8'h00;
            tx_reg <= 1'b1;
            td_reg <= 1'b0;
            tb_reg <= 1'b0;
            tc_reg <= 0;
            bc_reg <= 0;
        end else begin
            state_reg <= state_next;
            db_reg <= db_next;
            tx_reg <= tx_next;
            td_reg <= td_next;
            tb_reg <= tb_next;
            tc_reg <= tc_next;
            bc_reg <= bc_next;
        end
    end

    // combinational logic
    always_comb begin
        state_next = state_reg;
        db_next = db_reg;
        tx_next = tx_reg;
        td_next = td_reg;
        tb_next = tb_reg;
        tc_next = tc_reg;
        bc_next = bc_reg;

        case (state_reg)
            IDLE: begin
                db_next = 8'h00;
                tx_next = 1'b1;
                td_next = 1'b0;
                tb_next = 1'b0;
                tc_next = 0;
                bc_next = 0;
                if (tx_start) begin
                    db_next = tx_data;
                    state_next = START;
                end
            end
            START: begin
                tx_next = 1'b0;
                tb_next = 1'b1;
                if (baud) begin
                    if (tc_reg == 15) begin
                        state_next = DATA;
                        tc_next = 0;
                    end
                    begin
                        tc_next = tc_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = db_reg[0];
                if (baud) begin
                    if (tc_reg == 15) begin
                        if (bc_reg == 7) begin
                            state_next = STOP;
                            tc_next = 0;
                            bc_next = 0;
                        end else begin
                            db_next = db_reg >> 1;
                            bc_next = bc_reg + 1;
                            tc_next = 0;
                        end
                    end
                    begin
                        tc_next = tc_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (baud) begin
                    if (tc_reg == 15) begin
                        state_next = IDLE;
                        tx_next = 1'b1;
                        td_next = 1'b1;
                        tb_next = 1'b0;
                        tc_next = 0;
                    end
                    begin
                        tc_next = tc_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

module FIFO #(
    parameter DEPTH = 8
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       wr,
    input  logic       rd,
    input  logic [7:0] wdata,
    output logic [7:0] rdata,
    output logic       full,
    output logic       empty
);

    logic [$clog2(DEPTH)-1:0] waddr;
    logic [$clog2(DEPTH)-1:0] raddr;

    assign wr_en = wr & ~full;

    register_file U_REG_FILE (
        .*,
        .wr(wr_en)
    );
    fifo_control_unit U_FIFO_CU (.*);
endmodule

module register_file #(
    parameter DEPTH = 8
) (
    input  logic                     clk,
    input  logic                     wr,
    input  logic [              7:0] wdata,
    input  logic [$clog2(DEPTH)-1:0] waddr,
    input  logic [$clog2(DEPTH)-1:0] raddr,
    output logic [              7:0] rdata
);

    logic [7:0] ram[0:DEPTH-1];

    assign rdata = ram[raddr];

    always_ff @(posedge clk) begin
        if (wr) begin
            ram[waddr] <= wdata;
        end
    end

endmodule

module fifo_control_unit #(
    parameter DEPTH = 8
) (
    input  logic                     clk,
    input  logic                     rst,
    input  logic                     wr,
    input  logic                     rd,
    output logic [$clog2(DEPTH)-1:0] waddr,
    output logic [$clog2(DEPTH)-1:0] raddr,
    output logic                     full,
    output logic                     empty
);

    logic [$clog2(DEPTH)-1:0] waddr_reg, waddr_next;
    logic [$clog2(DEPTH)-1:0] raddr_reg, raddr_next;

    logic full_reg, full_next;
    logic empty_reg, empty_next;

    assign waddr = waddr_reg;
    assign raddr = raddr_reg;

    assign full  = full_reg;
    assign empty = empty_reg;

    // state reg
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            waddr_reg <= 0;
            raddr_reg <= 0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            waddr_reg <= waddr_next;
            raddr_reg <= raddr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    // next CL
    always_comb begin
        waddr_next = waddr_reg;
        raddr_next = raddr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;

        case ({
            wr, rd
        })
            2'b00: begin
                // nothing
            end

            2'b01: begin  // pop
                if (!empty_reg) begin
                    raddr_next = raddr_reg + 1;
                    full_next  = 1'b0;
                    if (waddr_reg == raddr_next) begin
                        empty_next = 1'b1;
                    end
                end
            end

            2'b10: begin  // push
                if (!full_reg) begin
                    waddr_next = waddr_reg + 1;
                    empty_next = 1'b0;
                    if (raddr_reg == waddr_next) begin
                        full_next = 1'b1;
                    end
                end
            end

            2'b11: begin  // push & pop
                if (full_reg) begin
                    raddr_next = raddr_reg + 1;
                    full_next  = 1'b0;
                end else if (empty_reg) begin
                    waddr_next = waddr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    waddr_next = waddr_reg + 1;
                    raddr_next = raddr_reg + 1;
                end
            end
        endcase
    end
endmodule
