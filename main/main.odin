package main

import "core:fmt"
import "core:math"
import "core:time"
import rl "vendor:raylib"

BOARD_HEIGHT :: 1000
BOARD_WIDTH  :: 1000 


EntityKind :: enum u8 {
    Paddle,
    Block,
    Ball,
}

FRAME_RATE :: 30 

dt: f32 = 1.0 / FRAME_RATE

Side :: enum u8 {
    North, East, South, West
}

Entity :: struct {
    kind:        EntityKind,
    position: [2]f32, // northwest corner
    velocity: [2]f32,
    width:       f32, 
    height:      f32,
}

CollisionKind :: enum u8 {
    Paddle, Wall, Block, None
}

CollisionEvent :: struct {
    kind:  CollisionKind,
    index: u8,
    side:  Side
}

collision :: proc(state: ^GameState) -> CollisionEvent {

    ball, paddle, blocks := state.ball, state.paddle, state.blocks 

    // collision with paddle
    if ball.position.y + ball.height >= paddle.position.y {
        if paddle.position.x <= ball.position.x + ball.width && ball.position.x <= paddle.position.x + paddle.width {
            return CollisionEvent { kind = .Paddle, side = .North }
        }
    }

    // collision with blocks 

    // collistion with wall
    if ball.position.x + ball.width >= BOARD_WIDTH {
        return CollisionEvent { kind = .Wall, side = .East }
    }

    if ball.position.x <= 0 {
        return CollisionEvent { kind = .Wall, side = .West } 
    }

    if ball.position.y <= 0 {
        return CollisionEvent { kind = .Wall, side = .North }
    }

    if ball.position.y + ball.height >= BOARD_HEIGHT {
        return CollisionEvent { kind = .Wall, side = .South }
    }


    return CollisionEvent{ kind = .None }

}


GameState :: struct {
     ball:       Entity,
     paddle:     Entity,
     blocks: [32]Entity,

}

init_game_state :: proc() -> GameState {
    state := GameState {
        ball = Entity {
            kind     = .Ball,
            position = {0.2*BOARD_WIDTH, 0.5*BOARD_HEIGHT}, 
            width    = 10, 
            height   = 10,
            velocity = {500.0, 100.0}
        },
        paddle = Entity {
            kind     = .Paddle,
            position = {0.5*BOARD_WIDTH, BOARD_HEIGHT-40.0}, 
            width    = 60, 
            height   = 40
        }
    }

    for i in 0..<32 {
        state.blocks[i].kind = .Block 
    }

    return state 
}

update :: proc(state: ^GameState) -> bool {

    fmt.println(state.ball)
    // Check for collision
    collision_evt := collision(state)

    if collision_evt.kind == .Wall && collision_evt.side == .South {
        return false
    }
    
    if collision_evt.kind != .None {
        fmt.println(collision_evt)
        switch collision_evt.side {
            case .North, .South:
                state.ball.velocity.y = -state.ball.velocity.y
            case .West, .East:
                state.ball.velocity.x = -state.ball.velocity.x
        }

    }
    // time-step
    state.ball.position += state.ball.velocity*dt
    return true

}

run_game :: proc() {

    state := init_game_state()

    for i in 0..<200 {
        ok := update(&state)

        if !ok {
            fmt.println("Faiked")
            break
        }
        time.sleep(30 * time.Millisecond)
    }

}

draw :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.RAYWHITE)
    rl.DrawText("Congrats!", 500, 500, 20, rl.LIGHTGRAY)    
}

main :: proc() {
	rl.InitWindow(BOARD_WIDTH, BOARD_HEIGHT, "Tetroid")
	defer rl.CloseWindow() 
    rl.SetTargetFPS(30)

    state := init_game_state()

    cnt := 0 

    for !rl.WindowShouldClose() {

        // update game state
        if cnt < 1000 { 
            ok := update(&state)

            if !ok {
                time.sleep(time.Second)
                fmt.println("Closing...")
                break
            }
        }
        time.sleep(30 * time.Millisecond)

        draw()

    }
    //run_game()
}