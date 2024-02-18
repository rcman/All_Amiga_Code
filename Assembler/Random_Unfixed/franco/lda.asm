; Sprite program wrinten by Franco Gaetan
; CustomChip-Register

open        equ -30
close       equ -36
read        equ -42
mode_old    equ 1005
sysbase	    equ 4
AllocMem    equ -198
FreeMem     equ -210	
closelib	equ -414
DMACONW		equ $dff096


movescreen  equ -162
openscreen  equ -198
closescreen equ -66
closelibrary equ -414
openlib equ -408
execbase equ 4

copper_halt	equ $fffffffe
custom 		equ $dff000        ; Hardware Register

intena		equ $9a            ; interupt-enable-register (write)
intreq 		equ $09c
intreqr 	equ $1e            ; interupt-request-register (read)
dmacon 		equ $096           ; DMA-Control palette register (write)


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
copjmp1 equ $088
copjmp2 equ $08a
;cop1lc  equ $080
;cop2lc  equ $084	

; ****************************************************************
; *** Start Program ***
; ****************************************************************

;

;;--- Get Dos base --------------------------
;		moveq	#0,d0
;		move.l	sysbase,a6
;		lea	dosname(pc),a1
;		jsr	openlib(a6)
;		move.l	d0,dosbase
;		beq	errordos

;--- Get Graphics base --------------------------
		moveq	#0,d0
		move.l	sysbase,a6
		lea	gfxname(pc),a1
		jsr	openlib(a6)
		move.l	d0,gfxbase
		beq	errorgfx

		move.l	d0,a0
		move.l	$26(a0),copperloc


		bra	start 	; get the librarys started



	
getthescreen:
        
	bsr	loadscreen  	; load the screen		

	lea 	custom,a0	   ; Custom Chip location	
	move.w	#$4200,bplcon0(a0) ; Point a0 at custom chips
	move.w  #$0000,bpl1mod(a0) ; 1 bit plane color is on
	move.w  #$0000,bplcon1(a0) ; modulo = 0
	move.w	#$0024,bplcon2(a0) ; horizontal scroll value = 0
	move.w	#$0038,ddfstrt(a0) ; sprite have priority over playfield
	move.w  #$00d0,ddfstop(a0) ; set data-fetch stop


; Display window defintion.

	move.w	#$2c81,diwstrt(a0) ; Set display window start
				   ; vertical start in high byte.
				   ; horizontal start = 2 in low byte
	move.w	#$f4c1,diwstop(a0) ; Set display window stop
				   ; vertical stop in high byte.
			           ; horizontal stop = 2 in low byte
;
; Set up color registers for sprite 1.
;
	move.w	#$0000,color00(a0)	; background color = dark blue
	move.w 	#$0000,color01(a0)	; foreground color = black
;	move.w	#$0f00,color17(a0)	; color 17 = yellow
;	move.w 	#$0fff,color18(a0)	; color 18 = cyan
;	move.w	#$0999,color19(a0)	; color 19 = magenta



;
; Set up color registers for sprite 2.
;
	move.w	#$0f00,color21(a0)	; color 17 = yellow
	move.w 	#$0fff,color22(a0)	; color 18 = cyan
	move.w	#$0999,color23(a0)	; color 19 = magenta


;
; Set up color registers for sprite 3.
;
;	move.w	#$0f00,color24(a0)	; color 17 = yellow
	move.w 	#$0fff,color25(a0)	; color 18 = cyan
	move.w	#$0999,color26(a0)	; color 19 = magenta

;
; Set up color registers for sprite 4.
;
	move.w	#$0ff0,color25(a0)	; color 17 = yellow
	move.w 	#$00ff,color26(a0)	; color 18 = cyan
	move.w	#$0f0f,color27(a0)	; color 19 = magenta


;
; move copper list to $20000

	move.l	#$20000,a1		; point a1 at copper list destination
	lea 	COPPERL(pc),a2		; point a2 at copper list source

