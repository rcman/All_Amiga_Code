 
openscreen	equ	-198
closescreen	equ	-66
openlib		equ	-408
closelib	equ	-414
open		equ	-30
close		equ	-36
write		equ	-48
AllocMem	equ	-198
FreeMem		equ	-210
sysbase		equ	4
serwrt		equ	$dff030
IntREQW		equ	$dff09c
serreg		equ	$dff01e
serbaud		equ	$dff032
serdatr		equ	$dff018
serdat		equ	$dff030
level5		equ	$74
mode_new	equ	1006
b19200		equ	185
b9600		equ	372
b4800		equ	744
b2400		equ	1490

xskip		equ	110
xscan		equ	100
;baud speed  (3579545/baud)-1
resol		equ	'7'


main:

;--- open intuition library ----------------
		move.b	(a0),d0
		sub.b	#$31,d0
		cmp.b	#6,d0
		bgt.s	no_sele_res
		add.b	#$31,d0
		move.b	d0,theresol
no_sele_res:

		moveq	#0,d0
		move.l	sysbase,a6
		lea	intname(pc),a1
		jsr	openlib(a6)
		move.l	d0,intbase
		beq	error

;--- open screen ---------------------------
		move.l	d0,a6
		lea	myscreen(pc),a0
		jsr	openscreen(a6)
		move.l	d0,screenhd
		beq	errorscrn

;--- Allocate Memory -----------------------

		move.l	sysbase,a6
		move.l	#150000,d0
		move.l	#$10002,d1
		jsr	AllocMem(a6)
		move.l	d0,Memarea
		beq	errormem
		move.l	d0,bufferp

;--- Get Dos base --------------------------
		moveq	#0,d0
		move.l	sysbase,a6
		lea	dosname(pc),a1
		jsr	openlib(a6)
		move.l	d0,dosbase
		beq	errordos

;--- set up the serial interupt ------------
		move.w	#b9600,$dff032
		move.l	level5,jmploc+2		;setup patch for jump
		lea	serinter(pc),a1
		move.l	a1,level5		;set up serial int.
		move.w	#$3fff,$bfd0fe		;init handshake lines
		move.w	#$800,$dff09c		;clear serial inter req
		move.w	#$8800,$dff09a		;enable serial inter

		bsr	transmit

		move.l	buffers,a1
		move.l	Memarea,a0
;		move.l	Memarea,bufferp
;		lea	countarea(pc),a2
		moveq	#0,d1
;		moveq	#2,d2
;		move.l	Memarea,$68000
;		move.l	a2,$68004

waitsbi:
		move.b	$bfe001,d0
		and.b	#$80,d0
		beq.s	getout

		cmp.l	bufferp,a1
		beq.s	waitsbi

;-----------------------
		move.b	(a1)+,d0	;get the data from the interrupt

		cmp.b	#0,d1
		bne.s	countdown

		move.b	d0,(a0)+

		move.b	d0,d1
		rol.w	#8,d1
		cmp.l	buffere,a1
		bne	nolowarea
		move.l	buffers,a1
nolowarea:
		cmp.l	bufferp,a1
		beq.s	nolowarea

		move.b	(a1)+,d0
		move.b	d0,d1

;		subq.w	#1,d2
;		cmp.b	#0,d2
;		bne.s	nocountdown
;
;		move.w	d3,d1		;got the count
		cmp.w	#1,d1		;check if there is anymore data
		beq.s	getout		;IF good-bye!!

		addq.w	#1,d1

countdown:
;		moveq	#2,d2
		subq.w	#1,d1
nocountdown:
		move.b	d0,(a0)+	;save the data

		move.l	a0,a3
		move.l	Memarea,a4
		sub.l	a4,a3
		cmp.l	#149000,a3
		bgt.s	getout

		cmp.l	buffere,a1
		bne	waitsbi
		move.l	buffers,a1

		bra	waitsbi

getout:

		move.l	a0,enddatarea	;save the end of data area

		move.w	#$114,$dff030
		move.w	#$800,$dff09a
		move.l	jmploc+2,a1
		move.l	a1,level5

;--- Save the Memory area
		move.l	dosbase,a6
		lea	dosfile(pc),a1
		move.l	a1,d1
		move.l	#mode_new,d2
		jsr	open(a6)
		move.l	d0,filehandle
		beq	dontsavefile

		move.l	d0,d1		;the file handle
		move.l	Memarea,d2	;Area to save
