
; This program saves a screen after you open another with a utility
; program. Run this program, load and IFF and hit the fire button to
; save it as 40000 bytes od data. 5 bitplanes 8000/plane = 40000 bytes.
; program written by Sean godsell and Franco Gaetan.
; Date: May 9, 1987

open        equ -30
close       equ -36
read        equ -42
mode_old    equ 1006
write equ -48
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

waittosave:
       move.b  fire,d0

       and.b   #$80,d0
       bne.s   waittosave

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
       jsr     write(a6)          

       move.l  bitplane2,d2      ;buffer
       move.l  #8000,d3          ;length
       move.l  filehandle,d1             ;file handle
       move.l  dosbase,a6
       jsr     write(a6)          

       move.l  bitplane3,d2      ;buffer
       move.l  #8000,d3          ;length
       move.l  filehandle,d1             ;file handle
       move.l  dosbase,a6
       jsr     write(a6)   

       move.l  bitplane4,d2      ;buffer
       move.l  #8000,d3          ;length
       move.l  filehandle,d1             ;file handle
       move.l  dosbase,a6
       jsr     write(a6)    

       move.l  bitplane5,d2      ;buffer
       move.l  #8000,d3          ;length
       move.l  filehandle,d1             ;file handle
       move.l  dosbase,a6
       jsr     write(a6)   

       move.l  filehandle,d1
       move.l  dosbase,a6
       jsr     close(a6)


       move.l  intbase,a6      ;Intuition base address in A6
       move.l  screenhd,openscreen+2(a6)  ;OPen


ende:
       bsr     closeint        ;close intuition
       clr.l   d0
       rts                     ;Done !


       move.l  bitplane1,a1
       add.l   #4019,a1

       lea     man(pc),a2
       moveq   #13,d0

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
       move.l  intbase,a6      ;Intuition base address in A6
       move.l  openscreen+2(a6),screenhd  ;OPen
       lea     screenpatch(pc),a1
       move.l  a1,openscreen+2(a6)
       lea     jmpadr+2(pc),a1
       move.l  screenhd,(a1)

waitforsomet:
       cmp.l   #0,handler
       beq.s   waitforsomet

       move.l  handler,a0           ;get screen pointer ready
       move.l  $c0(a0),bitplane1       ;get pointer to bit plane # 1
       move.l  $c4(a0),bitplane2       ;get pointer to bit plane # 2
       move.l  $c8(a0),bitplane3
       move.l  $cc(a0),bitplane4
       move.l  $d0(a0),bitplane5
       move.l  $2c(a0),viewport        ;get pointer to view port
       rts                     ;Return to Main Program

scrclose:

screenpatch:


jmpadr:
       jsr     $800000
       move.l  d0,handler
       rts

      
screen_defs:
x_pos:         dc.w    0       ;x-position
y_pos:         dc.w    0       ;y-position
width:         dc.w    320     ;width
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
handler:       dc.l    0       ;Return handle for sreen

intname:       dc.b    'intuition.library',0
       
gfxname:       dc.b    'graphics.library',0
       
dosname:       dc.b    'dos.library',0
       
dosfile        dc.b    'dh0:assem/picture1',0
       
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
bitplane6:     dc.l    0
	
man:           dc.b    1,$80,2,$40,1,$80,7,$e0,$d,$b0,9,$90
               dc.b    $11,$88,3,$c0,2,$40,6,$60,$c0,$30,$18,$18

       end





