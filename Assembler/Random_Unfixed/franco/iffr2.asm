	include "include/franco.i"


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

	lea	iffname(pc),a1
	move.l	$4,a6
	jsr	-408(a6)		;open iff library
	move.l	d0,IFFBase

	lea	filename(pc),a0
	move.l	IFFBase,a6
	jsr	-30(a6)			;open iff file
	move.l	d0,ifffile

	move.l	ifffile,a1
	move.l	screenhd,a0
	add.l	#$b8,a0
	move.l	IFFBase,a6
	nop
	nop
	jsr	-60(a6)			;decode picture

	move.l	ifffile,a1
	move.l	IFFBase,a6
	jsr	-36(a6)			;close iff file

	move.l	IFFBase,a1
	move.l	$4,a6
	jsr	-414(a6)		;close iff library

	WaitButton	0

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

yflag:		dc.w	0
factx:		dc.w	$4
shipx:		dc.w	150	
viewport:	dc.l	0

shotx:		ds.w	100
shoty:		ds.w	100
hitval:		ds.w	100


iff_screen:	dc.l	0
IFFBase:	dc.l	0
ifffile:	dc.l	0

		cnop 0,2
title:		dc.b	'0000000'
titleend:
		cnop 0,2
filename:	dc.b	'dh0:explode.iff',0
		cnop 0,2

ifflib:		dc.l	0

iffname:		dc.b	'iff.library',0
		cnop 0,2

