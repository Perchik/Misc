///////////////////////////////////////////////////////////////
//  3×3 Gear Grid – Frames, Spacers, Axles
//
//  Terminology:
//    SPACER:  6.7mm × 0.8mm disc at each of 9 points (both frames).
//             Supports BOTH gear faces, reduces contact area.
//    AXLE:    5mm post on LOWER frame for all gears.
//    AXLE HOLE: press-fit hole in UPPER frame for all gears.
//
//  Z-stack (global, once assembled):
//    Gears:             z = -2 .. +2  (gear_height = 4)
//    Lower frame:       translated to z = -(frame_height+spacer_height+gear_height/2)
//    Upper frame:       translated to z =  (gear_height/2+spacer_height)
//    -> lower spacers at z=-2, upper spacers at z=+2
///////////////////////////////////////////////////////////////

include <gears/gears.scad>;
include <BOSL2/std.scad>; // BOSL2
$fn = 64;
eps = .01;

///////////////////////////////////////////////////////////////
//  GLOBAL PARAMETERS + TOLERANCES
///////////////////////////////////////////////////////////////

// Tolerances
press_fit_tol = 0.13; // tight (axle holes in upper frame)
loose_fit_tol = 0.30; // loose (running fits on axles, etc.)

// Gear data
gear_teeth = 12;
gear_od = 28; // tip-to-tip OD
pa_deg = 20;

modul = gear_od / (gear_teeth + 2); // 28 / 14 = 2
center_dist = modul * gear_teeth; // pitch diameter

// Center spinner bearing (695) = 5 x 13 x 4 mm
bearing_id = 5;
bearing_od = 13;
bearing_width = 4;

// Gears
gear_height = 4; // gear thickness

// Axles
axle_shaft_diam = 5; // printed axle
axle_hole_diam = axle_shaft_diam - press_fit_tol; // press-fit in upper frame
axle_bore_diam = axle_shaft_diam + loose_fit_tol; // gear bore for all gears
axle_inset = 2; // how far the axle should extend into the upper frame

// cap dimensions,  2.2mm post, 4.6mm nub diam, 6.7mm diameter spacer, 0.6mm tall spacer
// frame hole is 13.3
// Spacers (all points, both frames)
spacer_diam = 6.7;
spacer_height = 0.6;

// Axle length (for all gears, from lower frame)
axle_length = gear_height + spacer_height + axle_inset;

// Frame pockets for bearing outer race at the center (key 5)
bearing_pocket_diam = bearing_od + press_fit_tol;
bearing_pocket_depth = bearing_width; // full plate thickness (radial press-fit)
bearing_pocket_floor = 2;

// Frame body
frame_height = bearing_pocket_depth + bearing_pocket_floor; // thickness of frame plate
frame_bar_width = 2; // width of bars / ring
frame_chamfer = 0.8; // tweak to taste (mm)

// Corner pad sizes (cosmetic / support zones)
corner_diam_all = 8;

// Center spinner shaft
center_shaft_round_d = bearing_id - loose_fit_tol; // shaft OD in bearing ID (slip fit)
center_shaft_clearance_d = bearing_id + loose_fit_tol; // hole through frame floors
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
//  BASIC HELPERS
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

// Central bearing pocket at key 5, cut from the frame plate
module center_bearing_pocket(points) {
  pc = point_from_key(points, 5);

  // Cut a cylindrical hole straight through the frame plate (0..frame_height)
  translate([pc[0], pc[1], 1])
    cylinder(d=bearing_pocket_diam, h=bearing_pocket_depth + 2, $fn=64);
}

module center_shaft_hole(points) {
  pc = point_from_key(points, 5);

  translate([pc[0], pc[1], -1])
    cylinder(d=center_shaft_clearance_d, h=frame_height + 2, $fn=48);
}

// Simple center shaft 
shaft_total_len = 2 * (frame_height + spacer_height + gear_height);
shaft_extra_each = 3; // sticks out each side, room for caps later

module center_shaft() {
  cylinder(
    d=center_shaft_round_d,
    h=shaft_total_len + 2 * shaft_extra_each,
    center=true,
    $fn=48
  );
}

///////////////////////////////////////////////////////////////
//  2D FRAME OUTLINE (plan view)
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
    [5, 8], // internal links
  ];

  union() {
    // Bars
    for (pair = key_pairs) {
      p1 = point_from_key(points, pair[0]);
      p2 = point_from_key(points, pair[1]);
      rect_between(p1, p2, w);
    }

    // Corner / pad circles 
    for (k = [1:9]) {
      p = point_from_key(points, k);
      // Center pad needs to be large enough to support the bearing pocket
      d =
        (k == 5) ? (bearing_pocket_diam + 2 * frame_bar_width) // center pad
        : corner_diam_all; // outer pads

      translate(p)
        circle(d=d, $fn=64);
    }

    // Central ring
    p4 = point_from_key(points, 4);
    p6 = point_from_key(points, 6);
    pc = point_from_key(points, 5);
    bigD = distance(p4, p6);

    translate(pc)
      difference() {
        circle(d=bigD + w, $fn=128);
        circle(d=bigD - w, $fn=128);
      }
  }
}