CLOOP:
	move.l	(a2),(a1)+		; move a long word
	cmp.l	#$fffffffe,(a2)+	; check for end of list
	bne	CLOOP			; loop until entire list is moved
;
; move sprite to $25000 this is where sprite 1 sits
;

	move.l	#$25000,a1		; point a1 at sprite destination
	lea 	SPRITE(pc),a2		; point a2 at sprite source

SPRLOOP1:
	move.l	(a2),(a1)+		; move long word
	cmp.l 	#$00000000,(a2)+  	; ckeck for end of sprite
	bne	SPRLOOP1		; loop until entire sprite is moved



; Sprite Data 2 into location 25100

	move.l	#$30000,a1
	lea	SPRITE2(pc),a2



SPRLOOP2:
	move.l	(a2),(a1)+		; move long word
	cmp.l 	#$00000000,(a2)+  	; ckeck for end of sprite
	bne	SPRLOOP2		; loop until entire sprite is moved


; Sprite Data 3 into location 35000

	move.l	#$27000,a1
	lea	SPRITE3(pc),a2



SPRLOOP3:
	move.l	(a2),(a1)+		; move long word
	cmp.l 	#$00000000,(a2)+  	; ckeck for end of sprite
	bne	SPRLOOP3		; loop unti



; Sprite Data 4 into location 30000 this is the dummy sprite

	move.l	#$35000,a1
	lea	SPRITE4(pc),a2



SPRLOOP4:
	move.l	(a2),(a1)+		; move long word
	cmp.l 	#$00000000,(a2)+  	; ckeck for end of sprite
	bne	SPRLOOP4		; loop unti


	;

; Now we write a dummy sprite to $30000, since all eight sprites are activated
; at the same time ane we're only going to use one. The remaining sprites
; will point to this dummy sprite data.
;
	move.l	#$00000000,$70000	; Write it

; fill bit-plane with 
;
	move.l	$50000,a2
	move.l	#$21000,a1
	move.l	#$21000,a1	; point a1 at bit-plane.
	move.l	#1999,d0	; 2000-1(for dbf) long words = 8000 bytes

FLOOP:
	move.l	a2,(a1)+
;	move.l	#$ffffffff,(a1)+	; move a long word of $ffffffff
	dbf	d0,FLOOP		; Decrement, repeat until false

;
; point copper at copper list
;
	move.l 	#$20000,COP1LC

	
;
; Start DMA.
;

	move.w	d0,copjmp1(a0)		; force load into copper
					; program counter
;	move.w 	#$83a0,DMACONW   	; bit-plane, copper, and sprite DMA
        				; ..return to rest of program..

; Initilize the screen locations

	move.b	#151,d0		; horizontal count
	move.b	#194,d1		; vertical count
	move.b	#189,d2		; horizontal posistion
	move.b	#144,d3		; vertical position
	move.b	#1,d4		; horizontal increment value
	move.b	#1,d5		; vertical increament value
	move.b	d2,$35001	; sprite #2 set screen pos
	move.b	d3,$35000	; sprite #2 set pos

Vloop:
	move.w	intreqr(a0),d6		; read interupt request word
	and.w	#$0020,d6		; mask off all but vertical blank bit
	beq	Vloop			; loop until bit is a 1
	move.w	#$0020,intreq(a0)	; vertical bit is on
	
	

TestJoystick:
 
	
	tst.b	fire		;test fire button
	bpl	shootmissle    ; shoot the missle!
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
;	bra     TestJoystick
;	add.b	#6,d6
;	move.b	d6,$35002
	bra	Vloop



shootmissle:

	move.b	d2,$27001	; d2 is the x position 
	move.b	d3,$27000	; d3 should be same as sprite pos		
	bra	TestJoystick

right:	
	move.w	d0,pos_right
	move.l	#$25000,a1
	move.l	#$35000,a2
