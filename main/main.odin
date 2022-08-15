package main

import "core:fmt"
import "core:math"

BOARD_L :: 0
BOARD_R :: 256
BOARD_T :: 256
BOARD_B :: 0 


Vector :: distinct [2]f32 

Rectangle :: struct {
    position: Vector, // northwest corner
    width: f32, 
    height: f32,
}

Paddle :: struct { 
    speed: f32,
    move_left: bool,
    using shape: Rectangle,
}

Ball :: struct { 
    velocity: Vector,    
    using shape: Rectangle,
}

Block :: struct {
    visible: bool,    
    using shape: Rectangle,
}

Walls :: struct {
    start_positions: [4]Vector,
    end_positions:   [4]Vector
}

Wall_Collision :: enum {top, bottom, right, left, none}

min :: proc(v:Vector) -> f32 { 
    return v.x < v.y ? v.x : v.y 
}

block_collision :: proc(projectile: ^Ball, block: ^Block) -> bool {
    // projectile up and to the left of block

    // If any of these are true then there is no collision, because there's
    // a gap between the blocks
    no_collide_from_left   := projectile.position.x + projectile.width  <= block.position.x
    no_collide_from_top    := projectile.position.y + projectile.height <= block.position.y
    no_collide_from_right  := block.position.x      + block.width       <= projectile.position.x 
    no_collide_from_bottom := block.position.y      + block.height      <= projectile.position.y 

    collision := !(no_collide_from_left || no_collide_from_top || no_collide_from_right || no_collide_from_bottom)

    return collision
}

paddle_collision :: proc(projectile: ^Ball, paddle: ^Paddle) -> bool {
    return false
}

//wall_collision :: proc(projectile: ^Rectangle) -> Wall_Collision {


//    return Wall_Collision.none
//}

// update_ball :: proc(ball: ^Ball) -> string {

//     // Determine the x/y limits of the ball flight
//     limits := Vector {
//         (ball.velocity.x < 0) ? f32(BOARD_L) : f32(BOARD_R),
//         (ball.velocity.y < 0) ? f32(BOARD_B) : f32(BOARD_T)
//     }

//     // Maximal flight times in the x and y direction
//     flight_times := (limits - ball.position) / ball.velocity 
 
//     // Determine the first collistion
//     flight_time := min(flight_times)

//     // ball position at wall
//     ball.position += flight_time*ball.velocity

//     // check if the paddle blocks the ball 

//     // velocity at wall
//     if flight_times.x < flight_times.y {
//         ball.velocity.x = -ball.velocity.x
//     } else {
//         ball.velocity.y = -ball.velocity.y   
//     }

//     return "ok"
// }



run_game :: proc() {

    fmt.println("Running game")


    a := Ball{
        shape = Rectangle {
            position = {5, 5}, 
            width=50, height=50
        }
    }

    b := Block{
        shape= Rectangle {
            position = {20, 10}, 
            width=60, height=40
        }
    }

    fmt.println(block_collision(&a, &b))
}

//const dim1 = {x: 5, y: 5, w: 50, h: 50}
//const dim2 = {x: 20, y: 10, w: 60, h: 40}

main :: proc() {
    run_game()

//    a := Rectangle{position = {5, 5}, width=50, height=50}
//    b := Rectangle{position = {20, 10}, width=60, height=40}

//    fmt.println(block_collision(&a, &b))
//    fmt.println(collision(nil, nil))
 //   dst, time := ball_destination(nil)
 //   fmt.println(dst, time)
}