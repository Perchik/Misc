//
// Gear grid + framed sandwich + tolerance test
// Uses gears/gears.scad (involute spur gears)
//
// - 3x3 grid of 12T gears, OD ~28mm
// - 695 bearings (5x13x4) in gears 1,3,5,7,9
// - 5mm axles for gears 2,4,6,8
// - Top/bottom flanges on every gear
// - Framed “keypad” with center ring and chamfered exterior
//

include <gears/gears.scad>;
$fn = 64;

// ---------------------------------------------------
// Global parameters
// ---------------------------------------------------

// Base tolerances
press_fit_tol = 0.18; // tighter press-fit (bearing pockets, axle holes)
loose_fit_tol = 0.30; // looser running fit (gear bores, posts into bearings)

gear_teeth = 12;
gear_od = 28; // tip-to-tip OD
pa_deg = 20;

// Compute module from OD ≈ m * (N + 2)
modul = gear_od / (gear_teeth + 2); // 28 / 14 = 2
center_dist = modul * gear_teeth; // pitch dia for identical gears

// Bearing (695) = 5 x 13 x 4 mm
bearing_id = 5;
bearing_od = 13;
bearing_width = 4;

gear_height = bearing_width; // gear thickness

// --- Diameters derived from tolerances ---

// Press-fit bearing pocket in gears (OD of bearing)
bearing_bore_diam = bearing_od + press_fit_tol; // ~13.18

// Gear bores for axle gears (loose on 5 mm pin)
axle_nominal = 5;
axle_bore_diam = axle_nominal + loose_fit_tol; // ~5.30

// Printed axle shaft (for frames)
axle_shaft_diam = 5; // nominal 5 mm

// Press-fit hole in upper frame for axle shaft
axle_hole_diam = axle_shaft_diam - press_fit_tol; // ~4.82

// --- Frame nubs (flanges now live on the frames) ---
frame_nub_diam = 6.7;
frame_nub_height = 0.8;

// --- Bearing centering posts (inside 5mm ID bearing) ---
// Small undersized stub that sits in the 5mm ID bearing (loose fit)
bearing_post_diam = bearing_id - loose_fit_tol; // e.g. 5 - 0.30 = 4.7

// Frame
frame_bar_width = 2; // bar / ring width
frame_height = 4;
frame_bevel = 0; // amount of chamfer (shrink at top)

// Axle length is derived from the stack:
//   frame body + frame nub + gear height
// so the full axle spans through nub + gear to meet the top frame.
axle_length = frame_height + frame_nub_height + gear_height;

corner_diam_bearing = 14; // big pad for bearing gears
corner_diam_axle = 8; // small pad for axle gears (if any corner ever is axle)

// ---------------------------------------------------
// Role lookup: bearing vs axle per keypad key (1..9)
// 1 = bearing gear, 0 = axle gear
// Here: 1,3,5,7,9 = bearing; 2,4,6,8 = axle
// ---------------------------------------------------
bearing_lut = [
  1, // key 1
  0, // key 2
  1, // key 3
  0, // key 4
  1, // key 5
  0, // key 6
  1, // key 7
  0, // key 8
  1, // key 9
];

function is_bearing_key(key) = bearing_lut[key - 1] == 1;
function is_axle_key(key) = !is_bearing_key(key);

// ---------------------------------------------------
// Utility functions
// ---------------------------------------------------

function distance(a, b) =
  sqrt(
    (b[0] - a[0]) * (b[0] - a[0]) + (b[1] - a[1]) * (b[1] - a[1])
  );

// 3x3 grid of points, like keypad 1–9
// 1 2 3
// 4 5 6
// 7 8 9
function gear_grid_points(rows, cols, spacing) =
  [
    for (r = [0:rows - 1], c = [0:cols - 1]) [
      (c - (cols - 1) / 2) * spacing, // X
      (r - (rows - 1) / 2) * spacing, // Y
    ],
  ];

points_3x3 = gear_grid_points(3, 3, center_dist);

// keypad index (1..9) to point
function point_from_key(points, key) = points[key - 1];

// ---------------------------------------------------
// 2D helper: rectangle between two points
// ---------------------------------------------------

