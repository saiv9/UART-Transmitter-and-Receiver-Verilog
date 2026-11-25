// UART transmitter: 8-bit default, LSB first, 1 start bit, 1 stop bit.
module uart_tx #(
    parameter integer CLKS_PER_BIT = 16,
    parameter integer DATA_BITS = 8
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  tx_start,
    input  wire [DATA_BITS-1:0]  tx_data,
    output reg                   tx,
    output reg                   tx_busy,
    output reg                   tx_done
);
    localparam [1:0] IDLE  = 2'd0,
                     START = 2'd1,
                     DATA  = 2'd2,
                     STOP  = 2'd3;
    localparam integer COUNT_WIDTH = (CLKS_PER_BIT <= 2) ? 1 : $clog2(CLKS_PER_BIT);
    localparam integer INDEX_WIDTH = (DATA_BITS <= 2) ? 1 : $clog2(DATA_BITS);

    reg [1:0] state;
    reg [COUNT_WIDTH-1:0] clk_count;
    reg [INDEX_WIDTH-1:0] bit_index;
    reg [DATA_BITS-1:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            clk_count <= {COUNT_WIDTH{1'b0}};
            bit_index <= {INDEX_WIDTH{1'b0}};
            shift_reg <= {DATA_BITS{1'b0}};
            tx        <= 1'b1;
            tx_busy   <= 1'b0;
            tx_done   <= 1'b0;
        end else begin
            tx_done <= 1'b0;

            case (state)
                IDLE: begin
                    tx        <= 1'b1;
                    tx_busy   <= 1'b0;
                    clk_count <= {COUNT_WIDTH{1'b0}};
                    bit_index <= {INDEX_WIDTH{1'b0}};
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        tx        <= 1'b0;
                        tx_busy   <= 1'b1;
                        state     <= START;
                    end
                end

                START: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= {COUNT_WIDTH{1'b0}};
                        tx        <= shift_reg[0];
                        state     <= DATA;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= {COUNT_WIDTH{1'b0}};
                        if (bit_index == DATA_BITS - 1) begin
                            tx    <= 1'b1;
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                            shift_reg <= shift_reg >> 1;
                            tx        <= shift_reg[1];
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= {COUNT_WIDTH{1'b0}};
                        tx_done   <= 1'b1;
                        tx_busy   <= 1'b0;
                        state     <= IDLE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                    tx    <= 1'b1;
                end
            endcase
        end
    end
endmodule
