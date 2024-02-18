
openscreen	equ	-198
closescreen	equ	-66
openwindow	equ	-204
closewindow	equ	-72
SetMenuStrip	equ	-264
ClearMenuStrip	equ	-54

openlib		equ	-408
closelib	equ	-414
open		equ	-30
close		equ	-36
write		equ	-48
AllocMem	equ	-198
FreeMem		equ	-210
GetMsg		equ	-372
sysbase		equ	4
Draw		equ	-246	;(rp,x,y) (a1,d0,d1)
_Move		equ	-240	;(rp,x,y) (a1,d0,d1)
SetAPen		equ	-342	;(rp,pen) (a1,d0)
SetDrMd		equ	-354
RectFill	equ	-306
WritePixel	equ	-324
PolyDraw	equ	-336

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

xskip		equ	0	;200	;0
xscan		equ	250	;100	;316
yskip		equ	0	;0
yscan		equ	200	;425  was 150
;baud speed  (3579545/baud)-1
resol		equ	'5'


;--- Check which resolution to use ---------
		move.b	(a0),d0
		sub.b	#$31,d0
		cmp.b	#6,d0
		bgt.s	no_sele_res
		add.b	#$31,d0
		move.b	d0,theresol
no_sele_res:

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
		move.l	d0,screen2hd
		move.l	d0,screen3hd
		beq	errorscrn
		move.l	d0,a0
;		move.l	$54(a0),rastport
		move.l	$c0(a0),plane1
		move.l	$c4(a0),plane2
		move.l	$c8(a0),plane3
		move.l	$cc(a0),plane4

;--- open Window ---------------------------

		lea	mywindow(pc),a0
		move.l	intbase,a6
		jsr	openwindow(a6)
		move.l	d0,windowhd
		beq	errorwindow
		move.l	d0,a0
		move.l	50(a0),rastport

;--- Allocate Memory -----------------------

		move.l	sysbase,a6
		move.l	#16000,d0
		move.l	#$10002,d1
		jsr	AllocMem(a6)
		move.l	d0,Memarea
		move.l	d0,bufferp
		move.l	d0,buffers
		beq	errormem
		add.l	#4000,d0
		move.l	d0,buffere

;--- Get Dos base --------------------------
		moveq	#0,d0
		move.l	sysbase,a6
		lea	dosname(pc),a1
		jsr	openlib(a6)
		move.l	d0,dosbase
		beq	errordos

;--- Get Graphics base --------------------------
		moveq	#0,d0
		move.l	sysbase,a6
		lea	gfxname(pc),a1
		jsr	openlib(a6)
		move.l	d0,gfxbase
		beq	errorgfx

;--- set up the serial interupt ------------
		move.w	#b19200,$dff032
		move.l	level5,jmploc+2		;setup patch for jump
		lea	serinter(pc),a1
		move.l	a1,level5		;set up serial int.
		move.w	#$3fff,$bfd0fe		;init handshake lines
		move.w	#$800,$dff09c		;clear serial inter req
		move.w	#$8800,$dff09a		;enable serial inter

;--- Draw Box -------------------------------

;		move.l	rastport,a1
;		move.l	gfxbase,a6

;		move.w	#560,d0
;		move.w	#10,d1
;		jsr	_Move(a6)

;		lea	poly2(pc),a0
;		move.l	#8,d0
;		jsr	PolyDraw(a6)

		move.l	#0,d0
		move.l	rastport,a1
		move.l	gfxbase,a6
		jsr	SetAPen(a6)

		move.w	#0,d0
		move.w	#10,d1
		jsr	_Move(a6)

		lea	poly1(pc),a0
		move.l	#10,d0
		jsr	PolyDraw(a6)

;-- MAIN LOOP -------------------------------
		bsr	setmenu		;Set up the Menu

mainloop:
		move.l	sysbase,a6
		move.l	windowhd,a0
		move.l	86(a0),a0
		jsr	GetMsg(a6)
		tst.l	d0
		beq.s	mainloop

		move.l	d0,a0
		move.l	$14(a0),d6
		
		cmp.w	#$200,d6	;Check if the window is closed
		beq	exit

		cmp.w	#$40,d6
		bne	no_gadget

;		lea	scangad(pc),a0
;		move.w	$c(a0),d0
;		and.w	#$80,d0
;		beq.s	mainloop

