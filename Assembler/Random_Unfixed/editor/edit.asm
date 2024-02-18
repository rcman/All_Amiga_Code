;hello sean
supervisor	equ	-30
sysbase		equ	4
superstate	equ	-150
userstate	equ	-156
open		equ	-30
close		equ	-36
write		equ	-48
read		equ	-42
output		equ	-60
Delay		equ	-198
openlib		equ	-408
closelib	equ	-414
AllocMem	equ	-198
FreeMem		equ	-210

serwrt		equ	$dff030
IntREQW		equ	$dff09c
serreg		equ	$dff01e
serbaud		equ	$dff032
serdatr		equ	$dff018
serdat		equ	$dff030

level5		equ	$74
mode_new	equ	1006

lfcramt		equ	2

;-------------------------------------------------------------------
lookatinp:
	movem.l	d0-d7/a0-a6,-(sp)

	move.l	a0,parmp		;save parameter ptr
	move.l	d0,parml		;save parameter length

; Open the Dos Base
	move.l	sysbase,a6
	lea	dosname(pc),a1
	jsr	openlib(a6)		;open dos library
	move.l	d0,dosbase
	beq	error

; Get Current Output Handle (the Console)
	move.l	d0,a6
	jsr	output(a6)
	move.l	d0,outhandle		;get current output handle
	beq	error2

;--- Allocate Memory -----------------------

	move.l	sysbase,a6
	move.l	#140000,d0
	move.l	#$10001,d1
	jsr	AllocMem(a6)		;allocate ram for edit space
	move.l	d0,Memareasave
	beq	error2
	move.l	d0,a0
	move.w	#0,(a0)+
	move.l	a0,Memarea
	move.l	a0,memendp
	move.l	a0,lineptrs
	move.l	a0,lineptre

;--- set up the serial interupt ------------
	move.l	level5,jmploc+2		;setup patch for jump
	lea	serinter(pc),a1
	move.l	a1,level5		;set up serial int.
	move.w	#$800,$dff09c		;clear serial inter req
;	move.w	#$3fff,$bfd0fe		;init handshake lines
;	move.w	#$8800,$dff09a		;enable serial inter

	bsr	clearscreen

; check to see if we need a file --------------
	move.l	parmp,a1
	move.l	parml,d0
	lea	filename(pc),a0		;file name ptr

	cmp.b	#0,d0
	beq.s	mainloop

checkf:
	cmp.b	#0,(a1)
	beq.s	donechckf
	cmp.b	#10,(a1)
	beq.s	donechckf
	cmp.b	#13,(a1)
	beq.s	donechckf
	move.b	(a1)+,(a0)+
	dbra	d0,checkf

donechckf:
	move.b	#0,(a1)
	move.b	#0,(a0)
	bsr	loadfilename

; mainloop the program ------------------------

mainloop:
	bsr	GetKey		;get a keystroke

; Process Special Keys ----------------------

	cmp.b	#27,d0		;ESC Key
	bne.s	noesc
	bsr	Checkesc
noesc:
	cmp.b	#13,d0		;New line
	bne.s	nocr
	bsr	newline
	nop
	nop
	nop
nocr:
	cmp.b	#17,d0		;Quit  Ctrl Q
	bne.s	noquit
	bra	Exit
noquit:
	cmp.b	#9,d0		;tab over
	bne.s	notab
	bra	doachar
notab:
	cmp.b	#127,d0		;delete a char
	bne.s	nodelete
	bsr	deletechar
nodelete:
	cmp.b	#10,d0		;down cursor  CTRL J
	bne.s	nodown
	bsr	godown
nodown:
	cmp.b	#26,d0		;up cursor  CTRL Z
	bne.s	noup
	bsr	goup
noup:
	cmp.b	#6,d0		;left cursor  CTRL F
	bne.s	noright
	bsr	goright
noright:
	cmp.b	#21,d0		;right cursor  CTRL U
	bne.s	noleft
	bsr	goleft
noleft:
	cmp.b	#8,d0		;back space or CTRL H
	bne.s	nobackspace
	bsr	backspace
nobackspace:
	cmp.b	#1,d0		;Ctrl A - insert mode
	bne.s	noinsert
	add.l	#1,ins
	cmp.l	#2,ins
	bne.s	noinsert
	move.l	#0,ins
noinsert:

	cmp.b	#127,d0
	beq	mainloop
	cmp.b	#31,d0
	ble	mainloop

doachar:
	move.l	cols,d2
	cmp.l	#78,d2
	bge	mainloop

; Process the Letters that are coming in ----

