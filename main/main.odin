package main

import "core:fmt"
import "core:math"

BOARD_HEIGHT :: 1000
BOARD_WIDTH  :: 1000 

EntityKind :: enum u8 {
    paddle,
    block,
    ball,
    wall
}

dt: f32 = 1.0/30 

Side :: enum u8 {
    north, east, south, west
}

Entity :: struct {
    kind:        EntityKind,
    position: [2]f32, // northwest corner
    velocity: [2]f32,
    width:       f32, 
    height:      f32,
}

CollisionKind :: enum {
    paddle, wall, block, none
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
        if paddle.position.x <= ball.position.x && ball.position.x <= paddle.position.x + paddle.width {
            return CollisionEvent { kind = .paddle, side = .north }
        }
    }

    // collision with blocks 

    // collistion with wall
    if ball.position.x + ball.width >= BOARD_WIDTH {
        return CollisionEvent { kind = .wall, side = .east }
    }

    if ball.position.x <= 0 {
        return CollisionEvent { kind = .wall, side = .west } 
    }

    if ball.position.y <= 0 {
        return CollisionEvent { kind = .wall, side = .north }
    }

    if ball.position.y + ball.height >= BOARD_HEIGHT {
        return CollisionEvent { kind = .wall, side = .south }
    }


    return CollisionEvent{ kind = .none }

}

//collision :: proc(r0: ^Entity, r1: ^Entity) -> bool {
    // projectile up and to the left of block

    // If any of these are true then there is no collision, because there's a gap between the blocks
//    no_collide_from_left   := r0.position.x  + r0.width   <= r1.position.x
//    no_collide_from_top    := r0.position.y  + r0.height  <= r1.position.y
//    no_collide_from_right  := r1.position.x  + r1.width   <= r0.position.x 
//    no_collide_from_bottom := r1.position.y  + r1.height  <= r0.position.y 

//    collision := !(no_collide_from_left || no_collide_from_top || no_collide_from_right || no_collide_from_bottom)

//    return collision
//}

//collision(ball: ^Entity) -> Wall {
//    
//    if ball.position.x + ball.width >= BOARD_WIDTH {
//        return Wall.east
//   }

//    if ball.position.x <= 0 {
//        return Wall.west 
//    }

//     if ball.position.y <= 0 {
//         return Wall.north
//     }

//     if ball.position.y + ball.height >= BOARD_HEIGHT {
//         return Wall.south
//     }

//     return Wall.none
// }

GameState :: struct {
     ball:       Entity,
     paddle:     Entity,
     blocks: [32]Entity
}

init_game_state :: proc() -> GameState {
    state := GameState {
        ball = Entity {
            kind     = .ball,
            position = {0.5*BOARD_WIDTH, BOARD_HEIGHT-42.0}, 
            width    = 10, 
            height   = 10
        },
        paddle = Entity {
            kind     = .paddle,
            position = {0.5*BOARD_WIDTH, BOARD_HEIGHT-40.0}, 
            width    = 60, 
            height   = 40
        }
    }

    for i in 0..<32 {
        state.blocks[i].kind = .block 
    }
    
    return state 
}

update :: proc(state: ^GameState) {

    
    // Check for collision
    collision_evt := collision(state)

    fmt.println(collision_evt)
    // Update dynamics

    // Run step of dynamics

//     // Does ball collide with wall ...
//     // velocity updates
//     switch wall {
//     case .north:
//         ball.velocity.y = -ball.velocity.y
//     case .south:
//         ball.velocity.y = -ball.velocity.y
//     case .east:
//         ball.velocity.x = -ball.velocity.x 
//     case .west:
//         ball.velocity.x = -ball.velocity.x
//     case .none:
//         fallthrough 
//     }

//     // time-step
//     ball.position += ball.velocity*dt
}

run_game :: proc() {

    state := init_game_state()
    update(&state)
}

main :: proc() {
    run_game()
}