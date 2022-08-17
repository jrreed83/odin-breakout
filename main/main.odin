package main

import "core:fmt"
import "core:math"
import "core:time"
import rl "vendor:raylib"

SCREEN_WIDTH  :: 850
SCREEN_HEIGHT :: 650
FRAME_RATE    :: 60

dt: f32 = 1.0 / FRAME_RATE

ball_pos:  [2]f32
ball_vel:  [2]f32 
ball_size: [2]f32

paddle_pos:  [2]f32 
paddle_vel:  [2]f32
paddle_size: [2]f32 

Collision :: enum u8 {
    North, 
    East, 
    South, 
    West,
    None
}


collision_ball_paddle :: proc() -> Collision {
    if ball_pos.y + ball_size.y > paddle_pos.y && ball_vel.y > 0 {
        if paddle_pos.x <= ball_pos.x + ball_size.x && ball_pos.x <= paddle_pos.x + paddle_size.x {
            return .North
        }
    }    
    return .None
}

collision_ball_wall :: proc() -> Collision {
    
    if ball_pos.x + ball_size.x >= SCREEN_WIDTH {
        return .East
    }

    if ball_pos.x <= 0 {
        return .West
    }

    if ball_pos.y <= 0 {
        return .North
    }

    if ball_pos.y + ball_size.y >= SCREEN_HEIGHT {
        return .South
    }
    return .None
}


init_game_state :: proc() {

    ball_pos  = {0.5*SCREEN_WIDTH, 0.5*SCREEN_HEIGHT}
    ball_vel  = {0, 100.0}
    ball_size = {10.0, 10.0}

    paddle_pos  = {0.5*SCREEN_WIDTH, SCREEN_HEIGHT-100}
    paddle_vel  = {0.0, 0.0}
    paddle_size = {60, 40}

}

update :: proc() {

    //fmt.println(state.ball)
    // Check for collision
    paddle_side := collision_ball_paddle() 
    switch paddle_side {
    case .North, .South:
        ball_vel.y = -ball_vel.y
    case .West, .East:
        ball_vel.x = -ball_vel.x
    case .None:
        fallthrough 
    }

    wall_side := collision_ball_wall()
    switch wall_side {
    case .North, .South:
        ball_vel.y = -ball_vel.y
    case .West, .East:
        ball_vel.x = -ball_vel.x
    case .None:
        fallthrough
    }   

    // time-step
    ball_pos += ball_vel*dt
    
    paddle_pos += paddle_vel*dt
}


draw :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()



    rl.ClearBackground(rl.RAYWHITE)

    rl.DrawRectangle(
        i32(ball_pos.x), 
        i32(ball_pos.y),
        i32(ball_size.x),
        i32(ball_size.y),
        rl.RED
    )

    rl.DrawRectangle(
        i32(paddle_pos.x), 
        i32(paddle_pos.y),
        i32(paddle_size.x),
        i32(paddle_size.y),
        rl.GREEN
    )  
}

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "BreakOut")
	defer rl.CloseWindow() 
    rl.SetTargetFPS(FRAME_RATE)

    init_game_state()

    cnt := 0 

    for !rl.WindowShouldClose() {

        // We make sure to move if we've pressed the key this frame
		if rl.IsKeyPressed(.LEFT) {
            paddle_pos.x -= 1.0
		}

        if rl.IsKeyPressed(.RIGHT) {
            paddle_pos.x += 1.0
        }
        // update game state
        
        update()

        time.sleep(16 * time.Millisecond)

        draw()

    }

}