;		move.b	#'5',contrast
;		move.w	#0,whichplane	;read into plane 0
;		bsr	ScanImage
;
;waitcon4:
;		btst.b	#6,$bfe001
;		bne.s	waitcon4
;
;		move.b	#'4',contrast
;		move.w	#4,whichplane	;read into plane 1
;		bsr	ScanImage
;
;waitcon3:
;		btst.b	#6,$bfe001
;		bne.s	waitcon3
;
;		move.b	#'3',contrast
;		move.w	#8,whichplane	;read into plane 2
;		bsr	ScanImage
;
;waitcon2:
;		btst.b	#6,$bfe001
;		bne.s	waitcon2
;
;		move.b	#'2',contrast
;		move.w	#$c,whichplane	;read into plane 3
;		bsr	ScanImage

		bra	mainloop

no_gadget:
		move.w	$18(a0),d0

		move.w	d0,d1
		and.l	#$1f,d0		;Menu title
		and.l	#$7e0,d1
		lsr.w	#5,d1		;Menu item

;-- Save the Picture ---------------------------
		cmp.w	#0,d0
		bne.s	gotosetres

		cmp.b	#0,d1
		bne.s	notthescan
		bsr	ScanImage
		bra	mainloop
notthescan:
		cmp.b	#1,d1
		bne.s	notthesave
		bsr	SaveScreen
		bra	mainloop
notthesave:
		cmp.b	#2,d1
		bne.s	notthearea
		bsr	AreaScan
		bra	mainloop
notthearea:

;-- Set the Resolution from the menu -----------
gotosetres:
		cmp.w	#1,d0
		bne.s	no_pick_baud

		move.l	#bauditem02-bauditem01,d0
		lea	bauditem01(pc),a2
		moveq	#0,d2
clearbaudfg:
		move.w	$c(a2),d3
		cmp.w	d1,d2
		beq.s	no_clr_item1
		and.w	#$feff,d3
		bra.s	no_set_item1
no_clr_item1:
		or.w	#$100,d3
no_set_item1:
		move.w	d3,$c(a2)
		add.l	d0,a2
		addq	#1,d2
		cmp.w	#4,d2
		bne.s	clearbaudfg

		cmp.b	#0,d1
		bne.s	not_19200
		move.w	#b19200,$dff032
not_19200:
		cmp.b	#1,d1
		bne.s	not_9600
		move.w	#b9600,$dff032
not_9600:
		cmp.b	#2,d1
		bne.s	not_4800
		move.w	#b4800,$dff032
not_4800:
		cmp.b	#3,d1
		bne.s	not_2400
		move.w	#b2400,$dff032
not_2400:

no_pick_baud:

;-- Set the Resolution from the menu -----------
		cmp.w	#2,d0
		bne.s	no_pick_resol

		move.l	#resolitem02-resolitem01,d0
		lea	resolitem01(pc),a2
		moveq	#0,d2
clearresfg:
		move.w	$c(a2),d3
		cmp.w	d1,d2
		beq.s	no_clr_item2
		and.w	#$feff,d3
		bra.s	no_set_item2
no_clr_item2:
		or.w	#$100,d3
no_set_item2:
		move.w	d3,$c(a2)
		add.l	d0,a2
		addq	#1,d2
		cmp.w	#7,d2
		bne.s	clearresfg
		add.b	#$31,d1
		move.b	d1,theresol


no_resol_baud:
no_pick_resol:

;-- Set the Contrast from the menu -----------
		cmp.w	#3,d0
		bne.s	no_set_contr

		move.l	#contrastitem02-contrastitem01,d0
		lea	contrastitem01(pc),a2
		moveq	#0,d2

clearcontr:
		move.w	$c(a2),d3
		cmp.w	d1,d2
		beq.s	no_clr_item3c
		and.w	#$feff,d3
		bra.s	no_set_item3c
no_clr_item3c:
		or.w	#$100,d3
no_set_item3c:
		move.w	d3,$c(a2)
		add.l	d0,a2
		addq	#1,d2
		cmp.w	#6,d2
		bne.s	clearcontr
		add.b	#$31,d1
		move.b	d1,contrast

no_set_contr:

		bra	mainloop

;--- Exit program ------------------------
exit:
		bsr	clearmenu	;disable the menu

;		move.l	a0,enddatarea	;save the end of data area

		move.w	#$114,$dff030
		move.w	#$800,$dff09a
		move.l	jmploc+2,a1
		move.l	a1,level5
;		bra	dontsavefile

		move.l	gfxbase,a1
		move.l	sysbase,a6
		jsr	closelib(a6)
