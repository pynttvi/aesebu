// I²C level shifter perfboard assembly guide. Grid orientation is viewed from the component side.
pitch = 2.54;
board_thickness = 1.6;
hole_diameter = 1.0;
pad_diameter = 1.85;

// Toggle the underside wiring and labels for a clear view of either side.
show_wiring = true;
show_labels = true;

function hole(column, row) = [(column - 1) * pitch, (6 - row) * pitch];

module board() {
    color("SaddleBrown") difference() {
        translate([-pitch, -pitch, 0])
            cube([13 * pitch, 7 * pitch, board_thickness]);
        for (column = [1:12], row = [1:6])
            translate(concat(hole(column, row), [-0.1]))
                cylinder(h = board_thickness + 0.2, d = hole_diameter, $fn = 20);
    }
    for (column = [1:12], row = [1:6])
        color("Peru") translate(concat(hole(column, row), [-0.08]))
            difference() {
                cylinder(h = 0.08, d = pad_diameter, $fn = 24);
                translate([0, 0, -0.01])
                    cylinder(h = 0.1, d = hole_diameter, $fn = 20);
            }
}

module wire(from, to, z, wire_color) {
    color(wire_color) hull() {
        translate(concat(from, [z])) sphere(d = 0.65, $fn = 12);
        translate(concat(to, [z])) sphere(d = 0.65, $fn = 12);
    }
}

module label_at(position, label, size = 1.15) {
    color("White") translate(concat(position, [board_thickness + 0.04]))
        linear_extrude(height = 0.08)
            text(label, size = size, halign = "center", valign = "center");
}

module terminal(column, row, terminal_color) {
    color(terminal_color)
        translate(concat(hole(column, row), [board_thickness]))
            cylinder(h = 1.15, d = 1.45, $fn = 20);
}

// Hole positions follow 02_line_shifter.md. The breakout attaches by wire.
// Red = 5 V, blue = 3.3 V, black = GND, green = SDA, orange = SCL.
board();

terminal(5, 1, "Red");
terminal(6, 1, "DodgerBlue");
terminal(7, 1, "Black");

for (column = [1, 12]) {
    terminal(column, 3, "LimeGreen");
    terminal(column, 4, "Orange");
    terminal(column, 5, "Black");
}

if (show_wiring) {
    wire(hole(7, 1), hole(7, 6), -0.42, "Black");
    wire(hole(1, 6), hole(12, 6), -0.42, "Black");
    wire(hole(1, 6), hole(1, 5), -0.42, "Black");
    wire(hole(12, 6), hole(12, 5), -0.42, "Black");
}

if (show_labels) {
    for (column = [1:12])
        label_at([hole(column, 1)[0], 5.65 * pitch], str(column), 0.9);
    rows = ["A", "B", "C", "D", "E", "F"];
    for (row = [1:6])
        label_at([-0.65 * pitch, hole(1, row)[1]], rows[row - 1], 0.9);

    label_at([hole(5, 1)[0], 11.1], "5V", 0.85);
    label_at([hole(6, 1)[0], 11.1], "3V3", 0.85);
    label_at([hole(7, 1)[0], 11.1], "GND", 0.85);
    label_at([3.9, 8.9], "XMOS / LV");
    // High-side connector callout next to the C12, D12, E12 pins.
    color("DarkSlateBlue") {
        translate([17.4, 9.05, board_thickness - 0.02])
            cube([12.1, 2.2, 0.06]);
        translate([29.25, 2.1, board_thickness - 0.02])
            cube([0.55, 6.0, 0.09]);
    }
    label_at([23.45, 10.15], "TO CS8406", 1.4);
    signals = ["SDA", "SCL", "GND"];
    for (row = [3:5]) {
        label_at([2.54, hole(1, row)[1]], signals[row - 3], 0.9);
        label_at([24.8, hole(12, row)[1]], signals[row - 3], 1.15);
    }
}
