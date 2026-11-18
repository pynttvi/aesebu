# 01 Power module

Build and test this module before connecting the CS8406, XMOS board, or AES3 transformer. The board takes regulated 5 V in and provides a 5 V branch, a regulated 3.3 V rail, and common ground.

## 1. Place the parts

This layout assumes **2.54 mm perfboard with individual copper pads**. View the board from the component side. Rows run A–F from top to bottom and columns run 1–12 from left to right. Reserve a 6 × 12 hole area. The regulator carrier can sit above or beside the board, with short wires to the connection points in the table.

| Part or connection | Holes | Notes |
| --- | --- | --- |
| 5 V input and ground | A1, F1 | Connect the bench supply here for the first test. |
| Ferrite bead FB1 | A1 to A3 | In series with 5 V. Use an axial leaded bead or pass a short insulated wire through a ferrite sleeve. |
| 5 V reservoir C1 | A4 (+), C4 (−) | 10–22 µF. Observe polarity if the capacitor is polarized. |
| Regulator VIN and GND | A6, F6 | Run short wires to the carrier. |
| Regulator 3.3 V output | C9 | Run a short wire from the carrier's OUT pin. |
| Output header, 3 pins | D12, E12, F12 | Label in order **5 V**, **3.3 V**, **GND**. |

FB1 spans 5.08 mm. A1 is the unfiltered input and A3 feeds the 5 V output, reservoir capacitor, and regulator. Fit FB1 in place of any existing jumper. Size the bead for the total current on the 5 V branch, including the current drawn by the 3.3 V regulator.

The C1 holes are 5.08 mm apart. If your capacitor needs a different spacing, fit it nearby and wire it to the same nets.

## 2. Wire the underside

| Wire | From | To | Result |
| --- | --- | --- | --- |
| 1 | A3 | A12 | 5 V rail. Solder at A3, A4, A6, and A12. |
| 2 | A12 | D12 | 5 V at the output header. |
| 3 | C9 | E12 | 3.3 V at the output header. |
| 4 | F1 | F12 | Ground bus. Solder at F1, F4, F6, and F12. |
| 5 | C4 | F4 | Ground for C1. |

Use insulated wire wherever runs cross. On individual-pad perfboard, each hole needs an explicit connection. When the board is flipped for soldering, the columns appear reversed. Mark A1 so you can track the orientation.

## 3. Connect the regulator

The owned **TLV75533PDRVR** requires a matching **DRV WSON-6 carrier with an exposed-pad land**. If you use a preassembled 3.3 V regulator module, follow its VIN, OUT, and GND labels and verify it accepts a 5 V input.

| TLV75533PDRVR pin | Connect to |
| --- | --- |
| 6 · IN | A6. Fit CIN from IN to GND at the carrier. |
| 4 · EN | Pin 6 on the carrier for always-on operation. |
| 3 · GND and exposed pad | Carrier ground copper, then F6. |
| 1 · OUT | C9. Fit COUT from OUT to GND at the carrier. |
| 2 and 5 · NC | Leave open. |

Use **2.2 µF X7R ceramic** for CIN and COUT, with short connections to the regulator pins. Check the capacitor's DC-bias data so it meets TI's effective-capacitance requirement. For a preassembled module, use the module's capacitor guidance.

[TI TLV755P datasheet](https://www.ti.com/lit/ds/symlink/tlv755p.pdf)

## 4. Test before connecting the audio board

| Step | Check | Expected result |
| --- | --- | --- |
| 1 | With power off, check continuity from input ground F1 to output ground F12. Check continuity through FB1 from A1 to A3. Check for solder bridges between the rails and ground or between the two rails. | Common ground and FB1 each have continuity. There is no sustained short between rails or from either rail to ground. |
| 2 | Feed A1 and F1 from a current-limited 5 V bench supply with the audio boards disconnected. Measure D12 and E12 relative to F12. | D12 reads near 5 V. E12 reads near 3.3 V. |
| 3 | If you have a 330 Ω resistor, connect it across E12 and F12 as a temporary test load. | E12 stays near 3.3 V with roughly 10 mA of load. |

When you connect the CS8406, route 5 V to VL and 3.3 V to VD. Place the 100 nF bypass capacitors at the CS8406 supply pins. Use the XMOS module as the eventual 5 V source only after confirming its exposed supply connection and available current. Keep the 3.3 V output local to the AES circuitry.

[Project power plan](xu316_cs8406_usb_aesebu_plan.md#power)
