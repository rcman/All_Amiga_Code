	include "include/franco.i"
;	include	'include:exec/funcdef.i'
;	include	'include:libraries/dos_lib.i'
;	include	'include:exec/exec_lib.i'
;	include	'include:hardware/custom.i'

		XREF ObjClip
		XREF FlipX
		XREF ObjInit
		XREF ObjInq
		XREF ObjSet
		XREF ObjLoadV
		XREF Sprite
		XREF ObjLoad


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

	AllocMem 200000,Chip
	move.l	d0,iff_screen
	add.l	#140000,d0
	move.l	d0,screen_data
	bsr	unpack

	move.l	windowhd,a0
	move.l	intbase,a6
	jsr	viewportaddress(a6)
	move.l	a0,viewport

       move.l  #0,d0           ;pen
       move.l  #$0,d1           ;red
       move.l  #$0,d2           ;green
       move.l  #$0,d3           ;blue
       move.l  viewport,a0     ;Get Pointer to View Port
       move.l  gfxbase,a6      ;get grapics base
       jsr     setrgb4(a6)     ;set a color registor

       move.l  #2,d0           ;pen
       move.l  #$d,d1           ;red
       move.l  #$d,d2           ;green
       move.l  #$d,d3           ;blue		;face
       move.l  viewport,a0     ;Get Pointer to View Port
       move.l  gfxbase,a6      ;get grapics base
       jsr     setrgb4(a6)     ;set a color registor

       move.l  #1,d0           ;pen
       move.l  #$f,d1           ;red
       move.l  #$f,d2           ;green
       move.l  #$f,d3           ;blue
       move.l  viewport,a0     ;Get Pointer to View Port
       move.l  gfxbase,a6      ;get grapics base
       jsr     setrgb4(a6)     ;set a color registor


       move.l  #7,d0           ;pen
       move.l  #$9,d1           ;red
       move.l  #$9,d2           ;green
       move.l  #$9,d3           ;blue
       move.l  viewport,a0     ;Get Pointer to View Port
       move.l  gfxbase,a6      ;get grapics base
       jsr     setrgb4(a6)     ;set a color registor


	move.l	screenhd,a0
	move.l	$c0(a0),bitplane1
	move.l	$c4(a0),bitplane2
	move.l	$c8(a0),bitplane3
	move.l	$cc(a0),bitplane4
	move.l	$d0(a0),bitplane5

GameInit:
	move.l	dosbase,d0
	move.l	gfxbase,d1
	move.l	#5,d7
	jsr	ObjInit

	move.l	bitplane1,a1
	move.l	bitplane2,a2
	move.l	bitplane3,a3
	move.l	bitplane4,a4
	move.l	bitplane5,a5
	jsr	ObjSet


	
	lea	filename(pc),a0
	bsr	ObjInq

	lea	filename(pc),a0
	move.l	iff_screen,a1
	bsr	ObjLoad

	nop
	nop
	nop
	nop
	move.l	iff_screen,a0
	move.l	#1,d0
	move.l	#35,d1
	move.l	#35,d2
	bsr	Sprite

;	move.l	#2,d0		; Lower X Clip (words)
;	move.l	#23,d1		; Lower Y Clip (pixels)
;	move.l	#2,d2		; High X Clip (words)
;	move.l	#40,d3		; High Y Clip (word)
;	bsr	ObjClip
	
	WaitButton 1

;	move.l	#5,d0
;	move.l	#23,d1
;	move.l	#5,d2
;	move.l	#23,d3
;	bsr	ObjClip

;	move.l	#0,obj
;	move.l	#20,val
hr:
	move.l	iff_screen,a0
	move.l	#0,d0
	move.l	#80,d1
	move.l	#60,d2
	bsr	Sprite
;	bsr	heywait
;	add.l	#10,val
;	add.l	#1,obj
;	cmp.l	#200,val
;	blt.s	hr
	
	WaitButton 0

	bra	Finished	
	
********************************************************************
* 			Wait (time delay)			   *
********************************************************************


heywait:
		movem.l d0-d7/a0-a6,-(sp)
		move.l	#1,d1			; Set # to Wait time
		move.l	dosbase,a6
		jsr	delay(a6)
		movem.l (sp)+,d0-d7/a0-a6
		rts


**************************************************************
unpack:

	Open	filename2,o
	Read	100000,screen_data
	Close

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

	move.l	screen_data,a0
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

	rts



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
	






Finished:
	FreeMem 200000,iff_screen

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


	Screen_Defs	320,200,5,Y,<framco was here>
	Window		320,200,Y
	Setup_Intuition_Data
	Setup_Dos_Data
	Setup_Graphics_Data

viewport:	dc.l	0
val:		dc.l	0
temp:		dc.b	0
obj:		dc.b	0
		cnop 0,2

iff_screen:	dc.l	0
screen_data:	dc.l	0

		cnop 0,2
title:		dc.b	'0000000'
titleend:
		cnop 0,2
filename:	dc.b	'dh0:obj/clowds.cel',0
		cnop 0,2
filename2:	dc.b	'dh0:assem/blue_back',0
		cnop 0,2