;	lea	prtchr(pc),a1	;Pointer to text
;	moveq	#1,d3		;length to print
;	bsr	printtext

	lea	linebuff(pc),a1		;buffer ptr
	move.w	#299,d3			;buffer length
	move.l	cols,d2			;offset inside buffer
	cmp.l	#0,ins			;check insert mode
	bne.s	noinserting

	
movetextup:
	move.b	0(a1,d3.w),1(a1,d3.w)
	cmp.w	d2,d3
	beq.s	getoutofmove
	dbra	d3,movetextup
getoutofmove:

noinserting:
	move.b	d0,0(a1,d2.w)
	
	add.l	#1,d2
	move.l	d2,cols
	move.l	d2,tcols

	bsr	printaline
	bsr	calcwhereonline

	bsr	printcolumn
	bra	mainloop

; Go up with cursor --------------------------
goup:
	movem.l	d0-d7/a0-a5,-(sp)
	move.l	line,d1
	add.l	sline,d1
	cmp.l	#1,d1
	ble	endup

	move.w	#0,flag

	sub.l	#1,sline
	move.l	sline,d1
	cmp.l	#1,d1
	bge	noscrolluping

	move.l	#1,sline
	sub.l	#1,line

	move.w	#1,flag

	bsr	printaupline
	bra	continueup

noscrolluping:
	lea	upcursor(pc),a1
	moveq	#eupcursor-upcursor,d3
	bsr	printtext

	bsr	clearinputbuff
	bsr	findlineb

continueup:

;  c=tc  
;  IF c>LEN(text$(sl+l)) THEN c=LEN(text$(sl+l))
;  IF c>15 THEN tmp=INT(c/10)*6 ELSE tmp=0

	move.l	tcols,cols
	move.l	lengthofline,d0
	cmp.l	cols,d0
	bgt	nochgcols2

	move.l	d0,cols
nochgcols2:


	move.l	lineptrs,a0
	lea	linebuff(pc),a1
	move.l	lengthofline,d0
	beq.s	nomoveofdata2
movedatatobuff2:
	move.b	(a0)+,(a1)+
	dbra	d0,movedatatobuff2
nomoveofdata2:
	
	bsr	calcwhereonline
	bsr	printcolumn
;  PRINT #1,CHR$(16);CHR$(c+tmp);

endup:
	movem.l	(sp)+,d0-d7/a0-a5
	rts

; Go down with cursor ------------------------
godown:
	movem.l	d0-d7/a0-a5,-(sp)
	move.l	rows,d2
	move.l	sline,d1
	add.l	line,d1

	cmp.l	d2,d1
	bge	enddown
;  IF a$=CHR$(10) AND sl+l<999 AND sl+l<r THEN GOSUB godown

;	move.l	d2,d0
;	moveq	#7,d1
;	bsr	printhexnum

	add.l	#1,sline
	move.l	sline,d1
	cmp.l	#24,d1
	ble	noscrolldowning

	move.l	#24,sline
	add.l	#1,line

	move.w	#1,flag

	bsr	clearinputbuff

	bsr	printadownline
	bra	continuedown

noscrolldowning:
	lea	downcursor(pc),a1
	moveq	#edowncursor-downcursor,d3
	bsr	printtext

	bsr	clearinputbuff
	bsr	findlinef

continuedown:

	move.l	lineptrs,a0
	lea	linebuff(pc),a1
	move.l	lengthofline,d0
	beq.s	nomoveofdata
movedatatobuff:
	move.b	(a0)+,(a1)+
	dbra	d0,movedatatobuff
nomoveofdata:

;  c=tc  
;  IF c>LEN(text$(sl+l)) THEN c=LEN(text$(sl+l))
;  IF c>15 THEN tmp=INT(c/10)*6 ELSE tmp=0

	move.l	tcols,cols

	move.l	cols2,d1
	bsr	calclinecol

	move.l	newcols,cols

;	move.l	lengthofline,d0
;	cmp.l	cols,d0
;	bgt	nochgcols
;	move.l	d0,cols
;nochgcols:

	bsr	calcwhereonline
	bsr	printcolumn
;  PRINT #1,CHR$(16);CHR$(c+tmp)

enddown:
	movem.l	(sp)+,d0-d7/a0-a5
	rts

; Go right with cursor ------------------------
goright:
	movem.l	d0-d7/a0-a5,-(sp)
	move.l	cols,d2

	bsr	checklength
	cmp.w	d1,d2
	bge.s	endgoright

	cmp.l	#78,d2
	bge.s	endgoright

	add.l	#1,d2
	move.l	d2,cols
	move.l	d2,tcols

;	lea	rightcursor(pc),a1	;Pointer to text
;	moveq	#erightcursor-rightcursor,d3		;length to print
;	bsr	printtext
	bsr	calcwhereonline
	bsr	printcolumn
endgoright:
	movem.l	(sp)+,d0-d7/a0-a5
	moveq	#0,d0
	rts

; Go left with cursor ------------------------
goleft:
	movem.l	d0-d7/a0-a5,-(sp)
	move.l	cols,d2
	cmp.l	#0,d2
	ble.s	endgoleft

	sub.l	#1,d2
	move.l	d2,cols
	move.l	d2,tcols

;	lea	leftcursor(pc),a1	;Pointer to text
;	moveq	#eleftcursor-leftcursor,d3		;length to print
;	bsr	printtext

	bsr	calcwhereonline
	bsr	printcolumn

endgoleft:
	movem.l	(sp)+,d0-d7/a0-a5
	moveq	#0,d0
	rts

; Tab over ---------------------------------------------------
tabover:
	movem.l	d0-d7/a0-a5,-(sp)


endtabover:
	movem.l	(sp)+,d0-d7/a0-a5
	moveq	#0,d0
	rts


; New Line ---------------------------------------------------

newline:
	movem.l	d0-d7/a0-a5,-(sp)
	add.l	#1,rows			;add 1 to rows
	add.l	#1,sline		;add 1 to screen line row
	move.l	sline,d1
	cmp.l	#24,d1			;is screen row at bottom
	ble.s	printcr

	add.l	#1,line
	move.l	#24,sline		;make screen line row at 24 consant

printcr:
	bsr	checklength		;get length of line in D1

	move.l	d1,d4			;put length of line in reg D4

	move.l	memendp,a1		;memory end ptr
	move.l	lineptre,a2		;line end memory ptr
	cmp.l	a1,a2			;is line end = to memory end
	bne	bypassputlineinmem	;if = put line in memory

	add.l	d1,a1
	add.l	#1,a1			;add the line feed, cr # to ptr
	move.l	a1,memendp
	bra	putlineinmem

bypassputlineinmem:
	move.l	lengthofline,d0		;length of current line
	sub.l	d0,d1			;subtract length of curr line into new line length
	beq	putlineinmem		;save line to memory no length chg
	bgt.s	addtomemptr

; move mem back d1 bytes ----------
	move.l	lineptrs,d0
	bsr	printhexnum2
	move.l	lineptre,d0
	bsr	printhexnum2
prepareforline:
	move.b	0(a2),0(a2,d1.l)
	addq.l	#1,a2
	cmp.l	a2,a1
	bne.s	prepareforline

	move.l	d1,d2
	neg.l	d2
	add.l	d2,a1			;add to end mem ptr
	move.l	a1,memendp
	bra.s	calcstorage

; move mem up d1 bytes ------------
addtomemptr:
	add.l	d1,memendp
	move.l	lineptrs,d0
	bsr	printhexnum2
	move.l	lineptre,d0
	bsr	printhexnum2
	move.l	memendp,d0
	bsr	printhexnum2
	move.l	lineptre,a2		;current memory line ptr (end)
prepareforline2:
	move.b	0(a1),0(a1,d1.w)
	subq.l	#1,a1
	cmp.l	a2,a1
	bne.s	prepareforline2

calcstorage:

putlineinmem:
	lea	linebuff(pc),a0		;get line buffer ptr
	move.l	lineptrs,a1		;get line start ptr
	cmp.w	#0,d4
	beq.s	endputlineinmem

putlineinmemd:
	move.b	(a0)+,(a1)+		;move buffer data to line start 
	dbra	d4,putlineinmemd
endputlineinmem:

	subq.l	#2,a1
	move.l	a1,lineptre		save line end ptr
	addq.l	#1,a1
	move.b	#10,(a1)		;save line feed

	bsr	findlinef

	bsr	printcrlf
	bsr	clearinputbuff

	move.l	#0,cols			;clear col
	move.l	#0,tcols

	movem.l	(sp)+,d0-d7/a0-a5
	moveq	#0,d0
	rts


;--- delete character ------------------------------------
deletechar:
	movem.l	d0-d7/a0-a5,-(sp)

	lea	linebuff(pc),a1		;buffer ptr
	move.l	cols,d2			;offset inside buffer
movetextback3:
	move.b	1(a1,d2.w),0(a1,d2.w)
	addq.l	#1,d2
	cmp.w	#298,d2
	bne.s	movetextback3

	bsr	printaline
	bsr	printaspace
	bsr	calcwhereonline
	bsr	printcolumn

enddeletechar:
	movem.l	(sp)+,d0-d7/a0-a5
	moveq	#0,d0
	rts


