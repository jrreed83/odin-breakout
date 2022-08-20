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
PADDLE_MIN_X     :: 0.5*(SCREEN_WIDTH - PADDLE_WIDTH)    
PADDLE_MIN_Y     :: 600  
PADDLE_MAX_X     :: PADDLE_MIN_X + PADDLE_WIDTH 
PADDLE_MAX_Y     :: PADDLE_MIN_Y + PADDLE_HEIGHT
PADDLE_CENTER_X  :: 0.5*(PADDLE_MIN_X + PADDLE_MAX_X)

PADDLE_SPEED     :: 100

BALL_COLOR       :: rl.WHITE
BALL_RADIUS      :: 10 
BALL_MIN_X       :: PADDLE_CENTER_X - BALL_RADIUS 
BALL_MAX_X       :: BALL_MIN_X + 2*BALL_RADIUS 
BALL_MIN_Y       :: PADDLE_MIN_Y - 2.1*BALL_RADIUS 
BALL_MAX_Y       :: BALL_MIN_Y + 2*BALL_RADIUS

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
    using box:   BoundingBox,
    shape_type:  ShapeType,
    velocity:    [2] f32,
    mass:            f32,
    color:           rl.Color,
    visible:         bool   
}


ball   : Entity  
paddle : Entity
bricks : [GRID_NUM_ROWS][GRID_NUM_COLS] Entity


collision :: proc(e1: Entity, e2: Entity) -> (location: [2] f32, do_collide: bool) {
    // Uses Minkowski sum technique to determine if the
    // bounding boxes for the shapes collide.  If they do 
    // collide, we'll use a different algorithm to determine 
    // where they collide

    c := bounding_box_center(e1)
    r := bounding_box_radii(e1)


    min_x, max_x := e2.min.x - r.x, e2.max.x + r.x 
    min_y, max_y := e2.min.y - r.y, e2.max.y + r.y 

    do_collide = min_x <= c.x && c.x <= max_x && min_y <= c.y && c.y <= max_y 

    if do_collide {
        t: [4] f32 
        dE := linalg.normalize(e1.velocity)

        t[0] = (min_x - c.x) / dE.x
        t[1] = (max_x - c.x) / dE.x 
        t[2] = (min_y - c.y) / dE.y 
        t[3] = (max_y - c.y) / dE.y

        best_t: f32 = 0.0
        best_i: int = 0

        for ti, i in t {
            if ti < best_t && ti > 0 {
                best_t = ti
                best_i = i
            }
        }
        location = c + best_t*dE
    }

    return location, do_collide
}

collision_location:: proc(ball: Entity, e2: Entity) -> [2] f32 {
    return ---
}

update_game :: proc () {
    ball_acceleration :   [2] f32 = {0,0}
    paddle_acceleration : [2] f32 = {0,0}
    
    ////////////////////////////////////////////////////////////////////////////
    // User input 
    if 
    ////////////////////////////////////////////////////////////////////////////
    // physics 

    ////////////////////////////////////////////////////////////////////////////
    // collision detection

    ////////////////////////////////////////////////////////////////////////////
    // update
}


setup_game :: proc() {
    ball = {
        box        = {min={BALL_MIN_X, BALL_MIN_Y}, max={BALL_MAX_X, BALL_MAX_Y}},
        shape_type = .Circle,
        color      = BALL_COLOR,
    }

    paddle = {
        box        = {min={PADDLE_MIN_X, PADDLE_MIN_Y}, max={PADDLE_MAX_X, PADDLE_MAX_Y}},
        shape_type = .Rectangle,
        color      = BALL_COLOR,   
    }


    brick_min: [2] f32 = {GRID_PADDING_X, GRID_PADDING_Y}
    
    for i in 0..<GRID_NUM_ROWS {
        brick_min.x = GRID_PADDING_X
            for j in 0..<GRID_NUM_COLS {
                bricks[i][j] = {
                    box        = {min = brick_min, max = brick_min + {BRICK_WIDTH, BRICK_HEIGHT}},
                    shape_type = .Rectangle,
                    color      = ROW_COLORS[i],
                    visible    = true

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

    center := bounding_box_center(ball)
    radii  := bounding_box_radii(ball)
    rl.DrawCircle(
        i32(center.x), 
        i32(center.y),
        radii[0],
        ball.color
    )

    rl.DrawRectangle(
        i32(paddle.min.x), 
        i32(paddle.min.y),
        i32(paddle.max.x-paddle.min.x),
        i32(paddle.max.y-paddle.min.y),
        paddle.color
    )

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
 
    for !rl.WindowShouldClose() {

        update_game()
//
        time.sleep(16.2 * time.Millisecond)

        draw_game()

    }
}
