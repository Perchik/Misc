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
eps = 0.01;

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
bearing_pocket_depth = bearing_width;
bearing_pocket_floor = 2;

// Frame body
frame_height = bearing_pocket_depth + bearing_pocket_floor; // thickness of frame plate
frame_bar_width = 2; // width of bars / ring
frame_chamfer = 0.8; // tweak to taste (mm)

// Corner pad sizes (cosmetic / support zones)
corner_diam_all = 8;

// Center spinner shaft & journals (HEX)
// Across-flats for the hex shaft
center_shaft_hex_af = 3.0; // try 3.0mm AF (2 perimeters in journal wall)
center_hex_clearance = press_fit_tol; // clearance in journal hex hole, etc.

// Outer diameter of journal that rides in 5mm bearing ID
center_shaft_round_d = bearing_id - press_fit_tol;

// Hole through frame floors must clear the hex corners
// Hex circumradius R = AF / sqrt(3); diameter = 2R
center_shaft_clearance_d = 2 * (center_shaft_hex_af / sqrt(3)) + loose_fit_tol;

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
// Regular hexagon, across-flats = af
module hex2d(af) {
  R = af / sqrt(3); // circumradius
  polygon(
    points=[
      for (i = [0:5]) [R * cos(60 * i), R * sin(60 * i)],
    ]
  );
}
// Central bearing pocket at key 5, cut from the frame plate
module center_bearing_pocket(points) {
  pc = point_from_key(points, 5);

  // Pocket starts just above the floor and overshoots the top by eps
  translate([pc[0], pc[1], bearing_pocket_floor - eps])
    cylinder(
      d=bearing_pocket_diam,
      h=bearing_pocket_depth + 2 * eps,
      $fn=64
    );
}

// Shaft clearance hole through frame floors
module center_shaft_hole(points) {
  pc = point_from_key(points, 5);

  // Slightly below and above to avoid coplanar faces
  translate([pc[0], pc[1], -eps])
    cylinder(
      d=center_shaft_clearance_d,
      h=frame_height + 2 * eps,
      $fn=48
    );
}

// Simple center shaft (round only for now)
// We'll add a square middle later.
shaft_total_len = 2 * (frame_height + spacer_height + gear_height);
shaft_extra_each = 3; // sticks out each side, room for caps later

module center_shaft() {
  shaft_len = shaft_total_len + 2 * shaft_extra_each;

  translate([0, 0, -shaft_len / 2])
    linear_extrude(height=shaft_len)
      hex2d(center_shaft_hex_af);
}
// Journal: cylinder in the bearing, hex hole for hex shaft
module center_journal() {
  journal_len = bearing_width + 2 * eps; // a hair longer than the bearing

