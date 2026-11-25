`timescale 1ns/1ps

// UART receiver with a two-flop input synchronizer and mid-bit sampling.
module uart_rx #(
    parameter integer CLKS_PER_BIT = 16,
    parameter integer DATA_BITS = 8
) (
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 rx,
    output reg  [DATA_BITS-1:0] rx_data,
    output reg                  rx_valid,
    output reg                  framing_error
);
    localparam [1:0] IDLE  = 2'd0,
                     START = 2'd1,
                     DATA  = 2'd2,
                     STOP  = 2'd3;
    localparam integer COUNT_WIDTH = (CLKS_PER_BIT <= 2) ? 1 : $clog2(CLKS_PER_BIT);
    localparam integer INDEX_WIDTH = (DATA_BITS <= 2) ? 1 : $clog2(DATA_BITS);

    reg rx_meta;
    reg rx_sync;
    reg [1:0] state;
    reg [COUNT_WIDTH-1:0] clk_count;
    reg [INDEX_WIDTH-1:0] bit_index;
    reg [DATA_BITS-1:0] shift_reg;

    // Synchronize the asynchronous serial input into the local clock domain.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            clk_count     <= {COUNT_WIDTH{1'b0}};
            bit_index     <= {INDEX_WIDTH{1'b0}};
            shift_reg     <= {DATA_BITS{1'b0}};
            rx_data       <= {DATA_BITS{1'b0}};
            rx_valid      <= 1'b0;
            framing_error <= 1'b0;
        end else begin
            rx_valid      <= 1'b0;
            framing_error <= 1'b0;

            case (state)
                IDLE: begin
                    clk_count <= {COUNT_WIDTH{1'b0}};
                    bit_index <= {INDEX_WIDTH{1'b0}};
                    if (rx_sync == 1'b0)
                        state <= START;
                end

                START: begin
                    if (clk_count == (CLKS_PER_BIT / 2) - 1) begin
                        clk_count <= {COUNT_WIDTH{1'b0}};
                        if (rx_sync == 1'b0) begin
                            bit_index <= {INDEX_WIDTH{1'b0}};
                            state     <= DATA;
                        end else begin
                            state <= IDLE; // Reject a short low pulse.
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= {COUNT_WIDTH{1'b0}};
                        shift_reg[bit_index] <= rx_sync;
                        if (bit_index == DATA_BITS - 1) begin
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= {COUNT_WIDTH{1'b0}};
                        if (rx_sync == 1'b1) begin
                            rx_data  <= shift_reg;
                            rx_valid <= 1'b1;
                        end else begin
                            framing_error <= 1'b1;
                        end
                        state <= IDLE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
