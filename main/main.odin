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
UPDATE_RATE      :: FRAME_RATE
REFRESH_TIME     :  time.Duration : time.Duration(16*time.Millisecond)

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
BALL_RADIUS      :: 8
BALL_MIN_X       :: PADDLE_CENTER_X - BALL_RADIUS -5
BALL_MAX_X       :: BALL_MIN_X + 2*BALL_RADIUS 
BALL_MIN_Y       :: PADDLE_MIN_Y - 10*BALL_RADIUS 
BALL_MAX_Y       :: BALL_MIN_Y + 2*BALL_RADIUS

BALL_SPEED       :: 300

BRICK_HEIGHT   :: 25
BRICK_WIDTH    :: 45 

GRID_NUM_ROWS  :: 6 
GRID_NUM_COLS  :: 10 
BRICK_SPACING  :: 10
GRID_PADDING_Y :: 50
GRID_PADDING_X :: 0.5*(SCREEN_WIDTH - BRICK_WIDTH * GRID_NUM_COLS - BRICK_SPACING * (GRID_NUM_COLS-1))

dt: f32 = 1.0 / UPDATE_RATE

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

Edge :: enum int {
    North, South, East, West
}

bounding_box_center :: proc (e: Entity) -> [2] f32 {
    return {0.5*(e.min.x + e.max.x), 0.5*(e.min.y + e.max.y)}
}

bounding_box_radii :: proc (e: Entity) -> [2] f32 {
    return {0.5*(e.max.x - e.min.x), 0.5*(e.max.y - e.min.y)}
}

paused := false 

Entity :: struct {
    using box:   BoundingBox,
    shape_type:  ShapeType,
    acceleration: [2] f32,
    velocity:     [2] f32,
    mass:             f32,
    color:            rl.Color,
    visible:          bool   
}


ball   : Entity  
paddle : Entity
bricks : [GRID_NUM_ROWS][GRID_NUM_COLS] Entity
walls  : [4] Entity 

collision :: proc(e1: Entity, e2: Entity) -> bool {
    // Uses Minkowski sum technique to determine if the
    // bounding boxes for the shapes collide.  If they do 
    // collide, we'll use a different algorithm to determine 
    // where they collide

    c := bounding_box_center(e1)
    r := bounding_box_radii(e1)


    min_x, max_x := e2.min.x - r.x, e2.max.x + r.x 
    min_y, max_y := e2.min.y - r.y, e2.max.y + r.y 

    return min_x <= c.x && c.x <= max_x && min_y <= c.y && c.y <= max_y 

}

collision_location:: proc(ball: Entity, e2: Entity) -> [2] f32 {
    return ---
}

