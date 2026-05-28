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

// ---- Shelves : which device(s) go on each shelf, side by side ---------------
SHELVES = [
    [ "ls1210gp", [ "ls1210gp" ]        ],
    [ "sg1005d",  [ "sg1005d"  ]        ],
    [ "n100",     [ "n100"     ]        ],
    [ "cm3500",   [ "cm3500"   ]        ],
    [ "combo",    [ "minipc", "ht801" ] ],   // shared 1U
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
base      = 2.5;    // thin floor so a ~43mm device still fits ~1U
wall      = 2.5;
front_lip = 4.0;
ledge     = 6.0;
back      = "wall"; // "wall" (solid back stop) | "open"
ov        = 0.8;

show_dev = false;
$fn = 40;

// ---- Resolve shelf ----------------------------------------------------------
items = SHELVES[search([shelf], SHELVES)[0]][1];
function dev(name) = DEV[search([name], DEV)[0]];
function dw(i) = dev(items[i])[1];
function dd(i) = dev(items[i])[2];
function dh(i) = dev(items[i])[3];

n      = len(items);
maxh   = max([ for (i=[0:n-1]) dh(i) ]);
maxd   = max([ for (i=[0:n-1]) dd(i) ]);
panel_h = max(u_mm, ceil(maxh / u_mm) * u_mm);
tray_d  = maxd + clr;

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
        for (i = [0:n-1]) {
            w = dw(i) - 2*front_lip;
            translate([bcx(i) - w/2, -face_t - 1, base])
                cube([w, face_t + 2, dh(i)]);
        }
        for (sx = [-1, 1], sz = [edge_z, panel_h - edge_z])
            translate([sx*hole_dx/2, -face_t - 1, sz])
                xslot(slot_len, screw_d, face_t + 2);
    }
}

module tray() {
    // Floor with vent slots, one bay region per device
    difference() {
        translate([-totalw/2, -ov, 0]) cube([totalw, tray_d + ov, base]);
        for (i = [0:n-1])
            for (gx = [-1:1:1])
                translate([bcx(i) + gx*(dw(i)/3.2) - 5, ledge, -1])
                    cube([10, tray_d - 2*ledge, base + 2]);
    }
    // Side walls + dividers between bays (height = each device, capped at panel)
    for (i = [0:n]) {
        h = (i == 0) ? dh(0) : (i == n ? dh(n-1) : max(dh(i-1), dh(i)));
        x = (i == 0) ? -totalw/2 : (i == n ? totalw/2 - wall : bx0(i) - wall);
        translate([x, -ov, 0]) cube([wall, tray_d + ov, base + min(h, panel_h)]);
    }
    // Back stop
    if (back == "wall")
        translate([-totalw/2, tray_d - ov, 0])
            cube([totalw, wall + ov, base + min(maxh, panel_h)]);
}

module ghost() {
    color([0.25, 0.4, 0.55, 0.45])
        for (i = [0:n-1])
            translate([bcx(i) - dw(i)/2, 0, base])
                cube([dw(i), dd(i), dh(i)]);
}

color([0.85, 0.85, 0.88]) { faceplate(); tray(); }
if (show_dev) ghost();
