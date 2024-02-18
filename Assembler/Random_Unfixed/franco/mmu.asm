
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

	move.l	sysbase,a6
	lea	dosname(pc),a1
	jsr	openlib(a6)
	move.l	d0,dosbase
	beq	error

	move.l	d0,a6
	jsr	output(a6)
	move.l	d0,outhandle
	beq	error2


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

	lea	savemmu1(pc),a0

startmmu:
	dc.w	%1111000000010000	;PMOVE	PSR,(A0)+
	dc.w	%0110001000000000

	lea	savemmu2(pc),a0

	dc.w	%1111000000010000	;PMOVE	TC,(A0)+
	dc.w	%0100001000000000

	lea	savemmu3(pc),a0

	dc.w	%1111000000010000	;PMOVE	SRP,(A0)+
	dc.w	%0100101000000000

	lea	savemmu4(pc),a0

	dc.w	%1111000000010000	;PMOVE	CRP,(A0)+
	dc.w	%0100111000000000

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
	beq.s	nommu

	lea	logo(pc),a1
	move.l	#elogo-logo,d3
	bsr	printmessage

	bsr	displaymmu

	bra.s	setallback
nommu:
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

displaymmu:
	move.l	savemmu2,d0
	btst.l	#31,d0
	bne.s	prtenable

	lea	disabled(pc),a1
	move.l	#edisabled-disabled,d3
	bsr	printmessage
	bra.s	chksre
prtenable:
	lea	enabled(pc),a1
	move.l	#eenabled-enabled,d3
	bsr	printmessage

chksre:
	btst.l	#25,d0
	bne.s	prtsre

	lea	srdisabled(pc),a1
	move.l	#esrdisabled-srdisabled,d3
	bsr	printmessage
	bra.s	chkfcl
prtsre:
	lea	srenabled(pc),a1
	move.l	#esrenabled-srenabled,d3
	bsr	printmessage

chkfcl:
	btst.l	#24,d0
	bne.s	prtfcl

	lea	fcdisabled(pc),a1
	move.l	#efcdisabled-fcdisabled,d3
	bsr	printmessage
	bra.s	chkpage
prtfcl:
	lea	fcenabled(pc),a1
	move.l	#efcenabled-fcenabled,d3
	bsr	printmessage

chkpage:
	lea	Pagelogo(pc),a1
	move.l	#ePagelogo-Pagelogo,d3
	bsr	printmessage

	swap	d0
	and.l	#$70,d0
	lea	Pagesize(pc),a1
	add.l	d0,a1
	move.l	#$10,d3
	bsr	printmessage
	bsr	printcrlf


	lea	Islogo(pc),a1
	move.l	#eIslogo-Islogo,d3
	bsr	printmessage

	move.l	savemmu2,d0
	swap	d0
	and.l	#$f,d0
	bsr	printnumber
	bsr	printcrlf


	lea	TIA(pc),a1
	move.l	#eTIA-TIA,d3
	bsr	printmessage
	move.l	savemmu2,d0
	moveq	#12,d3
	lsr	d3,d0
	and.l	#$f,d0
	bsr	printnumber

	lea	TIB(pc),a1
	move.l	#eTIB-TIB,d3
	bsr	printmessage
	move.l	savemmu2,d0
	lsr	#8,d0
	and.l	#$f,d0
	bsr	printnumber

	lea	TIC(pc),a1
	move.l	#eTIC-TIC,d3
	bsr	printmessage
	move.l	savemmu2,d0
	lsr	#4,d0
	and.l	#$f,d0
	bsr	printnumber

	lea	TID(pc),a1
	move.l	#eTID-TID,d3
	bsr	printmessage
	move.l	savemmu2,d0
	and.l	#$f,d0
	bsr	printnumber
	bsr	printcrlf

	lea	CRP(pc),a1
	move.l	#eCRP-CRP,d3
	bsr	printmessage

	move.l	savemmu4,d0
	btst.l	#31,d0
	bne.s	prtlower

	lea	Upper(pc),a1
	move.l	#eUpper-Upper,d3
	bsr	printmessage
	bra.s	chklimit
prtlower:
	lea	Lower(pc),a1
	move.l	#eLower-Lower,d3
	bsr	printmessage

