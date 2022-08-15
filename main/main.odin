package main

import "core:fmt"
import "core:math"

BOARD_L :: 0
BOARD_R :: 256
BOARD_T :: 256
BOARD_B :: 0 

Vector :: distinct [2]f32 

Foo :: struct {x, y:f32}

Paddle :: struct { 
    position: f32, 
    length: f32, 
    speed: f32
}

Ball :: struct { 
    position: Vector, 
    velocity: Vector,
    radius: f32
}

Wall :: enum {top, bottom, right, left}

min :: proc(v:Vector) -> f32 { 
    return v.x < v.y ? v.x : v.y 
}

// ball_destination :: proc(ball: ^Ball) -> (Wall, f32) {
//     // Determine the x/y limits of the ball flight
//     limits := Vector {
//         (ball.velocity.x < 0) ? f32(BOARD_L) : f32(BOARD_R),
//         (ball.velocity.y < 0) ? f32(BOARD_B) : f32(BOARD_T)
//     }

//     // Maximal flight times in the x and y direction
//     flight_times := (limits - ball.position) / ball.velocity 
 
//     wall: Wall 
//     time: f32 

//     if flight_times.x < flight_times.y {
        
//         flight_time := flight_times.x
//         if ball.velocity.x < 0 {
//             wall, time = Wall.left, 
//             return Wall.left, flight_time 
//         } else {
//             return Wall.right, flight_time 
//         }
        
//     } else {
//         flight_time := flight_times.y
//         if ball.velocity.y < 0 {
//             return Wall.bottom, flight_times 
//         } else {
//             return Wall.right, flight_times 
//         }
//     }

//     return wall, flight_time


// }

update_ball :: proc(ball: ^Ball) -> string {

    // Determine the x/y limits of the ball flight
    limits := Vector {
        (ball.velocity.x < 0) ? f32(BOARD_L) : f32(BOARD_R),
        (ball.velocity.y < 0) ? f32(BOARD_B) : f32(BOARD_T)
    }

    // Maximal flight times in the x and y direction
    flight_times := (limits - ball.position) / ball.velocity 
 
    // Determine the first collistion
    flight_time := min(flight_times)

    // ball position at wall
    ball.position += flight_time*ball.velocity

    // check if the paddle blocks the ball 

    // velocity at wall
    if flight_times.x < flight_times.y {
        ball.velocity.x = -ball.velocity.x
    } else {
        ball.velocity.y = -ball.velocity.y   
    }

    return "ok"
}



run_game :: proc() {

    fmt.println("Running game")

    ball := Ball{
        position=Vector{128, 128}, 
        velocity=Vector{3.0, 4.0},
        radius=1.0
    }

    fmt.println(ball)

    update_ball(&ball)
    fmt.println(ball)

    update_ball(&ball)
    fmt.println(ball)

    update_ball(&ball)
    fmt.println(ball)
}

main :: proc() {
    run_game()
    dst, time := ball_destination(nil)
    fmt.println(dst, time)
}