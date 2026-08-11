// =============================================================================
//  10" Rack mount cradle for an AMD Ryzen 7 mini PC
//  Target rack : DeskPi RackMate (10-inch / "mini rack"), 2U faceplate
//  Orientation : PC sits flat, top sticker up, POWER-BUTTON face to the front,
//                rear port cluster to the back, both VENTED SIDE faces fully
//                open to the left / right of the rack for airflow.
//
//  Units are millimetres. Designed to be FDM printed flat on the faceplate.
//  Render the cradle:   openscad -o mount.stl minipc_10in_rack_mount.scad
//  Preview with PC:     openscad -D show_pc=true ...
// =============================================================================

// ---- Mini PC outer size (measured) -----------------------------------------
pc_w = 120;   // X : across the rack  (the two VENTED faces point left / right)
pc_d = 115;   // Y : into the rack    (front = power button, rear = ports)
pc_h = 43;    // Z : vertical         (top sticker up, rubber feet down)

clr  = 2.0;   // clearance added around the PC on each side so it drops in

// ---- 10" rack interface  ----  *** VERIFY THESE AGAINST YOUR RACK ***  ------
// DeskPi RackMate / generic 10-inch values. The mounting holes are SLOTS, so a
// few mm of error in hole_dx is tolerated, but check with a caliper if unsure.
u_mm     = 44.45;   // 1U
units    = 2;       // faceplate height in U (PC is 43mm tall -> needs 2U)
panel_w  = 254;     // 10-inch faceplate width
hole_dx  = 236;     // center-to-center between the LEFT and RIGHT rail holes
edge_z   = 6.35;    // rail hole inset from top/bottom of panel (EIA 0.25")
screw_d  = 4.5;     // M4 clearance hole  (use 6.5 for M6 racks)
slot_len = 12;      // horizontal slot length -> +/-(slot_len-screw_d)/2 play

// ---- Structure --------------------------------------------------------------
face_t    = 3.0;    // faceplate thickness
base      = 3.5;    // bottom tray thickness
wall      = 3.0;    // curb / rear-lip / gusset thickness
curb_h    = 8.0;    // height of side locating curbs (LOW so vents stay open)
front_lip = 4.0;    // faceplate overlap onto the PC front bezel (retains PC)
back_gap  = 2.0;    // gap behind PC before the rear lip
vent_face = true;   // add cooling slots in the faceplate above the PC window
ov        = 0.8;    // interference overlap so all parts fuse into one solid

show_pc = false;    // true = draw a ghost PC for previews (NOT part of STL)
$fn = 48;

// ---- Derived ----------------------------------------------------------------
panel_h  = units * u_mm;            // 88.9 for 2U
cav_w    = pc_w + 2*clr;            // inner cavity width
tray_d   = pc_d + clr + back_gap;   // tray length front->rear lip
pc_z0    = base;                    // PC rests on the tray
win_w    = pc_w - 2*front_lip;      // front window opening
win_h    = pc_h - 2*front_lip;
win_zc   = pc_z0 + pc_h/2;          // window vertical center

// =============================================================================
//  Helpers
// =============================================================================

// Horizontal slot lying in the X-Z plane, bored through +Y for `depth`.
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

        // Front port / power-button window
        translate([-win_w/2, -face_t - 1, win_zc - win_h/2])
            cube([win_w, face_t + 2, win_h]);

        // Four rail mounting slots (top + bottom hole of the 2U panel)
        for (sx = [-1, 1], sz = [edge_z, panel_h - edge_z])
            translate([sx*hole_dx/2, -face_t - 1, sz])
                xslot(slot_len, screw_d, face_t + 2);

        // Optional cooling slots above the window
        if (vent_face) {
            vz0 = win_zc + win_h/2 + 6;     // start above the window
            vz1 = panel_h - 9;
            if (vz1 - vz0 > 12)
                for (gx = [-3:1:3])
                    translate([gx*11 - 2, -face_t - 1, vz0])
                        cube([4, face_t + 2, vz1 - vz0]);
        }
    }
}

module cradle() {
    out_w = cav_w + 2*wall;   // full outer width (tray runs under the curbs)

    // Full-width bottom tray (overlaps the faceplate) with a few floor vents
    difference() {
        translate([-out_w/2, -ov, 0]) cube([out_w, tray_d + ov, base]);
        for (gx = [-2:1:2])
            translate([gx*22 - 5, tray_d*0.18, -1])
                cube([10, tray_d*0.64, base + 2]);
    }

    // Low side locating curbs (only the bottom few mm of the vented faces).
    // They sit on the tray (overlap in Z) and bite into the faceplate (-ov).
    for (s = [-1, 1])
        translate([s == 1 ? cav_w/2 : -(cav_w/2 + wall), -ov, 0])
            cube([wall, tray_d + ov, base + curb_h]);

    // Rear lip / back stop (kept low so the rear ports stay clear)
    translate([-out_w/2, tray_d - ov, 0])
        cube([out_w, wall + ov, base + curb_h]);

    // Side gussets bracing the cradle to the faceplate (stiffens the cantilever).
    // Overlap into the curb top (gz0) and into the faceplate (-ov) so they fuse.
    g_len = 40;                    // short: only braces the tray near the front
    g_top = base + curb_h + 10;    // low so the side vents stay open
    gz0   = base + curb_h - 2;
    for (s = [-1, 1])
        translate([s == 1 ? cav_w/2 : -(cav_w/2 + wall), 0, 0])
            rotate([90, 0, 90])
                linear_extrude(wall)
                    polygon([[-ov, gz0],
                             [-ov, g_top],
                             [g_len, gz0]]);
}

module ghost_pc() {
    color([0.25, 0.4, 0.55, 0.45])
        translate([-pc_w/2, 0, pc_z0]) cube([pc_w, pc_d, pc_h]);
}

module assembly() {
    color([0.85, 0.85, 0.88]) {
        faceplate();
        cradle();
    }
    if (show_pc) ghost_pc();
}

assembly();
