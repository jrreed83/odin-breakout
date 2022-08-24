package main

import       "core:fmt"
import       "core:os"
import       "core:math"
import       "core:math/linalg"
import       "core:time"
import rl    "vendor:raylib"
import libc  "core:c/libc"


SCREEN_WIDTH     :: 850
SCREEN_HEIGHT    :: 650
FRAME_RATE       :: 60
UPDATE_RATE      :: FRAME_RATE / 2
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

BONUS_HEIGHT   :: 15
BONUS_WIDTH    :: BRICK_WIDTH

GRID_NUM_ROWS  :: 6 
GRID_NUM_COLS  :: 10 
NUM_BRICKS     :: GRID_NUM_COLS * GRID_NUM_ROWS
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

EntityType :: enum u8 {
    Ball,
    Paddle,
    Brick,
    Wall
}

BoundingBox :: struct {
    min: [2] f32,  // upper left visually
    max: [2] f32   // lower right visually
}

Edge :: enum int {
    North, South, East, West
}

bounding_box_center :: proc (e: ^Entity) -> [2] f32 {

    x := 0.5*(e.min.x + e.max.x)
    y := 0.5*(e.min.y + e.max.y)
    return {x, y}
}

bounding_box_radii :: proc (e: ^Entity) -> [2] f32 {

    x := 0.5*(e.max.x - e.min.x)
    y := 0.5*(e.max.y - e.min.y)

    return {x, y}
}

paused := false 

Entity :: struct {
    entity_type: EntityType,
    using box:   BoundingBox,
    shape_type:  ShapeType,
    
    acceleration: [2] f32,
    velocity:     [2] f32,
    mass:             f32,
    color:            rl.Color,
    visible:          bool,   
    health:           u8,
    moving:           bool
}


// TODO: want a single array of entities, indices to separate types of entities into groups
BALL_IDX     :: 0 
PADDLE_IDX   :: 1 
WALL_IDX     :: 2 
BRICK_IDX    :: WALL_IDX + 4
NUM_ENTITIES :: BRICK_IDX + 60

entities : [NUM_ENTITIES] Entity
collisions : [NUM_ENTITIES][NUM_ENTITIES] bool 

