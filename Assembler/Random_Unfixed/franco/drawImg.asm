; This program loads a screen, lifts a block from the screen then uses that 
; block to make a srceen design using a table listed at the bottom of this
; program. The table can be changed to form any shap on the screem.

; Written By: Sean Godsell, Franco Gaetan
; Date of Last Revision: June 8, 1991
; File DrawImg.ASM
; Status: Working 


movescreen	equ	-162
openscreen	equ	-198
closescreen	equ	-66
openwindow	equ	-204
closewindow	equ	-72
autorequest	equ 	-348
setmenustrip	equ	-264
clearmenustrip	equ	-54
printitext	equ	-216
drawimage	equ	-114
drawborder	equ	-108
displaybeep	equ	-96
closelibrary	equ	-414
openlib		equ	-408
execbase	equ	4
getmsg		equ	-372

joy2		equ	$dff0c
fire		equ	$bfe001

run:
	bsr	openint
	bsr	scropen
	bsr	windopen
	bsr	draw
nope:
	bra 	nope


	bsr	MouseCheck

ende:
	bsr	windclose
	bsr	scrclose

	bsr	closeint
	clr.l	d0
	rts

openint:
	move.l	execbase,a6
	lea	intname,a1
	jsr	openlib(a6)
	move.l	d0,intbase
	rts

closeint:
	move.l	execbase,a6
	move.l	intbase,a1
	jsr	closelibrary(a6)
	rts

scropen:
	move.l	intbase,a6
	lea	screen_defs,a0
	jsr	openscreen(a6)
	move.l	d0,screenhd
	rts

scrclose:
	move.l	intbase,a6
	move.l	screenhd,a0
	jsr	closescreen(a6)
	rts

scrmove:
	move.l	intbase,a6
	move.l	screenhd,a0
	jsr	movescreen(a6)
	rts

windopen:
	move.l	intbase,a6
	lea	windowdef,a0
	jsr	openwindow(a6)
	move.l	d0,windowhd
	move.l	d0,a0
	move.l	50(a0),rastport
	rts

windclose:
	move.l	intbase,a6
	move.l	windowhd,a0
	jsr	closewindow(a6)
	rts

MouseCheck:

	btst.b	#6,$bfe001
	bne	MouseCheck
	rts

draw:
	move.l	intbase,a6
	move.l	rastport,a0		; Rastport
	lea	image(pc),a1
	move.l	#100,d0
	move.l	#150,d1	
	jsr	drawimage(a6)
	rts
	
rastport:	dc.l	0
	
screen_defs:
	dc.w	0,0
	dc.w	320,200
	dc.w	4
	dc.b	0
	dc.b	1
	dc.w	$800
	dc.w	15
	dc.l	0
	dc.l	titel
	dc.l	0
	dc.l	0

windowdef:

	dc.w	10,20
	dc.w	300,150
	dc.b	0,1
	dc.l	$300
	dc.l	$100f
	dc.l	0
	dc.l	0
	dc.l	windname
screenhd:
	dc.l	0
	dc.l	0
	dc.w	200,40,600,200
	dc.w	$f

titel:		dc.b	'User Screen',0
	cnop	0,2
windname:	dc.b	'Window-Title',0
	cnop	0,2

intbase		dc.l	0
	cnop	0,2

intname		dc.b	'intuition.library',0
	cnop	0,2

image:	
		dc.w	0,0
		dc.w	5,13
		dc.w	1
		dc.l	imgdata
		dc.b	2,1
		dc.l	0

image2:
		dc.w	0,0
		dc.w	32,13
		dc.w	1
		dc.l	imgdata
		dc.b	1,0
		dc.l	0
	cnop	0,2

imgdata:	dc.l	$ffffffff
		dc.l	$ffffffff
		dc.l	$ffffffff
		dc.l	$ffffffff
		dc.l	$ffffffff
		dc.l	$ff11ffff
		dc.l	$ff11ffff
		dc.l	$ff11ffff
		dc.l	$ff11ffff
		dc.l	$ffffffff
		dc.l	$ffffffff
		dc.l	$ffffffff
		dc.l	$ff22ffff
		dc.l	$ff22ffff
		dc.l	$ff33ffff
	cnop	0,2

imgdata2:	
		dc.l	%00000000000000000000111000000000
		dc.l	%00011101110111000001111100000000
		dc.l	%00011101110111000001111100000000
		dc.l	%00011101110111000001111100000000
		dc.l	%00011101110111000001111100000000
		dc.l	%00011101110111000001111100000000
		dc.l	%00011101110111000001111100000000
		dc.l	%00011101110111000001111100000000
		dc.l	%00011101110111000001111100000000
		dc.l	%00011101110111000001111100000000
		dc.l	%00011101110111000001111100000000
		dc.l	0
	cnop	0,2

windowhd:	dc.l	0


	end

	
		







