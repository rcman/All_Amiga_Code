checkcollision:

	movem.l	d0-d6/a0-a6,-(sp)
	move.w	clxdat,a5
	tst.b	9(a5)
	bne	okayfornow
	movem.l	(sp)+,d0-d6/a0-a6
	move.l	#0,shtg
	move.l	sprite2loc,a5
	move.b	#0,1(a5)
	move.l	#1,setflghit
        nop
	rts


