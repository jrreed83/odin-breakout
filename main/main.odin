package main

import       "core:fmt"
import       "core:math"
import       "core:math/linalg"
import       "core:time"
import rl    "vendor:raylib"
import libc  "core:c/libc"


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

ShapeType :: enum u8 {
    Rectangle,
    Circle,
    Line 
}

BoundingBox :: struct {
    min: [2] f32,  // upper left visually
    max: [2] f32   // lower right visually
}

bounding_box_center :: proc (e: Entity) -> [2] f32 {
    return {0.5*(e.min.x + e.max.x), 0.5*(e.min.y + e.max.y)}
}

bounding_box_radii :: proc (e: Entity) -> [2] f32 {
    return {0.5*(e.max.x - e.min.x), 0.5*(e.max.y - e.min.y)}
}

Entity :: struct {
    using box:    BoundingBox,
    shape_type:   ShapeType,
    velocity:     [2] f32,
    acceleration: [2] f32,
    mass:             f32,
    color:            rl.Color    
}

circle :: proc(center: [2] f32, radius: f32) -> Entity {
    return Entity {
        box        = {center-radius, center+radius},
        shape_type = .Circle 
    }
}
 
//Projectile :: struct {
//    using shape: Circle,
//    velocity:     [2] f32,
//    acceleration: [2] f32,
//    mass:             f32,
//    color:            rl.Color
//}

//Brick :: struct {
//    using shape: Rectangle,
//    velocity:     [2] f32,
//    acceleration: [2] f32,
//    mass:             f32,
//    color:            rl.Color,
//    visible:          bool
//}/

//Paddle :: struct {
//    using shape: Rectangle,
//    velocity:     [2] f32,
//    acceleration: [2] f32,
//    mass:             f32,
//    color:            rl.Color,
//    visible:          bool,
//}

//ball   : Entity  
//paddle : Entity
//bricks : [GRID_NUM_ROWS][GRID_NUM_COLS] Entity


collision :: proc(e1: Entity, e2: Entity) -> bool {
    // Uses Minkowski sum technique to determine if the circle collides 
    // with the ball.  In this case, we're extending the restangle by the
    // radis of the cirle

    c := bounding_box_center(e1)
    r := bounding_box_radii(e1)


    min_x, max_x := e2.min.x - r.x, e2.max.x + r.x 
    min_y, max_y := e2.min.y - r.y, e2.max.y + r.y 

    return min_x <= c.x && c.x <= max_x && min_y <= c.y && c.y <= max_y 
}


//setup_game :: proc() {
//    ball = Projectile {
//        shape = Circle {
//            radius = BALL_RADIUS,
//            center = {0.0,0.0},
//        },
//        velocity = {0.0, 0.0},
//        color    = BALL_COLOR ,
//    }
//
//    paddle = {
//        shape = Rectangle {
//            min = {0.5*SCREEN_WIDTH, SCREEN_HEIGHT-100},
//            max = {0.5*SCREEN_WIDTH + PADDLE_WIDTH, SCREEN_HEIGHT-100 + PADDLE_HEIGHT},
//        },
//        velocity = {0.0, 0.0},
//        color    = PADDLE_COLOR
//    }

//    brick_min: [2] f32 = {GRID_PADDING_X, GRID_PADDING_Y}
//    
//    for i in 0..<GRID_NUM_ROWS {
//        brick_min.x = GRID_PADDING_X
//        for j in 0..<GRID_NUM_COLS {
//            bricks[i][j] = {
//                shape = Rectangle {
///                    min = brick_min,
 //                   max = brick_min + {BRICK_WIDTH, BRICK_HEIGHT} 
//                }, 
//                color   = ROW_COLORS[i],
//                visible = true
 //           }
//            brick_min.x += (BRICK_WIDTH + BRICK_SPACING)
//        }
//        brick_min.y += (BRICK_HEIGHT + BRICK_SPACING)
//    }
    

//}

//ROW_COLORS : [6] rl.Color = {rl.PINK, rl.RED, rl.ORANGE, rl.YELLOW, rl.GREEN, rl.BLUE}

//draw_game :: proc() {
//    
//    rl.BeginDrawing()
//    defer rl.EndDrawing()
//
//    rl.ClearBackground(BACKGROUND_COLOR)
//
//    rl.DrawText(rl.TextFormat("Score: %d", score), 40, 40, 20, rl.WHITE)
//
//    for i in 0..<GRID_NUM_ROWS {
//        for j in 0..<GRID_NUM_COLS {
//            brick := bricks[i][j]
//            if brick.visible {
//                rl.DrawRectangle(
//                    i32(brick.min.x), 
//                    i32(brick.min.y),
//                    i32(brick.max.x-brick.min.x),
//                    i32(brick.max.y-brick.min.y),
//                    brick.color
//                )
//            }      
//        }
//    }
//}

main :: proc() {
    e1 := circle(center={0,0}, radius=1)
    e2 := circle(center={1,0}, radius=1)
    e3 := circle(center={2,2}, radius=0.9)
    fmt.println(collision(e1, e2))
    fmt.println(collision(e1, e3))
    fmt.println(collision(e2, e3))

    fmt.println(e2.box)
}