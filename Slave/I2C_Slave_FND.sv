`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/12 15:05:13
// Design Name: 
// Module Name: I2C_Slave_FND
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


module I2C_Slave_FND #(parameter read_length = 2, address = 7'b1100101)(
    // Global Signals
    input logic clk,
    input logic reset,
    // I2C Signals
    input logic SCL,
    inout logic SDA,
    // External Signals
    output logic [15:0] fnd_data,
    output logic        rx_done
    );

    typedef enum {
        IDLE,
        START,
        ADDRESS,
        READ,
        ACK,
        NACK,
        HOLD,
        STOP
    } i2c_state_fnd;
    i2c_state_fnd state, state_next;

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

    logic [ 9:0] cnt_reg, cnt_next;
    logic [ 1:0] rd_cnt_reg, rd_cnt_next;
    logic [ 2:0] bit_cnt_reg, bit_cnt_next;
    logic [15:0] rx_data_reg, rx_data_next;
    logic        rx_done_reg, rx_done_next;
    logic [15:0] fnd_data_reg, fnd_data_next;

    assign SDA = (state == ACK && cnt_reg < 997) ? 1'b0 : 1'bz;
    assign fnd_data = fnd_data_reg;
    assign rx_done = rx_done_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            cnt_reg <= 0;
            rd_cnt_reg <= 0;
            bit_cnt_reg <= 0;
            rx_data_reg <= 0;
            rx_done_reg <= 0;
            fnd_data_reg <= 0;
        end else begin
            state <= state_next;
            cnt_reg <= cnt_next;
            rd_cnt_reg <= rd_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
            rx_data_reg <= rx_data_next;
            rx_done_reg <= rx_done_next;
            fnd_data_reg <= fnd_data_next;
        end
    end

    always_comb begin
        state_next = state;
        cnt_next   = cnt_reg;
        rd_cnt_next = rd_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        rx_data_next = rx_data_reg;
        rx_done_next = rx_done_reg;
        fnd_data_next = fnd_data_reg;
        case (state)
            IDLE: begin
                cnt_next = 0;
                rd_cnt_next = 0;
                bit_cnt_next = 0;
                rx_done_next = 0;
                if (scl_sync_1) begin
                    if (sda_neg) begin
                        state_next = START;
                    end
                end
            end 
            START: begin
                if (cnt_reg == 1000 - 1) begin
                    state_next = ADDRESS;
                    cnt_next = 0;
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end 
            ADDRESS: begin
                if (cnt_reg == 500 - 1) begin
                    rx_data_next = {rx_data_reg[15:0], sda_sync_1};
                end

                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    if (bit_cnt_reg == 8 - 1) begin
                        bit_cnt_next = 0;
                        // Master(write 1'b0) -> Slave(read) 
                        if(rx_data_reg[7:0] == {address, 1'b0}) begin
                            rx_data_next = 0;
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
            READ: begin
                if (cnt_reg == 500 - 1) begin
                    rx_data_next = {rx_data_reg[15:0], sda_sync_1};
                end

                if (cnt_reg == 1000 - 1) begin
                    cnt_next = 0;
                    if (bit_cnt_reg == 8 - 1) begin
                        bit_cnt_next = 0;
                        rd_cnt_next = rd_cnt_reg + 1;
                        if (rd_cnt_next != read_length) begin
                            state_next = ACK;
                        end else begin
                            fnd_data_next = rx_data_reg;
                            state_next = NACK;
                        end
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1;
                    end
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            ACK: begin
                if (cnt_reg == 1000 - 1) begin
                    state_next = READ;
                    cnt_next = 0;
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end 
            NACK: begin
                if (cnt_reg == 1000 - 1) begin
                    state_next = STOP;
                    rx_done_next = 1'b1;
                    cnt_next = 0;
                end else begin
                    cnt_next = cnt_reg + 1;
                end
            end
            STOP: begin
                rx_done_next = 1'b0;
                if (scl_sync_1) begin
                    cnt_next = cnt_reg + 1;
                    if (sda_pos && cnt_reg > 50) begin
                        state_next = IDLE;
                        cnt_next = 0;   
                    end                      
                end
            end
        endcase
    end
endmodule