errorgfx:
		move.l	dosbase,a1
		move.l	sysbase,a6
		jsr	closelib(a6)
errordos:
		move.l	Memarea,a1
		move.l	#16000,d0
		move.l	sysbase,a6
		jsr	FreeMem(a6)
errormem:
		move.l	intbase,a6
		move.l	windowhd,a0
		jsr	closewindow(a6)
errorwindow:
		move.l	intbase,a6
		move.l	screenhd,a0
		jsr	closescreen(a6)
errorscrn:
		move.l	intbase,a1
		move.l	sysbase,a6
		jsr	closelib(a6)
error:
		rts

;---- Setup Scan Area ---------------------
AreaScan:

;--- open Scan Area Window ---------------------------

		lea	areawindow(pc),a0
		move.l	intbase,a6
		jsr	openwindow(a6)
		move.l	d0,savewindowhd
		beq	dontsavefile

areamainloop:
		move.l	sysbase,a6
		move.l	savewindowhd,a0
		move.l	86(a0),a0
		jsr	GetMsg(a6)
		tst.l	d0
		beq.s	areamainloop

		move.l	d0,a0
		move.l	$14(a0),d6
		
		cmp.w	#$20,d6
		bne	areamainloop

		move.l	intbase,a6
		move.l	savewindowhd,a0
		jsr	closewindow(a6)

		rts

;---- Save the Screen ---------------------
SaveScreen:

;--- open Save Window ---------------------------

		lea	savewindow(pc),a0
		move.l	intbase,a6
		jsr	openwindow(a6)
		move.l	d0,savewindowhd
		beq	dontsavefile

clrflagssave:
savemainloop:
		move.l	sysbase,a6
		move.l	savewindowhd,a0
		move.l	86(a0),a0
		jsr	GetMsg(a6)
		tst.l	d0
		beq.s	savemainloop

		move.l	d0,a0
		move.l	$14(a0),d6
		
		cmp.w	#$20,d6
		bne	savemainloop

		move.w	$18(a0),d0

no_gadgets:

		lea	scangad(pc),a0
		move.w	$c(a0),d0
		and.w	#$80,d0
		bne	savefileit

		lea	scangad2(pc),a0
		move.w	$c(a0),d0
		and.w	#$80,d0
		bne	dontsavefile2

		bra	clrflagssave

savefileit:
		move.l	intbase,a6
		move.l	savewindowhd,a0
		jsr	closewindow(a6)

		move.l	dosbase,a6
		lea	bfilename(pc),a1
		move.l	a1,d1
		move.l	#mode_new,d2
		jsr	open(a6)
		move.l	d0,filehandle
		beq	dontsavefile

		move.l	d0,d1		;the file handle
		lea	IFFhead(pc),a1	;IFF Header Area to save
		move.l	a1,d2
		move.l	#IFFtail-IFFhead,d3	;IFF Header length
		move.l	dosbase,a6
		jsr	write(a6)

		move.l	filehandle,d1	;the file handle
;		move.l	MemArea,d2	;Area to save
		move.l	plane1,d2	;Area to save
		move.l	#32000,d3
;		move.l	enddatarea,d3	;get end area
;		sub.l	d2,d3		;length
		move.l	dosbase,a6
		jsr	write(a6)

		move.l	filehandle,d1
		move.l	dosbase,a6
		jsr	close(a6)

dontsavefile:
		rts

dontsavefile2:
		move.l	intbase,a6
		move.l	savewindowhd,a0
		jsr	closewindow(a6)

		rts

;---- Read in the Image ---------------------
ScanImage:
		bsr	transmit

		move.w	whichplane,d1
		lea	plane1(pc),a1
		move.l	0(a1,d1),a0

		move.l	buffers,a1
		add.l	#22,a1
		add.l	#960,a0
		moveq	#0,d1
		moveq	#0,d5
		move.l	#387,d3

wait_22:
		cmp.l	bufferp,a1
		bne.s	wait_22
		

;-------- Display the data on the screen -----------------

waitsbi:
		move.l	a0,a2
		moveq	#69,d2

		bsr	getbyte
		move.b	d0,d1
		rol.w	#8,d1
		bsr	getbyte
		move.b	d0,d1
		bsr	getbyte

		cmp.w	#1,d1		;check if there is anymore data
		beq.s	getout		;IF good-bye!!
		subq	#1,d1

countdown:
		bsr	getbyte
		cmp.b	#1,d5
		beq.s	getout
		move.b	d0,(a2)+	;put data on the screen
		subq.w	#1,d1
		bne.s	forthetime

		add.l	#80,a0
		bra.s	lookoutbaby
forthetime:
		dbra	d2,countdown
		add.l	#80,a0

keepgoin:
		bsr	getbyte
		cmp.b	#1,d5
		beq.s	getout
		subq.w	#1,d1
		bne.s	keepgoin

lookoutbaby:
		dbra	d3,waitsbi

getout:
		rts

;---------------------------------------------------
getbyte:
		btst.b	#7,$bfe001
		bne.s	no_cancel
		moveq	#1,d5
		bra.s	gotbyte
no_cancel:
		cmp.l	bufferp,a1
		beq.s	getbyte

		move.b	(a1)+,d0
		cmp.l	buffere,a1
		bne.s	gotbyte
		move.l	buffers,a1
gotbyte:
		rts

;---------------------------------------------------
serinter:
		movem.l	d0-d1/a1,-(sp)
		move.l	bufferp,a1
		move.w	$dff01e,d1
		and.w	#$800,d1
		beq.s	jmplevel5

		move.w	serdatr,d0

		move.b	d0,(a1)+	;save serial data

		cmp.l	buffere,a1
		bne.s	nochange

		move.l	buffers,a1
nochange:
		move.l	a1,bufferp

		move.w	#$800,IntREQW	;Clear the Receiver buffer

		move.w	$dff01e,d1
		and.w	#$1000,d1
		bne.s	jmplevel5

		movem.l	(sp)+,d0-d1/a1
		rte

jmplevel5:
		movem.l	(sp)+,d0-d1/a1
jmploc:
		jmp	$8000000

;--- Set up the Menu Strip --------------------
setmenu:
		move.l	intbase,a6
		move.l	windowhd,a0
		lea	file,a1
		jsr	SetMenuStrip(a6)
		rts

;--- Clear the Menu Strip ---------------------
clearmenu:
		move.l	intbase,a6
		move.l	windowhd,a0
		jsr	ClearMenuStrip(a6)
		rts

;--- transmit the data to the scanner ---------
transmit:
		move.l	buffers,bufferp
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

gfxname:	dc.b	'graphics.library',0
		cnop	0,2

dosfile:	dc.b	'ScanImage',0
		cnop	0,2

;countarea:	ds.w	2000

intbase:	dc.l	0
dosbase:	dc.l	0
gfxbase:	dc.l	0
windowhd:	dc.l	0
savewindowhd:	dc.l	0
Memarea:	dc.l	0
whichplane:	dc.w	0
plane1:		dc.l	0
plane2:		dc.l	0
plane3:		dc.l	0
plane4:		dc.l	0
rastport	dc.l	0
bufferp:	dc.l	0	;bufferarea
buffers:	dc.l	0	;bufferarea
buffere:	dc.l	0	;bufferarea+4000
filehandle	dc.l	0
enddatarea:	dc.l	0

;bufferarea:	ds.l	4200
		dc.l	0

myscreen:	dc.w	0	;left edge
		dc.w	0	;top edge
		dc.w	640	;width
		dc.w	400	;height
		dc.w	4	;depth
		dc.b	0,1	;detail pen,block pen
		dc.w	$8004	;view modes
		dc.w	$f	;intuition screen type
		dc.l	0	;pointer to font
		dc.l	mytitle	;screen title
		dc.l	0	;pointer to list of gadgets
		dc.l	0	;pointer to custom bit map

mywindow:	dc.w	0	;left edge
		dc.w	1	;top edge
		dc.w	580	;width
		dc.w	399	;height
		dc.b	0,1	;detail pen,block pen
		dc.l	$348	;IDCMP flags:Closewindow
		dc.l	$1808	;Activate and all gadgets
		dc.l	0 ;scangad	;first gadget:no gadgets
		dc.l	0	;Checkmark:Standard
		dc.l	mytitle	;screen title
screenhd:	dc.l	0	;Screen pointer
		dc.l	0	;no bitmap of our own
		dc.w	100	;Smallest width
		dc.w	20	;Smallest height
		dc.w	640	;Maximum width
		dc.w	400	;Maximum height
		dc.w	15	;Screen type:custom

		dc.l	0

savewindow:	dc.w	150	;left edge
		dc.w	50	;top edge
		dc.w	280	;width
		dc.w	80	;height
		dc.b	0,1	;detail pen,block pen
		dc.l	$68	;IDCMP flags:Closewindow
		dc.l	$1002	;Activate and all gadgets
		dc.l	scangad	;first gadget:no gadgets
		dc.l	0	;Checkmark:Standard
		dc.l	savetitle	;screen title
screen2hd:	dc.l	0	;Screen pointer
		dc.l	0	;no bitmap of our own
		dc.w	10	;Smallest width
		dc.w	10	;Smallest height
		dc.w	280	;Maximum width
		dc.w	80	;Maximum height
		dc.w	15	;Screen type:custom

		dc.l	0

areawindow:	dc.w	150	;left edge
		dc.w	50	;top edge
		dc.w	210	;width
		dc.w	300	;height
		dc.b	0,1	;detail pen,block pen
		dc.l	$68	;IDCMP flags:Closewindow
		dc.l	$1002	;Activate and all gadgets
		dc.l	areagad	;first gadget:no gadgets
		dc.l	0	;Checkmark:Standard
		dc.l	areatitle	;screen title
screen3hd:	dc.l	0	;Screen pointer
		dc.l	0	;no bitmap of our own
		dc.w	10	;Smallest width
		dc.w	10	;Smallest height
		dc.w	280	;Maximum width
		dc.w	399	;Maximum height
		dc.w	15	;Screen type:custom

		dc.l	0

mytitle:	dc.b	'Page Scanner - By Sean Godsell',0
		cnop	0,2
savetitle:	dc.b	'Save an Image',0
		cnop	0,2
areatitle:	dc.b	'Setup Scan Area',0
		cnop	0,2

transmitdata:
		dc.b	27,'R'		;Resolution 300dpi
theresol:	dc.b	resol
		dc.b	27,'C1'		;No Compression
		dc.b	27,'T1'		;High speed transmission mode
		dc.b	27,'g1'		;Gray scale suitability (Character)
		dc.b	27,'p1'		;Positive (Normal)
		dc.b	27,'d'		;Contrast
contrast:	dc.b	'5'

		dc.b	27,'X'
		dc.w	xskip		;Skip Length
		dc.w	xscan		;Scan Length
		dc.b	27,'Y'
		dc.w	yskip		;Skip Length
		dc.w	yscan		;Scan Length
		dc.b	27,'X'
		dc.w	xskip		;Skip Length
		dc.w	xscan		;Scan Length
		dc.b	27,'X'
		dc.w	xskip		;Skip Length
		dc.w	xscan		;Scan Length
		dc.b	18		;Transmit data (start)
transmitend:

		cnop	0,4

;--- Gadgets ----------------------
areagad:
		dc.l	areagad2
		dc.w	15,278,64,18
		dc.w	1 ;0 ;4
		dc.w	$3
		dc.w	1
		dc.l	0 ;scanimg	;image
		dc.l	0	;scanimg
		dc.l	astext
		dc.l	0
		dc.l	0
		dc.w	1
		dc.l	0
astext:
		dc.b	1,0,1,0
		dc.w	14,6
		dc.l	0
		dc.l	areatxt
		dc.l	0
areatxt:
		dc.b	' OK ',0
		cnop	0,4

areagad2:
		dc.l	0 scangad2
		dc.w	130,278,64,18
		dc.w	1 ;0 ;4
		dc.w	$3
		dc.w	1
		dc.l	0 ;scanimg	;image
		dc.l	0	;scanimg
		dc.l	astext2
		dc.l	0
		dc.l	0
		dc.w	1
		dc.l	0
astext2:
		dc.b	1,0,1,0
		dc.w	8,5
		dc.l	0
		dc.l	areatxt2
		dc.l	0
areatxt2:
		dc.b	'Cancel',0
		cnop	0,4

scangad:
		dc.l	scangad2
		dc.w	20,55,64,18
		dc.w	1 ;0 ;4
		dc.w	$3
		dc.w	1
		dc.l	0 ;scanimg	;image
		dc.l	0	;scanimg
		dc.l	ggtext
		dc.l	0
		dc.l	0
		dc.w	1
		dc.l	0
ggtext:
		dc.b	1,0,1,0
		dc.w	14,6
		dc.l	0
		dc.l	savetxt
		dc.l	0
savetxt:
		dc.b	'SAVE',0
		cnop	0,4
scanimg:
		dc.w	0,0
		dc.w	64,18
		dc.w	1
		dc.l	scandata
		dc.b	2,1
		dc.l	0
