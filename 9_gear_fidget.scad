///////////////////////////////////////////////////////////////
//  3×3 Gear Grid – Frames, Hex Shaft, Journals, Spacers
///////////////////////////////////////////////////////////////

include <gears/gears.scad>;
include <BOSL2/std.scad>;
$fn = 64;
eps = 0.01;

///////////////////////////////////////////////////////////////
//  GLOBAL PARAMETERS
///////////////////////////////////////////////////////////////

// --- Tolerances ---
press_fit_tol = 0.13; // for tight fits (press)
loose_fit_tol = 0.30; // for running fits (clearance)

// --- Gear geometry ---
gear_teeth = 12;
gear_od = 28;
pa_deg = 20;
modul = gear_od / (gear_teeth + 2);
center_dist = modul * gear_teeth;
gear_height = 4; // gear thickness

// --- Axles for 8 outer gears ---
axle_shaft_diam = 5;
axle_hole_diam = axle_shaft_diam - press_fit_tol;
axle_bore_diam = axle_shaft_diam + loose_fit_tol;
axle_inset = 2;
spacer_diam = 6.7;
spacer_height = 0.6;
axle_length = gear_height + spacer_height + axle_inset;

// --- Center bearing (695) ---
bearing_id = 5;
bearing_od = 13;
bearing_width = 4;
bearing_pocket_diam = bearing_od + press_fit_tol;
bearing_pocket_depth = bearing_width;
bearing_pocket_floor = 2;

// --- Frame geometry ---
frame_height = bearing_pocket_depth + bearing_pocket_floor;
frame_bar_width = 2;
corner_diam_all = 8;

// --- Hex shaft geometry ---
center_shaft_hex_af = 3.0; // Across flats
center_hex_press = press_fit_tol; // press-fit reduction
center_shaft_round_d = bearing_id + press_fit_tol; // OD press-fit into inner race

// Hex clearance hole in frame:
center_shaft_clearance_d =
2 * (center_shaft_hex_af / sqrt(3)) + loose_fit_tol;

// Derived lengths
shaft_total_len = 2 * (frame_height + spacer_height + gear_height);
shaft_extra_each = 3;

///////////////////////////////////////////////////////////////
//  GRID POINTS
///////////////////////////////////////////////////////////////

function gear_grid_points(rows, cols, spacing) =
  [
    for (r = [0:rows - 1], c = [0:cols - 1]) [
      (c - (cols - 1) / 2) * spacing,
      (r - (rows - 1) / 2) * spacing,
    ],
  ];

points_3x3 = gear_grid_points(3, 3, center_dist);
function point_from_key(points, key) = points[key - 1];

///////////////////////////////////////////////////////////////
//  BASIC GEOMETRY HELPERS
///////////////////////////////////////////////////////////////

function distance(a, b) =
  sqrt((a[0] - b[0]) * (a[0] - b[0]) + (a[1] - b[1]) * (a[1] - b[1]));

module rect_between(p1, p2, w) {
  dx = p2[0] - p1[0];
  dy = p2[1] - p1[1];
  d = sqrt(dx * dx + dy * dy);
  ang = atan2(dy, dx);
  mx = (p1[0] + p2[0]) / 2;
  my = (p1[1] + p2[1]) / 2;

  translate([mx, my])
    rotate(ang)
      square([d + w, w], center=true);
}

module hex2d(af) {
  R = af / sqrt(3);
  polygon(points=[for (i = [0:5]) [R * cos(60 * i), R * sin(60 * i)]]);
}

///////////////////////////////////////////////////////////////
//  FRAME POCKETS / CUTOUTS
///////////////////////////////////////////////////////////////

module center_bearing_pocket(points) {
  pc = point_from_key(points, 5);
  translate([pc[0], pc[1], bearing_pocket_floor - eps])
    cylinder(
      d=bearing_pocket_diam,
      h=bearing_pocket_depth + 2 * eps,
      $fn=64
    );
}

module center_shaft_hole(points) {
  pc = point_from_key(points, 5);
  translate([pc[0], pc[1], -eps])
    cylinder(
      d=center_shaft_clearance_d,
      h=frame_height + 2 * eps,
      $fn=48
    );
}

///////////////////////////////////////////////////////////////
//  SHAFT & JOURNALS
///////////////////////////////////////////////////////////////

module center_shaft() {
  shaft_len = shaft_total_len + 2 * shaft_extra_each;
  translate([0, 0, -shaft_len / 2])
    linear_extrude(height=shaft_len)
      hex2d(center_shaft_hex_af);
}

module center_journal() {
  journal_len = bearing_width + 2 * eps;

  difference() {
    // Outer cylinder – press fits into bearing inner race
    cylinder(
      d=center_shaft_round_d,
      h=journal_len,
      center=true,
      $fn=64
    );

    // Inner hex – press-fit onto shaft
    hex_af = center_shaft_hex_af - center_hex_press;
    translate([0, 0, -journal_len / 2 - eps])
      linear_extrude(height=journal_len + 2 * eps)
        hex2d(hex_af);
  }
}

///////////////////////////////////////////////////////////////
//  FRAME 2D PROFILE
///////////////////////////////////////////////////////////////

module frame_shape_2d(points, w) {

  key_pairs = [
    [1, 3],
    [3, 9],
    [9, 7],
    [7, 1], // outer square
    [2, 5],
    [4, 5],
    [5, 6],
    [5, 8], // internal struts
  ];

  union() {
    // Bars
    for (pair = key_pairs) {
      p1 = point_from_key(points, pair[0]);
      p2 = point_from_key(points, pair[1]);
      rect_between(p1, p2, w);
    }

