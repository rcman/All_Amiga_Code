; Sprite program wrinten  by Franco Gaetan
; CustomChip-Register

copper_halt	equ $fffffffe
custom 		equ $dff000        ; Hardware Register


openlib		equ	-408
closelib	equ	-414
open		equ	-30
close		equ	-36
write		equ	-48
read 		equ 	-42

closescreen 	equ $66
execbase 	equ $4
intena		equ $9a            ; interupt-enable-register (write)
intreq 		equ $09c
intreqr 	equ $1e            ; interupt-request-register (read)
dmacon 		equ $096           ; DMA-Control palette register (write)

AllocMem	equ	-198
FreeMem		equ	-210
sysbase		equ	$4
delay		equ	-198

color 	 equ $180
color00  equ color+00         ; Color palette register 0
color01  equ color+$02
color17  equ color+$22	     ; Sprite Color Registers	
color18  equ color+$24        ; Set up for all sprites being used
color19  equ color+$26
color21  equ color+$2a
color22  equ color+$2c
color23  equ color+$2e
color25  equ color+$32
color26  equ color+$34
color27  equ color+$36


joy0dat		equ $00a
joy1dat		equ $00c
joy2 		equ $dff00c
fire 		equ $bfe001
mouse 		equ $dfe00a
ciaapra 	equ $bfe001

; Sound Registers

ctlw equ   $dff096
c0thi equ  $dff0a0
c0tlo equ  c0thi+2
c0tl equ   c0thi+4
c0per equ  c0thi+6
c0vol equ  c0thi+8

; Sprite control register

sprpt	equ $120
spr0pt 	equ sprpt+$00
spr0pth	equ spr0pt+$00
spr0ptl equ spr0pt+$02

spr1pt	equ sprpt+$04
spr1pth	equ spr1pt+$00
spr1ptl equ spr1pt+$02

spr2pt	equ sprpt+$08
spr2pth	equ spr2pt+$00
spr2ptl equ spr2pt+$02

spr3pt	equ sprpt+$0c
spr3pth	equ spr3pt+$00
spr3ptl equ spr3pt+$02

spr4pt	equ sprpt+$10
spr4pth	equ spr4pt+$00
spr4ptl equ spr4pt+$02

spr5pt	equ sprpt+$14
spr5pth	equ spr5pt+$00
spr5ptl equ spr5pt+$02

spr6pt	equ sprpt+$18
spr6pth	equ spr6pt+$00
spr6ptl equ spr6pt+$02

spr7pt 	equ sprpt+$1c
spr7pth	equ spr7pt+$00
spr7ptl equ spr7pt+$02
vhposr	equ $006
vposr equ $4             ; half line position (read)

;Bitplane Register

bplcon0 equ $100         ;Bitplane control register 0
bplcon1 equ $102         ;1 (Scroll Value)
bplcon2 equ $104         ;2 (Sprite <> Playfield Priority)
bpl1pth equ $0e0         ;pointer to 1. Bitplane
bpl1ptl equ $0e2         ;
bpl1mod equ $108         ;Module-value for odd Bit-Plane
bpl2mod equ $10a         ;module-value for even Bitplanes
diwstrt equ $08e         ;start of screen windows
diwstop equ $090         ;end of screen window
ddfstrt equ $092         ;Bit-plane DMA Start
ddfstop equ $094         ;Bit-plane DmA Stop

; copper registers
COP1LC	equ $dff080
COP2LC	equ $dff084
COPJMP1  EQU $DFF088
COPJMP2  EQU $DFF08A

; ****************************************************************
; *** Start Program ***
; ****************************************************************


;--- Allocate Memory -----------------------

		move.l	sysbase,a6
		move.l	#98000,d0
		move.l	#$10002,d1
		jsr	AllocMem(a6)
		move.l	d0,Memarea
		move.l	d0,buffers
		beq	errordos
		move.l	d0,bufferp
		add.l	#2000,d0
		move.l	d0,screenptr

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
		beq	errordos

		move.l	d0,a0
		move.l	$26(a0),copperloc

;----- load screen -------------------------

		move.l	dosbase,a6
		lea	filename(pc),a0
		move.l	a0,d1
		move.l	#1005,d2
		jsr	open(a6)
		move.l	d0,filehd
		beq	notopened

		move.l	screenptr,d2
		move.l	#32000,d3
		move.l	d0,d1
		jsr	read(a6)

		move.l	filehd,d1
		jsr	close(a6)
