# Preliminary XU316 / CS8406 firmware

This is a portable CS8406 bring-up driver for the [perfboard project](../00_project_assembly.md). It probes the chip, configures stereo I²S slave mode, and starts or stops the AES3 encoder with audio muted. The XU316 board, GPIO mapping, vendor source, and matching XTC version are still unidentified. Those details are needed to build a board-specific `.xe` and wire up the XMOS callbacks.

## Integrate with a verified XU316 application

| Stage | Driver call and board work |
| --- | --- |
| Startup | Hold reset low until power is stable. Provide reset and microsecond-delay callbacks plus a 100 kHz I²C transfer callback with a bounded timeout. Call `cs8406_init()` from the board's initialization path. It reads register `0x7f` at 7-bit address `0x10` and records the revision. |
| Before changing rates | Call `cs8406_stop()` before changing or interrupting clocks, for example from `AudioHwConfig_Mute()` where available. |
| After clocks are stable | Call `cs8406_start_muted()` with the PCM sample rate and the frequency **at CS8406 OMCK**. Use the actual divider from the board design. Check MCLK, BCLK, and LRCLK synchrony and I²S framing on the bench. Start at 48 kHz with the Pulse transformer. |
| Before enabling playback | Implement and validate professional AES3 channel status, including the CS8406 E-to-F buffer transfer while RUN is set. Add the unmute step after that transfer. This scaffold stops at muted bring-up. |

Use the exact board's XN file, flash configuration, and supported USB Audio application. Keep the existing firmware's recovery or restore path available. Confirm that the XU316 exposes XTAG before using this script. A USB DFU-only board needs its vendor's update procedure.

[CS8406 datasheet, sections 6–8 and 16](https://www.mouser.com/datasheet/2/76/CS8406_F6-1141075.pdf) · [XMOS lib_xua callbacks](https://www.xmos.com/documentation/XM-012296-UG/html/doc/rst/api_user_functions.html)

## Run the host test

From the project root:

```sh
cc -std=c11 -Wall -Wextra -Werror -pedantic firmware/cs8406.c \
  firmware/tests/test_cs8406.c -o /tmp/aesebu-cs8406-test
/tmp/aesebu-cs8406-test
```

## Inspect or flash a board-specific image

Load the matching XMOS XTC environment and connect the XTAG adapter. The first command lists adapters. The second checks the image path and prints the selected target. The third programs flash.

```sh
firmware/flash.sh --list
firmware/flash.sh ADAPTER_SERIAL path/to/board-firmware.xe
firmware/flash.sh --write ADAPTER_SERIAL path/to/board-firmware.xe
```

Use an image built for the exact board and confirm the adapter serial before running `--write`. The script checks the path and extension. Image compatibility still depends on the build and target.

[XMOS XFLASH reference](https://www.xmos.com/documentation/XM-014363-PC/html/tools-guide/tools-ref/cmd-line-tools/xflash-manual/xflash-manual.html)
