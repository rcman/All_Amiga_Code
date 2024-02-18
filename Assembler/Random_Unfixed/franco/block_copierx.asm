; This program loads a screen, lifts a block from the screen then uses that 
; block to make a srceen design using a table listed at the bottom of this
; program. The table can be changed to form any shap on the screem.
; Size of block is 4 bytes wide and 25 lines high. 32 x 25 = 320 x 200



; Written By: Franco Gaetan
; Date of Last Revision: June 3, 1991
; From File PASTE.ASM
; Status: Working 
; Last Date Complete: January 14, 1992

	 include "include:franco.i"
	 include "include:iff.i"

open        equ -30
close       equ -36
read        equ -42
mode_old    equ 1005
mode_old2    equ 1006
movescreen  equ -162
openscreen  equ -198
closescreen equ -66
openwindow  equ -204
closewindow equ -72
closelibrary equ -414
openlib     equ -408      ;open library
joy2        equ $dff00c   ;joystick 2 Data
fire        equ $bfe001   ;fire button 2:Bit 7

***************************************************************************
no_of_bytes	equ	36	; no of bytes one scan line down
x_size		equ	3	; 0no of words in width (32 bits 0 - 3)
y_size		equ	24	; no of pixels in height
***************************************************************************

run:

	move.l		#4,plane_no

	move.l		plane_no,d1		; no of bitplanes to copy
 	move.l		#8000,sizeofsave	; so block 2
	move.l		#4,counter		


	move.l	#0,fileoffset
	move.l	#1000,offset		

	move.l		#500,d0
	mulu		#100,d1
	sub.l		d0,d1
	move.l		d1,skip

	OpenDos
	IFERR	ErrorDos
	OpenIntuition
	IFERR	ErrorIntuition
	OpenScreen
	IFERR   ErrorScreen
	OpenWindow
	IFERR	ErrorWindow
	OpenGraphics
	IFERR 	ErrorGfx	

        AllocMem 300000,Chip
	move.l	d0,block
	add.l	#8000,d0
        move.l	d0,temp2
	add.l	#18000,d0
	move.l	d0,iff_screen

        Open	filename,o
        Read	60000,iff_screen
        Close

        bsr 	unpack			; Get the screen unpacked
	
*************************************************************************
*			START						*
*************************************************************************


	move.l	#5,block_no
	move.l	#0,blocknumber
	bsr	write_block			; write data to disk

write_blocks:
	bsr	SaveArea
	bsr	Write
	add.l	#2,blocknumber
	sub.l	#1,block_no
	bne.s	write_blocks
	
	bsr	Close

	bra 	ende


wait:

	WaitButton	1

	rts


unpack:

	move.l	screenhd,a0

	move.l	$c0(a0),bitplane1
	move.l	$c4(a0),bitplane2
	move.l	$c8(a0),bitplane3
	move.l	$cc(a0),bitplane4
	move.l	$d0(a0),bitplane5

	move.l	windowhd,a0
	move.l	intbase,a6
	jsr	viewportaddress(a6)
	move.l	a0,viewport

	move.l	iff_screen,a0
	lea	bitplane1(pc),a3
	move.b	$1c(a0),d5	;num of bit planes
	move.w	#600,d1

lookcolor:
	cmp.l	#'CMAP',(a0)
	beq.s	setcolor
	add.l	#2,a0
	dbra	d1,lookcolor

setcolor:
	move.l	4(a0),d7	;length of color map
	divu	#3,d7		;num of pens
	add.l	#8,a0

	move.l	a0,a1
        move.l  viewport,a0     ;Get Pointer to View Port
        move.l  gfxbase,a6      ;get grapics base
	moveq	#0,d0		;pen number
	moveq	#0,d1		;clear r,g,b
	moveq	#0,d2
	moveq	#0,d3

setthecolor:
	move.b	(a1)+,d1	;red
	ror.b	#4,d1
	move.b	(a1)+,d2	;green
	ror.b	#4,d2
	move.b	(a1)+,d3	;blue
	ror.b	#4,d3
	movem.l	d0-d7/a0-a6,-(sp)
        jsr     setrgb4(a6)     ;set a color registor
	movem.l	(sp)+,d0-d7/a0-a6
	addq.l	#1,d0
	dbra	d7,setthecolor

	move.l	a1,a0
	move.l	a0,d0
	and.b	#$fe,d0
	move.l	d0,a0
	move.w	#600,d1

lookbody:
	cmp.l	#'BODY',(a0)
	beq.s	decompress
	add.l	#2,a0
	dbra	d1,lookbody


decompress:
;	move.l	4(a0),d7	;length of body
	move.l	#199,d7		;no. of  lines
 	add.l	#8,a0		;correct offset of data

new_plane:
	lea	bitplane1(pc),a3
	move.b	d5,d4

decomscreen:
	move.l	#40,d0
	move.l	(a3),a1
		
doline:
	moveq	#0,d1
	move.b	(a0)+,d1		;read the byte of data
	bmi.s	repeat

;----- write out bytes n+1 data ------------

keepthemove:
	move.b	(a0)+,(a1)+
	subq	#1,d0
	dble	d1,keepthemove
	bra.s	endline

repeat:
;----- repeat n+1 bytes out ----------------

	neg.b	d1 
	bmi.s	endline  
	move.b	(a0)+,temp

