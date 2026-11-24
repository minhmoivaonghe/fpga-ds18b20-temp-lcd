# FPGA DS18B20 Temperature Monitor with LCD Display

A Verilog design that reads temperature from a **DS18B20** digital sensor over the **1-Wire** protocol and shows the result on an **HD44780-compatible character LCD** (8-bit mode). The 1-Wire master is implemented entirely in hardware as an FSM on an Intel/Altera **Cyclone IV EP4CE6** FPGA, with no soft processor.

## Demo

'in folder docs'

## How It Works

The FPGA acts as the 1-Wire bus master and repeats this cycle forever:

```
Reset + presence check
   -> Skip ROM (0xCC) -> Convert T (0x44) -> wait 750 ms
   -> Reset + presence check
   -> Skip ROM (0xCC) -> Read Scratchpad (0xBE)
   -> read temperature bits (LSB first)
   -> wait 4 ms -> repeat
```

The raw 12-bit reading (1/16 °C per LSB) is converted to decimal digits and shown on the LCD with one decimal place, refreshed continuously.

## Architecture

All logic is in `src/lcd.v`, split into three modules:

| Module | Role |
|--------|------|
| `hehe` | 1-Wire master FSM: reset/presence, write slots, read slots, command sequencing, 750 ms conversion wait |
| `ds18b20_12bit_to_decimal` | Converts the 12-bit sensor value to hundreds / tens / units / one fractional digit and a sign flag |
| `lcd` (top level) | HD44780 initialization and display state machine; instantiates the two modules above |

```
                       +------------------------- FPGA -------------------------+
 DS18B20 <--- DQ ----> |  hehe (1-Wire FSM) --> 12-bit to decimal --> LCD FSM   | --> LCD
 (4.7k pull-up)        +--------------------------------------------------------+
```

## 1-Wire Timing (50 MHz system clock)

| Operation | Timing |
|-----------|--------|
| Reset pulse (low) | 500 us |
| Presence sample | about 60 us after release |
| Write 0 | 70 us low, 5 us release |
| Write 1 | 8 us low, 72 us release |
| Read slot | 4 us low, sample shortly after release, 55 us recovery |
| Conversion wait | 750 ms (12-bit resolution) |

## LCD Output

HD44780 in 8-bit mode, 2 lines. Line 1 shows the label `Nhiet do:` and the reading follows on the same line, for example `Nhiet do: 28.6`. The sign is shown for negative values and leading zeros are blanked.

## Hardware

| Item | Description |
|------|-------------|
| FPGA board | Intel/Altera Cyclone IV EP4CE6, 50 MHz clock |
| Sensor | DS18B20 on a single 1-Wire bus, 4.7 kOhm pull-up to 3.3 V |
| Display | HD44780-compatible character LCD (8-bit data bus, RW tied low) |
| Tool | Quartus II |

## Project Structure

```
fpga-ds18b20-temp-lcd/
├── src/
│   └── lcd.v        # hehe, ds18b20_12bit_to_decimal, lcd (top level)
├── docs/            # Demo video, photos, waveforms
└── README.md
```

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/minhmoivaonghe/fpga-ds18b20-temp-lcd.git
   ```
2. In Quartus II, create a project for **EP4CE6** and add `src/lcd.v`.
3. Set **`lcd`** as the top-level entity.
4. Assign pins:

   | Signal | Description |
   |--------|-------------|
   | `clock` | 50 MHz board clock |
   | `ds18b20` | Sensor data line (bidirectional) |
   | `LCD_EN`, `LCD_RS`, `LCD_RW` | LCD control |
   | `LCD_DATA[7:0]` | LCD data bus |
5. Compile, program the FPGA, and the temperature appears on the LCD.

## Limitations

- Uses Skip ROM, so only **one** DS18B20 may be on the bus.
- No CRC check on the scratchpad data.
- Display resolution is one decimal digit (the sensor provides 0.0625 °C).

## Author

**Do Thanh Minh** - Electrical/Electronic Engineering student, Industrial University of Ho Chi Minh City (IUH)
Interested in FPGA design and Design Verification.
GitHub: [@minhmoivaonghe](https://github.com/minhmoivaonghe)
