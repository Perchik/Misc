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
//
// tight_fit_tol:
//   Hole is THIS MUCH LARGER than shaft.
//   Intended to assemble without spinning or sliding under load.
//
// loose_fit_tol:
//   Free-running clearance.
//
tight_fit_tol = 0.13;
loose_fit_tol = 0.30;

// --- Gear geometry ---
gear_teeth = 12;
gear_od = 28;
pa_deg = 20;
modul = gear_od / (gear_teeth + 2);
center_dist = modul * gear_teeth;
gear_height = 4;

// --- Axles for 8 outer gears ---
axle_shaft_diam = 5;
axle_hole_diam = axle_shaft_diam + tight_fit_tol;
axle_bore_diam = axle_shaft_diam + loose_fit_tol;
axle_inset = 2;

spacer_diam = 6.7;
spacer_height = 0.6;
axle_length = gear_height + spacer_height + axle_inset;

// --- Center bearing (695) ---
bearing_id = 5;
bearing_od = 13;
bearing_width = 4;

bearing_pocket_diam = bearing_od + tight_fit_tol;
bearing_pocket_depth = bearing_width;
bearing_pocket_floor = 2;

// --- Frame geometry ---
frame_height = bearing_pocket_depth + bearing_pocket_floor;
frame_bar_width = 2;
corner_diam_all = 8;

// --- Hex shaft geometry ---
center_shaft_hex_af = 3.0; // across flats
center_shaft_round_d = bearing_id + tight_fit_tol;

// Nominal hex across-flats (shaft)
center_hex_af_nominal = center_shaft_hex_af;

// Tight-fit hex hole (non-spinning fit in gear & journal)
center_hex_af_tight = center_hex_af_nominal + tight_fit_tol;

// Circumradius helpers
center_hex_R_nominal = hex_circumradius(center_hex_af_nominal);
center_hex_R_tight = hex_circumradius(center_hex_af_tight);

// Clearance hole through frame floors (must clear hex corners)
center_shaft_clearance_d =
2 * (center_shaft_hex_af / sqrt(3)) + loose_fit_tol;

// --- Derived lengths ---
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

function hex_circumradius(af) = af / sqrt(3);

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
  R = hex_circumradius(af);
  polygon(
    points=[
      for (i = [0:5]) [R * cos(60 * i), R * sin(60 * i)],
    ]
  );
}

// Z-safe solid cylinder (extends slightly past bounds)
module cyl_solid(d, h, z0 = 0, fn = 48) {
  translate([0, 0, z0 - eps])
    cylinder(d=d, h=h + 2 * eps, $fn=fn);
}

// Z-safe subtractive cylinder
module cyl_cut(d, h, z0 = 0, fn = 48) {
  translate([0, 0, z0 - eps])
    cylinder(d=d, h=h + 2 * eps, $fn=fn);
}

///////////////////////////////////////////////////////////////
//  FRAME POCKETS / CUTOUTS
///////////////////////////////////////////////////////////////

module center_bearing_pocket(points) {
  pc = point_from_key(points, 5);
  translate([pc[0], pc[1], bearing_pocket_floor - eps])
    cyl_cut(bearing_pocket_diam, bearing_pocket_depth, bearing_pocket_floor);
}

module center_shaft_hole(points) {
  pc = point_from_key(points, 5);
  translate([pc[0], pc[1], -eps])
    cyl_cut(center_shaft_clearance_d, frame_height);
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

// Journal = round sleeve riding in bearing inner race,
// keyed (hex) to the center shaft to transmit torque
module center_journal() {
  journal_len = bearing_width + 2 * eps;

  difference() {
    // Outer: mates with bearing inner race
    cylinder(
      d=center_shaft_round_d,
      h=journal_len,
      center=true,
      $fn=64
    );

    // Inner: mates with hex shaft (non-spinning fit)
    translate([0, 0, -journal_len / 2 - eps])
      linear_extrude(height=journal_len + 2 * eps)
        hex2d(center_hex_af_tight);
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
    [7, 1],
    [2, 5],
    [4, 5],
    [5, 6],
    [5, 8],
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
        cyl_solid(spacer_diam, spacer_height);

      // Axle (lower frame only)
      if (!is_upper) {
        translate(
          [
            p[0],
            p[1],
            frame_height + spacer_height - eps,
          ]
        )
          cyl_solid(axle_shaft_diam, axle_length);
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

      translate([0, 0, -eps])
        linear_extrude(height=gear_height + 2 * eps)
          hex2d(center_hex_af_tight);
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
          gear_with_hex_bore(center_hex_af_tight);
        else
          gear_with_bore(axle_bore_diam);
      }
  }
}

module bearing_visual() {
  difference() {
    cylinder(d=bearing_od, h=bearing_width, center=true, $fn=64);
    cylinder(d=bearing_id, h=bearing_width + 2 * eps, center=true, $fn=48);
  }
}

///////////////////////////////////////////////////////////////
//  TEST PIECES — FIT & TOLERANCE VERIFICATION
//  (Foldable, never exported unless explicitly rendered)
///////////////////////////////////////////////////////////////

module tests_suite() {

  ///////////////////////////////////////////////////////////////
  // Test 1 — Printed axle shaft size check
  ///////////////////////////////////////////////////////////////
  module test_axle_block() {
    block_x = 30;
    block_y = 20;
    block_z = frame_height;

    union() {
      cube([block_x, block_y, block_z], center=true);

