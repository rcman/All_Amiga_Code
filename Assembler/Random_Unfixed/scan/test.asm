

	move.w	#$56,d0
	rol.w	#8,d0
	nop



	move.l	$74,a0
	lea	inter(pc),a1
here:
	move.l	a1,$74
	bra.s	here

inter:
	move.l	a0,$68000
	move.l	a1,$68004
	move.l	a2,$68008
	move.l	a3,$6800c
	move.l	a4,$68010
	move.l	a5,$68014
	move.l	a6,$68018
	move.l	a7,$6801c

	move.l	d0,$68020
	move.l	d1,$68024
	move.l	d2,$68028
	move.l	d3,$6802c
	move.l	d4,$68030
	move.l	d5,$68034
	move.l	d6,$68038
	move.l	d7,$6803c

always:
	nop
	bra.s	always


