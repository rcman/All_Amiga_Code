ctlw equ  $dff096
c0thi equ  $dff0a0
c0tlo equ  c0thi+2
c0tl equ   c0thi+4
c0per equ  c0thi+6
c0vol equ  c0thi+8

Openlib		equ 	-408
Closelib	equ	-414
Open		equ	-30
output		equ	-60
mode_old	equ	1005
IoErr		equ	-132
alloc_abs	equ	-$cc
Close		equ	-36
Write		equ	-48
Read		equ	-42
delay		equ	-198
text		equ	-54
AllocMem	equ	-198
FreeMem		equ	-210
sysbase		equ	$4

	move.l	a0,inputarg
	move.l	d0,inputlen

	move.l	sysbase,a6
	lea	dosname(pc),a1
	moveq	#0,d0
	jsr	Openlib(a6)
	move.l	d0,dosbase
	beq	error
	
;	jsr	output(a6)
;	move.l	d0,conhandle
;	beq	errordos


	bsr	writefile




endpgm:
errordos:
	move.l	dosbase,a1
	move.l	sysbase,a6
	jsr	Closelib(a6)
error:
	rts

writefile:
	movem.l	d0-d7/a0-a6,-(sp)

	lea	filename(pc),a0
	move.l	a0,d1
	move.l	#1006,d2
	move.l	dosbase,a6
	jsr	Open(a6)
	move.l	d0,filehandle
	beq.s	nosavemsg

	move.l	d0,d1
	move.l	inputarg,d2
	move.l	inputlen,d3
	move.l	dosbase,a6
	jsr	Write(a6)

	move.l	filehandle,d1
	move.l	dosbase,a6
	jsr	Close(a6)

nosavemsg:
	movem.l	(sp)+,d0-d7/a0-a6
	rts


dosbase:	dc.l	0
inputarg:	dc.l	0
inputlen:	dc.l	0
filehandle:	dc.l	0
conhandle:	dc.l	0

dosname:
		dc.b	'dos.library',0,0
		cnop 0,2
filename:
		dc.b	':s/msg'
process:	dc.b	'1',0
		cnop	0,2


	end



