# UART Verification Plan

## Configuration

The self-checking simulation uses an 8-bit data word and 16 clock cycles per serial bit. The transmitter output is connected to the receiver input for loopback tests. A separate test sequence drives the receiver input directly to exercise framing-error detection.

## Test cases

| Test | Stimulus | Expected result |
|---|---|---|
| Reset | Assert active-low reset | TX and RX return to idle; outputs and status flags clear |
| Zero data | Transmit `0x00` | Receiver reports `0x00` |
| All ones | Transmit `0xFF` | Receiver reports `0xFF` |
| Alternating pattern | Transmit `0xA5` | Receiver reports `0xA5` |
| Mixed pattern | Transmit `0x3C` and `0x96` | Receiver reports each byte in order |
| TX completion | Wait for each frame to finish | `tx_done` pulses and TX returns high/idle |
| Bad stop bit | Drive a valid start and data field followed by a low stop bit | `framing_error` pulses; no valid byte is counted for that frame |

## Run

From the repository root:

```sh
bash scripts/run_sim.sh
```

The testbench writes `build/uart_loopback.vcd` and the script writes `build/simulation.log`. GitHub Actions runs the same test using Icarus Verilog.

## Scope and limitations

This is a basic asynchronous UART with one start bit, eight data bits by default, and one stop bit. It does not implement parity, programmable stop-bit count, hardware flow control, FIFOs, or automatic baud-rate detection. The receiver uses a two-flop synchronizer and samples at the bit centers. The default reset is asynchronous and active-low.
