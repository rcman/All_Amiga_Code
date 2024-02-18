

	lea	sinedata,a0

	move.w	#$1,$dff096

	move.l	a0,$dff0a0
	move.w	#4,$dff0a4

	move.w	#64,$dff0a8
	move.w	#447,$dff0a6

	move.w	#$1,$dff096

	rts


sinedata:
	dc.b	0,90,0,127,90,0,-90,-127,-90