a:	move.l  (a1),(a2)+
	cmp.l	#$00000000,(a1)+
	bne 	a
	sub.b   d4,d2
;	cmp.w	#$199,pos_right
;	ble	left
	move.b	d2,$35001
	move.b 	d2,d6
	bra	TestJoystick

left:
	move.w	d0,pos_left
	move.l	#$30000,a1
	move.l	#$35000,a2
b:	move.l  (a1),(a2)+
	cmp.l	#$00000000,(a1)+
	bne 	b
	Sub.b	d4,d2
;	cmp.w	#$190,pos_left
;	ble	foward
	move.b	d2,$35001
	move.b	d2,d6
	bra 	TestJoystick

foward:

	move.w	d0,pos_foward
	Sub.b	d5,d3
;	cmp.w	#$10,pos_foward
;	ble	back
	move.b	d3,$35000
	move.b	d3,d6
	bra 	TestJoystick

back:

	move.w	d0,pos_back
	Add.b	d5,d3
;	cmp.w	#$99,pos_back
;	bhi	TestJoystick
	move.b	d3,$35000
	move.b	d3,d6
	bra	TestJoystick

; check if mouse button has been pressed

MouseCheck:

	btst	#6,ciaapra
	bne	TestJoystick
	
ende:

	move.l	copperloc,a0     ;get the address of copper instructions
	move.l	a0,COP1LC         ;copper jump location address

;--- Exit program ------------------------

exit:
		move.l	gfxbase,a1
		move.l	sysbase,a6
		jsr	closelib(a6)
errorgfx:
		move.l	dosbase,a1
		move.l	sysbase,a6
		jsr	closelib(a6)
errordos:
		move.l	Memarea,a1
		move.l	#98000,d0
		move.l	sysbase,a6
		jsr	FreeMem(a6)
		clr.l	d0
errormem:
error:

	       move.l  execbase,a6     ;*close Intuition
       	       move.l  intbase,a1      ;intuition base address in A1
       	       jsr     closelibrary(a6);close intuition


	       move.l  intbase,a6      ;Intuition base address in A6
      	       move.l  screenhd,a0     ;Screen Handle in A0
      	       jsr     closescreen(a6) ;And Move
      		
		rts
	


	
;
; This is a copper list for one bit-plane, and 8 sprites.
; The bit plane lives at $21000
; sprite 0 live at $25000; all others live at $30000 (the dummy Sprites)
;


;**************************************************************************

;setrgb4     equ  -288


start:

	bsr     openint         ;Open library
	bsr     scropen         ;Open Screen
	bra	getthescreen

	

loadscreen:	

;--- Allocate Memory -----------------------

		move.l	sysbase,a6
		move.l	#98000,d0
		move.l	#$10002,d1
		jsr	AllocMem(a6)
		move.l	d0,Memarea
		move.l	d0,buffers
		beq	ende
		move.l	d0,bufferp
		add.l	#2000,d0
		move.l	d0,bitplane2

        move.l  $4,a6
        lea     dosname(pc),a1
        moveq   #0,d0
        jsr     openlib(a6)
        move.l  d0,dosbase

        move.l  d0,a6
        lea     dosfile(pc),a1    ;file name
        move.l  a1,d1
        move.l  #mode_old,d2
        jsr     open(a6)          ;open the file

        move.l  d0,filehandle

        move.l  bitplane1,d2      ;buffer
        move.l  #8000,d3          ;length
        move.l  d0,d1             ;file handle
        move.l  dosbase,a6
        jsr     read(a6)          ;read in the picture

       	move.l	$50000,a2
	move.l  bitplane2,d2      ;buffer
        move.l  #8000,d3          ;length
        move.l  filehandle,d1             ;file handle
        move.l	d1,(a2)+
	move.l  dosbase,a6
        jsr     read(a6)          ;read in the picture

        move.l  bitplane3,d2      ;buffer
        move.l  #8000,d3          ;length
        move.l  filehandle,d1             ;file handle
        move.l  dosbase,a6
        jsr     read(a6)          ;read in the picture
	
        move.l  bitplane4,d2      ;buffer
        move.l  #8000,d3          ;length
        move.l  filehandle,d1             ;file handle
	move.l  dosbase,a6
        jsr     read(a6)          ;read in the picture


        move.l  bitplane5,d2      ;buffer
        move.l  #8000,d3          ;length
        move.l  filehandle,d1             ;file handle
        move.l  dosbase,a6
        
	jsr     read(a6)          ;read in the picture
	
	
	

        move.l  filehandle,d1
        move.l  dosbase,a6
   	jsr     close(a6)
	
	rts