update_game :: proc () {

    
    ////////////////////////////////////////////////////////////////////////////
    // User input 
    if rl.IsKeyPressed(.SPACE) {
        paused = !paused
    }

    if paused { return }

    ball.acceleration = {0,0}
    paddle.acceleration = {0,0}    
    if rl.IsKeyDown(.LEFT) {
        paddle.acceleration.x = -1000
    }

    if rl.IsKeyDown(.RIGHT) {
        paddle.acceleration.x = +1000
    }

    
    ////////////////////////////////////////////////////////////////////////////

    // physics

    // 1. Paddle: using some notion of drag, using semi-implicit Euler,
    // meaning that the bounding box is updated using the new velocity.  If you calculate the
    // limit of the velocity recurrence relation, the max velocity is 
    // paddle.acceleration / drag. 
    paddle.acceleration += -5*paddle.velocity 
    paddle.velocity += paddle.acceleration*dt
    paddle.min += paddle.velocity*dt + 0.5*paddle.acceleration * (dt*dt) 
    paddle.max += paddle.velocity*dt + 0.5*paddle.acceleration * (dt*dt) 
    
    // 2. Ball
    ball.min += ball.velocity*dt 
    ball.max += ball.velocity*dt 

    ////////////////////////////////////////////////////////////////////////////
    // collision detection
    c: [2]f32
    r: [2]f32
    // 1. Check to see if the paddle has collided with the wall.
    c, r = bounding_box_center(paddle), bounding_box_radii(paddle)
    for wall in walls {
        min_x, max_x := wall.min.x - r.x, wall.max.x + r.x 
        min_y, max_y := wall.min.y - r.y, wall.max.y + r.y 
        if min_x <= c.x && c.x <= max_x && min_y <= c.y && c.y <= max_y {

            // TODO(jrr): should there be some variable indicating that a collision has occured
            if paddle.velocity.x < 0 {
                // colliding with left-most wall
                paddle.min.x = wall.max.x
                paddle.max.x = paddle.min.x + PADDLE_WIDTH                
            } else if paddle.velocity.x > 0 {
                // colliding with right-most wall
                paddle.min.x = wall.min.x - PADDLE_WIDTH
                paddle.max.x = wall.min.x 
            } 

            paddle.acceleration = {0,0}
            paddle.velocity = {0, 0}

        }
    }

    // 2. Check to see if ball has collided with paddle 
    c, r = bounding_box_center(ball), bounding_box_radii(ball)
    min_x, max_x := paddle.min.x - r.x, paddle.max.x + r.x 
    min_y, max_y := paddle.min.y - r.y, paddle.max.y + r.y 
    if min_x <= c.x && c.x <= max_x && min_y <= c.y && c.y <= max_y {
        
        d : [4]f32

        // Determine how far the center of the ball is from each of the enlarged edges
        // 1. top edge ...
        d[0] = c.y - min_y 
        
        // 2. bottom edge ...
        d[1] = max_y - c.y 

        // 4. right edge ...
        d[2] = max_x - c.x 

        // 3. left edge ...
        d[3] = c.x - min_x 

        // Find the closest edge
        edge: int = 0 
        best: = d[0]
        for di, i in d {
            if di < best {
                best = di 
                edge = i
            }
        }

        // Determine intersection point along the closest enlarges edge
        intersection_point: [2] f32
        switch edge {
        case 0: intersection_point = {(max_x - c.x) / (max_x - min_x), 0}
        case 1: intersection_point = {(max_x - c.x) / (max_x - min_x), 1}
        case 2: intersection_point = {1, (max_y - c.y) / (max_y - min_y)}
        case 3: intersection_point = {0, (max_y - c.y) / (max_y - min_y)}
        }

        fmt.println(intersection_point)

        // physics update
        switch edge {
        case 0, 1: ball.velocity.y = -ball.velocity.y
        case 2, 3: ball.velocity.x = -ball.velocity.x
        }
    }
    // 3. Check to see if ball has collided with any targets 
    for i in 0..<GRID_NUM_ROWS {
        for j in 0..<GRID_NUM_COLS {

            brick := bricks[i][j]

            if brick.visible {
                min_x, max_x := brick.min.x - r.x, brick.max.x + r.x 
                min_y, max_y := brick.min.y - r.y, brick.max.y + r.y 
                if min_x <= c.x && c.x <= max_x && min_y <= c.y && c.y <= max_y {
                    d : [4]f32

                    // Determine where the ball hits the brick
                    // 1. top edge ...
                    d[0] = c.y - min_y 
        
                    // 2. bottom edge ...
                    d[1] = max_y - c.y 

                    // 4. right edge ...
                    d[2] = max_x - c.x 

                    // 3. left edge ...
                    d[3] = c.x - min_x 


                    index: int = 0 
                    smallest:= d[0]
                    for di, i in d {
                        if di < smallest {
                            smallest = di 
                            index    = i
                        }
                    }

                    // TODO: what about corner collision?
                    switch index {
                    case 0, 1: ball.velocity.y = -ball.velocity.y
                    case 2, 3: ball.velocity.x = -ball.velocity.x
                    }

                    bricks[i][j].visible = false
                }
            }
        }
    }

    // 4. Check to see if ball has collided with wall
    c, r = bounding_box_center(ball), bounding_box_radii(ball)
    for wall, i in walls {
        min_x, max_x := wall.min.x - r.x, wall.max.x + r.x 
        min_y, max_y := wall.min.y - r.y, wall.max.y + r.y 
        if min_x <= c.x && c.x <= max_x && min_y <= c.y && c.y <= max_y {

            // TODO(jrr): should there be some variable indicating that a collision has occured
            switch i {
            case 0, 1:    
                ball.velocity.y = -ball.velocity.y 
            case 2, 3: 
                ball.velocity.x = -ball.velocity.x 
            }

        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // update
}


setup_game :: proc() {
    ball = {
        box        = {min={BALL_MIN_X, BALL_MIN_Y}, max={BALL_MAX_X, BALL_MAX_Y}},
        shape_type = .Circle,
        color      = BALL_COLOR,
        velocity   = {0, 500.0}
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
    
    walls = {

        {   // TOP / NORTH
            box        = {min={-10, -10}, max={SCREEN_WIDTH+10, +10}},
            shape_type = .Rectangle, 
            color      = rl.YELLOW,
            visible    = true
        },
        {   // BOTTOM / SOUTH
            box        = {min={0, SCREEN_HEIGHT}, max={SCREEN_WIDTH, SCREEN_HEIGHT+10}},
            shape_type = .Rectangle,
            color      = rl.YELLOW,
            visible    = true
        },
        {   // RIGHT / EAST
            box        = {min={SCREEN_WIDTH-10, -10}, max={SCREEN_WIDTH+10, SCREEN_HEIGHT+10}},
            shape_type = .Rectangle, 
            color      = rl.YELLOW,
            visible    = true
        },
        {   // LEFT / WEST
            box        = {min={-10, -10}, max={+10, SCREEN_HEIGHT+10}},
            shape_type = .Rectangle, 
            color      = rl.YELLOW,
            visible    = true
        },

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

    for wall in walls {
        rl.DrawRectangle(
            i32(wall.min.x), 
            i32(wall.min.y),
            i32(wall.max.x-wall.min.x),
            i32(wall.max.y-wall.min.y),
            wall.color
        )     
    }
}

main :: proc() {
    stopwatch : time.Stopwatch

    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "BreakOut")
    defer rl.CloseWindow() 

    setup_game()
 
    for !rl.WindowShouldClose() {
    
        time.stopwatch_start(&stopwatch)
        update_game()
        time.stopwatch_stop(&stopwatch)
        time.sleep(REFRESH_TIME - stopwatch._accumulation)
        draw_game()
        time.stopwatch_reset(&stopwatch)
    }

    fmt.println(rl.GetFrameTime())

}
