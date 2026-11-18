# Agent Implementation Plan — XU316 USB Audio → CS8406 AES/EBU (Software-Controlled)

**Revision:** 1.0 — 2026-11-18  
**Status:** Engineering handoff / pre-fabrication design; **NOT** a certified or fabrication-approved schematic.  
**Target:** Stereo USB Audio Class 2 playback, 24-bit PCM, 44.1–192 kHz, to transformer-isolated balanced AES3 XLR for Genelec speakers.  
**Architecture:** Existing **XMOS XU316 USB-to-I²S board** → **CS8406-CZZ** → transformer → XLR. **No CS8422. No AM26LS31 line driver. No Raspberry Pi.**

## 0. Mission and operating rules for the agent

Produce a **reviewable, reproducible KiCad project**, complete electrical connection documentation, a BOM with sourcing statuses, and an XMOS firmware implementation plan/source scaffolding that configures the CS8406 over I²C as USB sample rates change.

1. **Only generate or edit project files.** Do not flash firmware, modify operating-system settings, order parts, power real hardware, or start fabrication automatically. The owner runs all physical and deployment actions.
2. **Use manufacturer datasheets as primary electrical authority.** Compare every pin, register, package, and supply condition. Where a board or component is unidentified, label it **UNVERIFIED** and provide a test/decision gate rather than guessing.
3. Do **not** call an electrical schematic 'production-ready' until ERC, footprint/pin verification, clock compatibility, power-budget review, and actual measurements are complete.
4. Do **not** copy the earlier generated image schematic: it contains obsolete assumptions. In particular, omit the 3.3 V-only AES output, two 22 Ω output resistors, and the AM26LS31.
5. Prioritize a working **48-kHz prototype**, then verify 44.1–96 kHz, then 176.4/192 kHz **only with an appropriately rated transformer**.
6. Record all open decisions in `docs/assumptions-and-blockers.md`. Do not invent the pinout of the particular XU316 module or claim access to vendor firmware without evidence.

## 1. Project hardware inventory

### Already held / previously selected

- **Cirrus Logic CS8406-CZZ**, 28-pin TSSOP digital audio transmitter (confirm actual top marking/package).
- **XMOS XU316 USB Audio board/module**, exact manufacturer, hardware revision, connector breakout, and firmware build **not yet confirmed**.
- **Pulse PE-65612NL** 1:1 through-hole AES transformer — good development starting point, **not rated for 192-kHz AES3** (its documentation gives 1–7 Mb/s).
- **Neutrik NC3MAH-LR**, male 3-pin XLR output connector.
- **TI TLV75533PDRVR** 3.3-V LDO. Confirm the exact **DRV 6-pin package** and pin numbers in the current TI datasheet/library footprint.
- Ferrite bead(s), 100 nF X7R, 1 µF X7R, 10 µF and 22 µF reservoir capacitors.
- 0603 22 Ω (Vishay `CRCW060322R0FKEA` or Panasonic `ERJ3EKF22R0V`).
- 0603 4.7 kΩ (Panasonic `ERJ3EKF4701V`, Vishay `CRCW06034K70FKEA`, or Yageo `RC0603FR-074K7L`).
- 0603 10 kΩ (Vishay `CRCW060310K0FKEA` or Yageo `RC0603FR-0710KL`).
- PESD5V0H1BSFYL TVS parts (optional connector-side ESD footprints; validate placement and grounding before fitting).
- Existing 22.5792 / 24.576 MHz oscillators are **not required** if the XU316 module provides correctly synchronized divided audio MCLK.

### Add / confirm before building

- **56.2 Ω, 1%, 0603/0805 resistor**, one for AES3 output source impedance (`R_AES`).
- **BSS138 ×2** or an explicitly suitable **PCA9306** bidirectional I²C-level translator (3.3 V ↔ 5 V).
- **4 × 4.7 kΩ I²C pull-ups** initially budgeted (two each side); reduce or omit duplicates if the XU316 board already has pull-ups. Check bus capacitance.
- **47 kΩ ×1** for CS8406 U pin; optional second 47 kΩ for TCBL if configured as an input.
- **1 kΩ ×1** optional series resistor on reset; **10 kΩ ×1** reset pulldown.
- 0 Ω jumpers / DNP signal termination options and accessible test pads.
- **192-kHz-rated 1:1 AES3 transformer**, such as a verified Scientific Conversion SC947 family member **only after reading its exact part datasheet, winding connections and footprint**. Do not claim PE-65612NL is 192-kHz-capable.
- Connector for the exact XU316 module; only select after checking actual dimensions, orientation and 5-V availability.
- If there is no safe accessible 5-V output on the XU316 module, devise a documented USB-power branch/power-path rather than tapping arbitrary USB pads.

