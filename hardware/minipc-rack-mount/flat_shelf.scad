// =============================================================================
//  Flat 1U shelf generator for 10" racks (DeskPi RackMate)
//
//  Devices lie FLAT (on their largest face), ports/LEDs facing the rack front
//  through a faceplate window. One or more devices sit side by side per shelf.
//  Reuses the same rack faceplate + forgiving mounting slots as rack_mount.scad.
//
//    openscad -D shelf=\"ls1210gp\"            -o ls1210gp_shelf.stl flat_shelf.scad
//    openscad -D shelf=\"combo\"               -o minipc_ht801_shelf.stl flat_shelf.scad
//    openscad -D shelf=\"ls1210gp\" -D panel_w=250 -D slot_len=8 ...   (A1 one-piece)
//    openscad -D shelf=\"ls1210gp\" -D show_dev=true ...               (ghost preview)
// =============================================================================

shelf = "ls1210gp";

// ---- Device table (laid FLAT): [ name, width(across), depth, height ] -------
DEV = [
    [ "ls1210gp", 209, 126, 26   ],   // 8-port PoE switch
    [ "sg1005d",  140, 88,  23   ],   // 5-port switch
    [ "n100",     136, 125, 40   ],   // N100 router
    [ "cm3500",   145, 135, 44   ],   // modem (laid on its side)
    [ "minipc",   120, 115, 43   ],   // mini-PC
    [ "ht801",    100, 100, 29.5 ],   // ATA
];

// ---- Shelves : [ name, [device(s) side by side], back-mode, [tweaks?] ] -----
//   back   = "wall" (solid stop, front-port devices) | "open" (rear-port devices)
//   tweaks = optional list of [key, value]; supported keys:
//      "win"     -> [w, h, dx, dz]  override front window (per bay, centered + offsets)
//      "notches" -> [ [side, pos, w, h], ... ]  side="L"|"R" (depth=pos) | "F" (x-offset=pos)
//      "vent"    -> N  vent slots per bay   (default 3)
//      "strap"   -> N  strap-slot pairs cut through side walls (default 2 if open, else 0)
SHELVES = [
    [ "ls1210gp", [ "ls1210gp" ], "wall", [ ["vent", 4] ] ],                 // PoE switch, warm
    [ "sg1005d",  [ "sg1005d"  ], "wall", [] ],                              // 5-port switch
    [ "n100",     [ "n100"     ], "open", [ ["vent", 4] ] ],                 // router, warm
    [ "cm3500",   [ "cm3500"   ], "open", [] ],                              // modem
    [ "minipc",   [ "minipc"   ], "open", [ ["vent", 5] ] ],                 // mini-PC, hot
    [ "ht801",    [ "ht801"    ], "open", [] ],                              // ATA
];

// ---- 10" rack interface  *** VERIFY ***  ------------------------------------
u_mm     = 44.45;
panel_w  = 254;     // use 250 to print one-piece on a 256 bed
hole_dx  = 236;
edge_z   = 6.35;
screw_d  = 4.5;
slot_len = 12;      // use 8 for a 250mm panel

// ---- Structure --------------------------------------------------------------
clr       = 2.0;
face_t    = 3.0;
base      = 2.5;    // floor (chunky devices auto-promote to 2U, so 2.5 is safe)
wall      = 2.5;
front_lip = 4.0;
ledge     = 6.0;
ov        = 0.8;

show_dev = false;
$fn = 40;

// ---- Resolve shelf ----------------------------------------------------------
srow  = SHELVES[search([shelf], SHELVES)[0]];
items = srow[1];
back  = srow[2];

// Per-shelf tweak lookup ------------------------------------------------------
function tweak(key, dflt) = let(
    tw  = (len(srow) >= 4) ? srow[3] : [],
    sr  = search([key], tw, 0),
    idx = (len(sr) > 0 && len(sr[0]) > 0) ? sr[0][0] : -1
) (idx >= 0) ? tw[idx][1] : dflt;

function dev(name) = DEV[search([name], DEV)[0]];
function dw(i) = dev(items[i])[1];
function dd(i) = dev(items[i])[2];
function dh(i) = dev(items[i])[3];

n      = len(items);
maxh   = max([ for (i=[0:n-1]) dh(i) ]);
maxd   = max([ for (i=[0:n-1]) dd(i) ]);
// Auto-promote U based on (device + floor); forceable via tweak "u".
u_auto  = max(1, ceil((maxh + base) / u_mm));
u_count = tweak("u", u_auto);
panel_h = u_count * u_mm;
tray_d  = maxd + clr;

// Resolved tweaks -------------------------------------------------------------
vent_n  = tweak("vent",    3);
strap_n = tweak("strap",   (back == "open") ? 2 : 0);
win_ov  = tweak("win",     [-1, -1, 0, 0]);   // [-1, -1] => use full-face default
notches = tweak("notches", []);