  difference() {
    // Outer cylinder: fits in bearing ID
    cylinder(
      d=center_shaft_round_d,
      h=journal_len,
      center=true,
      $fn=64
    );

    // Inner hex hole: slides over hex shaft with a bit of clearance
    translate([0, 0, -journal_len / 2 - eps])
      linear_extrude(height=journal_len + 2 * eps)
        hex2d(center_shaft_hex_af + center_hex_clearance);
  }
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
//  UNIFIED FRAME MODULE (NO BEARINGS YET)
//  Spacers ALWAYS drawn at all 9 points on both frames.
//  LOWER frame draws axles at all 9 points (except center).
//  UPPER frame subtracts axle holes at all 9 points.
///////////////////////////////////////////////////////////////
module frame(points, is_upper = false) {
  difference() {
    union() {
      // Frame body
      linear_extrude(height=frame_height, convexity=2)
        frame_shape_2d(points, frame_bar_width);

      // Features at each gear point
      for (key = [1:9]) {
        if (key != 5) {
          p = point_from_key(points, key);

          // Spacer sits on top of the frame body
          // Slight overlap into frame and above to avoid coplanar
          translate([p[0], p[1], frame_height - eps])
            cylinder(
              d=spacer_diam,
              h=spacer_height + 2 * eps,
              $fn=48
            );

          // Axle posts only on the LOWER frame, skip center
          if (!is_upper) {
            translate([p[0], p[1], frame_height + spacer_height - eps])
              cylinder(
                d=axle_shaft_diam,
                h=axle_length + 2 * eps,
                $fn=48
              );
          }
        }
      }
    }

    // center features (subtractive)
    center_bearing_pocket(points);
    center_shaft_hole(points);
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
          translate([p[0], p[1], frame_height - axle_inset - eps])
            cylinder(
              d=axle_hole_diam,
              h=axle_length + 2 * eps,
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
  // Slightly extend above/below to avoid coplanar with spacers
  translate([0, 0, -gear_height / 2 - eps])
    spur_gear(
      modul,
      gear_teeth,
      gear_height + 2 * eps,
      bore_diam,
      pressure_angle=pa_deg,
      optimized=false
    );
}
// Gear with HEX bore for the center gear
module gear_with_hex_bore(af) {
  hex_r = af / sqrt(3); // circumradius

  translate([0, 0, -gear_height / 2])
    difference() {

      // The gear body
      spur_gear(
        modul,
        gear_teeth,
        gear_height,
        bore=0, // we will subtract our own bore
        pressure_angle=pa_deg,
        optimized=false
      );

      // Subtract hex bore
      translate([0, 0, -eps])
        linear_extrude(height=gear_height + 2 * eps)
          polygon(
            points=[
              for (i = [0:5]) [hex_r * cos(60 * i), hex_r * sin(60 * i)],
            ]
          );
    }
}

module gears_at_points(points) {
  half_tooth_angle = 180 / gear_teeth; // for visual meshing

  for (i = [0:len(points) - 1]) {
    p = points[i];
    ang = (i % 2 == 1) ? half_tooth_angle : 0;
    key = i + 1;

    // All gears now use the same axle bore
    translate([p[0], p[1], 0])
      rotate([0, 0, ang])

      if (key == 5)
        gear_with_hex_bore(center_shaft_hex_af);
      else
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
    translate([0, 0, block_z / 2 - 0.1])
      cylinder(
        d=axle_shaft_diam,
        h=axle_length,
        $fn=48
      );
  }
}

module test_hole_block() {
  block_x = 30;
  block_y = 20;
  block_z = frame_height;

  difference() {
    cube([block_x, block_y, block_z], center=true);
    translate([0, 0, -block_z / 2 - 2])
      cylinder(
        d=axle_hole_diam,
        h=block_z + 4,
        $fn=48
      );
  }
}

module test_spacer_only() {
  block_x = 30;
  block_y = 15;
  block_z = frame_height;

  union() {
    cube([block_x, block_y, block_z], center=true);
    // spacer (sits on top of frame body)
    translate([0, 0, block_z / 2 - 0.1])
      cylinder(
        d=spacer_diam,
        h=spacer_height + 0.1,
        $fn=48
      );
  }
}

module tests() {
  translate([-40, 0, 0]) test_axle_block();
  translate([40, 0, 0]) test_hole_block();
  translate([0, 40, 0]) test_spacer_only();
}

///////////////////////////////////////////////////////////////
//  ASSEMBLY VIEW (NO CENTER BEARING SHAFT KEYING YET)
///////////////////////////////////////////////////////////////
// Gears:          -2 .. +2
// Lower frame top spacer should contact gear bottom at -2
// Upper frame bottom spacer should contact gear top at +2.

module assembly() {

  // Lower frame: local spacer top at (frame_height + spacer_height)
  // Shift so that -> global z = -gear_height/2 = -2 (approx; eps may nudge)
  lower_shift = -(frame_height + spacer_height + gear_height / 2);

  // Upper frame: local spacer bottom at z = -spacer_height
  // Shift so that -> global z = +gear_height/2 = +2
  upper_shift = +(frame_height - gear_height / 2 + frame_height + spacer_height);

  // Journals: one in each bearing pocket
  bearing_center_local = bearing_pocket_floor + bearing_pocket_depth / 2;
  // Lower journal (in lower frame's bearing)
  color("orange")
    translate([pc[0], pc[1], lower_shift + bearing_center_local])
      center_journal();

  // Upper journal (in upper frame's bearing)
  color("orange")
    translate([pc[0], pc[1], upper_shift - bearing_center_local])
      center_journal();

  // Lower frame
  color("purple")
    translate([0, 0, lower_shift])
      frame(points_3x3);

  // Gears
  color("silver")
    gears_at_points(points_3x3);

  // --- Bearing visuals (one in each frame pocket) ---
  bearing_center_local = bearing_pocket_floor + bearing_pocket_depth / 2;

  // Lower bearing
  color("gray", 0.6)
    translate([pc[0], pc[1], lower_shift + bearing_center_local])
      bearing_visual();

  // Upper bearing (mirrored frame: subtract local z)
  color("gray", 0.6)
    translate([pc[0], pc[1], upper_shift - bearing_center_local])
      bearing_visual();

  // Upper frame
  // color("lime")
  //   translate([0, 0, upper_shift])
  //     mirror([0, 0, 1])
  //       upper_frame(points_3x3);

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
//center_shaft();
//center_journal();
//gear_with_hex_bore(af = center_shaft_hex_af);
