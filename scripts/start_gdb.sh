#!/bin/bash
riscv32-unknown-elf-gdb ../ibex-demo-system/sw/c/build/demo/hello_world/demo -ex "set remotetimeout 2000" -ex "target extended-remote localhost:3333"
