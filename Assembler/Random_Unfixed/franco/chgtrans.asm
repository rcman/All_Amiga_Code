
Open		equ	-30
Close		equ	-36
Read		equ	-42
Write		equ	-48
AllocMem	equ	-198
FreeMem		equ	-210
Openlib		equ	-408
Closelib	equ	-414
mode_old	equ	1005
mode_new	equ	1006
sysbase		equ	$4

	lea	dosname(pc),a1
	move.l	sysbase,a6
	jsr	Openlib(a6)
	move.l	d0,dosbase
	beq	error

	move.l	#100000,d0
	move.l	#$10001,d1
	jsr	AllocMem(a6)
	move.l	d0,memarea
	beq	error2

	move.l	d0,memsr
	add.l	#4000,d0
	move.l	d0,memprog

	lea	filename(pc),a1
	move.l	a1,d1
	move.l	#mode_old,d2
	move.l	dosbase,a6
	jsr	Open(a6)
	move.l	d0,filehandle
	beq	error3

	move.l	d0,d1
	move.l	memprog,d2
	move.l	#84000,d3
	move.l	dosbase,a6
	jsr	Read(a6)

	move.l	memprog,a0
	move.l	memsr,a1
	move.l	#42000,d0
	moveq	#0,d3

lookforsr:
	move.w	(a0),d1
	and.w	#$ffc0,d1
	cmp.w	#$40c0,d1
	bne.s	nomovesr

	move.l	a0,(a1)+

	addq	#1,d3
	cmp.w	#37,d3
	blt.s	chgsrtccr
	cmp.w	#39,d3
	ble.s	nomovesr

chgsrtccr:
	move.w	(a0),d1
	or.w	#$200,d1
	move.w	d1,(a0)

nomovesr:
	addq	#2,a0
	dbra	d0,lookforsr

**** save the program ***
	lea	filesave(pc),a1
	move.l	a1,d1
	move.l	#mode_new,d2
	move.l	dosbase,a6
	jsr	Open(a6)
	move.l	d0,filehandsav
	beq	endprg

	move.l	d0,d1
	move.l	memprog,d2
	move.l	#82393,d3
	move.l	dosbase,a6
	jsr	Write(a6)

	move.l	filehandsav,d1
	move.l	dosbase,a6
	jsr	Close(a6)


endprg:
	move.l	filehandle,d1
	move.l	dosbase,a6
	jsr	Close(a6)
error3:
	move.l	memarea,a1
	move.l	#100000,d0
	move.l	sysbase,a6
	jsr	FreeMem(a6)
error2:
	move.l	sysbase,a6
	move.l	dosbase,a1
	jsr	Closelib(a6)
error:
	clr.l	d0
	rts

memarea:	dc.l	0
memprog:	dc.l	0
memsr:		dc.l	0
filehandle	dc.l	0
filehandsav	dc.l	0
dosbase:	dc.l	0
dosname:	dc.b	'dos.library',0
		cnop	0,4
filesave:	dc.b	'at1s',0
		cnop	0,4
filename:	dc.b	'at1',0
		cnop	0,4

