package main

import "core:fmt"
import "core:math"
import "core:time"
import rl "vendor:raylib"
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
    pos:  [2]f32 ,
    size: [2]f32 ,
    vel:  [2]f32 ,
    acc:  [2]f32 ,
    mass:    f32 ,
    visible: bool 
}

ball   :    Entity 
paddle :    Entity
bricks : [3]Entity

// ball_pos:  [2]f32
// ball_vel:  [2]f32 
// ball_size: [2]f32

// paddle_pos:  [2]f32 
// paddle_vel:  [2]f32
// paddle_size: [2]f32 

// bricks_pos:     [3][2]f32 
// bricks_size:    [3][2]f32 
// bricks_visible: [3]   bool

// Collision :: enum u8 {
//     North, 
//     East, 
//     South, 
//     West,
//     None
// }

// collision_ball_paddle :: proc() -> Collision {

//     if ball_pos.y < paddle_pos.y && ball_pos.y + ball_size.y > paddle_pos.y && ball_vel.y > 0 {
//         if paddle_pos.x <= ball_pos.x + ball_size.x && ball_pos.x <= paddle_pos.x + paddle_size.x {
//             return .North
//         }
//     }    

//     if ball_pos.y > paddle_pos.y && paddle_pos.y + paddle_size.y > ball_pos.y && ball_vel.y < 0 {
//         if paddle_pos.x <= ball_pos.x + ball_size.x && ball_pos.x <= paddle_pos.x + paddle_size.x {
//             return .South
//         }
//     }  
//     return .None
// }

// collision_ball_bricks :: proc() -> (Collision, int) {
//     for i in 0..<len(bricks_pos) {
//         if ball_pos.y < bricks_pos[i].y && ball_pos.y + ball_size.y > bricks_pos[i].y && ball_vel.y > 0 {
//             if bricks_pos[i].x <= ball_pos.x + ball_size.x && ball_pos.x <= bricks_pos[i].x + bricks_size[i].x {
//                 return .North, i
//             }
//         }    

//         if ball_pos.y > bricks_pos[i].y && bricks_pos[i].y + bricks_size[i].y > ball_pos.y && ball_vel.y < 0 {
//             if bricks_pos[i].x <= ball_pos.x + ball_size.x && ball_pos.x <= bricks_pos[i].x + bricks_size[i].x {
//                 return .South, i
//             }
//         }
        
//         if ball_pos.x < bricks_pos[i].x && ball_pos.x + ball_size.x > bricks_pos[i].x && ball_vel.x > 0 {
//             if bricks_pos[i].y <= ball_pos.y + ball_size.y && ball_pos.y <= bricks_pos[i].y + bricks_size[i].y {
//                 return .West, i
//             }
//         }

//     }  
//     return .None, -1
// }

//collision_ball_wall :: proc() -> Collision {
//    
//    if ball_pos.x + ball_size.x >= SCREEN_WIDTH {
//        return .East
//    }
//
//    if ball_pos.x <= 0 {
//        return .West
//    }
//
//    if ball_pos.y <= 0 {
//        return .North
//    }
//
//    if ball_pos.y + ball_size.y >= SCREEN_HEIGHT {
//        return .South
//    }
//    return .None
//}


init_game_state :: proc() {

    ball = {
        pos  = {0.5*SCREEN_WIDTH, 0.5*SCREEN_HEIGHT},
        vel  = {0, BALL_SPEED},
        size = {10, 10},
    }

    paddle = {
        pos  = {0.5*SCREEN_WIDTH, SCREEN_HEIGHT-200},
        vel  = {0.0, 0.0},
        size = {60, 10},
    }

    //ball_pos  = {0.5*SCREEN_WIDTH, 0.5*SCREEN_HEIGHT}
    //ball_vel  = {0, BALL_SPEED}
    ///ball_size = {10.0, 10.0}

    //paddle_pos  = {0.5*SCREEN_WIDTH, SCREEN_HEIGHT-200}
    //paddle_vel  = {0.0, 0.0}
    //paddle_size = {60, 10}

    bricks[0] = {
        pos     = {100, 100},
        size    = {30, 30},
        visible = true
    }

    bricks[1] = {
        pos     = {130, 100},
        size    = {30, 30},
        visible = true
    }

    bricks[2] = {
        pos     = {160, 100},
        size    = {30, 30},
        visible = true
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
        if ball.pos.y < brick.pos.y && ball.pos.y + ball.size.y > brick.pos.y && ball.vel.y > 0 {
            if brick.pos.x <= ball.pos.x + ball.size.x && ball.pos.x <= brick.pos.x + brick.size.x {
                ball.vel.x    = -ball.vel.x
                bricks[i].visible = false
                break
            }
        }    

        if ball.pos.y > brick.pos.y && brick.pos.y + brick.size.y > ball.pos.y && ball.vel.y < 0 {
            if brick.pos.x <= ball.pos.x + ball.size.x && ball.pos.x <= brick.pos.x + brick.size.x {
                ball.vel.y    = -ball.vel.y
                bricks[i].visible = false
                break
            }
        }
        
        if ball.pos.x < brick.pos.x && ball.pos.x + ball.size.x > brick.pos.x && ball.vel.x > 0 {
            if brick.pos.y <= ball.pos.y + ball.size.y && ball.pos.y <= brick.pos.y + brick.size.y {
                ball.vel.x    = -ball.vel.x 
                bricks[i].visible = false
                break
            }
        }

    }  
//    brick_side, index := collision_ball_bricks()
//    if index >= 0 {
//        bricks_visible[index] = false
//    }
//    switch brick_side {
//    case .North, .South:
//        ball_vel.y = -ball_vel.y
//    case .West, .East:
//        ball_vel.x = -ball_vel.x
//    case .None:
//        fallthrough
//    } 

    // Make sure paddle stays in region

//    paddle_side := collision_ball_paddle() 
//    switch paddle_side {
//    case .North, .South:
 //       ball_vel.y = -ball_vel.y
 //       ball_vel.x = +ball_vel.x + 0.5*paddle_vel.x
 //   case .West, .East:
 //       ball_vel.x = -ball_vel.x
 //   case .None:
 //       fallthrough 
 //   }
//
//    wall_side := collision_ball_wall()
//    switch wall_side {
//    case .North, .South:
//        ball_vel.y = -ball_vel.y
//    case .West, .East:
//        ball_vel.x = -ball_vel.x
//    case .None:
//        fallthrough
//    }   

//    // time-step
//    ball_pos += ball_vel*dt

//    paddle_pos.x += paddle_vel.x*dt
//    paddle_pos.x = paddle_pos.x < 0 ? 0 : paddle_pos.x
//    paddle_pos.x = paddle_pos.x + paddle_size.x > SCREEN_WIDTH ? SCREEN_WIDTH - paddle_size.x: paddle_pos.x
}   


draw :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    rl.DrawText("Score: 0", 40, 40, 20, rl.WHITE)
    rl.DrawRectangle(
        i32(ball.pos.x), 
        i32(ball.pos.y),
        i32(ball.size.x),
        i32(ball.size.y),
        BALL_COLOR
    )

    rl.DrawRectangle(
        i32(paddle.pos.x), 
        i32(paddle.pos.y),
        i32(paddle.size.x),
        i32(paddle.size.y),
        PADDLE_COLOR
    )  

    for brick in bricks {
        if brick.visible {
            rl.DrawRectangle(
                i32(brick.pos.x), 
                i32(brick.pos.y),
                i32(brick.size.x),
                i32(brick.size.y),
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
            paddle.vel.x = -PADDLE_SPEED
		}

        if rl.IsKeyDown(.RIGHT) {
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
