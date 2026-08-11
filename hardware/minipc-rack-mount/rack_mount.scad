// =============================================================================
//  Modular 10" rack mount generator  (DeskPi RackMate / 10-inch racks)
//
//  One reusable engine builds a rack faceplate + a row of vented cradle bays.
//  A "device" is defined only by its outer size; add a new item by adding a
//  row to the device table below -> the bays resize to fit it.
//
//  Mounting convention (all devices): the unit stands on its THIN edge, front
//  face to the rack front (shown through a faceplate window), big faces to the
//  dividers, so vents end up TOP/BOTTOM -> vertical convection (open floor +
//  open top). Devices taller/deeper than the cradle simply overhang (like a
//  cable modem in a partial cradle).
//
//    device="minipc"  -> 4 bays, fully cradled (120mm tall) on a 3U panel
//    device="cm3500"  -> 1 vented channel for an ARRIS CM3500 (145H x 135D x
//                        1RU W); cradled on a 3U panel, pokes ~16mm above top
//
//  Examples:
//    openscad -D device=\"minipc\"               -o minipc.stl   rack_mount.scad
//    openscad -D device=\"minipc\" -D split=true -D half=\"L\" -o L.stl rack_mount.scad
//    openscad -D device=\"cm3500\" -D panel_w=250 -D slot_len=8 -o cm3500_A1.stl rack_mount.scad
//    openscad -D device=\"minipc\" -D show_pc=true ...   (ghost preview)
// =============================================================================

device = "minipc";   // "minipc" | "cm3500"  (add more in the table below)

// ---- Device table : [ name, across, high, deep, bays, U, wall_vent, back ]
//   across   = thickness, packed across the rack
//   high     = device height (stands vertically); may exceed the panel
//   deep     = device depth into the rack; may exceed the cradle (overhang ok)
//   bays     = how many across
//   U        = faceplate height in rack units for this device
//   wall_vent= louvre the side walls? (big side faces need airflow)
//   back     = "ported" (back wall w/ port windows) | "open" (overhanging dev)
DEVICES = [
    [ "minipc", 43,    120, 115, 4, 3, false, "ported" ],
    [ "cm3500", 44.45, 145, 135, 1, 4, true,  "open"   ],   // W=1RU, measured
    [ "ht801",  29.5,  100, 100, 4, 3, true,  "open"   ],   // Grandstream ATA, measured
    [ "n100",   40,    136, 125, 4, 4, true,  "ported" ],   // Topton N100 4xETH router
];

// ---- Print splitting (even bay counts only) --------------------------------
split  = false;      // true -> cut into left/right halves for a small bed
half   = "both";     // "L", "R" (export one) or "both" (preview)
seam_d = 3.2;        // alignment-dowel holes at the center seam

// ---- 10" rack interface ----  *** VERIFY THESE AGAINST YOUR RACK ***  -------
u_mm     = 44.45;   // 1U
units    = 0;       // 0 = use the device's default U; or force a height here
bays     = 0;       // 0 = use the device's default bay count; or force here
panel_w  = 254;     // 10-inch faceplate width (use 250 to print on a 256 bed)
hole_dx  = 236;     // center-to-center between the LEFT and RIGHT rail holes
edge_z   = 6.35;    // rail hole inset from top/bottom (EIA 0.25")
screw_d  = 4.5;     // M4 clearance hole (use 6.5 for M6 racks)
slot_len = 12;      // horizontal mount-slot length (use 8 for a 250mm panel)

// ---- Structure --------------------------------------------------------------
clr         = 2.0;   // clearance around the device in its bay
max_depth   = 140;   // cap cradle depth so it fits a 10" rack (devices overhang)
face_t      = 3.0;   // front faceplate thickness
base        = 4.0;   // floor thickness
div_t       = 3.0;   // divider / wall thickness
wall        = 3.0;   // back wall thickness
ledge       = 5.0;   // floor ledge the device rests on (rest open for venting)
front_lip   = 4.0;   // faceplate overlap onto the front bezel (retains device)
back_margin = 6.0;   // back-wall overlap onto rear edges (ported mode)
back_gap    = 2.0;   // depth clearance behind the device
ov          = 0.8;   // interference overlap so everything fuses into one solid

show_pc = false;     // true = draw a ghost device for previews (NOT in STL)
$fn = 40;

// ---- Resolve the selected device -------------------------------------------
row     = DEVICES[search([device], DEVICES)[0]];
dev_t   = row[1];
dev_h   = row[2];
dev_d   = row[3];
n_bays  = bays > 0 ? bays : row[4];
w_vent  = row[6];
back    = row[7];

