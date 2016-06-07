init_game_state:
.(
lda DIRECTION_LEFT
sta player_b_direction

lda DIRECTION_RIGHT
sta player_a_direction

lda HITBOX_DISABLED
sta player_a_hitbox_enabled
sta player_b_hitbox_enabled

lda #$80
sta player_a_y
sta player_b_y
sta player_a_hurtbox_top
sta player_b_hurtbox_top
lda #$40
sta player_a_x
sta player_a_hurtbox_left
lda #$a0
sta player_b_x
sta player_a_hurtbox_left
lda #$88
sta player_a_hurtbox_bottom
sta player_b_hurtbox_bottom
lda #$48
sta player_a_hurtbox_right
lda #$a8
sta player_b_hurtbox_right

lda #$7f
sta player_a_max_velocity
sta player_b_max_velocity

ldx #$00
jsr start_standing_player
ldx #$01
jsr start_standing_player

rts
.)

update_players:
.(
; Remove processed nametable buffers
lda #$00
sta nametable_buffers

; Check hitbox collisions
ldx #$00
hitbox_one_player:
jsr check_player_hit
inx
cpx #$02
bne hitbox_one_player

; Clean hitboxes
lda HITBOX_DISABLED
sta player_a_hitbox_enabled
sta player_b_hitbox_enabled

ldx #$00 ; player number

update_one_player:

; Check state 0 - standing
lda player_a_state, x
bne check_running
jsr standing_player
jmp player_updated

; Check state 1 - running
check_running:
cmp PLAYER_STATE_RUNNING
bne check_falling
jsr running_player
jmp player_updated

; Check state 2 - falling
check_falling:
cmp PLAYER_STATE_FALLING
bne check_jumping
jsr falling_player
jmp player_updated

; Check state 3 - jumping
check_jumping:
cmp PLAYER_STATE_JUMPING
bne check_jabbing
jsr jumping_player
jmp player_updated

; Check state 4 - jabbing
check_jabbing:
cmp PLAYER_STATE_JABBING
bne check_thrown
jsr jabbing_player
jmp player_updated

; Check state 5 - thrown
check_thrown:
cmp PLAYER_STATE_THROWN
bne player_updated
jsr thrown_player

player_updated:
jsr move_player
jsr check_player_position
jsr write_player_damages
inx
cpx #$02
bne update_one_player

rts
.)

check_player_hit:
.(
current_player = tmpfield10
opponent_player = tmpfield11
force_h = tmpfield12
force_v = tmpfield13

; Store current player number
stx current_player

; Check that player's hitbox is enabled
lda player_a_hitbox_enabled, x
beq end

; Store current player's hitbox
lda player_a_hitbox_left, x
sta tmpfield1
lda player_a_hitbox_right, x
sta tmpfield2
lda player_a_hitbox_top, x
sta tmpfield3
lda player_a_hitbox_bottom, x
sta tmpfield4

; Switch current player to select the opponent
.(
cpx #$00
beq select_player_b
dex
jmp end_switch_player
select_player_b:
inx
end_switch_player:
.)

; Store opponent player number
stx opponent_player

; Store opponent's hurtbox
lda player_a_hurtbox_left, x
sta tmpfield5
lda player_a_hurtbox_right, x
sta tmpfield6
lda player_a_hurtbox_top, x
sta tmpfield7
lda player_a_hurtbox_bottom, x
sta tmpfield8

; Check collisions between hitbox and hurtbox
jsr boxes_overlap
lda tmpfield9
bne end

; Apply force vector to the opponent
ldx current_player
lda player_a_hitbox_force_h, x ;
sta force_h                    ; Save force vector to a player independent
lda player_a_hitbox_force_v, x ; location
sta force_v                    ;
ldx opponent_player
lda player_a_damages, x ;
lsr                     ;
lsr                     ; Get force multiplier
lsr                     ; "(damages / 16) + 1"
lsr                     ;
clc                     ;
adc #$01                ;
sta tmpfield2           ;
lda force_h   ;
sta tmpfield1 ;
jsr multiply  ; Push "force_h * multiplier"
lda tmpfield3 ;
pha           ;
lda force_v    ;
sta tmpfield1  ;
jsr multiply   ; Push "force_v * multiplier"
lda tmpfield3  ;
pha            ;
jsr merge_player_velocity ; Apply force vector from stack

; Apply damages to the opponent
ldx current_player
lda player_a_hitbox_damages, x ; Put hitbox damages in A
ldx opponent_player
clc                     ;
adc player_a_damages, x ;
cmp #200                ;
bcs cap_damages         ; Apply damages, capped to 199
jmp apply_damages:      ;
cap_damages:            ;
lda #199                ;
apply_damages:          ;
sta player_a_damages, x ;

; Set opponent to thrown state
jsr start_thrown_player

end:
; Reset register X to the current player
ldx current_player
rts
.)

