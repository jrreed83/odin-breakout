package main 

import "core:fmt"

EntityType :: enum u8 {
    Ball,
    Paddle,
    Brick,
}


bounding_box :: proc (e: Entity) -> (min: [2] f32, max: [2] f32) {
    half :[2]f32 = 0.5*{e.width, e.height}

    min = e.pos - half 
    max = e.pos + half

    return min, max
}


Entity :: struct {
    id: int,

    type: EntityType,
    
    mass:    f32,
    visible: bool,   
    health:  u8,
    moving:  bool,
    
    acc: [2] f32,
    vel: [2] f32,
    pos: [2] f32, // center mass 

    height: f32,
    width:  f32, 

}

// @TODO: determine distance to collision point if not collided

handle_collision :: proc(e0: Entity, e1: Entity) {

	min, max := bounding_box(e1)

	// use Minkowski sum algorithm?
	px, py := e0.pos.x, e0.pos.x


	min_x := min.x - 0.5*e0.width
	max_x := max.x + 0.5*e0.width

	min_y := min.y - 0.5*e0.height
	max_y := max.y + 0.5*e0.height	

	if min_x <= px && px <= max_x && min_y <= py && py <= max_y {
		fmt.println("Collision")
	} else {

		// Use center of pass to determine relative positions
		fmt.println("No collision")
		if e0.pos.x < e1.pos.x {
			fmt.println("e0 to the left")

		}

		if e1.pos.x < e0.pos.x {
			fmt.println("e0 to the right")

		}

		if e0.pos.y < e1.pos.y {
			fmt.println("e0 above")

		}

		if e1.pos.y < e0.pos.y {
			fmt.println("e0 below")

		}

		// Determine if they intersect in next time step, assume we have a direction vector
		

	}
	


}

main :: proc() {
	

	e0 := Entity{pos={ 0, 0}, width=10, height=10}
	e1 := Entity{pos={ 0, 45}, width=10, height=10}

	handle_collision(e0, e1)
}