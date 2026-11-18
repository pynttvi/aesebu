# 03 CS8406 transmitter

Use a **0.65 mm TSSOP-28 to DIP adapter**. The layout assumes isolated-pad 2.54 mm perfboard, 18 columns × 11 rows (A–K). Coordinates are from the component side, with A at the top. Use an adapter with **15.24 mm between header rows** for direct mounting. Verify continuity from each IC pad to its numbered header pin before soldering the adapter to the board.

## Placement and headers

| Part | Holes, in order | Signals or orientation |
| --- | --- | --- |
| CS8406 adapter | C3–C16 and I3–I16 | C3 is pin 1, C16 is pin 14, I16 is pin 15, I3 is pin 28 |
| Power from 01 | A3–A5 | 5 V, 3.3 V, GND |
| I²C from 02 HV | K3–K5 | SDA, SCL, GND |
| Audio and reset from 05 | A10–A15 | MCLK, GND, BCLK, LRCLK, DATA, RST |
| TX to 04 | K7–K8 | TXP, TXN |
| Ground bus | B3–B16 | Solder the ground taps below |
| VD bypass | C8 to B8 | 100 nF ceramic |
| VL bypass | I8 to I9 | 100 nF ceramic |
| Reset pulldown | C11 to B11 | 10 kΩ |
| User-bit pulldown | I11 to H11 | 47 kΩ, with H11 wired to I9 |

## Point-to-point wiring

| From | To |
| --- | --- |
| A3 (5 V) | I8 (23, VL) |
| A4 (3.3 V) | C8 (6, VD) |
| A5, K5, A11 and I9 (22, GND) | B5, B5, B11 and B9 respectively |
| C4–C7, C9–C10, C12–C13 | Ground each to the B-row hole in the same column (pins 2–5, 7–8, 10–11) |
| I4, I7, I13–I15 | Ground each to the B-row hole in the same column (pins 27, 24, 18–16) |
| K3 (SDA), K4 (SCL) | C3 (1), I3 (28) |
| A10 (MCLK) | I10 (21, OMCK) |
| A12 (BCLK), A13 (LRCLK), A14 (DATA) | C15 (13), C14 (12), C16 (14) |
| A15 (RST) | C11 (9) |
| K7 (TXP), K8 (TXN) | I5 (26), I6 (25) |

Use insulated wires where runs cross. The ground bus needs a solder joint at every tap. If the adapter allows, put the bypass capacitors directly at the IC supply pads and return them to pin 22 by the shortest practical path. Confirm that the high-side I²C pull-ups are already on module 02 before adding any. Leave INT (pin 19) open. If firmware uses TCBL (pin 15) as an undriven input, fit 47 kΩ from I16 to ground.

## Bring-up

1. With power off, verify the adapter orientation, ground straps and supply isolation. With module 01 connected, confirm VD is 3.3 V, VL is 5 V and RST is low.
2. Connect the 5 V side of module 02. Release reset with a verified 3.3 V GPIO after a low pulse of at least 200 µs. Read register `0x7F` at 7-bit I²C address `0x10`. The upper nibble should be `0xE`. You can check the control port before enabling RUN.
3. Connect the verified audio harness from module 05. Check clock rates and serial format with the CS8406 configured as a slave before enabling transmission.

[Cirrus CS8406 datasheet](https://www.mouser.com/datasheet/2/76/CS8406_F6-1141075.pdf) · [Project clock and firmware plan](xu316_cs8406_usb_aesebu_plan.md)
