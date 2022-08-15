package main

import "core:fmt"
import "core:math"

BOARD_L :: 0
BOARD_R :: 256
BOARD_T :: 256
BOARD_B :: 0 

Vector :: distinct [2]f32 

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

min :: proc(v:Vector) -> f32 { 
    return v.x < v.y ? v.x : v.y 
}

update_ball :: proc(ball: ^Ball) {

    limits := Vector {
        (ball.velocity.x < 0) ? f32(BOARD_L) : f32(BOARD_R),
        (ball.velocity.y < 0) ? f32(BOARD_B) : f32(BOARD_T)
    }

    flight_times := (limits - ball.position) / ball.velocity 
 
    flight_time := min(flight_times)

    ball.position += flight_time*ball.velocity

    if flight_times.x < flight_times.y {
        ball.velocity.x = -ball.velocity.x
    } else {
        ball.velocity.y = -ball.velocity.y   
    }

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

    b := Vector{1.0, 5.3}

    c := Vector{2.0, 5.2}

    fmt.println(c/b)
}