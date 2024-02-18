	AllocMem	equ	-198
	FindTask	equ	-294


	move.l	#512,d0		;512 bytes
	move.l	#$10001,d1	;public & clear
	move.l	$4,a6
	jsr	AllocMem(a6)
	move.l	d0,Port

	move.l	#0,a1
	move.l	$4,a6
	jsr	FindTask(a6)	;Find Current task

	move.l	Port,a2
	move.l	d0,16(a2)
	move.b	#4,8(a2)

	move.l	a2,a3
	add.l	#490,a3
	move.l	#'Sean',(a3)
	move.l	a3,10(a2)

Port:
	dc.l	0
	dc.l	0

