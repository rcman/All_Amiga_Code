* Password Examine      by Sean Godsell
*
* The folling are my own includes. Now the assembler does not have
* to go out and read any includes off the disk.

sysbase		equ	4
openmylib	equ	-408           exec
closemylib	equ	-414           exec
open		equ	-30            dos
close		equ	-36            dos
write		equ	-48            dos
read		equ	-42		dos
lock		equ	-84            dos
currentdir	equ	-126           dos
keyboard	equ	$bfec01        cia
version		equ	0
quit		equ	255
ESC		equ	27

*  open up the DOS library --------------------
	movem.l	d1-d7/a0-a6,-(sp)
	move.l	sysbase,a6
	lea	dosname(pc),a1
	moveq	#0,d0
	jsr	openmylib(a6)
	move.l	d0,dosbase
	beq	openerror

* open up the raw console ---------------------
	lea	rawname(pc),a1
	move.l	a1,d1
	move.l	#1005,d2
	move.l	d0,a6
	jsr	open(a6)
	move.l	d0,rawhandle
	beq	openerror2

	move.l	d0,d1
	lea	oldbuff(pc),a1
	move.l	a1,d2
	moveq	#22,d3
	move.l	dosbase,a6
	jsr	write(a6)

* open up the password file ---------------------
	lea	passfile(pc),a1
	move.l	a1,d1
	move.l	#1005,d2
	move.l	dosbase,a6
	jsr	open(a6)
	move.l	d0,fhpass
	beq	Goodbye

	move.l	d0,d1
	lea	password(pc),a1
	move.l	a1,d2
	move.l	#255,d3
	move.l	dosbase,a6
	jsr	read(a6)

	move.l	dosbase,a6
	move.l	fhpass,d1
	jsr	close(a6)

	lea	password(pc),a0
	clr.w	d2
	move.b	(a0),d2
	addq	#1,a0
	clr.w	d1

* read keyboard directly ----------------------
readkeys:
	move.b	keyboard,d0
	btst.b	#0,d0
	bne.s	no_changek
	move.b	d0,d1
no_changek:
	btst.b	#0,d0
	beq.s	readkeys

	cmp.b	d0,d1
	beq.s	readkeys

	cmp.b	(a0)+,d0
	bne	Goodbye

	dbra	d2,getanotherkey
	bra	Verify
;no_enter:
;	lea	password(pc),a0
;	clr.w	d2
;	move.b	(a0),d2
;	addq	#1,a0
getanotherkey:
	move.b	d0,d1
	bra.s	readkeys

* read keyboard directly ----------------------
Verify:
	move.l	rawhandle,d1
	lea	verbuff(pc),a1
	move.l	a1,d2
	moveq	#22,d3
	move.l	dosbase,a6
	jsr	write(a6)

	move.b	keyboard,d0
	btst.b	#0,d0
	bne.s	no_changek
	move.b	d0,d1
no_changek:
	btst.b	#0,d0
	beq.s	readkeys

	cmp.b	d0,d1
	beq.s	readkeys

	cmp.b	(a0)+,d0
	bne	Goodbye

	dbra	d2,getanotherkey
	bra	Verify

getanotherkey:
	move.b	d0,d1
	bra.s	readkeys

password:
	ds.b	256


Goodbye:
	move.l	dosbase,a6
	move.l	rawhandle,d1
	jsr	close(a6)
openerror2:
	move.l	dosbase,a1
	move.l	sysbase,a6
	jsr	closemylib(a6)
openerror:
	movem.l	(sp)+,d1-d7/a0-a6
	clr.l	d0
	rts

* data ----------------------------------------
dosname		dc.b	'dos.library',0
		cnop	0,2
rawname		dc.b	'RAW:185/80/266/80/Security Clearence',0
		cnop	0,2
oldbuff		dc.b	12,10,'Enter Old Pass    :',0
		cnop	0,2
verbuff		dc.b	10,10,13,'Enter Verify Pass :',0
		cnop	0,2
passfile	dc.b	':S/Passwd',0
		cnop	0,4
dosbase		ds.l	1
rawhandle	ds.l	1
fhpass		ds.l	1
	end
