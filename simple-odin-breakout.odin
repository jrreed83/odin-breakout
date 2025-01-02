package breakout

import       "core:fmt"
import       "core:os"
import       "core:math"
import       "core:math/linalg"
import       "core:time"
import rl    "vendor:raylib"



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


score:= 0


EntityType :: enum u8 {
    Ball,
    Paddle,
    Brick,
    Bonus
}



bounding_box :: proc (e: ^Entity) -> (min: [2] f32, max: [2] f32) {

    min = e.pos
    max = e.pos + {f32(e.width), f32(e.height)}

    return min, max
}

centroid :: proc(e: ^Entity) -> [2] f32 {
    cx := e.pos.x + 0.5*e.width 
    cy := e.pos.y + 0.5*e.height

    return {cx, cy}
}

paused := true

// @TODO: What about gravitational force?
Entity :: struct {
    id: int,

    type: EntityType,
    
    mass:     f32,
    visible:  bool,   
    health:   u8,
    mobile:   bool,
    bouncy:   bool,
    airdrag:  f32,

    acc: [2] f32,
    vel: [2] f32,
    pos: [2] f32, // center mass 

    color:  rl.Color,

    height: f32,
    width:  f32, 

    path: cstring,

    texture: rl.Texture,

    // @TODO: too specific to bricks, 
    points: int
}


// @TODO: want a single array of entities, indices to separate types of entities into groups
NUM_ENTITIES :: 57 // BRICK_IDX + 60


entities : [NUM_ENTITIES] Entity


square :: proc(x: f32) -> f32 {
    return x * x 
}

lost_game  := false
lost_turn  := false
turns_left := 3

colors : []rl.Color = {
    rl.BLUE, 
    rl.PURPLE, 
    rl.PINK, 
    rl.RED, 
    rl.ORANGE, 
    rl.YELLOW}

bonus_dropped_already := false

