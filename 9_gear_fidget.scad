///////////////////////////////////////////////////////////////
//  3×3 Gear Grid – Frames, Bearings, Spacers, Axles
//  Cleaned + Final Version
//  Upper frame faces downward directly (no mirroring needed)
//
//  Terminology:
//  - SPACER: 6.7mm × 0.8mm disc at each of 9 points (both frames)
//            Supports BOTH gear + bearing evenly.
//  - NUB:    4.8mm × 2.0mm cylinder (bearing alignment pin)
//            Only exists at bearing gears.
//  - AXLE:   5mm post on LOWER frame for axle gears.
//  - AXLE HOLE: press-fit hole on UPPER frame for axle gears.
//
//  The stack:
//
//        Upper Frame Body
//        Spacer (downward)
//        Nub (downward, bearing gears only)
//        ─────────────── top of bearing
//           Bearing (4mm)
//        ─────────────── bottom of bearing
//        Nub (upward, bearing gears only)
//        Spacer (upward)
//        Lower Frame Body
//
///////////////////////////////////////////////////////////////

include <gears/gears.scad>;
$fn = 64;

///////////////////////////////////////////////////////////////
//  GLOBAL PARAMETERS + TOLERANCES
///////////////////////////////////////////////////////////////

press_fit_tol = 0.18; // tight interference
loose_fit_tol = 0.30; // smooth running clearance

//////////// GEAR INFO /////////////////////////
gear_teeth = 12;
gear_od = 28; // tip-to-tip
pa_deg = 20;
modul = gear_od / (gear_teeth + 2);
center_dist = modul * gear_teeth;

//////////// BEARING INFO //////////////////////
// 695 bearing = 5mm ID × 13mm OD × 4mm width
bearing_id = 5;
bearing_od = 13;
bearing_width = 4;

gear_height = bearing_width; // gears = same as bearing width
axle_shaft_diam = 5; // Not necessarily the same as bearing ID

//////////// SPACERS + NUBS ////////////////////////
spacer_diam = 6.7;
spacer_height = 0.8;
nub_height = 2.0; // EACH FRAME contributes 2.0mm → total 4mm

//////////// FRAME DIMENSIONS //////////////////////
frame_height = 4; // body thickness
frame_bar_width = 2;
frame_bevel = 0; // set >0 if chamfer desired

//////////// DERIVED DIAMETERS ////////////////////
bearing_bore_diam = bearing_od + press_fit_tol; // pocket in gear

axle_bore_diam = axle_shaft_diam + loose_fit_tol; // gear bore for axle gears
axle_hole_diam = axle_shaft_diam - press_fit_tol; // press-fit hole
bearing_nub_diam = bearing_id - loose_fit_tol; // enters bearing ID

//////////// AXLE LENGTH /////////////////////////////
axle_length = frame_height + spacer_height + gear_height;
// = lower frame body + lower spacer + full gear thickness
// This ensures axle passes fully through to upper frame hole.

//////////// CORNER PAD DIAMETERS ///////////////////////
corner_diam_bearing = 14;
corner_diam_axle = 8;