## 2. Functional design

```text
USB HOST (Windows/Linux/macOS)
         |
         | USB Audio Class 2, stereo PCM
         v
+--------------------------+
| Existing XMOS XU316      |
| USB audio firmware       |
| I²S master, clock master |
+------+-------------------+
       |     |       |       |         |         |
       |     |       |       |         |         +-- RESET GPIO
       |     |       |       |         +------------ I²C SDA/SCL (3.3 V)
       |     |       |       +---------------------- MCLK/2, same domain as I²S
       |     |       +------------------------------ LRCLK
       |     +-------------------------------------- BCLK
       +-------------------------------------------- DATA
                    |                     |
                    v                     v
              3.3-V I²S              I²C 3.3→5 V
                    |                     |
                    +--------+------------+
                             v
                    +----------------+
                    | CS8406-CZZ     |  VD=3.3 V, VL=5 V
                    | software mode  |  7-bit I²C address 0x10
                    +-------+--------+
                            | TXP/TXN (built-in differential driver)
                    56.2-Ω series source matching
                            |
                    1:1 AES transformer
                            |
                    XLR-3 male (pin 2 hot, pin 3 cold, pin 1 chassis)
                            |
                         GENELEC
```

### Scope

- Audio playback only: **USB → I²S → AES3**.
- USB PCM playback at 44.1, 48, 88.2, 96, 176.4, 192 kHz, **provided the actual XMOS board/firmware supports each mode**.
- Stereo, 24-bit meaningful audio samples; verify 32-bit I²S slot width if used by the XMOS audio application.
- No sample-rate converter; preserve the host sample rate on AES3 with **fully synchronous MCLK/BCLK/LRCLK**.
- No analog DAC, microphone, recording interface, AES input, or network audio in this revision.

## 3. Mandatory source material and verification checkpoints

Read and archive URLs/revisions (do not copy entire proprietary datasheets into the repository):

1. CS8406 datasheet **DS580F6**:  
   https://www.mouser.com/datasheet/2/76/CS8406_F6-1141075.pdf  
   Examine Figures **5** (software-mode connection), **14** (professional AES output), software pin description, register map, clocks, I²C electrical/timing, serial-audio timing, supply/reset.
2. XMOS reference documentation, particularly `lib_xua`, `AudioHwInit`, `AudioHwConfig`, I²S master clocks and board-support code:  
   https://www.xmos.com/documentation/  
   https://www.xmos.com/documentation/XM-012296-UG/html/doc/rst/sw_audio.html
3. **Only if the owned board is confirmed to be Phaten A316-HF-I2S-V1:**  
   https://www.phaten-audio.com/en/dev_doc/evb/a316_hf_i2s_v1/datasheet/  
   Its published audio header has DATA/BCLK/LRCK, I²C and **Expansion 2 MCLK/2 (22.5792/24.576 MHz)**. **Do not apply its physical header numbers to an unconfirmed Amazon/generic board.**
4. Pulse PE-65612NL 1:1 transformer datasheet:  
   https://media.digikey.com/pdf/Data%20Sheets/Pulse%20PDFs/PE-65x12_Rev2006.pdf  
   Explicitly check the pin-number/dot diagram and documented **1–7 Mb/s** operating rate.
5. TI TLV755P family / exact `TLV75533PDRVR`:  
   https://www.ti.com/product/TLV755P  
   Verify **DRV footprint**, VIN/EN/GND/VOUT/NC and capacitor minimums.
