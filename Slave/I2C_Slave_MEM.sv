`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/14 01:28:21
// Design Name: 
// Module Name: I2C_Slave_MEM
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


module I2C_Slave_MEM #(parameter address = 7'b1100110)(
    // Global Signals
    input logic clk,
    input logic reset,
    // I2C Signals
    input logic SCL,
    inout logic SDA,
    // External Signals
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic [7:0] mm_addr,
    output logic       ld
    );

    typedef enum {
        IDLE,
        START,
        ADDRESS,
        MEMADDR,
        WRITE,
        READ,
        ACK,
        STOP,
        HOLD,
        HOLD_STOP,
        RESTART
    } i2c_state_eeprom;
    i2c_state_eeprom state, state_next;

    logic scl_sync_0, scl_sync_1;
    logic sda_sync_0, sda_sync_1;

    assign sda_pos = sda_sync_0 & ~sda_sync_1;
    assign sda_neg = ~sda_sync_0 & sda_sync_1;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            scl_sync_0 <= 1'b1;
            scl_sync_1 <= 1'b1;
            sda_sync_0 <= 1'b1;
            sda_sync_1 <= 1'b1;
        end else begin
            scl_sync_0 <= SCL;
            scl_sync_1 <= scl_sync_0;
            sda_sync_0 <= SDA;
            sda_sync_1 <= sda_sync_0;
        end
    end

    logic        sda_reg, sda_next;
    logic [ 9:0] cnt_reg, cnt_next;
    logic [ 2:0] bit_cnt_reg, bit_cnt_next;
    logic [ 7:0] tx_data_reg, tx_data_next;
    logic        tx_done_reg, tx_done_next;
    logic [ 7:0] rx_data_reg, rx_data_next;
    logic        rx_done_reg, rx_done_next;
    logic [ 7:0] mm_addr_reg, mm_addr_next;
    logic        wr_mode_reg, wr_mode_next;
    logic        mm_mode_reg, mm_mode_next;
    logic [ 7:0] rd_cnt_reg, rd_cnt_next;
    logic        restart_reg, restart_next;
    logic        ld_reg, ld_next;

    assign SDA = ((state == ACK || state == WRITE)) ? sda_reg : 1'bz;
    assign tx_done = tx_done_reg;
    assign rx_data = rx_data_reg;
    assign rx_done = rx_done_reg;
    assign mm_addr = mm_addr_reg;
    assign ld = ld_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            sda_reg <= 0;
            cnt_reg <= 0;
            bit_cnt_reg <= 0;
            tx_data_reg <= 0;
            tx_done_reg <= 0;
            rx_data_reg <= 0;
            rx_done_reg <= 0;
            mm_addr_reg <= 0;
            wr_mode_reg <= 0;
            mm_mode_reg <= 0;
            rd_cnt_reg <= 0;
            restart_reg <= 0;
            ld_reg <= 0;
        end else begin
            state <= state_next;
            sda_reg <= sda_next;
            cnt_reg <= cnt_next;
            bit_cnt_reg <= bit_cnt_next;
            tx_data_reg <= tx_data_next;
            tx_done_reg <= tx_done_next;
            rx_data_reg <= rx_data_next;
            rx_done_reg <= rx_done_next;
            mm_addr_reg <= mm_addr_next;
            wr_mode_reg <= wr_mode_next;
            mm_mode_reg <= mm_mode_next;
            rd_cnt_reg <= rd_cnt_next;
            restart_reg <= restart_next;
            ld_reg <= ld_next;
        end
    end

    always_comb begin
        state_next = state;
        cnt_next   = cnt_reg;
        sda_next   = sda_reg;
        bit_cnt_next = bit_cnt_reg;
        tx_data_next = tx_data_reg;
        tx_done_next = tx_done_reg;
        rx_data_next = rx_data_reg;
        rx_done_next = rx_done_reg;
        mm_addr_next = mm_addr_reg;
        wr_mode_next = wr_mode_reg;
        mm_mode_next = mm_mode_reg;
        rd_cnt_next = rd_cnt_reg;
        restart_next = restart_reg;
        ld_next = ld_reg;
        case (state)
            IDLE: begin
                cnt_next = 0;
                bit_cnt_next = 0;
                rd_cnt_next  = 0;
                rx_done_next = 0;
                tx_data_next = 0;
                rx_data_next = 0;
                restart_next = 0;
                if (scl_sync_1) begin
                    if (sda_neg) begin
                        state_next = START;
                    end
                end
            end 
            START: begin
                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    if (mm_mode_reg) begin
                        state_next = MEMADDR;
                    end else begin
                        state_next = ADDRESS;
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            ADDRESS: begin
                if (cnt_reg == 500 - 1) begin
                    rx_data_next = {rx_data_reg[6:0], sda_sync_1};
                end

                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    if (bit_cnt_reg == 8 - 1) begin
                        bit_cnt_next = 0;
                        if(rx_data_reg[7:0] == {address, 1'b0}) begin
                            rx_data_next = 0;
                            wr_mode_next = 0;
                            state_next = ACK;
                        end else if (rx_data_reg[7:0] == {address, 1'b1}) begin
                            rx_data_next = 0;
                            wr_mode_next = 1;
                            state_next = ACK;
                        end else begin
                            state_next = STOP;
                        end
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1;
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end 
            MEMADDR: begin
                if (cnt_reg == 500 - 1) begin
                    rx_data_next = {rx_data_reg[6:0], sda_sync_1};
                end

                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    if (bit_cnt_reg == 8 - 1) begin
                        state_next = ACK;
                        sda_next = 0;
                        mm_mode_next = 1;
                        mm_addr_next = rx_data_reg;
                        bit_cnt_next = 0;
                        if(rd_cnt_reg == 0) ld_next = 1;
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1;
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end 
            WRITE: begin
                wr_mode_next = 1;
                sda_next = tx_data_reg[7];
                tx_done_next = 0;
                rx_done_next = 0;
                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    if (bit_cnt_reg == 8 - 1) begin
                        sda_next = 0;
                        state_next = ACK;
                        bit_cnt_next = 0;
                        rd_cnt_next = rd_cnt_reg + 1;
                    end else begin
                        tx_data_next = {tx_data_reg[6:0], 1'b0};
                        bit_cnt_next = bit_cnt_reg + 1;
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end

                if (scl_sync_1) begin
                    if (sda_pos) begin
                        state_next = STOP;
                        cnt_next = 0;   
                    end                      
                end
            end
            READ: begin
                tx_done_next = 0;
                rx_done_next = 0;
                if (cnt_reg == 500 - 1) begin
                    rx_data_next = {rx_data_reg[6:0], sda_sync_1};
                end

                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    if (bit_cnt_reg == 8 - 1) begin
                        rd_cnt_next = rd_cnt_reg + 1;
                        state_next = ACK;
                        bit_cnt_next = 0;
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1;
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end

                if (scl_sync_1) begin
                    if (sda_pos) begin
                        state_next = STOP;
                        cnt_next = 0;   
                    end                      
                end
            end
            ACK: begin
                ld_next = 0;
                sda_next = (wr_mode_reg) ? 1'bz : 0;
                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    if (!mm_mode_reg) begin
                        if (wr_mode_reg && rd_cnt_reg == 0) begin
                            tx_data_next = tx_data;
                            state_next = WRITE;
                        end
                        else begin
                            if (restart_reg) begin
                                if (rd_cnt_reg > 0) tx_done_next = 1;
                                state_next = HOLD_STOP;
                            end else begin
                                if (rd_cnt_reg > 0) begin
                                    tx_done_next = 1;
                                    state_next = STOP;
                                end
                                else state_next = MEMADDR;
                            end                            
                        end
                    end else if (wr_mode_reg) begin
                        tx_data_next = tx_data;
                        if(rd_cnt_reg > 0) tx_done_next = 1;
                        sda_next = tx_data_reg[7];
                        state_next = HOLD;
                    end else if (!wr_mode_reg) begin
                        if(rd_cnt_reg > 0) rx_done_next = 1;
                        state_next = HOLD;
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end 
            HOLD: begin
                tx_done_next = 0;
                rx_done_next = 0;
                tx_data_next = tx_data;
                if (cnt_reg == 50 - 1) begin
                    if(scl_sync_1) begin
                        state_next = RESTART;
                    end else begin
                        if (wr_mode_reg) begin
                            tx_data_next = tx_data;
                            sda_next = tx_data_reg[7];
                            state_next = WRITE;
                        end else begin
                            state_next = READ;
                        end
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            HOLD_STOP: begin
                tx_done_next = 0;
                rx_done_next = 0;
                tx_data_next = tx_data;
                if (cnt_reg == 50 - 1) begin
                    if(scl_sync_1) begin
                        state_next = STOP;
                    end else begin
                        state_next = WRITE;
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            STOP: begin
                tx_data_next = 0;
                tx_done_next = 0;
                rx_data_next = 0;
                rx_done_next = 0;
                mm_addr_next = 0;
                wr_mode_next = 0;
                if (cnt_reg == 500 - 1) begin
                    state_next = IDLE;
                    cnt_next = 0;
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            RESTART: begin
                rd_cnt_next = 0;
                mm_mode_next = 0;
                restart_next = 1;
                if(sda_sync_1 && scl_sync_1 && cnt_reg > 300) state_next = STOP;
                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    state_next = ADDRESS;
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
        endcase
    end
endmodule