      // Printed axle (same as lower frame)
      translate([0, 0, block_z / 2 - eps])
        cylinder(
          d=axle_shaft_diam,
          h=axle_length + 2 * eps,
          $fn=48
        );
    }
  }

  ///////////////////////////////////////////////////////////////
  // Test 2 — Upper frame axle hole (tight-fit)
  ///////////////////////////////////////////////////////////////
  module test_hole_block() {
    block_x = 30;
    block_y = 20;
    block_z = frame_height;

    difference() {
      cube([block_x, block_y, block_z], center=true);

      // Axle hole (press-fit hole in upper frame)
      translate([0, 0, -block_z / 2 - 2 * eps])
        cylinder(
          d=axle_hole_diam,
          h=block_z + 4 * eps,
          $fn=48
        );
    }
  }

  ///////////////////////////////////////////////////////////////
  // Test 3 — Spacer disc
  ///////////////////////////////////////////////////////////////
  module test_spacer_only() {
    block_x = 30;
    block_y = 15;
    block_z = frame_height;

    union() {
      cube([block_x, block_y, block_z], center=true);

      translate([0, 0, block_z / 2 - eps])
        cylinder(
          d=spacer_diam,
          h=spacer_height + 2 * eps,
          $fn=48
        );
    }
  }

  ///////////////////////////////////////////////////////////////
  // Test 4 — Hex shaft sample
  ///////////////////////////////////////////////////////////////
  module test_hex_shaft() {
    translate([0, 0, -10])
      linear_extrude(height=20)
        hex2d(center_shaft_hex_af);
  }

  ///////////////////////////////////////////////////////////////
  // Test 5 — Gear hex bore (tight-fit)
  ///////////////////////////////////////////////////////////////
  module test_hex_bore_gear() {

    difference() {
      cube([20, 20, 10], center=true);

      translate([0, 0, -6])
        linear_extrude(height=12)
          hex2d(center_shaft_hex_af);
    }
  }

  ///////////////////////////////////////////////////////////////
  // Test 6 — Journal hex bore (tight-fit)
  ///////////////////////////////////////////////////////////////
  module test_hex_bore_journal() {
    difference() {
      cube([20, 20, 10], center=true);

      translate([0, 0, -6])
        linear_extrude(height=12)
          hex2d(center_shaft_hex_af);
    }
  }

  ///////////////////////////////////////////////////////////////
  // Test 7 — Journal outer diameter (bearing inner race)
  ///////////////////////////////////////////////////////////////
  module test_journal_outer() {
    difference() {
      cube([20, 20, 10], center=true);

      translate([0, 0, -6])
        cylinder(
          d=center_shaft_round_d,
          h=12,
          $fn=64
        );
    }
  }

  ///////////////////////////////////////////////////////////////
  // Test 8 — Frame bearing pocket (outer race)
  ///////////////////////////////////////////////////////////////
  module test_bearing_pocket() {
    difference() {
      cube([22, 22, 10], center=true);

      translate([0, 0, -6])
        cylinder(
          d=bearing_pocket_diam,
          h=12,
          $fn=64
        );
    }
  }

  ///////////////////////////////////////////////////////////////
  // Combined test layout
  ///////////////////////////////////////////////////////////////
  module tests() {
    spacing = 35;

    translate([0, 0, 0]) test_spacer_only();
    translate([spacing, 0, 0]) test_axle_block();
    translate([-spacing, 0, 0]) test_hole_block();

    translate([0, spacing, 0]) test_hex_shaft();
    translate([spacing, spacing, 0]) test_hex_bore_gear();
    translate([-spacing, spacing, 0]) test_hex_bore_journal();

    translate([0, -spacing, 0]) test_journal_outer();
    translate([spacing, -spacing, 0]) test_bearing_pocket();
  }

  tests();
}

///////////////////////////////////////////////////////////////
//  ASSEMBLY VIEW
///////////////////////////////////////////////////////////////

module assembly() {
  pc = point_from_key(points_3x3, 5);

  lower_shift = -gear_height / 2 - spacer_height - frame_height;
  upper_shift = +gear_height / 2 + 2*spacer_height+frame_height;

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

  // // --- Bearings (visual only) ---
  color("gray", 0.6)
    translate([pc[0], pc[1], lower_shift + bearing_center_local])
      bearing_visual();

  // color("gray", 0.6)
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
//gear_with_hex_bore(center_shaft_hex_af + press_fit_tol);
//tests_suite();
//test_bearing_pocket();

///////////////////////////////////////////////////////////////
//  CLI EXPORT DISPATCHER
///////////////////////////////////////////////////////////////

if (!is_undef(EXPORT_PART)) {
  if (EXPORT_PART == "lower_frame")
    frame(points_3x3, false);
  else if (EXPORT_PART == "upper_frame")
    upper_frame(points_3x3);
  else if (EXPORT_PART == "center_gear")
    gear_with_hex_bore(center_shaft_hex_af + tight_fit_tol);
  else if (EXPORT_PART == "round_gear")
    gear_with_bore(axle_bore_diam);
  else if (EXPORT_PART == "center_journal")
    center_journal();
  else if (EXPORT_PART == "center_shaft")
    rotate([90, 0, 0]) center_shaft();
  else
    echo(str("Unknown EXPORT_PART: ", EXPORT_PART));
}

if (!is_undef(RENDER_ASSEMBLY)) {
  assembly();
}