notopened:
		

;---------------------------------------------
		move.l	screenptr,a0
		move.l	a0,d2
		move.w	#200,d0
;loopline:
;		move.b	#$ff,(a0)
;		add.l	#81,a0
;		dbra	d0,loopline

		move.w	d2,pln1h
		swap.w	d2
		move.w	d2,pln1l

		swap	d2
		add.l	#1,d2

		move.w	d2,pln2h
		swap.w	d2
		move.w	d2,pln2l

		move.l	bufferp,a1
		lea	COPPERL(pc),a0
		move.w	#dosname-COPPERL,d0
movecop:
		move.b	(a0)+,(a1)+
		dbra	d0,movecop


		move.l	bufferp,a0	;get the address of copper instructions
		move.l	a0,COP1LC		;copper jump location address


		move.l	screenptr,d2
		move.l	bufferp,a0
		add.l	#pln1h-COPPERL,a0

; Start DMA.
;

	move.w	d0,COPJMP1		; force load into copper

; Initilize the screen locations

	move.b	#151,d0		;horizontal count
	move.b	#194,d1		;vertical count
	move.b	#164,d2		;horizontal posistion
	move.b	#144,d3		;vertical position
	move.b	#8,d4		; **** SHIP SPEED *********************
	move.b	#1,d5		; vertical increament value


	move.b	d2,$25001	; sprite #2 set screen pos
	move.b	d3,$25000	; sprite #2 set pos
	move.b	d2,$27001	; sprite #3 set pos also X Axis
	move.b	d3,$27000	; sprite #3 set pos
	
	move.w	#15,d5
topjmp:
	move.l	#4,d1
	bsr	heywait

	move.w	#12,d0
	move.l	bufferp,a1
	move.l	#color1-COPPERL,d1
	add.l	d1,a1
	move.l	#color2-color1,d1
loopme:
	move.w	(a1),d4
	beq	nosubt

	bsr	subbits
	move.w	d4,(a1)

nosubt:	
	add.l	d1,a1
	dbra	d0,loopme
	dbra	d5,topjmp




TestJoystick:


;	cmp.l	#1,misslegoing	; did I shoot the missle?
;	beq	shootmissle

	move.b	d2,sprposx
	move.b	d3,sprposy



Vloop:	
;	lea	custom,a0
;	move.b	vhposr(a0),d6
;	move.w	intreqr(a0),d6
;	and.w	#$0020,d6
;	beq	Vloop
;	move.w  #$0020,intreq(a0)
;	bsr	heywait	
	tst.b	fire		;test fire button
	bpl	shootman

;	bpl	shootmissle    ; shoot the missle!
	move.w	$dff00c,d0
	btst 	#1,d0
	bne 	right

 	btst    #9,d0
 	bne 	left

 	move.w  d0,d1
 	lsr.w 	#1,d1
 	eor.w 	d0,d1
 	btst  	#0,d1
 	bne 	back

 	btst 	#8,d1
 	bne 	foward

	bra	MouseCheck
	bra     TestJoystick
	add.b	#6,d6
	move.b	d6,$27002
	bra	TestJoystick


shootmissle:
	
	movem.l	d3/d2,-(sp)
	add.b	#2,sprposx
	add.b	#4,d3
	move.b	sprposx,$25001	; d2 is the x position 
	move.b	d3,$25000	; d3 should be same as sprite pos		
	add.b	#6,d6
	move.b	d6,$25002
	movem.l	(sp)+,d3/d2
	bra	TestJoystick


right:	
	add.l	#1,screenptr
	bsr	gohere
	Add.b   d4,d2
	move.b	d2,$27001
	move.b 	d2,d6
	bra	TestJoystick

left:

	sub.l	#1,screenptr
	bsr	gohere
	Sub.b	d4,d2
 	move.b	d2,$27001
	move.b	d2,d6
	bra 	TestJoystick

foward:

	Sub.b	d5,d3
	move.b	d3,$27000
	move.b	d3,d6
	bra 	TestJoystick

back:

	Add.b	d5,d3
	move.b	d3,$27000
	move.b	d3,d6
	bra	TestJoystick

; check if mouse button has been pressed

MouseCheck:

	btst	#6,ciaapra
	bne	TestJoystick
	

errordos:

;--- Exit program ------------------------


	move.l	copperloc,a0     ;get the address of copper instructions
	move.l	a0,COP1LC         ;copper jump location address