6. Selected I²C translator datasheet: TI PCA9306 or canonical MOSFET I²C level translator application circuit; validate VOL margins and presence of multiple pull-ups.
7. Neutrik NC3MAH-LR manufacturer mechanical drawing and pad numbering; check the XLR mating-view orientation rather than assuming the footprint drawing is front-view.
8. Manufacturer transformer datasheet for **each** alternative supporting 192-kHz AES3; verify bandwidth/bit rate, ratio, isolation, return loss and footprint.

## 4. Detailed CS8406 wiring (pin-level schematic specification)

**IC:** U1 CS8406-CZZ, **TSSOP-28, 0.65-mm lead pitch**. Pin numbers below checked against DS580F6 software-mode pin diagram. **Implement these as named nets in KiCad**, not as a hand-drawn pictorial wiring sketch.

| Pin | Function | Design connection |
|---:|---|---|
| 1 | SDA / CDOUT | I²C SDA **5-V side** of translator; 4.7-kΩ pull-up to `+5V_AES` |
| 2 | AD0 / CS | GND, select I²C address bit 0 = 0; ensure no SPI-select glitch at power-up |
| 3 | AD2 | GND, address bit 2 = 0 |
| 4 | RXP | GND for no bypass-input operation (verify unused-input guidance) |
| 5 | TSTN | **GND mandatory** |
| 6 | VD | `+3V3_AES` with local 100 nF to GND |
| 7 | TEST | GND (do not float) |
| 8 | TEST | GND (do not float) |
| 9 | RST | `CS_RST` from XMOS, reset-low until rails and clocks are ready; 10-kΩ pulldown |
| 10 | TEST | GND (do not float) |
| 11 | TEST | GND (do not float) |
| 12 | ILRCK | `I2S_LRCLK` from XMOS, optional 22-Ω source-end resistor |
| 13 | ISCLK | `I2S_BCLK` from XMOS, optional 22-Ω source-end resistor |
| 14 | SDIN | `I2S_DATA` from XMOS, optional 22-Ω source-end resistor |
| 15 | TCBL | Keep defined low via optional 47-kΩ pulldown if input; do not drive against configured output |
| 16 | TEST | GND (do not float) |
| 17 | TEST | GND (do not float) |
| 18 | TEST | GND (do not float) |
| 19 | INT | NC in Rev 1; optional test pad only; configure masks accordingly |
| 20 | U | 47-kΩ pulldown to GND when not supplying U bits |
| 21 | OMCK | `AUDIO_MCLK_DIV2` (22.5792 / 24.576 MHz) from synchronous XMOS board output; optional source-end 22 Ω |
| 22 | GND | low-impedance digital ground plane |
| 23 | VL | `+5V_AES` with local 100 nF to GND |
| 24 | H/S | **GND** for software-controlled mode |
| 25 | TXN | transformer primary leg B **without 22-Ω output resistor** |
| 26 | TXP | **56.2-Ω 1% series resistor** then transformer primary leg A |
| 27 | AD1 / CDIN | GND, address bit 1 = 0 |
| 28 | SCL / CCLK | I²C SCL **5-V side** of translator; 4.7-kΩ pull-up to `+5V_AES` |

> `VD` is the 3.3-V core supply and `VL` is the 5-V I/O/line-driver supply. The CS8406 data sheet specifies the control-port SDA/SCL pull-ups to **VL**, so level translation is needed before connecting to a 3.3-V XMOS interface.

### I²C

- Grounding AD2/AD1/AD0 yields **7-bit address `0x10`**, NOT `0x20` as a 7-bit address; `0x20` is the address+write R/W byte.
- Restrict I²C to **100 kHz until explicitly verified** with the CS8406 timing table and XU316 API.
- Q1/Q2 BSS138 classic bidirectional translator: source-side node and gate referenced to +3.3 V; drain-side node to +5 V; separate pull-ups to each rail on both SDA/SCL. Ensure **the module has no unexpected pull-ups to a conflicting supply**.
- Alternate: PCA9306 implementation with datasheet-specified bias/enable wiring; do not mix transistor and IC topologies.
- Reserve test points for SDA/SCL on both voltage domains.

### Reset

