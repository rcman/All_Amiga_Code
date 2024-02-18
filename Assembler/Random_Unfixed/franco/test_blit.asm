  include "include/franco.i"

	movem.l	d0-d6/a0-a2,-(sp)

	move.l	#$a0000,a0
	move.w	#$200,d0
cleararea:
	move.b	#0,(a0)+
	dbra	d0,cleararea


	move.l	#$dff000,a1

 
	btst.b	#6,dmaconr(a1)		;DMAB_BLTDONE-8,dmaconr(a1)
waitblit:
	btst.b	#6,dmaconr(a1)		;DMAB_BLTDONE-8,dmaconr(a1)
	bne.s	waitblit

	
lineover:
	move.w	#$09f0,bltcon0(a1)	;Set to LF and registers to use
	move.w	#0,bltcon1(a1)		;Set to 0 for area mode

	move.w	#8,bltamod(a1)		;modulus for A Source
	move.w	#0,bltdmod(a1)		;modulus for D destination

	move.w	#$ffff,bltafwm(a1)	;Mask for source (first word A)
	move.w	#$ffff,bltalwm(a1)	;Mask for source (last word A)

	move.l	#6,bltapth(a1)		;source A pointer
	move.l	#$a0000,bltdpth(a1)	;destination pointer

	move.w	#$0802,bltsize(a1)	;height and width


	movem.l	(sp)+,d0-d6/a0-a2

	rts


