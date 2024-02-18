;   E X A M P L E: Rotate Blt 


;   Here we rotate bits.  This code takes a single rast;   bitplane, and 'rotates' it into an array of 16-bit;   the specified bit of each word in the array accordi;   corresponding bit in the raster row.  We use the li;   conjunction w th patterns to do this magic.
;   Input:  dO contains the number of words in the rast;   contains the number of the bit to set (0..15).  aO;   pointer to the raster data, and al contains a poinl;   array we are filling; the array must be at least (<;   (or (d0)*32 bytes) long.


  include 'dh0:lc/include/exec/types.i'
  include 'dh0:lc/include/hardware/custom.i'
  include 'dh0:lc/include/hardware/blit.i'
  include 'dh0:lc/include/hardware/dmabits.i'
  include 'include/franco.i'


rotatebits:

	move.l	#20,d0
	lea	array,a1
	
        
	lea     custom,a2     	 ; We need to access tl
        tst     d0               ; if no words, just r 
        beq     gone
        lea     DMACONR(a2),a3   ; get the address of <
        moveq.l #DMAB,BLTDONE-8,d2      ; get the bit
        btst    d2,(a3)          ; check to see if we'.
waitl:
        btst    d2,(a3)          ; check again.
        bne     wait1            ; not done?  Keep wai
        moveq.I #-30,d3          ; Line mode:  aptr =
        move.1  d3,BLTAPT(a2)
        move.w  #-60,BLTAMOD(a2) ; amod = 4Y-4
        clr.w   BLTBMOD(a2)      ; bmod = 4Y
        move.w  #2,BLTCMOD(a2)   ; cmod = width of bit
        move.w  2,BLTDMOD(a2)   ; ditto
        ror.w   #4,dl            ; grab the four bits
        and.w   #$fOOO,dl       ; mas  them out
        or.w    #$bca,dl        ; USEA, USEC, USED, 
        move.w  dl,BLTCON0(a2)  ; stuff it
        move.w  $f049,BLTCON1(a2)      ; BSH=15, SG


        move.w  $8000,BLTADAT(a2)      ; Initialize
        move.w  $ffff,BLTAFWM(a2)      ; Initialize
        move.w  $ffff,BLTALWM(a2)
        move I  a1,BLTCPT(a2)   ; Initialize pointer
        move.I  a1,BLTDPT(a2)
        lea     BLTBDAT(a2),a4  ; For quick access,
        lea     BLTSlZE(a2),a5  ; addresses
        move.w  #$402,dl        ; Stuff bltsize; wid

         move.w  (a0)+,d3        ; Get next word
         bra     inloop          ; Go into the loop



   04  A miga Hardware Reference Manua/

again:
        move.w  (a0)+,d3        ; Grab another word
        btst    d2,(a3)         ; Check blit done
wait2:
        btst    d2,(a3)         ; Check aga n
        bne     wait2           ; oops, not ready, 
inloop:
        move.w  d3,(a4)         ; stuff new word to 
        move.w  dl,(a5)         ; start the blit
        subq.w  #1,d0           ; is that the last wi
        bne     again           ; keep go ng if not
gone:
        rts
        end

array:	ds.w	1000
