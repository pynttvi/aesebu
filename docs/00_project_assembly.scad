// Combined perfboard assembly. Board spacing and cable paths are illustrative.
show_harnesses = true;
show_module_names = true;

module power_module() {
    include <01_power_module.scad>
}
module level_shifter() {
    include <02_line_shifter.scad>
}
module transmitter() {
    include <03_cs8406_transmitter.scad>
}
module aes3_output() {
    include <04_aes3_output.scad>
}
module xmos_interconnect() {
    include <05_xmos_interconnect.scad>
}

power_at = [0, 0];
shifter_at = [0, 32];
transmitter_at = [56, 30];
output_at = [124, 28];
xmos_at = [56, 75];

translate(power_at) power_module();
translate(shifter_at) level_shifter();
translate(transmitter_at) transmitter();
translate(output_at) aes3_output();
translate(xmos_at) xmos_interconnect();

// Each cable represents the complete group of wires between two headers.
function header(origin, column, row, rows = 6) =
    origin + [(column - 1) * 2.54, (rows - row) * 2.54];

module harness(start, finish, bends, cable_color, height) {
    points = concat(
        [[start.x, start.y, 2.75], [start.x, start.y, height]],
        [for (bend = bends) [bend.x, bend.y, height]],
        [[finish.x, finish.y, height], [finish.x, finish.y, 2.75]]
    );
    color(cable_color)
        for (i = [0:len(points) - 2])
            hull() {
                translate(points[i]) sphere(d = 1.5, $fn = 12);
                translate(points[i + 1]) sphere(d = 1.5, $fn = 12);
            }
}

if (show_harnesses) {
    power_out = header(power_at, 12, 5);
    harness(power_out, header(shifter_at, 6, 1), [[39, 2.54], [39, 51], [12.7, 51]], "FireBrick", 6);
    harness(power_out, header(transmitter_at, 4, 1, 11), [[49, 2.54], [49, 62], [63.62, 62]], "FireBrick", 7);
    harness(header(shifter_at, 12, 4), header(transmitter_at, 4, 11, 11),
            [[36, 37.08], [45, 23], [63.62, 23]], "SeaGreen", 5);
    harness(header(xmos_at, 10, 6), header(shifter_at, 1, 4),
            [[78.86, 69], [-8, 69], [-8, 37.08]], "SeaGreen", 9);
    harness(header(xmos_at, 4.5, 1), header(transmitter_at, 12.5, 1, 11),
            [[64.89, 94], [104, 94], [104, 62], [85.21, 62]], "DarkOrange", 6);
    harness(header(transmitter_at, 7.5, 11, 11), header(output_at, 1, 3.5),
            [[72.51, 20], [117, 20], [117, 34.35]], "MediumPurple", 5);
}

module module_name(position, title) {
    color("SlateGray")
        translate([position.x, position.y, 0])
            linear_extrude(height = 0.5)
                text(title, size = 3, halign = "center");
}

if (show_module_names) {
    module_name([14, -8], "01 Power");
    module_name([14, 24], "02 I2C shifter");
    module_name([78, 12], "03 CS8406");
    module_name([138, 20], "04 AES3 output");
    module_name([70, 100], "05 XMOS interconnect");
}
