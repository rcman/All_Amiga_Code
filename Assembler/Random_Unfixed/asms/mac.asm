	include "include/franco.i"


	OpenIntuition
	IFERR	ErrorIntuition
	OpenScreen
	IFERR   ErrorScreen
	OpenWindow
	IFERR	ErrorWindow

	move.l	screenhd,a0
	move.l	$c0(a0),bitplane1
	move.l	$c4(a0),bitplane2


	move.l	#$ff,d5
	move.l	#10,d0
	move.l	#10,d1
	move.l	#100,d2
	move.l	#100,d3

writelines:
	move.l	#40,d4
	move.l	bitplane1,a0

	DrawLine

	addq	#1,d0
	cmp.w	#319,d0
	bne.s	gohere

	moveq	#0,d0
gohere:
	dbra	d5,writelines


	WaitButton	0


	move.l	bitplane1,a0
	move.w	#7999,d0
	move.w	#7,d1

rotatescreen:
	move.b	0(a0,d0.w),d4
	lsr.b	#1,d4
	move.b	d4,0(a0,d0.w)
	dbra	d0,rotatescreen

;	move.w	#$1,d4		;time delay
;waittime:
;	nop
;	dbra	d4,waittime

	move.w	#7999,d0
	dbra	d1,rotatescreen

	WaitButton	1


	CloseWindow
ErrorWindow:
	CloseScreen
ErrorScreen:
	CloseIntuition
ErrorIntuition:
	rts


	Screen_Defs	320,200,4,Y,<framco was here>
	Window		320,200,Y
	Setup_Intuition_Data


