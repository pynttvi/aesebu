column_count = 18;
row_count = 11;

// Perfboard assembly guide. Grid orientation is viewed from the component side.
pitch = 2.54;
board_thickness = 1.6;
hole_diameter = 1.0;
pad_diameter = 1.85;

// Toggle the underside wiring and labels for a clear view of either side.
show_wiring = true;
show_labels = true;

function hole(column, row) = [(column - 1) * pitch, (row_count - row) * pitch];

module board() {
    color("SaddleBrown") difference() {
        translate([-pitch, -pitch, 0])
            cube([(column_count + 1) * pitch, (row_count + 1) * pitch, board_thickness]);
        for (column = [1:column_count], row = [1:row_count])
            translate(concat(hole(column, row), [-0.1]))
                cylinder(h = board_thickness + 0.2, d = hole_diameter, $fn = 20);
    }
    for (column = [1:column_count], row = [1:row_count])
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
// Adapter header rows at C and I. Pin 1 is C3.
for (column = [3:16], row = [3, 9])
    terminal(column, row, "Silver");

for (connection = [
    [3,1,"Red"], [4,1,"DodgerBlue"], [5,1,"Black"],
    [10,1,"Gold"], [11,1,"Black"], [12,1,"Orange"], [13,1,"Yellow"],
    [14,1,"LimeGreen"], [15,1,"Violet"],
    [3,11,"LimeGreen"], [4,11,"Orange"], [5,11,"Black"],
    [7,11,"Magenta"], [8,11,"Purple"]
])
    terminal(connection[0], connection[1], connection[2]);

color("DarkGreen")
    translate(concat(hole(3, 8) + [-1.1, -1.2], [board_thickness + 1.1]))
        cube([13 * pitch + 2.2, 4 * pitch + 2.4, 1.35]);

// Placement markers for bypass caps and pulldowns.
for (part = [[8,3,8,2], [8,9,9,9], [11,3,11,2], [11,9,11,8]])
    wire(hole(part[0],part[1]), hole(part[2],part[3]), board_thickness + 0.5, "Tan");

if (show_wiring) {
    wire(hole(3,2), hole(16,2), -0.42, "Black");
    for (column = [4,5,6,7,9,10,12,13])
        wire(hole(column,3), hole(column,2), -0.42, "Black");
    for (column = [4,7,9,13,14,15])
        wire(hole(column,9), hole(column,2), -0.42, "Black");
    for (run = [
        [3,1,8,9,"Red"], [4,1,8,3,"DodgerBlue"],
        [5,1,5,2,"Black"], [5,11,5,2,"Black"], [11,1,11,2,"Black"],
        [11,8,9,9,"Black"], [3,11,3,3,"LimeGreen"], [4,11,3,9,"Orange"],
        [10,1,10,9,"Gold"], [12,1,15,3,"Orange"], [13,1,14,3,"Yellow"],
        [14,1,16,3,"LimeGreen"], [15,1,11,3,"Violet"],
        [7,11,5,9,"Magenta"], [8,11,6,9,"Purple"]
    ])
        wire(hole(run[0],run[1]), hole(run[2],run[3]), -0.75, run[4]);
}
if (show_labels) {
    label_at(hole(4,5), "PWR");
    label_at(hole(13,3) + [0,1.1], "AUDIO / RST");
    label_at(hole(4,10), "I2C HV");
    label_at(hole(8,10), "TX");
    label_at(hole(2,3), "1");
}

if (show_labels) {
    for (column = [1:column_count])
        label_at([hole(column, 1)[0], (row_count - 0.35) * pitch], str(column), 0.9);
    letters = ["A","B","C","D","E","F","G","H","I","J","K"];
    for (row = [1:row_count])
        label_at([-0.65 * pitch, hole(1, row)[1]], letters[row - 1], 0.9);
}
