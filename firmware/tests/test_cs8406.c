#include "../cs8406.h"

#include <assert.h>

struct fake_device {
    uint8_t registers[128];
    unsigned failures;
    unsigned calls;
    bool reset_asserted;
};

static int fake_transfer(void *context, uint8_t address, const uint8_t *tx,
                         size_t tx_size, uint8_t *rx, size_t rx_size)
{
    struct fake_device *fake = context;
    assert(address == 0x10 && !fake->reset_asserted);
    assert(tx[0] < sizeof fake->registers);
    ++fake->calls;
    if (fake->failures > 0) {
        --fake->failures;
        return 1;
    }
    if (rx_size != 0) {
        assert(tx_size == 1 && rx_size == 1 && tx[0] == 0x7f);
        *rx = fake->registers[tx[0]];
    } else {
        assert(tx_size == 2);
        fake->registers[tx[0]] = tx[1];
    }
    return 0;
}

static void fake_reset(void *context, bool asserted)
{
    struct fake_device *fake = context;
    fake->reset_asserted = asserted;
}

static void fake_delay(void *context, unsigned microseconds)
{
    (void)context;
    assert(microseconds >= 200);
}

int main(void)
{
    struct fake_device fake = {.registers = {[0x7f] = 0xe2}, .failures = 2};
    struct cs8406 device = {
        .context = &fake,
        .transfer = fake_transfer,
        .set_reset = fake_reset,
        .delay_us = fake_delay,
    };

    assert(cs8406_start_muted(&device, 48000, 24576000) == CS8406_NOT_READY);
    assert(cs8406_init(&device) == CS8406_OK);
    assert(device.revision == 2 && fake.calls == 8);
    assert(fake.registers[0x01] == 0x10 && fake.registers[0x04] == 0);
    assert(fake.registers[0x05] == 0x05);

    const struct {
        uint32_t omck;
        uint8_t running_clock_register;
    } ratios[] = {
        {6144000, 0x70}, {12288000, 0x40}, {18432000, 0x50}, {24576000, 0x60},
    };
    for (size_t i = 0; i < sizeof ratios / sizeof ratios[0]; ++i) {
        assert(cs8406_start_muted(&device, 48000, ratios[i].omck) == CS8406_OK);
        assert(fake.registers[0x04] == ratios[i].running_clock_register);
        assert(fake.registers[0x01] == 0x10);
    }
    assert(cs8406_start_muted(&device, 48000, 24576001) == CS8406_BAD_CLOCK);
    assert(cs8406_start_muted(&device, 0, 24576000) == CS8406_BAD_CLOCK);
    assert(fake.registers[0x01] == 0x10 && fake.registers[0x04] == 0);

    const unsigned calls_before_failure = fake.calls;
    fake.failures = 3;
    assert(cs8406_stop(&device) == CS8406_BUS_ERROR);
    assert(fake.calls - calls_before_failure == 3);
    assert(!device.ready && fake.reset_asserted);

    fake.registers[0x7f] = 0xff;
    assert(cs8406_init(&device) == CS8406_WRONG_DEVICE);
    assert(!device.ready && fake.reset_asserted);
}