; Move the player according to it's velocity and collisions with obstacles
;  register X - player number
;
;  When returning player's position is updated, tmpfield1 contains it's old X
;  and tmpfield2 contains it's old Y
move_player:
.(
; Save old position
lda player_a_x, x
sta tmpfield1
lda player_a_y, x
sta tmpfield2

; Apply velocity to position
lda player_a_velocity_h, x
clc
adc player_a_x, x
sta tmpfield3

lda player_a_velocity_v, x
clc
adc player_a_y, x
sta tmpfield4

; Check collisions with stage plaform
lda STAGE_EDGE_LEFT
sta tmpfield5
lda STAGE_EDGE_TOP
sta tmpfield6
lda STAGE_EDGE_RIGHT
sta tmpfield7
lda STAGE_EDGE_BOTTOM
sta tmpfield8

jsr check_collision
lda tmpfield3
sta player_a_x, x
lda tmpfield4
sta player_a_y, x

rts
.)

; Check the player's position and modify the current state accordingly
;  register X - player number
;  tmpfield1 - player's old X
;  tmpfield2 - player's old Y
check_player_position:
.(
old_x = tmpfield1
old_y = tmpfield2

; Check death
lda player_a_velocity_h, x
bpl check_right_blast
lda old_x           ; Horizontal velocity is negative
cmp player_a_x, x   ; die if "old X < new X"
bcc set_death_state ;
jmp check_vertical_blasts
check_right_blast:
lda player_a_x, x   ; Horizontal velocity is positive
cmp old_x           ; die if "new X < old X"
bcc set_death_state ;
check_vertical_blasts
lda player_a_velocity_v, x
bpl check_bottom_blast
lda old_y           ; Vertical velocity is negative
cmp player_a_y, x   ; die if "old Y < new Y"
bcc set_death_state ;
jmp end_death_checks
check_bottom_blast:
lda player_a_y, x   ; Vertical velocity is positive
cmp old_y           ; die if "new Y < old Y"
bcc set_death_state ;
end_death_checks:

; Jumping players obey their own physics
lda player_a_state, x
cmp PLAYER_STATE_JUMPING
beq end

; Check if on ground
;  Not grounded players must be falling
lda player_a_x, x
cmp STAGE_EDGE_LEFT
bcc set_falling_state
beq set_falling_state
cmp STAGE_EDGE_RIGHT
bcs set_falling_state
lda player_a_y, x
cmp STAGE_EDGE_TOP
bne set_falling_state

; On ground
;  Check if we are on a state that needs to be updated
lda player_a_state, x
cmp PLAYER_STATE_FALLING
beq set_standing_state

; No state change is required
jmp end

set_death_state:
jsr start_respawn_player
jmp end

set_standing_state:
jsr start_standing_player
jmp end

set_falling_state:
lda PLAYER_STATE_FALLING
sta player_a_state, x

end:
rts
.)

; Show on screen player's damages
;  register X must contain the player number
write_player_damages:
.(
ppu_position = tmpfield4

; Save X
txa
pha

; Set on-screen text position depending on the player
cpx #$00
beq prepare_player_a
lda #$91
sta ppu_position
jmp end_player_variables
prepare_player_a:
lda #$88
sta ppu_position
end_player_variables:

; Put damages value parameter for number_to_tile_indexes
lda player_a_damages, x
sta tmpfield1

; Write the begining of the buffer
jsr last_nt_buffer
lda #$01                 ; Continuation byte
sta nametable_buffers, x ;
inx
lda #$23                 ; PPU address MSB
sta nametable_buffers, x ;
inx
lda ppu_position         ; PPU address LSB
sta nametable_buffers, x ;
inx
lda #$03                 ; Tiles count
sta nametable_buffers, x ;
inx

; Store the tiles address as destination parameter for number_to_tile_indexes
txa
sta tmpfield2
lda #>nametable_buffers
sta tmpfield3

; Set the next continuation byte to 0
inx
inx
inx
lda #$00
sta nametable_buffers, x

; Populate tiles data
jsr number_to_tile_indexes

; Restore X
pla
tax

rts
.)

