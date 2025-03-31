#!/bin/bash
riscv32-unknown-elf-gdb main.elf -ex "set remotetimeout 2000" -ex "target extended-remote localhost:3333"
