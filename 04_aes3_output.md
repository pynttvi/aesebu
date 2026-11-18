# 04 AES3 output

Build this on a removable piece of isolated-pad 2.54 mm perfboard. The **56.2 Ω series resistor stays with the transformer board**. The two removable connections are TXP/TXN from module 03 and the floating balanced pair to the panel XLR.

## Placement

Use 6 rows × 12 columns, viewed from the component side, with A at the top.

**T1 is the Pulse PE-65612NL transformer.** In the CAD model, look for the dark rectangular body marked **T1 / PE-65612NL**. Its primary faces the tan resistor and its secondary faces the XLR header.

| Part | Holes | Notes |
| --- | --- | --- |
| Input header | C1, D1 | TXP, TXN |
| R1 | C2, C5 | 56.2 Ω, 1%, in series with TXP |
| **T1 · PE-65612NL primary** | **C6, E6** | C6 = pin 2 (from R1), E6 = pin 1 (TXN) |
| **T1 · PE-65612NL secondary** | **C10, E10** | C10 = pin 4 (XLR pin 2), E10 = pin 3 (XLR pin 3) |
| XLR output header | C12, D12 | Pin 2 hot, pin 3 cold |

T1 tie points are laid out 10.16 × 5.08 mm apart as shown in the CAD model. Check the lead spacing and orientation against your actual PE-65612NL before soldering. If it fits, mount it directly. Otherwise secure it separately and use short leads to the labeled tie points. The XLR mounts off the perfboard.

## Underside wiring

| From | To |
| --- | --- |
| C1 (TXP) | C2 (R1 input) |
| C5 (R1 output) | C6 (T1 pin 2) |
| D1 (TXN) | E6 (T1 pin 1) |
| C10 (T1 pin 4) | C12 (XLR pin 2) |
| E10 (T1 pin 3) | D12 (XLR pin 3) |

Keep the primary and secondary wiring separated. Connect XLR pin 1 and the shell to chassis at the connector per the project plan. Keep these off the transformer signal pads. Use short paired wires for TXP/TXN and for the run to XLR pins 2/3.

## Test and swap

1. With power off and the cable unplugged, check continuity within each winding and confirm that there is no DC path between the two windings.
2. Start at **48 kHz**. Test the waveform across a temporary **110 Ω** load between XLR pins 2 and 3. Use a differential scope probe or an appropriate differential measurement setup. Remove the test termination when connecting a receiver that already terminates the line.
3. For 192 kHz, build a second board with the same connector order, its own matching resistor, and the footprint and shield connection specified for the new transformer. Recheck amplitude and pulse shape into 110 Ω after swapping boards.

[Pulse PE-65612NL datasheet](https://media.digikey.com/pdf/Data%20Sheets/Pulse%20PDFs/PE-65x12_Rev2006.pdf) · [Cirrus CS8406 datasheet, Figure 14](https://www.mouser.com/datasheet/2/76/CS8406_F6-1141075.pdf)
