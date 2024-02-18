 
	include	'include/franco.i'
	include 'include/iff.i' 


;--- Allocate Memory -----------------------
		
	
	OpenDos
	IFERR	ErrorDos
	OpenGraphics
	IFERR   ErrorGfx

	move.l	d0,a0
	move.l	$26(a0),copperloc

	AllocMem	200000,chip
	IFERR	ErrorMem

	move.l	d0,MemArea
	move.l	d0,buffers
	move.l	d0,bufferp
	add.l	#2000,d0
	move.l	d0,screenptr

	move.l	d0,bitplane
	add.l	#16000,d0
	move.l	d0,bitplane2
	add.l	#16000,d0
	move.l	d0,bitplane3
	add.l	#16000,d0
	move.l	d0,bitplane4
	add.l	#16000,d0
	move.l	d0,bitplane5

	add.l	#36000,d0
	move.l	d0,decomp_area

	Open	filename,old
	IFERR	EndPgm
	Read	60000,decomp_area
	Close

	bsr	UnPack_Screen
	bsr	Take_Sys

;--- Exit program ------------------------
EndPgm:
	FreeMem	200000,MemArea
ErrorMem:
	CloseGraphics
ErrorGfx:
	CloseDos
ErrorDos:
		rts
		
		


;----- unpack screen -------------------------
UnPack_Screen:

	move.l	#40,iff_mod
	UnPack_IFF 	decomp_area,40,199,bitplane
	rts

;---------------------------------------------
Take_Sys:

	move.l	execbase,a6
	jsr	forbid(a6)


;---------------------------------------------
		move.l	screenptr,a0
		move.l	a0,d2
;		move.w	#200,d0

		
;loopline:
;		move.b	#$ff,(a0)
;		add.l	#41,a0
;		dbra	d0,loopline


;-------------------------------------------------------------


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

		move.l	bufferp,a0	;get the address of copper instructions
		move.l	a0,COP1LC	;copper jump location address


		
		move.l	screenptr,d2
		move.w	#15,d0
		move.l	bufferp,a0
		move.l	a0,a1
		add.l	#pln1h-copper_ins,a0	; a0 points at copper bitplane

gohere:
		movem.l	a0-a6/d0-d7,-(sp)
		move.l	#8,d1			; Set # to Wait time
		move.l	dosbase,a6
;		jsr	delay(a6)
		movem.l	(sp)+,a0-a6/d0-d7
	
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

		move.w	d0,d3
		rol.w	#4,d3
		or.w	d0,d3
		move.w	d3,hscr-copper_ins(a1)

;Wait on Raster line 16 (for the Exec-Interrupts)

wait:
		move.l  custom+4,d4	;read position
		and.l   #$0001ff00,d4   ;horizontal bits masked
		cmp.l   #$00001000,d4   ;wait on line 16
		bne.s   wait

		sub.w	#2,d0
		cmp.w	#$ffff,d0
		bne.s	gohere
			
		add.l	#2,d2
		add.w	#1,endofscreen
		cmp.w	#40,endofscreen
		bne.s   add_to_screen
		move.l	screenptr,d2
		move.w	#0,endofscreen

add_to_screen:
		move.w	#15,d0

		btst.b	#6,$bfe001
		bne	gohere
	
		move.l	copperloc,a0     ;get the address of copper instructions
		move.l	a0,COP1LC         ;copper jump location address

		move.l	execbase,a6
		jsr	permit(a6)
		rts


;----- data-----------------------------------------------------
dws:	dc.w	$581,$ffc1



*     copper instructions

copper_ins:
	
	
            dc.w $0100,$0200
            dc.w $0201,$fffe
            dc.w $0120,$0002	; Sprite 0 location
            dc.w $0122,$5000
            dc.w $0124,$0002
            dc.w $0126,$5000
            dc.w $0128,$0002
            dc.w $012a,$5000
            dc.w $012c,$0002
            dc.w $012e,$5000
            dc.w $0130,$0002
            dc.w $0132,$5000
            dc.w $0134,$0002
            dc.w $0136,$5000
            dc.w $0138,$0002
            dc.w $013a,$5000
	    
            dc.w $01a2,$0ff0		; Sprite Color 0
	    dc.w $01a4,$0fff
	    dc.w $01a6,$0999
			
            dc.w $2801,$fffe
            dc.w $0100,$0200

            dc.w $008e
diwstrtx:    dc.w $0581         ;diwstart	was 1a64

            dc.w $0090
diwstopx:    dc.w $ffc1        ;diwstop		was	39d1

            dc.w $00e0
pln1h:	    dc.w $0000    *    ;                       1(h)
            dc.w $00e2
pln1l:	    dc.w $0000    *    ;                       1(l)
	    dc.w $00e4
pln2h:	    dc.w $0000    *    ;bit plane display area 2(low)
            dc.w $00e6
pln2l:	    dc.w $0000    *    ;bit plane display area 2(high)
	    dc.w $00e8
pln3h:	    dc.w $0000    *    ;bit plane display area 3(low)
            dc.w $00ea
pln3l:	    dc.w $0000    *    ;bit plane display area 3(high)
            dc.w $00ec
pln4h:	    dc.w $0000    *    ;                       4(low)
            dc.w $00ee
pln4l:	    dc.w $0000    *    ;                       4(high)
            dc.w $00f0
pln5h:	    dc.w $0000    *    ;                       5(low)
            dc.w $00f2
pln5l:	    dc.w $0000    *    ;                       5(high)

            dc.w $0092
ddfstrtx:    dc.w $0020	;was 3c
            
            dc.w $0094
ddfstopx:    dc.w $00d8	; was d4

            dc.w $0104,$0024
            dc.w $0102
hscr:	    dc.w $0000 	;
            
            dc.w $0108,$0020	; modulo playfield 1
            dc.w $010a,$0020	; modulo playfield 2
            dc.w $0100,$2200	;bit plane control 
            dc.w $0182,$0000
            dc.w $0184,$0000
            dc.w $0186,$0f80
            dc.w $3001,$fffe         ;wait for line 30
            dc.w $0180,$0000         ;move black to color register (180)
            dc.w $4001,$fffe         ;wait for line 132
            dc.w $0180,$0000         ;move sky blue to color register
            dc.w $5001,$fffe         ;wait for line 200
            dc.w $0180,$0000         ;move pink to color register
            dc.w $6001,$fffe
            dc.w $0180,$0000         ;green
            dc.w $7001,$fffe
            dc.w $0180,$0000         ;orange
            dc.w $8001,$fffe
            dc.w $0180,$0000         ;brown
            dc.w $9001,$fffe
            dc.w $0180,$0000         ;magenta
            dc.w $a001,$fffe
            dc.w $0180,$0000         ;medium grey
            dc.w $b001,$fffe
            dc.w $0180,$0000         ;red
            dc.w $c001,$fffe
            dc.w $0180,$0000         ;blue
            dc.w $d001,$fffe
            dc.w $0180,$0000         ;lemon yellow
            dc.w $e001,$fffe
            dc.w $0180,$0000         ;tan
            dc.w $f001,$fffe         ;wait for end of screen
            dc.w $0100,$0200         ;turn off bit planes
            dc.w $ffff,$fffe         ;wait until you jump again



;--- data area -----------------------------------

	Setup_Dos_Data
	Setup_Graphics_Data

filename:	dc.b	'pics/brickwall',0
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
rastport	dc.l	0
bufferp:	dc.l	0	;bufferarea
buffers:	dc.l	0	;bufferarea
buffere:	dc.l	0	;bufferarea+4000
enddatarea:	dc.l	0
endofscreen:	dc.l	0
decomp_area	dc.l	0


SPRITE:
	DC.W  $6d60,$7200,$FE00,$4100,$FFF8,$AA48,$95BC,$0000
	DC.W  $001C,$7FD3,$4EE0,$0070,$3080,$4000,$0000,$0000

