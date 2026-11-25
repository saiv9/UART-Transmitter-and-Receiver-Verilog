`timescale 1ns/1ps

// Top-level UART block: one transmitter and one receiver.
module uart_top #(
    parameter integer CLKS_PER_BIT = 16,
    parameter integer DATA_BITS = 8
) (
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 tx_start,
    input  wire [DATA_BITS-1:0] tx_data,
    input  wire                 rx,
    output wire                 tx,
    output wire                 tx_busy,
    output wire                 tx_done,
    output wire [DATA_BITS-1:0] rx_data,
    output wire                 rx_valid,
    output wire                 framing_error
);
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .DATA_BITS(DATA_BITS)
    ) transmitter (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .DATA_BITS(DATA_BITS)
    ) receiver (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .framing_error(framing_error)
    );
endmodule
