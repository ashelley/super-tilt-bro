anim_sinbad_spe_up_left_prepare:
; Frame 1
ANIM_FRAME_BEGIN(200)
ANIM_HURTBOX($00, $07, $02, $0f) ; left, right, top, bottom
ANIM_SPRITE($09, TILE_SCIMITAR_BLADE, $01, $fa)  ; Y, tile, attr, X
ANIM_SPRITE($09, TILE_SCIMITAR_HANDLE, $01, $02)
ANIM_SPRITE($00, TILE_LANDING_SINBAD_2_TOP, $00, $00)
ANIM_SPRITE($08, TILE_LANDING_SINBAD_2_BOT, $00, $00)
ANIM_SPRITE($08, TILE_POWER_FLAMES_LARGE_2, $01, $f9)
ANIM_SPRITE($08, TILE_POWER_FLAMES_LARGE_2, $41, $07)
ANIM_FRAME_END
; End of animation
ANIM_ANIMATION_END

anim_sinbad_spe_up_left_jump:
; Frame 1
ANIM_FRAME_BEGIN(200)
ANIM_HURTBOX($00, $07, $00, $0f)
ANIM_HITBOX($01, $0a, $fd00, $fd00, $fffb, $fffe, $f4, $ff, $02, $07)
ANIM_SPRITE($00, TILE_SCIMITAR_BLADE, $81, $f4)  ; Y, tile, attr, X
ANIM_SPRITE($00, TILE_SCIMITAR_HANDLE, $81, $fc)
ANIM_SPRITE($00, TILE_SIDE_TILT_SINBAD_2_1, $00, $00)
ANIM_SPRITE($08, TILE_JUMPING_SINBAD_2, $00, $00)
ANIM_FRAME_END
; End of animation
ANIM_ANIMATION_END

anim_sinbad_spe_up_right_prepare:
; Frame 1
ANIM_FRAME_BEGIN(200)
ANIM_HURTBOX($00, $07, $02, $0f)
ANIM_SPRITE($08, TILE_POWER_FLAMES_LARGE_2, $01, $f9)
ANIM_SPRITE($08, TILE_POWER_FLAMES_LARGE_2, $41, $07)
ANIM_SPRITE($08, TILE_LANDING_SINBAD_2_BOT, $40, $00)
ANIM_SPRITE($00, TILE_LANDING_SINBAD_2_TOP, $40, $00)
ANIM_SPRITE($09, TILE_SCIMITAR_HANDLE, $41, $fe)
ANIM_SPRITE($09, TILE_SCIMITAR_BLADE, $41, $06)
ANIM_FRAME_END

anim_sinbad_spe_up_right_jump:
; Frame 1
ANIM_FRAME_BEGIN(200)
ANIM_HURTBOX($00, $07, $00, $0f)
ANIM_HITBOX($01, $0a, $0300, $fd00, $0005, $fffe, $08, $13, $02, $07)
ANIM_SPRITE($08, TILE_JUMPING_SINBAD_2, $40, $00)
ANIM_SPRITE($00, TILE_SIDE_TILT_SINBAD_2_1, $40, $00)
ANIM_SPRITE($00, TILE_SCIMITAR_HANDLE, $c1, $04)
ANIM_SPRITE($00, TILE_SCIMITAR_BLADE, $c1, $0c)
ANIM_FRAME_END
; End of animation
ANIM_ANIMATION_END