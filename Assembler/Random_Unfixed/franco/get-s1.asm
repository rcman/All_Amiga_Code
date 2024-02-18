
;Demo program to open and move a screen
open        equ -30
close       equ -36
read        equ -42
mode_old    equ 1005

movescreen  equ -162
openscreen  equ -198
closescreen equ -66
closelibrary equ -414
openlib     equ -408      ;open library
execbase    equ  4        ;EXEC base address
joy2        equ $dff00c   ;joystick 2 Data
fire        equ $bfe001   ;fire button 2:Bit 7
setrgb4     equ  -288
scrollrast  equ  -396


run:
       bsr     openint         ;Open library
       bsr     scropen         ;Open Screen

       move.l  $4,a6
       lea     dosname(pc),a1
       moveq   #0,d0
       jsr     openlib(a6)
       move.l  d0,dosbase

       move.l  d0,a6
       lea     dosfile(pc),a1    ;file name
       move.l  a1,d1
       move.l  #mode_old,d2
       jsr     open(a6)          ;open the file

       move.l  d0,filehandle

       move.l  bitplane1,d2      ;buffer
       move.l  #8000,d3          ;length
       move.l  d0,d1             ;file handle
       move.l  dosbase,a6
       jsr     read(a6)          ;read in the picture

       move.l  bitplane2,d2      ;buffer
       move.l  #8000,d3          ;length
       move.l  filehandle,d1             ;file handle
       move.l  dosbase,a6
       jsr     read(a6)          ;read in the picture

       move.l  bitplane3,d2      ;buffer
       move.l  #8000,d3          ;length
       move.l  filehandle,d1             ;file handle
       move.l  dosbase,a6
       jsr     read(a6)          ;read in the picture

       move.l  bitplane4,d2      ;buffer
       move.l  #8000,d3          ;length
       move.l  filehandle,d1             ;file handle
       move.l  dosbase,a6
       jsr     read(a6)          ;read in the picture

       move.l  bitplane5,d2      ;buffer
       move.l  #8000,d3          ;length
       move.l  filehandle,d1             ;file handle
       move.l  dosbase,a6
       jsr     read(a6)          ;read in the picture

       move.l  filehandle,d1
       move.l  dosbase,a6
       jsr     close(a6)

       move.w  #200,d0

scrollscrn:
       move.w  d0,counts
       move.l  screenhd,a1
       add.l   #$54,a1
;       move.l  d0,a1
       move.l   #0,d2           ;X1
       move.l  #619,d4         ;X2
       move.l   #0,d3           ;Y1
       move.l  #199,d5         ;Y2
       moveq   #3,d0          ;Dx
       moveq   #0,d1           ;Dy
	
	
       move.l  gfxbase,a6
       jsr     scrollrast(a6)
       move.w  counts,d0
       dbra    d0,scrollscrn
	
	


waitleave:
       move.b  fire,d0
       and.b   #$80,d0
       bne     waitleave

ende:
       bsr     scrclose        ;close screen
       bsr     closeint        ;close intuition
       rts                     ;Done !


openint:
       move.l  execbase,a6     ;EXEC base address
       lea     gfxname,a1      ;name of intuition library
       jsr     openlib(a6)     ;Open intuition
       move.l  d0,gfxbase      ;Save Intuition base address
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
       move.l  intbase,a6      ;Intuition base address in A6
       lea     screen_defs,a0  ;Pointer to Table
       jsr     openscreen(a6)  ;OPen
       move.l  d0,screenhd     ;Save Screen Handle
       move.l  d0,a0           ;get screen pointer ready
       move.l  $c0(a0),bitplane1       ;get pointer to bit plane # 1
       move.l  $c4(a0),bitplane2       ;get pointer to bit plane # 2
       move.l  $c8(a0),bitplane3
       move.l  $cc(a0),bitplane4
       move.l  $d0(a0),bitplane5
       move.l  $2c(a0),viewport        ;get pointer to view port
       rts                     ;Return to Main Program
scrclose:
       move.l  intbase,a6      ;Intuition base address in A6
       move.l  screenhd,a0     ;Screen Handle in A0
       jsr     closescreen(a6) ;And Move
       rts                     ;Done
       
screen_defs:
x_pos:         dc.w    0       ;x-position
y_pos:         dc.w    0       ;y-position
width:         dc.w    620     ;width
height:        dc.w    200     ;height
depth:         dc.w    5       ;Number of Bit Planes 2
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
       
gfxname:       dc.b    'graphics.library',0
       
dosname:        dc.b    'dos.library',0
       
dosfile:        dc.b    'dh0:assem/picture1',0
       
sname:         dc.b    'Our Screen',0 ;Screen Title
       
rastport:      dc.l    0
viewport:      dc.l    0
gfxbase:       dc.l    0
dosbase:       dc.l    0
filehandle:    dc.l    0

bitplane1:     dc.l    0
bitplane2:     dc.l    0
bitplane3:     dc.l    0
bitplane4:     dc.l    0
bitplane5:     dc.l    0
counts:        dc.w    0
     end





