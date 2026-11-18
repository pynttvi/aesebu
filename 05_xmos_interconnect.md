# 05 XMOS interconnect

This perfboard is a labeled harness termination for the XU316 module. The XMOS cable end can only be pinned once the exact module and header are confirmed. The perfboard connector coordinates below are independent of the XMOS connector.

## Placement and wiring

Use 6 rows × 12 columns on isolated-pad 2.54 mm perfboard. View from the component side, with A at the top. Feed the XMOS harness into row C. Use the matching output headers in rows A and F.

| XMOS signal to verify | Harness landing | Wire underneath to | Destination |
| --- | --- | --- | --- |
| Synchronous MCLK | C2 | A2 | Module 03 A10 |
| GND | C3 | A3 | Module 03 A11 |
| BCLK output | C4 | A4 | Module 03 A12 |
| LRCLK output | C5 | A5 | Module 03 A13 |
| I²S data output | C6 | A6 | Module 03 A14 |
| Reset GPIO, active low | C7 | A7 | Module 03 A15 |
| I²C SDA | C9 | F9 | Module 02 C1 |
| I²C SCL | C10 | F10 | Module 02 D1 |
| GND | C11 | F11 | Module 02 E1 |

A2–A7 form the six-pin audio/reset header. F9–F11 form the three-pin 3.3 V I²C header. Bond C3 and C11 with an underside wire routed out of the way of the other connections. Use insulated wires and solder only at the listed endpoints. Keep the audio harness short, especially MCLK, and route the clocks with a nearby ground return. If source series resistors are needed, place them at the XMOS end.

## Verify before connecting

1. Identify the exact XU316 board and firmware. Verify header pin numbers, 3.3 V logic, I²S output direction, and availability of a controllable reset GPIO. Leave the XMOS cable disconnected until this mapping is known.
2. Confirm the clocks share the same source and check MCLK at the actual output. The project plan calls for synchronous 22.5792/24.576 MHz for the 44.1/48 kHz families, subject to the clock ratios configured on the CS8406. Verify the selected rates at the receiving end.
3. With power off, check end-to-end continuity and inspect for swapped signals. Confirm the I²C cable goes to module 02 LV. Keep the XU316's power wiring separate from this signal harness.

[Project module identification and clock plan](xu316_cs8406_usb_aesebu_plan.md)