;********************* STOP RIGHT THERE ! *******************************
;************* Place Man ********************

	
       move.l  bitplane1,a1
       add.l   #4019,a1

       lea     man(pc),a2
       moveq   #13,d0

placeman:

       move.b  (a2)+,(a1)      ;place man data on the screen
       move.b  (a2)+,1(a1)     ;place man data on the screen
       add.l   #40,a1          ;move plane pointer down one scan line
       dbra    d0,placeman

waitleave:
       move.b  fire,d0
       and.b   #$80,d0
       bne     waitleave

ende2:
       bsr     scrclose        ;close screen
       bsr     closeint        ;close intuition
       rts                     ;Done !


;       move.l  #0,d0           ;pen
;       move.l  #0,d1           ;red
;       move.l  #0,d2           ;green
;       move.l  #0,d3           ;blue
;       move.l  viewport,a0     ;Get Pointer to View Port
;       move.l  gfxbase,a6      ;get grapics base
;       jsr     setrgb4(a6)     ;set a color registor

openint:

       move.l  execbase,a6     ;EXEC base address
       lea     intname,a1      ;name of intuition library
       jsr     openlib(a6)     ;Open intuition
       move.l  d0,intbase      ;Save Intuition base address
       rts

closeint:

       move.l  execbase,a6     ;*close Intuition
       move.l  intbase,a1      ;intuition base address in A1
       jsr     closelibrary(a6);close intuition
       rts                     ;Done

scropen:

       move.l  intbase,a6      ;Intuition base address in A6
       lea     screen_defs,a0  ;Pointer to Table
       jsr     openscreen(a6)  ;OPen
       move.l  d0,screenhd     ;Save Screen Handle
       move.l  d0,a0           ;get screen pointer ready
       move.l  $c0(a0),bitplane1       ;get pointer to bit plane # 1
       move.l  $c4(a0),bitplane2       ;get pointer to bit plane # 2
       move.l  $c8(a0),bitplane3 		
       move.l  $cc(a0),bitplane4
       move.l  $d0(a0),bitplane5
       move.l  $2c(a0),viewport        ;get pointer to view port
       rts                     ;Return to Main Program

scrclose:

       move.l  intbase,a6      ;Intuition base address in A6
       move.l  screenhd,a0     ;Screen Handle in A0
       jsr     closescreen(a6) ;And Move
       rts                     ;Done

;scrmove:
;       move.l  intbase,a6      ;Intuition base in A6
;       move.l  screenhd,a0     ;Screen Handle in A0
;       clr.l   d0              ;No horizontal movement
;       jsr     movescreen(a6)  ;And Move
;       rts                     ;Done
       
screen_defs:
x_pos:         dc.w    0       ;x-position
y_pos:         dc.w    0       ;y-position
width:         dc.w    320     ;width
height:        dc.w    200     ;height
depth:         dc.w    5       ;Number of Bit Planes 2
detail_pen:    dc.b    1       ;Text Colour equ  White
block_pen:     dc.b    3       ;Background Color equ  Red
view_modes:    dc.w    2       ;Representation Mode
screen_types:  dc.w    15      ;Screen Type:Custom Screen
font:          dc.l    0       ;Standard Character Set
title:         dc.l    sname   ;Pointer to title text
gadgets:       dc.l    0       ;No gadgets
bitmap:        dc.l    0       ;No Bit Map
intbase:       dc.l    0       ;Base Address of Intuition
screenhd:      dc.l    0       ;Screen Handle
intname:       dc.b    'intuition.library',0
       
gfxname:       dc.b    'graphics.library',0
       
dosname:       dc.b    'dos.library',0
       
dosfile        dc.b    'dh0:assem/picture1',0
       
sname:         dc.b    'Our Screen',0 ;Screen Title
       
rastport:      dc.l    0
viewport:      dc.l    0
gfxbase:       dc.l    0
dosbase:       dc.l    0
filehandle:    dc.l    0

bitplane1:     dc.l    0
bitplane2:     dc.l    0
bitplane3:     dc.l    0
bitplane4:     dc.l    0
bitplane5:     dc.l    0

man:           dc.b    1,$80,2,$40,1,$80,7,$e0,$d,$b0,9,$90
               dc.b    $11,$88,3,$c0,2,$40,6,$60,$c0,$30,$18,$18

COPPERL:
	dc.w	bpl1pth,$0005	; bit plane 1 pointer = $21000
	dc.w	bpl1ptl,$0000	
	dc.w	spr0pth,$0002	; sprite 0 pointer = $25000 set!
	dc.w	spr0ptl,$5000
	dc.w	spr1pth,$0003	; sprite 1 pointer = $30000 set !
	dc.w	spr1ptl,$0000
	dc.w	spr2pth,$0002	; sprite 2 pointer = $27000 set !
	dc.w	spr2ptl,$7000
	dc.w	spr3pth,$0003	; sprite 3 pointer = $35000 Dummy Sprite
	dc.w 	spr3ptl,$5000
	dc.w	spr4pth,$0007	; sprite 4 pointer = $40000
	dc.w 	spr4ptl,$0000
	dc.w	spr5pth,$0007	; sprite 5 pointer = $40000
	dc.w 	spr5ptl,$0000
	dc.w	spr6pth,$0007	; sprite 6 pointer = $40000
	dc.w 	spr6ptl,$0000
	dc.w	spr7pth,$0007	; sprite 7 pointer = $40000
	dc.w 	spr7ptl,$0000
	dc.w	$ffff,$fffe	; end of copper list
;
; Sprite data for space ship. It appears on the screen at v=65 and h=128
;

SPRITE:
	DC.W  $6d60,$7200,$FE00,$4100,$FFF8,$AA48,$95BC,$0000
	DC.W  $001C,$7FD3,$4EE0,$0070,$3080,$4000,$0000,$0000
	DC.W  $001e,$0021,$007F,$0082,$1FFF,$1255,$3DA9,$7803
	DC.W  $3800,$CBFE,$0772,$0E00,$010C,$0002,$0000,$0000


SPRITE2:

	DC.W  $6d60,$7200,$007F,$0082,$1FFF,$1255,$3DA9,$7803
	DC.W  $3800,$CBFE,$0772,$0E00,$010C,$0002,$0000,$0000


SPRITE3:

	DC.W  $001e,$0021,$0000,$0001,$0001,$0001,$0001,$0001
	DC.W  $0001,$0001,$0001,$0001,$0001,$0001,$0000,$0000

SPRITE4: ; This is the dummy sprite that all will be moved into

	DC.W  $001e,$0021,$007F,$0082,$1FFF,$1255,$3DA9,$7803
	DC.W  $3800,$CBFE,$0772,$0E00,$010C,$0002,$0000,$0000
clrspr:

	DC.W  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

pos_foward	dc.w	0
pos_back	dc.w	0
pos_right	dc.w	0
pos_left	dc.w	0
buffers		dc.l	0
bufferp		dc.l	0
screenprt	dc.l	0
Memarea		dc.l	0
copperloc	dc.l	0
	
	end

