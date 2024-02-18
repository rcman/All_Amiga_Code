*    Hopefully this program will set up
*    Copper instructions

DMACONW  EQU $DFF096
COP1LC   EQU $DFF080
COP2LC   EQU $DFF084
COPJMP1  EQU $DFF088
COPJMP2  EQU $DFF08A

      move.w   #$4,d1            ;counter
      lea      copper_ins,a0     ;get the address of copper instructions
      move.l   #$70000,COP1LC         ;copper jump location address
      move.l   $25c0,a1

getbit:
	 move.w   $7a(a1),d0
      move.w   d0,$1e(a0)
      add.l    #$4,a0
      add.l    #$4,a1
      sub.w    #$1,d1
      bne.s   getbit
      move.w   COPJMP1,d0        ;make the copper jump to the given address
      move.l   #$70000,a1
      sub.l    #$10,a0

movemem: 
	move.l   (a0)+,(a1)+    ;move to 70000 hex
     	cmp.l    #$70300,a1        ;amount to move 300 hex
     	ble.s    movemem           ;keep branching until its all moved
     	rts                        ;go back to where ever!

*     copper instructions

copper_ins:
            dc.w $0100,$0200
            dc.w $0120,$0000
            dc.w $0122,$41c8
            dc.w $2801,$fffe
            dc.w $0100,$0200
            dc.w $008e,$0581         ;diwstart
            dc.w $0090,$ffc1         ;diwstop
firsta:     dc.w $00e4,$0000    *    ;bit plane display area 2(low)
            dc.w $00e6,$0000    *    ;bit plane display area 2(high)
            dc.w $00e0,$0000    *    ;                       1(low)
            dc.w $00e2,$0000    *    ;                       1(high)
            dc.w $0092,$003c
            dc.w $0094,$00d4
            dc.w $0104,$0024
            dc.w $0102,$0000
            dc.w $0108,$0000
            dc.w $010a,$0000
            dc.w $0100,$a200
            dc.w $0182,$0000
            dc.w $0184,$0fff
            dc.w $0186,$0f80
            dc.w $3001,$fffe         ;wait for line 30
            dc.w $0180,$0000         ;move black to color register (180)
            dc.w $4001,$fffe         ;wait for line 132
            dc.w $0180,$06fe         ;move sky blue to color register
            dc.w $5001,$fffe         ;wait for line 200
            dc.w $0180,$0fac         ;move pink to color register
            dc.w $6001,$fffe
            dc.w $0180,$00f0         ;green
            dc.w $7001,$fffe
            dc.w $0180,$0f90         ;orange
            dc.w $8001,$fffe
            dc.w $0180,$0c80         ;brown
            dc.w $9001,$fffe
            dc.w $0180,$0f1f         ;magenta
            dc.w $a001,$fffe
            dc.w $0180,$0999         ;medium grey
            dc.w $b001,$fffe
            dc.w $0180,$0f00         ;red
            dc.w $c001,$fffe
            dc.w $0180,$000f         ;blue
            dc.w $d001,$fffe
            dc.w $0180,$0ff0         ;lemon yellow
            dc.w $e001,$fffe
            dc.w $0180,$0db9         ;tan
            dc.w $f001,$fffe         ;wait for end of screen
            dc.w $0100,$0200         ;turn off bit planes
            dc.w $ffff,$fffe         ;wait until you jump again
      end