chklimit:

	swap	d0
	and.l	#$7fff,d0
	bsr	printhexnum
	bsr	printcrlf

	move.l	savemmu4,d0
	btst.l	#9,d0
	bne.s	prtsgy

	lea	SGN(pc),a1
	move.l	#eSGN-SGN,d3
	bsr	printmessage
	bra.s	chkdt
prtsgy:
	lea	SGY(pc),a1
	move.l	#eSGY-SGY,d3
	bsr	printmessage

chkdt:
	bsr	printcrlf

	and.l	#3,d0
	add.b	d0,dtbyte

	lea	PDT(pc),a1
	move.l	#ePDT-PDT,d3
	bsr	printmessage

	move.l	savemmu4+4,d0
	and.b	#$f0,d0
	bsr	printhexnum
	bsr	printcrlf
	bsr	printcrlf

	rts


prtbyte:
	dc.b	0,0,0,0

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
logo:
	dc.b	10,13,27,'[3mMMU  - By Sean Godsell',27,'[m',10,10,13
	dc.b	27,'[4mTranslation Control (TC)',27,'[m',10,13
	cnop	0,2
elogo:
enabled:
	dc.b	'Enabled',10,13
	cnop	0,2
eenabled:
disabled:
	dc.b	'Disabled',10,13
	cnop	0,2
edisabled:
srenabled:
	dc.b	'Supervisor Root Pointer Enabled',10,13
	cnop	0,2
esrenabled:
srdisabled:
	dc.b	'Supervisor Root Pointer Disabled',10,13
	cnop	0,2
esrdisabled:
fcenabled:
	dc.b	'Function Code Lookup Enabled',10,13
	cnop	0,2
efcenabled:
fcdisabled:
	dc.b	'Function Code Lookup Disabled',10,13
	cnop	0,2
efcdisabled:
Pagelogo:
	dc.b	'Page Size  '
	cnop	0,2
ePagelogo:
Pagesize:
	dc.b	'$8 - 256 Bytes  '
	dc.b	'$9 - 512 Bytes  '
	dc.b	'$A - 1K Bytes   '
	dc.b	'$B - 2K Bytes   '
	dc.b	'$C - 4K Bytes   '
	dc.b	'$D - 8K Bytes   '
	dc.b	'$E - 16K Bytes  '
	dc.b	'$F - 32K Bytes  '
	cnop	0,2

Islogo:
	dc.b	'Initial Shift  - '
	cnop	0,2
eIslogo:

TIA:
	dc.b	'Table Indices  (0 - Not Used)  TIA - '
	cnop	0,2
eTIA:
TIB:
	dc.b	' , TIB - '
	cnop	0,2
eTIB:
TIC:
	dc.b	' , TIC - '
	cnop	0,2
eTIC:
TID:
	dc.b	' , TID - '
	cnop	0,2
eTID:

CRP:
	dc.b	10,13,27,'[4mCPU Root Pointer (CRP)',27,'[m',10,13
	cnop	0,2
eCRP:

Upper:
	dc.b	'Upper Limit - $'
	cnop	0,2
eUpper:
Lower:
	dc.b	'Lower Limit - $'
	cnop	0,2
eLower:

SGY:
	dc.b	'Shared Globally - 1'
	cnop	0,2
eSGY:
SGN:
	dc.b	'Shared Globally - 0'
	cnop	0,2
eSGN:
PDT:
	dc.b	'Descriptor Type (DT) - $'
dtbyte:
	dc.b	'0',10,13
	dc.b	'Table Address - $'
	cnop	0,2
ePDT:

crlf:
	dc.b	10,13
	cnop	0,2

savesr:	
	dc.w	0,0
	
dosbase:
	dc.l	0,0
outhandle:
	dc.l	0,0
savepriv:
	dc.l	0,0

savemmu1:
	dc.l	0,0,0,0,0,0,0,0
savemmu2:
	dc.l	0,0,0,0,0,0,0,0
savemmu3:
	dc.l	0,0,0,0,0,0,0,0
savemmu4:
	dc.l	0,0,0,0,0,0,0,0
savemmu5:
	dc.l	0,0,0,0,0,0,0,0
savemmu6:
	dc.l	0,0,0,0,0,0,0,0
