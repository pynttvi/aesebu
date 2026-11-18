// Perfboard assembly guide. Grid orientation is viewed from the component side.
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

board();

// FB1 occupies the former jumper holes. Body size illustrates a leaded bead.
bead_axis_height = board_thickness + 1.35;
wire(hole(1, 1), hole(3, 1), bead_axis_height, "Silver");
color("DimGray")
    translate(concat(hole(2, 1), [bead_axis_height]))
        rotate([0, 90, 0])
            cylinder(h = 3.2, d = 2.5, center = true, $fn = 24);
wire(hole(4, 1), hole(4, 3), board_thickness + 0.65, "Silver"); // C1 leads
color("DimGray")
    translate(concat(hole(4, 2), [board_thickness + 0.65]))
        cylinder(h = 5, d = 4.5, $fn = 32); // Illustrative capacitor body

terminal(1, 1, "Red");        // 5 V input
terminal(1, 6, "DimGray");    // Input ground
terminal(6, 1, "Red");        // Carrier VIN
terminal(6, 6, "DimGray");    // Carrier ground
terminal(9, 3, "DodgerBlue"); // Carrier OUT
terminal(12, 4, "Red");       // 5 V output
terminal(12, 5, "DodgerBlue");// 3.3 V output
terminal(12, 6, "DimGray");   // Output ground

if (show_wiring) {
    wire(hole(3, 1), hole(12, 1), -0.42, "Red");
    wire(hole(12, 1), hole(12, 4), -0.42, "Red");
    wire(hole(9, 3), hole(12, 5), -0.42, "DodgerBlue");
    wire(hole(1, 6), hole(12, 6), -0.42, "DimGray");
    wire(hole(4, 3), hole(4, 6), -0.42, "DimGray");
}

if (show_labels) {
    for (column = [1:12])
        label_at([hole(column, 1)[0], 5.65 * pitch], str(column), 0.9);
    rows = ["A", "B", "C", "D", "E", "F"];
    for (row = [1:6])
        label_at([-0.65 * pitch, hole(1, row)[1]], rows[row - 1], 0.9);
    label_at([2.4, 11.1], "FB1", 0.9);
    label_at([7.62, 5.9], "C1", 0.9);
    label_at([12.7, 11.1], "VIN", 0.9);
    label_at([20.32, 6.1], "OUT", 0.9);
    label_at([12.7, 1.45], "GND", 0.9);
}
