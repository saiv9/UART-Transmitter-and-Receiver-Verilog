#!/usr/bin/env bash
set -euo pipefail

mkdir -p build
iverilog -g2012 -Wall -s tb_uart_top -o build/tb_uart_top.vvp \
  rtl/uart_tx.v rtl/uart_rx.v rtl/uart_top.v tb/tb_uart_top.v
vvp build/tb_uart_top.vvp | tee build/simulation.log