// bay widths and X positions (side by side)
bayw   = [ for (i=[0:n-1]) dw(i) + 2*clr ];
totalw = wall + sum_to(n) ;
function sum_to(k) = (k==0) ? 0 : bayw[k-1] + wall + sum_to(k-1);
function bx0(i)    = -totalw/2 + wall + (i==0 ? 0 : sum_partial(i));
function sum_partial(i) = (i==0) ? 0 : bayw[i-1] + wall + sum_partial(i-1);
function bcx(i)    = bx0(i) + bayw[i]/2;     // bay center X

// =============================================================================
//  Helpers
// =============================================================================
module xslot(len, d, depth) {
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
        // Front window per bay (override via tweak "win" = [w, h, dx, dz])
        for (i = [0:n-1]) {
            def_w = dw(i) - 2*front_lip;
            def_h = min(dh(i), panel_h - base);
            ww = (win_ov[0] > 0) ? win_ov[0] : def_w;
            wh = (win_ov[1] > 0) ? win_ov[1] : def_h;
            wdx = win_ov[2];
            wdz = win_ov[3];
            translate([bcx(i) + wdx - ww/2, -face_t - 1, base + wdz])
                cube([ww, face_t + 2, wh]);
        }
        // Front-face notches (cable/antenna): cut from top of faceplate down by h
        for (nt = notches) if (nt[0] == "F")
            translate([nt[1] - nt[2]/2, -face_t - 1, panel_h - nt[3]])
                cube([nt[2], face_t + 2, nt[3] + 1]);
        // Rack mounting slots (bottom of panel + top of panel; always align with
        // rack holes for any integer U count)
        for (sx = [-1, 1], sz = [edge_z, panel_h - edge_z])
            translate([sx*hole_dx/2, -face_t - 1, sz])
                xslot(slot_len, screw_d, face_t + 2);
    }
}

module tray() {
    strap_l  = 22;                                       // slot length (along depth)
    strap_t  = 4;                                        // slot height (vertical)
    wall_top = min(base + maxh, panel_h);                // actual top of side walls
    strap_z  = wall_top - strap_t - 2;                   // sit inside wall, near top

    difference() {
        union() {
            // Floor with vent slots (vent_n slots per bay along width)
            difference() {
                translate([-totalw/2, -ov, 0]) cube([totalw, tray_d + ov, base]);
                for (i = [0:n-1])
                    for (gi = [0 : vent_n - 1]) {
                        // distribute slot centers across the device width
                        frac = (vent_n == 1) ? 0
                                             : (gi/(vent_n - 1) - 0.5);
                        cx   = bcx(i) + frac * (dw(i) - 18);
                        translate([cx - 5, ledge, -1])
                            cube([10, tray_d - 2*ledge, base + 2]);
                    }
            }
            // Side walls + dividers (capped at panel_h)
            for (i = [0:n]) {
                h = (i == 0) ? dh(0) : (i == n ? dh(n-1) : max(dh(i-1), dh(i)));
                x = (i == 0) ? -totalw/2
                             : (i == n ? totalw/2 - wall : bx0(i) - wall);
                translate([x, -ov, 0])
                    cube([wall, tray_d + ov, min(base + h, panel_h)]);
            }
            // Back stop (closed-back only)
            if (back == "wall")
                translate([-totalw/2, tray_d - ov, 0])
                    cube([totalw, wall + ov, min(base + maxh, panel_h)]);
        }
        // Strap slots cut through ALL side walls of each bay
        if (strap_n > 0)
            for (i = [0:n-1])
                for (s = [0 : strap_n - 1]) {
                    cy = (strap_n == 1)
                         ? tray_d/2
                         : ledge + (tray_d - 2*ledge - strap_l)
                                   * s / (strap_n - 1) + strap_l/2;
                    // Left wall of bay i
                    translate([bx0(i) - wall - 1, cy - strap_l/2, strap_z])
                        cube([wall + 2, strap_l, strap_t]);
                    // Right wall of bay i
                    translate([bx0(i) + bayw[i] - 1, cy - strap_l/2, strap_z])
                        cube([wall + 2, strap_l, strap_t]);
                }
        // Side-wall notches (cable/antenna): cut from top down by h
        for (nt = notches) {
            if (nt[0] == "L")
                translate([-totalw/2 - 1, nt[1] - nt[2]/2, panel_h - nt[3]])
                    cube([wall + 2, nt[2], nt[3] + 1]);
            if (nt[0] == "R")
                translate([totalw/2 - wall - 1, nt[1] - nt[2]/2, panel_h - nt[3]])
                    cube([wall + 2, nt[2], nt[3] + 1]);
        }
    }
}

module ghost() {
    color([0.25, 0.4, 0.55, 0.45])
        for (i = [0:n-1])
            translate([bcx(i) - dw(i)/2, 0, base])
                cube([dw(i), dd(i), dh(i)]);
}

color([0.85, 0.85, 0.88]) { faceplate(); tray(); }
if (show_dev) ghost();