update_sprites:
.(
ldx #$00

player_animation:
ldy #$00
lda #$00
sta tmpfield1

; Store current player's animation vector to a player independent location
cpx #$00
bne select_anim_player_b
lda player_a_animation
sta tmpfield3
lda player_a_animation+1
sta tmpfield4
lda #$00
sta tmpfield5
jmp new_frame
select_anim_player_b:
lda player_b_animation
sta tmpfield3
lda player_b_animation+1
sta tmpfield4
lda #$08
sta tmpfield5

; New frame (search for the frame on time with clock)
new_frame:
lda (tmpfield3), y ; Load frame duration
beq loop_animation ; Frame of duration 0 means end of animation
clc           ;
adc tmpfield1 ; Store current frame clock end in tmpfield1
sta tmpfield1 ;

; If the current frame ends after the clock time, draw it
cmp player_a_anim_clock, x
bcs draw_current_frame

; Search the next frame
iny ; Skip frame duration field
skip_sprite:
lda (tmpfield3), y ; Check current sprite continuation byte
beq end_skip_frame ;
sta tmpfield6  ;
lda #$05       ;
sta tmpfield7  ; Set data length in tmpfield7
lda #%00001000 ; hitbox data is 9 bytes long
bit tmpfield6  ; other data are 5 bytes long
beq inc_cursor ; (counting the continuation byte)
lda #$09       ;
sta tmpfield7  ;
inc_cursor:
tya           ;
clc           ; Add data length to Y, to point on the next continuation byte
adc tmpfield7 ;
tay           ;
jmp skip_sprite
end_skip_frame:
iny ; Skip the last continuation byte
jmp new_frame

draw_current_frame:
; Animation location is player's location
lda player_a_x, x
sta tmpfield1
lda player_a_y, x
sta tmpfield2

; Add Y to the animation vector, to point to the good frame
iny ; Inc Y to skip the frame duration field
tya
clc
adc tmpfield3
sta tmpfield3
lda #$00
adc tmpfield4
sta tmpfield4

txa
pha
jsr draw_anim_frame
pla
tax

tick_clock:
inc player_a_anim_clock, x
jmp next_player

loop_animation:
lda #$00
sta player_a_anim_clock, x

next_player:
inx
cpx #$02
bne player_animation

jsr show_hitboxes

rts
.)

; Draw an animation frame on screen
;  tmpfield1 - Position X
;  tmpfield2 - Position Y
;  tmpfield3, tmpfield4 - Vector pointing to the frame to draw
;  tmpfield5 - First sprite index to use
;  X register - player number (ignored if the animation is not related to a player)
;
; Overwrites tmpfield5, tmpfield6, tmpfield7, tmpfield8, tmpfield9 and all registers
draw_anim_frame:
.(
; Pretty names
anim_pos_x = tmpfield1
anim_pos_y = tmpfield2
frame_vector = tmpfield3
sprite_index = tmpfield5
player_number = tmpfield6
sprite_orig_x = tmpfield7
sprite_orig_y = tmpfield8
continuation_byte = tmpfield9

.(
ldy #$00
stx player_number

; Check continuation byte - zero value means end of data
draw_one_sprite:
lda (frame_vector), y
beq end
iny

; Check positioning mode from continuation byte
sta continuation_byte
lda #%00000010
bit continuation_byte
beq set_relative
lda #$00
sta sprite_orig_x
sta sprite_orig_y
jmp check_hurtbox
set_relative:
lda anim_pos_x
sta sprite_orig_x
lda anim_pos_y
sta sprite_orig_y

; Check if next data is hurtbox position, hitbox definition or sprite data from continuation byte
check_hurtbox:
lda #%00000100
bit continuation_byte
beq check_hitbox
jsr anim_frame_move_hurtbox
jmp draw_one_sprite

check_hitbox:
lda #%00001000
bit continuation_byte
beq move_sprite
jsr anim_frame_move_hitbox
jmp draw_one_sprite

move_sprite:
jsr anim_frame_move_sprite
jmp draw_one_sprite

end:
rts
.)

anim_frame_move_sprite:
.(
; Copy sprite data
lda sprite_index
asl
asl
tax
; Y value, must be relative to animation Y position
lda (frame_vector), y
clc
adc sprite_orig_y
sta oam_mirror, x
inx
iny
; Tile number
lda (frame_vector), y
sta oam_mirror, x
inx
iny
; Attributes
lda (frame_vector), y
sta oam_mirror, x
inx
iny
; X value, must be relative to animation X position
lda (frame_vector), y
clc
adc sprite_orig_x
sta oam_mirror, x
iny

; Next sprite
inc sprite_index

rts
.)

anim_frame_move_hurtbox:
.(
; Left
ldx player_number
lda (frame_vector), y
clc
adc sprite_orig_x
sta player_a_hurtbox_left, x
iny
; Right
lda (frame_vector), y
clc
adc sprite_orig_x
sta player_a_hurtbox_right, x
iny
; Top
lda (frame_vector), y
clc
adc sprite_orig_y
sta player_a_hurtbox_top, x
iny
; Top
lda (frame_vector), y
clc
adc sprite_orig_y
sta player_a_hurtbox_bottom, x
iny

rts
.)

anim_frame_move_hitbox:
.(
ldx player_number
; Enabled
lda (frame_vector), y
sta player_a_hitbox_enabled, x
iny
; Damages
lda (frame_vector), y
sta player_a_hitbox_damages, x
iny
; Force_h
lda (frame_vector), y
sta player_a_hitbox_force_h, x
iny
; Force_v
lda (frame_vector), y
sta player_a_hitbox_force_v, x
iny
; Left
ldx player_number
lda (frame_vector), y
clc
adc sprite_orig_x
sta player_a_hitbox_left, x
iny
; Right
lda (frame_vector), y
clc
adc sprite_orig_x
sta player_a_hitbox_right, x
iny
; Top
lda (frame_vector), y
clc
adc sprite_orig_y
sta player_a_hitbox_top, x
iny
; Top
lda (frame_vector), y
clc
adc sprite_orig_y
sta player_a_hitbox_bottom, x
iny

rts
.)

.)

