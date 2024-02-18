
	move.l	#$dff000,a6		a6 ALWAYS point to base of
	move.l	#-1,bltafwm(a6)		custom chips
	bsr	GameInit
	move.l	#clist,cop1lc(a6)
	move.w	#$87e0,dmacon(a6)	enable copper,sprite,blitter
	move.w	#$7fff,intreq(a6)	clear all int request flags
	move.w	#$0c30,clxcon(a6)



TakeSystem
	move.w	intenar(a6),SystemInts		save system interupts
	move.w	dmaconr(a6),SystemDMA		and DMA settings
	move.w	#$7fff,intena(a6)		kill everything!
	move.w	#$7fff,dmacon(a6)
	move.b	#%01111111,ICRA			kill keyboard
	move.l	$68,Level2Vector		save these interrupt vectors
	move.l	$6c,Level3Vector		as we will use our own 
	rts					keyboard & vblank routines


FreeSystem
	move.l	Level2Vector,$68	restore the system vectors
	move.l	Level3Vector,$6c		and interrupts and DMA
	move.l	GraphicsBase,a1			and replace the system
	move.l	SystemCopper1(a1),Hardware+cop1lc	copper list
	move.l	SystemCopper2(a1),Hardware+cop2lc
	move.w	SystemInts,d0
	or.w	#$c000,d0
	move.w	d0,intena(a6)
	move.w	SystemDMA,d0
	or.w	#$8100,d0
	move.w	d0,dmacon(a6)
	move.b	#%10011011,ICRA	keyboard etc back on
	rts
