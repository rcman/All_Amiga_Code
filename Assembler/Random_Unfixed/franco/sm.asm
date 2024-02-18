* Bob Attempt
 include "exec/types.i"
 include "intuition/intuition.i"

movescreen  equ -162
openscreen  equ -198
closescreen equ -66
closelibrary equ -414
openlib     equ -408      ;open library
execbase    equ  4        ;EXEC base address
joy2        equ $dff00c   ;joystick 2 Data
fire        equ $bfe001   ;fire button 2:Bit 7
setrgb4     equ  -288


run:
       bsr     openint         ;Open library
       bsr     scropen         ;Open Screen
       
		
 
;       move.l  bitplane1,a1
;       add.l   #4019,a1

;       lea     man(pc),a2
;       moveq   #13,d0
placeman:
;       move.b  (a2)+,(a1)      ;place man data on the screen
;       move.b  (a2)+,1(a1)     ;place man data on the screen
;       add.l   #40,a1          ;move plane pointer down one scan line
;       dbra    d0,placeman

        move.l  #0,d0           ;pen
        move.l  #0,d1           ;red
        move.l  #0,d2           ;green
        move.l  #0,d3           ;blue
        move.l  viewport,a0     ;Get Pointer to View Port
        move.l  gfxbase,a6      ;get grapics base
        jsr     setrgb4(a6)     ;set a color registor

        move    joy2,d6         ;Save Joystick Info

loop:
        tst.b   fire            ;Test Fire Button
        bpl     ende            ;Press Down:Done
        move    joy2,d0         ;Basic info in D0
        sub     d6,d0           ;Subtract New Data
        cmp     #$0100,d0       ;Up?
        bne     noup            ;No
        move.l  #-2,d1          ;dy equ -2 direction Y
        bsr     scrmove         ;Move Up
        bra     loop

noup:

        cmp     #$0001,d0       ;Down?
        bne     loop            ;No
        move.l  #2,d1           ;dy equ 2
        bsr     scrmove         ;move down
        bra     loop

ende:

        bsr     scrclose        ;close screen
        bsr     closeint        ;close intuition
        rts                     ;Done !

openint:

        move.l  execbase,a6     ;EXEC base address
        lea     intname,a1      ;name of intuition library
        jsr     openlib(a6)     ;Open intuition
        move.l  d0,intbase      ;Save Intuition base address
        rts

closeint:

        move.l  execbase,a6     ;*close Intuition
        move.l  intbase,a1      ;intuition base address in A1
        jsr     closelibrary(a6);close intuition
        rts                     ;Done
scropen:
      
	move.l  intbase,a6    	        ;Intuition base address in A6
        lea     screen_defs,a0 	        ;Pointer to Table
        jsr     openscreen(a6)          ;OPen
	move.l  d0,screenhd             ;Save Screen Handle
        move.l  d0,a0                   ;get screen pointer ready
	move.l  $c0(a0),bitplane1       ;get pointer to bit plane # 1
        move.l  $c4(a0),bitplane2       ;get pointer to bit plane # 2
        move.l  $2c(a0),viewport        ;get pointer to view port
        move.l  RastPort(a0),Raster
	move.l  execbase,a6             ;EXEC base address
   	lea     gfxname,a1              ;name of graphics library
	jsr     openlib(a6)             ;Open graphics library
        move.l  d0,gfxbase              ;Save graphics base address
        

	rts                     ;Return to Main Program

scrclose:

       move.l  intbase,a6      ;Intuition base address in A6
       move.l  screenhd,a0     ;Screen Handle in A0
       jsr     closescreen(a6) ;And Move
       rts                     ;Done

scrmove:

       move.l  intbase,a6      ;Intuition base in A6
       move.l  screenhd,a0     ;Screen Handle in A0
       clr.l   d0              ;No horizontal movement
       jsr     movescreen(a6)  ;And Move
       rts                     ;Done

       cnop 0,2

screen_defs:
x_pos:         dc.w    0       ;x-position
y_pos:         dc.w    0       ;y-position
width:         dc.w    320     ;width
height:        dc.w    200     ;height
depth:         dc.w    2       ;Number of Bit Planes 2

detail_pen:    dc.b    1       ;Text Colour equ  White
block_pen:     dc.b    3       ;Background Color equ  Red
view_modes:    dc.w    2       ;Representation Mode
screen_types:  dc.w    15      ;Screen Type:Custom Screen
font:          dc.l    0       ;Standard Character Set
title:         dc.l    sname   ;Pointer to title text
gadgets:       dc.l    0       ;No gadgets
bitmap:        dc.l    0       ;No Bit Map
intbase:       dc.l    0       ;Base Address of Intuition
screenhd:      dc.l    0       ;Screen Handle
intname:       dc.b    'intuition.library',0
       cnop 0,2
gfxname:       dc.b    'graphics.library',0
       cnop 0,2

sname:         dc.b    'BOB Screen',0 ;Screen Title
       cnop 0,2
Raster:      dc.l    0
viewport:      dc.l    0
gfxbase:       dc.l    0

bitplane1:     dc.l    0
bitplane2:     dc.l    0

man:           dc.b    1,$80,2,$40,1,$80,7,$e0,$d,$b0,9,$90
               dc.b    $11,$88,3,$c0,2,$40,6,$60,$c0,$30,$18,$18

       end