; Debug subroutine to show hitboxes and hurtboxes
show_hitboxes:
.(
pha
txa
pha
tya
pha

; Player A hurtbox
ldx #$fc
lda player_a_hurtbox_top
sta oam_mirror, x
inx
lda #$0d
sta oam_mirror, x
inx
lda #$03
sta oam_mirror, x
inx
lda player_a_hurtbox_left
sta oam_mirror, x
inx
ldx #$f8
lda player_a_hurtbox_bottom
sec
sbc #$08
sta oam_mirror, x
inx
lda #$0d
sta oam_mirror, x
inx
lda #$03
sta oam_mirror, x
inx
lda player_a_hurtbox_right
sec
sbc #$08
sta oam_mirror, x
inx

; Player B hurtbox
ldx #$f4
lda player_b_hurtbox_top
sta oam_mirror, x
inx
lda #$0d
sta oam_mirror, x
inx
lda #$03
sta oam_mirror, x
inx
lda player_b_hurtbox_left
sta oam_mirror, x
inx
ldx #$f0
lda player_b_hurtbox_bottom
sec
sbc #$08
sta oam_mirror, x
inx
lda #$0d
sta oam_mirror, x
inx
lda #$03
sta oam_mirror, x
inx
lda player_b_hurtbox_right
sec
sbc #$08
sta oam_mirror, x
inx

; Player A hitbox
lda player_a_hitbox_enabled
bne show_player_a_hitbox
lda #$fe  ;
sta $02e8 ;
sta $02e9 ;
sta $02ea ;
sta $02eb ; Hide disabled hitbox
sta $02ec ;
sta $02ed ;
sta $02ee ;
sta $02ef ;
jmp end_player_a_hitbox
show_player_a_hitbox:
ldx #$ec
lda player_a_hitbox_top
sta oam_mirror, x
inx
lda #$0e
sta oam_mirror, x
inx
lda #$03
sta oam_mirror, x
inx
lda player_a_hitbox_left
sta oam_mirror, x
inx
ldx #$e8
lda player_a_hitbox_bottom
sec
sbc #$08
sta oam_mirror, x
inx
lda #$0e
sta oam_mirror, x
inx
lda #$03
sta oam_mirror, x
inx
lda player_a_hitbox_right
sec
sbc #$08
sta oam_mirror, x
inx
end_player_a_hitbox

; Player B hitbox
lda player_b_hitbox_enabled
bne show_player_b_hitbox
lda #$fe  ;
sta $02e0 ;
sta $02e1 ;
sta $02e2 ;
sta $02e3 ; Hide disabled hitbox
sta $02e4 ;
sta $02e5 ;
sta $02e6 ;
sta $02e7 ;
jmp end_player_b_hitbox
show_player_b_hitbox:
ldx #$e4
lda player_b_hitbox_top
sta oam_mirror, x
inx
lda #$0e
sta oam_mirror, x
inx
lda #$03
sta oam_mirror, x
inx
lda player_b_hitbox_left
sta oam_mirror, x
inx
ldx #$e8
lda player_b_hitbox_bottom
sec
sbc #$08
sta oam_mirror, x
inx
lda #$0e
sta oam_mirror, x
inx
lda #$03
sta oam_mirror, x
inx
lda player_b_hitbox_right
sec
sbc #$08
sta oam_mirror, x
inx
end_player_b_hitbox

pla
tay
pla
tax
pla
rts
.)