- Pull RST low with **10 kΩ to GND** so a high-Z/busy XMOS never enables the transmitter prematurely.
- XU316 GPIO drives high to **3.3 V** after clocks/rails stabilize; one optional **1-kΩ** series resistor near GPIO.
- Ensure the selected GPIO is safe during reset/DFU/boot, has no conflicting peripheral and can be controlled by the firmware build.
- Minimum reset-low width: **200 µs** per datasheet. Prefer ≥1 ms in firmware with measured clocks ready.
- If the XU316 module has no accessible reset GPIO, treat as a blocking design decision and document alternative verified control path.

### Power

```text
XU316 module / USB-provided +5 V (ONLY if exposed and rated)
    → input protection/filtering (ferrite chosen for AES branch, not USB power trunk)
    → +5V_AES (CS8406 VL pin 23)
    → TLV75533 VIN/EN → +3V3_AES (CS8406 VD pin 6)
Common ground: XU316 module GND ↔ AES daughterboard digital GND
Chassis: XLR pin 1 and shell, short local chassis path separate from digital audio ground
```

- Add **100 nF** at both CS8406 supply pins; use the exact TI-specified **≥1-µF effective input and output capacitors** for the LDO, allowing for DC-bias derating. Example provision: 1 µF at VIN, 1 µF + 100 nF at VOUT, optional 10 µF reservoir at +3V3_AES; 10–22 µF at +5V_AES entrance.
- Check real **DRV-6 power-pad footprint and thermal/ground pad** in TI datasheet. Never infer TLV755 pin numbers from another package variant.
- Do not back-feed 3.3 V into the XMOS module. Use local `+3V3_AES` only for the AES daughterboard and translator low-side pull-ups unless board documentation specifically establishes compatibility.
- Before finalizing, measure XU316 power feed availability, USB port current budget, voltage on 5-V branch, and current consumption at 192 kHz.
- Size the ferrite current rating for **this AES daughterboard branch**, not the entire upstream USB board.

## 5. Professional AES3 output and transformer

CS8406 has **built-in differential TXP/TXN** and drives the transformer directly: **no AM26LS31**.

```text
CS8406 pin 26 TXP ── R_AES 56.2 Ω (1%) ── transformer PRIMARY A
CS8406 pin 25 TXN ─────────────────────── transformer PRIMARY B
transformer SECONDARY A ────────────────── XLR pin 2 (hot)
transformer SECONDARY B ────────────────── XLR pin 3 (cold)
XLR pin 1 / connector shell ─────────────── CHASSIS
```

The source matching resistor derives from the professional CS8406 Figure 14: `110 Ω − (R_TXP + R_TXN)` with approx. 26.5 Ω per driver at `VL=5 V` → **~57 Ω**, thus **56.2 Ω 1%**.

For **PE-65612NL** datasheet schematic: 1:1 windings on **pins 2–1 and 4–3** (pin 1 and pin 3 dotted). A proposed polarity-preserving mapping is primary **2 (TXP via resistor), 1 (TXN)** and secondary **4 (XLR pin 2), 3 (XLR pin 3)**. **Verify physical lead orientation and phase against the actual part/footprint before releasing a PCB.**

- AES3 line impedance target **110 Ω balanced**; measure output across an external **110-Ω termination** and inspect pulse shape/eye pattern, do not guess unloaded amplitude.
- **No permanent 110-Ω resistor across XLR output:** the receiving Genelec device provides load termination.
- Use male XLR with **pin 2 hot, pin 3 cold, pin 1 chassis/shield**, verify connector mechanical pin numbering.
- Provide **optional DNP** low-capacitance ESD protection pads near XLR pin 2 and 3. Review whether protection returning to chassis compromises transformer isolation or affects signal before populating.
- Keep transformer/XLR close together, avoid routing high-frequency clocks beside the secondary, control return paths, and maintain primary–secondary isolation clearances.

### Transformer bandwidth gate

AES3 biphase line rate is `64 × Fs`:

| Fs | AES3 nominal bit rate | PE-65612NL manufacturer 1–7 Mb/s rating |
|---:|---:|---|
| 44.1 kHz | 2.8224 Mb/s | within stated range |
| 48 kHz | 3.072 Mb/s | within stated range |
| 88.2 kHz | 5.6448 Mb/s | within stated range |
| 96 kHz | 6.144 Mb/s | within stated range |
| 176.4 kHz | 11.2896 Mb/s | **out of rating** |
| 192 kHz | 12.288 Mb/s | **out of rating** |

The CS8406 and clocks can support 192 kHz, **but this particular transformer does not have a manufacturer's 192-kHz performance claim**. Make full-rate output conditional on selecting a transformer independently validated for at least 12.288 Mb/s / 192-kHz AES3 and checking output compliance in situ.

## 6. Clocking — mandatory cross-check

XMOS must generate **I²S BCLK/LRCLK and CS8406 OMCK coherently**. Never combine an independent oscillator with unrelated XMOS frame clocks. No ASRC is installed in this revision.

For a board exposing `MCLK/2 = 22.5792 MHz` for 44.1 family or `24.576 MHz` for 48 family:

| USB sample rate Fs | CS8406 OMCK | Ratio | CS8406 reg 0x04 CLK1:CLK0 | reg 0x04 RUN=0 | RUN=1 |
|---:|---:|---:|---|---|---|
| 44,100 | 22.5792 MHz | 512× | `10` | `0x20` | `0x60` |
| 48,000 | 24.5760 MHz | 512× | `10` | `0x20` | `0x60` |
| 88,200 | 22.5792 MHz | 256× | `00` | `0x00` | `0x40` |
| 96,000 | 24.5760 MHz | 256× | `00` | `0x00` | `0x40` |
| 176,400 | 22.5792 MHz | 128× | `11` | `0x30` | `0x70` |
| 192,000 | 24.5760 MHz | 128× | `11` | `0x30` | `0x70` |

At 176.4/192 kHz, the transformer must be upgraded/validated as described above.

The published **Phaten A316-HF-I2S-V1** has a nominal 45.1584/49.152-MHz `MCLK` and a 22.5792/24.576-MHz `MCLK/2` on Expansion 2. If this is the actual board, connect CS8406 OMCK to **`MCLK/2`, not undivided `MCLK`**. If your board is another XU316 module, inspect its published board schematic and scope before mapping any pins.

Confirm **BCLK** and I²S framing: 64×Fs is typical for 2 × 32-bit slots, but the firmware/configuration may differ. Validate SDIN alignment, CS8406 I²S slave rising-edge sample, and right/left channel polarity with an oscilloscope/logic analyzer.

## 7. CS8406 firmware — software-controlled from XMOS

### Register settings (datasheet-backed **starting point**, not an untested binary release)

| Register | Suggested initialization | Why |
|---|---|---|
| `0x01` Control 1 | `0x10` initially | MUTEAES=1 during configuration (TCBL remains input) |
| `0x02` Control 2 | `0x00` | stereo mode |
| `0x03` Data Flow | `0x00` | normal SDIN → encoder → differential output |
| `0x04` Clock Control | rate-specific `0x20/0x00/0x30` with RUN=0; then `0x60/0x40/0x70` | clock ratio and RUN |
| `0x05` Serial Format | `0x05` as **initial I²S slave hypothesis** | SIMS=0, SIDEL=1, SILRPOL=1, 24-bit default |
| `0x20`–`0x37` | constructed AES3 Channel Status block | professional PCM, actual sample rate/word length/channel mode |
| `0x7F` | read-only, upper nibble `0xE` expected | verify chip identity; retain low-nibble revision |

`0x05=0x05` must be confirmed against actual XU316 I²S waveform (clock edge, WS polarity, data delay). **Do not assume 32-bit USB container means 32-bit AES3 audio**; format must provide 24 meaningful bits where supported.

**Critical sequence detail:** CS8406 states its C/U data buffers are **not writable with RUN=0**. Firmware must (a) mute, (b) stop RUN, (c) reconfigure clocks/rate, (d) set RUN=1 once stable, (e) program AES3 channel status with proper buffering/block transfer, then (f) unmute after block synchronization. Do not blindly copy the old startup pseudocode that attempted C-buffer writes while RUN=0.

### Required XMOS changes

1. Identify the **actual XU316 board hardware and firmware repository/toolchain**. Establish whether stock vendor firmware can be rebuilt/flashed and which GPIOs/I²C ports are exposed.
2. Start from a licensed, compatible **XMOS USB Audio Class 2 (`lib_xua`) example** for that XU316 hardware. Do not assume a marketplace module uses the Phaten reference firmware.
3. Implement a **CS8406 I²C driver**, 100-kHz transport, address 0x10, `read_id()`, `write_reg()`, burst channel-status writes, and bounded I²C retry with error reporting.
4. Integrate with the audio hardware configuration callback, e.g. `AudioHwInit`/`AudioHwConfig(sampleFreq, mClk, ...)` **according to the actual version of XMOS source used**.
5. Ensure the MCLK family is selected by XMOS audio firmware before CS8406 RUN is enabled. Calculate and assert `OMCK / Fs` ∈ {128,256,384,512} for the configured route.
6. Use reset GPIO on power-up and during unrecoverable I²C fault; initial output muted; successful chip-ID/readback required before signal transmission.
7. On sample-rate change, mute, stop RUN, wait for new synchronous clocks, set ratio, RUN=1, update valid professional AES3 channel-status fields, unmute on block boundary.
8. Implement **professional channel-status metadata** using applicable AES3 standard: PCM/non-audio bit, professional bit, rate, word length, channels. Validate with an AES analyzer or reliable receiver; do not invent channel-status byte constants.
9. Keep firmware logs/diagnostics or expose a UART/HID diagnostic path if available. USB audio must remain functional if diagnostics are disabled.
10. If the exact module has **closed/inaccessible firmware** or no available I²C/GPIO controls, **stop and document the blocker**. An auxiliary MCU is a separate fallback design, not an implicit part of this revision.

### Firmware pseudocode

```c
// Conceptual only — adapt to exact XMOS SDK and CS8406 APIs.
void audio_hw_init(void) {
    cs_rst_low();
    init_i2c_100khz();
    // Confirm clocks and supplies before releasing reset.
    cs_rst_high();
    delay_ms(1);
    assert((cs8406_read(0x7F) & 0xF0) == 0xE0);
    cs8406_write(0x01, 0x10); // muted
    cs8406_write(0x02, 0x00); // stereo
    cs8406_write(0x03, 0x00); // no AES bypass
    cs8406_write(0x05, 0x05); // I2S slave candidate; verify waveforms
}

void audio_hw_config(unsigned fs, unsigned omck) {
    cs8406_write(0x01, 0x10);  // mute
    cs8406_write(0x04, 0x00);  // stop RUN (actual bits later set)
    // XMOS clock/audio reconfiguration must happen here/around this callback,
    // in the correct board-specific sequence.
    unsigned ratio_bits = checked_ratio_bits(omck, fs); // returns 0x20/0x00/0x30
    wait_for_stable_i2s_clocks();
    cs8406_write(0x04, ratio_bits);        // RUN=0
    cs8406_write(0x04, ratio_bits | 0x40); // RUN=1
    write_and_commit_channel_status(fs, 24, true); // after RUN=1
    await_channel_status_boundary();
    cs8406_write(0x01, 0x00);  // unmute
}
```

The firmware must handle unsupported rate/clock combos cleanly (mute, error, no random AES output), and the exact timing/API integration must be established by tests.

## 8. Preliminary single-board BOM (verify pricing and stock independently)

| Reference | Qty | Description / selection | Status |
|---|---:|---|---|
| XM1 | 1 | Existing XU316 USB-to-I²S **module**, exact revision unknown | **GATE: module ID** |
| U1 | 1 | Cirrus **CS8406-CZZ**, TSSOP-28 | Owned; verify marking |
| U2 | 1 | TI **TLV75533PDRVR**, LDO 3.3 V, DRV package | Owned; verify symbol/footprint |
| Q1–Q2 | 2 | BSS138 I²C translator, SOT-23 | Add |
| FB1 | 1 | Ferrite for 5-V AES branch; choose exact impedance/current package | Verify actual part |
| R_DIG1–4 | 4 | 22 Ω, 1%, 0603 optional source-end I²S/MCLK series | Owned; populate after SI review |
| R_I2C_L1–L2 | 2 | 4.7 kΩ, 0603 to 3.3 V; check existing XMOS pull-ups | Owned |
| R_I2C_H1–H2 | 2 | 4.7 kΩ, 0603 to 5 V | Owned |
| R_RST_PD | 1 | 10 kΩ, 0603 to GND | Owned |
| R_RST_SER | 1 | 1 kΩ, 0603 optional reset series | Add |
| R_U | 1 | 47 kΩ, 0603 U pulldown | Add |
| R_TCBL | 1 | 47 kΩ, 0603 optional TCBL pulldown | Add |
| R_AES | 1 | **56.2 Ω**, 1%, 0603 or 0805 | **Add mandatory** |
| C_VD, C_VL | 2 | 100 nF X7R, near CS8406 supply pins | Owned |
| C_LDO_IN | 1 | ≥1 µF effective X7R/X5R, suitable voltage | Owned |
| C_LDO_OUT | 1 | ≥1 µF effective X7R/X5R | Owned |
| C_LOCAL | 1–3 | 100 nF / 10 µF local reservoir capacitors per regulator/branch review | Owned |
| C_BULK5 | 1 | 10–22 µF, +5-V branch | Owned |
| T1 | 1 | Pulse **PE-65612NL**, 1:1, **≤96-kHz development** | Owned; not 192-kHz-rated |
| T1_ALT | 1 | Verified 192-kHz-capable 1:1 AES transformer | **GATE for 192 kHz** |
| J_AES | 1 | Neutrik **NC3MAH-LR**, male XLR | Owned |
| D_ESD1–2 | 2 | PESD5V0H1BSFYL, optional DNP initially | Owned; topology review |
| J_MOD | 1 | Connector matching actual XU316 board | **GATE: module ID** |
| TP_* | several | Test pads for 5 V, 3.3 V, GND, I²S clocks/data, I²C, RST, TXP/TXN | Add |

**Deliberately absent:** CS8422, AM26LS31, Pi HAT header, independent audio oscillators, second XLR, analog amplifier/line driver, and 110-Ω load termination resistor on the output.

## 9. Required deliverables and file layout

```text
usb-aes-ebu/
  README.md                         project overview, assembly restrictions
  docs/
    architecture.md                 block diagram + clock-domain explanation
    module-pinmap.md                evidence-backed actual XU316 connector mapping
    schematic-notes.md             net names, pin tables, grounding/ESD
    assumptions-and-blockers.md    unresolved decisions and verification status
    design-review-checklist.md     signoff gates and measured findings
    test-plan.md                   electrical/audio/USB tests
    sources.md                     exact manufacturer doc URLs and revisions
  hardware/
    xu316_cs8406_usb_aes.kicad_pro
    xu316_cs8406_usb_aes.kicad_sch
    symbols/                       only where stock KiCad symbols insufficient
    footprints/                    only verified footprints
    bom.csv                        manufacturer part numbers, quantity, status
    connections.csv                from-pin/to-pin, net, voltage, validation
    erc-report.txt                 KiCad ERC generated, no hidden exceptions
  firmware/
    README.md                       exact XMOS SDK + version + build procedure
    cs8406_i2c.h/.xc or C           portable register definitions and driver
    audio_hw_config.*              tested callback integration (when buildable)
    channel_status.*               AES3 metadata encoder
    tests/                          register/rate calculations and mocks
  scripts/
    validate.sh                    non-destructive: source/BOM/check/compile
```

The agent should generate **valid KiCad files**, not a drawing pretending to be a netlist. If a symbol library is missing or a connector pinmap is unverified, clearly identify the blocker; do not generate invented symbol pads.

## 10. Execution phases and acceptance criteria

### Phase A — Evidence, pinout and feasibility

- Confirm actual XU316 board name/revision/photos/schematic, accessible 5 V, audio I²S direction, MCLK/2, 3.3-V I²C/GPIO, firmware openness and usable reset pin.
- Confirm exact CS8406-CZZ footprint; verify both `VL=5 V` output and `VD=3.3 V` logic interface.
- Identify transformer to qualify a separate 176.4/192-kHz build variant.
- **Gate:** no PCB placement/final wire mapping with an undocumented module.

### Phase B — KiCad schematic and BOM

