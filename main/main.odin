package main

import "core:fmt"
import "core:math"
import "core:time"
import rl "vendor:raylib"

SCREEN_WIDTH     :: 850
SCREEN_HEIGHT    :: 650

FRAME_RATE       :: 60
PADDLE_SPEED     :: 100
BALL_SPEED       :: 150 
BACKGROUND_COLOR :: rl.BLACK 
PADDLE_COLOR     :: rl.RED
BALL_COLOR       :: rl.RED

dt: f32 = 1.0 / FRAME_RATE

score:= 0
ball_pos:  [2]f32
ball_vel:  [2]f32 
ball_size: [2]f32

paddle_pos:  [2]f32 
paddle_vel:  [2]f32
paddle_size: [2]f32 

bricks_pos:     [3][2]f32 
bricks_size:    [3][2]f32 
bricks_visible: [3]   bool

Collision :: enum u8 {
    North, 
    East, 
    South, 
    West,
    None
}

Foo :: struct {
    a: int
}

collision_ball_paddle :: proc() -> Collision {

    if ball_pos.y < paddle_pos.y && ball_pos.y + ball_size.y > paddle_pos.y && ball_vel.y > 0 {
        if paddle_pos.x <= ball_pos.x + ball_size.x && ball_pos.x <= paddle_pos.x + paddle_size.x {
            return .North
        }
    }    

    if ball_pos.y > paddle_pos.y && paddle_pos.y + paddle_size.y > ball_pos.y && ball_vel.y < 0 {
        if paddle_pos.x <= ball_pos.x + ball_size.x && ball_pos.x <= paddle_pos.x + paddle_size.x {
            return .South
        }
    }  
    return .None
}

collision_ball_bricks :: proc() -> (Collision, int) {
    for i in 0..<len(bricks_pos) {
        if ball_pos.y < bricks_pos[i].y && ball_pos.y + ball_size.y > bricks_pos[i].y && ball_vel.y > 0 {
            if bricks_pos[i].x <= ball_pos.x + ball_size.x && ball_pos.x <= bricks_pos[i].x + bricks_size[i].x {
                return .North, i
            }
        }    

        if ball_pos.y > bricks_pos[i].y && bricks_pos[i].y + bricks_size[i].y > ball_pos.y && ball_vel.y < 0 {
            if bricks_pos[i].x <= ball_pos.x + ball_size.x && ball_pos.x <= bricks_pos[i].x + bricks_size[i].x {
                return .South, i
            }
        }
        
        if ball_pos.x < bricks_pos[i].x && ball_pos.x + ball_size.x > bricks_pos[i].x && ball_vel.x > 0 {
            if bricks_pos[i].y <= ball_pos.y + ball_size.y && ball_pos.y <= bricks_pos[i].y + bricks_size[i].y {
                return .West, i
            }
        }

    }  
    return .None, -1
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
    ball_vel  = {0, BALL_SPEED}
    ball_size = {10.0, 10.0}

    paddle_pos  = {0.5*SCREEN_WIDTH, SCREEN_HEIGHT-200}
    paddle_vel  = {0.0, 0.0}
    paddle_size = {60, 10}

    bricks_pos     = {{100, 100}, {130, 100}, {160, 100}}
    bricks_size    = {{30, 20}, {30, 20}, {30, 20}}
    bricks_visible = {true, true, true} 
}

update :: proc() {

    brick_side, index := collision_ball_bricks()
    if index >= 0 {
        bricks_visible[index] = false
    }
    switch brick_side {
    case .North, .South:
        ball_vel.y = -ball_vel.y
    case .West, .East:
        ball_vel.x = -ball_vel.x
    case .None:
        fallthrough
    } 

    // Make sure paddle stays in region

    paddle_side := collision_ball_paddle() 
    switch paddle_side {
    case .North, .South:
        ball_vel.y = -ball_vel.y
        ball_vel.x = +ball_vel.x + 0.5*paddle_vel.x
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

    paddle_pos.x += paddle_vel.x*dt
    paddle_pos.x = paddle_pos.x < 0 ? 0 : paddle_pos.x
    paddle_pos.x = paddle_pos.x + paddle_size.x > SCREEN_WIDTH ? SCREEN_WIDTH - paddle_size.x: paddle_pos.x
}   


draw :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    rl.DrawText("Score: 0", 40, 40, 20, rl.WHITE)
    rl.DrawRectangle(
        i32(ball_pos.x), 
        i32(ball_pos.y),
        i32(ball_size.x),
        i32(ball_size.y),
        BALL_COLOR
    )

    rl.DrawRectangle(
        i32(paddle_pos.x), 
        i32(paddle_pos.y),
        i32(paddle_size.x),
        i32(paddle_size.y),
        PADDLE_COLOR
    )  

    for i in 0..<len(bricks_pos) {
        if bricks_visible[i] {
            rl.DrawRectangle(
                i32(bricks_pos[i].x), 
                i32(bricks_pos[i].y),
                i32(bricks_size[i].x),
                i32(bricks_size[i].y),
                rl.GREEN
            )
        }  
    }
}

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "BreakOut")
	defer rl.CloseWindow() 

    init_game_state()

    cnt := 0 

    for !rl.WindowShouldClose() {

        // We make sure to move if we've pressed the key this frame
		if rl.IsKeyDown(.LEFT) {
            paddle_vel.x = -PADDLE_SPEED
		}

        if rl.IsKeyDown(.RIGHT) {
            paddle_vel.x = +PADDLE_SPEED
        }

        if rl.IsKeyReleased(.LEFT) || rl.IsKeyReleased(.RIGHT) {
            paddle_vel.x = 0
            paddle_vel.y = 0
        } 
        // update game state
        
        update()

        time.sleep(16 * time.Millisecond)

        draw()

    }

    tmp: [64]u8 
    a := fmt.bprintf(tmp[:], "Score %d", 10)
    fmt.println(a)
}