;--- back space ------------------------------------------
backspace:
;  text$(sl+l)=LEFT$(text$(sl+l),c-1)+MID$(text$(sl+l),c+1,80)
;  c=c-1
;  tc=c
;  printwhereonline:
;  IF c>15 THEN tmp=INT(c/10)*6 ELSE tmp=0
;  PRINT #1,CHR$(13);text$(sl+l);" ";CHR$(16);CHR$(c+tmp);
;  RETURN

	movem.l	d0-d7/a0-a5,-(sp)
	move.l	cols,d2
	cmp.l	#0,d2
	ble.s	endbackspace

	subq.l	#1,d2
	move.l	d2,cols
	move.l	d2,tcols

	lea	linebuff(pc),a1

movetextback:
	move.b	1(a1,d2.w),0(a1,d2.w)
	addq.l	#1,d2
	cmp.w	#298,d2
	bne.s	movetextback

	bsr	printaline
	bsr	printaspace
	bsr	calcwhereonline

	bsr	printcolumn

endbackspace:
	movem.l	(sp)+,d0-d7/a0-a5
	moveq	#0,d0
	rts

;--- clear the keyboard input area -----------------------
clearinputbuff:
	movem.l	d2-d3/a1,-(sp)
	lea	linebuff(pc),a1
	move.w	#299,d3
	moveq	#0,d2

nullinput:
	move.b	d2,(a1)+
	dbra	d3,nullinput

	move.l	#0,lengthofline
	movem.l	(sp)+,d2-d3/a1
	rts


; Find Next line forwards -----------------------

findlinef:
	move.l	lineptre,a1		;get end line ptr
       	moveq	#0,d1
       	moveq	#lfcramt,d2
finderokf:
	cmp.b	#0,(a1)
	beq.s	jumpoutfindf

	cmp.b	#10,(a1)
	bne.s	contforwf
	subq.l	#1,d2
	cmp.b	#10,1(a1)
	bne.s	contforwf

	addq.l	#1,a1
	move.l	a1,lineptrs
	bra.s	jumpoutfindf

contforwf:
	add.l	d2,a1
	move.l	a1,lineptrs		;save to start line ptr
	cmp.b	#10,(a1)
	beq.s	jumpoutfindf

finderokf2:
	cmp.b	#0,(a1)
	beq.s	lookahead2
	cmp.b	#10,(a1)
	beq.s	lookahead2
	cmp.b	#13,(a1)
	beq.s	lookahead2
	addq.l	#1,d1
	addq.l	#1,a1
	bra.s	finderokf2
lookahead2:
	subq.l	#1,a1

	cmp.l	#0,d1
	beq.s	jumpoutfindf
	subq.l	#1,d1

jumpoutfindf:
	move.l	a1,lineptre
	move.l	d1,lengthofline
	rts


; Find Next line backwards -----------------------

findlineb:
	move.l	lineptrs,a1		; get start line ptr
	move.l	Memarea,a2
	moveq	#0,d1
finderokb:
	cmp.b	#0,(a1)
	beq.s	jumpoutfindb

	cmp.b	#10,-2(a1)
	beq.s	gotfindb
	cmp.b	#0,-2(a1)
	bne.s	contbackw
gotfindb:
	subq.l	#1,a1
	move.l	a1,lineptre
	bra.s	jumpoutfindb

contbackw:
	subq.l	#lfcramt,a1
	cmp.l	a2,a1
	ble.s	jumpoutfindb

	move.l	a1,lineptre

finderokb2:
	cmp.b	#0,(a1)
	beq.s	lookback2
	cmp.b	#10,(a1)
	beq.s	lookback2
	cmp.b	#13,(a1)
	beq.s	lookback2
	addq.l	#1,d1
	subq.l	#1,a1
	bra.s	finderokb2
lookback2:
	addq.l	#1,a1

	cmp.l	#0,d1
	beq.s	jumpoutfindb
	subq.l	#1,d1

jumpoutfindb:	
	move.l	a1,lineptrs
	move.l	d1,lengthofline
	rts


;----------------------------------------
; Check the length of a line and return length in D1
checklength:
	movem.l	d2/a1,-(sp)
	lea	linebuff(pc),a1
	move.w	#299,d2
	moveq	#0,d1

checklenght:
	cmp.b	#0,0(a1,d1.w)
	beq.s	getoutofchk
	addq.w	#1,d1
	dbra	d2,checklenght
getoutofchk:
	movem.l	(sp)+,d2/a1
	rts

; Process Escape Keys ------------------

Checkesc:
	bsr	GetKey		;get a keystroke
;check keys
	cmp.b	#'L',d1
	bne.s	noload
	bsr	loadfile
	moveq	#27,d0
noload:
	cmp.b	#'S',d1
	bne.s	nosave
	bsr	savefile
	moveq	#27,d0
nosave:
	cmp.b	#'4',d0		;left cursor
	bne.s	noleft2
	bsr	goleft
noleft2:
	cmp.b	#'6',d0		;right cursor
	bne.s	noright2
	bsr	goright
noright2:
	cmp.b	#'8',d0		;up cursor
	bne.s	noup2
	bsr	goup
noup2:
	cmp.b	#'2',d0		;down cursor
	bne.s	nodown2
	bsr	godown
nodown2:

	cmp.b	#27,d0
	bne	Checkesc

	moveq	#0,d0		;clear keycode
	rts

; Get a Keystroke ----------------------------------------
;	d0=raw key
;	d1=upper case letter

GetKey:
	move.b	inputbuf,d0
	bne.s	nodelay

	moveq	#2,d1
	move.l	dosbase,a6
	jsr	Delay(a6)
	bra.s	GetKey
nodelay:
	move.b	#0,inputbuf	;clear buffer
	move.b	d0,prtchr

	move.b	d0,d1
	and.b	#$df,d1		;Make upper case
	rts

;--------------------------------------------------------------------
calclinecol:
	movem.l	d1-d7/a0-a5,-(sp)

	moveq	#0,d0
	moveq	#0,d2

	cmp.l	#0,d1
	beq.s	nocalconline2

	lea	linebuff(pc),a0
calcit2:
	cmp.b	#0,(a0)
	beq.s	nocalconline2

	cmp.b	#9,(a0)+
	bne.s	notabchar2

	move.l	d0,d4
	divu	#8,d4
	swap	d4
	moveq	#8,d6
	sub.b	d4,d6
	add.l	d6,d0
**
	subq.w	#1,d0

notabchar2:
	addq	#1,d2

	addq	#1,d0
	subq	#1,d1

	cmp.l	cols,d0
	blt.s	calcit2

nocalconline2:
	move.l	d2,newcols
	movem.l	(sp)+,d1-d7/a0-a5
	rts

;--------------------------------------------------------------------
calcwhereonline:
	movem.l	d0-d7/a0-a5,-(sp)
	move.l	cols,d0

	move.l	#0,cols2

	cmp.l	#0,d0
	beq.s	setcols

	lea	linebuff(pc),a0
	moveq	#0,d1
calcit:
	cmp.b	#9,(a0)+
	bne.s	notabchar

	move.l	d1,d4
	divu	#8,d4
	swap	d4
	moveq	#8,d6
	sub.b	d4,d6
	add.l	d6,d1
**
	subq.w	#1,d1

notabchar:
	addq	#1,d1
	subq	#1,d0
	bne.s	calcit	

	clr.l	d0
	move.b	d1,d0
	move.l	d1,cols2

setcols:
	move.b	d0,setcursorcol+2
	cmp.w	#15,d0
	ble.s	nocalconline

	divu.w	#10,d0
	swap	d0
	move.w	#0,d0
	swap	d0
	mulu.w	#6,d0
	add.b	d0,setcursorcol+2

nocalconline:
	movem.l	(sp)+,d0-d7/a0-a5
	rts

; print a line down -----------------------------------------------
printadownline:
	movem.l	d0-d7/a0-a5,-(sp)

	lea	downcursor(pc),a1	;Pointer to text
	moveq	#1,d3
	bsr	printtext

	bsr	findlinef

	move.l	lineptrs,a0
	lea	linebuff(pc),a1
	move.l	lengthofline,d0
	beq.s	nomoveofdat
movedatatobuf:
	move.b	(a0)+,(a1)+
	dbra	d0,movedatatobuf
nomoveofdat:

	bsr	printaline
	movem.l	(sp)+,d0-d7/a0-a5
	rts

; print a line down -----------------------------------------------
printaupline:
	movem.l	d0-d7/a0-a5,-(sp)

	bsr	clearinputbuff

	bsr	findlineb

	move.l	lineptrs,a2
	move.l	lineptre,a3
	move.l	lengthofline,d0
	movem.l	d0-d7/a0-a5,-(sp)

;	bsr	findlineb

	bsr	clearscreen

	bsr	print24lines

	bsr	clearinputbuff

	movem.l	(sp)+,d0-d7/a0-a5
	move.l	a2,lineptrs
	move.l	a3,lineptre
	move.l	d0,lengthofline

	move.l	lineptrs,a0
	lea	linebuff(pc),a1
	move.l	lengthofline,d0
	beq.s	nomoveofda
movedatatobu:
	move.b	(a0)+,(a1)+
	dbra	d0,movedatatobu
nomoveofda:

	bsr	printaline
	movem.l	(sp)+,d0-d7/a0-a5
	rts

; print out a line of data ----------------------------------------
printaline:
	movem.l	d0-d7/a0-a1,-(sp)
	lea	printtextline(pc),a1
	lea	linebuff(pc),a0
	moveq	#0,d3
	moveq	#0,d5

checkendofline:
	cmp.b	#0,0(a0,d5.w)
	beq.s	gotendofline

	cmp.b	#9,0(a0,d5.w)
	bne.s	notabss

	move.l	d3,d4
	divu	#8,d4
	swap	d4
	moveq	#8,d6
	sub.w	d4,d6
savespaces:
	move.b	#' ',1(a1,d3.w)
	addq	#1,d3
	subq.w	#1,d6
	bne.s	savespaces
	subq	#1,d3
	bra.s	bypasstabs
notabss:
	move.b	0(a0,d5.w),1(a1,d3.w)
bypasstabs:

	cmp.w	#78,d3
	bge.s	gotendofline
	addq	#1,d3
	addq	#1,d5
	bra.s	checkendofline

gotendofline:

	moveq	#8,d6
padwithspc:
	cmp.b	#78,d3
	beq.s	nomorepadding
	move.b	#' ',1(a1,d3.w)
	addq	#1,d3
	dbra	d6,padwithspc
nomorepadding:
	addq	#1,d3

	bsr	printtext
	movem.l	(sp)+,d0-d7/a0-a1
	rts

;-------------------------------------
printcolumn:
	cmp.l	#10,cols2
	beq.s	print10right

	lea	setcursorcol(pc),a1
	moveq	#3,d3
	bsr	printtext
	rts

;-------------------------------------
print10right:
	lea	right10(pc),a1
	moveq	#11,d3
	bsr	printtext
	rts

-------------------------------------
printaspace:
	movem.l	d0-d7/a0-a6,-(sp)
	lea	space(pc),a1
	moveq	#1,d3
	bsr	printtext
	movem.l	(sp)+,d0-d7/a0-a6
	rts

--------------------------------------------------
Exit:
;	move.w	#$114,$dff030
;	move.w	#$800,$dff09a
	move.l	jmploc+2,a1
	move.l	a1,level5
	bsr	clearscreen

error3:
	move.l	Memareasave,a1
	move.l	#140000,d0
	move.l	sysbase,a6
	jsr	FreeMem(a6)
error2:

	move.l	sysbase,a6
	move.l	dosbase,a1
	jsr	closelib(a6)

error:
	movem.l	(sp)+,d0-d7/a0-a6
	clr.l	d0
	rts

; print a screen of text data ----------------------------------
print24lines:
	movem.l	d0-d7/a0-a6,-(sp)

	move.l	lineptrs,a4
	move.l	lineptre,a5

	moveq	#23,d7
print24:

	bsr	printaline
	cmp.b	#0,d7
	beq.s	skipcrlf
	bsr	printcrlf
skipcrlf:
	bsr	clearinputbuff

	bsr	findlinef

	move.l	lineptrs,a0
	lea	linebuff(pc),a1
	move.l	lengthofline,d0
	beq.s	nomove2
movedata2buff2:
	move.b	(a0)+,(a1)+
	dbra	d0,movedata2buff2
nomove2:

	dbra	d7,print24

	move.l	a4,lineptrs
	move.l	a5,lineptre

	bsr	topofscreen

	movem.l	(sp)+,d0-d7/a0-a6
	clr.l	d0
	rts


; Load a File From the Disk ------------------------------------
loadfile:
	
	lea	loadtext(pc),a1		;Pointer to text
	move.l	#eloadtext-loadtext,d3	;length to print
	bsr	printtext

	bsr	GetFileName
	cmp.b	#0,d2
	beq	noloading

loadfilename:
	lea	filename(pc),a1
	move.l	a1,d1
	move.l	#1005,d2
	move.l	dosbase,a6
	jsr	open(a6)

	move.l	d0,filehandle
	beq	noloading

	move.l	d0,d1
	move.l	Memarea,d2
	move.l	#$130000,d3
	move.l	dosbase,a6
	jsr	read(a6)

	move.l	Memarea,memendp
	add.l	d0,memendp
	move.l	Memarea,lineptrs

	move.l	#0,line
	move.l	#1,sline
	move.l	#0,cols
	move.l	#0,tcols

	moveq	#0,d0
	move.l	Memarea,a1
findrows:
	cmp.b	#0,(a1)
	beq.s	endrowcount
	cmp.b	#13,(a1)
	beq.s	foundaline
	cmp.b	#10,(a1)
	bne.s	checknextb
foundaline:
	addq.l	#1,d0
checknextb:
	add.l	#1,a1
	bra.s	findrows
endrowcount:
	move.l	d0,rows

	lea	linebuff(pc),a0
	move.l	Memarea,a1
findinfo1line:
	cmp.b	#0,(a1)
	beq.s	foundit
	cmp.b	#13,(a1)
	beq.s	foundit
	cmp.b	#10,(a1)
	beq.s	foundit
	move.b	(a1)+,(a0)+
	bra.s	findinfo1line
foundit:
	cmp.l	Memarea,a1
	beq.s	zerolengthok
	sub.l	#1,a1
zerolengthok:
	move.l	a1,lineptre
	sub.l	Memarea,a1
	move.l	a1,lengthofline

	bsr	checklength
	move.l	d1,lengthofline

	move.l	filehandle,d1
	move.l	dosbase,a6
	jsr	close(a6)
noloading:
	bsr	clearscreen
;	bsr	findlinef
;	bsr	findlinef
;	bsr	findlineb
;	bsr	findlineb
;	bsr	findlineb

	bsr	print24lines

	bsr	clearinputbuff


	move.l	lineptrs,a0
	lea	linebuff(pc),a1
	moveq	#0,d1
movedatastart:
	move.b	(a0)+,d0
	cmp.b	#10,d0
	beq.s	endloading
	cmp.b	#13,d0
	beq.s	endloading
	cmp.b	#0,d0
	beq.s	endloading
	addq.l	#1,d1
	move.b	d0,(a1)+
	bra.s	movedatastart
endloading:
	move.l	d1,lengthofline

	rts


; Get the file name --------------------------------------------

GetFileName:
	lea	filename(pc),a0		;file name ptr
	moveq	#0,d2			;name length
getname:
	movem.l	d2-d7/a0-a6,-(sp)
	bsr	GetKey			;get a keystroke
	movem.l	(sp)+,d2-d7/a0-a6
	cmp.b	#13,d0
	beq.s	endgetname
	cmp.b	#8,d0
	bne.s	notabs

	cmp.b	#0,d2
	beq.s	notabs
	sub.l	#1,a0
	subq.l	#1,d2
	move.b	#0,(a0)
	bsr	printbackspc
	bsr	printaspace
	bsr	printbackspc
	bra.s	getname
notabs:
	cmp.b	#31,d0
	ble.s	getname

	cmp.b	#49,d2
	beq.s	getname
	addq.l	#1,d2
	move.l	a0,a1
	move.b	d0,(a0)+
	move.b	#0,(a0)
	moveq.l	#1,d3			;length to print
	bsr	printtext
	bra.s	getname

endgetname:
	rts

; Load a File From the Disk -----------------------------------
savefile:
	
	lea	savetext(pc),a1		;Pointer to text
	move.l	#esavetext-savetext,d3	;length to print
	bsr	printtext

	bsr	GetFileName		;get a file name
	cmp.b	#0,d2
	beq.s	nosaveing

	lea	filename(pc),a1
	move.l	a1,d1
	move.l	#1006,d2
	move.l	dosbase,a6
	jsr	open(a6)
	move.l	d0,filehandle
	beq.s	nosaveing

	move.l	d0,d1
	move.l	Memarea,d2
	move.l	memendp,d3
	sub.l	d2,d3			;sub start mem ptr into end mem ptr
	move.l	dosbase,a6
	jsr	write(a6)		;save the data to disk

	move.l	filehandle,d1
	move.l	dosbase,a6
	jsr	close(a6)
nosaveing:

	bsr	clearscreen
	rts


; Clear the text screen and home the cursor -------------------

clearscreen:
	lea	clearscreentext(pc),a1		;Pointer to text
	move.l	#eclearscreentext-clearscreentext,d3	;length to print
	bsr	printtext
	rts

;*************************************
;---------------------------------------------------
serinter:
		movem.l	d0/a1,-(sp)
		btst.b	#3,$dff01e
;		 move.w	$DFF01E,d0
;		 and.w	#$800,d0
		beq.s	jmplevel5

		move.w	serdatr,d0

		move.b	d0,inputbuf

;		move.l	bufferp,a1
;		move.b	d0,(a1)+	;save serial data

;		cmp.l	buffere,a1
;		bne.s	nochange

;		move.l	buffers,a1
;nochange:
;		move.l	a1,bufferp

		move.w	#$800,IntREQW	;Clear the Receiver buffer

		movem.l	(sp)+,d0/a1
		rte

jmplevel5:
		movem.l	(sp)+,d0/a1
jmploc:
		jmp	$8000000


;*************************************

printtext:
	movem.l	d0-d7/a0-a6,-(sp)

	move.l	a1,d2			;text pointer
	move.l	outhandle,d1		;output handle
	move.l	dosbase,a6
	jsr	write(a6)

	movem.l	(sp)+,d0-d7/a0-a6
	rts