keepmoving:

	move.b	temp,(a1)+
	subq	#1,d0
	dble	d1,keepmoving

endline:
	tst.w	d0
	bgt.s	doline
	move.l	a1,(a3)+
	
	subq.w	#1,d4
	cmp.w	#0,d4
	bne.s	decomscreen

	dbra	d7,new_plane
return:
	rts

******************************************************************************

Read_Block:

        Open	blockname,o
        Read	4000,temp2
        Close
	rts


******************************************************************************

ende:
	FreeMem 300000,block

EndPgm:	
	CloseGraphics
ErrorGfx:
	CloseWindow
ErrorWindow:
	CloseScreen
ErrorScreen:
	CloseIntuition
ErrorIntuition:
	CloseDos
ErrorDos:
	rts

*****************************************************************
*		Take Data from screen	          		*
*****************************************************************
; a2 = area to place save data
; x = d5 x coordinates
; y = d6 y coordinates
 
SaveArea:

	
	movem.l d0-d7/a0-a6,-(sp)
	move.l	temp2,a2
	move.l	plane_no,d4		; no of bitplanes
        lea     bitplane1(pc),a3

getall:

        move.l  (a3)+,a1	;Get me next bitplane 
	add.l	blocknumber,a1
	move.l	#y_size,d0		; how many lines high

doagain:

        move.l  (a1)+,(a2)+      ;read source destination 1 bitplane at
        add.l   #no_of_bytes,a1          ;move plane pointer down one scan line
        dbra    d0,doagain	; get all the data block for one bitplane
	dbra	d4,getall	        ; get all the bitplanes
	movem.l (sp)+,d0-d7/a0-a6

	rts


*****************************************************************
*		Place Data back on screen			*
*****************************************************************

PlaceBob:
	
	movem.l d0-d7/a0-a6,-(sp)
 
Read_Blocks2:
 	
	move.l  temp2,a2
	move.l	plane_no,d4
	lea 	bitplane1(pc),a3

getall2:

        move.l  (a3)+,a1
	add.l	offset,a1
	move.l	#y_size,d0		; how many lines high

placeman2:
        move.l  (a2)+,(a1)+     	 ;place man data on the screen
	add.l   #no_of_bytes,a1          ;move plane pointer down one scan line
       	dbra    d0,placeman2

kickout2:        

	dbra	d4,getall2

	movem.l (sp)+,d0-d7/a0-a6
	rts


*****************************************************************
*                    Delay                                      *
*****************************************************************

heywait:
		movem.l d0-d7/a0-a6,-(sp)
		move.l	#8,d1			; Set # to Wait time
		move.l	dosbase,a6
		jsr	delay(a6)
		movem.l (sp)+,d0-d7/a0-a6
		rts

write_block:

	move.l	$4,a6
	lea	dosname(pc),a1
	moveq	#0,d0
	jsr	openlib(a6)
	move.l	d0,dosbase

	move.l	d0,a6
	lea	dest_file(pc),a1
	move.l	a1,d1
	move.l	#mode_old2,d2
	jsr	open(a6)	
	move.l	d0,filehandle2
	rts

Write:
		
	move.l	filehandle2,d0

	move.l	temp2,d2
	move.l	#500,d3
	move.l	d0,d1
	move.l	dosbase,a6
	jsr	write(a6)
	rts


Close:	

	move.l	filehandle2,d1
	move.l	dosbase,a6
	jsr	close(a6)

	rts

       


; This is screen 1 it is 10 x 10


table:		dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		
		dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		
		dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00		
		dc.b	$00,$00,$00,$01,$01,$01,$01,$00,$00,$00		
		dc.b	$00,$00,$00,$01,$00,$00,$00,$00,$00,$00		
		dc.b	$00,$00,$00,$01,$00,$00,$00,$00,$00,$00		
		dc.b	$00,$00,$00,$01,$01,$00,$00,$00,$00,$00		
		dc.b	$00,$00,$00,$01,$00,$00,$00,$00,$00,$00		
		dc.b	$00,$00,$00,$01,$00,$00,$00,$00,$00,$00		
		dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02		
		
		; 1 = block offcopy 
		; 0 = block on
		; 2 = end of screen

		cnop	0,2


	Screen_Defs	320,200,5,Y,<framco was here>
	Window		320,200,Y
	Setup_Intuition_Data
	Setup_Dos_Data
	Setup_Graphics_Data

	cnop	0,2

viewport:	dc.l	0
temp:		ds.l	100
temp2:		dc.l	0
	cnop	0,2

on_off:		dc.l	0
filehandle2:	dc.l	0
accros:		dc.l	0
down:		dc.l	0
sizeofsave:	dc.l	0
plane_no:	dc.l	0
block:		dc.l	0
iff_screen	dc.l	0
counter:	dc.l	0
fileoffset:	dc.l	0
skip:		dc.l	0
count:		dc.l	0
temp3:		dc.l	0
offset:		dc.l	0
block_no:	dc.l	0
blocknumber	dc.l	0
	cnop	0,2
blockname:	dc.b	'block.map',0
		cnop 0,2
filename:	dc.b	'grass',0
		cnop 0,2
dest_file:	dc.b	'block.map',0
		cnop 0,2



       end


