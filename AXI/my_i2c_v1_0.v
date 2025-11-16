
`timescale 1 ns / 1 ps

	module my_i2c_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		output wire      SCL,
		inout            SDA,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);

	wire [7:0] wr_len, rd_len;
	wire enb;
	wire [7:0] t_dat, r_dat;
	wire txd, rxd, ready, ackerr, busy;

	// Instantiation of Axi Bus Interface S00_AXI
	my_i2c_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) my_i2c_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),

		.write_length(wr_len),
		.read_length(rd_len),
		.ENABLE(enb),
		.tx_data(t_dat),
		.tx_done(txd),
		.tx_ready(ready),
		.rx_data(r_dat),
		.rx_done(rxd),
		.ack_err(ackerr),
		.busy(busy)
	);

	// Add user logic here

	I2C_Master U_I2C_Master(
		.clk(s00_axi_aclk),
		.reset(s00_axi_aresetn),
		.write_length(wr_len),
		.read_length(rd_len),
		.ENABLE(enb),
		.SCL(SCL),
		.SDA(SDA),
		.tx_data(t_dat),
		.tx_done(txd),
		.tx_ready(ready),
		.rx_data(r_dat),
		.rx_done(rxd),
		.ack_err(ackerr),
		.busy(busy)
	);
	// User logic ends

	endmodule

	module I2C_Master (
		// Global Signals
		input  wire       clk,
		input  wire       reset,
		input  wire [7:0] write_length,
		input  wire [7:0] read_length,
		// I2C Signals
		input  wire       ENABLE,
		output wire       SCL,
		inout  wire       SDA,
		// Internal Signals
		input  wire [7:0] tx_data,
		output wire       tx_done,
		output wire       tx_ready,
		output wire [7:0] rx_data,
		output wire       rx_done,
		output wire       ack_err,
		output wire       busy
	);

		// I2C State
		localparam IDLE = 0, START = 1, CONTROL = 2, MEMCONT = 3, WRITE = 4, READ = 5, ACK = 6,
		NACK = 7, HOLD = 8, STOP = 9, RESTART = 10;
		reg [3:0] state, state_next;

		// Registers
		reg [9:0] cnt_reg, cnt_next;
		reg [2:0] bit_cnt_reg, bit_cnt_next;
		reg [7:0] wr_cnt_reg, wr_cnt_next;
		reg [7:0] rd_cnt_reg, rd_cnt_next;
		reg scl_reg, scl_next;
		reg sda_reg, sda_next;
		reg [7:0] tx_data_reg, tx_data_next;
		reg [7:0] rx_data_reg, rx_data_next;
		reg tx_done_reg, tx_done_next;
		reg tx_ready_reg, tx_ready_next;
		reg rx_done_reg, rx_done_next;
		reg mode_flag_reg, mode_flag_next;
		reg ack_reg, ack_next;
		reg error_reg, error_next;

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

    // Sequential Logic
    always @(posedge clk, posedge reset) begin
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
    always @(*) begin
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
                sda_next = SDA;
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