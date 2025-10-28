`timescale 1ns / 1ps

module MCU (
    // Global Signals
    input  logic       clk,
    input  logic       reset,

    // GPIO Ports
    inout  logic [15:0] gpio,

    // UART Ports
    input  logic       rx_in,
    output logic       tx_out,

    // FND Ports
    output logic [7:0] fnd_data,
    output logic [3:0] fnd_com
);
    // Global Signals
    wire         PCLK = clk;
    wire         PRESET = reset;

    // Internal Interface Signals
    logic        transfer;
    logic        ready;
    logic        write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;

    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;
    logic        busWe;
    logic [31:0] busAddr;
    logic [31:0] busWData;
    logic [31:0] busRData;

    // APB Interface Signals
    logic [31:0] PADDR;
    logic        PWRITE;
    logic        PENABLE;
    logic [31:0] PWDATA;

    logic        PSEL_RAM;
    logic        PSEL_GPIO;
    logic        PSEL_UART;
    logic        PSEL_TIMER;
    logic        PSEL_FND;

    logic [31:0] PRDATA_RAM;
    logic [31:0] PRDATA_GPIO;
    logic [31:0] PRDATA_UART;
    logic [31:0] PRDATA_TIMER;
    logic [31:0] PRDATA_FND;

    logic        PREADY_RAM;
    logic        PREADY_GPIO;
    logic        PREADY_UART;
    logic        PREADY_TIMER;
    logic        PREADY_FND;

    assign write = busWe;
    assign addr = busAddr;
    assign wdata = busWData;
    assign busRData = rdata;


    ////////////////////////
    // Instruction Memory //
    ////////////////////////

    ROM U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    ///////////////////////////////
    // RV32I Multicycle CPU Core //
    ///////////////////////////////

    CPU_RV32I U_RV32I (.*);

    //////////////////
    // AMBA APB Bus //
    //////////////////

    APB_Master U_APB_Master (
        .*,
        .PSEL0  (PSEL_RAM),
        .PSEL1  (PSEL_GPIO),
        .PSEL2  (PSEL_UART),
        .PSEL3  (PSEL_TIMER),
        .PSEL4  (PSEL_FND),

        .PRDATA0(PRDATA_RAM),
        .PRDATA1(PRDATA_GPIO),
        .PRDATA2(PRDATA_UART),
        .PRDATA3(PRDATA_TIMER),
        .PRDATA4(PRDATA_FND),

        .PREADY0(PREADY_RAM),
        .PREADY1(PREADY_GPIO),
        .PREADY2(PREADY_UART),
        .PREADY3(PREADY_TIMER),
        .PREADY4(PREADY_FND)
    );

    /////////////////
    // Peripherals //
    /////////////////

    // RAM (0x10000000 ~ 0x10000FFF)
    RAM U_RAM (
        .*,
        .PADDR (PADDR[11:0]),
        .PSEL  (PSEL_RAM),
        .PRDATA(PRDATA_RAM),
        .PREADY(PREADY_RAM)
    );

    // GPIO (0x10001000 ~ 0x10001FFF)
    GPIO_Periph U_GPIO_Periph (
        .*,
        .PADDR (PADDR[3:0]),
        .PSEL  (PSEL_GPIO),
        .PRDATA(PRDATA_GPIO),
        .PREADY(PREADY_GPIO)
    );

    // UART (0x10002000 ~ 0x10002FFF)
    UART_Periph U_UART_Periph(
        .*,
        .PADDR (PADDR[3:0]),
        .PSEL  (PSEL_UART),
        .PRDATA(PRDATA_UART),
        .PREADY(PREADY_UART)
    );

    // TIMER (0x10003000 ~ 0x10003FFF)
    TIMER_Periph U_TIMER_Periph(
        .*,
        .PADDR (PADDR[3:0]),
        .PSEL  (PSEL_TIMER),
        .PRDATA(PRDATA_TIMER),
        .PREADY(PREADY_TIMER),
        .irq()
    );

    // FND (0x10004000 ~ 0x10004FFF)
    FND_Periph U_FND_Periph(
        .*,
        .PADDR (PADDR[3:0]),
        .PSEL  (PSEL_FND),
        .PRDATA(PRDATA_FND),
        .PREADY(PREADY_FND)
    );
endmodule