///////////////////////////////////////////////////////////////
//  ROLE LOOKUP LIST
///////////////////////////////////////////////////////////////
bearing_lut = [
  1, // key 1 = bearing
  0, // key 2 = axle
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

///////////////////////////////////////////////////////////////
//  POINT GRID
///////////////////////////////////////////////////////////////
function gear_grid_points(rows, cols, spacing) =
  [
    for (r = [0:rows - 1], c = [0:cols - 1]) [
      (c - (cols - 1) / 2) * spacing, // X
      (r - (rows - 1) / 2) * spacing, // Y
    ],
  ];

points_3x3 = gear_grid_points(3, 3, center_dist);

function point_from_key(points, key) = points[key - 1];

///////////////////////////////////////////////////////////////
//  2D helper: rectangle between two points
///////////////////////////////////////////////////////////////
function distance(a, b) =
  sqrt(
    (a[0] - b[0]) * (a[0] - b[0]) + (a[1] - b[1]) * (a[1] - b[1])
  );

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

///////////////////////////////////////////////////////////////
//  2D FRAME OUTLINE (top-down)
///////////////////////////////////////////////////////////////
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

    // Corner pads, size depends on bearing vs axle
    for (k = [1:9]) {
      p = point_from_key(points, k);
      d = is_bearing_key(k) ? corner_diam_bearing : corner_diam_axle;
      translate(p) circle(d=d, $fn=64);
    }

    // Central ring
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

///////////////////////////////////////////////////////////////
//  3D FRAME BODY
///////////////////////////////////////////////////////////////
module frame_body(points, w, h) {
  // TODO: add bevel
  linear_extrude(height=h)
    frame_shape_2d(points, w);
}

///////////////////////////////////////////////////////////////
//  LOWER FRAME (UPWARD SPACERS + UPWARD NUBS/AXLES)
///////////////////////////////////////////////////////////////
module lower_frame(points) {
  union() {
    // Main frame body
    frame_body(points, frame_bar_width, frame_height);

    for (key = [1:9]) {
      p = point_from_key(points, key);

      // Spacer 
      translate([p[0], p[1], frame_height])
        cylinder(d=spacer_diam, h=spacer_height, $fn=48);

      if (is_bearing_key(key)) {
        // Bearing half-height centering post
        translate([p[0], p[1], frame_height + spacer_height])
          cylinder(d=bearing_nub_diam, h=nub_height, $fn=48);
      } else {
        // Axle (upward)
        translate([p[0], p[1], frame_height + spacer_height])
          cylinder(d=axle_shaft_diam, h=axle_length, $fn=48);
      }
    }
  }
}

///////////////////////////////////////////////////////////////
//  UPPER FRAME (DOWNWARD SPACERS + DOWNWARD NUBS + HOLES)
///////////////////////////////////////////////////////////////
module upper_frame(points) {
  difference() {
    union() {
      // Frame body
      frame_body(points, frame_bar_width, frame_height);

      for (key = [1:9]) {
        p = point_from_key(points, key);

        // Spacer (DOWNWARD)
        translate([p[0], p[1], 0])
          cylinder(d=spacer_diam, h=spacer_height, $fn=48);

        // Bearing nub (DOWNWARD)
        if (is_bearing_key(key)) {
          translate([p[0], p[1], -nub_height])
            cylinder(d=bearing_nub_diam, h=nub_height, $fn=48);
        }
      }
    }

    // Axle holes (DOWNWARD) for axle gears
    for (key = [1:9]) {
      if (is_axle_key(key)) {
        p = point_from_key(points, key);
        translate([p[0], p[1], -axle_length - 2])
          cylinder(
            d=axle_hole_diam,
            h=axle_length + 4,
            $fn=48
          );
      }
    }
  }
}

///////////////////////////////////////////////////////////////
//  GEARS
///////////////////////////////////////////////////////////////
module gear_with_bore(diam) {
  translate([0, 0, -gear_height / 2])
    spur_gear(
      modul, gear_teeth, gear_height,
      diam, pressure_angle=pa_deg, optimized=false
    );
}

module gears_at_points(points) {
  half_rot = 180 / gear_teeth;
  for (i = [0:len(points) - 1]) {
    key = i + 1;
    p = points[i];
    // Alternate gear rotation for visible meshing
    ang = (i % 2 == 1) ? half_rot : 0;

    translate([p[0], p[1], 0])
      rotate([0, 0, ang])
        gear_with_bore(bore);
  }
}

///////////////////////////////////////////////////////////////
//  BEARING VISUAL (not printed)
///////////////////////////////////////////////////////////////
module bearing_visual() {
  difference() {
    cylinder(d=bearing_od, h=bearing_width, center=true, $fn=64);
    cylinder(d=bearing_id, h=bearing_width + 0.2, center=true, $fn=48);
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

///////////////////////////////////////////////////////////////
//  TEST PIECES (updated)
///////////////////////////////////////////////////////////////

module test_axle_block() {
  cube([30, 20, frame_height], center=true);
  translate([0, 0, frame_height / 2])
    cylinder(d=axle_shaft_diam, h=axle_length, $fn=48);
}

module test_hole_block() {
  difference() {
    cube([30, 20, frame_height], center=true);
    translate([0, 0, -frame_height / 2 - 2])
      cylinder(d=axle_hole_diam, h=frame_height + 4, $fn=48);
  }
}

module test_gear_axle() {
  gear_with_bore(axle_bore_diam);
}

module test_gear_bearing() {
  gear_with_bore(bearing_bore_diam);
}

module tests() {
  translate([-40, 0, 0]) test_axle_block();
  translate([40, 0, 0]) test_hole_block();
  translate([0, 30, 0]) test_gear_axle();
  translate([0, -30, 0]) test_gear_bearing();
}

///////////////////////////////////////////////////////////////
//  ASSEMBLY VIEW (no mirroring needed)
///////////////////////////////////////////////////////////////

module assembly() {
  // correct placement so spacers/nubs touch bearing/gear surfaces
  offset = gear_height / 2 + spacer_height;

  // lower frame
  color("red", 0.7)
    translate([0, 0, -offset])
      lower_frame(points_3x3);

  // gears
  color("silver", 0.9)
    gears_at_points(points_3x3);

  // bearings (visual)
  color("black", 0.3)
    bearings_at_points(points_3x3);

  // upper frame
  color("lime", 0.7)
    translate([0, 0, offset])
      upper_frame(points_3x3);
}

// WHAT TO RENDER?
assembly();
// tests();
