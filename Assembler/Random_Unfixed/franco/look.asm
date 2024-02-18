
	move.l	#$60000,a1
	move.l	#0,a0
doit:
	cmp.w	#$100,(a0)
	bne.s	gohere

	move.l	a0,(a1)+

gohere:
	addq.l	#2,a0
	cmp.l	#$100000,a0
	bne.s	doit

	rts