module rect_between(p1, p2, w) {
  dx = p2[0] - p1[0];
  dy = p2[1] - p1[1];
  d = sqrt(dx * dx + dy * dy);

  mx = (p1[0] + p2[0]) / 2;
  my = (p1[1] + p2[1]) / 2;

  ang = atan2(dy, dx);

  translate([mx, my])
    rotate(ang)
      square([d + w, w], center=true);
}

// ---------------------------------------------------
// 2D frame outline: bars, corner pads, center ring
// ---------------------------------------------------

module frame_shape_2d(points, rect_width) {

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
      rect_between(p1, p2, rect_width);
    }

    // --- Corner pads: size depends on bearing vs axle role ---
    for (k = [1:9]) {
      p = point_from_key(points, k);

      // Lookup: is this key a bearing gear?
      d = is_bearing_key(k) ? corner_diam_bearing : corner_diam_axle;

      translate(p)
        circle(d=d, $fn=64);
    }

    // Center ring: thickness = rect_width
    p4 = point_from_key(points, 4);
    p6 = point_from_key(points, 6);
    pc = point_from_key(points, 5);
    bigD = distance(p4, p6);

    translate(pc)
      difference() {
        circle(d=bigD + rect_width, $fn=128);
        circle(d=bigD - rect_width, $fn=128);
      }
  }
}
// ---------------------------------------------------
// Bearing visualization (NOT for printing)
// 695 bearing: ID, OD, width
// ---------------------------------------------------
module bearing_visual(od = bearing_od, id = bearing_id, width = bearing_width) {
  // Outer ring
  color("black")
    difference() {
      cylinder(d=od, h=width, center=true, $fn=64);
      cylinder(d=id, h=width + 0.2, center=true, $fn=48);
    }
}

// ---------------------------------------------------
// 3D frame: chamfered extrusion of the 2D shape
// ---------------------------------------------------

module frame_body(points, rect_width, height, bevel = frame_bevel) {
  // Simple chamfer: top slightly scaled inwards
  linear_extrude(height=height, scale=(1 - bevel / height))
    frame_shape_2d(points, rect_width);
}

// Lower frame: chamfered body + face nubs at all points
module lower_frame(points) {
  union() {
    // Main frame body
    frame_body(points, frame_bar_width, frame_height);

    // For every gear position 1..9
    for (key = [1:9]) {
      p = point_from_key(points, key);

      // --- Face nub (flange) for both bearing & axle gears ---
      translate([p[0], p[1], frame_height])
        cylinder(d=frame_nub_diam, h=frame_nub_height, $fn=32);

      // --- Role-dependent posts ---
      if (is_bearing_key(key)) {
        // Bearing: half-height centering post
        translate([p[0], p[1], frame_height + frame_nub_height])
          cylinder(
            d=bearing_post_diam,
            h=axle_length / 2,
            $fn=32
          );
      } else {
        // Axle gear: full-length axle shaft
        translate([p[0], p[1], frame_height + frame_nub_height])
          cylinder(
            d=axle_shaft_diam,
            h=axle_length,
            $fn=32
          );
      }
    }
  }
}

// Upper frame: body at Z=0..frame_height,
// nubs and posts extend DOWN toward the gears (negative Z)
module upper_frame(points) {
  difference() {
    union() {

      // Frame body
      frame_body(points, frame_bar_width, frame_height);

      // Nubs + bearing half-posts (extend downward)
      for (key = [1:9]) {
        p = point_from_key(points, key);

        // --- Downward nub ---
        translate([p[0], p[1], 0])
          cylinder(
            d=frame_nub_diam,
            h=frame_nub_height,
            $fn=32,
            center=false
          );

        // --- Downward bearing half-post ---
        if (is_bearing_key(key)) {
          translate([p[0], p[1], -axle_length / 2])
            cylinder(
              d=bearing_post_diam,
              h=axle_length / 2 + frame_nub_height,
              $fn=32
            );
        }
      }
    }

    // --- Axle holes: cut DOWN through the frame and nub area ---
    for (key = [1:9]) {
      if (is_axle_key(key)) {
        p = point_from_key(points, key);

        translate([p[0], p[1], -frame_height - axle_length])
          cylinder(
            d=axle_hole_diam,
            h=frame_height + axle_length + 5,
            $fn=32
          );
      }
    }
  }
}

// ---------------------------------------------------
// Gears: bearings vs axles, flanges both sides
// ---------------------------------------------------

// Place gears at grid points (1..9) with bearings / axle bores
module gears_at_points(points) {
  half_tooth_angle = 180 / gear_teeth; // 360 / (2*N) = 15° for 12T

  for (i = [0:len(points) - 1]) {
    p = points[i];
    key = i + 1;

    // Alternate gear rotation for visible meshing
    ang = (i % 2 == 1) ? half_tooth_angle : 0;

    use_bearing = is_bearing_key(key);
    bore = use_bearing ? bearing_bore_diam : axle_bore_diam;

    translate([p[0], p[1], -gear_height / 2])
      rotate([0, 0, ang])
        spur_gear(
          modul,
          gear_teeth,
          gear_height,
          bore_diam,
          pressure_angle=pa_deg,
          optimized=false
        );
  }
}

module bearings_at_points(points) {
  for (i = [0:len(points) - 1]) {
    key = i + 1;
    if (is_bearing_key(key)) {
      p = points[i];
      // Gears are centered around Z=0, so center bearings there too
      translate([p[0], p[1], 0])
        bearing_visual();
    }
  }
}

// ---------------------------------------------------
// Main assemblies
// ---------------------------------------------------

// Full gadget: lower frame, gears, upper frame.
// (Z positioning is illustrative; for printing, export parts separately.)
module assembly() {

  // Lower frame: drop so spacer top touches gear/bearing bottom (z=0)
  //translate([0, 0, -(frame_height + spacer_height)])
  color("red", 0.6)
    lower_frame(points_3x3);

  // Gears centered on Z = 0..4
  color("silver", 0.9)
    gears_at_points(points_3x3);

  // Bearings at correct Z
  color("grey", 0.5)
    translate([0, 0, 0])
      bearings_at_points(points_3x3);

  // Upper frame: lift so spacer bottom touches gear top (z=4)
  // translate([0,0, gear_height])
  //   color("lime",0.6)
  //     upper_frame(points_3x3);
}

// ---------------------------------------------------
// Tolerance test module
// - Block with axle
// - Block with press-fit hole
// - Gear with axle bore + flanges
// - Gear with bearing bore + flanges
// ---------------------------------------------------

module test_block_with_axle() {
  block_x = 30;
  block_y = 20;
  block_z = frame_height;

  union() {
    cube([block_x, block_y, block_z], center=true);

    translate([0, 0, block_z / 2])
      cylinder(d=axle_shaft_diam, h=axle_length, $fn=32);
  }
}

module test_block_with_hole() {
  block_x = 30;
  block_y = 20;
  block_z = frame_height;

  difference() {
    cube([block_x, block_y, block_z], center=true);

    translate([0, 0, -block_z / 2 - 1])
      cylinder(d=axle_hole_diam, h=block_z + 2, $fn=32);
  }
}

module test_gear_axle_bore() {
  gear_with_bore(axle_bore_diam);
}

module test_gear_bearing_bore() {
  gear_with_bore(bearing_bore_diam);
}

module tolerance_test() {
  // Left: axle block
  translate([-40, 0, 0])
    test_block_with_axle();

  // Right: hole block
  translate([40, 0, 0])
    test_block_with_hole();

  // Top: gear with axle bore
  translate([0, 35, 0])
    test_gear_axle_bearing_label(false);

  // Bottom: gear with bearing bore
  translate([0, -35, 0])
    test_gear_axle_bearing_label(true);
}

// helper so you can visually tell them apart if you want
module test_gear_axle_bearing_label(is_bearing) {
  if (is_bearing) {
    color("orange")
      test_gear_bearing_bore();
  } else {
    color("cyan")
      test_gear_axle_bore();
  }
}

// ---------------------------------------------------
// Choose what to render
// ---------------------------------------------------

// Uncomment ONE of these at a time when you render/export:

//gears_at_points(points_3x3);

// Full assembly preview (for sanity checking)
assembly();

// Tolerance test pieces for printing
//tolerance_test();

//upper_frame(points=points_3x3);
