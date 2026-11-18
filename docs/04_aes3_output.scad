column_count = 12;
row_count = 6;

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
for (connection = [[1,3,"Magenta"], [1,4,"Purple"], [12,3,"LimeGreen"], [12,4,"Orange"]])
    terminal(connection[0],connection[1],connection[2]);

wire(hole(2,3), hole(5,3), board_thickness + 0.7, "Silver");
color("Tan")
    translate(concat((hole(2,3) + hole(5,3)) / 2, [board_thickness + 0.7]))
        rotate([0,90,0]) cylinder(h = 5, d = 2, center = true, $fn = 24);

for (column = [6,10], row = [3,5])
    terminal(column,row,"Silver");
color("DimGray")
    translate(concat((hole(6,5) + hole(10,3)) / 2 - [6.35,4.445], [board_thickness + 1.15]))
        cube([12.7,8.89,6.35]); // Illustrative body

if (show_wiring)
    for (run = [[1,3,2,3,"Magenta"], [5,3,6,3,"Magenta"], [1,4,6,5,"Purple"],
                [10,3,12,3,"LimeGreen"], [10,5,12,4,"Orange"]])
        wire(hole(run[0],run[1]), hole(run[2],run[3]), -0.42, run[4]);

if (show_labels) {
    label_at(hole(2,2), "TX");
    label_at(hole(4,2), "R1");
    label_at(hole(8,2), "T1");
    label_at(hole(12,2), "XLR");
}

if (show_labels) {
    for (column = [1:column_count])
        label_at([hole(column, 1)[0], (row_count - 0.35) * pitch], str(column), 0.9);
    letters = ["A","B","C","D","E","F","G","H","I","J","K"];
    for (row = [1:row_count])
        label_at([-0.65 * pitch, hole(1, row)[1]], letters[row - 1], 0.9);
}