;**********************************************************
printbackspc:
	movem.l	d0-d7/a0-a6,-(sp)

	moveq	#1,d3
	lea	leftcursor(pc),a1
	move.l	a1,d2			;text pointer
	move.l	outhandle,d1		;output handle
	move.l	dosbase,a6
	jsr	write(a6)

	movem.l	(sp)+,d0-d7/a0-a6
	rts

;**********************************************************
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
	move.b	d0,prtchr
	add.b	#$30,prtchr
	lea	prtchr(pc),a1
	moveq	#1,d3
	bsr	printtext
nozeros:
	move.w	#0,d0
	swap	d0
	add.l	#2,a0
	dbra	d1,doit

gotoprtzero:
	cmp.b	#0,d2
	beq.s	dontprtlz
	move.b	#$30,prtchr
	lea	prtchr(pc),a1
	moveq	#1,d3
	bsr	printtext
dontprtlz:

	movem.l	(sp)+,d0-d7/a0-a6
	rts

; Print a Hex Number (8 digits) ------------------------------
;	D0=Binary Number
printhexnum2:
	movem.l	d0-d7/a0-a6,-(sp)
	moveq	#7,d1
	bsr	printhexnum
	bsr	printaspace
	movem.l	(sp)+,d0-d7/a0-a6
	rts

; Print a Hex Number -----------------------------------------
;	D0=Binary Number
;	D1=number of digits to print
printhexnum:
	movem.l	d0-d7/a0-a6,-(sp)
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
	move.b	d0,prtchr
	add.b	#$30,prtchr
	lea	prtchr(pc),a1
	moveq	#1,d3
	bsr	printtext
nozeros2:
	dbra	d1,doit2

	movem.l	(sp)+,d0-d7/a0-a6
	rts


; Print a Carrige Return and a Line Feed
printcrlf:
	movem.l	d0-d7/a0-a6,-(sp)
	lea	crlf(pc),a1
	moveq	#2,d3
	bsr	printtext
	movem.l	(sp)+,d0-d7/a0-a6
	rts

; set cursor a top of screen
topofscreen:
	movem.l	d0-d7/a0-a6,-(sp)
	lea	toptext(pc),a1
	moveq	#3,d3
	bsr	printtext
	movem.l	(sp)+,d0-d7/a0-a6
	rts


values:
	dc.w	10000
	dc.w	1000
	dc.w	100
	dc.w	10
	dc.w	1

dosname:
	dc.b	'dos.library',0
	cnop	0,2
loadtext:
	dc.b	11,'7',13,27,'KEnter the File Name to Load :'
eloadtext:
	cnop	0,2
space:	dc.b	' ',0
	cnop	0,2
savetext:
	dc.b	11,'7',13,27,'KEnter the File Name to Save :'
esavetext:
	cnop	0,2
toptext:
	dc.b	11,' ',13
etoptext:
	cnop	0,2
clearscreentext:
	dc.b	12
eclearscreentext:
	cnop	0,2
leftcursor:
	dc.b	8
eleftcursor:
	cnop	0,2
rightcursor:
	dc.b	6
erightcursor:
	cnop	0,2
upcursor:
	dc.b	26
eupcursor:
	cnop	0,2
downcursor:
	dc.b	$a
edowncursor:
	cnop	0,2
setcursorrow:
	dc.b	11,' '
esetcursorrow:
	cnop	0,2
setcursorcol:
	dc.b	13,16,0,0
esetcursorcol:
	cnop	0,2
right10:
	dc.b	13,6,6,6,6,6,6,6,6,6,6,0
eright10:
	cnop	0,2
prtchr:
	dc.b	0,0

crlf:
	dc.b	10,13
	cnop	0,2

dosbase:	dc.l	0
outhandle:	dc.l	0
saveserint:	dc.l	0

Memareasave:	dc.l	0
Memarea:	dc.l	0
lineptrs	dc.l	0
lineptre	dc.l	0
memendp:	dc.l	0

lengthofline	dc.l	0
sline		dc.l	1
line		dc.l	0
rows		dc.l	0
cols		dc.l	0
cols2		dc.l	0
tcols		dc.l	0
newcols		dc.l	0
ins		dc.l	0
flag		dc.w	0,0,0,0
parmp		dc.l	0
parml		dc.l	0

filehandle	dc.l	0
filename:	ds.b	60

printtextline:	dc.b	13
		ds.b	400

linebuff:	ds.b	400

	cnop	0,2

inputbuf:	dc.b	0,0
		cnop	0,4

		ds.b	500


	end