handle_collision :: proc ()
update_game :: proc () {

    ////////////////////////////////////////////////////////////////////////////
    // initialize for frame 
    //


    ////////////////////////////////////////////////////////////////////////////
    // User input
    // 

    if rl.IsKeyPressed(.SPACE) {
        paused = !paused
    }

    if paused { return }

    // @TODO: add a start button?
    

    // @TODO: change to force and derive acceleration
    if rl.IsKeyDown(.LEFT) {
        entities[1].acc.x = -1000
    } else if rl.IsKeyDown(.RIGHT) {
        entities[1].acc.x = +1000
    } else {
        entities[1].acc.x = 0
    }

    
    ////////////////////////////////////////////////////////////////////////////
    // physics

    for i in 0..<NUM_ENTITIES {
        entity := &entities[i]

        if entity.mobile {
            entity.acc += -entity.airdrag*entity.vel 
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
        trial_entity := &entities[i]

        for j in 0..<NUM_ENTITIES {
            test_entity := &entities[j]
            
            if i != j && trial_entity.mobile && test_entity.visible {
                
                trial_min, trial_max := bounding_box(trial_entity)
                trial_centroid := centroid(trial_entity)

                test_min, test_max := bounding_box(test_entity)


                dx := 0.5*trial_entity.width
                dy := 0.5*trial_entity.height

                min_x := test_min.x - dx 
                max_x := test_max.x + dx 

                min_y := test_min.y - dy 
                max_y := test_max.y + dy

                cx := trial_centroid.x 
                cy := trial_centroid.y 

                if min_x <= cx && cx <= max_x && min_y <= cy && cy <= max_y {
                    if trial_entity.type == .Ball && test_entity.type == .Brick {

                        // @TODO: Migrate from `visible` to something related to alive or lifetime
                        test_entity.visible = false

                        // @TODO: This is way too specific
                        score += test_entity.points
    
                        // @TODO: Revisit this edge detection scheme.  Want to use a predictive/continuous collision detection approach


                        // Determine which edge the ball most likely hit.  Based on distance
                        d0 := cx - min_x 
                        d1 := max_x - cx
                        d2 := cy - min_y 
                        d3 := max_y - cy

                        // @TODO: Apply force rather than velocity?
                        if d0 <= d1 && d0 <= d2 && d0 <= d3 {
                            // left edge 
                            trial_entity.vel.x = -trial_entity.vel.x 
                        } else if d1 <= d0 && d1 <= d2 && d1 <= d3 {
                            // right edge 
                            trial_entity.vel.x = -trial_entity.vel.x 
                        } else if d2 <= d0 && d2 <= d1 && d2 <= d3 {
                            // top edge 
                            trial_entity.vel.y = -trial_entity.vel.y

                        } else {
                            // bottom edge
                            trial_entity.vel.y = -trial_entity.vel.y
                        }

                        // @TODO: Need more systematic way to handle bonus dropping 
                        if !bonus_dropped_already {
                            entities[56].visible = true 
                            entities[56].vel.y   = +10
                        }    
                    }

                    if trial_entity.type == .Ball && test_entity.type == .Paddle {


                        // @TODO: Revisit this edge detection scheme.  Want to use a predictive/continuous collision detection approach


                        // Determine which edge the ball most likely hit.  Based on distance
                        d0 := cx - min_x 
                        d1 := max_x - cx
                        d2 := cy - min_y 
                        d3 := max_y - cy

                        // @TODO: Apply force rather than velocity?
                        if d0 <= d1 && d0 <= d2 && d0 <= d3 {
                            // left edge 
                            trial_entity.vel.x = -trial_entity.vel.x 
                        } else if d1 <= d0 && d1 <= d2 && d1 <= d3 {
                            // right edge 
                            trial_entity.vel.x = -trial_entity.vel.x 
                        } else if d2 <= d0 && d2 <= d1 && d2 <= d3 {
                            // top edge 
                            trial_entity.vel.y = -trial_entity.vel.y
                            trial_entity.vel.x += 0.5*test_entity.vel.x
                        } else {
                            // bottom edge
                            trial_entity.vel.y = -trial_entity.vel.y
                        }
                    }

                    if trial_entity.type == .Bonus && test_entity.type == .Paddle {
                        trial_entity.visible = false 
                        test_entity.color = rl.RED
                    }
                }
            }

        }
    }
    
    // Wall collision 
    for i in 0..<NUM_ENTITIES {
        // @TODO: Minkowski sum collision?
        entity := &entities[i]

        min, max := bounding_box(entity)

        if entity.bouncy {
            if min.x <= 0 || max.x >= SCREEN_WIDTH {
                entity.vel.x = -entity.vel.x
            } 

            if min.y <= 0 {
                entity.vel.y = -entity.vel.y
            }

            if max.y >= SCREEN_HEIGHT {
                lost_turn = true 
                turns_left -= 1

                if turns_left == 0 {
                    lost_game = true
                } 
            }



        }

        if entity.type == .Paddle {
            // @TODO: Should this just be clipping?
            if min.x <= 0 {
                entity.pos.x = 0
            } else if max.x >= SCREEN_WIDTH {
                entity.pos.x = SCREEN_WIDTH - entity.width
            } else if min.x <= 0 {
                entity.pos.y = 0
            } else if max.y >= SCREEN_HEIGHT {
                entity.pos.y = SCREEN_HEIGHT - entity.height
            }
        }

        if entity.type == .Bonus {
            // What to do here??
        }
    }

}


reset_ball_and_paddle :: proc() {
    // @TODO: need to streamline this code, should it go at the end of update?
    // @TODO: ball and paddle locations should be placed outside of function
    ball_diameter := f32(10)
    ball_pos_x    := f32(SCREEN_WIDTH / 2 - ball_diameter/2)    
    ball_pos_y    := f32(SCREEN_HEIGHT - 75)
    entities[0].acc = {0.0,0.0}
    entities[0].vel = {0.0,-40.0}
    entities[0].pos = {ball_pos_x, ball_pos_y}

    // paddle 
    paddle_width := 100 
    paddle_pos_x := f32(SCREEN_WIDTH / 2 - paddle_width/2)
    entities[1].acc = {0.0,0.0}
    entities[1].vel = {0.0,0.0}
    entities[1].pos = {paddle_pos_x, f32(ball_pos_y + ball_diameter)}
}

reset_bricks :: proc() {
    for i in 0..<NUM_ENTITIES {
        if entities[i].type == .Brick {
            entities[i].visible = true    
        }
    }
}

setup_game :: proc() {
    // ball ...
    ball_diameter := f32(10)
    ball_pos_x    := f32(SCREEN_WIDTH / 2 - ball_diameter/2)    
    ball_pos_y    := f32(SCREEN_HEIGHT - 75)
    entities[0] = {
        id       = 0,
        type     = .Ball,
        visible  = true,
        mobile   = true,
        airdrag  = 0.0,
        acc      = {0.0,0.0},
        vel      = {0.0,-40.0},
        pos      = {ball_pos_x, ball_pos_y},
        bouncy   = true,
        height   = f32(ball_diameter),
        width    = f32(ball_diameter),
        color    = rl.RAYWHITE
    }

    // paddle 
    paddle_width := 100 
    paddle_pos_x := f32(SCREEN_WIDTH / 2 - paddle_width/2)
    entities[1] = {
        id       = 0,
        type     = .Paddle,
        visible  = true,
        mobile   = true,
        airdrag  = 5.0,
        acc      = {0.0,0.0},
        vel      = {0.0,0.0},
        pos      = {paddle_pos_x, f32(ball_pos_y + ball_diameter)},
        bouncy   = false,
        height   = 20,
        width    = 100,
        color    = rl.GREEN
    }

    // @TODO: Improve way the grid is set up, including the units

    row := 0
    col := 0

    height := f32(30)
    width  := f32(60) 
    space  := f32(1) 

    grid_width := 9 * width + 8 * space
    grid_min_x := (f32(SCREEN_WIDTH) - f32(grid_width)) / 2 

    xpos: f32 = grid_min_x
    ypos: f32 = 50.0

    for i in 2..<56 {

        entities[i] = {
            id       = i,
            type     = .Brick,
            visible  = true,
            mobile   = false,
            pos      = {xpos, ypos},
            height   = f32(height),
            width    = f32(width),
            color    = colors[row],
            points   = 10*(6-row),
        }

        xpos += width + space
        col  += 1
        if col == 9 {
            xpos  = grid_min_x
            ypos += height+space
            row  += 1 
            col   = 0
        }
    }

    // Bonuses
    entities[56] = {
        id      = 56,
        type    = .Bonus,
        visible = false,
        height  = 20,
        width   = 40,
        color   = rl.GRAY,
        pos     = {200.0, 75.0},
        mobile  = true
    } 

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
     
}

turns : int = 3 

main :: proc() {

    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "BreakOut")
    defer rl.CloseWindow() 

    setup_game()
 
    // @TODO: eliminate this
    // Running way faster so that we can test my timing routine
    rl.SetTargetFPS(240)

    N := 0

    cnt : u64 

    prev_tick := time.read_cycle_counter() 
    curr_tick := prev_tick
    
    // @TODO: Make this a compile time constant?
    counts_per_frame := u64(PROCESSOR_HZ * 15e-3)

    for !rl.WindowShouldClose() {
        
        ///////////////////////////////////////////////////////////////////////
        // Initial set up
        //
        if lost_game {
            if rl.IsKeyPressed(.ENTER) {
                reset_ball_and_paddle()
                reset_bricks()
                lost_turn = false
                lost_game = false
                paused    = true 
                score     = 0               
            }
        } else if lost_turn {
            reset_ball_and_paddle()
            lost_turn = false
            paused    = true   
        } 


        ///////////////////////////////////////////////////////////////////////
        // Update the physics
        //
        if !lost_turn {
            update_game()
        } 

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

        rl.DrawText(rl.TextFormat("Score: %03d", score), 10, SCREEN_HEIGHT - 32, 32, rl.RAYWHITE)
        rl.DrawText(rl.TextFormat("Turns Left: %d", turns_left), 500, SCREEN_HEIGHT - 32, 32, rl.RAYWHITE)
        for i in 0..<NUM_ENTITIES {
            entity := &entities[i]
            if entity.visible {
                draw_entity(entity)
            }
        }

        if lost_game {
            // @TODO: Should probably so this text location and measurement ahead of time
            str : cstring = "HIT ENTER TO PLAY AGAIN"
            width := rl.MeasureText(str, 32);
            rl.DrawText(str, SCREEN_WIDTH/2 - width/2, SCREEN_HEIGHT/2, 32, rl.RED)    
        }

        rl.EndDrawing()

        //////////////////////////////////////////////////////////////////////
        // Check that we're hitting the frame rate
        // @TODO: add a compile time flag to enable/disable framerate timing
        curr_tick = time.read_cycle_counter() 
        //fmt.printf("%.6f\n", f32(curr_tick - prev_tick) / f32(PROCESSOR_HZ))
        prev_tick = curr_tick
        //////////////////////////////////////////////////////////
        
    }

}

