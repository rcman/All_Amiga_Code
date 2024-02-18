

	include ':sourcec/include/franco.i'


	OpenDos
	IFERR	ErrorDos
	OpenIntuition
	IFERR	ErrorIntuition
	OpenScreen
	IFERR   ErrorScreen
	OpenWindow
	IFERR	ErrorWindow
	OpenGraphics
	IFERR 	ErrorGfx	

	AllocMem 200000,Chip
	move.l	d0,iff_screen
	add.l	#80000,d0
	move.l	d0,images
	add.l	#1000,d0
	move.l	d0,savearea
	add.l	#10000,d0
	move.l	d0,cleararea
	add.l	#200,d0
	move.l	d0,man_data
	
	Open	filename,o
	Read	60000,iff_screen
	Close

	bsr	Init_Chip

	move.w	#100,xcor
	move.w	#100,ycor

	jsr 	unpack
	move.l	#50,val

	move.l	sysbase,a6
	jsr	forbid(a6)

	move.l	custom,a6
	move.w	#$7fff,intena(a6)	; disable all interupts
	
main:
	bsr	checkjoy

;	move.w	pxcor,d7
;	cmp.w	xcor,d7
;	bne.s   doshape
;	move.w	pycor,d7
;	cmp	ycor,d7
;	beq.s 	continue	

doshape:

	bsr	waitbeam

	bsr	Save_Screen		; save the background image
	bsr	Blit_to_backgnd		; blit the object to the screen
	bsr	heywait

continue:

	bsr	waitbeam
	bsr	Place_area				; place the background back
		
noshoot:

	btst.b	#6,ciaapra		;test fire button
	bne	main

Exit:
	move.l	sysbase,a6
	jsr	permit(a6)

	FreeMem 200000,iff_screen

EndPgm:	
	CloseGraphics
ErrorGfx:
	CloseWindow
ErrorWindow:
	CloseScreen
ErrorScreen:
	CloseIntuition
ErrorIntuition:
	CloseDos
ErrorDos:
	rts

**************************************************************************

waitbeam:
	move.l	#$dff000,a0
waitbeam2:
	move.w	6(a0),d0		;get vposition
	lsr.w	#8,d0
	cmp.w	#$7f,d0
	ble.s	waitbeam2
	rts


**************************************************************************

waitline223
	move.l	custom,a6
	btst	#4,intreqr+1(a6)	wait for vertical line 223
	beq	waitline223		interrupt set by the
	move.w	#$10,intreq(a6)		copperlist
	rts

**************************************************************************

Init_Chip:


;        Open	manname,o
;        Read	5000,man_data
;        Close


	lea	enemy(pc),a0
	move.l	images,a1		;location of bob
	move.w	#100,d0
moveenemy:
	move.b	(a0)+,(a1)+
	dbra	d0,moveenemy

	
;	move.l	images,a0
;	move.l	cleararea,a1
;	move.w	#100,d0

;makemask:

;	move.b	(a0)+,d1
;	cmp.b	#$ff,d1
;	bne.s	cmask
;	bra	moveenemy2
;cmask:
;	eor.b	#$ff,d1
;	move.b	d1,(a1)+
;	dbra	d0,makemask

	lea	enemym(pc),a0
	move.l	images,a1		;location of bob
	add.l	#100,a1
	move.w	#100,d0
moveenemy2:
	move.b	(a0)+,(a1)+
	dbra	d0,moveenemy2


	lea	enemy2(pc),a0
	move.l	images,a1		;location of bob
	add.l	#200,a1
	move.w	#100,d0
moveenemy3:
	move.b	#$0,(a1)+
	dbra	d0,moveenemy3
	rts


**************************************************************************
unpack:

	move.l	screenhd,a0

	move.l	$c0(a0),tmplane
	move.l	$c4(a0),tmplane+4
	move.l	$c8(a0),tmplane+8
	move.l	$cc(a0),tmplane+12
	move.l	$d0(a0),tmplane+16

	move.l	$c0(a0),bitplane1
	move.l	$c4(a0),bitplane2
	move.l	$c8(a0),bitplane3
	move.l	$cc(a0),bitplane4
	move.l	$d0(a0),bitplane5

	move.l	$c0(a0),bobplane1
	move.l	$c4(a0),bobplane2
	move.l	$c8(a0),bobplane3
	move.l	$cc(a0),bobplane4
	move.l	$d0(a0),bobplane5

	move.l	windowhd,a0
	move.l	intbase,a6
	jsr	viewportaddress(a6)
	move.l	a0,viewport

	move.l	iff_screen,a0
	lea	tmplane(pc),a3
	move.b	$1c(a0),d5	;num of bit planes
	move.w	#600,d1