exit:
		move.l	gfxbase,a1
		move.l	sysbase,a6
		jsr	closelib(a6)
errorgfx:
		move.l	dosbase,a1
		move.l	sysbase,a6
		jsr	closelib(a6)

		move.l	Memarea,a1
		move.l	#98000,d0
		move.l	sysbase,a6
		jsr	FreeMem(a6)
		clr.l	d0
			

		rts

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



;*****************************************************************
;*                    Delay                                      *
;*****************************************************************

heywait:
		movem.l d0-d7/a0-a6,-(sp)
;		move.l	#9,d1			; Set # to Wait time
		move.l	dosbase,a6
		jsr	delay(a6)
		movem.l (sp)+,d0-d7/a0-a6
		rts



heywait2:

		move.l	#2,d1			; Set # to Wait time
		move.l	dosbase,a6
		jsr	delay(a6)
		rts
	


;************* Place Man ********************

shootman:
	
	move.l  screenptr,a1
;	move.l	#100,d3
;	move.l	#100,d2
;	muls.w	#80,d2
;	add.w	d3,d2   
;	add.l   d2,a1
;	move.l	d2,$c70000
;	move.l	d3,$c70004
;       	lea     man(pc),a2
;       	moveq   #1,d0

placeman2:

;       	move.b  )      ;place man data on the screen
       	move.w  #$ffaa,4(a1,d2)     ;place man data on the screen
;       	dbra    d0,placeman2
	bra     TestJoystick

go:		
		move.l	bufferp,a0	;get the address of copper instructions
		move.l	a0,COP1LC		;copper jump location address


		move.l	screenptr,d2
		move.l	bufferp,a0
		add.l	#pln1h-COPPERL,a0

gohere:
		movem.l d0-d7/a0-a6,-(sp)

		move.l	bufferp,a0	;get the address of copper instructions
		move.l	a0,COP1LC		;copper jump location address

		move.l	screenptr,d2
		move.l	bufferp,a0
		add.l	#pln1h-COPPERL,a0
	
		movem.l d0-d7/a0-a6,-(sp)
	
		move.l	#2,d1			; Set # to Wait time
		move.l	dosbase,a6
		jsr	delay(a6)
	
		move.w	d2,(a0)
		swap.w	d2
		move.w	d2,-4(a0)
		swap.w	d2

		add.l	#16000,d2
		move.w	d2,-8(a0)
		swap.w	d2

		move.w	d2,-$c(a0)
		swap.w	d2
		sub.l	#16000,d2
		
;		add.l	#1,d2
		move.l	d2,screenptr
		movem.l d0-d7/a0-a6,-(sp)

		rts

;
; This is a copper list for one bit-plane, and 8 sprites.
; The bit plane lives at $21000
; sprite 0 live at $25000; all lothers liv at $30000 (the dummy Sprites)
;
COPPERL:
	
	dc.w	bpl1pth,$0002	; bit plane 1 pointer = $21000
	dc.w	bpl1ptl,$1000	
	dc.w	spr0pth,$0002	; sprite 0 pointer = $25000 set!
	dc.w	spr0ptl,$5000
	dc.w	spr1pth,$0003	; sprite 1 pointer = $30000 set !
	dc.w	spr1ptl,$0000
	dc.w	spr2pth,$0002	; sprite 2 pointer = $27000 set !
	dc.w	spr2ptl,$7000
	dc.w	spr3pth,$0003	; sprite 3 pointer = $35000 Dummy Sprite
	dc.w 	spr3ptl,$5000
	dc.w	spr4pth,$0004	; sprite 4 pointer = $40000
	dc.w 	spr4ptl,$0000
	dc.w	spr5pth,$0004	; sprite 5 pointer = $40000
	dc.w 	spr5ptl,$0000
	dc.w	spr6pth,$0004	; sprite 6 pointer = $40000
	dc.w 	spr6ptl,$0000
	dc.w	spr7pth,$0004	; sprite 7 pointer = $40000
	dc.w 	spr7ptl,$0000
;       	dc.w	$ffff,$fffe	; end of copper list


	dc.w	$01a2,$0f00	; Sprite 0 Color
	dc.w	$01a4,$0fff
	dc.w	$01a6,$0999	
	dc.w	$01aa,$0f00	; Sprite 1 Color
	dc.w	$01ac,$0fff
	dc.w	$01ae,$0999	
	dc.w	$01b2,$0f00	; Sprite 2 Color
	dc.w	$01b4,$0fff
	dc.w	$01b6,$0999	


	
            dc.w $0100,$0200
            dc.w $0201,$fffe

	    dc.w $2801,$fffe
            dc.w $0100,$0200
	    dc.w $008e,$002c	
