#include "cs8406.h"

enum {
    ADDRESS = 0x10,
    CONTROL_1 = 0x01,
    CONTROL_2 = 0x02,
    DATA_FLOW = 0x03,
    CLOCK_CONTROL = 0x04,
    SERIAL_FORMAT = 0x05,
    DEVICE_ID = 0x7f,
    MUTE_AES = 0x10,
    RUN = 0x40,
    I2S_SLAVE_24_BIT = 0x05,
    IO_ATTEMPTS = 3,
};

static bool transfer(struct cs8406 *device, const uint8_t *tx, size_t tx_size,
                     uint8_t *rx, size_t rx_size)
{
    for (unsigned attempt = 0; attempt < IO_ATTEMPTS; ++attempt) {
        if (device->transfer(device->context, ADDRESS, tx, tx_size,
                             rx, rx_size) == 0) {
            return true;
        }
    }
    return false;
}

static bool write_register(struct cs8406 *device, uint8_t reg, uint8_t value)
{
    const uint8_t command[] = {reg, value};
    return transfer(device, command, sizeof command, NULL, 0);
}

static enum cs8406_result reset_on_error(struct cs8406 *device,
                                        enum cs8406_result error)
{
    device->set_reset(device->context, true);
    device->ready = false;
    return error;
}

enum cs8406_result cs8406_init(struct cs8406 *device)
{
    if (!device || !device->transfer || !device->set_reset || !device->delay_us) {
        return CS8406_BAD_ARGUMENT;
    }

    device->ready = false;
    device->revision = 0;
    device->set_reset(device->context, true);
    device->delay_us(device->context, 1000);
    device->set_reset(device->context, false);
    device->delay_us(device->context, 1000);

    const uint8_t address = DEVICE_ID;
    uint8_t id;
    if (!transfer(device, &address, 1, &id, 1)) {
        return reset_on_error(device, CS8406_BUS_ERROR);
    }
    if ((id & 0xf0) != 0xe0) {
        return reset_on_error(device, CS8406_WRONG_DEVICE);
    }
    if (!write_register(device, CONTROL_1, MUTE_AES) ||
        !write_register(device, CLOCK_CONTROL, 0) ||
        !write_register(device, CONTROL_2, 0) ||
        !write_register(device, DATA_FLOW, 0) ||
        !write_register(device, SERIAL_FORMAT, I2S_SLAVE_24_BIT)) {
        return reset_on_error(device, CS8406_BUS_ERROR);
    }

    device->revision = id & 0x0f;
    device->ready = true;
    return CS8406_OK;
}

enum cs8406_result cs8406_stop(struct cs8406 *device)
{
    if (!device || !device->ready) {
        return CS8406_NOT_READY;
    }
    if (!write_register(device, CONTROL_1, MUTE_AES) ||
        !write_register(device, CLOCK_CONTROL, 0)) {
        return reset_on_error(device, CS8406_BUS_ERROR);
    }
    return CS8406_OK;
}

enum cs8406_result cs8406_start_muted(struct cs8406 *device, uint32_t sample_hz,
                                     uint32_t omck_hz)
{
    enum cs8406_result result = cs8406_stop(device);
    if (result != CS8406_OK) {
        return result;
    }
    if (sample_hz < 8000 || sample_hz > 192000 || omck_hz % sample_hz != 0) {
        return CS8406_BAD_CLOCK;
    }

    uint8_t clock_bits;
    switch (omck_hz / sample_hz) {
    case 128: clock_bits = 0x30; break;
    case 256: clock_bits = 0x00; break;
    case 384: clock_bits = 0x10; break;
    case 512: clock_bits = 0x20; break;
    default: return CS8406_BAD_CLOCK;
    }
    if (!write_register(device, CLOCK_CONTROL, clock_bits) ||
        !write_register(device, CLOCK_CONTROL, clock_bits | RUN)) {
        return reset_on_error(device, CS8406_BUS_ERROR);
    }
    return CS8406_OK;
}