lookcolor:
	cmp.l	#'CMAP',(a0)
	beq.s	setcolor
	add.l	#2,a0
	dbra	d1,lookcolor

setcolor:
	move.l	4(a0),d7	;length of color map
	divu	#3,d7		;num of pens
	add.l	#8,a0

	move.l	a0,a1
        move.l  viewport,a0     ;Get Pointer to View Port
        move.l  gfxbase,a6      ;get grapics base
	moveq	#0,d0		;pen number
	moveq	#0,d1		;clear r,g,b
	moveq	#0,d2
	moveq	#0,d3

setthecolor:
	move.b	(a1)+,d1	;red
	ror.b	#4,d1
	move.b	(a1)+,d2	;green
	ror.b	#4,d2
	move.b	(a1)+,d3	;blue
	ror.b	#4,d3
	movem.l	d0-d7/a0-a6,-(sp)
        jsr     setrgb4(a6)     ;set a color registor
	movem.l	(sp)+,d0-d7/a0-a6
	addq.l	#1,d0
	dbra	d7,setthecolor

	move.l	a1,a0
	move.l	a0,d0
	and.b	#$fe,d0
	move.l	d0,a0
	move.w	#600,d1

lookbody:
	cmp.l	#'BODY',(a0)
	beq.s	decompress
	add.l	#2,a0
	dbra	d1,lookbody

	rts



decompress:
;	move.l	4(a0),d7	;length of body
	move.l	#199,d7		;no. of  lines
 	add.l	#8,a0		;correct offset of data

new_plane:
	lea	tmplane(pc),a3
	move.b	d5,d4

decomscreen:
	move.l	#40,d0
	move.l	(a3),a1
		
doline:
	moveq	#0,d1
	move.b	(a0)+,d1		;read the byte of data
	bmi.s	repeat

;----- write out bytes n+1 data ------------

keepthemove:
	move.b	(a0)+,(a1)+
	subq	#1,d0
	dble	d1,keepthemove
	bra.s	endline

repeat:
;----- repeat n+1 bytes out ----------------

	neg.b	d1 
	bmi.s	endline  
	move.b	(a0)+,temp

keepmoving:

	move.b	temp,(a1)+
	subq	#1,d0
	dble	d1,keepmoving

endline:
	tst.w	d0
	bgt.s	doline
	move.l	a1,(a3)+
	
	subq.w	#1,d4
	cmp.w	#0,d4
	bne.s	decomscreen

e	dbra	d7,new_plane
return:
	rts
	


**********************************************************************
*			Check Joystick				     *
**********************************************************************

checkjoy:
	

	movem.l d0-d7/a0-a6,-(sp)
	move.w	xcor,pxcor
	move.w	ycor,pycor
	move.w	$dff00c,d0
	btst 	#1,d0		; is it right, no?
	beq.s 	noright
	cmp.w	#200,xcor
	bgt.s	noright
	Add.w   #1,xcor
	bra	noleft

noright:
	btst    #9,d0
 	beq.s 	noleft		; is it left?
	cmp.w	#14,xcor
	blt.s	noleft
	Sub.w	#1,xcor

noleft:
	move.w	d0,d1
	and.w	#$303,d1
	cmp.w   #1,d1
 	beq.s 	nodown		; is it up?
	cmp.w	#14,ycor
	blt.s	nodown
	Sub.w	#1,ycor

nodown:

	cmp.w   #$100,d1
 	beq.s 	endjoy		; is it down?
	cmp.w	#190,ycor
	bgt.s	endjoy
	add.w	#1,ycor
	
endjoy:
		
	movem.l (sp)+,d0-d7/a0-a6
	rts

*********************************************************************

Clear_Screen:

	movem.l d0-d7/a0-a6,-(sp)
	move.l	bitplane1,a0
	move.l	#8000,d0

clearit1:

	move.b	#0,(a0)+
	dbra	d0,clearit1


	move.l	bitplane2,a0
	move.l	#8000,d0

clearit2:

	move.b	#0,(a0)+
	dbra	d0,clearit2


 
	move.l	bitplane3,a0
	move.l	#8000,d0

