Output		equ	-60
write		equ	-48
Openlib		equ	-408

	move.l	a0,a1
	move.l	a1,parms
	move.l	d0,d1
makeupper:
	move.b	(a1),d2
	cmp.b	#$d,d2
	beq.s	allupper
	and.b	#$df,d2
	move.b	d2,(a1)+
	dbra	d1,makeupper
allupper:

	move.l	$4,a6
	lea	dosname(pc),a1
	jsr	Openlib(a6)
	move.l	d0,dosbase
	beq	endpgm

	move.l	d0,a6
	jsr	Output(a6)
	move.l	d0,outhandle

	move.l	parms,a0

	move.b	(a0)+,d1
	lsl.l	#8,d1
	move.b	(a0)+,d1
	lsl.l	#8,d1
	move.b	(a0)+,d1
	lsl.l	#8,d1
	move.b	(a0)+,d1
	move.l	d1,d2
	lsr.l	#8,d1
	
	cmp.l	#$4f4646,d1
	bne.s	chktemplate

	lea	turnoff(pc),a2
	move.l	a2,d2
	move.l	#msg512-turnoff,d3

	move.l	#$100000,$6b4
	move.l	$9fffc,$6a0
	bra	error512

chktemplate:
	swap	d1
	cmp.b	#$1f,d1
	bne.s	chkifonemeg

	lea	template(pc),a2
	move.l	a2,d2
	move.l	#turnoff-template,d3
	bra	error512
chkifonemeg:


	move.l	$c0000,d1
	move.l	#'Sean',$c0000
	cmp.l	#'Sean',$40000
	bne.s	isonemeg

	lea	msg512(pc),a2
	move.l	a2,d2
	move.l	#msginst-msg512,d3
	bra	error512

isonemeg:

	move.w	#endreset-startreset,d0
	lea	startreset(pc),a0
	move.l	#$a0000,a1

copyreset:
	move.b	(a0)+,(a1)+
	dbra	d0,copyreset

	move.l	$6a0,$9fffc
	move.l	#$0a0000,$6a0
	move.l	#$80000,$6b4
;	move.l	#$100000,$6c4

	move.l	#$698,a0
	move.w	#$16,d0
	moveq	#0,d1

chksum:
	add.w	(a0)+,d1
	dbf	d0,chksum
	not.w	d1
	move.w	d1,$6c8


	move.l	outhandle,d1
	lea	msginst(pc),a2
	move.l	a2,d2
	move.l	#dosname-msginst,d3
	move.l	dosbase,a6
	jsr	write(a6)

	bra	endpgm

error512:
	move.l	dosbase,a6
	move.l	outhandle,d1
	jsr	write(a6)

endpgm:
	rts

template:
	dc.b	'ON/OFF/F :',13,10
	cnop	0,2
turnoff:
	dc.b	$1b,'[3m',$1b,'[33mChip512 ',$1b,'[m- By Sean Godsell',13,10,10
	dc.b	'          In order to make your 512k system think it has 1MB of ram',13,10
	dc.b	'          again.  You MUST REBOOT your machine <CRTL> <AMIGA> <AMIGA>',13,10,10,0
	cnop	0,2
msg512:
	dc.b	$1b,'[3m',$1b,'[33mChip512 ',$1b,'[m- By Sean Godsell',13,10,10
	dc.b	'You Do Not have 1MB of Chip Ram in the first place',13,10,0
	cnop	0,2
msginst:
	dc.b	$1b,'[3m',$1b,'[33mChip512 ',$1b,'[m- By Sean Godsell',13,10
	dc.b	'          In order to make your 1MB system think it has 512k',13,10
	dc.b	'          of ram you MUST REBOOT your machine <CRTL> <AMIGA> <AMIGA>',13,10,10,0
	cnop	0,4

dosname:
	dc.b	'dos.library',0
	cnop	0,4
dosbase:
	dc.l	0
outhandle:
	dc.l	0
parms:
	dc.l	0

startreset:

;	move.l	#$100000,$6c4

	move.b	#$3,$bfe201
	move.b	#$2,$bfe001

	move.w	#$0008,$6b4

	lea	$dff000,a4
	move.w	#$7fff,d0
	move.w	d0,154(a4)
	move.w	d0,156(a4)
	move.w	d0,150(a4)
	move.w	#$0200,256(a4)
	move.w	#$0000,272(a4)
	move.w	#$0444,384(a4)

	lea	$400,a6
	suba.w	#$fd8a,a6
	lea	$c00000,a0
	lea	$dc0000,a1
	move.l	#$0,a4
;	move.l	#$100000,a4
	move.l	a4,d0
	move.l	#$40000,a7
	move.l	#$ffffffff,d6

	move.l	#$80000,a3

;	jmp	$fc0208
	jmp	$fc021a

endreset:
