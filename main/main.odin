package main

import      "core:fmt"
import      "core:math"
import      "core:time"
import rl   "vendor:raylib"
import libc "core:c/libc"


SCREEN_WIDTH     :: 850
SCREEN_HEIGHT    :: 650
FRAME_RATE       :: 60
SAMPLE_RATE      :: 60

BACKGROUND_COLOR :: rl.BLACK 

PADDLE_COLOR     :: rl.RED
PADDLE_WIDTH     :: 60  
PADDLE_HEIGHT    :: 20 
PADDLE_SPEED     :: 100

BALL_COLOR       :: rl.RED
BALL_RADIUS      :: 10 
BALL_SPEED       :: 300

BRICK_HEIGHT   :: 25
BRICK_WIDTH    :: 45 

GRID_NUM_ROWS  :: 6 
GRID_NUM_COLS  :: 10 
BRICK_SPACING  :: 10
GRID_PADDING_Y :: 50
GRID_PADDING_X :: 0.5*(SCREEN_WIDTH - BRICK_WIDTH * GRID_NUM_COLS - BRICK_SPACING * (GRID_NUM_COLS-1))

#assert(SCREEN_WIDTH == 850)

dt: f32 = 1.0 / SAMPLE_RATE

friction :f32 = 1.0 

score:= 0

Rectangle :: struct {
    min: [2] f32,  // upper left visually
    max: [2] f32   // lower right visually
}

Circle :: struct {
    center: [2] f32,
    radius:     f32
}

Projectile :: struct {
    using shape: Circle,

    velocity:     [2] f32,
    acceleration: [2] f32,
    mass:             f32,
    color:            rl.Color
}

Brick :: struct {
    using shape: Rectangle,

    velocity:     [2] f32,
    acceleration: [2] f32,
    mass:             f32,
    color:            rl.Color,
    visible:          bool
}

Paddle :: struct {
    using shape: Rectangle,

    velocity:     [2] f32,
    acceleration: [2] f32,
    mass:             f32,
    color:            rl.Color
}

ball   : Projectile 
paddle : Paddle
bricks : [GRID_NUM_ROWS][GRID_NUM_COLS] Brick


setup_game :: proc() {
    ball = Projectile {
        shape = Circle {
            radius = BALL_RADIUS,
            center = {0.0,0.0},
        },
        velocity = {0.0, 0.0},
        color    = BALL_COLOR ,
    }

    paddle = {
        shape = Rectangle {
            min = {0.5*SCREEN_WIDTH, SCREEN_HEIGHT-100},
            max = {0.5*SCREEN_WIDTH + PADDLE_WIDTH, SCREEN_HEIGHT-100 + PADDLE_HEIGHT},
        },
        velocity = {0.0, 0.0},
        color    = PADDLE_COLOR
    }

    brick_min: [2] f32 = {GRID_PADDING_X, GRID_PADDING_Y}
    
    for i in 0..<GRID_NUM_ROWS {
        brick_min.x = GRID_PADDING_X
        for j in 0..<GRID_NUM_COLS {
            bricks[i][j] = {
                shape = Rectangle {
                    min = brick_min,
                    max = brick_min + {BRICK_WIDTH, BRICK_HEIGHT} 
                }, 
                color   = ROW_COLORS[i],
                visible = true
            }
            brick_min.x += (BRICK_WIDTH + BRICK_SPACING)
        }
        brick_min.y += (BRICK_HEIGHT + BRICK_SPACING)
    }
    

}

ROW_COLORS : [6] rl.Color = {rl.PINK, rl.RED, rl.ORANGE, rl.YELLOW, rl.GREEN, rl.BLUE}

draw_game :: proc() {
    
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    rl.DrawText(rl.TextFormat("Score: %d", score), 40, 40, 20, rl.WHITE)

    for i in 0..<GRID_NUM_ROWS {
        for j in 0..<GRID_NUM_COLS {
            brick := bricks[i][j]
            if brick.visible {
                rl.DrawRectangle(
                    i32(brick.min.x), 
                    i32(brick.min.y),
                    i32(brick.max.x-brick.min.x),
                    i32(brick.max.y-brick.min.y),
                    brick.color
                )
            }      
        }
    }
}

