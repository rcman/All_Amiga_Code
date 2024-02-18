
openscreen	equ	-198
closescreen	equ	-66
openlib		equ	-408
closelib	equ	-414
open		equ	-30
close		equ	-36
write		equ	-48
read		equ	-42
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
mode_old	equ	1005

main:

;--- open intuition library ----------------
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
		move.l	d0,a0
		move.l	$c0(a0),plane1

;--- Allocate Memory -----------------------

		move.l	sysbase,a6
		move.l	#150000,d0
		move.l	#$10002,d1
		jsr	AllocMem(a6)
		move.l	d0,Memarea
		beq	errormem

;--- Get Dos base --------------------------
		moveq	#0,d0
		move.l	sysbase,a6
		lea	dosname(pc),a1
		jsr	openlib(a6)
		move.l	d0,dosbase
		beq	errordos

		bsr	readthefile

;--- Display the data ----------------------

;		move.l	Memarea,$68000
;waitbuttn:
;		move.b	$bfe001,d0
;		and.b	#$80,d0
;		bne.s	waitbuttn

;		bra	getout


;		move.l	plane1,a1
;		move.l	Memarea,a0
;		add.l	#22,a0

;		lea	countarea(pc),a2
;		clr.l	d1
;		move.w	#350,d3
;		move.l	Memarea,$68000
;		move.l	a2,$68004

chinondata:
;		bsr	getlength

;		cmp.w	#1,d1
;		beq.s	getout
;		cmp.w	#100,d1
;		bgt.s	getout

;		moveq	#65,d2
;		move.l	a1,a2

placedata:
;		move.b	(a0)+,(a2)+	

;		subq.w	#1,d1
;		bne.s	forthetime
;		add.l	#80,a1
;		bra.s	lookoutbaby
forthetime:
;		dbra	d2,placedata

;		add.l	#80,a1
keepgoin:
;		move.b	(a0)+,d5
;		subq.w	#1,d1
;		bne.s	keepgoin
lookoutbaby:
;		dbra	d3,chinondata

getout:
waitbutton:
		move.b	$bfe001,d0
		and.b	#$40,d0
		bne.s	waitbutton


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

;--- Get the Data length -----------------
getlength:
		move.b	(a0)+,d0
		move.b	d0,d1
		rol.w	#8,d1
		move.b	(a0)+,d0
		move.b	d0,d1
		rts

;--- Read the file into the Memory area
readthefile:
		move.l	dosbase,a6
		lea	dosfile(pc),a1
		move.l	a1,d1
		move.l	#mode_old,d2
		jsr	open(a6)
		move.l	d0,filehandle
		beq	dontsavefile

		move.l	d0,d1		;the file handle
;		move.l	Memarea,d2	;Area to save
;		move.l	#123000,d3	;length
		move.l	plane1,d2
		move.l	32000,d3
		move.l	dosbase,a6
		jsr	read(a6)

		move.l	filehandle,d1
		move.l	dosbase,a6
		jsr	close(a6)

dontsavefile:
		rts

;--- data area -----------------------------------

intname:	dc.b	'intuition.library',0
		cnop	0,2

dosname:	dc.b	'dos.library',0
		cnop	0,2

dosfile:	dc.b	'ScanImage',0
		cnop	0,2

intbase:	dc.l	0
dosbase:	dc.l	0
screenhd:	dc.l	0
Memarea:	dc.l	0
;bufferp:	dc.l	0bufferarea
;buffers:	dc.l	bufferarea
;buffere:	dc.l	bufferarea+4000
plane1:		dc.l	0
filehandle	dc.l	0
enddatarea:	dc.l	0

myscreen:	dc.w	0	;left edge
		dc.w	0	;top edge
		dc.w	640	;width
		dc.w	400	;height
		dc.w	1	;depth
		dc.b	0,1	;detail pen,block pen
		dc.w	$8004	;view modes
		dc.w	$f	;intuition screen type
		dc.l	0	;pointer to font
		dc.l	mytitle	;screen title
		dc.l	0	;pointer to list of gadgets
		dc.l	0	;pointer to custom bit map

mytitle:	dc.b	'Page Scanner - By Sean Godsell',0
		cnop	0,2

