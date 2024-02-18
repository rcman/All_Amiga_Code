
supervisor	equ	-30
sysbase		equ	4
superstate	equ	-150
userstate	equ	-156
write		equ	-48
read		equ	-42
output		equ	-60
openlib		equ	-408
closelib	equ	-414

lookatinp:
	movem.l	d0-d7/a0-a6,-(sp)

	move.l	a0,parmp
	move.l	d0,parml
	moveq	#0,d2

gethexnum:
	move.b	(a0)+,d1
	cmp.b	#$d,d1
	beq.s	theend
	cmp.b	#$a,d1
	beq.s	theend
	cmp.b	#' ',d1
	beq.s	theend

	cmp.b	#'a',d1
	blt.s	trybig
	sub.b	#$20,d1
trybig:

	cmp.b	#'9',d1
	ble.s	trynum

	sub.b	#$7,d1
trynum:
	sub.b	#'0',d1

	or.b	d1,d2
	rol.l	#4,d2

	dbra	d0,gethexnum
theend:

	ror.l	#4,d2
	move.l	d2,addnum

	move.l	sysbase,a6
	lea	dosname(pc),a1
	jsr	openlib(a6)
	move.l	d0,dosbase
	beq	error

	move.l	d0,a6
	jsr	output(a6)
	move.l	d0,outhandle
	beq	error2


	move.l	addnum,d0
	bsr	printhexnum
	bsr	printcrlf

	move.l	sysbase,a6
	jsr	superstate(a6)
	move.l	d0,savesp



	lea	Wipecopp(pc),a0
	move.l	$2c,savepriv

	move.l	a0,$2c

;returnto:


;*************************************
gohere:
	move.w	sr,savesr

	or.w	#$0700,sr

	bra	turnoffmmu

gochangemmu:

	move.l	#$4c0000,a0
	move.w	#$ffff,d0
	move.l	#$1,d1

loopmmu:
	move.l	d1,(a0)
;	move.w	#$1,2(a0)

	add.l	#4,a0
	add.l	addnum,d1

	dbra	d0,loopmmu	

startmmu:
	lea	savemmu1(pc),a0

	dc.w	%1111000000010000	;PMOVE	CRP,(A0)+
	dc.w	%0100110000000000

	lea	savemmu2(pc),a0

	or.b	#$80,(a0)

	dc.w	%1111000000010000	;PMOVE	TC,(A0)+
	dc.w	%0100000000000000
	bra.s	endmmu

turnoffmmu:
	lea	savemmu2(pc),a0

	and.b	#$7f,(a0)

	dc.w	%1111000000010000	;PMOVE	TC,(A0)+
	dc.w	%0100000000000000


	bra	gochangemmu

endmmu:
	nop
	nop
	nop
	nop

	move.l	savepriv,$2c
	move.l	#'Tend',$47fff8

	move.w	savesr,sr

	move.l	savesp,d0
	move.l	sysbase,a6
	jsr	userstate(a6)


	lea	startmmu(pc),a0
	cmp.w	#$4e71,(a0)
	bne.s	setallback

	lea	prtnommu(pc),a1
	move.l	#eprtnommu-prtnommu,d3
	bsr	printmessage

setallback:

error2:
	move.l	sysbase,a6
	move.l	dosbase,a1
	jsr	closelib(a6)
error:
	movem.l	(sp)+,d0-d7/a0-a6
	rts


;*************************************
Wipecopp:

	lea	startmmu(pc),a0
	move.l	#endmmu-startmmu,d0
	lsr	#1,d0
wipeit:
	move.w	#$4e71,(a0)+
	dbra	d0,wipeit
	rte

printmessage:
	movem.l	d0-d7/a0-a6,-(sp)

	move.l	a1,d2			;text pointer
	move.l	outhandle,d1		;output handle
	move.l	dosbase,a6
	jsr	write(a6)

	movem.l	(sp)+,d0-d7/a0-a6
	rts

printnumber:
	movem.l	d0-d7/a0-a6,-(sp)
	lea	values(pc),a0
	moveq	#4,d1
	moveq	#1,d2
doit:
	divu.w	(a0),d0
	cmp.b	#0,d2
	beq.s	zeros
	cmp.b	#0,d0
	beq.s	nozeros
zeros:
	moveq	#0,d2
	move.b	d0,prtbyte
	add.b	#$30,prtbyte
	lea	prtbyte(pc),a1
	moveq	#1,d3
	bsr	printmessage
nozeros:
	move.w	#0,d0
	swap	d0
	add.l	#2,a0
	dbra	d1,doit

gotoprtzero:
	cmp.b	#0,d2
	beq.s	dontprtlz
	move.b	#$30,prtbyte
	lea	prtbyte(pc),a1
	moveq	#1,d3
	bsr	printmessage
dontprtlz:

	movem.l	(sp)+,d0-d7/a0-a6
	rts

printhexnum:
	movem.l	d0-d7/a0-a6,-(sp)
	moveq	#7,d1
	moveq	#1,d2
	move.l	d0,d5
doit2:
	move.l	d5,d0
	rol.l	#4,d0
	move.l	d0,d5
	and.l	#$f,d0
	cmp.b	#0,d2
	beq.s	zeros2
	cmp.b	#0,d0
	beq.s	nozeros2
zeros2:
	moveq	#0,d2
	cmp.b	#$a,d0
	blt.s	noletter
	add.b	#7,d0
noletter:
	move.b	d0,prtbyte
	add.b	#$30,prtbyte
	lea	prtbyte(pc),a1
	moveq	#1,d3
	bsr	printmessage
nozeros2:
	dbra	d1,doit2

	bra	gotoprtzero

printcrlf:
	movem.l	d0-d7/a0-a6,-(sp)
	lea	crlf(pc),a1
	moveq	#2,d3
	bsr	printmessage
	movem.l	(sp)+,d0-d7/a0-a6
	rts


values:
	dc.w	10000
	dc.w	1000
	dc.w	100
	dc.w	10
	dc.w	1

savesp:
	dc.l	0
dosname:
	dc.b	'dos.library',0
	cnop	0,2
prtnommu:
	dc.b	10,13,'There is No MMU!',10,10,13
	cnop	0,2
eprtnommu:

prtbyte:
	dc.b	0,0

crlf:
	dc.b	10,13
	cnop	0,2

parmp:	dc.l	0
parml:	dc.l	0
addnum:	dc.l	0

savesr:	
	dc.w	0,0
	
dosbase:
	dc.l	0,0
outhandle:
	dc.l	0,0
savepriv:
	dc.l	0,0

savemmu1:
	dc.w	$7fff,$0202,$004c,$0000,0,0,0,0
savemmu2:
	dc.b	$80,$a8,$e0,0,0,0,0,0,0
savemmu3:
	dc.l	0,0,0,0,0,0,0,0

	dc.w	$80a8,$7700,0,0,0,0,0