main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "BreakOut")
    defer rl.CloseWindow() 

    setup_game()

    //cnt := 0 

    for !rl.WindowShouldClose() {


//        paddle.acc = {0,0}
//
//        // We make sure to move if we've pressed the key this frame
//        if rl.IsKeyDown(.LEFT) {
//            paddle.acc.x = -1000
//        }
//
///        if rl.IsKeyDown(.RIGHT) {
//            paddle.acc.x = +1000
//        }
//        
//        update_game()
//
//        time.sleep(16 * time.Millisecond)

        draw_game()

    }


}
/*
square :: proc(x: f32) -> f32 { return x * x }

setup_game :: proc() {

    ball = {
        shape = Circle{{}, BALL_RADIUS},
        velocity   = {0, BALL_SPEED},
        size  = {BALL_WIDTH, BALL_HEIGHT},
        color = BALL_COLOR
    }

    paddle = {
        pos   = {0.5*SCREEN_WIDTH, SCREEN_HEIGHT-100},
        vel   = {0.0, 0.0},
        size  = {PADDLE_WIDTH, PADDLE_HEIGHT},
        color = PADDLE_COLOR
    }

    idx := 0
    for i in 0..<GRID_NUM_ROWS {
        for j in 0..<GRID_NUM_COLS {
            bricks[i][j] = {
                pos     = {f32(GRID_PADDING_X+(BRICK_WIDTH+BRICK_SPACING)*j), f32(GRID_PADDING_Y+(BRICK_HEIGHT+BRICK_SPACING)*i)},
                size    = {BRICK_WIDTH, BRICK_HEIGHT},
                visible = true,
                color   = ROW_COLORS[i]
            }
            idx = idx + 1
        }
    }
}


update_score :: proc(color: rl.Color) {
    switch color {
    case rl.BLUE:   score += 1
    case rl.GREEN:  score += 2
    case rl.YELLOW: score += 3
    case rl.ORANGE: score += 4
    case rl.PINK:   score += 5
    case :          fallthrough  
    }
}

update_game :: proc() {

    // Update dynamics
    ball.pos = ball.pos + ball.vel*dt 

    // semi-implicit Euler with drag
    paddle.acc = paddle.acc - 5*paddle.vel
    paddle.vel = paddle.vel + paddle.acc * dt
    paddle.pos = paddle.pos + paddle.vel * dt + 0.5*paddle.acc*square(dt)
    


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

    for i in 0..<GRID_NUM_ROWS {
        for j in 0..<GRID_NUM_COLS {
            brick := bricks[i][j]
            if brick.visible {
                
                if ball.pos.y < brick.pos.y && ball.pos.y + ball.size.y > brick.pos.y && ball.vel.y > 0 {
                    if brick.pos.x <= ball.pos.x + ball.size.x && ball.pos.x <= brick.pos.x + brick.size.x {
                        ball.vel.y = -ball.vel.y
                        bricks[i][j].visible = false
                    
                        update_score(brick.color)


                        break
                    }
                }    

                if ball.pos.y > brick.pos.y && brick.pos.y + brick.size.y > ball.pos.y && ball.vel.y < 0 {
                    if brick.pos.x <= ball.pos.x + ball.size.x && ball.pos.x <= brick.pos.x + brick.size.x {
                        ball.vel.y = -ball.vel.y
                        bricks[i][j].visible = false
                        update_score(brick.color)
                    
                        break
                    }
                }
            
                if ball.pos.x < brick.pos.x && ball.pos.x + ball.size.x > brick.pos.x && ball.vel.x > 0 {
                    if brick.pos.y <= ball.pos.y + ball.size.y && ball.pos.y <= brick.pos.y + brick.size.y {
                        ball.vel.x = -ball.vel.x 
                        bricks[i][j].visible = false
                        update_score(brick.color)
                    
                        break
                    }
                }
            }
        }
    }

}   


draw_game :: proc() {
    
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

    for i in 0..<GRID_NUM_ROWS {
        for j in 0..<GRID_NUM_COLS {
            brick := bricks[i][j]
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
}

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "BreakOut")
	defer rl.CloseWindow() 

    setup_game()

    cnt := 0 

    for !rl.WindowShouldClose() {


        paddle.acc = {0,0}

        // We make sure to move if we've pressed the key this frame
		if rl.IsKeyDown(.LEFT) {
            paddle.acc.x = -1000
		}

        if rl.IsKeyDown(.RIGHT) {
            paddle.acc.x = +1000
        }
        
        update_game()

        time.sleep(16 * time.Millisecond)

        draw_game()

    }


}
*/