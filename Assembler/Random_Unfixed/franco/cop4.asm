 
	include	'dh0:sourcec/include/franco.i'
	include 'dh0:sourcec/include/iff.i' 

***************************************************************************
no_of_bytes	equ	36	; no of bytes one scan line down
x_size		equ	3	; no of words in width (32 bits 0 - 3 = 4 bytes)
y_size		equ	24	; no of pixels in height
***************************************************************************


	move.l	#1,no_of_planes



;--- Allocate Memory -----------------------
		
	
	OpenDos
	IFERR	ErrorDos
	OpenGraphics
	IFERR   ErrorGfx

	move.l	d0,a0
	move.l	$26(a0),copperloc

	AllocMem	300000,chip
	IFERR	ErrorMem

	move.l	d0,MemArea
	move.l	d0,buffers
	move.l	d0,bufferp
	add.l	#2000,d0

	move.l	d0,screenptr
	move.l	d0,screenfgnd
	move.l	d0,resetscreenptr
	move.l	d0,bitplane
	add.l	#16000,d0
	move.l	d0,bitplane2
	add.l	#16000,d0
	move.l	d0,bitplane3
	add.l	#16000,d0
	move.l	d0,bitplane4
	add.l	#16000,d0
	move.l	d0,bitplane5
	add.l	#16000,d0
	move.l	d0,decomp_area
	add.l	#40000,d0
	move.l	d0,object_data
	move.l	#9000,d0
	move.l	d0,map_area


	Open	filename,old
	IFERR	EndPgm
	Read	60000,decomp_area
	Close
	bsr	init_gfx

	move.l	execbase,a6		; Take System
	jsr	forbid(a6)

	move.l	custom,a6
	move.w	#$7fff,intena(a6)	; disable all interupts

	nop

	bsr	UnPack_Screen
	bsr	Find_Color_Map	
	bmi	Exit	
	bsr	change_color
	bsr	MoveCopper
	bsr	Set_PF_Scroll


	move.l	#0,resetval	; checker for 80 byte count
	move.b	#0,pfscrollval	; set scroll value (0-15)
	move.l	screenfgnd,a2	; source pointer
	add.l	#76*1,a2							; and its offset to draw at
	
	move.l	a2,screenfgnd
	move.l	a2,offset


Vloop:
;Wait on Raster line 16 (for the Exec-Interrupts)

wait:
	move.l	custom+4,d4	;read position
	and.l	#$0001ff00,d4   ;horizontal bits masked
	cmp.l	#$00001000,d4   ;wait on line 16
	bne.s	wait

	bsr	Place_MYBob
;	bsr	Blit_to_Screen	;add data after 15 pixels have
;	WaitButton		1
;	bsr	PlaceObject
;	bsr	Blit_Strip
	bsr 	gohere							;scroll the screen
												;scrolled
	 
	bsr	heywait
	btst.b	#6,$bfe001
	bne	Vloop

******************************************************************************

;--- Exit program ------------------------

Exit:
	move.l	copperloc,a0     ;get the address of copper instructions
	move.l	a0,COP1LC        ;copper jump location address
	move.l	execbase,a6
	jsr	permit(a6)

EndPgm:
	FreeMem	300000,MemArea
ErrorMem:
	CloseGraphics
ErrorGfx:
	CloseDos
ErrorDos:
		rts
		
****************************************************************************


Blit_to_Screen:

	add.b	#1,pfscrollval	; still count (0-15) 8 = 16 pixels
	cmp.b	#8,pfscrollval	; screen scrolls at 2 pixels
	blt	noscreen							; if it hasn't scrolled a 16 pixels
													; don't draw the next line
	
aaa:

	movem.l	d0-d7/a0-a6,-(sp)
	move.l	screenfgnd,a5	; source pointer
	move.l	#25,d1		; no of blocks in block

resetobjdata:	
	move.l	#0,d0
	add.l	#1*15,d0							; number of lines down
	move.l	object_data,a4	; graphics pointer of data

scnloop:

;	move.l	(a4)+,(a5)	; write the data to the screen
	add.l	#80,a5		; next scan line down
	dbra	d0,scnloop	; keep drawing 
	dbra	d1,resetobjdata


	add.l	#2,screenfgnd	; must be reset after 80 bytes
	add.l	#2,resetval	; store it to scroll count
	cmp.l	#80,resetval	; if 80 reset screen ptr + offset
	bne.s	end_of_screen	; if not keep going

	move.l	resetscreenptr,a6	; original screen ptr
	add.l	#76*1,a6							; and its offset to draw at
	move.l	a6,screenfgnd		; store back to drawing ptr
	move.l	#0,resetval		; and reset the scroll count

end_of_screen:

	move.b	#0,pfscrollval		; one line drawn so reset and 
	movem.l (sp)+,d0-d7/a0-a6	; wait another 15 pixels
noscreen:
	rts

***************************************************************************


init_gfx:
	movem.l	d0-d7/a0-a6,-(sp)

	Open	blockname,o
	Read	60000,object_data
	Close
	Open	mapname,o
	Read	10000,map_area
	Close
	movem.l 	(sp)+,d0-d7/a0-a6			

	rts

	

**************************************************************************

Wait_Blit:
	move.l	#$dff000,a6
	btst.b	#6,dmaconr(a6)		;DMAB_BLTDONE-8,dmaconr(a1)
waitblitter:
	btst.b	#6,dmaconr(a6)		;DMAB_BLTDONE-8,dmaconr(a1)
	bne.s	waitblitter
	rts

**********************************************************************

PlaceObject:
	movem.l	d0-d7/a0-a3,-(sp)
	
	move.l	#$dff000,a2
	btst.b	#6,dmaconr(a2)		;DMAB_BLTDONE-8,dmaconr(a1)
waitblit:
	btst.b	#6,dmaconr(a2)		;DMAB_BLTDONE-8,dmaconr(a1)
	bne.s	waitblit

	
	move.l	screenfgnd,a0
;	move.l	#$f00f,(a0)
;	move.l	#100,d0
;	move.l	#100,d1

;	move.l	d0,d2
;	ror.l	#3,d0			; divide by 8
;	add.l	d0,a0
;	mulu	#40,d1			; multiply by 40
;	add.l	d1,a0			; add to screen ptr

	move.l	#$dff000,a2
	move.w	#0*4096,d4		;Shift Value
	or.w	#$9f0,d4
	move.w	d4,bltcon0(a2)		;Set to LF and registers to use
	move.w	#0,bltcon1(a2)		;Set to 0 for area mode
	move.w	#0,bltamod(a2)		;modulus for A Source mask
	move.w	#76,bltdmod(a2)		;modulus for D destination
	move.w	#$ffff,bltafwm(a2)	;Mask for source (first word A)
	move.w	#$ffff,bltalwm(a2)	;Mask for source (last word A)

	move.l	object_data,d0
	move.l	d0,bltapth(a2)		;source A pointer
	move.l	a0,bltdpth(a2)		;destination pointer
	move.w	#$0642,bltsize(a2)	;height and width
	movem.l	(sp)+,d0-d7/a0-a3
	rts


*************************************************************************


Blit_Strip:
	movem.l	d0-d7/a0-a6,-(sp)

	bsr	Wait_Blit

	move.l	custom,a6
	move.w	#$09f0,bltcon0(a6)
	
	move.l	object_data,bltapt(a6)	;source data in chip ram
	clr.w	bltcon1(a6)
	clr.w	bltamod(a6)
	
	move.w	#76,bltdmod(a6)		;modulus for D destination
	move.w	#$ffff,bltafwm(a6)	;Mask for source (first word A)
	move.w	#$0,bltalwm(a6)		;Mask for source (last word A)
;	move.w	#$ffff,bltalwm(a6)	;Mask for source (last word A)

	move.l	screenfgnd,a0
	move.l	object_data,d0

	move.l	d0,bltapth(a6)		;source A pointer
	move.l	a0,bltdpth(a6)		;destination pointer
	move.w	#$0642,bltsize(a6)	;height and width

	movem.l (sp)+,d0-d7/a0-a6	; wait another 15 pixels
	bsr	Wait_Blit
	rts

*****************************************************************************


Place_MYBob:


	add.b	#1,pfscrollval		; still count (0-15) 8 = 16 pixels
	cmp.b	#16,pfscrollval		; screen scrolls at 2 pixels
	blt	nopaste				; if it hasn't scrolled a 16 pixels

	movem.l	d0-d7/a0-a3,-(sp)

	bsr	Setup_Blit

	move.l	#$dff000,a2
	move.l	screenfgnd,a0
	move.l	a0,a3
	move.l	a3,tempplane
	move.l	a3,temp_plane2
	move.l	no_of_planes,d2		; # of planes
	move.l	#7,d4								; no of blocks

	move.l	map_area,a1
	
Block_Number:
	
	clr.l	d1
	move.b	(a1)+,d1								; Get the block number
	cmp.b	#$ff,d1
	bne.s	not_end
	move.b	#1,set_end_of_screen

not_end:

	ext.l	d1
	move.l	object_data,a4
	move.l	a4,d6
	mulu	#500,d1			; multiply x 500 to find the offset
	add.l	d1,a4			; add it to the pointer
	move.l	a4,d0			; move pointer to object data pointer
	

Next_plane:
	
	move.l	d0,bltapth(a2)		;source A pointer
	move.l	a3,bltdpth(a2)		;destination pointer
	move.w	#$0642,bltsize(a2)	;height and width
	
	bsr	Wait_Blit

	add.l	#100,d0			; add 100 to the pointer of data
	add.l	#16000,temp_plane2	; next plane down
	move.l	temp_plane2,a3

	dbra	d2,Next_plane		; branch until all planes are drawn

	add.l	#2000,tempplane		; move 25 scan lines down (25 * 80)
	move.l	tempplane,a5		; one block done
	move.l	a5,temp_plane2		; move it back to the starting position +
	move.l	a5,a3			; the offset of 25 lines down
	move.l	no_of_planes,d2		; and do another 5 planes

	dbra	d4,Block_Number


	add.l	#4,screenfgnd
	add.l	#4,resetval	        ; store it to scroll count
	cmp.l	#80,resetval		; if 80 reset screen ptr + offset
	ble.s	end_of_pointer		; if not keep going

	move.l	resetscreenptr,a6	; original screen ptr
	add.l	#76*1,a6							; and its offset to draw at
	move.l	a6,screenfgnd		; store back to drawing ptr
	move.l	#0,resetval		; and reset the scroll count

end_of_pointer:

	move.b	#0,pfscrollval		; one line drawn so reset and 
	move.l	a1,map_area
	movem.l	(sp)+,d0-d7/a0-a3

nopaste:

	rts


***********************************************************************

Setup_Blit:

	move.l	#$dff000,a2
	move.w	#$09f0,bltcon0(a2)	;Set to LF and registers to use

	clr.w	bltcon1(a2)		;Set to 0 for area mode
	clr.w	bltamod(a2)		;modulus for A Source mask
	move.w	#76,bltdmod(a2)		;modulus for D destination
	move.w	#$ffff,bltafwm(a2)	;Mask for source (first word A)
	move.w	#$ffff,bltalwm(a2)

	rts


		
***************************************************************************


Find_Color_Map	

;	move.l	windowhd,a0
;	move.l	intbase,a6
;	jsr	viewportaddress(a6)
;	move.l	a0,viewport

	move.l	decomp_area,a0
;	lea	bitplane1(pc),a3
	move.b	$1c(a0),d5	;num of bit planes
	move.w	#600,d1

lookcolor:
	cmp.l	#'CMAP',(a0)
	beq.s	setcolor
	add.l	#2,a0
	dbra	d1,lookcolor
	moveq	#-1,d0
	rts

setcolor:
	move.l	4(a0),d7	;length of color map
	divu	#3,d7		;num of pens
	add.l	#8,a0

	move.l	a0,a1
;        move.l  viewport,a0     ;Get Pointer to View Port
;        move.l  gfxbase,a6      ;get grapics base
;	moveq	#0,d0		;pen number
;	moveq	#0,d1		;clear r,g,b
;	moveq	#0,d2
;	moveq	#0,d3
	lea	level.colours,a5

setthecolor:
	moveq	#0,d1
	move.b	(a1)+,d1	;red
;	ror.b	#4,d1
	move.b	(a1)+,d2	;green
	ror.b	#4,d2
	add.b	d2,d1

	move.b	(a1)+,d3	;blue
	ror.b	#4,d3
	rol.w	#4,d1
	add.b	d3,d1
	move.w	d1,(a5)+

;	movem.l	d0-d7/a0-a6,-(sp)
;        jsr     setrgb4(a6)     ;set a color registor
;	movem.l	(sp)+,d0-d7/a0-a6
;	addq.l	#1,d0
	dbra	d7,setthecolor
	moveq	#0,d0
	rts


;---------------------------------------------
	movem.l d0-d7/a0-a6,-(sp)
	move.l	screenptr,a0
	move.l	a0,d2
	move.w	#200,d0

		
loopline:
	move.b	#$ff,(a0)
	add.l	#41,a0
	dbra	d0,loopline
	movem.l (sp)+,d0-d7/a0-a6
	rts


;----- unpack screen -------------------------
UnPack_Screen:

	move.l	#80,iff_mod
	UnPack_IFF 	decomp_area,80,199,bitplane
	rts

;---------------------------------------------


change_color:

	lea	level.colours,a0	;copy the level colours into the
	lea	colours(pc),a1		;copperlist
	moveq	#31,d0
.copy	move.w	(a0)+,2(a1)
	addq	#4,a1
	dbf	d0,.copy
	rts


************************************************************************
*                 Transition Start 				       *
************************************************************************


topjmp:
	move.l	#4,d1
	jsr	heywait

	move.w	#12,d0
	move.l	bufferp,a1
;	move.l	#color1-copper_ins,d1
	add.l	d1,a1
;	move.l	#color2-color1,d1
loopme:
	move.w	(a1),d4
	beq	nosubt

	jsr	subbits
	move.w	d4,(a1)

nosubt:	
	add.l	d1,a1
	dbra	d0,loopme
	dbra	d5,topjmp
;	bra	comehere
	rts


**************************************************************************
*                Transition Stop                                         *
**************************************************************************



***********************************************************************
*              Transition Loop to mask off the bits                   *
***********************************************************************


subbits:
		movem.l	d0-d3/a0-a6,-(sp)
	
		move.l	#3,d0
looprot:
		move.l	d4,d2
		and.l	#$f,d2
		cmp.b	#$0,d2
		beq	noroll
		sub.b	#1,d2
noroll:
		and.w	#$fff0,d4
		or.w	d2,d4
		ror.w	#4,d4
		dbra	d0,looprot

		movem.l	(sp)+,d0-d3/a0-a6
		rts

*************************************************************************
*               End of Transistion Mask                                 *
*************************************************************************

	
********************************************************************
* 			Wait (time delay)			   *
********************************************************************


heywait:
		movem.l d0-d7/a0-a6,-(sp)
		move.l	#0,d1			; Set # to Wait time
		move.l	dosbase,a6
		jsr	delay(a6)
		movem.l (sp)+,d0-d7/a0-a6
		rts

	
********************************************************************
* 			Move CopperList To Chip			   *
********************************************************************

MoveCopper:
		move.l	screenptr,a0
		move.l	a0,d2
		move.w	d2,pln1h
		swap.w	d2
		move.w	d2,pln1l

		swap	d2
		add.l	#5,d2

		move.w	d2,pln2h
		swap.w	d2
		move.w	d2,pln2l

		move.l	bufferp,a1
		lea	copper_ins(pc),a0
		move.w	#dosname-copper_ins,d0
movecop:
		move.b	(a0)+,(a1)+
		dbra	d0,movecop

		move.l	bufferp,a0      ;get the address of copper instructions
		move.l	a0,COP1LC	;copper jump location address
		rts

Set_PF_Scroll:
	
		move.l	screenptr,d2
		move.w	#15,scrollval
		move.l	bufferp,a0
		move.l	a0,a1
		add.l	#pln1h-copper_ins,a0	; a0 points at copper bitplane
		rts

gohere:
;		move.l	#3,d1			; Set # to Wait time
;		move.l	dosbase,a6
;		jsr	delay(a6)

;		movem.l	a0-a6/d0-d7,-(sp)

		move.w	d2,4(a0)
		swap.w	d2
		move.w	d2,(a0)
		swap.w	d2

		add.l	#16000,d2
		move.w	d2,12(a0)
		swap.w	d2
		move.w	d2,8(a0)
		swap.w	d2
		sub.l	#16000,d2

		move.w	scrollval,d0

		move.w	d0,d3
		rol.w	#4,d3
		or.w		d0,d3
		move.w	d3,hscr-copper_ins(a1)

		
		sub.w	#2,d0
		cmp.w	#$ffff,d0
		bne.s	gohereokay
		moveq	#15,d0

		add.l	#2,d2
		add.w	#1,endofscreen
		cmp.w	#40,endofscreen
		bne.s   add_to_screen

		move.l	screenptr,d2
		move.w	#0,endofscreen

add_to_screen:
gohereokay:
		move.w	d0,scrollval

;		movem.l	(sp)+,a0-a6/d0-d7
		
		rts

			
;		move.l	copperloc,a0     ;get the address of copper instructions
;		move.l	a0,COP1LC         ;copper jump location address

;		move.l	execbase,a6
;		jsr	permit(a6)
		rts

*****************************************************************
*		Place Data back on screen			*
*****************************************************************
PlaceBob:
	
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	#4,d4
	move.l	screenfgnd,a1
;    lea        graphics,a2

getall2:
	move.l	#y_size,d0	; how many lines high

again:
	move.l	#x_size,d3	; how many bytes wide 32 pixels (4 bytes)

placeman2:

	move.b 	(a2)+,(a1)    	;place man data on the screen
	add.l	#40,a1
	dbra   	d3,placeman2
	add.l  	#no_of_bytes,a1      ;move plane pointer down one scan line
	dbra   	d0,again
kickout2:        
	dbra	d4,getall2
	movem.l (sp)+,d0-d7/a0-a6
	add.w	#4,screenfgnd
	rts


;----- data-----------------------------------------------------
dws:	dc.w	$581,$ffc1



*     copper instructions

copper_ins:
	
	
            dc.w $0100,$0200
            dc.w $0201,$fffe
            dc.w $0120,$0000	; Sprite 0 location
            dc.w $0122,$0000
            dc.w $0124,$0000
            dc.w $0126,$0000
            dc.w $0128,$0000
            dc.w $012a,$0000
            dc.w $012c,$0000
            dc.w $012e,$0000
            dc.w $0130,$0000
            dc.w $0132,$0000
            dc.w $0134,$0000
            dc.w $0136,$0000
            dc.w $0138,$0000
            dc.w $013a,$0000
            dc.w $013c,$0000
            dc.w $013e,$0000
	    
		
		dc.w $01a0,$0000
            dc.w $01a2,$0000		; Sprite Color 0
	       dc.w $01a4,$0000
	       dc.w $01a6,$0000
            dc.w $01a8,$0000		; Sprite Color 0
	       dc.w $01aa,$0000
	       dc.w $01ac,$0000
            dc.w $01ae,$0000		; Sprite Color 0
		dc.w $01b0,$0000
            dc.w $01b2,$0000		; Sprite Color 0
	       dc.w $01b4,$0000
	       dc.w $01b6,$0000
            dc.w $01b8,$0000		; Sprite Color 0
	       dc.w $01ba,$0000
	       dc.w $01bc,$0000
            dc.w $01be,$0000		; Sprite Color 0
			
            dc.w $2801,$fffe
            dc.w $0100,$0200

            dc.w $00e0
pln1h:	dc.w $0000    *    ;                       1(h)
            dc.w $00e2
pln1l:	dc.w $0000    *    ;                       1(l)
	       dc.w $00e4
pln2h:	dc.w $0000    *    ;bit plane display area 2(low)
            dc.w $00e6
pln2l:	dc.w $0000    *    ;bit plane display area 2(high)
	       dc.w $00e8
pln3h:	dc.w $0000    *    ;bit plane display area 3(low)
            dc.w $00ea
pln3l:	dc.w $0000    *    ;bit plane display area 3(high)
            dc.w $00ec
pln4h:	dc.w $0000    *    ;                       4(low)
            dc.w $00ee
pln4l:	dc.w $0000    *    ;                       4(high)
            dc.w $00f0
pln5h:	dc.w $0000    *    ;                       5(low)
            dc.w $00f2
pln5l:	dc.w $0000    *    ;                       5(high)


;		DC.W	ddfstrt,$0028,ddfstop,$00D8
;		DC.W	diwstrt,$1F78,diwstop,$FFC6



            dc.w $0092
ddfstrtx:   dc.w $0020		;was 3c 20	was 20	
            
		
            dc.w $0094
ddfstopx:   dc.w $00d8	; was d4 was d8

            dc.w $008e
diwstrtx:   dc.w $3091 				;0581         ;diwstart	was 1a64  3091

            dc.w $0090
diwstopx:    dc.w $39d1			 ;ffc1        ;diwstop		was	39d1

            dc.w $0104,$0024
            dc.w $0102
hscr:	    dc.w $0000 	;
            
            dc.w $0108,$0020	; modulo playfield 1
            dc.w $010a,$0020	; modulo playfield 2

            dc.w $0100,$2200	;bit plane control 

colours:	DC.W	color00+0,$0000,color00+2,$0000
		DC.W	color00+4,$0000,color00+6,$0000
		DC.W	color00+8,$0000,color00+10,$0000
		DC.W	color00+12,$0000,color00+14,$0000
		DC.W	color00+16,$0000,color00+18,$0000
		DC.W	color00+20,$0000,color00+22,$0000
		DC.W	color00+24,$0000,color00+26,$0000
		DC.W	color00+28,$0000,color00+30,$0000
		DC.W	color00+32,$0000,color00+34,$0000
		DC.W	color00+36,$0000,color00+38,$0000
		DC.W	color00+40,$0000,color00+42,$0000
		DC.W	color00+44,$0000,color00+46,$0000
		DC.W	color00+48,$0000,color00+50,$0000
		DC.W	color00+52,$0000,color00+54,$0000
		DC.W	color00+56,$0000,color00+58,$0000
		DC.W	color00+60,$0000,color00+62,$0000

;           dc.w $0182,$0000
;            dc.w $0184,$0fff
 
;            dc.w $0186
;color1:	    dc.w $0000           
;            dc.w $3001,$fffe         ;wait for line 30
;            dc.w $0180
;color2:	    dc.w $0000         ;move black to color register (180)
;            dc.w $4001,$fffe         ;wait for line 132
;            dc.w $0180
;	    dc.w $0000         ;move sky blue to color register
;            dc.w $5001,$fffe         ;wait for line 200
;            dc.w $0180,$0111         ;move pink to color register
;            dc.w $6001,$fffe
;            dc.w $0180,$0222         ;green
;            dc.w $7001,$fffe
;            dc.w $0180,$0333        ;orange
;            dc.w $8001,$fffe
;            dc.w $0180,$0444         ;brown
;            dc.w $9001,$fffe
;            dc.w $0180,$0555         ;magenta
;            dc.w $a001,$fffe
;            dc.w $0180,$0666         ;medium grey
;            dc.w $b001,$fffe
;            dc.w $0180,$0777         ;red
;            dc.w $c001,$fffe
;            dc.w $0180,$0888         ;blue
;            dc.w $d001,$fffe
;            dc.w $0180,$0999        ;lemon yellow
;            dc.w $e001,$fffe
;            dc.w $0180,$0aaa         ;tan
            dc.w $f001,$fffe         ;wait for end of screen
            dc.w $0100,$0200         ;turn off bit planes
            dc.w $ffff,$fffe         ;wait until you jump again



;--- data area -----------------------------------

	Setup_Dos_Data
	Setup_Graphics_Data

filename:	dc.b	'a640.iff',0
		cnop	0,2
blockname:	dc.b	'block.map',0
		cnop	0,2
mapname:	dc.b	'Graphics_Map',0
		cnop	0,2

copperloc:	dc.l	0
screenptr:	dc.l	0
MemArea:	dc.l	0
whichplane:	dc.w	0
bitplane:		dc.l	0
bitplane2:		dc.l	0
bitplane3:		dc.l	0
bitplane4:		dc.l	0
bitplane5:		dc.l	0
scrollval:	dc.w		15
rastport	dc.l	0
bufferp:	dc.l	0	;bufferarea
buffers:	dc.l	0	;bufferarea
buffere:	dc.l	0	;bufferarea+4000
enddatarea:	dc.l	0
endofscreen:	dc.l	0
decomp_area	dc.l	0
screenfgnd:	dc.l	0
flag:	dc.l	0
pfscrollval	dc.b	0
		cnop	0,2

resetscreenptr:	dc.l	0
offset:		dc.l	0
resetval:	dc.l	0
object_data:	dc.l	0
tempplane:	dc.l	0
temp_plane2:	dc.l	0
map_area:	dc.l	0
no_of_planes:	dc.l	0
set_end_of_screen:	dc.b	0
		cnop	0,2


level.colours	ds.l	200

;level.colours
;		DC.W	$0332,$0055,$0543,$0000,$0000,$0000,$0000,$0000
;		DC.W	$0000,$0F55,$0B05,$0700,$08A7,$0182,$0065,$0055
;		DC.W	$0000,$0FF6,$0000,$0FD0,$0A00,$0BDF,$06AF,$004F
;		DC.W	$0FFF,$0CDD,$0ABB,$0798,$0587,$0465,$0243,$0E32

SPRITE:
	DC.W  $6d60,$7200,$FE00,$4100,$FFF8,$AA48,$95BC,$0000
	DC.W  $001C,$7FD3,$4EE0,$0070,$3080,$4000,$0000,$0000

		end

