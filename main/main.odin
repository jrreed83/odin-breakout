package main

import      "core:fmt"
import      "core:math"
import      "core:time"
import rl   "vendor:raylib"
import libc "core:c/libc"

SCREEN_WIDTH     :: 850
SCREEN_HEIGHT    :: 650

FRAME_RATE       :: 60
PADDLE_SPEED     :: 100
BALL_SPEED       :: 300
BACKGROUND_COLOR :: rl.BLACK 
PADDLE_COLOR     :: rl.RED
BALL_COLOR       :: rl.RED

dt: f32 = 1.0 / FRAME_RATE

score:= 0

Entity :: struct {
    pos:     [2]f32     ,
    size:    [2]f32     ,
    vel:     [2]f32     ,
    acc:     [2]f32     ,
    mass:       f32     ,
    visible:    bool    ,
    color:      rl.Color 
}

ball   :     Entity 
paddle :     Entity
bricks : [60]Entity

ROW_COLORS : [6]rl.Color = {rl.PINK, rl.RED, rl.ORANGE, rl.YELLOW, rl.GREEN, rl.BLUE}

init_game_state :: proc() {

    ball = {
        pos   = {0.5*SCREEN_WIDTH, 0.5*SCREEN_HEIGHT},
        vel   = {0, BALL_SPEED},
        size  = {10, 10},
        color = BALL_COLOR
    }

    paddle = {
        pos   = {0.5*SCREEN_WIDTH, SCREEN_HEIGHT-200},
        vel   = {0.0, 0.0},
        size  = {60, 10},
        color = PADDLE_COLOR
    }

    idx := 0
    for i in 0..<6 {
        for j in 0..<10 {
            bricks[idx] = {
                pos     = {f32(100+50*j), f32(100+30*i)},
                size    = {50, 30},
                visible = true,
                color   = ROW_COLORS[i]
            }
            idx = idx + 1
        }
    }
}

update :: proc() {

    // Update dynamics
    ball.pos   += dt * ball.vel 
    paddle.pos += dt * paddle.vel

    // Deal with paddle going to boundary
    paddle.pos.x = paddle.pos.x < 0 ? 0 : paddle.pos.x
    paddle.pos.x = paddle.pos.x + paddle.size.x > SCREEN_WIDTH ? SCREEN_WIDTH - paddle.size.x: paddle.pos.x


    // Check for wall collision
    if ball.pos.x + ball.size.x >= SCREEN_WIDTH {
        ball.vel.x = -ball.vel.x
    } else if ball.pos.x <= 0 {
        ball.vel.x = -ball.vel.x
    } else if ball.pos.y <= 0 {
        ball.vel.y = -ball.vel.y
    } else if ball.pos.y + ball.size.y >= SCREEN_HEIGHT {
        ball.vel.y = -ball.vel.y
    }

    // Check for paddle collision
    if ball.pos.y < paddle.pos.y && ball.pos.y + ball.size.y > paddle.pos.y && ball.vel.y > 0 {
        if paddle.pos.x <= ball.pos.x + ball.size.x && ball.pos.x <= paddle.pos.x + paddle.size.x {
            ball.vel.y = -ball.vel.y
            ball.vel.x = +ball.vel.x + 0.5*paddle.vel.x
        }
    }    

    if ball.pos.y > paddle.pos.y && paddle.pos.y + paddle.size.y > ball.pos.y && ball.vel.y < 0 {
        if paddle.pos.x <= ball.pos.x + ball.size.x && ball.pos.x <= paddle.pos.x + paddle.size.x {
            ball.vel.y = -ball.vel.y
            ball.vel.x = +ball.vel.x + 0.5*paddle.vel.x
        }
    }  

    // Check for brick collistion

    for brick, i in bricks {
        if brick.visible {

            if ball.pos.y < brick.pos.y && ball.pos.y + ball.size.y > brick.pos.y && ball.vel.y > 0 {
                if brick.pos.x <= ball.pos.x + ball.size.x && ball.pos.x <= brick.pos.x + brick.size.x {
                    ball.vel.y = -ball.vel.y
                    bricks[i].visible = false
                    
                    switch brick.color {
                    case rl.BLUE:   score += 1
                    case rl.GREEN:  score += 2
                    case rl.YELLOW: score += 3
                    case rl.ORANGE: score += 4
                    case rl.PINK:   score += 5
                    }

                    break
                }
            }    

            if ball.pos.y > brick.pos.y && brick.pos.y + brick.size.y > ball.pos.y && ball.vel.y < 0 {
                if brick.pos.x <= ball.pos.x + ball.size.x && ball.pos.x <= brick.pos.x + brick.size.x {
                    ball.vel.y = -ball.vel.y
                    bricks[i].visible = false
                    switch brick.color {
                    case rl.BLUE:   score += 1
                    case rl.GREEN:  score += 2
                    case rl.YELLOW: score += 3
                    case rl.ORANGE: score += 4
                    case rl.PINK:   score += 5
                    }
                    
                    break
                }
            }
            
            if ball.pos.x < brick.pos.x && ball.pos.x + ball.size.x > brick.pos.x && ball.vel.x > 0 {
                if brick.pos.y <= ball.pos.y + ball.size.y && ball.pos.y <= brick.pos.y + brick.size.y {
                    ball.vel.x = -ball.vel.x 
                    bricks[i].visible = false
                    switch brick.color {
                    case rl.BLUE:   score += 1
                    case rl.GREEN:  score += 2
                    case rl.YELLOW: score += 3
                    case rl.ORANGE: score += 4
                    case rl.PINK:   score += 5
                    }
                    
                    break
                }
            }

            // NEED AN ADDITIONAL ONE
        }

    }  
}   


draw :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    rl.DrawText(rl.TextFormat("Score: %d", score), 40, 40, 20, rl.WHITE)
    rl.DrawRectangle(
        i32(ball.pos.x), 
        i32(ball.pos.y),
        i32(ball.size.x),
        i32(ball.size.y),
        ball.color 
    )

    rl.DrawRectangle(
        i32(paddle.pos.x), 
        i32(paddle.pos.y),
        i32(paddle.size.x),
        i32(paddle.size.y),
        paddle.color
    )  

    for brick in bricks {
        if brick.visible {
            rl.DrawRectangle(
                i32(brick.pos.x), 
                i32(brick.pos.y),
                i32(brick.size.x),
                i32(brick.size.y),
                brick.color
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
            //event = .MOVE_LEFT
            paddle.vel.x = -PADDLE_SPEED
		}

        if rl.IsKeyDown(.RIGHT) {
            //event = .MOVE_RIGHT
            paddle.vel.x = +PADDLE_SPEED
        }

        if rl.IsKeyReleased(.LEFT) || rl.IsKeyReleased(.RIGHT) {
            paddle.vel.x = 0
            paddle.vel.y = 0
        } 
        // update game state
        
        update()

        time.sleep(16 * time.Millisecond)

        draw()

    }

    tmp: [64]u8 
    //a := fmt.bprintf(tmp[:], "Score %d", 10)

    //c : [64]libc.char = {0 = 'a', 5 ='b'}

    //b : [^]libc.char = c[:]
    //b := ([^]libc.char)(&c) // raw_data: converts to a multipointer
    //libc.printf(cstring(b))
    //fmt.println(a)

    //b: cstring = "Hello there"

    a: [2]f32 = {1.0, 5.3}
    b: [2]f32 = {2.1, 4.7}

    fmt.println(a+b)

}
