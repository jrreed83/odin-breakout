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


EntityType :: enum u8 {
    Ball,
    Paddle,
    Brick,
    Wall
}



bounding_box :: proc (e: Entity) -> (min: [2] f32, max: [2] f32) {
    half :[2]f32 = 0.5*{e.width, e.height}

    min = e.pos - half 
    max = e.pos + half

    return min, max
}

paused := false 

Entity :: struct {
    id: int,

    type: EntityType,
    
    mass:    f32,
    visible: bool,   
    health:  u8,
    moving:  bool,
    drag:    f32,

    acc: [2] f32,
    vel: [2] f32,
    pos: [2] f32, // center mass 

    color:  rl.Color,

    height: f32,
    width:  f32, 

}


// @TODO: want a single array of entities, indices to separate types of entities into groups
BALL_IDX     :: 0 
PADDLE_IDX   :: 1 
WALL_IDX     :: 2 
BRICK_IDX    :: WALL_IDX + 4
NUM_ENTITIES :: 1 // BRICK_IDX + 60


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
            entity.vel +=  entity.acc*dt
            entity.pos +=  entity.vel*dt + 0.5*entity.acc * square(dt)     
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // b
//    for i in 0..<NUM_ENTITIES {
//        hash_entity(&spatial_hash_tbl, entities[i])
//    }
//
//    for i in 0..<NUM_ENTITIES {
//        entity := &entities[i]
//         
//        close_entity_ids := get_close_entities(&spatial_hash_tbl, id=i, distance=1)
//         
//        for j in close_entity_ids {
//            handle_collision(entity, &entities[j]) //            
//        }
//    }
    
    // Wall collision 
    for i in 0..<NUM_ENTITIES {
        entity := &entities[i]

        min, max := bounding_box(entity^)
        if min.x <= 0 {
            entity.vel.x = -entity.vel.x
        } 

        if max.x >= SCREEN_WIDTH {
            entity.vel.x = -entity.vel.x
        } 

        if min.y <= 0 {
            entity.vel.y = -entity.vel.y
        }

        if max.y >= SCREEN_HEIGHT {
            entity.vel.y = -entity.vel.y
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
        vel      = {34.0,100.0},
        height   = 10.0,
        width    = 10.0,
        color    = BALL_COLOR,
        pos      = {100, 100}
    }

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
    cx, cy := i32(entity.pos.x), i32(entity.pos.y)
    radius := 0.5*entity.height 
    rl.DrawCircle(cx, cy, radius, entity.color)
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

draw_game :: proc() {
    
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    //rl.DrawText(rl.TextFormat("Score: %d", score), 40, 40, 20, rl.WHITE)

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
    
        //time.stopwatch_start(&stopwatch)
        update_game()
        //time.stopwatch_stop(&stopwatch)
        time.sleep(REFRESH_TIME - stopwatch._accumulation)

        draw_game()
        
        //time.stopwatch_reset(&stopwatch)
    }
}

