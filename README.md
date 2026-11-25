# UART Transmitter and Receiver in Verilog

A basic UART block written in Verilog HDL. The design contains separate transmitter and receiver modules and a top-level wrapper. It uses one start bit, eight data bits by default, one stop bit, and least-significant-bit-first transmission.

## What is included

- Parameterized clock cycles per serial bit and data width.
- UART transmitter with `tx_busy` and one-cycle `tx_done` status.
- UART receiver with a two-flop input synchronizer.
- Mid-bit start validation and data sampling.
- Framing-error indication when the stop bit is low.
- Self-checking loopback testbench and a separate bad-stop-bit test.
- Icarus Verilog simulation script and GitHub Actions workflow.

## Architecture

![UART architecture](docs/architecture.svg)

The transmitter converts a parallel word into a serial frame. The receiver synchronizes the asynchronous input, checks the start bit near its midpoint, samples each data bit, and validates the stop bit. The top-level module exposes independent TX and RX pins; the testbench connects TX to RX for loopback verification.

## Files

| Path | Purpose |
|---|---|
| `rtl/uart_tx.v` | Serial transmitter |
| `rtl/uart_rx.v` | Serial receiver |
| `rtl/uart_top.v` | TX/RX top-level integration |
| `tb/tb_uart_top.v` | Self-checking testbench |
| `docs/verification-plan.md` | Test cases and verification scope |
| `scripts/run_sim.sh` | Compile and run with Icarus Verilog |
| `.github/workflows/uart-simulation.yml` | Automated simulation on GitHub Actions |

## Interface

### Parameters

| Parameter | Default | Description |
|---|---:|---|
| `CLKS_PER_BIT` | 16 | Clock cycles per UART bit; must be at least 2 |
| `DATA_BITS` | 8 | Number of data bits per frame |

Choose `CLKS_PER_BIT` to match the clock frequency and desired baud rate:

`CLKS_PER_BIT = CLOCK_FREQUENCY / BAUD_RATE`

The division should produce an integer for this implementation. The default value of 16 is intended for simulation and is not tied to a particular board clock or standard baud rate.

### Top-level signals

| Signal | Direction | Description |
|---|---|---|
| `clk` | Input | System clock |
| `rst_n` | Input | Asynchronous active-low reset |
| `tx_start` | Input | Starts a frame when the transmitter is idle |
| `tx_data` | Input | Parallel word to transmit |
| `rx` | Input | Asynchronous serial input |
| `tx` | Output | Serial output, idle high |
| `tx_busy` | Output | High while a frame is being transmitted |
| `tx_done` | Output | One-clock pulse after the stop bit |
| `rx_data` | Output | Most recently received word |
| `rx_valid` | Output | One-clock pulse for a valid frame |
| `framing_error` | Output | One-clock pulse if the stop bit is low |

## Example instantiation

```verilog
uart_top #(
    .CLKS_PER_BIT(434),
    .DATA_BITS(8)
) uart_inst (
    .clk(clk),
    .rst_n(rst_n),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .rx(rx),
    .tx(tx),
    .tx_busy(tx_busy),
    .tx_done(tx_done),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .framing_error(framing_error)
);
```

The example divider is illustrative only. Calculate it from the actual system clock and target baud rate, and account for integer-divider error in a real design.

## Run the simulation

Install Icarus Verilog, then run from the repository root:

```sh
bash scripts/run_sim.sh
```

The testbench checks loopback for `00`, `FF`, `A5`, `3C`, and `96`, checks transmitter completion, and verifies that a low stop bit raises `framing_error`. It writes a VCD waveform to `build/uart_loopback.vcd`. GitHub Actions runs the same test and uploads the waveform and simulation log as an artifact.

## Verification scope

The testbench is simulation-based. It does not establish timing closure or operation on a physical FPGA board. This project does not include parity, configurable stop-bit count, FIFO buffering, flow control, or automatic baud-rate detection.