;		move.l	#150000,d3
		move.l	enddatarea,d3	;get end area
		sub.l	d2,d3		;length
		move.l	dosbase,a6
		jsr	write(a6)

		move.l	filehandle,d1
		move.l	dosbase,a6
		jsr	close(a6)


dontsavefile:
		move.l	dosbase,a1
		move.l	sysbase,a6
		jsr	closelib(a6)
errordos:
		move.l	Memarea,a1
		move.l	#150000,d0
		move.l	sysbase,a6
		jsr	FreeMem(a6)
errormem:
		move.l	intbase,a6
		move.l	screenhd,a0
		jsr	closescreen(a6)
errorscrn:
		move.l	intbase,a1
		move.l	sysbase,a6
		jsr	closelib(a6)
error:
		rts

;---------------------------------------------------
serinter:
		movem.l	d0/a1,-(sp)

;		move.w	#$4000,$dff09a

		move.l	bufferp,a1
		btst.b	#3,$dff01e
;		move.w	$DFF01E,d0
;		and.w	#$800,d0
		beq.s	jmplevel5

		move.w	serdatr,d0

		move.b	d0,(a1)+	;save serial data

		cmp.l	buffere,a1
		bne.s	nochange

		move.l	buffers,a1
nochange:
		move.l	a1,bufferp

		move.w	#$800,IntREQW	;Clear the Receiver buffer

;		move.w	#$c000,$dff09a

		movem.l	(sp)+,d0/a1
		rte

jmplevel5:
;		move.w	#$c000,$dff09a
		movem.l	(sp)+,d0/a1
jmploc:
		jmp	$8000000


;--- transmit the data to the scanner ---------
transmit:
		lea	transmitdata(pc),a1
		move.w	#transmitend-transmitdata,d0
		bsr	cleartb

senddata:
		move.w	#$100,d1
		or.b	(a1)+,d1
		move.w	d1,serdat		;send the data

waitempty:
		move.w	serreg,d1		;look at sertransmit buffer
		and.w	#$1,d1
		beq.s	waitempty

		bsr	cleartb

		dbra	d0,senddata

		rts

cleartb:
		move.w	#$1,$dff09c
		rts

;--- data area -----------------------------------

intname:	dc.b	'intuition.library',0
		cnop	0,2

dosname:	dc.b	'dos.library',0
		cnop	0,2

dosfile:	dc.b	'ScanImage',0
		cnop	0,2

;countarea:	ds.w	2000

intbase:	dc.l	0
dosbase:	dc.l	0
screenhd:	dc.l	0
Memarea:	dc.l	0
bufferp:	dc.l	bufferarea
buffers:	dc.l	bufferarea
buffere:	dc.l	bufferarea+2000
filehandle	dc.l	0
enddatarea:	dc.l	0

bufferarea:	ds.l	3000
		dc.l	0

myscreen:	dc.w	0	;left edge
		dc.w	0	;top edge
		dc.w	640	;width
		dc.w	400	;height
		dc.w	2	;depth
		dc.b	0,1	;detail pen,block pen
		dc.w	$8004	;view modes
		dc.w	$f	;intuition screen type
		dc.l	0	;pointer to font
		dc.l	mytitle	;screen title
		dc.l	0	;pointer to list of gadgets
		dc.l	0	;pointer to custom bit map

mytitle:	dc.b	'Page Scanner - By Sean Godsell',0
		cnop	0,2

transmitdata:
		dc.b	27,'R'		;Resolution 300dpi
theresol:	dc.b	resol
		dc.b	27,'C1'		;No Compression
		dc.b	27,'T1'		;High speed transmission mode
		dc.b	27,'g1'		;Gray scale suitability (Character)
		dc.b	27,'p1'		;Positive (Normal)

		dc.b	27,'X'
		dc.w	xskip		;Skip Length
		dc.w	xscan		;Scan Length
		dc.b	27,'Y'
		dc.w	0		;Skip Length
		dc.w	150		;Scan Length
		dc.b	27,'X'
		dc.w	xskip		;Skip Length
		dc.w	xscan		;Scan Length
		dc.b	27,'X'
		dc.w	xskip		;Skip Length
		dc.w	xscan		;Scan Length
		dc.b	18		;Transmit data (start)
transmitend:


