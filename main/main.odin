package main

import "core:fmt"
import "core:math"

BOARD_L :: 0
BOARD_R :: 256
BOARD_T :: 256
BOARD_B :: 0 

Vector :: struct { x, y: f32}

Paddle :: struct { position: f32, length: f32, speed: f32}

Ball :: struct { 
    position: Vector, 
    velocity: Vector,
    radius: f32
}

collide :: proc(ball: ^Ball) {
    vx := ball.velocity.x 
    vy := ball.velocity.y

    px := ball.position.x 
    py := ball.position.y


    tx := vx < 0 ? (BOARD_L - px)/vx : (BOARD_R - px)/vx
    ty := vy < 0 ? (BOARD_B - py)/vy : (BOARD_T - px)/vy

    time_to_collision := tx < ty ? tx : ty 

    xx := px + time_to_collision*vx 
    yy := py + time_to_collision*vy

    ball.position.x = xx 
    ball.position.y = yy 

    ball.velocity.x = -vx
    ball.velocity.y = +vy


}

run_game :: proc() {

    //ball := Ball{position = Vector{x=}}
    fmt.println("Running game")

    ball := Ball{
        position=Vector{128, 128}, 
        velocity=Vector{5.0, 1.0}
    }

    fmt.println(ball)
    collide(&ball)
    fmt.println(ball)

}

main :: proc() {
    run_game()
}