update_game :: proc () {

    // initialize for frame 
    paddle := &entities[PADDLE_IDX]
    ball   := &entities[BALL_IDX]
    ////////////////////////////////////////////////////////////////////////////
    // User input 
    if rl.IsKeyPressed(.SPACE) {
        paused = !paused
    }

    if paused { return }

    // TODO: change to force and derive acceleration
    if rl.IsKeyDown(.LEFT) {
        entities[PADDLE_IDX].acceleration.x = -1000
    } else if rl.IsKeyDown(.RIGHT) {
        entities[PADDLE_IDX].acceleration.x = +1000
    } else {
        entities[PADDLE_IDX].acceleration.x = 0
    }

    
    ////////////////////////////////////////////////////////////////////////////
    // physics

    for i in 0..<NUM_ENTITIES {
        entity := &entities[i]

        if entity.entity_type == .Paddle {
            entity.acceleration += -5*entity.velocity 
            entity.velocity     += entity.acceleration*dt
            //entity.position     += entity.velocity*dt + 0.5*entity.acceleration * (dt*dt)
            entity.min          += entity.velocity*dt + 0.5*entity.acceleration * (dt*dt) 
            entity.max          += entity.velocity*dt + 0.5*entity.acceleration * (dt*dt)             
        }

        if entity.entity_type == .Ball {
            //entity.position += entity.velocity*dt
            entity.min += entity.velocity*dt 
            entity.max += entity.velocity*dt     
        }

        if entity.entity_type == .Brick {
            //entity.position += entity.velocity*dt
            entity.min += entity.velocity*dt 
            entity.max += entity.velocity*dt        
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // collision detection in two phases
    // 1. broad phase where we determine if two entities are close enough to collide
    //    do we need some sort of hashing? or tile map?  Maybe use an array of index tuples?
    // 2. narrow phase where we actually determine if a collision occurs
    // 3. Update the physics in response to a collision 

    //for i in 0..<NUM_ENTITIES {
    //    entity := &entities[i]
    //    
    //    if entity.entity_type == .Paddle {
    //    
    //    }    
    //}
    // want a visited array so we don't duplicate work?
    // Collision detection using Minkowski sum/difference
    for i in 0..<NUM_ENTITIES {
        e0 := &entities[i]
        c0 := bounding_box_center(e0)
        r0 := bounding_box_radii(e0)

        for j in 0..<NUM_ENTITIES {
            if j != i {
                e1 := &entities[j]
                min_x, max_x := e1.min.x - r0.x, e1.max.x + r0.x 
                min_y, max_y := e1.min.y - r0.y, e1.max.y + r0.y 
                collisions[i][j] = min_x <= c0.x && c0.x <= max_x && min_y <= c0.y && c0.y <= max_y
            }
        }
    }



    /////////////////////////////////////////////////////////////////////////////
    c: [2]f32
    r: [2]f32
    // 1. Check to see if the paddle has collided with the wall.
    c, r = bounding_box_center(paddle), bounding_box_radii(paddle)
    for i in WALL_IDX..<WALL_IDX+4 {
        wall := entities[i]

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

        // physics update
        switch edge {
        case 0, 1: ball.velocity.y = -ball.velocity.y
        case 2, 3: ball.velocity.x = -ball.velocity.x
        }
    }
    // 3. Check to see if ball has collided with any targets 
    for i in BRICK_IDX..<BRICK_IDX+60 {
        brick := &entities[i]
        if brick.visible && !brick.moving {
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

                brick.velocity.y = +50
                brick.color      = rl.LIGHTGRAY  
                brick.min        = brick.min + 5
                brick.max        = brick.max - 5 
                brick.moving     = true

            }
        }
    }

    // 4. Check to see if ball has collided with wall
    c, r = bounding_box_center(ball), bounding_box_radii(ball)
    for i in WALL_IDX..<WALL_IDX+4 {
        wall := entities[i]
        min_x, max_x := wall.min.x - r.x, wall.max.x + r.x 
        min_y, max_y := wall.min.y - r.y, wall.max.y + r.y 
        if min_x <= c.x && c.x <= max_x && min_y <= c.y && c.y <= max_y {

            // TODO(jrr): should there be some variable indicating that a collision has occured
            offset := i-WALL_IDX
            switch offset {
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
    // ball ...
    entities[BALL_IDX] = {
        box         = {min={BALL_MIN_X, BALL_MIN_Y}, max={BALL_MAX_X, BALL_MAX_Y}},
        shape_type  = .Circle,
        entity_type = .Ball,
        color       = BALL_COLOR,
        velocity    = {0, 250.0},
        visible     = true
    }

    // paddle ...
    entities[PADDLE_IDX] = {
        box         = {min={PADDLE_MIN_X, PADDLE_MIN_Y}, max={PADDLE_MAX_X, PADDLE_MAX_Y}},
        shape_type  = .Rectangle,
        color       = BALL_COLOR,   
        entity_type = .Paddle,        
        visible     = true,
    }


    // bricks ...
    brick_min: [2] f32 = {GRID_PADDING_X, GRID_PADDING_Y}
    row, col := 0, 0
    
    for i in BRICK_IDX..<BRICK_IDX+60 {
        entities[i] = {
            box        = {min = brick_min, max = brick_min + {BRICK_WIDTH, BRICK_HEIGHT}},
            shape_type = .Rectangle,
            color      = ROW_COLORS[row],
            visible    = true,
            moving     = false,    
        }

        // wrap around...
        if col == 9 {
            brick_min.x = GRID_PADDING_X
            brick_min.y = brick_min.y + BRICK_SPACING + BRICK_HEIGHT 
            col = 0
            row = row+1
        } else {
            brick_min.x   = brick_min.x + BRICK_SPACING + BRICK_WIDTH
            col += 1
        }
    }

    // walls ...
    entities[WALL_IDX + 0] = {   
        // TOP / NORTH
        box        = {min={-10, -10}, max={SCREEN_WIDTH+10, +10}},
        shape_type = .Rectangle, 
        color      = rl.YELLOW,
        visible    = true
    }

    entities[WALL_IDX + 1] = {
        // BOTTOM / SOUTH
        box        = {min={0, SCREEN_HEIGHT}, max={SCREEN_WIDTH, SCREEN_HEIGHT+10}},
        shape_type = .Rectangle,
        color      = rl.YELLOW,
        visible    = true
    }

    entities[WALL_IDX + 2] = {
        // RIGHT / EAST
        box        = {min={SCREEN_WIDTH-10, -10}, max={SCREEN_WIDTH+10, SCREEN_HEIGHT+10}},
        shape_type = .Rectangle, 
        color      = rl.YELLOW,
        visible    = true
    }

    entities[WALL_IDX + 3] = {
        // LEFT / WEST
        box        = {min={-10, -10}, max={+10, SCREEN_HEIGHT+10}},
        shape_type = .Rectangle, 
        color      = rl.YELLOW,
        visible    = true
    }
}

draw_entity :: proc(entity: ^Entity) {
    if entity.shape_type == .Circle {
        c := bounding_box_center(entity)
        r := bounding_box_radii(entity)
        rl.DrawCircle(i32(c.x), i32(c.y), r.x, entity.color)
    } else {
        rl.DrawRectangle(
            i32(entity.min.x), 
            i32(entity.min.y),
            i32(entity.max.x-entity.min.x),
            i32(entity.max.y-entity.min.y),
            entity.color
        )
    }         
}

ROW_COLORS : [6] rl.Color = {rl.PINK, rl.RED, rl.ORANGE, rl.YELLOW, rl.GREEN, rl.BLUE}

draw_game :: proc() {
    
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    rl.DrawText(rl.TextFormat("Score: %d", score), 40, 40, 20, rl.WHITE)

    for i in 0..<NUM_ENTITIES {
        entity := &entities[i]
        if entity.visible {
            draw_entity(entity)
        }
    }
}

hash := SpatialHash{}

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

    test_read()
}

