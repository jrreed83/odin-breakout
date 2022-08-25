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
PADDLE_HEIGHT    :: 60
PADDLE_MIN_X     :: 0.5*(SCREEN_WIDTH - PADDLE_WIDTH)    
PADDLE_MIN_Y     :: 500 //600
PADDLE_MAX_X     :: PADDLE_MIN_X + PADDLE_WIDTH 
PADDLE_MAX_Y     :: PADDLE_MIN_Y + PADDLE_HEIGHT
PADDLE_CENTER_X  :: 0.5*(PADDLE_MIN_X + PADDLE_MAX_X)

PADDLE_SPEED     :: 100

BALL_COLOR       :: rl.WHITE
BALL_RADIUS      :: 5
BALL_MIN_X       :: PADDLE_CENTER_X - BALL_RADIUS -5 - PADDLE_MIN_X
BALL_MAX_X       :: BALL_MIN_X + 2*BALL_RADIUS 
BALL_MIN_Y       :: PADDLE_MIN_Y - 10*BALL_RADIUS +50
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
    id: int,

    type: EntityType,
    
    mass:    f32,
    visible: bool,   
    health:  u8,
    moving:  bool,
    
    acceleration: [2] f32,
    velocity:     [2] f32,
    position:     [2] f32,

    shape:  ShapeType,
    color:  rl.Color,

    using box:   BoundingBox,
}


// @TODO: want a single array of entities, indices to separate types of entities into groups
BALL_IDX     :: 0 
PADDLE_IDX   :: 1 
WALL_IDX     :: 2 
BRICK_IDX    :: WALL_IDX + 4
NUM_ENTITIES :: BRICK_IDX + 60

entities : [NUM_ENTITIES] Entity

collision_handler :: proc(e0: ^Entity, e1: ^Entity) {
    
    c, r: = bounding_box_center(e0), bounding_box_radii(e0)

    min_x, max_x := e1.min.x - r.x, e1.max.x + r.x 
    min_y, max_y := e1.min.y - r.y, e1.max.y + r.y 
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
//        switch edge {
//        case 0, 1: ball.velocity.y = -ball.velocity.y
//        case 2, 3: ball.velocity.x = -ball.velocity.x
//        }
    }
}

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

    // @TODO: change to force and derive acceleration
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

        if entity.type == .Paddle {
            entity.acceleration += -5*entity.velocity 
            entity.velocity     += entity.acceleration*dt
            //entity.position     += entity.velocity*dt + 0.5*entity.acceleration * (dt*dt)
            entity.min          += entity.velocity*dt + 0.5*entity.acceleration * (dt*dt) 
            entity.max          += entity.velocity*dt + 0.5*entity.acceleration * (dt*dt)             
        } 

        if entity.type == .Ball {
            //entity.position += entity.velocity*dt
            entity.min += entity.velocity*dt 
            entity.max += entity.velocity*dt     
        }

        if entity.type == .Brick {
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
    //
    // for i in 0..<NUM_ENTITIES {
    //    entity := entities[i]
    //    hash_entity(&spatial_hash_tbl, entity)
    // }
    //
    // for i in 0..<NUM_ENTITIES {
    //     entity := &entities[i]
    //     
    //     close_entity_ids := get_close_entities(&spatial_hash_tbl, id=i, distance=1)
    //     
    //     for j in close_entity_ids {
    //        handle_collision(entity, &entities[j]) //            
    //     }
    //}
    //}
    // want a visited array so we don't duplicate work?
    // Collision detection using Minkowski sum/difference

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

            // @TODO: should there be some variable indicating that a collision has occured
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

        d0 := abs(ball.max.y-paddle.min.y)
        d1 := abs(ball.min.y-paddle.max.y)
        d2 := abs(ball.min.x-paddle.max.x)
        d3 := abs(ball.max.x-paddle.min.x)


        if d0 <= d1 && d0 <= d2 && d0 <= d3 {
            fmt.println("N")
            ball.velocity.y = -ball.velocity.y
        } else if d1 <= d0 && d1 <= d2 && d1 <= d3 {
            fmt.println("S")
            ball.velocity.y = -ball.velocity.y
        } else if d2 <= d0 && d2 <= d1 && d2 <= d3 {
            fmt.println("E")
            ball.velocity.x = +ball.velocity.x  
        } else if d3 <= d0 && d3 <= d1 && d3 <= d2 {
            fmt.println("W")
            ball.velocity.x = -ball.velocity.x    
        }

        //if ball.velocity.y > 0 && ball.max.x >= paddle.min.x && ball.min.x <= paddle.max.x {
        //    fmt.println("top")
        //    ball.velocity.y = -ball.velocity.y
        //} else if ball.velocity.y < 0 && ball.max.x >= paddle.min.x && ball.min.x <= paddle.max.x {
        //    fmt.println("bottom")
        //    ball.velocity.y = -ball.velocity.y
        //} else if paddle.velocity.x < 0 && ball.max.x >= paddle.min.y && ball.max.y >= paddle.min.y && ball.min.y <= paddle.max.y {
        //} else if paddle.max.x >= ball.min.x {
        //}
        //    fmt.println("right")
        //    ball.velocity.x = +paddle.velocity.x
        //} else if ball.max.y >= paddle.min.y {
        //    fmt.println("top")
        //    ball.velocity.y = -ball.velocity.y
        //} else if ball.min.y <= paddle.max.y {
        //    fmt.println("bottom")
        //    ball.velocity.y = -ball.velocity.y
        //} 

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

                // @TODO: what about corner collision?
                switch index {
                case 0, 1: ball.velocity.y = -ball.velocity.y
                case 2, 3: ball.velocity.x = -ball.velocity.x
                }

                brick.velocity.y = +10
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

            // @TODO: should there be some variable indicating that a collision has occured
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
        box      = {min={BALL_MIN_X, BALL_MIN_Y}, max={BALL_MAX_X, BALL_MAX_Y}},
        shape    = .Circle,
        type     = .Ball,
        color    = BALL_COLOR,
        velocity = {20, 0.0},
        visible  = true,
        id       = BALL_IDX
    }

    // paddle ...
    entities[PADDLE_IDX] = {
        box     = {min={PADDLE_MIN_X, PADDLE_MIN_Y}, max={PADDLE_MAX_X, PADDLE_MAX_Y}},
        shape   = .Rectangle,
        color   = BALL_COLOR,   
        type    = .Paddle,        
        visible = true,
        id      = PADDLE_IDX
    }


    // bricks ...
    brick_min: [2] f32 = {GRID_PADDING_X, GRID_PADDING_Y}
    row, col := 0, 0
    
    for i in BRICK_IDX..<BRICK_IDX+60 {
        entities[i] = {
            box        = {min = brick_min, max = brick_min + {BRICK_WIDTH, BRICK_HEIGHT}},
            shape = .Rectangle,
            color      = ROW_COLORS[row],
            visible    = true,
            moving     = false, 
            id         = i   
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
        box     = {min={-10, -10}, max={SCREEN_WIDTH+10, +10}},
        shape   = .Rectangle, 
        color   = rl.YELLOW,
        visible = true,
        id      = WALL_IDX
    }

    entities[WALL_IDX + 1] = {
        // BOTTOM / SOUTH
        box      = {min={0, SCREEN_HEIGHT}, max={SCREEN_WIDTH, SCREEN_HEIGHT+10}},
        shape    = .Rectangle,
        color    = rl.YELLOW,
        visible  = true,
        id       = WALL_IDX+1   
    }

    entities[WALL_IDX + 2] = {
        // RIGHT / EAST
        box        = {min={SCREEN_WIDTH-10, -10}, max={SCREEN_WIDTH+10, SCREEN_HEIGHT+10}},
        shape = .Rectangle, 
        color      = rl.YELLOW,
        visible    = true,
        id         = WALL_IDX+2
    }

    entities[WALL_IDX + 3] = {
        // LEFT / WEST
        box        = {min={-10, -10}, max={+10, SCREEN_HEIGHT+10}},
        shape = .Rectangle, 
        color      = rl.YELLOW,
        visible    = true,
        id         = WALL_IDX+3
    }
}

draw_entity :: proc(entity: ^Entity) {
    if entity.shape == .Circle {
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

//hash := SpatialHash{}

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
}

