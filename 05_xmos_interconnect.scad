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
audio_signals = ["MCLK","GND","BCLK","LRCK","DATA","RST"];
audio_colors = ["Gold","Black","Orange","Yellow","LimeGreen","Violet"];
i2c_signals = ["SDA","SCL","GND"];
i2c_colors = ["LimeGreen","Orange","Black"];

for (index = [0:5]) {
    column = index + 2;
    terminal(column,3,audio_colors[index]);
    terminal(column,1,audio_colors[index]);
    if (show_wiring)
        wire(hole(column,3), hole(column,1), -0.42, audio_colors[index]);
    if (show_labels)
        label_at(hole(column,2), audio_signals[index], 0.65);
}
for (index = [0:2]) {
    column = index + 9;
    terminal(column,3,i2c_colors[index]);
    terminal(column,6,i2c_colors[index]);
    if (show_wiring)
        wire(hole(column,3), hole(column,6), -0.42, i2c_colors[index]);
    if (show_labels)
        label_at(hole(column,5), i2c_signals[index], 0.8);
}
if (show_wiring)
    wire(hole(3,3), hole(11,3), -0.85, "Black");
if (show_labels) {
    label_at(hole(5,4), "XMOS HARNESS");
    label_at(hole(5,6), "AUDIO TO 03");
    label_at(hole(10,4), "I2C TO 02");
}

if (show_labels) {
    for (column = [1:column_count])
        label_at([hole(column, 1)[0], (row_count - 0.35) * pitch], str(column), 0.9);
    letters = ["A","B","C","D","E","F","G","H","I","J","K"];
    for (row = [1:row_count])
        label_at([-0.65 * pitch, hole(1, row)[1]], letters[row - 1], 0.9);
}
