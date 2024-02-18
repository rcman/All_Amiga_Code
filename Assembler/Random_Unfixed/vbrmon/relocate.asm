RelocTable:

	dc.l myreloc1
	dc.l myreloc2
	dc.l myreloc3
;	dc.l myreloc4
;	dc.l myreloc5
;	dc.l myreloc6
;	dc.l myreloc7
;	dc.l Reloc000002
;	dc.l Reloc00511E
;	dc.l Reloc005126
	dc.l Reloc007E60
	dc.l Reloc007E6E
	dc.l Reloc007E7C
	dc.l Reloc007E8A
	dc.l Reloc007E98
	dc.l Reloc007EA6
	dc.l Reloc007EB4
	dc.l Reloc007EC2
	dc.l Reloc007ED0
	dc.l Reloc007EDE
	dc.l Reloc007EEC
	dc.l Reloc007EFA
	dc.l Reloc007F08
	dc.l Reloc007F16
	dc.l Reloc007F24
	dc.l Reloc007F32
	dc.l Reloc007F40
	dc.l Reloc007F4E
	dc.l Reloc007F5C
	dc.l Reloc007F6A
	dc.l Reloc007F78
	dc.l Reloc007F86
	dc.l Reloc007F94
	dc.l Reloc007FA2
	dc.l Reloc007FB0
	dc.l Reloc007FBE
	dc.l Reloc007FCC
	dc.l Reloc007FDA
	dc.l Reloc007FE8
	dc.l Reloc007FF6
	dc.l Reloc008004
	dc.l Reloc008012
	dc.l Reloc008020
	dc.l Reloc00802E
	dc.l Reloc00803C
	dc.l Reloc00804A
	dc.l Reloc008058
	dc.l Reloc008066
	dc.l Reloc008074
	dc.l Reloc008082
	dc.l Reloc008090
	dc.l Reloc00809E
	dc.l Reloc0080AC
	dc.l Reloc0080BA
	dc.l Reloc0080C8
	dc.l Reloc0080D6
	dc.l Reloc0080E4
	dc.l Reloc0080F2
	dc.l Reloc008100
	dc.l Reloc00810E
	dc.l Reloc00811C
	dc.l Reloc00812A
	dc.l Reloc008138
	dc.l Reloc008146
	dc.l Reloc008154
	dc.l Reloc008162
	dc.l Reloc008170
	dc.l Reloc00817E
	dc.l Reloc00818C
	dc.l Reloc00819A
	dc.l Reloc0081A8
	dc.l Reloc0081B6
	dc.l Reloc0081C4
	dc.l Reloc0081D2
	dc.l Reloc0081E0
	dc.l Reloc0081EE
	dc.l Reloc0081FC
	dc.l Reloc00820A
	dc.l Reloc008218
	dc.l Reloc008226
	dc.l Reloc008234
	dc.l Reloc008242
	dc.l Reloc008250
	dc.l Reloc00825E
;	dc.l Reloc00828C
;	dc.l Reloc008290
;	dc.l Reloc008294
;	dc.l Reloc008298
;	dc.l Reloc00829C
;	dc.l Reloc0082A0
;	dc.l Reloc0082A4
;	dc.l Reloc0082A8
;	dc.l Reloc0082AC
;	dc.l Reloc0082B0
;	dc.l Reloc0082B4
;	dc.l Reloc0082B8
;	dc.l Reloc0082BC
;	dc.l Reloc0082C0
;	dc.l Reloc0082C4
;	dc.l Reloc0082C8
;	dc.l Reloc0082CC
;	dc.l Reloc0082D0
;	dc.l Reloc0082D4
;	dc.l Reloc0082D8
;	dc.l Reloc0082DC
;	dc.l Reloc0082E0
;	dc.l Reloc0082E4
;	dc.l Reloc0082E8
;	dc.l Reloc0082EC
;	dc.l Reloc0082F0
;	dc.l Reloc0082F4
;	dc.l Reloc0082F8
;	dc.l Reloc0082FC
;	dc.l Reloc008300
	dc.l Reloc008304
	dc.l Reloc008308
	dc.l Reloc00830C
	dc.l Reloc008310
	dc.l Reloc008314
	dc.l Reloc008318
	dc.l Reloc00831C
	dc.l Reloc008320
	dc.l Reloc008324
	dc.l Reloc008328
	dc.l Reloc00832C
	dc.l Reloc008330
	dc.l Reloc008334
	dc.l Reloc008338
	dc.l Reloc00833C
	dc.l Reloc008340
	dc.l Reloc008344
	dc.l Reloc008348
	dc.l Reloc00834C
	dc.l Reloc008350
	dc.l Reloc008354
	dc.l Reloc008358
	dc.l Reloc00835C
	dc.l Reloc008360
	dc.l Reloc008364
	dc.l Reloc008368
	dc.l Reloc00836C
	dc.l Reloc008370
	dc.l Reloc008374
	dc.l Reloc00837C
	dc.l Reloc008380
	dc.l Reloc008384
	dc.l Reloc008388
	dc.l 0

Relocate:

;D0=Starting locationg, D1=Relocate location

	moveq	#0,d2
	lea.l (RelocTable,PC),a0
1$:	movea.l (a0)+,a1
	cmp.l d2,a1
	beq.b 2$
	sub.l d0,(a1)
	add.l d1,(a1)
	bra.b 1$

2$:	rts

	END
