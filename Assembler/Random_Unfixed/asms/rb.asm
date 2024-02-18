	;   E X A M P L E: Rotate Blt 


;   Here we rotate bits.  This code takes a single rastcd 
;   bitplane, and 'rotates' it into an array of 16-bit
;   the specified bit of each word in the array accordi
;   corresponding bit in the raster row.  We use the li
;   conjunction w th patterns to do this magic.
;   Input:  dO contains the number of words in the rast
;   contains the number of the bit to set (0..15).  aO
;   pointer to the raster data, and al contains a poinl
;   array we are filling; the array must be at least (<
;   (or (d0)*32 bytes) long.


;  include 'dh0:lc/include/exec/types.i'
;  include 'dh0:lc/include/hardware/custom.i'
;  include 'dh0:lc/include/hardware/blit.i'
;  include 'dh0:lc/include/hardware/dmabits.i'
   include 'include/franco.i'


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

	AllocMem 100000,Chip
	move.l	d0,iff_screen
	Open	filename,o
	Read	100000,iff_screen
	Close

	jsr 	unpack
	WaitButton 0
	
	jsr	rotatebits
	WaitButton 1


	FreeMem 100000,iff_screen

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


**************************************************************
unpack:

	move.l	screenhd,a0

	move.l	$c0(a0),bitplane1
	move.l	$c4(a0),bitplane2
	move.l	$c8(a0),bitplane3
	move.l	$cc(a0),bitplane4
	move.l	$d0(a0),bitplane5

	move.l	windowhd,a0
	move.l	intbase,a6
	jsr	viewportaddress(a6)
	move.l	a0,viewport

	move.l	iff_screen,a0
	lea	bitplane1(pc),a3
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
	lea	bitplane1(pc),a3
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

	dbra	d7,new_plane
return:
	rts
	

rotatebits:

	move.l	#20,d0
	move.l	#4,d1
	lea	array,a1
	move.l	bitplane1,a0
        
	lea     custom,a2     	 ; We need to access tl
        tst     d0               ; if no words, just r 
        beq     gone
        lea     DMACONR(a2),a3   ; get the address of <
        moveq.l #DMAB_BLTDONE-8,d2      ; get the bit
        btst    d2,(a3)          ; check to see if we'.
wait1:
        btst    d2,(a3)          ; check again.
        bne.s   wait1            ; not done?  Keep wai
        moveq.l #-30,d3          ; Line mode:  aptr =
        move.l  d3,BLTAPT(a2)
        move.w  #-60,BLTAMOD(a2) ; amod = 4Y-4
        clr.w   BLTBMOD(a2)      ; bmod = 4Y
        move.w  #2,BLTCMOD(a2)   ; cmod = width of bit
        move.w  #2,BLTDMOD(a2)   ; ditto
        ror.w   #4,d1            ; grab the four bits
        and.w   #$f000,d1       ; mas  them out
        or.w    #$bca,d1        ; USEA, USEC, USED, 
        move.w  d1,BLTCON0(a2)  ; stuff it
        move.w  #$f049,BLTCON1(a2)      ; BSH=15, SG


        move.w  #$8000,BLTADAT(a2)      ; Initialize
        move.w  #$ffff,BLTAFWM(a2)      ; Initialize
        move.w  #$ffff,BLTALWM(a2)
        move.l  a1,BLTCPT(a2)   ; Initialize pointer
        move.l  a1,BLTDPT(a2)
	lea	BLTBDAT(a2),a4	; For quick access
	lea	BLTSIZE(a2),a5	; addresses
	move.w  #$402,d1	; Stuff bltsize; wid

         move.w  (a0)+,d3        ; Get next word
         bra.s   inloop          ; Go into the loop



;   04  A miga Hardware Reference Manual


again:
        move.w  (a0)+,d3        ; Grab another word
        btst    d2,(a3)         ; Check blit done
wait2:
        btst    d2,(a3)         ; Check aga n
        bne     wait2          ; oops, not ready,
 
inloop:
        move.w  d3,(a4)         ; stuff new word to 
        move.w  d1,(a5)         ; start the blit
        subq.w  #1,d0           ; is that the last wi
        bne.s   again           ; keep go ng if not
gone:
        rts


array:	ds.w	1000

	Screen_Defs	320,200,5,Y,<framco was here>
	Window		320,200,Y
	Setup_Intuition_Data
	Setup_Dos_Data
	Setup_Graphics_Data

viewport:	dc.l	0

temp:		dc.b	0
		cnop 0,2

iff_screen:	dc.l	0

		cnop 0,2
title:		dc.b	'0000000'
titleend:
		cnop 0,2
filename:	dc.b	'wall-game2',0
		cnop 0,2

