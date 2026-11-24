# FPGA DS18B20 Temperature Monitor with LCD Display

A hardware design in Verilog that reads temperature from a **DS18B20** digital sensor over the **1-Wire** protocol and displays the result on a character **LCD**, implemented on an Intel/Altera **Cyclone IV EP4CE6** FPGA.

## Demo

[![Demo video](https://img.youtube.com/vi/YOUR_VIDEO_ID/maxresdefault.jpg)](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)

> Watch the full demo on YouTube: https://www.youtube.com/watch?v=YOUR_VIDEO_ID

## Overview

The FPGA acts as a 1-Wire master. It periodically issues a temperature conversion command to the DS18B20, reads back the raw 16-bit result, converts it to a decimal value, and drives an LCD to show the temperature in real time.

## Features

- Bit-accurate 1-Wire master implemented in hardware (reset/presence, write slot, read slot)
- FSM-based control of the DS18B20 command sequence (Skip ROM, Convert T, Read Scratchpad)
- Binary-to-decimal conversion of the temperature reading
- LCD driver module for displaying the temperature
- Fully synchronous design, single system clock

## Hardware

| Item | Description |
|------|-------------|
| FPGA board | Intel/Altera Cyclone IV EP4CE6 |
| Sensor | DS18B20 (1-Wire digital thermometer) |
| Display | Character LCD |
| Tool | Quartus II |

## System Architecture

```
          +---------------------------------------------+
          |                    FPGA                     |
          |                                             |
DS18B20 <-+-> 1-Wire Master FSM --> BCD Converter --> LCD Driver --> LCD
 (DQ)     |                                             |
          +---------------------------------------------+
```

## Project Structure

```
fpga-ds18b20-temp-lcd/
├── src/        # Verilog source files (1-Wire master, LCD driver, top level)
├── docs/       # Block diagrams, waveforms, photos
└── README.md
```

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/minhmoivaonghe/fpga-ds18b20-temp-lcd.git
   ```
2. Open Quartus II and create a new project targeting **EP4CE6**.
3. Add all files from `src/` and set the top-level entity.
4. Assign pins for the clock, DS18B20 data line (with a 4.7 kΩ pull-up to 3.3 V) and LCD.
5. Compile and program the board.

## Results

The measured temperature is shown on the LCD and updates continuously. See the demo video above.

## Author

**Do Thanh Minh** — Electrical/Electronic Engineering student, Industrial University of Ho Chi Minh City (IUH)
Interested in FPGA design and Design Verification.
GitHub: [@minhmoivaonghe](https://github.com/minhmoivaonghe)