///////////////////////////////////////////////////////////////
//  UNIFIED FRAME MODULE (NO BEARINGS)
//  Spacers ALWAYS drawn at all 9 points on both frames.
//  LOWER frame draws axles at all 9 points.
//  UPPER frame subtracts axle holes at all 9 points.
///////////////////////////////////////////////////////////////
module frame(points, is_upper = false) {
  // Base frame + spacers + (optionally) axles
  difference() {
    union() {
      linear_extrude(height=frame_height) frame_shape_2d(points, frame_bar_width);

      // Features at each gear point
      for (key = [1:9]) {
        p = point_from_key(points, key);

        // Spacer sits on top of the frame body
        translate([p[0], p[1], frame_height])
          cylinder(d=spacer_diam, h=spacer_height, $fn=48);

        // Axle posts only on the LOWER frame
        if (!is_upper && key != 5) {
          translate([p[0], p[1], frame_height + spacer_height])
            cylinder(d=axle_shaft_diam, h=axle_length, $fn=48);
        }
      }
    }
    color("purple") center_bearing_pocket(points);
    center_shaft_hole(points=points);
  }
}

module upper_frame(points) {
  difference() {
    // Upper frame with spacers (no axles)
    frame(points, true);

    // Punch axle holes in the upper frame for all 9 positions
    color("blue")
      union() {
        for (key = [1:9]) {
          p = point_from_key(points, key);
          translate([p[0], p[1], frame_height - axle_inset])
            cylinder(
              d=axle_hole_diam,
              h=axle_length,
              $fn=48
            );
        }
      }
  }
}

///////////////////////////////////////////////////////////////
//  GEARS (centered at Z = -gear_height/2 .. +gear_height/2)
///////////////////////////////////////////////////////////////
module gear_with_bore(bore_diam) {
  translate([0, 0, -gear_height / 2])
    spur_gear(
      modul,
      gear_teeth,
      gear_height,
      bore_diam,
      pressure_angle=pa_deg,
      optimized=false
    );
}

module gears_at_points(points) {
  half_tooth_angle = 180 / gear_teeth; // for visual meshing

  for (i = [0:len(points) - 1]) {
    p = points[i];
    ang = (i % 2 == 1) ? half_tooth_angle : 0;

    // All gears now use the same axle bore
    translate([p[0], p[1], 0])
      rotate([0, 0, ang])
        gear_with_bore(axle_bore_diam);
  }
}

///////////////////////////////////////////////////////////////
//  SIMPLE TEST PIECES (AXLES / HOLES / SPACERS)
///////////////////////////////////////////////////////////////
module test_axle_block() {
  block_x = 30;
  block_y = 20;
  block_z = frame_height;

  union() {
    cube([block_x, block_y, block_z], center=true);
    translate([0, 0, block_z / 2 - .1])
      cylinder(d=axle_shaft_diam, h=axle_length, $fn=48);
  }
}

module test_hole_block() {
  block_x = 30;
  block_y = 20;
  block_z = frame_height;

  difference() {
    cube([block_x, block_y, block_z], center=true);
    translate([0, 0, -block_z / 2 - 2])
      cylinder(d=axle_hole_diam, h=block_z + 4, $fn=48);
  }
}

module test_spacer_only() {
  block_x = 30;
  block_y = 15;
  block_z = frame_height;

  union() {
    cube([block_x, block_y, block_z], center=true);
    // spacer (sits on top of frame body)
    translate([0, 0, block_z / 2 - .1])
      cylinder(d=spacer_diam, h=spacer_height + .1, $fn=48);
  }
}

module tests() {
  translate([-40, 0, 0]) test_axle_block();
  translate([40, 0, 0]) test_hole_block();
  translate([0, 40, 0]) test_spacer_only();
}

///////////////////////////////////////////////////////////////
//  ASSEMBLY VIEW (NO BEARINGS)
///////////////////////////////////////////////////////////////
// Gears:          -2 .. +2
// Lower frame top spacer should contact gear bottom at -2
// Upper frame bottom spacer should contact gear top at +2.

module assembly() {

  // Lower frame: local spacer top at (frame_height + spacer_height)
  // Shift so that -> global z = -gear_height/2 = -2
  lower_shift = -(frame_height + spacer_height + gear_height / 2);

  // Upper frame: local spacer bottom at z = -spacer_height
  // Shift so that -> global z = +gear_height/2 = +2
  upper_shift = +(frame_height - gear_height / 2 + frame_height + spacer_height);

  // Lower frame
  color("purple")
    translate([0, 0, lower_shift])
      frame(points_3x3);

  // Gears
  color("silver")
    gears_at_points(points_3x3);

  // Upper frame
  color("lime")
    translate([0, 0, upper_shift])
      mirror([0, 0, 1])
        upper_frame(points_3x3);

  // Center shaft
  pc = point_from_key(points_3x3, 5);
  color("red")
    translate([pc[0], pc[1], 0])
      center_shaft();
}

// -----------------------------------------------------------
// What to render?
// -----------------------------------------------------------
assembly();
//upper_frame(points_3x3);
//tests();
//frame(points_3x3);
