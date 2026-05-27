// =============================================================================
//  10" Rack 4-bay vertical mount for AMD Ryzen 7 mini PCs
//  Target rack : DeskPi RackMate (10-inch / "mini rack"), 3U faceplate
//
//  Each PC stands VERTICALLY on its thin (43mm) edge so several pack across
//  one faceplate. Power-button face -> rack FRONT (window), rear ports -> BACK.
//  Because the units are packed across, the big sticker faces sit next to the
//  dividers and the VENTS end up on the TOP and BOTTOM -> vertical convection:
//  cool air in through the open floor, hot air out the open top.
//
//  Units are millimetres. Print flat on the faceplate.
//  Cradle STL:        openscad -o mount4.stl minipc_10in_rack_4bay.scad
//  Preview with PCs:  openscad -D show_pc=true ...
// =============================================================================

// ---- Mini PC, oriented for vertical packing (measured outer size) ----------
slot_across = 43;    // X : device THICKNESS  -> packed across the rack
slot_high   = 120;   // Z : device WIDTH      -> now the vertical height
slot_deep   = 115;   // Y : device DEPTH      -> into the rack (front=power)
clr         = 2.0;   // clearance around the PC in its bay

n_bays      = 4;     // how many PCs across

// ---- 10" rack interface ----  *** VERIFY THESE AGAINST YOUR RACK ***  -------
u_mm     = 44.45;   // 1U
units    = 3;       // faceplate height in U (a 120mm-tall PC needs 3U)
panel_w  = 254;     // 10-inch faceplate width
hole_dx  = 236;     // center-to-center between the LEFT and RIGHT rail holes
edge_z   = 6.35;    // rail hole inset from top/bottom (EIA 0.25")
screw_d  = 4.5;     // M4 clearance hole (use 6.5 for M6 racks)
slot_len = 12;      // horizontal mount-slot length -> tolerance for hole_dx

// ---- Structure --------------------------------------------------------------
face_t      = 3.0;   // front faceplate thickness
base        = 4.0;   // floor thickness
div_t       = 3.0;   // divider / outer-wall thickness
wall        = 3.0;   // back wall thickness
ledge       = 5.0;   // floor ledge the PC rests on (rest is open for venting)
front_lip   = 4.0;   // faceplate overlap onto the PC front bezel (retains PC)
back_margin = 6.0;   // back-wall overlap onto the PC rear edges (retains PC)
back_gap    = 2.0;   // depth clearance behind the PC
ov          = 0.8;   // interference overlap so everything fuses into one solid

show_pc = false;     // true = draw ghost PCs for previews (NOT part of STL)
$fn = 40;

// ---- Derived ----------------------------------------------------------------
panel_h = units * u_mm;                       // 133.35 for 3U
bay_w   = slot_across + 2*clr;                // inner bay width
pitch   = bay_w + div_t;                      // bay-to-bay spacing
total_w = n_bays*bay_w + (n_bays + 1)*div_t;  // overall cradle width
floor_d = slot_deep + back_gap;               // floor / divider depth
dev_z0  = base;                               // PC rests on the floor ledge
top_z   = dev_z0 + slot_high;                 // PC top (divider/back-wall top)
win_zc  = dev_z0 + slot_high/2;               // window vertical center
win_w   = slot_across - 2*front_lip;          // front window width
win_h   = slot_high   - 2*front_lip;          // front window height

function bay_cx(i) = -total_w/2 + div_t + bay_w/2 + i*pitch;   // bay X center

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

        // Per-bay front window (power button / USB-C / USB-A / audio)
        for (i = [0:n_bays-1])
            translate([bay_cx(i) - win_w/2, -face_t - 1, win_zc - win_h/2])
                cube([win_w, face_t + 2, win_h]);

        // Four rail mounting slots (top + bottom of the 3U panel)
        for (sx = [-1, 1], sz = [edge_z, panel_h - edge_z])
            translate([sx*hole_dx/2, -face_t - 1, sz])
                xslot(slot_len, screw_d, face_t + 2);
    }
}

module backwall() {
    bw_w = slot_across - 2*back_margin;
    bw_h = slot_high   - 2*back_margin;
    difference() {
        translate([-total_w/2, floor_d - ov, 0])
            cube([total_w, wall + ov, top_z]);
        for (i = [0:n_bays-1])
            translate([bay_cx(i) - bw_w/2, floor_d - ov - 1, win_zc - bw_h/2])
                cube([bw_w, wall + 2, bw_h]);
    }
}

module floor_and_dividers() {
    // Ventilated floor: a ledge frame per bay, open in the middle
    difference() {
        translate([-total_w/2, -ov, 0]) cube([total_w, floor_d + ov, base]);
        for (i = [0:n_bays-1])
            translate([bay_cx(i) - (slot_across/2 - ledge), ledge, -1])
                cube([slot_across - 2*ledge, slot_deep - 2*ledge, base + 2]);
    }

    // n+1 dividers / outer walls, full PC height
    for (i = [0:n_bays])
        translate([-total_w/2 + i*pitch, -ov, 0])
            cube([div_t, floor_d + ov, top_z]);
}

module ghost_pcs() {
    color([0.25, 0.4, 0.55, 0.45])
        for (i = [0:n_bays-1])
            translate([bay_cx(i) - slot_across/2, 0, dev_z0])
                cube([slot_across, slot_deep, slot_high]);
}

module assembly() {
    color([0.85, 0.85, 0.88]) {
        faceplate();
        floor_and_dividers();
        backwall();
    }
    if (show_pc) ghost_pcs();
}

assembly();
