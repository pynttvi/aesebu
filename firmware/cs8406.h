#ifndef AESEBU_CS8406_H
#define AESEBU_CS8406_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum cs8406_result {
    CS8406_OK,
    CS8406_BAD_ARGUMENT,
    CS8406_BUS_ERROR,
    CS8406_WRONG_DEVICE,
    CS8406_BAD_CLOCK,
    CS8406_NOT_READY,
};

struct cs8406 {
    void *context;
    // Return zero on success. Use a repeated start when rx_size is nonzero.
    int (*transfer)(void *context, uint8_t address, const uint8_t *tx,
                    size_t tx_size, uint8_t *rx, size_t rx_size);
    void (*set_reset)(void *context, bool asserted);
    void (*delay_us)(void *context, unsigned microseconds);
    bool ready;       // Managed by the driver. Initialize the struct to zero.
    uint8_t revision; // Valid after successful initialization.
};

// Call after power is stable. On transport or ID failure the device stays in reset.
enum cs8406_result cs8406_init(struct cs8406 *device);

// Call before changing clocks. Stops the encoder with the output muted.
enum cs8406_result cs8406_stop(struct cs8406 *device);

// Call once the new clocks are stable. Starts the encoder with audio still muted.
enum cs8406_result cs8406_start_muted(struct cs8406 *device, uint32_t sample_hz,
                                     uint32_t omck_hz);

#endif
