// https://gist.github.com/ggs67/ff6ba8caf5a1871d285c5c758dce0575
include <roundedcube.scad>

// PCB maximum width
pcb_x           = 72.7;
// PCB maximum height
pcb_y           = 60.4+3;
// PCB thickness, pretty much constant
pcb_thick       = 1.6;
// Free space under PCB
pcb_bottom      = 4.5;
// Free space over PCB
pcb_top         = 7.8;
//
internal_border = false;

// Box thickness, x sides
wall_x          = 2.5;
// Box thickness, y sides
wall_y          = 2.5;
// Box thickness, z sides
wall_z          = 3;
// Box borders radius
wall_radius     = 1;
// Top border %
wall_cover_step = 0.5;

// Battery wrapper
battery_x       = 52;
battery_y       = 17.5;
battery_z       = 15;

// screw_positions = [];
// Screw diameter
screw_dia       = 3.2;
// Arbitary screw positions
screw_positions = [
    [1.10+screw_dia/2,         17.9+screw_dia/2],
    [1.10+64.15+3*screw_dia/2, 17.9+screw_dia/2],
    [1.10+screw_dia/2,         17.9+34.4+3*screw_dia/2],
    [1.10+64.15+3*screw_dia/2, 17.9+34.4+3*screw_dia/2]
];
// (TODO) Dimensione dei bordini di supporto scheda e vite
screw_border    = 7;
// Use bolts
bolt            = true;
nut_dia         = 6.4;
nut_thick       = 2.45;

tolerance       = 1;

function get_full_width() = 2*wall_x + pcb_x;
function get_pcb_level() = wall_z + pcb_bottom + pcb_thick;

/* - - - - - - Asserts and messages - - - - - - - */

assert(wall_cover_step >= 0 && wall_cover_step < 1, "wall_cover_step: must be in interval 0 - 1!");

echo("To close box, you need a screw of ", pcb_thick + pcb_top + pcb_bottom + 2*wall_z, " mm length (head included).");

// Make a screw support
// (TODO) Di fatto è un cilindretto che schiaccia la scheda sopra-sotto
module screw_support(border, h)
{
    cylinder(h=h, d=border, $fn=50); 
}

// (TODO) Il buco della vite. Si forza un rendering del cerchio decente
module screw_hole(d, h)
{
    difference() {
        cylinder(h=h, d=d , $fn=50);
    }
}

// (TODO) Disegna il buco per la testa del bullone o per il dado
module nut(diameter, thickness)
{
    cylinder(h=thickness, d=diameter, $fn=6);
}

// (TODO) Fa la svasatura. Le viti hanno una apertura a 90°
module flaring(diameter)
{
    cylinder(h=diameter/2, d1=diameter, d2=0, $fn=50);
}

/* - - - - - - Enclosure modules - - - - - - - */

// (TODO) Disegna solamente il bordo della scatola
// Utilizzato per adesso solo per evitare che i supporti vite sbordino dal tappo
module side_box()
{
    size_x  = pcb_x + 2 * wall_x;
    size_y  = pcb_y + 2 * wall_y;
    size_z  = wall_z + pcb_top;
    inner_z = size_z - wall_z;

    difference() {
        // Outer walls
        translate([-wall_x/2, -wall_y/2, 0])
            roundedcube([size_x, size_y, size_z], false, wall_radius + wall_x, "z");
        
        // Inner walls
        translate([0, 0, 0])
            if (internal_border) roundedcube([pcb_x-tolerance, pcb_y-tolerance, size_z], false, wall_radius, "z");
            else cube([pcb_x-tolerance, pcb_y-tolerance, size_z]);
    }
}

module box()
{
    difference() {
        union() {
            // Box walls
            difference() {
                size_x  = pcb_x + 2 * wall_x;
                size_y  = pcb_y + 2 * wall_y;
                size_z  = wall_z + pcb_bottom + pcb_top + pcb_thick + wall_z * wall_cover_step;
                inner_z = size_z - wall_z;
                
                // Outer walls
                translate([-wall_x, -wall_y, 0])
                    roundedcube([size_x, size_y, size_z], false, wall_radius + wall_x, "z");
                
                // Inner walls
                translate([0, 0, wall_z])
                    // (TODO) i bordi interni possono essere sia stondati che squadrati
                    if (internal_border) roundedcube([pcb_x, pcb_y, inner_z], false, wall_radius, "z");
                    else cube([pcb_x, pcb_y, inner_z]);
                        
            }

            // Screw supports, from manual positions
            for (a = [ 0 : len(screw_positions) - 1 ]) {
                translate([screw_positions[a][0], screw_positions[a][1], wall_z])
                    screw_support(screw_border, pcb_bottom);
            }
        }

        // Screw holes, from manual positions
        for (a = [ 0 : len(screw_positions) - 1 ]) {
            translate([screw_positions[a][0], screw_positions[a][1], 0]) {
                screw_hole(screw_dia, wall_z + pcb_bottom);
                if (bolt)
                    nut(nut_dia, nut_thick);
            }
        }
    }
}

