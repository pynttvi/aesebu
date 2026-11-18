# USB to AES3 perfboard project

The XU316 receives stereo audio over USB and sends serial audio to the CS8406. The CS8406 encodes it as AES3, then a pulse transformer couples the balanced signal to a male XLR connector. Start at **48 kHz** with the PE-65612NL. The transformer board can be swapped later for a version specified for **192 kHz**.

## The five boards

| Module | What it does |
| --- | --- |
| [01 Power](01_power_module.md) | Takes regulated 5 V in and supplies 5 V, regulated 3.3 V, and common ground. |
| [02 I²C level shifter](02_line_shifter.md) | Translates SDA and SCL between the XMOS 3.3 V bus and the CS8406 5 V bus. |
| [03 CS8406 transmitter](03_cs8406_transmitter.md) | Receives audio clocks and data, handles I²C control, and drives the differential TXP/TXN pair. |
| [04 AES3 output](04_aes3_output.md) | Places the 56.2 Ω series resistor and pulse transformer on a removable board. |
| [05 XMOS interconnect](05_xmos_interconnect.md) | Breaks out the XU316's audio, reset, and I²C connections to the other boards. |

## Connect the boards

The cable colors below match the [combined OpenSCAD layout](00_project_assembly.scad). Each colored path represents a group of wires. Board spacing and cable paths are illustrative.

| Cable | From → to | Signals in connector order |
| --- | --- | --- |
| Red | 01 → 02 and 03 | 5 V, 3.3 V, GND. Split the power feed to both boards. |
| Green | 05 → 02 LV | SDA, SCL, GND |
| Green | 02 HV → 03 | SDA, SCL, GND |
| Orange | 05 → 03 | MCLK, GND, BCLK, LRCLK, DATA, RST |
| Purple | 03 → 04 | TXP, TXN |
| XLR pair | 04 → panel XLR | Pin 2 hot, pin 3 cold. Connect pin 1 and the shell to chassis at the connector. |

The XU316 and panel XLR connect off-board. Identify the exact XU316 header and confirm its signal mapping before wiring it to module 05. The separate module guides give the hole coordinates. Keep the audio clock harness and the transformer leads short.

## Bring it up in stages

1. **Power.** With the audio boards disconnected, feed module 01 from a current-limited 5 V supply. Check the 5 V and 3.3 V outputs.
2. **Control.** Check the idle I²C voltages on module 02. Connect module 03, then release reset and read register `0x7F` at 7-bit address `0x10`. Expect an upper nibble of `0xE`.
3. **Audio.** Check that the XMOS provides synchronous MCLK, BCLK, and LRCLK with the expected serial format. Configure the CS8406 and start at 48 kHz.
4. **AES3 output.** Connect module 04. Measure the differential output across a temporary 110 Ω load, then remove that load when connecting a receiver that already terminates the line. Verify playback at 48 kHz before trying higher rates.
5. **192 kHz upgrade.** Fit a daughterboard with a transformer specified for 192 kHz and repeat the output test. Verify the clock configuration and the waveform into 110 Ω at the new sample rate.

[Detailed engineering plan](xu316_cs8406_usb_aesebu_plan.md)