// ---- Derived ----------------------------------------------------------------
panel_units = units > 0 ? units : row[5];
panel_h  = panel_units * u_mm;
bay_w    = dev_t + 2*clr;
pitch    = bay_w + div_t;
total_w  = n_bays*bay_w + (n_bays + 1)*div_t;
cradle_d = min(dev_d + back_gap, max_depth);
wall_top = min(base + dev_h, panel_h);        // walls capped at the panel top
win_z0   = base + front_lip;
win_z1   = wall_top - front_lip;
win_zc   = (win_z0 + win_z1)/2;
win_h    = win_z1 - win_z0;
win_w    = dev_t - 2*front_lip;
mid_i    = floor(n_bays/2);
can_split = split && (n_bays % 2 == 0);

function bay_cx(i) = -total_w/2 + div_t + bay_w/2 + i*pitch;
function div_cx(i) = -total_w/2 + i*pitch + div_t/2;

// =============================================================================
//  Helpers
// =============================================================================
module xslot(len, d, depth) {                 // horizontal slot bored along +Y
    hull() for (s = [-1, 1])
        translate([s*(len - d)/2, 0, 0])
            rotate([-90, 0, 0]) cylinder(d = d, h = depth);
}

// =============================================================================
//  Parts
// =============================================================================
module faceplate() {
    difference() {
        translate([-panel_w/2, -face_t, 0]) cube([panel_w, face_t, panel_h]);
        for (i = [0:n_bays-1])                                   // front windows
            translate([bay_cx(i) - win_w/2, -face_t - 1, win_zc - win_h/2])
                cube([win_w, face_t + 2, win_h]);
        for (sx = [-1, 1], sz = [edge_z, panel_h - edge_z])      // mount slots
            translate([sx*hole_dx/2, -face_t - 1, sz])
                xslot(slot_len, screw_d, face_t + 2);
    }
}

module backwall() {                                              // ported mode
    bw_w = dev_t - 2*back_margin;
    bw_h = win_h + 2*front_lip - 2*back_margin;
    difference() {
        translate([-total_w/2, cradle_d - ov, 0])
            cube([total_w, wall + ov, wall_top]);
        for (i = [0:n_bays-1])
            translate([bay_cx(i) - bw_w/2, cradle_d - ov - 1, win_zc - bw_h/2])
                cube([bw_w, wall + 2, bw_h]);
    }
}

module floor_and_walls() {
    // Ventilated floor: a ledge frame per bay, open in the middle
    difference() {
        translate([-total_w/2, -ov, 0]) cube([total_w, cradle_d + ov, base]);
        for (i = [0:n_bays-1])
            translate([bay_cx(i) - (dev_t/2 - ledge), ledge, -1])
                cube([dev_t - 2*ledge, cradle_d - 2*ledge, base + 2]);
    }

    // n+1 dividers / side walls. Center divider doubled when splitting; the
    // big side faces get louvre slots when the device needs side airflow.
    for (i = [0:n_bays]) {
        cw = (can_split && i == mid_i) ? 2*div_t : div_t;
        difference() {
            translate([div_cx(i) - cw/2, -ov, 0])
                cube([cw, cradle_d + ov, wall_top]);
            if (w_vent)
                for (yy = [cradle_d*0.16 : (cradle_d*0.68)/4 : cradle_d*0.84])
                    translate([div_cx(i) - cw, yy, base + 8])
                        cube([cw + 2, cradle_d*0.10, wall_top - base - 16]);
        }
    }
}

// Alignment-dowel holes through the center seam (split only)
module seam_holes() {
    for (z = [win_zc - 35, win_zc + 35])
        translate([0, cradle_d*0.5, z]) rotate([0, 90, 0])
            cylinder(d = seam_d, h = 4*div_t + 2, center = true);
}

module solid_assembly() {
    if (can_split)
        difference() {
            union() { faceplate(); floor_and_walls(); if (back=="ported") backwall(); }
            seam_holes();
        }
    else { faceplate(); floor_and_walls(); if (back=="ported") backwall(); }
}

module half_cut(which) {
    big = 1000;
    intersection() {
        solid_assembly();
        if (which == "L") translate([-big, -big, -big/2]) cube([big, 2*big, big]);
        else              translate([0,    -big, -big/2]) cube([big, 2*big, big]);
    }
}

module ghost_devices() {
    color([0.25, 0.4, 0.55, 0.45])
        for (i = [0:n_bays-1])
            translate([bay_cx(i) - dev_t/2, 0, base])
                cube([dev_t, dev_d, dev_h]);
}

// =============================================================================
//  Output
// =============================================================================
if (!can_split) {
    color([0.85, 0.85, 0.88]) solid_assembly();
    if (show_pc) ghost_devices();
} else if (half == "both") {
    color([0.85, 0.85, 0.88]) {
        translate([-6, 0, 0]) half_cut("L");
        translate([ 6, 0, 0]) half_cut("R");
    }
} else {
    color([0.85, 0.85, 0.88]) half_cut(half);
}