;            dc.w $008e,$0581         ;diwstart
            dc.w $0090,$ffc1         ;diwstop
	    dc.w $00e4
pln2l:	    dc.w $0000    *    ;bit plane display area 2(low)
            dc.w $00e6
pln2h:	    dc.w $0000    *    ;bit plane display area 2(high)
            dc.w $00e0
pln1l:	    dc.w $0000    *    ;                       1(low)
            dc.w $00e2
pln1h:	    dc.w $0000    *    ;                       1(high)
            dc.w $0092,$003c
            dc.w $0094,$00d4
            dc.w $0104,$0024
            dc.w $0102,$0000 	;
            dc.w $0108,$0028	; modulo playfield 1
            dc.w $010a,$0028	; modulo playfield 2
            dc.w $0100,$2200	;bit plane control 

            dc.w $0182,$0000
            dc.w $0184,$0fff

            dc.w $0186
color1:		dc.w  $0f80

            dc.w $3001,$fffe         ;wait for line 30

            dc.w $0180
color2:		dc.w $0fac         ;move black to color register (180)
            dc.w $4001,$fffe         ;wait for line 132
            dc.w $0180
		dc.w $00f0         ;move sky blue to color register
            dc.w $5001,$fffe         ;wait for line 200
            dc.w $0180
        	dc.w $00db         ;move pink to color register
            dc.w $6001,$fffe
            dc.w $0180,$0ff0         ;green
            dc.w $7001,$fffe
            dc.w $0180,$00bb         ;orange
            dc.w $8001,$fffe
            dc.w $0180,$06fe         ;brown
            dc.w $9001,$fffe
            dc.w $0180,$0db9         ;magenta
            dc.w $a001,$fffe
            dc.w $0180,$01fb         ;medium grey
            dc.w $b001,$fffe
            dc.w $0180,$0bf0         ;red
            dc.w $c001,$fffe
            dc.w $0180,$00b1         ;blue
            dc.w $d001,$fffe
            dc.w $0180,$0f00         ;lemon yellow
            dc.w $e001,$fffe
            dc.w $0180,$0c1f         ;tan
            dc.w $f001,$fffe         ;wait for end of screen
            dc.w $0100,$0200         ;turn off bit planes
            dc.w $ffff,$fffe         ;wait until you jump again


;
; Sprite data for space ship. It appears on the screen at v=65 and h=128
;

SPRITE:
	DC.W  $001e,$0021,$FE00,$4100,$FFF8,$AA48,$95BC,$0000
	DC.W  $001C,$7FD3,$4EE0,$0070,$3080,$4000,$0000,$0000


SPRITE2:

	DC.W  $0016,$0016,$007F,$0082,$1FFF,$1255,$3DA9,$7803
	DC.W  $3800,$CBFE,$0772,$0E00,$010C,$0002,$0000,$0000


SPRITE3:

	DC.W  $6d60,$7200,$0000,$0001,$0001,$0001,$0001,$0001
	DC.W  $0001,$0001,$0001,$0001,$0001,$0001,$0000,$0000

SPRITE4: ; This is the dummy sprite that all will be moved into

	DC.W  $0016,$0016,$007F,$0082,$1FFF,$1255,$3DA9,$7803
	DC.W  $3800,$CBFE,$0772,$0E00,$010C,$0002,$0000,$0000
clrspr:

	DC.W  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

man:         
		dc.b   $ff,$aa
		dc.b   $ff

dosname:	dc.b	'dos.library',0
		cnop	0,2

gfxname:	dc.b	'graphics.library',0
		cnop	0,2

filename:	dc.b	'picture1',0
		cnop	0,2




pos_foward	dc.w	0
pos_back	dc.w	0
pos_right	dc.w	0
pos_left	dc.w	0
dosbase		dc.l	0
bitplane1	dc.l	0
gfxbase:       	dc.l    0
copperloc	dc.l	0
Memarea:	dc.l	0
bufferp:	dc.l	0	;bufferarea
buffers:	dc.l	0	;bufferarea
buffere:	dc.l	0	;bufferarea+4000
screenptr:	dc.l	0
filehd:		dc.l	0
goahead		dc.l	0
misslegoing	dc.l	0
sprposx		dc.b	0
sprposy		dc.b	0