scangad2:
		dc.l	scangad3
		dc.w	175,55,64,18
		dc.w	1 ;0 ;4
		dc.w	$3
		dc.w	1
		dc.l	0 ;scanimg2	;image
		dc.l	0	;scanimg
		dc.l	ggtext2
		dc.l	0
		dc.l	0
		dc.w	1
		dc.l	0
ggtext2:
		dc.b	1,0,1,0
		dc.w	8,5
		dc.l	0
		dc.l	scantxt2
		dc.l	0
scantxt2:
		dc.b	'Cancel',0
		cnop	0,4
scanimg2:
		dc.w	0,0
		dc.w	64,18
		dc.w	1
		dc.l	scandata
		dc.b	2,1
		dc.l	0
scangad3:
		dc.l	0
		dc.w	55,25,200,18
		dc.w	0 ;0 ;4
		dc.w	1
		dc.w	4
		dc.l	0 ;scanimg	;image
		dc.l	0	;scanimg
		dc.l	ggtext3
		dc.l	0
		dc.l	stringinfo
		dc.w	1
		dc.l	0
ggtext3:
		dc.b	1,0,1,0
		dc.w	-40,0
		dc.l	0
		dc.l	savetxt3
		dc.l	0
savetxt3:
		dc.b	'File',0
		cnop	0,4
stringinfo:
		dc.l	bfilename
		dc.l	bfilename2
		dc.w	0
		dc.w	50
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.l	0
		dc.l	0
		dc.l	0
		dc.l	0

bfilename:	dc.b	'SaveImage',0
		cnop	0,2
		dc.l	0,0,0,0,0,0,0,0,0,0,0,0
bfilename2:	dc.b	'SaveImage',0
		cnop	0,2
		dc.l	0,0,0,0,0,0,0,0,0,0,0,0

scandata:
		dc.l	$ffff,$ffff
		dc.l	$ffff,$ffff
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$c000,$0003
		dc.l	$ffff,$ffff
		dc.l	$ffff,$ffff


		cnop	0,4

;--- Menu Data --------------------
file:		dc.l	baud		;pointer to next menu
		dc.w	10,30		;X/Y
		dc.w	70,10		;Width/Height
		dc.w	1		;Menu Enabled
		dc.l	filename	;Menu title
		dc.l	fileitem01	;Menu entry
		dc.w	0,0,0,0
filename:
		dc.b	'Project',0
		cnop	0,2
baud:
		dc.l	Resolution
		dc.w	100,0		;X/Y
		dc.w	50,10		;Width/Height
		dc.w	1		;enable
		dc.l	baudname
		dc.l	bauditem01
		dc.w	0,0,0,0

baudname:
		dc.b	'Baud',0
		cnop	0,2
Resolution:
		dc.l	Contrst
		dc.w	170,0		;X/Y
		dc.w	88,10		;Width/Height
		dc.w	1		;enable
		dc.l	resolname
		dc.l	resolitem01
		dc.w	0,0,0,0
resolname:
		dc.b	'Resolution',0
		cnop	0,2

Contrst:
		dc.l	0
		dc.w	280,0		;X/Y
		dc.w	88,10		;Width/Height
		dc.w	1		;enable
		dc.l	contrastname
		dc.l	contrastitem01
		dc.w	0,0,0,0
contrastname:
		dc.b	'Contrast',0
		cnop	0,2

fileitem01:
		dc.l	fileitem02
		dc.w	0,0
		dc.w	130,12
		dc.w	$56
		dc.l	0
		dc.l	scan01
		dc.l	0
		dc.b	'S',0
		dc.l	0
		dc.w	0
scan01:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	scan01txt
		dc.l	0
scan01txt:
		dc.b	'Scan Image',0
		cnop	0,2
fileitem02:
		dc.l	fileitem03
		dc.w	0,10
		dc.w	130,12
		dc.w	$56
		dc.l	0
		dc.l	save01
		dc.l	0
		dc.b	'W',0
		dc.l	0
		dc.w	0
save01:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	save01txt
		dc.l	0
save01txt:
		dc.b	'Save Image',0
		cnop	0,2
fileitem03:
		dc.l	0
		dc.w	0,20
		dc.w	130,12
		dc.w	$56
		dc.l	0
		dc.l	area01
		dc.l	0
		dc.b	'A',0
		dc.l	0
		dc.w	0
area01:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	area01txt
		dc.l	0
area01txt:
		dc.b	'Scan Area',0
		cnop	0,2


