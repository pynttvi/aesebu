# 02 I²C level shifter

Use two channels of a bidirectional BSS138 I²C breakout to connect the 3.3 V XMOS control bus to the CS8406's 5 V control bus. This module carries SDA and SCL. The I²S signals have their own wiring.

## 1. Place the headers

Use a **6 × 12 area of 2.54 mm perfboard with individual pads**. View from the component side, with A at the top and column 1 at the left. Mount or secure the breakout nearby and connect it by short wires. Its footprint and header order depend on the board you buy.

| Header | Holes in pin order | Labels |
| --- | --- | --- |
| Power from module 01 | A5, A6, A7 | 5 V, 3.3 V, GND |
| XMOS control bus | C1, D1, E1 | SDA, SCL, GND |
| CS8406 control bus | C12, D12, E12 | SDA, SCL, GND |

The power header follows the 5 V, 3.3 V, GND order in [01_power_module.md](01_power_module.md). Check orientation at both ends of the cable.

## 2. Wire the breakout

The table assumes breakout channels labeled LV1/HV1 and LV2/HV2. If your board uses different markings, identify the matching low-side and high-side pins for each channel.

| Perfboard hole | Breakout pin | Signal |
| --- | --- | --- |
| A5 | HV | 5 V from module 01 |
| A6 | LV | 3.3 V from module 01 |
| A7 | GND | Common ground. If the breakout has two GND pins, wire both to common ground. |
| C1 | LV1 | XMOS SDA |
| D1 | LV2 | XMOS SCL |
| C12 | HV1 | CS8406 SDA, pin 1 |
| D12 | HV2 | CS8406 SCL, pin 28 |

On the underside, run insulated ground wires **A7 → F7**, **F1 → F12**, **F1 → E1**, and **F12 → E12**. Solder the ground bus at F1, F7, and F12. Every connection on isolated-pad perfboard needs a wire. Mark A1 before turning the board over.

Check which pull-ups are already fitted on the breakout and XMOS board. Each of the four signal nodes needs a pull-up to its own side's rail. If a pull-up is missing, the project plan starts with **4.7 kΩ**. Existing pull-ups in parallel reduce the total resistance, so check the total before adding more.

## 3. Test the module

| Step | Check | Expected result |
| --- | --- | --- |
| 1 | With power off, check ground continuity and inspect for shorts. | A7, E1, and E12 have continuity. The 5 V and 3.3 V rail headers have no sustained short between them or to ground. |
| 2 | Power the module from module 01 with the XMOS and CS8406 disconnected. Measure the four signal holes relative to GND. | C1 and D1 idle near 3.3 V. C12 and D12 idle near 5 V. |
| 3 | With the breakout powered and the endpoints still disconnected, briefly pull one signal low through 330 Ω. Check the corresponding signal on the other side. Repeat from each side for SDA and SCL. | The matching node falls toward ground and returns high on release. The other channel stays high. |
| 4 | Power down, connect both endpoints, then power up and try an I²C read of CS8406 register 0x7F. | The upper nibble of the chip ID reads 0xE once the CS8406 is powered, out of reset, and configured for I²C. |

[Project control bus wiring](xu316_cs8406_usb_aesebu_plan.md)
