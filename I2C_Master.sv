`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/11 14:26:41
// Design Name: 
// Module Name: I2C_Master
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


module I2C_Master (
    // Global Signals
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] write_length,
    input  logic [7:0] read_length,
    // I2C Signals
    input  logic       ENABLE,
    output logic       SCL,
    inout  logic       SDA,
    // Internal Signals
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic       tx_ready,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       ack_err,
    output logic       busy
);

    // I2C State
    typedef enum {
        IDLE,
        START,
        CONTROL,
        WRITE,
        READ,
        ACK,
        NACK,
        HOLD,
        STOP,
        RESTART
    } i2c_state_m;
    i2c_state_m state, state_next;

    // Registers
    logic [9:0] cnt_reg, cnt_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic [7:0] wr_cnt_reg, wr_cnt_next;
    logic [7:0] rd_cnt_reg, rd_cnt_next;
    logic scl_reg, scl_next;
    logic sda_reg, sda_next;
    logic [7:0] tx_data_reg, tx_data_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic tx_done_reg, tx_done_next;
    logic tx_ready_reg, tx_ready_next;
    logic rx_done_reg, rx_done_next;
    logic mode_flag_reg, mode_flag_next;
    logic ack_reg, ack_next;
    logic error_reg, error_next;

    // Assign Outputs
    assign SCL      = scl_reg;
    assign SDA      = (wr_cnt_reg == write_length) ?
                      ((state == ACK || state == NACK) ? sda_reg : 
                      ((state != READ) ? sda_reg : 1'bz)) : 
                      ((state == ACK) ? 1'bz : ((state == HOLD) ? sda_next : sda_reg));
    assign tx_done  = tx_done_reg;
    assign tx_ready = tx_ready_reg;
    assign rx_done  = rx_done_reg;
    assign rx_data  = rx_data_reg;
    assign ack_err  = error_reg;
    assign busy     = !tx_ready_reg;

    // Synchronizer
    reg sda_sync_0, sda_sync_1;
	always @(posedge clk, posedge reset) begin
        if (reset) begin
            sda_sync_0 <= 1'b1;
            sda_sync_1 <= 1'b1;
        end else begin
            sda_sync_0 <= (state == READ || (state == ACK && rd_cnt_reg == 0)) ? SDA : 1'bz;
            sda_sync_1 <= sda_sync_0;
        end
    end

    // Sequential Logic
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state         <= IDLE;
            scl_reg       <= 1'b1;
            sda_reg       <= 1'b1;
            tx_data_reg   <= 8'h00;
            rx_data_reg   <= 8'h00;
            tx_done_reg   <= 1'b0;
            tx_ready_reg  <= 1'b1;
            rx_done_reg   <= 1'b0;
            ack_reg       <= 1'b0;
            mode_flag_reg <= 1'b0;
            error_reg     <= 1'b0;
            cnt_reg       <= 0;
            bit_cnt_reg   <= 0;
            wr_cnt_reg    <= 0;
            rd_cnt_reg    <= 0;
        end else begin
            state         <= state_next;
            scl_reg       <= scl_next;
            sda_reg       <= sda_next;
            tx_data_reg   <= tx_data_next;
            rx_data_reg   <= rx_data_next;
            tx_done_reg   <= tx_done_next;
            tx_ready_reg  <= tx_ready_next;
            rx_done_reg   <= rx_done_next;
            ack_reg       <= ack_next;
            mode_flag_reg <= mode_flag_next;
            error_reg     <= error_next;
            cnt_reg       <= cnt_next;
            bit_cnt_reg   <= bit_cnt_next;
            wr_cnt_reg    <= wr_cnt_next;
            rd_cnt_reg    <= rd_cnt_next;
        end
    end

    // Combinational Logic
    always_comb begin
        state_next     = state;
        scl_next       = scl_reg;
        sda_next       = sda_reg;
        tx_data_next   = tx_data_reg;
        rx_data_next   = rx_data_reg;
        tx_done_next   = tx_done_reg;
        tx_ready_next  = tx_ready_reg;
        rx_done_next   = rx_done_reg;
        ack_next       = ack_reg;
        cnt_next       = cnt_reg;
        bit_cnt_next   = bit_cnt_reg;
        wr_cnt_next    = wr_cnt_reg;
        rd_cnt_next    = rd_cnt_reg;
        mode_flag_next = mode_flag_reg;
        error_next     = error_reg;
        case (state)
            IDLE: begin
                sda_next = 1'b1;
                scl_next = 1'b1;
                tx_ready_next = 1'b1;
                wr_cnt_next = 0;
                rd_cnt_next = 0;
                if (ENABLE) begin
                    state_next = START;
                    sda_next = 1'b0;
                    tx_ready_next = 1'b0;
                end
            end
            START: begin
                scl_next = (cnt_reg < 500 - 1) ? 1'b1 : 1'b0;
                tx_done_next  = 1'b0;
                if (cnt_reg == 1000 - 1) begin
                    state_next = CONTROL;
                    tx_data_next = tx_data;
                    sda_next     = tx_data[7];
                    mode_flag_next = tx_data[0];
                    cnt_next = 0;
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            CONTROL: begin
                sda_next = tx_data_reg[7];
                scl_next = (cnt_reg >= 250 - 1 && cnt_reg < 750 - 1) ? 1'b1 : 1'b0;
                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    if (bit_cnt_reg == 8 - 1) begin
                        state_next = ACK;
                        sda_next = (wr_cnt_reg == write_length) ? 1'b0 : 1'bz;
                        bit_cnt_next = 0;
                    end else begin
                        tx_data_next = {tx_data_reg[6:0], 1'b0};
                        sda_next     = tx_data_next[7];
                        bit_cnt_next = bit_cnt_reg + 1;
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            WRITE: begin
                sda_next = tx_data_reg[7];
                scl_next = (cnt_reg >= 250 - 1 && cnt_reg < 750 - 1) ? 1'b1 : 1'b0;
                tx_done_next = 1'b0;
                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    if (bit_cnt_reg == 8 - 1) begin
                        state_next = ACK;
                        sda_next = (wr_cnt_reg == write_length) ? 1'b0 : 1'bz;
                        bit_cnt_next = 0;
                        wr_cnt_next = wr_cnt_reg + 1;
                    end else begin
                        tx_data_next = {tx_data_reg[6:0], 1'b0};
                        sda_next     = tx_data_next[7];
                        bit_cnt_next = bit_cnt_reg + 1;
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            READ: begin
                sda_next = sda_sync_1;
                scl_next = (cnt_reg >= 250 - 1 && cnt_reg < 750 - 1) ? 1'b1 : 1'b0;
                tx_done_next = 1'b0;
                rx_done_next = 1'b0;

                if (cnt_reg == 500 - 1) begin
                    rx_data_next = {rx_data_reg[6:0], sda_reg};
                end

                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    if (bit_cnt_reg == 8 - 1) begin
                        bit_cnt_next = 0;
                        rd_cnt_next = rd_cnt_reg + 1;
                        if(rd_cnt_next == read_length) begin
                            state_next = NACK;
                            sda_next = 1'b0;
                        end else begin
                            state_next = ACK;
                            sda_next = (wr_cnt_reg == write_length) ? 1'b0 : 1'bz;
                        end
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1;
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            ACK: begin
                sda_next = (wr_cnt_reg == write_length) ? 1'b0 : 1'bz;
                scl_next = (cnt_reg >= 250 - 1 && cnt_reg < 750 - 1) ? 1'b1 : 1'b0;

                if (cnt_reg == 499) ack_next = SDA;

                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    if (ack_reg == 0) begin
                        if (mode_flag_reg == 0) begin
                            tx_done_next = 1'b1;
                            if (read_length != 0 && wr_cnt_reg == write_length) begin
                                scl_next = 1'b1;
                                if (mode_flag_reg) begin
                                    state_next = READ;
                                end else begin
                                    state_next = RESTART;
                                end
                            end else if (wr_cnt_reg == write_length) begin
                                state_next = STOP;
                            end else begin
                                state_next = HOLD;
                                sda_next   = 1'b0;
                            end
                        end else if (mode_flag_reg == 1) begin
                            state_next = READ;
                            if(rd_cnt_reg == 0) begin
                                tx_done_next = 1'b1;
                            end else begin
                                rx_done_next = 1'b1;
                            end
                        end                        
                    end else begin
                        state_next = NACK;
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            NACK: begin
                sda_next = 1'b0;
                scl_next = (cnt_reg >= 250 - 1 && cnt_reg < 750 - 1) ? 1'b1 : 1'b0;
                if (cnt_reg == 1000 - 1) begin
                    state_next = STOP;
                    if (rd_cnt_reg == read_length) begin
                        rx_done_next = 1'b1;
                    end else begin
                        error_next = 1'b1;
                    end
                    cnt_next = 0;
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            HOLD: begin
                tx_data_next = tx_data;
                sda_next = tx_data_next[7];
                scl_next = 1'b0;
                tx_done_next = 1'b0;
                if(cnt_reg == 100 - 1) begin
                    state_next = WRITE;
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            STOP: begin
                sda_next = (cnt_reg < 500 - 1) ? 1'b0 : 1'b1;
                scl_next = 1'b1;
                tx_done_next = 0;
                rx_done_next = 1'b0;
                error_next   = 1'b0;
                if (cnt_reg == 1000 - 1) begin
                    state_next = IDLE;
                    cnt_next = 0;
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            RESTART: begin
                sda_next = (cnt_reg < 250 - 1) ? 1'b1 : 1'b0;
                scl_next = (cnt_reg < 500 - 1) ? 1'b1 : 1'b0;
                mode_flag_next = 1'b1;
                tx_done_next  = 1'b0;
                if (cnt_reg == 1000 - 1) begin
                    state_next = CONTROL;
                    tx_data_next = tx_data;
                    sda_next     = tx_data[7];
                    cnt_next = 0;
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
        endcase
    end
endmodule