- Create hierarchical sheets (XMOS-module interface; Power; CS8406; I²C/reset; AES3 output and chassis).
- Cross-check every pin against DS580F6, every local regulator pin against TI DRV package, and every transformer/connector pin against vendor mechanicals.
- Run ERC, explicitly document any waived warnings, label 3.3-V and 5-V signal domains, separate chassis net from digital GND.
- **Gate:** ERC passes with all exceptions justified; review BOM pad footprints and values.

### Phase C — Firmware implementation

- Build compatible XMOS USB Audio example **without modifying the hardware**.
- Make CS8406 ID read and mute/reset sequencing work on a simulated/stubbed I²C layer.
- Implement six supported clock/rate entries, channel-status handling, and failure modes.
- **Gate:** firmware compiles for exact board, register/mapping tests pass, code never enables output with inconsistent clock ratios.

### Phase D — Owner-executed bench bring-up

1. Power only; check +5V_AES and +3V3_AES, LDO thermal, power sequencing and no back-feed.
2. Verify safe 3.3-V XMOS GPIO and translator 5-V domain; I²C reads `0x7F` with ID high nibble `0xE`.
3. Scope MCLK/2, BCLK, LRCLK synchronization and `RST` rise timing.
4. First run 48-kHz 1-kHz stereo test tone / PCM channel checks into an **AES analyzer or 110-Ω load**, then Genelec.
5. Verify 44.1, 88.2, 96 kHz; test sample-rate transitions, USB unplug/replug, failed I²C, reset, mute behavior and no bursts.
6. Only after installing a validated full-bandwidth transformer, test 176.4/192 kHz and inspect balanced waveform / receiver lock / channel-status reporting.
7. Document real measurements and update schematic/BOM.

### Phase E — Fabrication readiness (optional follow-up)

- PCB layout only after schematic signoff; preserve transformer isolation, controlled AES3 pair, ground/chassis strategy, short decoupling loops and clock-edge signal integrity.
- Generate PCB DRC, gerbers, assembly drawings and release checklist **only after explicit owner approval**.

## 11. Red flags / prohibited shortcuts

- **Never** connect 5-V CS8406 I²C directly to XU316 3.3-V pins.
- **Never** connect `VL=3.3 V` and assume the professional AES3 line amplitude is identical to `VL=5 V`.
- **Never** use two 22-Ω output resistors in place of the single computed 56.2-Ω resistor without revisiting manufacturer Figure 14 and impedance math.
- **Never** insert AM26LS31 between CS8406 TXP/TXN and transformer.
- **Never** drive OMCK with independent 22.5792/24.576 oscillator while BCLK/LRCLK come from asynchronous XMOS oscillator.
- **Never** feed 45.1584/49.152 MHz directly into CS8406 OMCK under the stated 44.1–192-kHz plan.
- **Never** declare the PE-65612NL a specified 192-kHz AES transformer.
- **Never** copy physical header pin numbers from Phaten or another board to the user's unidentified XU316 module.
- **Never** claim the XMOS controller is programmable from arbitrary vendor firmware without first finding source/SDK/boot mechanism.
- **Never** write C/U channel-status buffers when CS8406 RUN=0.
- **Never** claim S/PDIF coax levels and 110-Ω professional AES3 balanced levels are interchangeable.

## 12. Final handoff checklist

- [ ] Exact XU316 board/manufacturer/hardware revision documented.
- [ ] I²S/MCLK/I²C/reset physical pinout verified.
- [ ] CS8406 manufacturer software-mode pin diagram reconciled with KiCad symbols.
- [ ] TLV75533PDRVR DRV 6-pin pinout and CIN/COUT verified.
- [ ] Firmware control interface, licenses and source-build route verified.
- [ ] I²C translator and pull-ups checked for voltage/current margins.
- [ ] Clock-family/OMCK ratio table and serial polarity verified by simulation/bench.
- [ ] Professional AES3 output impedance and 56.2-Ω resistor verified.
- [ ] PE-65612NL footprint, pin orientation and bandwidth limitation documented.
- [ ] Optional 192-kHz transformer selected and verified before full-rate claim.
- [ ] XLR pin numbering, chassis and ESD topology reviewed.
- [ ] KiCad schematic/netlist/ERC and CSV BOM generated.
- [ ] XMOS sample-rate callback integration builds and tests pass.
- [ ] Owner can follow power-up/test steps independently; no automatic flashing or fabrication.
