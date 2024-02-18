   include 'include/franco.i'
   include 'include/iff.i'

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

	AllocMem 100000,Chip
	move.l	d0,iff_screen
	Open	filename,o
	Read	100000,iff_screen
	Close

	jsr 	UnPack_Screen

	WaitButton 1



;----- unpack screen -------------------------
UnPack_Screen:

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

	move.l	#40,iff_mod
	UnPack_IFF 	iff_screen,40,199,bitplane1
	rts




	FreeMem 100000,iff_screen

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

temp:		dc.b	0
		cnop 0,2

iff_screen:	dc.l	0

		cnop 0,2
title:		dc.b	'0000000'
titleend:
		cnop 0,2
enemy:
		dc.b	0,0
		dc.b	0,0
		dc.b	%00111100,%00111100
		dc.b	%01000010,%01000010
		dc.b	%10001001,%10010001
		dc.b	%10010000,%00001001
		dc.b	%10000000,%00000001
		dc.b	%01000100,%00100010
		dc.b	%00100000,%00000100
		dc.b	%00011101,%10111000
		dc.b	%00010010,%01001000
		dc.b	%00100010,%01000100
		dc.b	0,0
		dc.b	0,0

filename:	dc.b	'box_anim.br',0
		cnop 0,2

