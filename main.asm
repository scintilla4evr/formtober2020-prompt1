    device ZXSPECTRUM128

    org $8000

    include "./lib/output.z80"

Main:
    ; pain incoming
    call PrepScreen
    call PrepTrack

    call FillTurnBack
    call DrawString

    call AnimLoop
    ret

AnimTickDelay: db 80 ; delay for tick updates

; Animation loop!
AnimLoop:
    call FillTrackStart

    ; This calms the tick updates by spacing them out
    ld a, (AnimTickDelay)
    cp 0
    jr nz, AnimLoopDone
    ld a, 80
    ld (AnimTickDelay), a

    ; Tick updates
    call TrackPaletteTick

AnimLoopDone:
    ld a, (AnimTickDelay)
    dec a
    ld (AnimTickDelay), a

    jp AnimLoop

; Draws the * TURN BACK * text
TurnBackStr: db $9, $0, "* TURN  BACK *", $FF
DrawString:
    ld ix, TurnBackStr
    call Print_String
    ret

FillTurnBack:
    ld b, 8
    ld c, 0
    call GetAttrAddress ; HL = address

    ld c, 16 ; width
    ld b, 1 ; height
    ld a, %11000010 ; bright red, flashing
    call Fill_Attr
    ret

; fill screen with black
PrepScreen:
    ld a, %00000000 ; black
    call Clear_Screen
    call 8859 ; border color
    ret

; fills out the area that will be next to the track
PrepTrack:
    ld b, 0
    ld c, 96 ; 12 * 8 (8 "pixels" per block)
    call GetAttrAddress

    ld c, 32
    ld b, 12
    ld a, %00111111 ; "dark" white = gray
    call Fill_Attr
    ret

TrackPaletteOffset: db 0 ; 0, 1 or 2

; Update the palette offset
TrackPaletteTick:
    ld a, (TrackPaletteOffset)
    inc a ; increment
    cp 3 ; if a == 3, Z = true
    jr nz, TrackPaletteTickDone

    ; uh oh! offset = 3!! oopsies!
    ld a, 0

TrackPaletteTickDone:
    ld (TrackPaletteOffset), a ; put back
    ret

FillTrackStart:
    ld b, 12 ; b is the loop counter
FillTrackLoop:
    call FillTrackLoopBody
    
    djnz FillTrackLoop ; loop back if b != 0

    ret

; track colors!
TrackPalette: db %01010010 ; red
              db %01110110 ; yellow
              db %01100100 ; green
              db %01010010 ; repeating, so that i don't need modulo
              db %01110110
              db %01100100
              db %01010010
              db %01110110
              db %01100100
              db %01010010
              db %01110110
              db %01100100
              db %01010010
              db %01110110
              db %01100100

FillTrackLoopBody:
    push bc ; this puts b (and c) onto the stack
            ; that will preserve the loop counter

    ; Calculating the Y position of the track block
    ld a, b
    rla ; multiply by 8 by rotating left 3 times
    rla
    rla
    add 88
    ld c, a

    ; Calculating the X position of the track block
    ld a, 12
    sub b
    ld b, a

    call GetAttrAddress

    ; Pick the color from the palette based on X
    push hl ; hl has the address!!
    ld hl, TrackPalette
    ld a, l ; manipulation time!
    add b ; different colors!

    ; Adding the "offset"
    push hl
    ld hl, (TrackPaletteOffset)
    add l ; offset!
    pop hl

    ld l, a
    ld a, (hl)
    pop hl ; oof!
    push af ; store the color for a sec

    ; Calculating the width
    ; Width = 32 - x - x (x = "margin")
    ld a, 32
    sub b
    sub b
    ld c, a
    ; Height = 1
    ld b, 1

    pop af ; get that color back
    call Fill_Attr

    pop bc ; bring back the loop counter
    ret

; Get address of block in attribute map
; BC - XY
; address -> HL
; https://www.chibiakumas.com/z80/simplesamples.php#LessonS2
GetAttrAddress:
    ld a, C
        and %11000000
        rlca
        rlca
        add $58
        ld d, a
    ld a, C
    and %00111000
    rlca
    rlca

    add b
    ld e, a

    push de
    pop hl
    ret

    savesna "./main.sna", Main