module cover()
{
    difference() {
        // (TODO) dimensioni degli scalini esterno ed interno.
        outer_step = wall_z * (1-wall_cover_step);
        inner_step = wall_z * wall_cover_step;
        
        union() {
            size_x  = pcb_x + 2 * wall_x;
            size_y  = pcb_y + 2 * wall_y;
            inner_z = pcb_bottom + pcb_top;
            // Cover
            translate([-wall_x, -wall_y, 0])
                roundedcube([size_x, size_y, outer_step], false, wall_radius + wall_x, "z");
            // Alignment border. May be squared
            translate([0, 0, outer_step])
                if (internal_border) roundedcube([pcb_x-tolerance, pcb_y-tolerance, inner_step], false, wall_radius, "z");
                else  cube([pcb_x-tolerance, pcb_y-tolerance, inner_step]);
            
            // Screw supports
            difference() {
                union() for (a = [ 0 : len(screw_positions) - 1 ])
                    translate([screw_positions[a][0], screw_positions[a][1], wall_z])
                        screw_support(screw_border, pcb_top);
                side_box();
            }
        }
        
        // Screw holes
        for (a = [ 0 : len(screw_positions) - 1 ])
            translate([screw_positions[a][0], screw_positions[a][1], 0]) {
                screw_hole(screw_dia, wall_z + pcb_top);
                if (bolt)
                    flaring(nut_dia);
            }
    }
}

/* - - - - - - Customizations (i.e. holes, drills) - - - - - - - */

module battery_holder()
{
    translate([0, 0, (battery_z + wall_z)/2])
    difference() {
        roundedcube([battery_x, battery_y, battery_z] + [2*wall_x, 2*wall_y, wall_z], true, wall_radius + wall_x, "z");
        translate([0, 0, wall_z]) cube([battery_x, battery_y, battery_z], true);
    }
}

module custom_box()
{
    translate([pcb_x/2, pcb_y + wall_y + battery_y/2, 0])
        battery_holder();
    difference() {
        // Draw the actual box
        box();
        
        pcb_level  = get_pcb_level();
        
        // Move origin to PCB top copper level
        translate([0, 0, pcb_level])
            // Put in this union top holes or other customizations
            union() {
                arm_h = 5;
                // ZIF "arm"
                translate([-wall_x, 0, 5]) cube([wall_x, 2, arm_h]);
            }
    }
}

module custom_cover()
{
    mirror([1,0,0]) // X Flip
    difference() {
        // Draw the actual cover
        cover();
        
        // Put in this union top holes or other customizations
        union() {
            // Display hole
            translate([7.85, 22]) cube([58.3, 30, wall_z]);
            // ZIF hole
            translate([0, 0, 0]) cube([34.5, 16.5, wall_z]);
            // ZIF "arm"
            translate([-wall_x, 0, 0]) cube([wall_x, 2, wall_z]);
            // Button
            translate([59.6 + 6, 8 , 0]) cylinder(h=wall_z, d=14.5);
            // Power pins
            translate([0, 29.5, 0]) cube([6, 7.5, wall_z]);
        }
    }
}

/* - - - - - - Renderings - - - - - - - */

module full_enclosure() {
        union() {
            custom_box();
            translate([0, 0, 2 * wall_z + pcb_bottom + pcb_thick + pcb_top]) rotate([0,180,0]) custom_cover();
        }
}

module only_box() {
    custom_box();
}

module only_cover() {
    custom_cover();
}
    
module all() {
    custom_box();
    full_width = get_full_width();
    translate([full_width*2,0,0])
        custom_cover();
}


// full_enclosure();
all();
// only_box();
// only_cover();