bauditem01:
		dc.l	bauditem02
		dc.w	0,0
		dc.w	90,12
		dc.w	$15b
		dc.l	0
		dc.l	br1
		dc.l	0
		dc.b	0,0
		dc.l	0
		dc.w	0
br1:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	br1txt
		dc.l	0
br1txt:
		dc.b	'  19200',0
		cnop	0,2
bauditem02:
		dc.l	bauditem03
		dc.w	0,10
		dc.w	90,12
		dc.w	$5b
		dc.l	0
		dc.l	br2
		dc.l	0
		dc.b	0,0
		dc.l	0
		dc.w	0
br2:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	br2txt
		dc.l	0
br2txt:
		dc.b	'   9600',0
		cnop	0,2
bauditem03:
		dc.l	bauditem04
		dc.w	0,20
		dc.w	90,12
		dc.w	$5b
		dc.l	0
		dc.l	br3
		dc.l	0
		dc.b	0,0
		dc.l	0
		dc.w	0
br3:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	br3txt
		dc.l	0
br3txt:
		dc.b	'   4800',0
		cnop	0,2
bauditem04:
		dc.l	0
		dc.w	0,30
		dc.w	90,12
		dc.w	$5b
		dc.l	0
		dc.l	br4
		dc.l	0
		dc.b	0,0
		dc.l	0
		dc.w	0
br4:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	br4txt
		dc.l	0
br4txt:
		dc.b	'   2400',0
		cnop	0,2

resolitem01:
		dc.l	resolitem02
		dc.w	0,0
		dc.w	120,12
		dc.w	$5f
		dc.l	0
		dc.l	resol1
		dc.l	0
		dc.b	'1',0
		dc.l	0
		dc.w	0
resol1:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	res1txt
		dc.l	0
res1txt:
		dc.b	'  300 DPI',0
		cnop	0,2
resolitem02:
		dc.l	resolitem03
		dc.w	0,10
		dc.w	120,12
		dc.w	$5f
		dc.l	0
		dc.l	resol2
		dc.l	0
		dc.b	'2',0
		dc.l	0
		dc.w	0
resol2:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	res2txt
		dc.l	0
res2txt:
		dc.b	'  240 DPI',0
		cnop	0,2
resolitem03:
		dc.l	resolitem04
		dc.w	0,20
		dc.w	120,12
		dc.w	$5f
		dc.l	0
		dc.l	resol3
		dc.l	0
		dc.b	'3',0
		dc.l	0
		dc.w	0
resol3:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	res3txt
		dc.l	0
res3txt:
		dc.b	'  200 DPI',0
		cnop	0,2
resolitem04:
		dc.l	resolitem05
		dc.w	0,30
		dc.w	120,12
		dc.w	$5f
		dc.l	0
		dc.l	resol4
		dc.l	0
		dc.b	'4',0
		dc.l	0
		dc.w	0
resol4:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	res4txt
		dc.l	0
res4txt:
		dc.b	'  150 DPI',0
		cnop	0,2
resolitem05:
		dc.l	resolitem06
		dc.w	0,40
		dc.w	120,12
		dc.w	$5f
		dc.l	0
		dc.l	resol5
		dc.l	0
		dc.b	'5',0
		dc.l	0
		dc.w	0
resol5:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	res5txt
		dc.l	0
res5txt:
		dc.b	'  120 DPI',0
		cnop	0,2
resolitem06:
		dc.l	resolitem07
		dc.w	0,50
		dc.w	120,12
		dc.w	$15f
		dc.l	0
		dc.l	resol6
		dc.l	0
		dc.b	'6',0
		dc.l	0
		dc.w	0
resol6:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	res6txt
		dc.l	0
res6txt:
		dc.b	'  100 DPI',0
		cnop	0,2
resolitem07:
		dc.l	0
		dc.w	0,60
		dc.w	120,12
		dc.w	$5f
		dc.l	0
		dc.l	resol7
		dc.l	0
		dc.b	'7',0
		dc.l	0
		dc.w	0
resol7:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	res7txt
		dc.l	0
res7txt:
		dc.b	'   75 DPI',0
		cnop	0,2


contrastitem01:
		dc.l	contrastitem02
		dc.w	0,0
		dc.w	130,12
		dc.w	$5b
		dc.l	0
		dc.l	contr1
		dc.l	0
		dc.b	0,0
		dc.l	0
		dc.w	0
