
;            ----------------------------------------
;            -                                      -
;            -         "LA BOUM II - THEME"         -
;            -                                      -
;            -  spreaded  by   M F C    in  1987    -
;            -                                      -   
;            ----------------------------------------

irqvec       equ $00000068
dmacon       equ $dff096
timerlo      equ $00
timerhi      equ $28
talo         equ $bfe401
tahi         equ $bfe501
icr          equ $bfed01
cra          equ $bfee01
aud0lch      equ $a0
aud0lcl      equ $a2
aud0len      equ $a4
aud0per      equ $a6
aud0vol      equ $a8
s_wavedco    equ 0
s_envelope   equ 32       
s_sus        equ 48
s_end        equ 49
s_wavelfo    equ 50
s_spdlfo     equ 66+16
s_slctlfo    equ 67+16
s_typelfo    equ 68+16
s_phase      equ 69+16
s_arp        equ 70+16
s_spdport    equ 78+16
s_spdbend    equ 80+16
s_egfreq     equ 82+16
v_sactive    equ 0
v_envpoint   equ 4
v_lfowpoint  equ 8
v_phmark     equ 12
v_notetim    equ 14
v_lfotim     equ 16
v_arpoint    equ 18
v_actnote    equ 22
v_wntnote    equ 24
v_hardw      equ 26
v_trkstp     equ 30
v_crnot      equ 34
v_trkbck     equ 38
v_actfrq     equ 42
v_trnspse    equ 46
v_savnote    equ 50
v_add        equ 52
v_pauspnt    equ 54
v_actloud    equ 56

on:
	move.l #$1,d0
	jsr beg
	rts

off:
	move.l #$0,d0
	jsr beg
	rts

beg:
	jmp progstart

saveirqvec:
	dc.l 0

sound1:
	dc.b 127,127,127,127,127,127,127,127,-128,-128  ; WaveForm DCO
	dc.b -128,127,127,-128,-128,-128,127,127,127,127,127
	dc.b 127,127,127,127,127,127,127,127,127,127,127

	dc.b 50,175,6,0,0,0,0,0,0,0,0,0,0,0,0,0  ; Envelope (Rate/Level)
	dc.b 0,2  ; No SUS, END is step #2

	dc.b -128,-128,-128,-128,-128,-128,-128,-128,-128,-128  ; WaveForm LFO
	dc.b -128,-128,-128,-128,-128,-128,127,127,127,127,127
	dc.b 127,127,127,127,127,127,127,127,127,127,127
	dc.b 0  ; Speed LFO
	dc.b 1+2  ; LFO for Amplitude & Frequency
	dc.b 1  ; LFO: on

	dc.b 0  ; Depth of Phasing, 0=none

	dc.b 0,0,0,0,0,0,0,0  ; Arpeggio

	dc.w 0  ; Speed Portamento (0=none)

	dc.w 0  ; BendRate

	dc.w 0  ; EG frequency off


sound2:
	dc.b 127,127,127,127,127,127,127,127,-128,-128  ; WaveForm DCO
	dc.b -128,127,127,-128,-128,-128,127,127,127,127,127
	dc.b 127,127,127,127,127,127,127,127,127,127,127

	dc.b 255,255,7,100,3,0,0,0,0,0,0,0,0,0,0,0  ; Envelope (Rate/Level)
	dc.b 0,3  ; No SUS, END is step #2

	dc.b -128,-120,-112,-104,-96,-88,-80,-72,-64,-56  ; WaveForm LFO
	dc.b -48,-40,-32,-24,-16,-8,0,8,16,24,32
	dc.b 40,48,56,64,72,80,88,96,104,112,127
	dc.b 0  ; Speed LFO
	dc.b 1+2  ; LFO for Amplitude & Frequency
	dc.b 1  ; LFO: on

	dc.b 0  ; Depth of Phasing, 0=none
	
	dc.b 0,0,0,0,0,0,0,0  ; Arpeggio

	dc.w 0  ; Speed Portamento (0=none)

	dc.w 0  ; BendRate

	dc.w 0  ; EG frequency off


sound3:
	dc.b -128,-128,-128,-128,-128,-128,-128,-128,-128,-128  ; WaveForm DCO
	dc.b -128,-128,-128,-128,-128,-128,127,127,127,127,127
	dc.b 127,127,127,127,127,127,127,127,127,127,127

	dc.b 255,255,25,0,0,0,0,0,0,0,0,0,0,0,0,0  ; Envelope (Rate/Level)
	dc.b 0,2  ; No SUS, END is step #2

	dc.b -128,-128,-128,-128,-128,-128,-128,-128,-128,-128  ; WaveForm LFO
	dc.b -128,-128,-128,-128,-128,-128,127,127,127,127,127
	dc.b 127,127,127,127,127,127,127,127,127,127,127
	dc.b 0  ; Speed LFO
	dc.b 1+2  ; LFO for Amplitude & Frequency
	dc.b 1  ; LFO: on

	dc.b 0  ; Depth of Phasing, 0=none

	dc.b 0,0,0,0,0,0,0,0  ; Arpeggio

	dc.w 0  ; Speed Portamento (0=none)

	dc.w -50  ; BendRate

	dc.w 0  ; EG frequency off


sound4:
	dc.b -128,-128,-128,-128,-128,-128,-128,-128,-128,-128  ; WaveForm DCO
	dc.b -128,-128,-128,-128,-128,-128,127,127,127,127,127
	dc.b 127,127,127,127,127,127,127,127,127,127,127

	dc.b 255,255,15,0,0,0,0,0,0,0,0,0,0,0,0,0  ; Envelope (Rate/Level)
	dc.b 0,2  ; No SUS, END is step #2

	dc.b -128,-128,-128,-128,-128,-128,-128,-128,-128,-128  ; WaveForm LFO
	dc.b -128,-128,-128,-128,-128,-128,127,127,127,127,127
	dc.b 127,127,127,127,127,127,127,127,127,127,127
	dc.b 0  ; Speed LFO
	dc.b 1+2  ; LFO for Amplitude & Frequency
	dc.b 1  ; LFO: on

	dc.b 0  ; Depth of Phasing, 0=none

	dc.b 0,0,0,0,0,0,0,0  ; Arpeggio

	dc.w 0  ; Speed Portamento (0=none)

	dc.w -50  ; BendRate

	dc.w 0  ; EG frequency off


sound5:
	dc.b -128,-128,-128,-128,-128,-128,-128,-128,127,127  ; WaveForm DCO
	dc.b 127,127,127,127,127,127,-128,-98,-68,-38,-8,28
	dc.b 58,78,98,118,120,122,124,125,126,127

	dc.b 50,255,4,80,0,0,0,0,0,0,0,0,0,0,0,0  ; Envelope (Rate/Level)
	dc.b 0,2  ; No SUS, END is step #2

	dc.b -128,-128,-128,-128,-128,-128,127,127,127,127  ; WaveForm LFO
	dc.b 127,127,127,127,127,127,127,127,127,127,127
	dc.b 127,127,127,127,127,127,127,127,127,127,127
	dc.b 0  ; Speed LFO
	dc.b 0
	dc.b 1  ; LFO on

	dc.b 4  ; Depth of Phasing, 0=none

	dc.b 0,0,0,0,0,0,0,0  ; Arpeggio

	dc.w 0  ; Speed Portamento (0=none)

	dc.w 0  ; BendRate

	dc.w 0  ; EG frequency off


even
freqtab:
	dc.w 6848,6464,6096,5760,5424,5120,4832,4560,4304,4064,3840,3616
	dc.w 3424,3232,3048,2880,2712,2560,2416,2280,2152,2032,1920,1808
	dc.w 1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,0960,0904
	dc.w 0856,0808,0762,0720,0678,0640,0604,0570,0538,0508,0480,0452
	dc.w 0428,0404,0381,0360,0339,0320,0302,0285,0269,0254,0240,0226
	dc.w 0214,0202,0190,0180,0170,0160,0151,0143,0135,0127

voice1:
	dc.l sound1  ; Active Sound
	dc.l 0       ; Pointer to Envelope
	dc.l 0       ; Pointer to LFO-Waveform
	dc.w 0       ; Phaser
	dc.w 0       ; Timer of Note
	dc.w 0       ; Timer of LFO-Speed
	dc.l 0       ; Pointer to Arpeggio
	dc.w 0       ; Actual Frequency
	dc.w 0       ; Wanted Frequency
	dc.l $dff0a0 ; Pointer to Hardware registers
	dc.l 0       ; Current step of track
	dc.l 0       ; Current note
	dc.l track1  ; reset track #
	dc.l 0       ; Actual frequency
	dc.l 0       ; Transpose
	dc.w 0       ; Savenote
	dc.w 0       ; Value to add
	dc.w 0       ; PausePoint
	dc.w 0       ; ActLoud

voice2:
	dc.l sound1  ; Active Sound
	dc.l 0       ; Pointer to Envelope
	dc.l 0       ; Pointer to LFO-Waveform
	dc.w 0       ; Phaser
	dc.w 0       ; Timer of Note
	dc.w 0       ; Timer of LFO-Speed
	dc.l 0       ; Pointer to Arpeggio
	dc.w 0       ; Actual Frequency
	dc.w 0       ; Wanted Frequency
	dc.l $dff0b0 ; Pointer to Hardware registers
	dc.l 0       ; Current step of track
	dc.l 0       ; Current note
	dc.l track2  ; reset track #
	dc.l 0       ; Actual frequency
	dc.l 0       ; Transpose
	dc.w 0       ; Savenote
	dc.w 0       ; Value to add
	dc.w 0       ; PausePoint
	dc.w 0       ; ActLoud

voice3:
	dc.l sound1  ; Active Sound
	dc.l 0       ; Pointer to Envelope
	dc.l 0       ; Pointer to LFO-Waveform
	dc.w 0       ; Phaser
	dc.w 0       ; Timer of Note
	dc.w 0       ; Timer of LFO-Speed
	dc.l 0       ; Pointer to Arpeggio
	dc.w 0       ; Actual Frequency
	dc.w 0       ; Wanted Frequency
	dc.l $dff0c0 ; Pointer to Hardware registers
	dc.l 0       ; Current step of track
	dc.l 0       ; Current note
	dc.l track3  ; reset track #
	dc.l 0       ; Actual frequency
	dc.l 0       ; Transpose
	dc.w 0       ; Savenote
	dc.w 0       ; Value to add
	dc.w 0       ; PausePoint
	dc.w 0       ; ActLoud

voice4:
	dc.l sound1  ; Active Sound
	dc.l 0       ; Pointer to Envelope
	dc.l 0       ; Pointer to LFO-Waveform
	dc.w 0       ; Phaser
	dc.w 0       ; Timer of Note
	dc.w 0       ; Timer of LFO-Speed
	dc.l 0       ; Pointer to Arpeggio
	dc.w 0       ; Actual Frequency
	dc.w 0       ; Wanted Frequency
	dc.l $dff0d0 ; Pointer to Hardware registers
	dc.l 0       ; Current step of track
	dc.l 0       ; Current note
	dc.l track4  ; reset track #
	dc.l 0       ; Actual frequency
	dc.l 0       ; Transpose
	dc.w 0       ; Savenote
	dc.w 0       ; Value to add
	dc.w 0       ; PausePoint
	dc.w 0       ; ActLoud

track2:
	dc.l score1,13,score1,18,score2,11,score2,16,score2,9,score2,8
	dc.l score2,13,score2,13
	dc.l 0,0
track1:
	dc.l score3,-23,score3,-18,score4,-25,score4,-20,score4,-27,score3,-24
	dc.l score4,-23,score4,-23
	dc.l 0,0
track3:
	dc.l score5,5
	dc.l 0,0
track4:
	dc.l score6,-2
	dc.l 0,0

progstart:
	movem.l d0-d7/a0-a6,-(a7)
	tst.l d0
	beq soff
	jsr switchon
	bra back
soff:
	jsr switchoff
	back:
	movem.l (a7)+,d0-d7/a0-a6
	rts

switchoff:
	cmpi.l #newirq,irqvec
	bne notoff
	move.b #$01,icr
	move.l saveirqvec,irqvec
	move.w #$000f,dmacon
	jsr setback
notoff:
	rts

switchon:
	cmpi.l #newirq,irqvec
	beq noton 
	move.b #$81,icr
	move.b #$2f,cra
	move.b #$81,cra
	move.b #timerlo,talo
	move.b #timerhi,tahi
	move.l irqvec,saveirqvec
	move.l irqvec,statement+2
	jsr setback
	jsr setup
	move.w #$800f,dmacon
	move.l #newirq,irqvec
noton:
	rts

setback:
	lea $dff000,a0
	jsr reset
	lea $dff010,a0
	jsr reset
	lea $dff020,a0
	jsr reset
	lea $dff030,a0
	jsr reset
	rts
reset:
	clr.l aud0lch(a0)
	clr.w aud0len(a0)
	clr.w aud0per(a0)
	clr.w aud0vol(a0)
	rts

setup:
	move.l #track1,v_trkstp+voice1
	move.l #track2,v_trkstp+voice2
	move.l #track3,v_trkstp+voice3
	move.l #track4,v_trkstp+voice4
	clr.l v_notetim+voice1
	clr.l v_notetim+voice2
	clr.l v_notetim+voice3
	clr.l v_notetim+voice4
	move.l track1,v_crnot+voice1
	move.l track2,v_crnot+voice2
	move.l track3,v_crnot+voice3
	move.l track4,v_crnot+voice4
	move.l track1+4,v_trnspse+voice1
	move.l track2+4,v_trnspse+voice2
	move.l track3+4,v_trnspse+voice3
	move.l track4+4,v_trnspse+voice4

	move.l #s_wavedco+sound1,aud0lch+$dff000
	move.l #s_wavedco+sound1,aud0lch+$dff010
	move.l #s_wavedco+sound1,aud0lch+$dff020
	move.l #s_wavedco+sound1,aud0lch+$dff030
	move.w #$10,aud0len+$dff000
	move.w #$10,aud0len+$dff010
	move.w #$10,aud0len+$dff020
	move.w #$10,aud0len+$dff030
	rts

newirq:
	movem.l d0-d7/a0-a6,-(a7)
	cmp.b #timerhi-1,$bfe501
	bne nottim
	bsr playsound
nottim:
	movem.l (a7)+,d0-d7/a0-a6
statement:
	jmp $ffffffff

playsound:
	lea voice1,a0
	jsr playvoice
	lea voice2,a0
	jsr playvoice
	lea voice3,a0
	jsr playvoice
	lea voice4,a0
	jsr playvoice
	rts

playvoice:
	subq.w #1,v_notetim(a0)
	bpl notyet1
	clr.w v_add(a0)
	clr.w v_pauspnt(a0)
musl1:
	move.l v_crnot(a0),a1
	move.l v_trnspse(a0),d3
	clr.l d4
	move.w (a1),d4
	cmp.w #128,d4          ;change snd?
	bne testarp
	move.l 2(a1),v_sactive(a0)
	addi.l #6,v_crnot(a0)
	move.l 2(a1),d5
	move.l v_hardw(a0),a3
	move.l d5,(a3)
	bra musl1 
testarp:
	cmp.w #129,d4          ;change arp?
	bne chpause
	move.l v_sactive(a0),a3
	move.l 2(a1),s_arp(a3)
	move.l 6(a1),s_arp+4(a3)
	addi.l #10,v_crnot(a0)
	bra musl1
chpause:
	cmp.w #130,d4          ;pause?
	bne chweiter
	move.w #1,v_pauspnt(a0)
	bra gut1
chweiter:
	add.w d4,d3
	move.w d3,v_savnote(a0)
	cmp.l v_trnspse(a0),d3
	bne gut1
	addi.l #8,v_trkstp(a0)
	move.l v_trkstp(a0),a2
	move.l 4(a2),v_trnspse(a0)
	move.l (a2),v_crnot(a0)
	bne musl1
	move.l v_trkbck(a0),v_trkstp(a0)
	move.l v_trkstp(a0),a2
	move.l 4(a2),v_trnspse(a0)
	move.l (a2),v_crnot(a0)
	bra musl1
gut1:
	tst.w v_pauspnt(a0)
	bne notset
	clr.l v_envpoint(a0)
	clr.w v_actloud(a0)
notset:
	move.w 2(a1),d0
	subq.w #1,d0
	move.w d0,v_notetim(a0)
	adda.l #4,a1
	move.l a1,v_crnot(a0)
notyet1:
	move.l v_hardw(a0),a2
	move.l v_sactive(a0),a3
	move.w v_wntnote(a0),d0
	subq.w #1,d0
	mulu #2,d0
	lea freqtab,a4
	move.w (a4,d0.w),d1
	move.w s_spdport(a3),d0
	beq noport
	cmp.w v_actfrq(a0),d1
	blo portdown
	addi.w d0,v_actfrq(a0)
	cmp.w v_actfrq(a0),d1
	bhi nochklei
	move.w d1,v_actfrq(a0)
nochklei:
	bra portaend
portdown:
	subi.w d0,v_actfrq(a0)
	cmp.w v_actfrq(a0),d1
	blo nochgroe
	move.w d1,v_actfrq(a0)
nochgroe:
	bra portaend
noport:
	add.w v_add(a0),d1
	move.w d1,v_actfrq(a0)
portaend:
	move.l v_sactive(a0),a3
	adda.l #s_arp,a3
	move.l v_arpoint(a0),d1
	clr.l d2
	move.b (a3,d1.l),d2
	bpl positiv
	neg.b d2
	clr.l d3
	move.w v_savnote(a0),d3
	sub.w d2,d3
	move.w d3,d2
	bra negativ
positiv:
	add.w v_savnote(a0),d2
negativ:
	move.w d2,v_wntnote(a0)
	addq.l #1,v_arpoint(a0)
	cmp.l #8,v_arpoint(a0)
	bne notnull
	clr.l v_arpoint(a0)
notnull:
	move.l v_sactive(a0),a3
	tst.w v_phmark(a0)
	beq ffff
	clr.w v_phmark(a0)
	clr.l d2
	move.b s_phase(a3),d2
	move.w v_actfrq(a0),d1
	add.w d2,d1
	move.w d1,v_actfrq(a0)
	bra wasffff
ffff:
	move.w #$ffff,v_phmark(a0)
	clr.l d2
	move.b s_phase(a3),d2
	move.w v_actfrq(a0),d1
	sub.w d2,d1
	move.w d1,v_actfrq(a0)
wasffff:
	clr.l d2
	move.w s_spdbend(a3),d2
	sub.w d2,v_add(a0)
	clr.l d0
	move.w v_actfrq(a0),d0
	move.w s_egfreq(a3),d1
	beq noteg
	bmi dazu
	sub.w v_actloud(a0),d0
	bra noteg
dazu:
	add.w v_actloud(a0),d0
noteg:
	move.w d0,$06(a2)
	clr.l d2
	move.l v_sactive(a0),a2
	clr.l d0
	clr.l d1
	move.b s_sus(a2),d0
	move.b s_end(a2),d1
	cmp.l v_envpoint(a0),d1
	beq envelopend
	cmp.l #$00,d0
	beq notsustep
	cmp.l v_envpoint(a0),d0
	bne notsustep
	cmpi.w #$00,v_pauspnt(a0)
	beq envelopend
notsustep:
	move.l v_envpoint(a0),d2
	mulu #2,d2
	lea s_envelope(a2),a3
	clr.l d3
	clr.l d4
	move.b (a3,d2.w),d3
	move.b 1(a3,d2.w),d4
	cmp.w v_actloud(a0),d4
	bhi loudup
	sub.w d3,v_actloud(a0)
	cmp.w v_actloud(a0),d4
	ble nichtunt
	move.w d4,v_actloud(a0)
	addq.l #$1,v_envpoint(a0)
nichtunt:
	bra envelopend
loudup:
	add.w d3,v_actloud(a0)
	cmp.w v_actloud(a0),d4
	bhi envelopend
	move.w d4,v_actloud(a0)
	addq.l #$1,v_envpoint(a0)
envelopend:
	clr.l d1
	move.w v_actloud(a0),d1
	divu #4,d1
	move.l v_hardw(a0),a1
	move.w d1,$08(a1)
	rts

score1:
	dc.w 128
	dc.l sound1
	dc.w 129
	dc.l $0003070c,$0003070c
	dc.w 40,28,40,28,40,28,40,28
	dc.w 40,28,40,28,40,28,40,28
	dc.w 0,0

score2:
	dc.w 128
	dc.l sound1
	dc.w 129
	dc.l $0004070c,$0004070c
	dc.w 40,28,40,28,40,28,40,28
	dc.w 40,28,40,28,40,28,40,28
	dc.w 0,0

score3:
	dc.w 128
	dc.l sound2
	dc.w 129
	dc.l $00000000,$00000000
	dc.w 40,84,40,28,40,70,40,14,42,14,43,14
	dc.w 0,0

score4:
	dc.w 128
	dc.l sound2
	dc.w 129
	dc.l $00000000,$0000000
	dc.w 40,84,40,28,40,70,40,14,42,14,44,14
	dc.w 0,0

score5:
	dc.w 128
	dc.l sound3
	dc.w 129
	dc.l $00000000,$00000000
	dc.w 43,56
	dc.w 128
	dc.l sound4
	dc.w 129
	dc.l $00000000,$00000000
	dc.w 43,28
	dc.w 128
	dc.l sound3
	dc.w 43,28
	dc.w 128
	dc.l sound4
	dc.w 43,56
	dc.w 43,56
	dc.w 0,0

score6:
	dc.w 128
	dc.l sound5
	dc.w 129
	dc.l $00000000,$00000000
	dc.w 43,56,46,56,50,56,53,56,53,28,51,28,50,28,51,140
	dc.w 41,84,45,28,48,56,51,56,51,28,50,28,49,28,50,140
	dc.w 39,56,43,56,46,56,50,56,50,28,48,28,47,28,48,84
	dc.w 50,28,45,28
	dc.w 48,28,47,28,45,28,47,140
	dc.w 48,28,47,28,46,28,47,140
	dc.w 129
	dc.l $00000c0c,$00000c0c
	dc.w 43,56,46,56,50,56,53,56,53,28,51,28,50,28,51,140
	dc.w 41,84,45,28,48,56,51,56,51,28,50,28,49,28,50,140
	dc.w 39,56,43,56,46,56,50,56,50,28,48,28,47,28,48,84
	dc.w 50,28,45,28
	dc.w 48,28,47,28,45,28,47,140
	dc.w 48,28,47,28,46,28,47,140
	dc.w 0,0