clearit3:

	move.b	#0,(a0)+
	dbra	d0,clearit3

	move.l	bitplane4,a0
	move.l	#8000,d0

clearit4:

	move.b	#0,(a0)+
	dbra	d0,clearit4


	movem.l (sp)+,d0-d7/a0-a6
	rts




********************************************************************
* 			Wait (time delay)			   *
********************************************************************

heywait:
		movem.l d0-d7/a0-a6,-(sp)
		move.l	#1,d1			; Set # to Wait time
		move.l	dosbase,a6
		jsr	delay(a6)
		movem.l (sp)+,d0-d7/a0-a6
		rts



; Copy To Blitter Routine ---------------------------------------------
; a0 = pointer to screen to source object
; a1 = pointer to where to place object
; d0 = X coordinates
; d1 = Y coordinates

PlaceBob:
	movem.l	d0-d7/a0-a3,-(sp)
	
	move.l	#$dff000,a2
	btst.b	#6,dmaconr(a2)		;DMAB_BLTDONE-8,dmaconr(a1)
waitblit2:
	btst.b	#6,dmaconr(a2)		;DMAB_BLTDONE-8,dmaconr(a1)
	bne.s	waitblit2
	
	move.l	bitplane1,a0
	move.l	#100,d0
	move.l	#100,d1

	move.l	d0,d2
	ror.l	#3,d0			; divide by 8
	add.l	d0,a0
	mulu	#40,d1			; multiply by 40
	add.l	d1,a0			; add to screen ptr

	move.w	#0*4096,d4		;Shift Value
	or.w	#$9f0,d4
	move.w	d4,bltcon0(a2)		;Set to LF and registers to use
	move.w	#0,bltcon1(a2)		;Set to 0 for area mode
	move.w	#0,bltamod(a2)		;modulus for A Source mask
	move.w	#36,bltdmod(a2)		;modulus for D destination
	move.w	#$ffff,bltafwm(a2)	;Mask for source (first word A)
	move.w	#$ffff,bltalwm(a2)	;Mask for source (last word A)

	move.l	images,d0
	move.l	d0,bltapth(a2)		;source A pointer
	move.l	a0,bltdpth(a2)		;destination pointer
	move.w	#$0382,bltsize(a2)	;height and width
	movem.l	(sp)+,d0-d7/a0-a3
	rts


just_here:
	move.l	bitplane1,a0
	move.l	#10,d0
	move.l	#15,d1

	move.l	#$dff000,a2
	btst.b	#6,dmaconr(a2)		;DMAB_BLTDONE-8,dmaconr(a1)
waitblit3:
	btst.b	#6,dmaconr(a2)		;DMAB_BLTDONE-8,dmaconr(a1)
	bne.s	waitblit3
	
	move.l	d0,d2
	ror.l	#3,d0			; divide by 8
	add.l	d0,a0
	mulu	#40,d1			; multiply by 40
	add.l	d1,a0			; add to screen ptr

	move.l	images,d0
	add.l	#100,d0
	move.l	d0,bltapth(a2)		;source A pointer
	move.l	a0,bltdpth(a2)		;destination pointer
	move.w	#$0382,bltsize(a2)	;height and width
	rts

******************************************************************************

Save_Screen:

	bsr	Setup_Blit_AD

;	move.w	xcor,d0			; X
;	ext.l	d0
;	lsr.l	#3,d0
;	move.w	ycor,d1			; Y
;	ext.l	d1
;	mulu	#40,d1
;	move.l	d0,offsetx
;	move.l	d1,offsety
	

	bsr	coords

	move.l	bobplane1,a0
	