contr1:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	contr1txt
		dc.l	0

contrastitem02:
		dc.l	contrastitem03
		dc.w	0,10
		dc.w	130,12
		dc.w	$5b
		dc.l	0
		dc.l	contr2
		dc.l	0
		dc.b	0,0
		dc.l	0
		dc.w	0
contr2:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	contr2txt
		dc.l	0

contrastitem03:
		dc.l	contrastitem04
		dc.w	0,20
		dc.w	130,12
		dc.w	$5b
		dc.l	0
		dc.l	contr3
		dc.l	0
		dc.b	0,0
		dc.l	0
		dc.w	0
contr3:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	contr3txt
		dc.l	0

contrastitem04:
		dc.l	contrastitem05
		dc.w	0,30
		dc.w	130,12
		dc.w	$5b
		dc.l	0
		dc.l	contr4
		dc.l	0
		dc.b	0,0
		dc.l	0
		dc.w	0
contr4:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	contr4txt
		dc.l	0

contrastitem05:
		dc.l	contrastitem06
		dc.w	0,40
		dc.w	130,12
		dc.w	$5b
		dc.l	0
		dc.l	contr5
		dc.l	0
		dc.b	0,0
		dc.l	0
		dc.w	0
contr5:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	contr5txt
		dc.l	0

contrastitem06:
		dc.l	0
		dc.w	0,50
		dc.w	130,12
		dc.w	$15b
		dc.l	0
		dc.l	contr6
		dc.l	0
		dc.b	0,0
		dc.l	0
		dc.w	0
contr6:
		dc.b	0,1
		dc.b	0,0
		dc.w	5,3
		dc.l	0
		dc.l	contr6txt
		dc.l	0

contr1txt:
		dc.b	'   Very Light',0
		cnop	0,2

contr2txt:
		dc.b	'   Light',0
		cnop	0,2

contr3txt:
		dc.b	'   Normal',0
		cnop	0,2

contr4txt:
		dc.b	'   Dark',0
		cnop	0,2

contr5txt:
		dc.b	'   Very Dark',0
		cnop	0,2

contr6txt:
		dc.b	'   By Controller',0
		cnop	0,2


;---- Polygon Info ---------------------------
poly1:		dc.w	0,10		;x,y
		dc.w	0,399
		dc.w	1,10
		dc.w	1,399
		dc.w	639,399
		dc.w	0,398
		dc.w	639,398
		dc.w	639,10
		dc.w	638,399
		dc.w	638,10
		dc.w	0,0

poly2:		dc.w	560,10
		dc.w	560,400
		dc.w	561,10
		dc.w	561,400
		dc.w	561,200
		dc.w	640,200
		dc.w	561,201
		dc.w	640,201

		dc.l	0,0,0,0,0,0,0

IFFhead:

	dc.l	$464F524D,$00007d36,$494C424D,$424D4844    ;FORM....ILBMBMHD
	dc.l	$00000014,$02800190,$00000000,$01000000    ;................
	dc.l	$0000140B,$02800190,$434D4150,$00000006    ;........CMAP....
	dc.l	$000000F0
	dc.w	$F0F0	;4450,$50530000,$006E0002    ;......DPPS...n..
;	dc.l	$00000000,$00000000,$00000000,$01680000    ;.............h..
;	dc.l	$014000C8,$0002005A,$00010000,$00010000    ;.@.....Z........
;	dc.l	$00010000,$00000000,$00000000,$00000000    ;................
;	dc.l	$00000000,$00000000,$00000000,$00000000    ;................
;	dc.l	$00000000,$00000000,$00010000,$00000000    ;................
;	dc.l	$00000000,$00000000,$00010000,$00000000    ;................
;	dc.l	$00000000,$00000000,$00010000,$43524E47    ;............CRNG
;	dc.l	$00000008,$00000AAA,$00010101,$43524E47    ;............CRNG
;	dc.l	$00000008,$00000AAA,$00010101,$43524E47    ;............CRNG
;	dc.l	$00000008,$00000AAA,$00010000,$43524E47    ;............CRNG
;	dc.l	$00000008,$00000AAA,$00010000,$43524E47    ;............CRNG
;	dc.l	$00000008,$00000000,$00010000,$43524E47    ;............CRNG
;	dc.l	$00000008,$00000000,$00010000,$43414D47    ;............CAMG
;	dc.l	$00000004,$0000C004,
	dc.l	$424F4459,$00007d00    ;........BODY....
IFFtail:



