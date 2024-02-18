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

	move.l	$c0000,d1
	move.l	#'Sean',$c0000
	cmp.l	#'Sean',$40000
	bne.s	isonemeg

	lea	msg512(pc),a2
	move.l	a2,d2
	move.l	#msginst-msg512,d3
	bra	error512

isonemeg:

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
	
	cmp.l	#$4f4646,d1		;OFF - Turn off 512k Chip system
	bne.s	chkExtmem

	lea	turnoff(pc),a2
	move.l	a2,d2
	move.l	#msg512-turnoff,d3

        move.l	$4,a6
	move.l	#$100000,62(a6)
	move.l	$9fffc,42(a6)
	bra	error512

chkExtmem:
	lsr.l	#8,d1

	cmp.w	#$0f46,d1		; /F - for 512k chip & 512 Fast
	bne.s	chktemplate

	lea	msgext(pc),a2
	move.l	a2,d2
	move.l	#template-msgext,d3

	move.l	#$80276,execarea+2
	move.l	#$100000,fastram+2
	bra.s	setuparea2

chktemplate:
	lsr.l	#8,d1

	cmp.b	#$1f,d1			; ? - Print the Template
	bne.s	setuparea

	lea	template(pc),a2
	move.l	a2,d2
	move.l	#turnoff-template,d3
	bra	error512

setuparea:
	lea	msginst(pc),a2
	move.l	a2,d2
	move.l	#dosname-msginst,d3


setuparea2:
	move.w	#endreset-startreset,d0
	lea	startreset(pc),a0
	move.l	#$a0000,a1

copyreset:
	move.b	(a0)+,(a1)+
	dbra	d0,copyreset

	move.l	$4,a6
	move.l	42(a6),$9fffc
	move.l	#$0a0000,42(a6)
	move.l	#$80000,62(a6)

;	move.l	#$0a0000,a0
;	add.l	#coolvector-startreset,a0
;	move.l	#$a0082,46(a6)

	move.l	a6,a0
	add.l	#34,a0
	move.w	#$16,d0
	moveq	#0,d1

chksum:
	add.w	(a0)+,d1
	dbf	d0,chksum

	not.w	d1
	move.w	d1,82(a6)

error512:
	move.l	dosbase,a6
	move.l	outhandle,d1
	jsr	write(a6)

endpgm:
	rts

msgext:
	dc.b	$1b,'[3m',$1b,'[33mChip ',$1b,'[m- By Sean Godsell',13,10,10
	dc.b	'          In order to make your system think it has 512k of Chip',13,10
	dc.b	'          ram plus 512k Fast Ram.  Then you MUST REBOOT you machine.',13,10
        dc.b    '          Press <CRTL> <AMIGA> <AMIGA>',13,10,10,0
	cnop	0,2
template:
	dc.b	'ON/OFF/F :',13,10
	cnop	0,2
turnoff:
	dc.b	$1b,'[3m',$1b,'[33mChip ',$1b,'[m- By Sean Godsell',13,10,10
	dc.b	'          In order to make your system think it has 1MB of Chip ram',13,10
	dc.b	'          again.  You MUST REBOOT your machine.',13,10
        dc.b    '          Press <CRTL> <AMIGA> <AMIGA>',13,10,10,0
	cnop	0,2
msg512:
	dc.b	$1b,'[3m',$1b,'[33mChip ',$1b,'[m- By Sean Godsell',13,10,10
	dc.b	'You Do Not have 1MB of Chip Ram in the first place.',13,10,0
	cnop	0,2
msginst:
	dc.b	$1b,'[3m',$1b,'[33mChip ',$1b,'[m- By Sean Godsell',13,10
	dc.b	'          In order to make your system think it has 512k of Chip',13,10
	dc.b	'          ram, you MUST REBOOT your machine.',13,10
        dc.b    '          Press <CRTL> <AMIGA> <AMIGA>',13,10,10,0
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

	move.b	#$3,$bfe201
	move.b	#$2,$bfe001

	lea	$dff000,a4
	move.w	#$7fff,d0
	move.w	d0,154(a4)
	move.w	d0,156(a4)
	move.w	d0,150(a4)
	move.w	#$0200,256(a4)
	move.w	#$0000,272(a4)
	move.w	#$0444,384(a4)

	lea	$c00000,a0
	lea	$dc0000,a1

	move.l	#$8c2,$7b8

execarea:
	move.l	#$676,a6
fastram:
	move.l	#$000000,a4

	move.l	a4,d0
	move.l	#$40000,a7
	move.l	#$ffffffff,d6

	move.l	#$80000,a3

	move.l	$7b8,$60000

	move.l	#$0,$7b8


	move.l	#$000000,$0
	move.l	a3,d0
	lea	$00c0,a0


	lea	continuea(pc),a5
	jmp	$fc0602			;clear	low memory
continuea:

	movem.l	a0,-(sp)
	lea	coolvector(pc),a0
	move.l	a0,$6a8			;coolvector
	movem.l	(sp)+,a0

	move.l	#$fc0240,a5

	jmp	$fc0240


coolvector:
	move.w	#$1,$20000e
	move.w	#$1,$40000e
	move.l	#'Momy',$60008
	move.l	$7b8,$60004
	move.l	#$8c2,$7b8
	rts


endreset:
