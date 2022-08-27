package main

import       "core:fmt"
import       "core:os"
import       "core:math"
import       "core:math/linalg"
import       "core:time"
import rl    "vendor:raylib"
import libc  "core:c/libc"


// @TODO: Determine the processor speed programatically
PROCESSOR_HZ     :: 2_420_000_000
SCREEN_WIDTH     :: 850
SCREEN_HEIGHT    :: 650
//FRAME_RATE       :: 60
//UPDATE_RATE      :: FRAME_RATE / 2
//REFRESH_TIME     :  time.Duration : time.Duration(16*time.Millisecond)

BACKGROUND_COLOR :: rl.BLACK 

//PADDLE_COLOR     :: rl.RED
//PADDLE_WIDTH     :: 60  
//PADDLE_HEIGHT    :: 60
//PADDLE_MIN_X     :: 0.5*(SCREEN_WIDTH - PADDLE_WIDTH)    
//PADDLE_MIN_Y     :: 500 //600
//PADDLE_MAX_X     :: PADDLE_MIN_X + PADDLE_WIDTH 
//PADDLE_MAX_Y     :: PADDLE_MIN_Y + PADDLE_HEIGHT
//PADDLE_CENTER_X  :: 0.5*(PADDLE_MIN_X + PADDLE_MAX_X)

//PADDLE_SPEED     :: 100

//BALL_COLOR       :: rl.WHITE
//BALL_RADIUS      :: 5
//BALL_MIN_X       :: PADDLE_CENTER_X - BALL_RADIUS -5 - PADDLE_MIN_X
//BALL_MAX_X       :: BALL_MIN_X + 2*BALL_RADIUS 
//BALL_MIN_Y       :: PADDLE_MIN_Y - 10*BALL_RADIUS +50
//BALL_MAX_Y       :: BALL_MIN_Y + 2*BALL_RADIUS

//BALL_SPEED       :: 300

//BRICK_HEIGHT   :: 25
//BRICK_WIDTH    :: 45 

//BONUS_HEIGHT   :: 15
//BONUS_WIDTH    :: BRICK_WIDTH

//GRID_NUM_ROWS  :: 6 
//GRID_NUM_COLS  :: 10 
//NUM_BRICKS     :: GRID_NUM_COLS * GRID_NUM_ROWS
//BRICK_SPACING  :: 10
//GRID_PADDING_Y :: 50
//GRID_PADDING_X :: 0.5*(SCREEN_WIDTH - BRICK_WIDTH * GRID_NUM_COLS - BRICK_SPACING * (GRID_NUM_COLS-1))

FRAMES_PER_SECOND  :: 60
UPDATES_PER_SECOND :: 30

//UPDATES_PER_SECOND :: 4 * FRAMES_PER_SECOND

DT: f32 : 1.0 / f32(UPDATES_PER_SECOND)

DT_SQUARED :: DT * DT

//friction :f32 = 1.0 

//score:= 0


EntityType :: enum u8 {
    Ball,
    Paddle,
    Brick,
    Wall
}



bounding_box :: proc (e: Entity) -> (min: [2] f32, max: [2] f32) {

    min = e.pos
    max = e.pos + {f32(e.width), f32(e.height)}

    return min, max
}

centroid :: proc(e: Entity) -> [2] f32 {
    cx := e.pos.x + 0.5*e.width 
    cy := e.pos.y + 0.5*e.height

    return {cx, cy}
}

paused := false 

Entity :: struct {
    id: int,

    type: EntityType,
    
    mass:    f32,
    visible: bool,   
    health:  u8,
    moving:  bool,
    bouncy:  bool,
    drag:    f32,

    acc: [2] f32,
    vel: [2] f32,
    pos: [2] f32, // center mass 

    color:  rl.Color,

    height: f32,
    width:  f32, 

    path: cstring,

    texture: rl.Texture 
}


// @TODO: want a single array of entities, indices to separate types of entities into groups
BALL_IDX     :: 0 
PADDLE_IDX   :: 1 
WALL_IDX     :: 2 
BRICK_IDX    :: WALL_IDX + 4
NUM_ENTITIES :: 56 // BRICK_IDX + 60


entities : [NUM_ENTITIES] Entity


square :: proc(x: f32) -> f32 {
    return x * x 
}

update_game :: proc () {

    // initialize for frame 
    ////////////////////////////////////////////////////////////////////////////
    // User input 
    if rl.IsKeyPressed(.SPACE) {
        paused = !paused
    }

    if paused { return }

    // @TODO: add a start button 

    // @TODO: change to force and derive acceleration
    //if rl.IsKeyDown(.LEFT) {
    //    entities[PADDLE_IDX].acc.x = -1000
    //} else if rl.IsKeyDown(.RIGHT) {
    //    entities[PADDLE_IDX].acc.x = +1000
    //} else {
    //    entities[PADDLE_IDX].acc.x = 0
    //}

    
    ////////////////////////////////////////////////////////////////////////////
    // physics

    for i in 0..<NUM_ENTITIES {
        entity := &entities[i]

        if entity.moving {
            entity.acc += -entity.drag*entity.vel 
            entity.vel +=  entity.acc*DT
            entity.pos +=  entity.vel*DT + 0.5*entity.acc * DT_SQUARED     
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // collisions

    // @TODO: Add spatial hash for more efficient collision detection
    // @TODO: Check location of collision to determine deflection
    // @TODO: Integrate life time?
    for i in 0..<NUM_ENTITIES {
        ei := &entities[i]
        for j in 0..<NUM_ENTITIES {
            ej := &entities[j]

            if i != j && ei.moving && ej.visible {
                mini, maxi := bounding_box(ei^)
                c := centroid(ei^)
        
                minj, maxj := bounding_box(ej^)

                dx := 0.5*ei.width
                dy := 0.5*ei.height 
                if minj.x-dx <= c.x && c.x <= maxj.x+dx && minj.y-dy <= c.y && c.y <= maxj.y+dy {
                    if ei.type == .Ball && ej.type == .Brick {
                        ej.visible = false 

                        ei.vel.y = -ei.vel.y
                    }
                }
            }

        }
    }
    
    // Wall collision 
    for i in 0..<NUM_ENTITIES {
        // @TODO: Minkowski sum collision?
        entity := &entities[i]

        min, max := bounding_box(entity^)

        if entity.bouncy {
            if min.x <= 0 || max.x >= SCREEN_WIDTH {
                entity.vel.x = -entity.vel.x
            } 

            if min.y <= 0 || max.y >= SCREEN_HEIGHT{
                entity.vel.y = -entity.vel.y
            }

        }
    }




}


setup_game :: proc() {
    // ball ...
    entities[0] = {
        id       = 0,
        type     = .Ball,
        visible  = true,
        moving   = true,
        drag     = 0.0,
        acc      = {0.0,0.0},
        vel      = {0.0,40.0},
        pos      = {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2},
        bouncy   = true,
        path     = "ball.png",
        height   = 10,
        width    = 10,
        color    = rl.GREEN
    }


    xpos: f32 = 10
    ypos: f32 = 50
    row := 0
    col := 0
    for i in 1..<NUM_ENTITIES {

        entities[i] = {
            id       = i,
            type     = .Brick,
            visible  = true,
            moving   = false,
            drag     = 0.0,
            pos      = {xpos, ypos},
            bouncy   = false,
            height   = 30,
            width    = 60,
            color    = rl.PINK
        }

        xpos += 65
        col  += 1
        if xpos > SCREEN_WIDTH {
            xpos  = 10
            ypos += 35
            row  += 1 
            col   = 0
        }
    }

    //for i in 0..<NUM_ENTITIES {
    //    entity := &entities[i]
    //
    //    entity.texture = rl.LoadTexture(entity.path)
    //}
    // paddle ...
    //entities[PADDLE_IDX] = {
    //    box     = {min={PADDLE_MIN_X, PADDLE_MIN_Y}, max={PADDLE_MAX_X, PADDLE_MAX_Y}},
    //    shape   = .Rectangle,
    //    color   = BALL_COLOR,   
    //    type    = .Paddle,        
    //    visible = true,
    //    id      = PADDLE_IDX
    //}


    // bricks ...
    //brick_min: [2] f32 = {GRID_PADDING_X, GRID_PADDING_Y}
    //row, col := 0, 0
    //
    //for i in BRICK_IDX..<BRICK_IDX+60 {
    //    entities[i] = {
    //        box        = {min = brick_min, max = brick_min + {BRICK_WIDTH, BRICK_HEIGHT}},
    //        shape = .Rectangle,
    //        color      = ROW_COLORS[row],
    //        visible    = true,
    //        moving     = false, 
    //        id         = i   
    //    }

        // wrap around...
    //    if col == 9 {
    //        brick_min.x = GRID_PADDING_X
    //        brick_min.y = brick_min.y + BRICK_SPACING + BRICK_HEIGHT 
    //        col = 0
    //        row = row+1
    //    } else {
    //       brick_min.x   = brick_min.x + BRICK_SPACING + BRICK_WIDTH
    //        col += 1
    //    }
    //}

    // walls ...
    //entities[WALL_IDX + 0] = {   
        // TOP / NORTH
    //    box     = {min={-10, -10}, max={SCREEN_WIDTH+10, +10}},
    //    shape   = .Rectangle, 
    //    color   = rl.YELLOW,
    //    visible = true,
    //    id      = WALL_IDX
    //}

    //entities[WALL_IDX + 1] = {
        // BOTTOM / SOUTH
    //    box      = {min={0, SCREEN_HEIGHT}, max={SCREEN_WIDTH, SCREEN_HEIGHT+10}},
    //    shape    = .Rectangle,
    //    color    = rl.YELLOW,
    //    visible  = true,
    //    id       = WALL_IDX+1   
    //}

    //entities[WALL_IDX + 2] = {
        // RIGHT / EAST
    //    box        = {min={SCREEN_WIDTH-10, -10}, max={SCREEN_WIDTH+10, SCREEN_HEIGHT+10}},
    //    shape = .Rectangle, 
    //    color      = rl.YELLOW,
    //    visible    = true,
    //    id         = WALL_IDX+2
    //}

//    entities[WALL_IDX + 3] = {
//        // LEFT / WEST
//        box        = {min={-10, -10}, max={+10, SCREEN_HEIGHT+10}},
//        shape = .Rectangle, 
//        color      = rl.YELLOW,
//        visible    = true,
//        id         = WALL_IDX+3
//    }
}

draw_entity :: proc(entity: ^Entity) {
    x, y := entity.pos.x, entity.pos.y

    rl.DrawRectangle(
        i32(entity.pos.x), 
        i32(entity.pos.y),
        i32(entity.width),
        i32(entity.height),
        entity.color
    )
    //rl.DrawTexture(entity.texture, i32(x), i32(y), rl.WHITE)
    

//    if entity.shape == .Circle {
//        c := bounding_box_center(entity)
//        r := bounding_box_radii(entity)
//        rl.DrawCircle(i32(c.x), i32(c.y), r.x, entity.color)
//    } else {
//        rl.DrawRectangle(
//            i32(entity.min.x), 
//            i32(entity.min.y),
//            i32(entity.max.x-entity.min.x),
//            i32(entity.max.y-entity.min.y),
//            entity.color
 //       )
//    }         
}

//ROW_COLORS : [6] rl.Color = {rl.PINK, rl.RED, rl.ORANGE, rl.YELLOW, rl.GREEN, rl.BLUE}


//hash := SpatialHash{}

main :: proc() {

    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "BreakOut")
    defer rl.CloseWindow() 

    setup_game()
 
    // @TODO: eliminate this
    // Running way faster so that we can test my timing routine
    rl.SetTargetFPS(120)

    N := 0

    cnt : u64 

    prev_tick := time.read_cycle_counter() 
    curr_tick := prev_tick
    
    // @TODO: Make this a compile time constant?
    counts_per_frame := u64(PROCESSOR_HZ * 15e-3)

    for !rl.WindowShouldClose() {
        
        ///////////////////////////////////////////////////////////////////////
        // Update the physics
        //
        update_game() 

        ///////////////////////////////////////////////////////////////////////
        // Rendering: 
        //   

        // Wait until it's time to paint the frame.  This makes sure that
        // there's a fairly precise amount of time between refresh times
        // @TODO: is 10 microseconds of sleeping sufficient.  
        // Definitely need some
        // sleeping, otherwise the computer fans are put to work
        for time.read_cycle_counter() - prev_tick < counts_per_frame {  
            time.sleep(10*time.Microsecond)
        }
    
        // @TODO: Investigate BeginDrawing, ClearBackground, and EndDrawing
        rl.BeginDrawing() 
        rl.ClearBackground(BACKGROUND_COLOR)

        for i in 0..<NUM_ENTITIES {
            entity := &entities[i]
            if entity.visible {
                draw_entity(entity)
            }
        }
        rl.EndDrawing()

        //////////////////////////////////////////////////////////////////////
        // Check that we're hitting the frame rate
        // @TODO: add a compile time flag to enablee/disable framerate timing
        curr_tick = time.read_cycle_counter() 
        fmt.printf("%.6f\n", f32(curr_tick - prev_tick) / f32(PROCESSOR_HZ))
        prev_tick = curr_tick
        //////////////////////////////////////////////////////////
        
    }

    
}

