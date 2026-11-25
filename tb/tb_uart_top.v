`timescale 1ns/1ps

module tb_uart_top;
    localparam integer CLKS_PER_BIT = 16;
    localparam integer DATA_BITS = 8;

    reg clk;
    reg rst_n;
    reg tx_start;
    reg [DATA_BITS-1:0] tx_data;
    reg inject_rx;
    reg rx_stim;
    wire tx;
    wire rx_line;
    wire tx_busy;
    wire tx_done;
    wire [DATA_BITS-1:0] rx_data;
    wire rx_valid;
    wire framing_error;

    integer rx_valid_count;
    integer framing_error_count;
    integer timeout_count;
    integer i;
    reg framing_error_seen;

    assign rx_line = inject_rx ? rx_stim : tx;

    uart_top #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .DATA_BITS(DATA_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .rx(rx_line),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .framing_error(framing_error)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rx_valid)
            rx_valid_count <= rx_valid_count + 1;
        if (framing_error) begin
            framing_error_count <= framing_error_count + 1;
            framing_error_seen <= 1'b1;
        end
    end

    task send_and_check;
        input [DATA_BITS-1:0] value;
        begin
            wait (tx_busy == 1'b0);
            @(negedge clk);
            tx_data  = value;
            tx_start = 1'b1;
            @(negedge clk);
            tx_start = 1'b0;

            timeout_count = 0;
            while ((rx_valid !== 1'b1) && (timeout_count < CLKS_PER_BIT * 12)) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
            end

            if (rx_valid !== 1'b1)
                $fatal(1, "Timeout waiting for RX data 0x%02h", value);
            if (rx_data !== value)
                $fatal(1, "Loopback mismatch: sent 0x%02h, received 0x%02h", value, rx_data);

            wait (tx_done == 1'b1);
            @(negedge clk);
            if (tx !== 1'b1 || tx_busy !== 1'b0)
                $fatal(1, "TX did not return to idle after 0x%02h", value);
            $display("PASS: loopback 0x%02h", value);
        end
    endtask

    task send_bad_stop_frame;
        reg [DATA_BITS-1:0] value;
        integer bit_no;
        begin
            value = 8'hA6;
            wait (tx_busy == 1'b0);
            @(negedge clk);
            inject_rx = 1'b1;
            rx_stim = 1'b1;
            repeat (CLKS_PER_BIT) @(negedge clk);

            rx_stim = 1'b0; // Start bit
            repeat (CLKS_PER_BIT) @(negedge clk);

            for (bit_no = 0; bit_no < DATA_BITS; bit_no = bit_no + 1) begin
                rx_stim = value[bit_no];
                repeat (CLKS_PER_BIT) @(negedge clk);
            end

            rx_stim = 1'b0; // Deliberately invalid stop bit
            repeat (CLKS_PER_BIT) @(negedge clk);
            rx_stim = 1'b1;
            repeat (CLKS_PER_BIT) @(negedge clk);
            inject_rx = 1'b0;

            if (framing_error_seen !== 1'b1)
                $fatal(1, "Receiver did not flag the invalid stop bit");
            if (framing_error_count != 1)
                $fatal(1, "Expected one framing error, observed %0d", framing_error_count);
            $display("PASS: invalid stop bit reported as framing_error");
        end
    endtask

    initial begin
        $dumpfile("build/uart_loopback.vcd");
        $dumpvars(0, tb_uart_top);

        clk = 1'b0;
        rst_n = 1'b0;
        tx_start = 1'b0;
        tx_data = {DATA_BITS{1'b0}};
        inject_rx = 1'b0;
        rx_stim = 1'b1;
        rx_valid_count = 0;
        framing_error_count = 0;
        timeout_count = 0;
        framing_error_seen = 1'b0;

        repeat (4) @(negedge clk);
        rst_n = 1'b1;
        repeat (4) @(negedge clk);

        send_and_check(8'h00);
        send_and_check(8'hFF);
        send_and_check(8'hA5);
        send_and_check(8'h3C);
        send_and_check(8'h96);

        send_bad_stop_frame();

        if (rx_valid_count != 5)
            $fatal(1, "Expected 5 valid loopback bytes, observed %0d", rx_valid_count);

        $display("PASS: %0d loopback bytes and framing-error check completed", rx_valid_count);
        $finish;
    end
endmodule