;	add.l	d0,a0
	add.l	d1,a0
	move.l	d1,offsetx

	move.l	#$dff000,a6

	move.l	savearea,d0		;area to save to
	move.l	a0,bltapth(a6)		;source A pointer
	move.l	d0,bltdpth(a6)		;destination pointer
	move.w	#$0642,bltsize(a6)	;height and width

	bsr	Wait_Blit	


	add.l	#100,d0
	move.l	bitplane2,a0
	add.l	offsetx,a0
	move.l	a0,bltapth(a6)		;source A pointer
	move.l	d0,bltdpth(a6)		;destination pointer
	move.w	#$0642,bltsize(a6)	;height and width

	bsr	Wait_Blit	


	add.l	#100,d0
	move.l	bitplane3,a0
	add.l	offsetx,a0
	move.l	a0,bltapth(a6)		;source A pointer
	move.l	d0,bltdpth(a6)		;destination pointer
	move.w	#$0642,bltsize(a6)	;height and width

	bsr	Wait_Blit	

	add.l	#100,d0
	move.l	bitplane4,a0
	add.l	offsetx,a0
	move.l	a0,bltapth(a6)		;source A pointer
	move.l	d0,bltdpth(a6)		;destination pointer
	move.w	#$0642,bltsize(a6)	;height and width

	bsr	Wait_Blit	

	add.l	#100,d0
	move.l	bitplane5,a0
	add.l	offsetx,a0
	move.l	a0,bltapth(a6)		;source A pointer
	move.l	d0,bltdpth(a6)		;destination pointer
	move.w	#$0642,bltsize(a6)	;height and width

	bsr	Wait_Blit	

	rts
	


*****************************************************************************



Setup_Blit_AD:

	move.l	#$dff000,a6
	move.w	#$09f0,bltcon0(a6)	;Set to LF and registers to use
	clr.w	bltcon1(a6)		;Set to 0 for area mode
	clr.w	bltdmod(a6)		;modulus for A Source mask
	move.w	#36,bltamod(a6)		;modulus for D destination
	move.w	#$ffff,bltafwm(a6)	;Mask for source (first word A)
	move.w	#$ffff,bltalwm(a6)

	rts


*****************************************************************************



Setup_Blit_AD_P:

	move.l	#$dff000,a6
	move.w	#$09f0,bltcon0(a6)	;Set to LF and registers to use
	clr.w	bltcon1(a6)		;Set to 0 for area mode
	clr.w	bltamod(a6)		;modulus for D destination
	move.w	#36,bltdmod(a6)		;modulus for A Source mask
	move.w	#$ffff,bltafwm(a6)	;Mask for source (first word A)
	move.w	#$ffff,bltalwm(a6)

	rts


Setup_Blit_ABCD:

	move.l	#$dff000,a2
	move.w	#$09f0,bltcon0(a2)	;Set to LF and registers to use
	clr.w	bltcon1(a2)		;Set to 0 for area mode
	clr.w	bltamod(a2)		;modulus for A Source mask
	move.w	#36,bltdmod(a2)		;modulus for D destination
	move.w	#$ffff,bltafwm(a2)	;Mask for source (first word A)
	move.w	#$ffff,bltalwm(a2)

	rts

****************************************************************************

Set_Blit_C:

	move.l	#$dff000,a6

	move.w	#36,bltdmod(a6)		set up the destination modulos
	move.w	#36,bltcmod(a6)
	clr.w	bltbmod(a6)
	clr.w	bltamod(a6)

	move.w	#$ffff,bltafwm(a6)
	move.w	#$ffff,bltalwm(a6)
;	move.w	#$0,bltalwm(a6)
	rts
	

****************************************************************************

Place_area:

	bsr	Setup_Blit_AD_P
	
;	move.w	xcor,d0			; X
;	ext.l	d0
;	lsr.w	#3,d0
;	move.w	ycor,d1			; Y
;	ext.l	d1
;	mulu	#40,d1

	bsr	coords
	move.l	bobplane1,a0

;	add.l	d0,a0			;add x to plane ptr
	add.l	d1,a0			;add y to plane ptr
	move.l	d1,ploffsetx

	move.l	savearea,d0

	move.l	#$dff000,a6

	move.l	d0,bltapth(a6)		;source A pointer
	move.l	a0,bltdpth(a6)		;destination pointer
	move.w	#$0642,bltsize(a6)	;height and width

	bsr	Wait_Blit	
	
	add.l	#100,d0
	move.l	bitplane2,a0
	add.l	ploffsetx,a0		;add x to plane ptr
	move.l	d0,bltapth(a6)		;source A pointer
	move.l	a0,bltdpth(a6)		;destination pointer
	move.w	#$0642,bltsize(a6)	;height and width

	bsr	Wait_Blit	

	add.l	#100,d0
	move.l	bitplane3,a0
	add.l	ploffsetx,a0		;add x to plane ptr
	move.l	d0,bltapth(a6)		;source A pointer
	move.l	a0,bltdpth(a6)		;destination pointer
	move.w	#$0642,bltsize(a6)	;height and width

	bsr	Wait_Blit	

	add.l	#100,d0
	move.l	bitplane4,a0
	add.l	ploffsetx,a0		;add x to plane ptr
	move.l	d0,bltapth(a6)		;source A pointer
	move.l	a0,bltdpth(a6)		;destination pointer
	move.w	#$0642,bltsize(a6)	;height and width

	bsr	Wait_Blit	

	add.l	#100,d0
	move.l	bitplane5,a0
	add.l	ploffsetx,a0		;add x to plane ptr
	move.l	d0,bltapth(a6)		;source A pointer
	move.l	a0,bltdpth(a6)		;destination pointer
	move.w	#$0642,bltsize(a6)	;height and width

	bsr	Wait_Blit	

	rts

******************************************************************************

Blit_to_backgnd:


;	move.l	offsetx,d0
;	move.l	offsety,d1

;	move.l	bobplane1,a1
;	add.l	d0,a1
;	add.l	d1,a1


;	move.l	#$ff,(a1)
;	rts


blit.to.backgnd
	
	bsr	Set_Blit_C

	move.l	#$0642,d3				; blit size
	move.l	images,a2
;	move.l	man_data,a2				; shape pointer

	move.l	a2,a3
;	move.l	cleararea,a3
	add.l	#100,a3					; mask pointer
;	move.l	man_data,a3				; shape pointer
;	add.l	#2000,a3	

	bsr	coords			; get the offfset in d2

	move.l	bobplane1,d5				; pointer to plane
	add.l	d1,d5			; add the offset to the bitplane pointer
	move.l	d1,cookoff	
	
	move.l	d2,d1
	move.l	#$dff000,a6
	ror.w	#4,d1
	move.w	d1,bltcon1(a6)		set up the B scroll value

	or.w	#$0fca,d1		set up the A scroll value and the
	move.w	d1,bltcon0(a6)		minterm for D = notA.C + B

	move.l	a2,bltbpt(a6)
	move.l	d5,bltcpt(a6)	   	setup the screen pointers
	move.l	d5,bltdpt(a6)
	move.l	a3,bltapt(a6)	    	setup the bob mask
	move.w	d3,bltsize(a6)		and blit the bob to the screen

	bsr	Wait_Blit	

	move.l	bobplane2,d5
	add.l	cookoff,d5
;	add.l	#100,a2
	move.l	a2,bltbpt(a6)
	move.l	d5,bltcpt(a6)	   	setup the screen pointers
	move.l	d5,bltdpt(a6)
	move.l	a3,bltapt(a6)	    	setup the bob mask
	move.w	d3,bltsize(a6)		and blit the bob to the screen

	bsr	Wait_Blit	


	move.l	bobplane3,d5
	add.l	cookoff,d5
;	add.l	#100,a2

	move.l	a2,bltbpt(a6)
	move.l	d5,bltcpt(a6)	   	setup the screen pointers
	move.l	d5,bltdpt(a6)
	move.l	a3,bltapt(a6)	    	setup the bob mask
	move.w	d3,bltsize(a6)		and blit the bob to the screen

	bsr	Wait_Blit	

	move.l	bobplane4,d5
	add.l	cookoff,d5
;	add.l	#100,a2

	move.l	a2,bltbpt(a6)
	move.l	d5,bltcpt(a6)	   	setup the screen pointers
	move.l	d5,bltdpt(a6)
	move.l	a3,bltapt(a6)	    	setup the bob mask
	move.w	d3,bltsize(a6)		and blit the bob to the screen

	bsr	Wait_Blit	

	move.l	bobplane5,d5
	add.l	cookoff,d5
;	add.l	#100,a2

	move.l	a2,bltbpt(a6)
	move.l	d5,bltcpt(a6)	   	setup the screen pointers
	move.l	d5,bltdpt(a6)
	move.l	a3,bltapt(a6)	    	setup the bob mask
	move.w	d3,bltsize(a6)		and blit the bob to the screen

	bsr	Wait_Blit	


	
	rts

coords:

	move.w	#0,pf1scroll			
	move.w	xcor,d1				; X
	move.w	ycor,d2				; Y
	add.w	#16,d1
	sub.w	pf1scroll,d1			d2 = y coord
	mulu	#40,d2				d1 = x coord
	swap	d2
	move.w	d1,d2
	and.w	#$f,d2
	swap	d2
	lsr.w	#3,d1
	add.w	d2,d1
	swap	d2				d2 = scroll value
	ext.l	d1				d1 = offset
	rts

 
**************************************************************************
Wait_Blit:
	move.l	#$dff000,a6
	btst.b	#6,dmaconr(a6)		;DMAB_BLTDONE-8,dmaconr(a1)
waitblitter:
	btst.b	#6,dmaconr(a6)		;DMAB_BLTDONE-8,dmaconr(a1)
	bne.s	waitblitter
	rts


;--- data area ---------------------------------------------------

array:	ds.w	1000

	Screen_Defs	320,200,5,Y,<framco was here>
	Window		320,200,Y
	Setup_Intuition_Data
	Setup_Dos_Data
	Setup_Graphics_Data

viewport:	dc.l	0


Level2Vector:	dc.l	0
Level3Vector:	dc.l	0
SystemInts:	dc.w	0
SystemDMA:	dc.w	0
temp:		dc.b	0
		cnop 0,2

savearea	dc.l	0
offsetx:	dc.l 0
offsety:	dc.l 0
cookoff:	dc.l	0
ploffsetx:	dc.l 0
ploffsety:	dc.l 0

tmplane		ds.l	10
pf1scroll	dc.W	0	pixel scroll value (0-15) background
pf2scroll	dc.W	0	pixel scroll value (0-15) foreground
iff_screen:	dc.l	0
val:		dc.l	100
images:	dc.l		0
xcor:		dc.w	0
ycor:		dc.w	0
pxcor:		dc.w	0
man_data:	dc.l	0
cleararea:	dc.l	0
pycor:		dc.w	0
bobplane1	dc.l	0
bobplane2	dc.l	0
bobplane3	dc.l	0
bobplane4	dc.l	0
bobplane5	dc.l	0

		cnop 0,2
title:		dc.b	'0000000'
titleend:
		cnop 0,2
enemy:
		dc.b	0,0,0,0
		dc.b	0,0,0,0
		dc.b	%00111100,%00111100,0,0
		dc.b	%01000010,%01000010,0,0
		dc.b	%10001001,%10010001,0,0
		dc.b	%10010000,%00001001,0,0
		dc.b	%10000000,%00000001,0,0
		dc.b	%01000100,%00100010,0,0
		dc.b	%00100000,%00000100,0,0
		dc.b	%00011101,%10111000,0,0
		dc.b	%00010010,%01001000,0,0
		dc.b	%00100010,%01000100,0,0 
		dc.b	0,0,0,0
		dc.b	0,0,0,0

	cnop	0,2
enemy2:
		dc.b	0,0,0,0
		dc.b	0,0,0,0
		dc.b	%00100100,%00100100,0,0
		dc.b	%01000010,%01000010,0,0
		dc.b	%10000001,%10000001,0,0
		dc.b	%10011000,%00011001,0,0
		dc.b	%10000000,%00000001,0,0
		dc.b	%01011100,%00111010,0,0
		dc.b	%00000000,%00000000,0,0
		dc.b	%00010101,%10101000,0,0
		dc.b	%00000010,%01000000,0,0
		dc.b	%00010001,%10001000,0,0
		dc.b	0,0,0,0
		dc.b	0,0,0,0
	cnop	0,2

enemym:
		dc.b	0,0,0,0
		dc.b	0,0,0,0
		dc.b	%00111100,%00111100,0,0
		dc.b	%01111110,%01111110,0,0
		dc.b	%11111111,%11111111,0,0
		dc.b	%11111111,%11111111,0,0
		dc.b	%11111111,%11111111,0,0
		dc.b	%01111111,%11111110,0,0
		dc.b	%00111111,%11111100,0,0
		dc.b	%00011111,%11111000,0,0
		dc.b	%00011011,%11011000,0,0
		dc.b	%00110011,%11001100,0,0
		dc.b	0,0,0,0
		dc.b	0,0,0,0
	cnop	0,2

;filename:	dc.b	'dh0:assem/pics/blank',0
;filename:	dc.b	'dh0:assem/pics/explode.iff',0
;filename:	dc.b	'dh0:assem/pics/arena1.iff',0
;filename:	dc.b	'dh0:dpaint/franco-look2',0
filename:	dc.b	'cityenemy.iff',0
		cnop 0,2
;manname:	dc.b	'dh0:assem/blocks/man.gfx',0
		cnop 0,2
;manname:	dc.b	'dh0:assem/blocks/block.map',0
;		cnop 0,2

		end

