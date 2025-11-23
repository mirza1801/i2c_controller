#  I²C Controller — Master and Slave Simulation (SystemVerilog)

This repository demonstrates an I²C (Inter-Integrated Circuit) **Master Controller** in Verilog, 
paired with a simple **Behavioral Slave Model** for simulation and waveform analysis.  
The design implements both **WRITE** and **READ** transactions with acknowledgment handling.

---

## Simulation Output (Expected Console Log)

```
Starting WRITE
Write Done. ACK = 1
Starting READ
Read Done. ACK = 1, Data = 00001010
```

- `ACK = 1` → Slave acknowledged the transaction.  
- `Data = 00001010` → Data `0x0A` read successfully from the slave.

---

## Folder Structure

```text
i2c_controller/
├─ rtl/
│  └─ i2c_master.v               # RTL implementation of the I²C master
├─ models/
│  └─ i2c_slave_model.v          # Behavioral slave (ACK + fixed read data)
├─ tb/
│  └─ i2c_master_tb.v            # Testbench (WRITE then READ)
├─ logs/
│  └─ i2c.log                    # Full simulator output log
├─ docs/
│  ├─ simulation_result.png      # Console screenshot
│  └─ waveform.png               # GTKWave screenshot
├─ Makefile                      # Build & run automation (VCS + Icarus)
├─ .gitignore                    # Ignore sim artifacts
└─ README.md                     # Project documentation
```

---

## File Descriptions

| File | Description |
|------|--------------|
| **rtl/i2c_master.v** | Implements the I²C master logic with FSM controlling `SCL` and `SDA` lines, generating Start/Stop, ACK detection, and READ/WRITE sequences. |
| **models/i2c_slave_model.v** | Behavioral model of an I²C slave. Sends an ACK and drives a fixed response byte (`0xAA`) during reads. |
| **tb/i2c_master_tb.v** | Testbench controlling reset, start signals, and executing one WRITE and one READ operation. Dumps waveforms for GTKWave. |
| **logs/i2c.log** | Console log from VCS run — shows transaction messages, ACKs, and final read data. |
| **docs/waveform.png** | Screenshot from GTKWave showing signal transitions for address, data, and ACK phases. |
| **Makefile** | Build automation file — supports both Synopsys VCS and Icarus Verilog. |
| **README.md** | Documentation for this project (you’re reading it). |

---

## How to Build & Run

### •Using Synopsys VCS
```bash
# 1) Compile
vcs -sverilog -full64 -debug_access+all -timescale=1ns/1ps \
    rtl/i2c_master.v models/i2c_slave_model.v tb/i2c_master_tb.v \
    -top i2c_master_tb -o simv

# 2) Run simulation (log stored in logs/i2c.log)
./simv -l logs/i2c.log -no_save
```

### •Using Icarus Verilog
```bash
# Compile (SystemVerilog-2012)
iverilog -g2012 -o simv rtl/i2c_master.v models/i2c_slave_model.v tb/i2c_master_tb.v

# Run simulation
vvp simv
```

> The waveform is dumped to `dump.vcd`  
> (ensure `$dumpfile("dump.vcd"); $dumpvars(0, i2c_master_tb);` exist in the testbench)

To view the waveform:
```bash
gtkwave dump.vcd &
```

---

## Makefile Shortcuts

```bash
make run           # Compile & run with Synopsys VCS
make run-iverilog  # Compile & run with Icarus Verilog
make clean         # Delete build artifacts & waveforms
```

---

## Features

- Fully synthesizable **I²C Master RTL**
- Behavioral **Slave Model** for simulation
- Verifies both WRITE and READ transfers
- Works with **Synopsys VCS** and **Icarus Verilog**
- Includes waveform and log visualization

---

## Results Preview

| Screenshot | Description |
|-------------|-------------|
| ![Simulation Result](docs/simulation_result.png) | Console log showing successful WRITE and READ operations |
| ![Waveform](docs/waveform.png) | GTKWave view of `SCL`, `SDA`, `ACK`, and data transfers |

---

## Requirements

| Tool | Purpose |
|------|----------|
| **Synopsys VCS** | Primary simulator |
| **Icarus Verilog** | Open-source alternative |
| **GTKWave** | View waveforms (`.vcd` or `.vpd`) |
| **MobaXterm / Git Bash / Linux shell** | Command execution |

---