    // Corner pads
    for (k = [1:9]) {
      p = point_from_key(points, k);
      d =
        (k == 5) ? (bearing_pocket_diam + 2 * frame_bar_width)
        : corner_diam_all;

      translate(p) circle(d=d, $fn=64);
    }

    // Central ring
    pc = point_from_key(points, 5);
    p4 = point_from_key(points, 4);
    p6 = point_from_key(points, 6);
    bigD = distance(p4, p6);

    translate(pc)
      difference() {
        circle(d=bigD + w, $fn=128);
        circle(d=bigD - w, $fn=128);
      }
  }
}

///////////////////////////////////////////////////////////////
//  FRAME (LOWER & UPPER)
///////////////////////////////////////////////////////////////

module frame(points, is_upper = false) {
  difference() {
    // Base frame plate
    linear_extrude(height=frame_height, convexity=10)
      frame_shape_2d(points, frame_bar_width);

    // SUBTRACT center features
    center_bearing_pocket(points);
    center_shaft_hole(points);
  }

  // ADD spacers and (for lower frame) axles
  for (key = [1:9]) {
    if (key != 5) {
      p = point_from_key(points, key);

      // Spacer
      translate([p[0], p[1], frame_height - eps])
        cylinder(
          d=spacer_diam,
          h=spacer_height + 2 * eps,
          $fn=48
        );

      // Axle (lower frame only)
      if (!is_upper) {
        translate(
          [
            p[0],
            p[1],
            frame_height + spacer_height - eps,
          ]
        )
          cylinder(
            d=axle_shaft_diam,
            h=axle_length + 2 * eps,
            $fn=48
          );
      }
    }
  }
}

module upper_frame(points) {
  difference() {
    frame(points, true);

    // Subtract axle holes
    for (key = [1:9]) {
      p = point_from_key(points, key);
      translate(
        [
          p[0],
          p[1],
          frame_height - axle_inset - eps,
        ]
      )
        cylinder(
          d=axle_hole_diam,
          h=axle_length + 2 * eps,
          $fn=48
        );
    }
  }
}

///////////////////////////////////////////////////////////////
//  GEARS
///////////////////////////////////////////////////////////////

module gear_with_bore(bore_d) {
  translate([0, 0, -gear_height / 2 - eps])
    spur_gear(
      modul,
      gear_teeth,
      gear_height + 2 * eps,
      bore_d,
      pressure_angle=pa_deg,
      optimized=false
    );
}

module gear_with_hex_bore(af) {
  hex_r = af / sqrt(3);

  translate([0, 0, -gear_height / 2])
    difference() {
      spur_gear(
        modul,
        gear_teeth,
        gear_height,
        bore=0,
        pressure_angle=pa_deg,
        optimized=false
      );

      // subtract hex
      translate([0, 0, -eps])
        linear_extrude(height=gear_height + 2 * eps)
          hex2d(af);
    }
}
module gears_at_points(points) {
  half_tooth_angle = 180 / gear_teeth; // for visual meshing

  for (i = [0:len(points) - 1]) {
    p = points[i];
    key = i + 1;
    ang = (i % 2 == 1) ? half_tooth_angle : 0;

    translate([p[0], p[1], 0])
      rotate([0, 0, ang]) {
        if (key == 5)
          gear_with_hex_bore(center_shaft_hex_af - press_fit_tol);
        else
          gear_with_bore(axle_bore_diam);
      }
  }
}

///////////////////////////////////////////////////////////////
//  VISUAL HELPERS
///////////////////////////////////////////////////////////////

module bearing_visual() {
  difference() {
    cylinder(d=bearing_od, h=bearing_width, center=true, $fn=64);
    cylinder(d=bearing_id, h=bearing_width + 2 * eps, center=true, $fn=48);
  }
}

///////////////////////////////////////////////////////////////
//  ASSEMBLY VIEW (COLOR-CODED)
///////////////////////////////////////////////////////////////

module assembly() {
  pc = point_from_key(points_3x3, 5);

  lower_shift =
  -(frame_height + spacer_height + gear_height / 2);
  upper_shift =
  +(frame_height - gear_height / 2 + frame_height + spacer_height);

  bearing_center_local =
  bearing_pocket_floor + bearing_pocket_depth / 2;

  // --- Journals ---
  color("orange")
    translate([pc[0], pc[1], lower_shift + bearing_center_local])
      center_journal();

  color("orange")
    translate([pc[0], pc[1], upper_shift - bearing_center_local])
      center_journal();

  // --- Lower Frame ---
  color("purple", 0.6)
    translate([0, 0, lower_shift])
      frame(points_3x3);

  // --- Gears ---
  color("silver", 0.9)
    gears_at_points(points_3x3);

  // --- Bearings (visual only) ---
  color("gray", 0.6)
    translate([pc[0], pc[1], lower_shift + bearing_center_local])
      bearing_visual();

  color("gray", 0.6)
    translate([pc[0], pc[1], upper_shift - bearing_center_local])
      bearing_visual();

  // --- Upper Frame ---
  color("lime", 0.6)
    translate([0, 0, upper_shift])
      mirror([0, 0, 1])
        upper_frame(points_3x3);

  // --- Shaft ---
  color("red")
    translate([pc[0], pc[1], 0])
      center_shaft();
}

///////////////////////////////////////////////////////////////
//  RENDERING
///////////////////////////////////////////////////////////////

assembly();
//frame(points_3x3);
//upper_frame(points_3x3);
//center_shaft();
//center_journal();
//gear_with_hex_bore(center_shaft_hex_af - press_fit_tol);
