
	include 'include:exec/types.i'
	include	'include:hardware/custom.i'
	include 'include:hardware/blit.i'
	include 'include:hardware/dmabits.i'
;	include 'include:hardware/hw_examples.i'


start:
	moveq.l	#DMAB_BLTDONE-8,d2
	nop
	rts


	end

