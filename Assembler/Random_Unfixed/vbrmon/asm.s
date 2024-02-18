StartAssembler:
	lea	(bwl.msg,pc),a4
	add.l	#$7ffe,a4
	bsr	GetArg
	bcc.b	.normal
	move.l	a3,-(sp)
	bra.b	.skip

.normal:
	move.l	d0,-(sp)
..	bsr	GetArg
	bcc.b	..

.skip:
	bsr	Assemble
	addq.l	#4,sp
	move.l	(CurrentPC-DT,A4),a3
	rts

;************ Mini-assembler main routine ***********************

Assemble:
	LINK.w	A5,#-8
	MOVE.L	(8,A5),D3
	bclr	#0,d3
;	ANDi.L	#$FFFFFE,D3
	MOVE.L	D3,(CurrentPC-DT,A4)
MonlbC0040CA:
	MOVE.L	(CurrentPC-DT,A4),-(SP)
	PEA	(lx.MSG1,PC)
	JSR	(MonlbC006CFE,PC)	;printf
	ADDQ.W	#8,SP

;*****************************************

;	push	d0
;	push	d6

;    PUTDEBUG   30,<'%s/Asm: called!'>

	bsr	GetArg

;	move.l	d0,-(sp)
;    PUTDEBUG   30,<'%s/Asm: GetArg returned $%lx'>
;	addq.w	#4,sp

	push	a5
	movea.l	(lbL00059C,pc),a5
	tst.b	($A2,a5)
	pop	a5
	bne	EndAsm

GS:
	bsr	__Get

;	move.l	d0,-(sp)
;    PUTDEBUG   30,<'%s/Asm: __Get returned $%lx'>
;	addq.w	#4,sp

	cmp.b	#' ',d0
	beq.b	GS
	bsr	_UnGet	

;	bsr	_GetChar
;	moveq	#10,d6
;	move.b	#'/',d0
;	bsr	MonPutChar
1$:
;	bsr	_GetChar
;	subq.l	#1,d6
;	beq.b	2$
;	cmp.b	#':',d0
;	bne.b	1$
;	bsr	_GetChar
;	move.b	#'\',d0
;	bsr	MonPutChar
2$
;	pop	d6
;	pop	d0

;*****************************************

	CLR.W	(-2,A5)
MonlbC0040DC

;call to scanf
;This is the ONLY input-gathering code !
;	PEA	(-7,A5)
;	PEA	(c.MSG,PC)
;	JSR	(MonlbC00635E,PC)
;	ADDQ.W	#8,SP
	bsr	__Get

	tst.b	d0
	bne.b	.SkipThis
	move.b	#$a,d0
.SkipThis:

	move.b	d0,(-7,a5)

	CMPi.W	#$3C,(-2,A5)
	BGE.b	MonlbC00412E
	MOVE.B	(-7,A5),D3
	EXT.W	D3
	CMPi.W	#$20,D3
	BLT.b	MonlbC00412E
	MOVE.B	(-7,A5),D3
	EXT.W	D3
	CMPi.W	#$41,D3
	BLT.b	MonlbC00411C
	MOVE.B	(-7,A5),D3
	EXT.W	D3
	CMPi.W	#$5A,D3
	BGT.b	MonlbC00411C
	ADDi.B	#$20,(-7,A5)
MonlbC00411C:
	MOVE.W	(-2,A5),D3
	ADDQ.W	#1,(-2,A5)
	LEA	(MonlbL008660-DT,A4),A6
	MOVE.B	(-7,A5),(0,A6,D3.W)
MonlbC00412E:
	MOVE.B	(-7,A5),D3
	EXT.W	D3
	CMPi.W	#10,D3
;	CMPi.W	#0,D3
	BNE.b	MonlbC0040DC

;go here if char = CR

	MOVE.W	(-2,A5),D3
	LEA	(MonlbL008660-DT,A4),A6
	CLR.B	(0,A6,D3.W)	;put a zero in place of zero :-)
	TST.B	(MonlbL008660-DT,A4)
	BEQ	MonlbC004242
	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.L	A6,(MonlbL0086B0-DT,A4)
	CLR.W	(OpcodeTableIndex-DT,A4)
	MOVE.W	#1,(-6,A5)
MonlbC004164:
	MOVE.W	#1,(-4,A5)
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(Reloc007E60-DT,A4),A6
	MOVE.L	(0,A6,D3.L),-(SP)
	PEA	(MonlbL008660-DT,A4)

	JSR	(MonlbC001EB4,PC)

	ADDQ.W	#8,SP
	MOVE.W	D0,(-2,A5)
	TST.W	D0
	BEQ	MonlbC0041F6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E68-DT,A4),A6
	MOVEQ	#0,D2
	MOVE.W	(0,A6,D3.L),D2
	ASL.L	#2,D2
	LEA	(Reloc008304-DT,A4),A6
	TST.L	(0,A6,D2.L)
	BEQ	MonlbC0041F6
	MOVE.W	(-2,A5),D3
	EXT.L	D3
	LEA	(MonlbL008660-DT,A4),A6
	ADD.L	A6,D3
	MOVE.L	D3,(CurrentCharPtr-DT,A4)
	JSR	(MonlbC002096,PC)
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E68-DT,A4),A6
	MOVEQ	#0,D2
	MOVE.W	(0,A6,D3.L),D2
	ASL.L	#2,D2
	LEA	(Reloc008304-DT,A4),A6
	MOVEa.L	(0,A6,D2.L),A1

;Substitute "a7" for "sp"
	movem.l	d0/a0,-(sp)
	move.l	(CurrentCharPtr-DT,A4),a0
.scan:
	move.b	(a0)+,d0
	beq.b	.endscan
	cmp.b	#$27,d0	;'''
	beq.b	.quote
	cmp.b	#'s',d0
	bne.b	.scan
	cmp.b	#'p',(a0)
	bne.b	.scan
	move.b	#'a',(-1,a0)
	move.b	#'7',(a0)
	bra.b	.scan
.quote:
	move.b	(a0)+,d0
	beq.b	.endscan
	cmp.b	#$27,d0
	bne.b	.quote
	bra.b	.scan
.endscan:
	movem.l	(sp)+,d0/a0

	JSR	(A1)
	MOVE.W	D0,(-4,A5)
	MOVE.W	D0,(-6,A5)
	TST.W	(-6,A5)
	BNE.b	MonlbC0041F6
	JSR	(MonlbC0020D4,PC)
	MOVE.W	D0,(-4,A5)
	MOVE.W	D0,(-6,A5)
MonlbC0041F6:
	TST.W	(-4,A5)
	BEQ.b	MonlbC004206
	MOVE.L	(MonlbL0086B0-DT,A4),(CurrentPC-DT,A4)
	ADDQ.L	#2,(CurrentPC-DT,A4)
MonlbC004206:
	ADDQ.W	#1,(OpcodeTableIndex-DT,A4)
	TST.W	(-4,A5)
	BEQ.b	MonlbC00421A
	CMPi.W	#$4C,(OpcodeTableIndex-DT,A4)
	BLT	MonlbC004164
MonlbC00421A:
	TST.W	(-4,A5)
	BEQ.b	MonlbC004242
	MOVE.L	(MonlbL0086B0-DT,A4),(CurrentPC-DT,A4)
	MOVE.W	(-6,A5),D3
	SUBQ.W	#1,D3
	EXT.L	D3
	ASL.L	#2,D3
	LEA	(Reloc00837C-DT,A4),A6
	MOVE.L	(0,A6,D3.L),-(SP)
	PEA	(s.MSG1,PC)
	JSR	(MonlbC006CFE,PC)
	ADDQ.W	#8,SP
MonlbC004242:
	TST.B	(MonlbL008660-DT,A4)
	BNE	MonlbC0040CA
EndAsm:
	UNLK	A5
	RTS

lx.MSG1:	dc.b	'%08lx: ',0
c.MSG:	dc.b	'%c',0
s.MSG1:	dc.b	'*** %s',$A,0
	even

;************* Main routine subroutines **************

__Get:
	lea	(_flag,pc),a0
	tst.l	(a0)
	bne.b	1$
	bsr	_GetChar
	lea	(_buf,pc),a0
	move.b	D0,(a0)
1$:
	lea	(_flag,pc),a0
	clr.l	(a0)
	move.b	(_buf,pc),D0
	tst.b	d0
	bne.b	2$
	move.b	#$a,d0
2$:
	and.l	#$ff,d0
	RTS

_UnGet	
	lea	(_flag,pc),a0
	move.l	#1,(a0)
	RTS

_flag:	dc.l 0
_buf:	dc.b 0
	even

move.MSG4	dc.b	'move',0
	even

MyPrintF:
MonlbC006CFE:
;*****
	bra	PrintLong

MonlbC001EB4:
	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVEQ	#0,D4
	CMPi.W	#10,(OpcodeTableIndex-DT,A4)
	BLE.b	MonlbC001ED4
	CMPi.W	#14,(OpcodeTableIndex-DT,A4)
	BGE.b	MonlbC001ED4
	LEA	(move.MSG4,PC),A6
	MOVE.L	A6,(12,A5)
MonlbC001ED4	MOVEa.L	(12,A5),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	TST.W	D3
	BEQ.b	MonlbC001F16
	MOVEa.L	(12,A5),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	CMPi.W	#$2E,D3	;'.'
	BEQ.b	MonlbC001F16
	MOVEa.L	(12,A5),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	MOVEa.L	(8,A5),A6
	MOVE.B	(0,A6,D4.W),D2
	EXT.W	D2
	CMP.W	D2,D3
	BEQ.b	MonlbC001F12
	MOVEQ	#0,D0
MonlbC001F0C	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC001F12	ADDQ.W	#1,D4
	BRA.b	MonlbC001ED4

MonlbC001F16	CMPi.W	#10,(OpcodeTableIndex-DT,A4)
	BLE.b	MonlbC001F58
	CMPi.W	#14,(OpcodeTableIndex-DT,A4)
	BGE.b	MonlbC001F58
	MOVEa.L	(8,A5),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BNE.b	MonlbC001F38
	ADDQ.W	#1,D4
MonlbC001F38	MOVEa.L	(8,A5),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	CMPi.W	#$2E,D3	;'.'
	BEQ.b	MonlbC001F58
	CMPi.W	#13,(OpcodeTableIndex-DT,A4)
	BNE.b	MonlbC001F54
	MOVE.W	D4,D0
	BRA.b	MonlbC001F0C

MonlbC001F54	MOVEQ	#0,D0
	BRA.b	MonlbC001F0C

MonlbC001F58	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6C-DT,A4),A6
	CMPi.W	#4,(0,A6,D3.L)
	BEQ	MonlbC002002
	MOVEa.L	(8,A5),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	CMPi.W	#$2E,D3
	BEQ.b	MonlbC001F82
	MOVE.W	D4,D0
	BRA.b	MonlbC001F0C

MonlbC001F82	ADDQ.W	#1,D4
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6C-DT,A4),A6
	TST.W	(0,A6,D3.L)
	BNE.b	MonlbC001FAC
	MOVEa.L	(8,A5),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	CMPi.W	#$62,D3
	BEQ.b	MonlbC001FAC
	MOVEQ	#0,D0
	BRA	MonlbC001F0C

MonlbC001FAC	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6C-DT,A4),A6
	CMPi.W	#1,(0,A6,D3.L)
	BNE.b	MonlbC001FD6
	MOVEa.L	(8,A5),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	CMPi.W	#$77,D3
	BEQ.b	MonlbC001FD6
	MOVEQ	#0,D0
	BRA	MonlbC001F0C

MonlbC001FD6	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6C-DT,A4),A6
	CMPi.W	#2,(0,A6,D3.L)
	BNE.b	MonlbC002000
	MOVEa.L	(8,A5),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	CMPi.W	#$6C,D3
	BEQ.b	MonlbC002000
	MOVEQ	#0,D0
	BRA	MonlbC001F0C

MonlbC002000	ADDQ.W	#1,D4
MonlbC002002	MOVE.W	D4,D0
	BRA	MonlbC001F0C

;************************************************************
;************* Mini-assembler subroutines *******************
;************************************************************
;(Called by jump table)

; ----------------------------------------------

MonlbC001A94:
	LINK.w	A5,#0
	MOVEM.L	D4/D5,-(SP)
	MOVEQ	#0,D4
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEQ	#0,D5
MonlbC001AA4	LEA	(abcdef.MSG-DT,A4),A6
	MOVE.B	(0,A6,D5.W),D3
	EXT.W	D3
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D2
	EXT.W	D2
	CMP.W	D2,D3
	BNE.b	MonlbC001AD0
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.W	D5,D3
	EXT.L	D3
	MOVE.L	D4,D2
	ASL.L	#4,D2
	MOVE.L	D3,D4
	ADD.L	D2,D4
	MOVEQ	#-$1,D5
MonlbC001AD0	ADDQ.W	#1,D5
	CMPi.W	#$10,D5
	BLT.b	MonlbC001AA4
	MOVE.L	D4,D0
	MOVEM.L	(SP)+,D4/D5
	UNLK	A5
	RTS

MonlbC001AE2:
	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVEQ	#0,D4
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
MonlbC001AEE	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	TST.W	D3
	BEQ.b	MonlbC001B20
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$27,D3
	BEQ.b	MonlbC001B20
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	EXT.L	D3
	MOVE.L	D4,D2
	ASL.L	#8,D2
	MOVE.L	D3,D4
	ADD.L	D2,D4
	BRA.b	MonlbC001AEE

MonlbC001B20	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$27,D3
	BNE.b	MonlbC001B32
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
MonlbC001B32	MOVE.L	D4,D0
	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC001B3A:
	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVEQ	#0,D4
MonlbC001B42	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$30,D3
	BLT.b	MonlbC001B80
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$39,D3
	BGT.b	MonlbC001B80
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	EXT.L	D3
	MOVE.L	D4,D0
	MOVEQ	#10,D1
	JSR	(MonlbC006C8E,PC)
	ADD.L	D0,D3
	MOVE.L	D3,D4
	SUBi.L	#$30,D4
	BRA.b	MonlbC001B42

MonlbC001B80	MOVE.L	D4,D0
	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC001B88:
	LINK.w	A5,#0
	MOVEM.L	D4/D5,-(SP)
	MOVEQ	#0,D4
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2D,D3
	BNE.b	MonlbC001BA8
	MOVEQ	#1,D5
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	BRA.b	MonlbC001BD2

MonlbC001BA8	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$7E,D3
	BNE.b	MonlbC001BBE
	MOVEQ	#2,D5
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	BRA.b	MonlbC001BD2

MonlbC001BBE	MOVEQ	#0,D5
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2B,D3
	BNE.b	MonlbC001BD2
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
MonlbC001BD2	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$28,D3
	BNE.b	MonlbC001BEC
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	JSR	(MonlbC001D34,PC)
	MOVE.L	D0,D4
	BRA.b	MonlbC001C46

MonlbC001BEC	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$30,D3
	BLT.b	MonlbC001C10
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$39,D3
	BGT.b	MonlbC001C10

;No override, so use default
	move.b	(_dformat,pc),d0
	cmp.b	#10,d0
	bne.b	NotDeci
	JSR	(MonlbC001B3A,PC)	;decimal parse
FinishedParse:
	MOVE.L	D0,D4
	BRA.b	MonlbC001C46
NotDeci:
	subq.l	#1,(CurrentCharPtr-DT,A4)
	JSR	(MonlbC001A94,PC)	;hex parse
	bra.b	FinishedParse

MonlbC001C10	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$24,D3	;'$'
	BNE.b	TryDec
	JSR	(MonlbC001A94,PC)	;hex parse
	bra.b	FinishedParse
TryDec:
	cmp.b	#'_',d3
	BNE.b	MonlbC001C26
	addq.l	#1,(CurrentCharPtr-DT,A4)
	JSR	(MonlbC001B3A,PC)	;decimal parse
	bra.b	FinishedParse

MonlbC001C26	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$27,D3	;'''!
	BNE.b	MonlbC001C3C
	JSR	(MonlbC001AE2,PC)
	bra.b	FinishedParse

MonlbC001C3C	MOVEQ	#0,D0
MonlbC001C3E	MOVEM.L	(SP)+,D4/D5
	UNLK	A5
	RTS

MonlbC001C46	CMPi.L	#1,D5
	BNE.b	MonlbC001C54
	MOVE.L	D4,D0
	NEG.L	D0
	BRA.b	MonlbC001C3E

MonlbC001C54	CMPi.L	#2,D5
	BNE.b	MonlbC001C62
	MOVE.L	D4,D0
	NOT.L	D0
	BRA.b	MonlbC001C3E

MonlbC001C62	MOVE.L	D4,D0
	BRA.b	MonlbC001C3E

MonlbC001C66:
	LINK.w	A5,#0
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$28,D3
	BNE.b	MonlbC001C84
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	JSR	(MonlbC001D34,PC)
MonlbC001C80	UNLK	A5
	RTS

MonlbC001C84	JSR	(MonlbC001B88,PC)
	BRA.b	MonlbC001C80

MonlbC001C8A	LINK.w	A5,#0
	MOVEM.L	D4-D6,-(SP)
	MOVEQ	#1,D6
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$28,D3
	BNE.b	MonlbC001CAE
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	JSR	(MonlbC001D34,PC)
	MOVE.L	D0,D4
	BRA.b	MonlbC001CB4

MonlbC001CAE	JSR	(MonlbC001B88,PC)
	MOVE.L	D0,D4
MonlbC001CB4	TST.L	D6
	BEQ.b	MonlbC001D2A
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D0
	EXT.W	D0
	EXT.L	D0
	BRA.b	MonlbC001D16

MonlbC001CC8	BSR.b	MonlbC001C66
	MOVE.L	D4,D1
	JSR	(MonlbC006C8E,PC)
	MOVE.L	D0,D4
	BRA.b	MonlbC001D28

MonlbC001CD4	MOVE.L	D4,D0
	MOVE.L	D0,-(SP)
	BSR.b	MonlbC001C66
	MOVE.L	D0,D5
	TST.L	D0
	BEQ.b	MonlbC001CE4
	MOVE.L	D5,D1
	BRA.b	MonlbC001CE6

MonlbC001CE4	MOVEQ	#1,D1
MonlbC001CE6	MOVE.L	(SP)+,D0
	JSR	(MonlbC0071B2,PC)
	MOVE.L	D0,D4
	BRA.b	MonlbC001D28

MonlbC001CF0	MOVE.L	D4,D0
	MOVE.L	D0,-(SP)
	JSR	(MonlbC001C66,PC)
	MOVE.L	D0,D5
	TST.L	D0
	BEQ.b	MonlbC001D02
	MOVE.L	D5,D1
	BRA.b	MonlbC001D04

MonlbC001D02	MOVEQ	#1,D1
MonlbC001D04	MOVE.L	(SP)+,D0
	JSR	(MonlbC0071D4,PC)
	MOVE.L	D0,D4
	BRA.b	MonlbC001D28

MonlbC001D0E	SUBQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEQ	#0,D6
	BRA.b	MonlbC001D28

MonlbC001D16	SUBi.L	#$25,D0
	BEQ.b	MonlbC001CF0
	SUBQ.L	#5,D0
	BEQ.b	MonlbC001CC8
	SUBQ.L	#5,D0
	BEQ.b	MonlbC001CD4
	BRA.b	MonlbC001D0E

MonlbC001D28	BRA.b	MonlbC001CB4

MonlbC001D2A	MOVE.L	D4,D0
	MOVEM.L	(SP)+,D4-D6
	UNLK	A5
	RTS

MonlbC001D34:
	LINK.w	A5,#-2
	MOVEM.L	D4-D7,-(SP)
	MOVEQ	#1,D6
	MOVEQ	#0,D7
MonlbC001D40	TST.W	D7
	BNE.b	MonlbC001D64
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$28,D3
	BNE.b	MonlbC001D5C
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	BSR.b	MonlbC001D34
	MOVE.L	D0,D4
	BRA.b	MonlbC001D62

MonlbC001D5C	JSR	(MonlbC001B88,PC)
	MOVE.L	D0,D4
MonlbC001D62	ADDQ.W	#1,D7
MonlbC001D64	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D0
	MOVE.B	D0,(-1,A5)
	EXT.W	D0
	EXT.L	D0
	BRA	MonlbC001E14

MonlbC001D7A	MOVE.L	D4,D0
	MOVE.L	D0,-(SP)
	JSR	(MonlbC001C66,PC)
	MOVE.L	D0,D1
	MOVE.L	(SP)+,D0
	JSR	(MonlbC006C8E,PC)
	MOVE.L	D0,D4
	BRA	MonlbC001E56

MonlbC001D90	MOVE.L	D4,D0
	MOVE.L	D0,-(SP)
	JSR	(MonlbC001C66,PC)
	MOVE.L	D0,D5
	TST.L	D0
	BEQ.b	MonlbC001DA2
	MOVE.L	D5,D1
	BRA.b	MonlbC001DA4

MonlbC001DA2	MOVEQ	#1,D1
MonlbC001DA4	MOVE.L	(SP)+,D0
	JSR	(MonlbC0071B2,PC)
	MOVE.L	D0,D4
	BRA	MonlbC001E56

MonlbC001DB0	MOVE.L	D4,D0
	MOVE.L	D0,-(SP)
	JSR	(MonlbC001C66,PC)
	MOVE.L	D0,D5
	TST.L	D0
	BEQ.b	MonlbC001DC2
	MOVE.L	D5,D1
	BRA.b	MonlbC001DC4

MonlbC001DC2	MOVEQ	#1,D1
MonlbC001DC4	MOVE.L	(SP)+,D0
	JSR	(MonlbC0071D4,PC)
	MOVE.L	D0,D4
	BRA	MonlbC001E56

MonlbC001DD0	JSR	(MonlbC001C8A,PC)
	ADD.L	D0,D4
	BRA.b	MonlbC001E56

MonlbC001DD8	JSR	(MonlbC001C8A,PC)
	SUB.L	D0,D4
	BRA.b	MonlbC001E56

MonlbC001DE0	JSR	(MonlbC001C8A,PC)
	ASL.L	D0,D4
	BRA.b	MonlbC001E56

MonlbC001DE8	JSR	(MonlbC001C8A,PC)
	ASR.L	D0,D4
	BRA.b	MonlbC001E56

MonlbC001DF0	JSR	(MonlbC001C8A,PC)
	AND.L	D0,D4
	BRA.b	MonlbC001E56

MonlbC001DF8	JSR	(MonlbC001C8A,PC)
	OR.L	D0,D4
	BRA.b	MonlbC001E56

MonlbC001E00	JSR	(MonlbC001C8A,PC)
	EOR.L	D0,D4
	BRA.b	MonlbC001E56

MonlbC001E08	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
MonlbC001E0C	SUBQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEQ	#0,D6
	BRA.b	MonlbC001E56

MonlbC001E14	SUBi.L	#$25,D0
	BEQ.b	MonlbC001DB0
	SUBQ.L	#1,D0
	BEQ.b	MonlbC001DF0
	SUBQ.L	#3,D0
	BEQ.b	MonlbC001E08
	SUBQ.L	#1,D0
	BEQ	MonlbC001D7A
	SUBQ.L	#1,D0
	BEQ.b	MonlbC001DD0
	SUBQ.L	#2,D0
	BEQ.b	MonlbC001DD8
	SUBQ.L	#2,D0
	BEQ	MonlbC001D90
	SUBi.L	#13,D0
	BEQ.b	MonlbC001DE0
	SUBQ.L	#2,D0
	BEQ.b	MonlbC001DE8
	SUBi.L	#$20,D0
	BEQ.b	MonlbC001E00
	SUBi.L	#$1E,D0
	BEQ.b	MonlbC001DF8
	BRA.b	MonlbC001E0C

MonlbC001E56	TST.W	D6
	BNE	MonlbC001D40
	MOVE.L	D4,D0
	MOVEM.L	(SP)+,D4-D7
	UNLK	A5
	RTS

; ----------------------------------------------

;Handle condition codes
MonlbC00200E	LINK.w	A5,#0
	MOVEM.L	D4/D5,-(SP)
	MOVEQ	#-$1,D5
	MOVEQ	#0,D4
	BRA.b	MonlbC002054

MonlbC00201C	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVEa.L	(8,A5),A6
	MOVE.B	(0,A6,D4.W),D2
	EXT.W	D2
	CMP.W	D2,D3
	BNE.b	MonlbC002052
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(1,A6),D3
	EXT.W	D3
	MOVE.W	D4,D2
	ADDQ.W	#1,D2
	MOVEa.L	(8,A5),A6
	MOVE.B	(0,A6,D2.W),D1
	EXT.W	D1
	CMP.W	D1,D3
	BNE.b	MonlbC002052
	MOVE.W	D4,D5
	ASL.W	#7,D5
MonlbC002052	ADDQ.W	#2,D4
MonlbC002054	CMPi.W	#$20,D4
	BGT.b	MonlbC002060
	CMPi.W	#$FFFF,D5
	BEQ.b	MonlbC00201C
MonlbC002060	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$20,D3
	BEQ.b	MonlbC00208C
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	TST.W	D3
	BEQ.b	MonlbC00208C
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2E,D3
	BNE.b	MonlbC002060
MonlbC00208C	MOVE.W	D5,D0
	MOVEM.L	(SP)+,D4/D5
	UNLK	A5
	RTS

MonlbC002096:
	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVEQ	#0,D4
MonlbC00209E	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$20,D3
	BNE.b	MonlbC0020B4
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	ADDQ.W	#1,D4
	BRA.b	MonlbC00209E

MonlbC0020B4	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	TST.W	D3
	BNE.b	MonlbC0020C8
	MOVEQ	#0,D0
MonlbC0020C2	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC0020C8	TST.W	D4
	BEQ.b	MonlbC0020D0
	MOVEQ	#2,D0
	BRA.b	MonlbC0020C2

MonlbC0020D0	MOVEQ	#1,D0
	BRA.b	MonlbC0020C2

MonlbC0020D4:
	LINK.w	A5,#0
MonlbC0020D8	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$20,D3
	BNE.b	MonlbC0020EC
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	BRA.b	MonlbC0020D8

MonlbC0020EC	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	TST.W	D3
	BNE.b	MonlbC0020FE
	MOVEQ	#0,D0
MonlbC0020FA	UNLK	A5
	RTS

MonlbC0020FE	MOVEQ	#2,D0
	BRA.b	MonlbC0020FA

MonlbC002102	LINK.w	A5,#-2
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2E,D3	;'.'
	BEQ.b	MonlbC00211C
	BSR.b	MonlbC002096
	MOVEQ	#1,D0
MonlbC002118	UNLK	A5
	RTS

MonlbC00211C	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),(-1,A5)
	JSR	(MonlbC002096,PC)
	MOVE.B	(-1,A5),D0
	EXT.W	D0
	EXT.L	D0
	BRA.b	MonlbC00214A

MonlbC00213A	MOVEQ	#0,D0
	BRA.b	MonlbC002118

MonlbC00213E	MOVEQ	#1,D0
	BRA.b	MonlbC002118

MonlbC002142	MOVEQ	#2,D0
	BRA.b	MonlbC002118

MonlbC002146	MOVEQ	#-$1,D0
	BRA.b	MonlbC002118

MonlbC00214A	SUBi.L	#$62,D0
	BEQ.b	MonlbC00213A
	SUBi.L	#10,D0
	BEQ.b	MonlbC002142
	SUBQ.L	#7,D0
	BEQ.b	MonlbC00213A
	SUBQ.L	#4,D0
	BEQ.b	MonlbC00213E
	BRA.b	MonlbC002146

	BRA.b	MonlbC002118

MonlbC002166:
	LINK.w	A5,#0
	JSR	(MonlbC001D34,PC)
	UNLK	A5
	RTS

;Get a number
GetNum:
	LINK.w	A5,#0
	MOVEM.L	D4-D6,-(SP)
	MOVEQ	#$2B,D5
	MOVEQ	#0,D6
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$40,D3
	BNE.b	MonlbC0021A0
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	BSR.b	MonlbC002166
	SUB.L	(MonlbL0086B0-DT,A4),D0
	SUBQ.L	#2,D0
MonlbC002198	MOVEM.L	(SP)+,D4-D6
	UNLK	A5
	RTS

MonlbC0021A0	BSR.b	MonlbC002166
	BRA.b	MonlbC002198

MonlbC0021A4:
	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$28,D3
	BEQ.b	MonlbC0021C4
	MOVEQ	#-$1,D0
MonlbC0021BE	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC0021C4	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC0021DA
	MOVEQ	#-$1,D0
	BRA.b	MonlbC0021BE

MonlbC0021DA	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D4
	SUBi.W	#$30,D4
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$29,D3
	BEQ.b	MonlbC002202
	MOVEQ	#-$1,D0
	BRA.b	MonlbC0021BE

MonlbC002202	MOVE.W	D4,D0
	BRA.b	MonlbC0021BE

;Effective address handling routine
MonlbC002206:
	LINK.w	A5,#0
	MOVEM.L	D4-D7/A2,-(SP)
	MOVEQ	#-$1,D6
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3	;'d'
	BNE.b	MonlbC00223A
	MOVEQ	#0,D6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D7
	SUBi.W	#$30,D7
	BRA	MonlbC002600

MonlbC00223A	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3	;'a'
	BNE.b	MonlbC00227A
	MOVEQ	#1,D6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D7
	SUBi.W	#$30,D7
	MOVE.B	(9,A5),D3
	EXT.W	D3
	CMPi.W	#$62,D3
	BNE.b	MonlbC002276
	MOVEQ	#-$1,D0
MonlbC00226E	MOVEM.L	(SP)+,D4-D7/A2
	UNLK	A5
	RTS

MonlbC002276	BRA	MonlbC002600

MonlbC00227A	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$28,D3	;'('
	BNE.b	MonlbC0022B8
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(1,A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BNE.b	MonlbC0022B8
	JSR	(MonlbC0021A4,PC)
	MOVE.W	D0,D7
	MOVEQ	#2,D6
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2B,D3
	BNE.b	MonlbC0022B4
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEQ	#3,D6
MonlbC0022B4	BRA	MonlbC002600

MonlbC0022B8	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$23,D3	;'#'
	BNE.b	MonlbC002306
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	JSR	(MonlbC002166,PC)
	MOVEa.L	D0,A2
	MOVEQ	#7,D6
	MOVEQ	#4,D7
	MOVE.B	(9,A5),D3
	EXT.W	D3
	CMPi.W	#$6C,D3
	BNE.b	MonlbC0022F0
	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.L	A2,D3
	MOVEQ	#$10,D2
	ASR.L	D2,D3
	MOVE.W	D3,(A6)
MonlbC0022F0	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.L	A2,D3
	ANDi.L	#$FFFF,D3
	MOVE.W	D3,(A6)
	BRA	MonlbC002600

MonlbC002306	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$40,D3	;'@'
	BNE.b	MonlbC00232E
	MOVEQ	#7,D6
	MOVEQ	#2,D7
	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.L	A6,-(SP)
	JSR	(GetNum,PC)
	MOVEa.L	(SP)+,A6
	MOVE.W	D0,(A6)
	BRA	MonlbC002600

MonlbC00232E	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2D,D3	;'-'
	BNE.b	MonlbC00237A
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(1,A6),D3
	EXT.W	D3
	CMPi.W	#$28,D3	;'('
	BNE.b	MonlbC00237A
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(2,A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3	;'a'
	BNE.b	MonlbC00237A
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	JSR	(MonlbC0021A4,PC)
	MOVE.W	D0,D7
	MOVEQ	#4,D6
	CMPi.W	#$FFFF,D7
	BNE.b	MonlbC002376
	SUBQ.L	#1,(CurrentCharPtr-DT,A4)
	SUBQ.L	#1,(CurrentCharPtr-DT,A4)
MonlbC002376	BRA	MonlbC002600

MonlbC00237A	JSR	(MonlbC002166,PC)
	MOVEa.L	D0,A2
	MOVEQ	#7,D6
	MOVEQ	#1,D7
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2E,D3	;'.'
	BNE.b	MonlbC0023C6
	MOVEQ	#0,D7
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
;	CMPi.W	#$73,D3	;'s'
	CMPi.W	#$77,D3	;'w'
	BEQ.b	MonlbC0023B0
	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC0023B0	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.L	A2,D3
	ANDi.L	#$FFFF,D3
	MOVE.W	D3,(A6)
	BRA	MonlbC002600

MonlbC0023C6:
	MOVE.l	A2,D4	;***
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$28,D3	;'('
	BEQ.b	MonlbC002404

;*** Handle absolute long ***
	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.L	A2,D3
	MOVEQ	#$10,D2
	ASR.L	D2,D3	;shift right 16 (get high word)
	MOVE.W	D3,(A6)	;put high word
	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.L	A2,D3
	ANDi.L	#$FFFF,D3
	MOVE.W	D3,(A6)	;put low word
	SUBQ.L	#1,(CurrentCharPtr-DT,A4)
	BRA	MonlbC002600

MonlbC002404	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3	;'a'
	BNE	MonlbC0024FC
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D7
	SUBi.W	#$30,D7
	MOVEQ	#5,D6
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$29,D3	;')'
	BNE.b	MonlbC00244C
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.W	D4,(A6)
	BRA	MonlbC0024F8

MonlbC00244C	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3	;','
	BNE	MonlbC0024F2
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.W	#3,-(SP)
	MOVE.W	#$6C,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D5
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC00247C
	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC00247C	MOVEQ	#12,D3
	ASL.W	D3,D5
	MOVE.W	D4,D3
	ANDi.W	#$FF,D3
	OR.W	D3,D5
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2E,D3	;'.'
	BEQ.b	MonlbC0024A0
	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC0024A0	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$6C,D3	;'l'
	BNE.b	MonlbC0024B4
	ORi.W	#$800,D5
	BRA.b	MonlbC0024C8

MonlbC0024B4	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$77,D3	;'w'
	BEQ.b	MonlbC0024C8
	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC0024C8	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$29,D3	;')'
	BEQ.b	MonlbC0024E4
	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC0024E4	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.W	D5,(A6)
	MOVEQ	#6,D6
	BRA.b	MonlbC0024F8

MonlbC0024F2	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC0024F8	BRA	MonlbC002600

MonlbC0024FC	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$70,D3	;'p'
	BNE	MonlbC0025FA
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$63,D3	;'c'
	BEQ.b	MonlbC002528
EndPCRel:
	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC002528	MOVEQ	#7,D6
	MOVEQ	#2,D7
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$29,D3	;')'
	BNE.b	MonlbC00254C
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)

	sub.l	(CurrentPC-DT,A4),d4	;current
	addq.l	#2,d4
	cmp.l	#-32768,d4
	blt	EndPCRel
	cmp.l	#32767,d4
	bgt	EndPCRel
	MOVE.W	D4,(A6)
	BRA	MonlbC0025F8

MonlbC00254C	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3	;','
	BNE	MonlbC0025F2
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.W	#3,-(SP)
	MOVE.W	#$6C,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D5
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC00257C
	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC00257C	MOVEQ	#12,D3
	ASL.W	D3,D5

	sub.l	(CurrentPC-DT,A4),d4	;current
	cmp.l	#-128,d4
	blt	EndPCRel
	cmp.l	#127,d4
	bgt	EndPCRel

	MOVE.W	D4,D3
	ANDi.W	#$FF,D3
	OR.W	D3,D5
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2E,D3
	BEQ.b	MonlbC0025A0
	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC0025A0	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$6C,D3
	BNE.b	MonlbC0025B4
	ORi.W	#$800,D5
	BRA.b	MonlbC0025C8

MonlbC0025B4	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$77,D3
	BEQ.b	MonlbC0025C8
	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC0025C8	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$29,D3
	BEQ.b	MonlbC0025E4
	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC0025E4	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.W	D5,(A6)
	MOVEQ	#3,D7
	BRA.b	MonlbC0025F8

MonlbC0025F2	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC0025F8	BRA.b	MonlbC002600

MonlbC0025FA	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

;Create mode-reg field in D0 and return to caller
MonlbC002600:
	CMPi.W	#$FFFF,D6
	BEQ.b	MonlbC002612
	CMPi.W	#7,D7	;D7 is reg sub-field
	BGT.b	MonlbC002612
	CMPi.W	#0,D7
	BGE.b	MonlbC002618
MonlbC002612	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC002618	MOVE.W	D6,D4
	CMPi.W	#7,D6
	BNE.b	MonlbC002622
	ADD.W	D7,D4
MonlbC002622	MOVEQ	#1,D3
	ASL.W	D4,D3
	AND.W	(10,A5),D3
	BNE.b	MonlbC002632
	MOVEQ	#-$1,D0
	BRA	MonlbC00226E

MonlbC002632	MOVE.W	D6,D0
	ASL.W	#3,D0
	OR.W	D7,D0
	BRA	MonlbC00226E

MonlbC00263C:
	LINK.w	A5,#0
	MOVEM.L	D4/D5,-(SP)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$23,D3
	BNE.b	MonlbC0026CC
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.L	A6,-(SP)
	JSR	(MonlbC002166,PC)
	MOVEa.L	(SP)+,A6
	MOVE.W	D0,(A6)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC002684
	MOVEQ	#2,D0
MonlbC00267C	MOVEM.L	(SP)+,D4/D5
	UNLK	A5
	RTS

MonlbC002684	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	MOVE.W	#$62,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC0026AA
	MOVEQ	#2,D0
	BRA.b	MonlbC00267C

MonlbC0026AA	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	D4,D2
	ORi.W	#$800,D2
	MOVE.W	D2,(A6)
	JSR	(MonlbC0020D4,PC)
	BRA.b	MonlbC00267C

MonlbC0026CC	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3	;'d'
	BEQ.b	MonlbC0026E2
	MOVEQ	#2,D0
	BRA.b	MonlbC00267C

MonlbC0026E2	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC002702
	MOVEQ	#2,D0
	BRA	MonlbC00267C

MonlbC002702	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3	;','
	BEQ.b	MonlbC00271A
	MOVEQ	#2,D0
	BRA	MonlbC00267C

MonlbC00271A	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	MOVE.W	#$62,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC002742
	MOVEQ	#2,D0
	BRA	MonlbC00267C

MonlbC002742	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	D5,D2
	MOVEQ	#9,D1
	ASL.W	D1,D2
	MOVE.W	(0,A1,D3.L),D1
	OR.W	D2,D1
	OR.W	D4,D1
	ORi.W	#$100,D1
	MOVE.W	D1,(A6)
	MOVEQ	#0,D0
	BRA	MonlbC00267C

MonlbC00276C	LINK.w	A5,#0
	MOVEM.L	D4-D6,-(SP)
	JSR	(MonlbC002102,PC)
	MOVE.W	D0,D4
	CMPi.W	#1,D0
	BGE.b	MonlbC00278A
	MOVEQ	#1,D0
MonlbC002782	MOVEM.L	(SP)+,D4-D6
	UNLK	A5
	RTS

MonlbC00278A	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3
	BNE	MonlbC00286E
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC0027BC
	MOVEQ	#2,D0
	BRA.b	MonlbC002782

MonlbC0027BC	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC0027D2
	MOVEQ	#2,D0
	BRA.b	MonlbC002782

MonlbC0027D2	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.L	A6,-(SP)
	JSR	(MonlbC002166,PC)
	MOVEa.L	(SP)+,A6
	MOVE.W	D0,(A6)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$28,D3
	BEQ.b	MonlbC0027FA
	MOVEQ	#2,D0
	BRA.b	MonlbC002782

MonlbC0027FA	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC002812
	MOVEQ	#2,D0
	BRA	MonlbC002782

MonlbC002812	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D6
	SUBi.W	#$30,D6
	MOVE.W	D6,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC002832
	MOVEQ	#2,D0
	BRA	MonlbC002782

MonlbC002832	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$29,D3
	BEQ.b	MonlbC00284A
	MOVEQ	#2,D0
	BRA	MonlbC002782

MonlbC00284A	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	D5,D3
	MOVEQ	#9,D2
	ASL.W	D2,D3
	MOVE.W	D4,D2
	NOT.W	D2
	ANDi.W	#1,D2
	ASL.W	#6,D2
	OR.W	D2,D3
	OR.W	D6,D3
	ORi.W	#$188,D3
	MOVE.W	D3,(A6)
	MOVEQ	#0,D0
	BRA	MonlbC002782

MonlbC00286E	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.L	A6,-(SP)
	JSR	(MonlbC002166,PC)
	MOVEa.L	(SP)+,A6
	MOVE.W	D0,(A6)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$28,D3
	BEQ.b	MonlbC002898
	MOVEQ	#2,D0
	BRA	MonlbC002782

MonlbC002898	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC0028B0
	MOVEQ	#2,D0
	BRA	MonlbC002782

MonlbC0028B0	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D6
	SUBi.W	#$30,D6
	MOVE.W	D6,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC0028D0
	MOVEQ	#2,D0
	BRA	MonlbC002782

MonlbC0028D0	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$29,D3
	BEQ.b	MonlbC0028E8
	MOVEQ	#2,D0
	BRA	MonlbC002782

MonlbC0028E8	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC002900
	MOVEQ	#2,D0
	BRA	MonlbC002782

MonlbC002900	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3
	BEQ.b	MonlbC002918
	MOVEQ	#2,D0
	BRA	MonlbC002782

MonlbC002918	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC002938
	MOVEQ	#2,D0
	BRA	MonlbC002782

MonlbC002938	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	D5,D3
	MOVEQ	#9,D2
	ASL.W	D2,D3
	MOVE.W	D4,D2
	NOT.W	D2
	ANDi.W	#1,D2
	ASL.W	#6,D2
	OR.W	D2,D3
	OR.W	D6,D3
	ORi.W	#$108,D3
	MOVE.W	D3,(A6)
	MOVEQ	#0,D0
	BRA	MonlbC002782

;Immediate addressing handler
MonlbC00295C:
;	move.w	#$00f0,$dff180

	LINK.w	A5,#0
	MOVEM.L	D4/D5,-(SP)
	JSR	(MonlbC002102,PC)
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC00297A
	MOVEQ	#1,D0
MonlbC002972	MOVEM.L	(SP)+,D4/D5
	UNLK	A5
	RTS

MonlbC00297A	CMPi.W	#11,(OpcodeTableIndex-DT,A4)
	BGE.b	MonlbC0029B8
	MOVE.W	#$800,-(SP)
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC0029A2
	MOVEQ	#2,D0
	BRA.b	MonlbC002972

MonlbC0029A2	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3	;','
	BEQ.b	MonlbC0029B8
	MOVEQ	#2,D0
	BRA.b	MonlbC002972

MonlbC0029B8	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$73,D3	;'s'
	BNE.b	MonlbC002A00
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),D2
	ANDi.W	#$8000,D2
	BEQ.b	MonlbC002A00
	MOVEQ	#0,D4
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$72,D3
	BEQ.b	MonlbC0029FA
	MOVEQ	#2,D0
	BRA	MonlbC002972

MonlbC0029FA	MOVEQ	#$7C,D5
	BRA	MonlbC002A8E

MonlbC002A00	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$63,D3
	BNE.b	MonlbC002A5E
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),D2
	ANDi.W	#$8000,D2
	BEQ.b	MonlbC002A5E
	MOVEQ	#0,D4
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$63,D3	;'c'
	BEQ.b	MonlbC002A42
	MOVEQ	#2,D0
	BRA	MonlbC002972

MonlbC002A42	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$72,D3	;'r'
	BEQ.b	MonlbC002A5A
	MOVEQ	#2,D0
	BRA	MonlbC002972

MonlbC002A5A	MOVEQ	#$3C,D5
	BRA.b	MonlbC002A8E

MonlbC002A5E	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D5
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC002A8E
	MOVEQ	#2,D0
	BRA	MonlbC002972

MonlbC002A8E	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	D4,D2
	ASL.W	#6,D2
	MOVE.W	(0,A1,D3.L),D1
	OR.W	D2,D1
	OR.W	D5,D1
	MOVE.W	D1,(A6)
	MOVEQ	#0,D0
	BRA	MonlbC002972

MonlbC002AB2	LINK.w	A5,#0
	MOVEM.L	D4/D5,-(SP)
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A6
	MOVE.W	(0,A6,D3.L),(MonlbW0086AE-DT,A4)
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6C-DT,A4),A6
	MOVE.W	(0,A6,D3.L),D2
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D2.W),D4
	MOVE.W	#$FFF,-(SP)
	MOVE.B	D4,D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D5
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC002B06
	MOVEQ	#2,D0
MonlbC002AFE	MOVEM.L	(SP)+,D4/D5
	UNLK	A5
	RTS

MonlbC002B06	OR.W	D5,(MonlbW0086AE-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC002B20
	MOVEQ	#2,D0
	BRA.b	MonlbC002AFE

MonlbC002B20	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	MOVE.B	D4,D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D5
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC002B48
	MOVEQ	#2,D0
	BRA.b	MonlbC002AFE

MonlbC002B48	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	D5,D3
	ANDi.W	#$38,D3
	ASL.W	#3,D3
	MOVE.W	D5,D2
	ANDi.W	#7,D2
	MOVEQ	#9,D1
	ASL.W	D1,D2
	OR.W	D2,D3
	OR.W	(MonlbW0086AE-DT,A4),D3
	MOVE.W	D3,(A6)
	MOVEQ	#0,D0
	BRA.b	MonlbC002AFE

MonlbC002B6A	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$73,D3
	BEQ.b	MonlbC002B8A
	MOVEQ	#2,D0
MonlbC002B84	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC002B8A	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$72,D3
	BEQ.b	MonlbC002BA0
	MOVEQ	#2,D0
	BRA.b	MonlbC002B84

MonlbC002BA0	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC002BB6
	MOVEQ	#2,D0
	BRA.b	MonlbC002B84

MonlbC002BB6	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	MOVE.W	#$77,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC002BDC
	MOVEQ	#2,D0
	BRA.b	MonlbC002B84

MonlbC002BDC	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	D4,D2
	MOVE.W	D2,(A6)
	MOVEQ	#0,D0
	BRA.b	MonlbC002B84

MonlbC002BF8	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	MOVE.W	#$62,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC002C28
	MOVEQ	#2,D0
MonlbC002C22	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC002C28	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC002C3E
	MOVEQ	#2,D0
	BRA.b	MonlbC002C22

MonlbC002C3E	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$63,D3
	BEQ.b	MonlbC002C54
	MOVEQ	#2,D0
	BRA.b	MonlbC002C22

MonlbC002C54	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$63,D3
	BEQ.b	MonlbC002C6A
	MOVEQ	#2,D0
	BRA.b	MonlbC002C22

MonlbC002C6A	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$72,D3
	BEQ.b	MonlbC002C80
	MOVEQ	#2,D0
	BRA.b	MonlbC002C22

MonlbC002C80	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	D4,D2
	MOVE.W	D2,(A6)
	MOVEQ	#0,D0
	BRA.b	MonlbC002C22

MonlbC002C9C	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	MOVE.W	#$77,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC002CCC
	MOVEQ	#2,D0
MonlbC002CC6	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC002CCC	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC002CE2
	MOVEQ	#2,D0
	BRA.b	MonlbC002CC6

MonlbC002CE2	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$73,D3
	BEQ.b	MonlbC002CF8
	MOVEQ	#2,D0
	BRA.b	MonlbC002CC6

MonlbC002CF8	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$72,D3
	BEQ.b	MonlbC002D0E
	MOVEQ	#2,D0
	BRA.b	MonlbC002CC6

MonlbC002D0E	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	D4,D2
	MOVE.W	D2,(A6)
	MOVEQ	#0,D0
	BRA.b	MonlbC002CC6

MonlbC002D2A	LINK.w	A5,#0
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6C-DT,A4),A6
	MOVE.W	(0,A6,D3.L),D2
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D2.W),D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,(MonlbW0086AE-DT,A4)
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC002D70
	MOVEQ	#2,D0
MonlbC002D6C	UNLK	A5
	RTS

MonlbC002D70	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	(MonlbW0086AE-DT,A4),D2
	MOVE.W	D2,(A6)
	MOVEQ	#0,D0
	BRA.b	MonlbC002D6C

MonlbC002D8E	LINK.w	A5,#0
	MOVE.W	#1,-(SP)
	MOVE.W	#$6C,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,(MonlbW0086AE-DT,A4)
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC002DB0
	MOVEQ	#2,D0
MonlbC002DAC	UNLK	A5
	RTS

MonlbC002DB0	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	(MonlbW0086AE-DT,A4),D2
	MOVE.W	D2,(A6)
	MOVEQ	#0,D0
	BRA.b	MonlbC002DAC

MonlbC002DCE	LINK.w	A5,#-$20
	MOVEM.L	D4-D7,-(SP)
	MOVEQ	#0,D4
MonlbC002DD8	MOVE.W	D4,D3
	EXT.L	D3
	ASL.L	#1,D3
	LEA	(-$20,A5),A6
	CLR.W	(0,A6,D3.L)
	ADDQ.W	#1,D4
	CMPi.W	#$10,D4
	BLT.b	MonlbC002DD8
MonlbC002DEE	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC002E0C
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3
	BNE	MonlbC002F14
MonlbC002E0C	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BNE.b	MonlbC002E22
	MOVEQ	#8,D4
	BRA.b	MonlbC002E24

MonlbC002E22	MOVEQ	#0,D4
MonlbC002E24	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC002E48
	MOVEQ	#-$1,D0
MonlbC002E40	MOVEM.L	(SP)+,D4-D7
	UNLK	A5
	RTS

MonlbC002E48	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2D,D3
	BEQ.b	MonlbC002E7E
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2F,D3
	BNE.b	MonlbC002E68
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
MonlbC002E68	MOVE.W	D4,D3
	ADD.W	D5,D3
	EXT.L	D3
	ASL.L	#1,D3
	LEA	(-$20,A5),A6
	MOVE.W	#1,(0,A6,D3.L)
	BRA	MonlbC002F10

MonlbC002E7E	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	TST.W	D4
	BEQ.b	MonlbC002E9E
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC002E9C
	MOVEQ	#-$1,D0
	BRA.b	MonlbC002E40

MonlbC002E9C	BRA.b	MonlbC002EB4

MonlbC002E9E	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3
	BEQ.b	MonlbC002EB4
	MOVEQ	#-$1,D0
	BRA.b	MonlbC002E40

MonlbC002EB4	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D6
	SUBi.W	#$30,D6
	MOVE.W	D6,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC002ED4
	MOVEQ	#-$1,D0
	BRA	MonlbC002E40

MonlbC002ED4	CMP.W	D5,D6
	BGE.b	MonlbC002EDE
	MOVE.W	D5,D7
	MOVE.W	D6,D5
	MOVE.W	D7,D6
MonlbC002EDE	MOVE.W	D4,D7
	ADD.W	D5,D7
	BRA.b	MonlbC002EF6

MonlbC002EE4	MOVE.W	D7,D3
	EXT.L	D3
	ASL.L	#1,D3
	LEA	(-$20,A5),A6
	MOVE.W	#1,(0,A6,D3.L)
	ADDQ.W	#1,D7
MonlbC002EF6	MOVE.W	D4,D3
	ADD.W	D6,D3
	CMP.W	D3,D7
	BLE.b	MonlbC002EE4
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2F,D3
	BNE.b	MonlbC002F10
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
MonlbC002F10	BRA	MonlbC002DEE

MonlbC002F14	MOVEQ	#0,D5
	MOVEQ	#15,D4
MonlbC002F18	ASL.W	#1,D5
	MOVE.W	D4,D3
	EXT.L	D3
	ASL.L	#1,D3
	LEA	(-$20,A5),A6
	CMPi.W	#1,(0,A6,D3.L)
	BNE.b	MonlbC002F30
	ORi.W	#1,D5
MonlbC002F30	SUBQ.W	#1,D4
	CMPi.W	#0,D4
	BGE.b	MonlbC002F18
	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	D5,(2,A6)
	MOVEQ	#0,D0
	BRA	MonlbC002E40

;Movem routine

MonlbC002F46:
	LINK.w	A5,#0
	MOVEM.L	D4-D7,-(SP)

;	MOVEa.L	(MonlbL0086B0-DT,A4),A6

;	move.l	(a6),$90000
;	move.l	(4,a6),$90004

;	move.w	(4,a6),(-8,a5)

	ADDQ.L	#2,(CurrentPC-DT,A4)
	JSR	(MonlbC002102,PC)
	MOVE.W	D0,D4
	CMPi.W	#1,D0
	BGE.b	MonlbC002F68
	MOVEQ	#1,D0
MonlbC002F60	MOVEM.L	(SP)+,D4-D7
	UNLK	A5
	RTS

MonlbC002F68	CMPi.W	#$18,(OpcodeTableIndex-DT,A4)
	BEQ.b	MonlbC002FC2
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D5
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC002F9E
	MOVEQ	#2,D0
	BRA.b	MonlbC002F60

MonlbC002F9E	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3	;','
	BEQ.b	MonlbC002FB4
	MOVEQ	#2,D0
	BRA.b	MonlbC002F60

MonlbC002FB4	JSR	(MonlbC002DCE,PC)
	TST.W	D0
	BEQ.b	MonlbC002FC0
	MOVEQ	#2,D0
	BRA.b	MonlbC002F60

MonlbC002FC0	BRA.b	MonlbC003016

MonlbC002FC2	JSR	(MonlbC002DCE,PC)
	TST.W	D0
	BEQ.b	MonlbC002FCE
	MOVEQ	#2,D0
	BRA.b	MonlbC002F60

MonlbC002FCE	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3	;','
	BEQ.b	MonlbC002FE6
	MOVEQ	#2,D0
	BRA	MonlbC002F60

MonlbC002FE6	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D5
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC003016
	MOVEQ	#2,D0
	BRA	MonlbC002F60

MonlbC003016	MOVE.W	D5,D3
	ANDi.W	#$38,D3
	CMPi.W	#$20,D3
	BNE.b	MonlbC003052
	MOVEQ	#0,D6
	MOVEQ	#0,D7
MonlbC003026	ASL.W	#1,D6
	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(2,A6),D3
	ANDi.W	#1,D3
	BEQ.b	MonlbC00303A
	ORi.W	#1,D6
MonlbC00303A	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	LSR.w	(2,A6)
	ADDQ.W	#1,D7
	CMPi.W	#$10,D7	;16
	BLT.b	MonlbC003026
	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	D6,(2,A6)	;writes second word
MonlbC003052:
	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	D4,D2
	NOT.W	D2
	ANDi.W	#1,D2
	ASL.W	#6,D2
	MOVE.W	(0,A1,D3.L),D1
	OR.W	D2,D1
	OR.W	D5,D1
	MOVE.W	D1,(A6)	;writes opcode

;	move.w	(-8,a5),(4,a6)

	MOVEQ	#0,D0
	BRA	MonlbC002F60

MonlbC00307C	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$23,D3
	BEQ.b	MonlbC00309C
	MOVEQ	#2,D0
MonlbC003096	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC00309C	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVEQ	#0,D2
	MOVE.W	(0,A1,D3.L),D2
	MOVE.L	A6,-(SP)
	MOVE.L	D2,-(SP)
	JSR	(MonlbC002166,PC)
	ANDi.L	#15,D0
	MOVE.L	(SP)+,D2
	OR.L	D0,D2
	MOVEa.L	(SP)+,A6
	MOVE.W	D2,(A6)
	MOVEQ	#0,D0
	BRA.b	MonlbC003096

MonlbC0030CC	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC0030EC
	MOVEQ	#2,D0
MonlbC0030E6	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC0030EC	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D4
	SUBi.W	#$30,D4
	MOVE.W	D4,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC00310A
	MOVEQ	#2,D0
	BRA.b	MonlbC0030E6

MonlbC00310A	CMPi.W	#$1F,(OpcodeTableIndex-DT,A4)
	BNE.b	MonlbC003150
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC003128
	MOVEQ	#2,D0
	BRA.b	MonlbC0030E6

MonlbC003128	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$23,D3
	BEQ.b	MonlbC00313E
	MOVEQ	#2,D0
	BRA.b	MonlbC0030E6

MonlbC00313E	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.L	A6,-(SP)
	JSR	(MonlbC002166,PC)
	MOVEa.L	(SP)+,A6
	MOVE.W	D0,(A6)
MonlbC003150	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	D4,D2
	MOVE.W	D2,(A6)
	MOVEQ	#0,D0
	BRA	MonlbC0030E6

MonlbC00316E	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC00318E
	MOVEQ	#2,D0
MonlbC003188	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC00318E	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D4
	SUBi.W	#$30,D4
	MOVE.W	D4,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC0031AC
	MOVEQ	#2,D0
	BRA.b	MonlbC003188

MonlbC0031AC	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC0031C2
	MOVEQ	#2,D0
	BRA.b	MonlbC003188

MonlbC0031C2	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$75,D3
	BEQ.b	MonlbC0031D8
	MOVEQ	#2,D0
	BRA.b	MonlbC003188

MonlbC0031D8	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$73,D3
	BEQ.b	MonlbC0031EE
	MOVEQ	#2,D0
	BRA.b	MonlbC003188

MonlbC0031EE	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$70,D3	;'p'
	BEQ.b	MonlbC003204
	MOVEQ	#2,D0
	BRA.b	MonlbC003188

MonlbC003204	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	D4,D2
	MOVE.W	D2,(A6)
	MOVEQ	#0,D0
	BRA	MonlbC003188

MonlbC003222	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$75,D3
	BEQ.b	MonlbC003242
	MOVEQ	#2,D0
MonlbC00323C	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC003242	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$73,D3
	BEQ.b	MonlbC003258
	MOVEQ	#2,D0
	BRA.b	MonlbC00323C

MonlbC003258	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$70,D3	;'p'
	BEQ.b	MonlbC00326E
	MOVEQ	#2,D0
	BRA.b	MonlbC00323C

MonlbC00326E	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3	;','
	BEQ.b	MonlbC003284
	MOVEQ	#2,D0
	BRA.b	MonlbC00323C

MonlbC003284	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC00329A
	MOVEQ	#2,D0
	BRA.b	MonlbC00323C

MonlbC00329A	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D4
	SUBi.W	#$30,D4
	MOVE.W	D4,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC0032B8
	MOVEQ	#2,D0
	BRA.b	MonlbC00323C

MonlbC0032B8	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	D4,D2
	MOVE.W	D2,(A6)
	MOVEQ	#0,D0
	BRA	MonlbC00323C

MonlbC0032D6	LINK.w	A5,#0
	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),(A6)
	CMPi.W	#$25,(OpcodeTableIndex-DT,A4)
	BEQ.b	MonlbC0032FC
	MOVEQ	#0,D0
MonlbC0032F8	UNLK	A5
	RTS

MonlbC0032FC	MOVE.W	#$800,-(SP)
	MOVE.W	#$77,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC003314
	MOVEQ	#2,D0
	BRA.b	MonlbC0032F8

MonlbC003314	MOVEQ	#0,D0
	BRA.b	MonlbC0032F8

MonlbC003318	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6C-DT,A4),A6
	MOVE.W	(0,A6,D3.L),D2
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D2.W),D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,(MonlbW0086AE-DT,A4)
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC003362
	MOVEQ	#2,D0
MonlbC00335C	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC003362	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC003378
	MOVEQ	#2,D0
	BRA.b	MonlbC00335C

MonlbC003378	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3
	BEQ.b	MonlbC00338E
	MOVEQ	#2,D0
	BRA.b	MonlbC00335C

MonlbC00338E	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D4
	SUBi.W	#$30,D4
	MOVE.W	D4,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC0033AC
	MOVEQ	#2,D0
	BRA.b	MonlbC00335C

MonlbC0033AC	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	D4,D2
	MOVEQ	#9,D1
	ASL.W	D1,D2
	MOVE.W	(0,A1,D3.L),D1
	OR.W	D2,D1
	OR.W	(MonlbW0086AE-DT,A4),D1
	MOVE.W	D1,(A6)
	MOVEQ	#0,D0
	BRA.b	MonlbC00335C

;Lea-handling routine
MonlbC0033D2:
	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6C-DT,A4),A6
	MOVE.W	(0,A6,D3.L),D2
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D2.W),D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)	;do EA
	ADDQ.W	#4,SP
	MOVE.W	D0,(MonlbW0086AE-DT,A4)
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC00341C
	MOVEQ	#2,D0
MonlbC003416	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC00341C	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3	;','
	BEQ.b	MonlbC003432
	MOVEQ	#2,D0
	BRA.b	MonlbC003416

MonlbC003432	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC003448
	MOVEQ	#2,D0
	BRA.b	MonlbC003416

MonlbC003448	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D4
	SUBi.W	#$30,D4
	MOVE.W	D4,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003466
	MOVEQ	#2,D0
	BRA.b	MonlbC003416

MonlbC003466	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	D4,D2
	MOVEQ	#9,D1
	ASL.W	D1,D2
	MOVE.W	(0,A1,D3.L),D1
	OR.W	D2,D1
	OR.W	(MonlbW0086AE-DT,A4),D1
	MOVE.W	D1,(A6)
	MOVEQ	#0,D0
	BRA.b	MonlbC003416

MonlbC00348C	LINK.w	A5,#0
	MOVEM.L	D4/D5,-(SP)
	JSR	(MonlbC002102,PC)
	MOVE.W	D0,D5
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC0034AA
	MOVEQ	#1,D0
MonlbC0034A2	MOVEM.L	(SP)+,D4/D5
	UNLK	A5
	RTS

MonlbC0034AA	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$23,D3
	BEQ.b	MonlbC0034C0
	MOVEQ	#2,D0
	BRA.b	MonlbC0034A2

MonlbC0034C0	JSR	(MonlbC002166,PC)
	MOVE.W	D0,(MonlbW0086AE-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC0034DE
	MOVEQ	#2,D0
	BRA.b	MonlbC0034A2

MonlbC0034DE	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D5.W),D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC00350C
	MOVEQ	#2,D0
	BRA.b	MonlbC0034A2

MonlbC00350C	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(MonlbW0086AE-DT,A4),D2
	ANDi.W	#7,D2
	MOVEQ	#9,D1
	ASL.W	D1,D2
	MOVE.W	(0,A1,D3.L),D1
	OR.W	D2,D1
	MOVE.W	D5,D3
	ASL.W	#6,D3
	OR.W	D3,D1
	OR.W	D4,D1
	MOVE.W	D1,(A6)
	MOVEQ	#0,D0
	BRA	MonlbC0034A2

MonlbC00353E	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	PEA	(tfhilscccsnee.MSG-DT,A4)
	JSR	(MonlbC00200E,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,(MonlbW0086AE-DT,A4)
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC003560
	MOVEQ	#1,D0
MonlbC00355A	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC003560	JSR	(MonlbC002096,PC)
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	MOVE.W	#$62,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC00358A
	MOVEQ	#2,D0
	BRA.b	MonlbC00355A

MonlbC00358A	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	(MonlbW0086AE-DT,A4),D2
	OR.W	D4,D2
	MOVE.W	D2,(A6)
	MOVEQ	#0,D0
	BRA.b	MonlbC00355A

;DBcc handling routine
MonlbC0035AA	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	PEA	(tfhilscccsnee.MSG-DT,A4)
	JSR	(MonlbC00200E,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,(MonlbW0086AE-DT,A4)
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC0035CC
EndDBcc:
	MOVEQ	#1,D0
MonlbC0035C6	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC0035CC	JSR	(MonlbC002096,PC)
	MOVE.W	#1,-(SP)
	MOVE.W	#$77,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC0035EA
	MOVEQ	#2,D0
	BRA.b	MonlbC0035C6

MonlbC0035EA	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3	;','
	BEQ.b	MonlbC003600
	MOVEQ	#2,D0
	BRA.b	MonlbC0035C6

MonlbC003600	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	(MonlbW0086AE-DT,A4),D2
	OR.W	D4,D2
	MOVE.W	D2,(A6)
	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.L	A6,-(SP)
	JSR	(GetNum,PC)
	MOVEa.L	(SP)+,A6

	sub.l	(CurrentPC-DT,A4),d0	;current
	addq.l	#2,d0
	cmp.l	#-32768,d0
	blt	EndDBcc
	cmp.l	#32767,d0
	bgt	EndDBcc

	MOVE.W	D0,(A6)
	MOVEQ	#0,D0
	BRA	MonlbC0035C6

;Branch (bcc) handling routine

MonlbC003632	LINK.w	A5,#0
	MOVEM.L	D4/D5,-(SP)
	PEA	(rasrhilscccsn.MSG-DT,A4)
	JSR	(MonlbC00200E,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,(MonlbW0086AE-DT,A4)
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC003658
EndBcc:
	MOVEQ	#1,D0
MonlbC003650	MOVEM.L	(SP)+,D4/D5
	UNLK	A5
	RTS

MonlbC003658	JSR	(MonlbC002102,PC)
	MOVE.W	D0,D4

;	move.l	d0,($380000)	;0 = short, 1 = long

	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC003668
	MOVEQ	#1,D0
	BRA.b	MonlbC003650

MonlbC003668	JSR	(GetNum,PC)
	MOVE.l	D0,D5

;	move.l	d0,($380004)	;number typed

	sub.l	(CurrentPC-DT,A4),d5	;current

	TST.W	D4
	BEQ.b	MonlbC003698	;go if short

	cmp.l	#-32768,d5
	blt	EndBcc
	cmp.l	#32767,d5
	bgt	EndBcc

	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	(MonlbW0086AE-DT,A4),D2
	MOVE.W	D2,(A6)
	MOVEa.L	(CurrentPC-DT,A4),A6
	ADDQ.L	#2,(CurrentPC-DT,A4)
	MOVE.W	D5,(A6)
	BRA.b	MonlbC0036BA

MonlbC003698

;Short branch case

	tst.l	d5
	beq	EndBcc	;zero offset illegal for short
	cmp.l	#-128,d5
	blt	EndBcc
	cmp.l	#127,d5
	bgt	EndBcc

	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	D5,D2
	ANDi.W	#$FF,D2
	MOVE.W	(0,A1,D3.L),D1
	OR.W	D2,D1
	OR.W	(MonlbW0086AE-DT,A4),D1
	MOVE.W	D1,(A6)
MonlbC0036BA	MOVEQ	#0,D0
	BRA	MonlbC003650

;moveq

MonlbC0036BE:
	LINK.w	A5,#0
	MOVEM.L	D4/D5,-(SP)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$23,D3	;'#'
	BEQ.b	MonlbC0036E2
	MOVEQ	#2,D0
MonlbC0036DA	MOVEM.L	(SP)+,D4/D5
	UNLK	A5
	RTS

MonlbC0036E2	JSR	(MonlbC002166,PC)
	MOVE.W	D0,D4
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3	;','
	BEQ.b	MonlbC0036FE
	MOVEQ	#2,D0
	BRA.b	MonlbC0036DA

MonlbC0036FE	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3	;'d'
	BEQ.b	MonlbC003714
	MOVEQ	#2,D0
	BRA.b	MonlbC0036DA

MonlbC003714	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003732
	MOVEQ	#2,D0
	BRA.b	MonlbC0036DA

MonlbC003732	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	D5,D2
	MOVEQ	#9,D1
	ASL.W	D1,D2
	MOVE.W	(0,A1,D3.L),D1
	OR.W	D2,D1
	MOVE.W	D4,D3
	ANDi.W	#$FF,D3
	OR.W	D3,D1
	MOVE.W	D1,(A6)
	MOVEQ	#0,D0
	BRA	MonlbC0036DA

;********** Add-handling routine (and much more!) *****************

MonlbC00375E:
;	move.w	#$0f00,$dff180

	LINK.w	A5,#0
	MOVEM.L	D4-D6,-(SP)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3	;'a'
	BEQ	MonlbC0038F0
	cmp.b	#'i',d3
	bne.b	.skipi
	addq.l	#1,(CurrentCharPtr-DT,A4)
	bra.b	DoAddI
.skipi:
	move.l	(CurrentPC-DT,A4),-(sp)
	push	a6
	JSR	(MonlbC002102,PC)
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC00378C	;main add
	MOVEQ	#1,D0
MonlbC003784:	;main add returns here
	pop	a6
	addq.l	#4,sp
	tst.l	d0
	beq.b	EndAdd
;	move.w	#$0f00,$dff180
	subq.l	#4,sp
	move.l	(sp),(CurrentPC-DT,A4)
	push	a6
	subq.l	#1,a6
	move.l	a6,(CurrentCharPtr-DT,A4)
	bra	MonlbC0038F0	;try adda

ReturnFromAdda:
	pop	a6
	addq.l	#4,sp
	tst.l	d0
	beq.b	EndAdd
	move.l	(-4,sp),(CurrentPC-DT,A4)
	move.l	a6,(CurrentCharPtr-DT,A4)
DoAddI:
	push	a0
	lea	(MagicTable,pc),a0
.loop:
	move.b	(a0),d0
	beq.b	EndAdd1
	cmp.b	(OpcodeTableIndex-DT+1,A4),d0
	beq.b	.hit
	addq.l	#2,a0
	bra.b	.loop
.hit:
	move.b	(1,a0),(OpcodeTableIndex-DT+1,A4)
	bsr	MonlbC00295C	;immediate
EndAdd1:
	pop	a0
EndAdd:
	move.b	#$49,(OpcodeTableIndex-DT+1,A4)
	MOVEM.L	(SP)+,D4-D6
	UNLK	A5
	RTS

MonlbC00378C	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3	;'d'
	BNE.b	MonlbC0037BC
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3	;'d'
	BNE	MonlbC003862
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(3,A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3	;'d'
	BNE	MonlbC003862
MonlbC0037BC	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D5
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC0037EA
	MOVEQ	#2,D0
	BRA	MonlbC003784

MonlbC0037EA	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3	;','
	BEQ.b	MonlbC003800
	MOVEQ	#2,D0
	BRA	MonlbC003784

MonlbC003800	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3	;'d'
	BEQ.b	MonlbC003818
	MOVEQ	#2,D0
	BRA	MonlbC003784

MonlbC003818	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D6
	SUBi.W	#$30,D6
	MOVE.W	D6,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003838
	MOVEQ	#2,D0
	BRA	MonlbC003784

MonlbC003838	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	D4,D2
	ASL.W	#6,D2
	MOVE.W	(0,A1,D3.L),D1
	OR.W	D2,D1
	MOVE.W	D6,D3
	MOVEQ	#9,D2
	ASL.W	D2,D3
	OR.W	D3,D1
	OR.W	D5,D1
	MOVE.W	D1,(A6)
	BRA	MonlbC0038EC

MonlbC003862	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D6
	SUBi.W	#$30,D6
	MOVE.W	D6,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003886
	MOVEQ	#2,D0
	BRA	MonlbC003784

MonlbC003886	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC00389E
	MOVEQ	#2,D0
	BRA	MonlbC003784

MonlbC00389E	MOVE.W	#$1FC,-(SP)
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D5
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC0038C2
	MOVEQ	#2,D0
	BRA	MonlbC003784

MonlbC0038C2	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	D4,D2
	ASL.W	#6,D2
	MOVE.W	(0,A1,D3.L),D1
	OR.W	D2,D1
	MOVE.W	D6,D3
	MOVEQ	#9,D2
	ASL.W	D2,D3
	OR.W	D3,D1
	OR.W	D5,D1
	ORi.W	#$100,D1
	MOVE.W	D1,(A6)
MonlbC0038EC	BRA	MonlbC0039C0

MonlbC0038F0	CMPi.W	#$34,(OpcodeTableIndex-DT,A4)
	BEQ.b	MonlbC003900
	CMPi.W	#$3E,(OpcodeTableIndex-DT,A4)
	BNE.b	MonlbC003906
MonlbC003900	MOVEQ	#1,D0
	BRA	ReturnFromAdda

MonlbC003906	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	JSR	(MonlbC002102,PC)
	MOVE.W	D0,D4
	CMPi.W	#1,D0
	BGE.b	MonlbC00391C
	MOVEQ	#1,D0
	BRA	ReturnFromAdda

MonlbC00391C	MOVE.W	#$FFF,-(SP)
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D5
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC003940
	MOVEQ	#2,D0
	BRA	ReturnFromAdda

MonlbC003940	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC003958
	MOVEQ	#2,D0
	BRA	ReturnFromAdda

MonlbC003958	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC003970
	MOVEQ	#2,D0
	BRA	ReturnFromAdda

MonlbC003970	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D6
	SUBi.W	#$30,D6
	MOVE.W	D6,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003990
	MOVEQ	#2,D0
	BRA	ReturnFromAdda

MonlbC003990	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	D6,D2
	MOVEQ	#9,D1
	ASL.W	D1,D2
	MOVE.W	(0,A1,D3.L),D1
	OR.W	D2,D1
	MOVE.W	D4,D3
	NOT.W	D3
	ANDi.W	#1,D3
	ASL.W	#8,D3
	OR.W	D3,D1
	OR.W	D5,D1
	ORi.W	#$C0,D1
	MOVE.W	D1,(A6)
MonlbC0039C0	MOVEQ	#0,D0
	BRA	ReturnFromAdda

MonlbC0039C6	LINK.w	A5,#0
	MOVEM.L	D4/D5,-(SP)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2D,D3
	BEQ.b	MonlbC0039E6
	CMPi.W	#$3C,(OpcodeTableIndex-DT,A4)
	BNE	MonlbC003B72
MonlbC0039E6	CMPi.W	#$3C,(OpcodeTableIndex-DT,A4)
	BEQ.b	MonlbC0039F2
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
MonlbC0039F2	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$28,D3
	BEQ.b	MonlbC003A0E
	MOVEQ	#2,D0
MonlbC003A06	MOVEM.L	(SP)+,D4/D5
	UNLK	A5
	RTS

MonlbC003A0E	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC003A24
	MOVEQ	#2,D0
	BRA.b	MonlbC003A06

MonlbC003A24	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D4
	SUBi.W	#$30,D4
	MOVE.W	D4,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003A42
	MOVEQ	#2,D0
	BRA.b	MonlbC003A06

MonlbC003A42	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$29,D3
	BEQ.b	MonlbC003A58
	MOVEQ	#2,D0
	BRA.b	MonlbC003A06

MonlbC003A58	CMPi.W	#$3C,(OpcodeTableIndex-DT,A4)
	BNE.b	MonlbC003A76
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2B,D3
	BEQ.b	MonlbC003A76
	MOVEQ	#2,D0
	BRA.b	MonlbC003A06

MonlbC003A76	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC003A8E
	MOVEQ	#2,D0
	BRA	MonlbC003A06

MonlbC003A8E	CMPi.W	#$3C,(OpcodeTableIndex-DT,A4)
	BEQ.b	MonlbC003AAE
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2D,D3
	BEQ.b	MonlbC003AAE
	MOVEQ	#2,D0
	BRA	MonlbC003A06

MonlbC003AAE	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$28,D3
	BEQ.b	MonlbC003AC6
	MOVEQ	#2,D0
	BRA	MonlbC003A06

MonlbC003AC6	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC003ADE
	MOVEQ	#2,D0
	BRA	MonlbC003A06

MonlbC003ADE	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003AFE
	MOVEQ	#2,D0
	BRA	MonlbC003A06

MonlbC003AFE	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$29,D3
	BEQ.b	MonlbC003B16
	MOVEQ	#2,D0
	BRA	MonlbC003A06

MonlbC003B16	CMPi.W	#$3C,(OpcodeTableIndex-DT,A4)
	BNE.b	MonlbC003B36
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2B,D3
	BEQ.b	MonlbC003B36
	MOVEQ	#2,D0
	BRA	MonlbC003A06

MonlbC003B36	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(OpcodeTableIndex-DT,A4),D2
	MULS.w	#14,D2
	LEA	(MonlbW007E6C-DT,A4),A0
	MOVE.W	(0,A0,D2.L),D1
	ASL.W	#6,D1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	D1,D2
	MOVE.W	D4,D3
	MOVEQ	#9,D1
	ASL.W	D1,D3
	OR.W	D3,D2
	OR.W	D5,D2
	ORi.W	#8,D2
	MOVE.W	D2,(A6)
	BRA	MonlbC003C2E

MonlbC003B72	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3
	BEQ.b	MonlbC003B8A
	MOVEQ	#2,D0
	BRA	MonlbC003A06

MonlbC003B8A	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D4
	SUBi.W	#$30,D4
	MOVE.W	D4,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003BAA
	MOVEQ	#2,D0
	BRA	MonlbC003A06

MonlbC003BAA	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC003BC2
	MOVEQ	#2,D0
	BRA	MonlbC003A06

MonlbC003BC2	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3
	BEQ.b	MonlbC003BDA
	MOVEQ	#2,D0
	BRA	MonlbC003A06

MonlbC003BDA	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003BFA
	MOVEQ	#2,D0
	BRA	MonlbC003A06

MonlbC003BFA	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	(OpcodeTableIndex-DT,A4),D2
	MULS.w	#14,D2
	LEA	(MonlbW007E6C-DT,A4),A0
	MOVE.W	(0,A0,D2.L),D1
	ASL.W	#6,D1
	MOVE.W	(0,A1,D3.L),D2
	OR.W	D1,D2
	MOVE.W	D5,D3
	MOVEQ	#9,D1
	ASL.W	D1,D3
	OR.W	D3,D2
	OR.W	D4,D2
	MOVE.W	D2,(A6)
MonlbC003C2E	MOVEQ	#0,D0
	BRA	MonlbC003A06

MonlbC003C34	LINK.w	A5,#0
	MOVE.L	D4,-(SP)
	JSR	(MonlbC002102,PC)
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC003C4E
	MOVEQ	#1,D0
MonlbC003C48	MOVE.L	(SP)+,D4
	UNLK	A5
	RTS

MonlbC003C4E	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6C-DT,A4),A6
	MOVE.W	D4,(0,A6,D3.L)
	JSR	(MonlbC0039C6,PC)
	MOVE.W	D0,D4
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6C-DT,A4),A6
	MOVE.W	#4,(0,A6,D3.L)
	MOVE.W	D4,D0
	BRA.b	MonlbC003C48

;Eor-handler
MonlbC003C7A:
	LINK.w	A5,#0
	MOVEM.L	D4-D6,-(SP)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	cmp.b	#'i',d3
	bne.b	.skipimm
	addq.l	#1,(CurrentCharPtr-DT,A4)
	bra.b	DoEorI
.skipimm:
	move.l	(CurrentPC-DT,A4),-(sp)
	push	a6
	JSR	(MonlbC002102,PC)
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC003C98
	MOVEQ	#1,D0
MonlbC003C90:	;return from eor
	pop	a6
	addq.l	#4,sp
	tst.l	d0
	beq.b	EndEor
	move.l	(-4,sp),(CurrentPC-DT,A4)
	move.l	a6,(CurrentCharPtr-DT,A4)
DoEori:
	move.b	#9,(OpcodeTableIndex-DT+1,A4)
	bsr	MonlbC00295C	;immediate
EndEor:
	move.b	#$49,(OpcodeTableIndex-DT+1,A4)
	MOVEM.L	(SP)+,D4-D6
	UNLK	A5
	RTS

MonlbC003C98	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3	;'d'
	BEQ.b	MonlbC003CAE
	MOVEQ	#2,D0
	BRA.b	MonlbC003C90

MonlbC003CAE	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003CCC
	MOVEQ	#2,D0
	BRA.b	MonlbC003C90

MonlbC003CCC	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC003CE2
	MOVEQ	#2,D0
	BRA.b	MonlbC003C90

MonlbC003CE2	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E6A-DT,A4),A6
	MOVE.W	(0,A6,D3.L),-(SP)
	LEA	(bwl.MSG-DT,A4),A6
	MOVE.B	(0,A6,D4.W),D3
	EXT.W	D3
	MOVE.W	D3,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D6
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC003D10
	MOVEQ	#2,D0
	BRA	MonlbC003C90

MonlbC003D10	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	MULS.w	#14,D3
	LEA	(MonlbW007E64-DT,A4),A1
	MOVE.W	D4,D2
	ASL.W	#6,D2
	MOVE.W	(0,A1,D3.L),D1
	OR.W	D2,D1
	MOVE.W	D5,D3
	MOVEQ	#9,D2
	ASL.W	D2,D3
	OR.W	D3,D1
	OR.W	D6,D1
	MOVE.W	D1,(A6)
	MOVEQ	#0,D0
	BRA	MonlbC003C90

MonlbC003D3C	LINK.w	A5,#0
	MOVEM.L	D4/D5,-(SP)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3
	BNE	MonlbC003E24
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D4
	SUBi.W	#$30,D4
	MOVE.W	D4,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003D7C
	MOVEQ	#2,D0
MonlbC003D74	MOVEM.L	(SP)+,D4/D5
	UNLK	A5
	RTS

MonlbC003D7C	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC003D92
	MOVEQ	#2,D0
	BRA.b	MonlbC003D74

MonlbC003D92	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3
	BNE.b	MonlbC003DD6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003DC2
	MOVEQ	#2,D0
	BRA.b	MonlbC003D74

MonlbC003DC2	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	D5,D3
	MOVEQ	#9,D2
	ASL.W	D2,D3
	OR.W	D4,D3
	ORi.W	#$C140,D3
	MOVE.W	D3,(A6)
	BRA.b	MonlbC003E1E

MonlbC003DD6	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC003DEC
	MOVEQ	#2,D0
	BRA.b	MonlbC003D74

MonlbC003DEC	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003E0C
	MOVEQ	#2,D0
	BRA	MonlbC003D74

MonlbC003E0C	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	D4,D3
	MOVEQ	#9,D2
	ASL.W	D2,D3
	OR.W	D5,D3
	ORi.W	#$C188,D3
	MOVE.W	D3,(A6)
MonlbC003E1E	MOVEQ	#0,D0
	BRA	MonlbC003D74

MonlbC003E24	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC003E3C
	MOVEQ	#2,D0
	BRA	MonlbC003D74

MonlbC003E3C	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D4
	SUBi.W	#$30,D4
	MOVE.W	D4,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003E5C
	MOVEQ	#2,D0
	BRA	MonlbC003D74

MonlbC003E5C	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC003E74
	MOVEQ	#2,D0
	BRA	MonlbC003D74

MonlbC003E74	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3
	BNE.b	MonlbC003EBA
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003EA6
	MOVEQ	#2,D0
	BRA	MonlbC003D74

MonlbC003EA6	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	D5,D3
	MOVEQ	#9,D2
	ASL.W	D2,D3
	OR.W	D4,D3
	ORi.W	#$C188,D3
	MOVE.W	D3,(A6)
	BRA.b	MonlbC003F04

MonlbC003EBA	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$61,D3
	BEQ.b	MonlbC003ED2
	MOVEQ	#2,D0
	BRA	MonlbC003D74

MonlbC003ED2	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003EF2
	MOVEQ	#2,D0
	BRA	MonlbC003D74

MonlbC003EF2	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	D4,D3
	MOVEQ	#9,D2
	ASL.W	D2,D3
	OR.W	D5,D3
	ORi.W	#$C148,D3
	MOVE.W	D3,(A6)
MonlbC003F04	MOVEQ	#0,D0
	BRA	MonlbC003D74

MonlbC003F0A	LINK.w	A5,#0
	MOVEM.L	D4-D6,-(SP)
	MOVE.W	#$E000,(MonlbW0086AE-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$6C,D3
	BNE.b	MonlbC003F2E
	ORi.W	#$100,(MonlbW0086AE-DT,A4)
	BRA.b	MonlbC003F46

MonlbC003F2E	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$72,D3
	BEQ.b	MonlbC003F46
	MOVEQ	#1,D0
MonlbC003F3E	MOVEM.L	(SP)+,D4-D6
	UNLK	A5
	RTS

MonlbC003F46	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	JSR	(MonlbC002102,PC)
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC003F5A
	MOVEQ	#1,D0
	BRA.b	MonlbC003F3E

MonlbC003F5A	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3
	BEQ.b	MonlbC003FBA
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$23,D3
	BEQ.b	MonlbC003FBA
	CMPi.W	#1,D4
	BEQ.b	MonlbC003F80
	MOVEQ	#1,D0
	BRA.b	MonlbC003F3E

MonlbC003F80	MOVE.W	#$1FC,-(SP)
	MOVE.W	#$77,-(SP)
	JSR	(MonlbC002206,PC)
	ADDQ.W	#4,SP
	MOVE.W	D0,D4
	CMPi.W	#$FFFF,D0
	BNE.b	MonlbC003F9A
	MOVEQ	#2,D0
	BRA.b	MonlbC003F3E

MonlbC003F9A	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	(OpcodeTableIndex-DT,A4),D3
	SUBi.W	#$45,D3
	MOVEQ	#9,D2
	ASL.W	D2,D3
	OR.W	(MonlbW0086AE-DT,A4),D3
	OR.W	D4,D3
	ORi.W	#$C0,D3
	MOVE.W	D3,(A6)
	MOVEQ	#0,D0
	BRA.b	MonlbC003F3E

MonlbC003FBA	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$23,D3
	BNE.b	MonlbC003FDA
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	JSR	(MonlbC002166,PC)
	ANDi.L	#7,D0
	MOVE.W	D0,D5
	BRA.b	MonlbC004004

MonlbC003FDA	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D5
	SUBi.W	#$30,D5
	MOVE.W	D5,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC003FFE
	MOVEQ	#2,D0
	BRA	MonlbC003F3E

MonlbC003FFE	ORi.W	#$20,(MonlbW0086AE-DT,A4)
MonlbC004004	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$2C,D3
	BEQ.b	MonlbC00401C
	MOVEQ	#2,D0
	BRA	MonlbC003F3E

MonlbC00401C	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	CMPi.W	#$64,D3
	BEQ.b	MonlbC004034
	MOVEQ	#2,D0
	BRA	MonlbC003F3E

MonlbC004034	MOVEa.L	(CurrentCharPtr-DT,A4),A6
	ADDQ.L	#1,(CurrentCharPtr-DT,A4)
	MOVE.B	(A6),D3
	EXT.W	D3
	MOVE.W	D3,D6
	SUBi.W	#$30,D6
	MOVE.W	D6,D3
	ANDi.W	#$FFF8,D3
	BEQ.b	MonlbC004054
	MOVEQ	#2,D0
	BRA	MonlbC003F3E

MonlbC004054	MOVEa.L	(MonlbL0086B0-DT,A4),A6
	MOVE.W	D5,D3
	MOVEQ	#9,D2
	ASL.W	D2,D3
	MOVE.W	D4,D2
	ASL.W	#6,D2
	OR.W	D2,D3
	MOVE.W	(OpcodeTableIndex-DT,A4),D2
	SUBi.W	#$45,D2
	ASL.W	#3,D2
	OR.W	D2,D3
	OR.W	(MonlbW0086AE-DT,A4),D3
	OR.W	D6,D3
	MOVE.W	D3,(A6)
	MOVEQ	#0,D0
	BRA	MonlbC003F3E

; ----------------------------------------------

MonlbC006C8E:
	MOVEM.L	D2/D3,-(SP)
	MOVE.W	D1,D2
	MULU.w	D0,D2
	MOVE.L	D1,D3
	SWAP	D3
	MULU.w	D0,D3
	SWAP	D3
	CLR.W	D3
	ADD.L	D3,D2
	SWAP	D0
	MULU.w	D1,D0
	SWAP	D0
	CLR.W	D0
	ADD.L	D2,D0
	MOVEM.L	(SP)+,D2/D3
	RTS

; ----------------------------------------------

MonlbC0071B2	MOVE.L	D4,-(SP)
	CLR.L	D4
	TST.L	D0
	BPL.b	MonlbC0071BE
	NEG.L	D0
	ADDQ.W	#1,D4
MonlbC0071BE	TST.L	D1
	BPL.b	MonlbC0071C8
	NEG.L	D1
	EORi.W	#1,D4
MonlbC0071C8	BSR.b	MonlbC0071F6
MonlbC0071CA	TST.W	D4
	BEQ.b	MonlbC0071D0
	NEG.L	D0
MonlbC0071D0	MOVE.L	(SP)+,D4
	RTS

MonlbC0071D4	MOVE.L	D4,-(SP)
	CLR.L	D4
	TST.L	D0
	BPL.b	MonlbC0071E0
	NEG.L	D0
	ADDQ.W	#1,D4
MonlbC0071E0	TST.L	D1
	BPL.b	MonlbC0071EA
	NEG.L	D1
	EORi.W	#1,D4
MonlbC0071EA	BSR.b	MonlbC0071F6
	MOVE.L	D1,D0
	BRA.b	MonlbC0071CA

; ----------------------------------------------

MonlbC0071F6	MOVEM.L	D2/D3,-(SP)
	SWAP	D1
	TST.W	D1
	BNE.b	MonlbC007228
	SWAP	D1
	CLR.W	D3
	DIVU.w	D1,D0
	BVC.b	MonlbC007216
	MOVE.W	D0,D2
	CLR.W	D0
	SWAP	D0
	DIVU.w	D1,D0
	MOVE.W	D0,D3
	MOVE.W	D2,D0
	DIVU.w	D1,D0
MonlbC007216	MOVE.L	D0,D1
	SWAP	D0
	MOVE.W	D3,D0
	SWAP	D0
	CLR.W	D1
	SWAP	D1
	MOVEM.L	(SP)+,D2/D3
	RTS

MonlbC007228	SWAP	D1
	CLR.L	D2
	MOVEQ	#$1F,D3
MonlbC00722E	ASL.L	#1,D0
	ROXL.L	#1,D2
	SUB.L	D1,D2
	BMI.b	MonlbC007246
MonlbC007236	ADDQ.L	#1,D0
	DBRA	D3,MonlbC00722E

	BRA.b	MonlbC00724C

MonlbC00723E	ASL.L	#1,D0
	ROXL.L	#1,D2
	ADD.L	D1,D2
	BPL.b	MonlbC007236
MonlbC007246	DBRA	D3,MonlbC00723E

	ADD.L	D1,D2
MonlbC00724C	MOVE.L	D2,D1
	MOVEM.L	(SP)+,D2/D3
	RTS

; ----------------------------------------------

;***************************************************************
;**************** End of Mini-assembler subroutines ************
;***************************************************************

MagicTable:
;Table of immediate table indexes for use with routine number $17
 db 52,5	;or
 db 67,8	;add
 db 56,7	;sub
 db 62,6	;and
 db 59,10	;cmp
 db 0,0

;*** Other data (referenced in the global data section) ***

btst.MSG	dc.b	'btst',0
bchg.MSG	dc.b	'bchg',0
bclr.MSG	dc.b	'bclr',0
bset.MSG	dc.b	'bset',0
movep.MSG	dc.b	'movep',0

ori.MSG	dc.b	'gwen',0
andi.MSG	dc.b	'dzenc',0
subi.MSG	dc.b	'cbm',0
addi.MSG	dc.b	'hazy',0
eori.MSG	dc.b	'guess',0
cmpi.MSG	dc.b	'danb',0

moveb.MSG	dc.b	'move.b',0
movel.MSG	dc.b	'move.l',0
movew.MSG	dc.b	'move.w',0
negx.MSG	dc.b	'negx',0
move.MSG	dc.b	'move',0
clr.MSG	dc.b	'clr',0
neg.MSG	dc.b	'neg',0
move.MSG0	dc.b	'move',0
not.MSG	dc.b	'not',0
move.MSG1	dc.b	'move',0
nbcd.MSG	dc.b	'nbcd',0
pea.MSG	dc.b	'pea',0
swap.MSG	dc.b	'swap',0
movem.MSG	dc.b	'movem',0
extw.MSG	dc.b	'ext.w',0
extl.MSG	dc.b	'ext.l',0
tst.MSG	dc.b	'tst',0
tas.MSG	dc.b	'tas',0
movem.MSG0	dc.b	'movem',0
trap.MSG	dc.b	'trap',0
link.MSG	dc.b	'link',0
unlk.MSG	dc.b	'unlk',0
move.MSG2	dc.b	'move',0
move.MSG3	dc.b	'move',0
myreset.msg	dc.b	'reset',0
nop.MSG	dc.b	'nop',0
stop.MSG	dc.b	'stop',0
rte.MSG	dc.b	'rte',0
rts.MSG	dc.b	'rts',0
trapv.MSG	dc.b	'trapv',0
rtr.MSG	dc.b	'rtr',0
jsr.MSG	dc.b	'jsr',0
jmp.MSG	dc.b	'jmp',0
chk.MSG	dc.b	'chk',0
lea.MSG	dc.b	'lea',0
addq.MSG	dc.b	'addq',0
subq.MSG	dc.b	'subq',0
s.MSG0	dc.b	's',0
db.MSG	dc.b	'db',0
b.MSG	dc.b	'b',0
moveq.MSG	dc.b	'moveq',0
or.MSG	dc.b	'or',0
divu.MSG	dc.b	'divu',0
divs.MSG	dc.b	'divs',0
sbcd.MSG	dc.b	'sbcd',0
sub.MSG	dc.b	'sub',0
subx.MSG	dc.b	'subx',0
linea.MSG	dc.b	'linea',0
cmp.MSG	dc.b	'cmp',0
cmpm.MSG	dc.b	'cmpm',0
eor.MSG	dc.b	'eor',0
and.MSG	dc.b	'and',0
mulu.MSG	dc.b	'mulu',0
muls.MSG	dc.b	'muls',0
abcd.MSG	dc.b	'abcd',0
exg.MSG	dc.b	'exg',0
add.MSG	dc.b	'add',0
addx.MSG	dc.b	'addx',0
as.MSG	dc.b	'as',0
ls.MSG	dc.b	'ls',0
rox.MSG	dc.b	'rox',0
ro.MSG	dc.b	'ro',0
linef.MSG	dc.b	'linef',0
myillegal.msg:	dc.b	'illegal',0
xyzzy.msg:	dc.b	'xyzzy',0
	even

IllegalInstru.MSG	dc.b	'Illegal Instruction',0
IllegalOperan.MSG	dc.b	'Illegal Operands',0
myascii.msg	dc.b	'???',0
MissingOperan.MSG	dc.b	'Missing Operands',0
	even

;****************** Global data/variable section ****************

DT	EQU	*+$7FFE

bwl.MSG	dc.b	'bwl?',0
tfhilscccsnee.MSG	dc.b	't rahilscccsneeqvcvsplmigeltgtle',0
rasrhilscccsn.MSG	dc.b	'rasrhilscccsneeqvcvsplmigeltgtle',0
	even

Reloc007E60	dc.l	btst.MSG	;0
MonlbW007E64	dc.w	0
MonlbW007E66	dc.w	$F3F
MonlbW007E68	dc.w	0
MonlbW007E6A	dc.w	$1FD
MonlbW007E6C	dc.w	4

Reloc007E6E	dc.l	bchg.MSG	;1
	dc.w	$40
	dc.w	$F3F
	dc.w	0	;jump table offset!
	dc.w	$1FD
	dc.w	4
Reloc007E7C	dc.l	bclr.MSG	;2
	dc.w	$80
	dc.w	$F3F
	dc.w	0
	dc.w	$1FD
	dc.w	4
Reloc007E8A	dc.l	bset.MSG	;3
	dc.w	$C0
	dc.w	$F3F
	dc.w	0
	dc.w	$1FD
	dc.w	4
Reloc007E98	dc.l	movep.MSG	;4
	dc.w	8
	dc.w	$FC7
	dc.w	1
	dc.w	0
	dc.w	4
Reloc007EA6	dc.l	ori.MSG	;5
	dc.w	0
	dc.w	$FF
	dc.w	2
	dc.w	$C1FD
	dc.w	4
Reloc007EB4	dc.l	andi.MSG	;6
	dc.w	$200
	dc.w	$FF
	dc.w	2
	dc.w	$C1FD
	dc.w	4
Reloc007EC2	dc.l	subi.MSG	;7
	dc.w	$400
	dc.w	$FF
	dc.w	2
	dc.w	$1FD
	dc.w	4
Reloc007ED0	dc.l	addi.MSG	;8
	dc.w	$600
	dc.w	$FF
	dc.w	2
	dc.w	$1FD
	dc.w	4
Reloc007EDE	dc.l	eori.MSG	;9
	dc.w	$A00
	dc.w	$FF
	dc.w	2
	dc.w	$C1FD
	dc.w	4
Reloc007EEC	dc.l	cmpi.MSG	;10
	dc.w	$C00
	dc.w	$FF
	dc.w	2
	dc.w	$1FD
	dc.w	4
Reloc007EFA	dc.l	moveb.MSG	;11
	dc.w	$1000
	dc.w	$FFF
	dc.w	3
	dc.w	$1FD
	dc.w	0
Reloc007F08	dc.l	movel.MSG	;12
	dc.w	$2000
	dc.w	$FFF
	dc.w	3
	dc.w	$1FF
	dc.w	2
Reloc007F16	dc.l	movew.MSG	;13
	dc.w	$3000
	dc.w	$FFF
	dc.w	3
	dc.w	$1FF
	dc.w	1
Reloc007F24	dc.l	negx.MSG	;14
	dc.w	$4000
	dc.w	$FF
	dc.w	2
	dc.w	$1FD
	dc.w	4
Reloc007F32	dc.l	move.MSG	;15
	dc.w	$40C0
	dc.w	$3F
	dc.w	4
	dc.w	$1FD
	dc.w	1
Reloc007F40	dc.l	clr.MSG	;16
	dc.w	$4200
	dc.w	$FF
	dc.w	2
	dc.w	$1FD
	dc.w	4
Reloc007F4E	dc.l	neg.MSG	;17
	dc.w	$4400
	dc.w	$FF
	dc.w	2
	dc.w	$1FD
	dc.w	4
Reloc007F5C	dc.l	move.MSG0	;18
	dc.w	$44C0
	dc.w	$3F
	dc.w	5
	dc.w	$FFD
	dc.w	0
Reloc007F6A	dc.l	not.MSG	;19
	dc.w	$4600
	dc.w	$FF
	dc.w	2
	dc.w	$1FD
	dc.w	4
Reloc007F78	dc.l	move.MSG1	;20
	dc.w	$46C0
	dc.w	$3F
	dc.w	6
	dc.w	$FFD
	dc.w	1
Reloc007F86	dc.l	nbcd.MSG	;21
	dc.w	$4800
	dc.w	$3F
	dc.w	7
	dc.w	$1FD
	dc.w	0
Reloc007F94	dc.l	pea.MSG	;22
	dc.w	$4840
	dc.w	$3F
	dc.w	7
	dc.w	$7E4
	dc.w	2
Reloc007FA2	dc.l	swap.MSG	;23
	dc.w	$4840
	dc.w	7
	dc.w	8
	dc.w	0
	dc.w	1
Reloc007FB0	dc.l	movem.MSG	;24
	dc.w	$4880
	dc.w	$7F
	dc.w	9
	dc.w	$1F4
	dc.w	4
;	dc.w	2
Reloc007FBE	dc.l	extw.MSG	;25
	dc.w	$4880
	dc.w	7
	dc.w	8
	dc.w	0
	dc.w	1
Reloc007FCC	dc.l	extl.MSG	;26
	dc.w	$48C0
	dc.w	7
	dc.w	8
	dc.w	0
	dc.w	2
Reloc007FDA	dc.l	tst.MSG	;27
	dc.w	$4A00
	dc.w	$FF
	dc.w	2
	dc.w	$1FD
	dc.w	4
Reloc007FE8	dc.l	tas.MSG	;28
	dc.w	$4AC0
	dc.w	$3F
	dc.w	7
	dc.w	$1FD
	dc.w	0
Reloc007FF6	dc.l	movem.MSG0	;29
	dc.w	$4C80
	dc.w	$7F
	dc.w	10
	dc.w	$7EC
	dc.w	4
Reloc008004	dc.l	trap.MSG	;30
	dc.w	$4E40
	dc.w	15
	dc.w	11
	dc.w	0
	dc.w	4
Reloc008012	dc.l	link.MSG	;31
	dc.w	$4E50
	dc.w	7
	dc.w	12
	dc.w	0
	dc.w	4
Reloc008020	dc.l	unlk.MSG	;32
	dc.w	$4E58
	dc.w	7
	dc.w	12
	dc.w	0
	dc.w	4
Reloc00802E	dc.l	move.MSG2	;33
	dc.w	$4E60
	dc.w	7
	dc.w	13
	dc.w	0
	dc.w	2
Reloc00803C	dc.l	move.MSG3	;34
	dc.w	$4E68
	dc.w	7
	dc.w	14
	dc.w	0
	dc.w	2

Reloc00804A	dc.l	myreset.msg	;35
	dc.w	$4E70
	dc.w	0
	dc.w	15
	dc.w	0
	dc.w	4

Reloc008058	dc.l	nop.MSG	;36
	dc.w	$4E71
	dc.w	0
	dc.w	15
	dc.w	0
	dc.w	4

Reloc008066	dc.l	stop.MSG	;37
	dc.w	$4E72
	dc.w	0
	dc.w	15
	dc.w	0
	dc.w	4
Reloc008074	dc.l	rte.MSG	;38
	dc.w	$4E73
	dc.w	0
	dc.w	15
	dc.w	0
	dc.w	4
Reloc008082	dc.l	rts.MSG	;39
	dc.w	$4E75
	dc.w	0
	dc.w	15
	dc.w	0
	dc.w	4
Reloc008090	dc.l	trapv.MSG	;40
	dc.w	$4E76
	dc.w	0
	dc.w	15
	dc.w	0
	dc.w	4
Reloc00809E	dc.l	rtr.MSG	;41
	dc.w	$4E77
	dc.w	0
	dc.w	15
	dc.w	0
	dc.w	4
Reloc0080AC	dc.l	jsr.MSG	;42
	dc.w	$4E80
	dc.w	$3F
	dc.w	7
	dc.w	$7E4
	dc.w	4
Reloc0080BA	dc.l	jmp.MSG	;43
	dc.w	$4EC0
	dc.w	$3F
	dc.w	7
	dc.w	$7E4
	dc.w	4
Reloc0080C8	dc.l	chk.MSG	;44
	dc.w	$4180
	dc.w	$E3F
	dc.w	$10
	dc.w	$FFD
	dc.w	1
Reloc0080D6	dc.l	lea.MSG	;45
	dc.w	$41C0
	dc.w	$E3F
	dc.w	$11
	dc.w	$7E4
	dc.w	2
Reloc0080E4	dc.l	addq.MSG	;46
	dc.w	$5000
	dc.w	$EFF
	dc.w	$12
	dc.w	$1FF
	dc.w	4
Reloc0080F2	dc.l	subq.MSG	;47
	dc.w	$5100
	dc.w	$EFF
	dc.w	$12
	dc.w	$1FF
	dc.w	4
Reloc008100	dc.l	s.MSG0	;48
	dc.w	$50C0
	dc.w	$F3F
	dc.w	$13
	dc.w	$1FD
	dc.w	0
Reloc00810E	dc.l	db.MSG	;49
	dc.w	$50C8
	dc.w	$F07
	dc.w	$14
	dc.w	0
	dc.w	1
Reloc00811C	dc.l	b.MSG	;50
	dc.w	$6000
	dc.w	$FFF
	dc.w	$15
	dc.w	0
	dc.w	4
Reloc00812A	dc.l	moveq.MSG	;51
	dc.w	$7000
	dc.w	$EFF
	dc.w	$16
	dc.w	0
	dc.w	2
Reloc008138	dc.l	or.MSG	;52
	dc.w	$8000
	dc.w	$FFF
	dc.w	$17
	dc.w	$FFD
	dc.w	4
Reloc008146	dc.l	divu.MSG	;53
	dc.w	$80C0
	dc.w	$E3F
	dc.w	$10
	dc.w	$FFD
	dc.w	1
Reloc008154	dc.l	divs.MSG	;54
	dc.w	$81C0
	dc.w	$E3F
	dc.w	$10
	dc.w	$FFD
	dc.w	1
Reloc008162	dc.l	sbcd.MSG	;55
	dc.w	$8100
	dc.w	$E0F
	dc.w	$18
	dc.w	0
	dc.w	0
Reloc008170	dc.l	sub.MSG	;56
	dc.w	$9000
	dc.w	$FFF
	dc.w	$17
	dc.w	$FFF
	dc.w	4
Reloc00817E	dc.l	subx.MSG	;57
	dc.w	$9100
	dc.w	$ECF
	dc.w	$19
	dc.w	0
	dc.w	4
Reloc00818C	dc.l	linea.MSG	;58
	dc.w	$A000
	dc.w	$FFF
	dc.w	$1D
	dc.w	0
	dc.w	4
Reloc00819A	dc.l	cmp.MSG	;59
	dc.w	$B000
	dc.w	$FFF
	dc.w	$17
	dc.w	$FFF
	dc.w	4
Reloc0081A8	dc.l	cmpm.MSG	;60
	dc.w	$B108
	dc.w	$EC7
	dc.w	$19
	dc.w	0
	dc.w	4
Reloc0081B6	dc.l	eor.MSG	;61
	dc.w	$B100
	dc.w	$EFF
	dc.w	$1A
	dc.w	$1FD
	dc.w	4
Reloc0081C4	dc.l	and.MSG	;62
	dc.w	$C000
	dc.w	$FFF
	dc.w	$17
	dc.w	$FFD
	dc.w	4
Reloc0081D2	dc.l	mulu.MSG	;63
	dc.w	$C0C0
	dc.w	$E3F
	dc.w	$10
	dc.w	$FFD
	dc.w	1
Reloc0081E0	dc.l	muls.MSG	;64
	dc.w	$C1C0
	dc.w	$E3F
	dc.w	$10
	dc.w	$FFD
	dc.w	1
Reloc0081EE	dc.l	abcd.MSG	;65
	dc.w	$C100
	dc.w	$E0F
	dc.w	$18
	dc.w	0
	dc.w	0
Reloc0081FC	dc.l	exg.MSG	;66
	dc.w	$C100
	dc.w	$EFF
	dc.w	$1B
	dc.w	0
	dc.w	2
Reloc00820A	dc.l	add.MSG	;67
	dc.w	$D000
	dc.w	$FFF
	dc.w	$17
	dc.w	$FFF
	dc.w	4
Reloc008218	dc.l	addx.MSG	;68
	dc.w	$D100
	dc.w	$ECF
	dc.w	$19
	dc.w	0
	dc.w	4
Reloc008226	dc.l	as.MSG	;69
	dc.w	$E000
	dc.w	$FFF
	dc.w	$1C
	dc.w	0
	dc.w	4
Reloc008234	dc.l	ls.MSG	;70
	dc.w	$E000
	dc.w	$FFF
	dc.w	$1C
	dc.w	0
	dc.w	4
Reloc008242	dc.l	rox.MSG	;71
	dc.w	$E000
	dc.w	$FFF
	dc.w	$1C
	dc.w	0
	dc.w	4
Reloc008250	dc.l	ro.MSG	;72
	dc.w	$E000
	dc.w	$FFF
	dc.w	$1C
	dc.w	0
	dc.w	4
Reloc00825E	dc.l	linef.MSG	;73
	dc.w	$F000
	dc.w	$FFF
	dc.w	$1D
	dc.w	0
	dc.w	4

;************************************
myreloc1	dc.l	myillegal.msg	;74
	dc.w	$4AFC
	dc.w	0
	dc.w	15
	dc.w	0
	dc.w	4

myreloc2	dc.l	xyzzy.msg	;75
	dc.w	$50C8
	dc.w	0
	dc.w	15
	dc.w	0
	dc.w	4

MonlbW00826C	dc.w	10
	dc.w	11
	dc.w	12
	dc.w	13
	dc.w	$2D
	dc.w	$31
	dc.w	$32
	dc.w	$33
	dc.w	$37
	dc.w	$39
	dc.w	$3A
	dc.w	$3D
	dc.w	$42
	dc.w	$44
	dc.w	$48
	dc.w	$49

;	dcb.l	30,0

 comment |
Reloc00828C	dc.l	MonlbC0005F0
Reloc008290	dc.l	MonlbC0006CA
Reloc008294	dc.l	MonlbC0007A6
Reloc008298	dc.l	MonlbC0008BC
Reloc00829C	dc.l	MonlbC000942
Reloc0082A0	dc.l	MonlbC000990
Reloc0082A4	dc.l	MonlbC0009F4
Reloc0082A8	dc.l	MonlbC000A4C
Reloc0082AC	dc.l	MonlbC000A8E
Reloc0082B0	dc.l	MonlbC000D0E
Reloc0082B4	dc.l	MonlbC000D0E
Reloc0082B8	dc.l	MonlbC000DD8
Reloc0082BC	dc.l	MonlbC000E08
Reloc0082C0	dc.l	MonlbC000E6E
Reloc0082C4	dc.l	MonlbC000ECE
Reloc0082C8	dc.l	MonlbC000F2E
Reloc0082CC	dc.l	MonlbC000F62
Reloc0082D0	dc.l	MonlbC000FE0
Reloc0082D4	dc.l	MonlbC00105E
Reloc0082D8	dc.l	MonlbC001110
Reloc0082DC	dc.l	MonlbC001186
Reloc0082E0	dc.l	MonlbC001226
Reloc0082E4	dc.l	MonlbC0012CE
Reloc0082E8	dc.l	MonlbC001314
Reloc0082EC	dc.l	MonlbC0014B0
Reloc0082F0	dc.l	MonlbC001574
Reloc0082F4	dc.l	MonlbC0015BC
Reloc0082F8	dc.l	MonlbC0016B4
Reloc0082FC	dc.l	MonlbC00170E
Reloc008300	dc.l	MonlbC0018AE
|

;************ Start of mini-assembler jump table ****************

Reloc008304	dc.l	MonlbC00263C
Reloc008308	dc.l	MonlbC00276C
Reloc00830C	dc.l	MonlbC00295C	;immediate handler
Reloc008310	dc.l	MonlbC002AB2
Reloc008314	dc.l	MonlbC002B6A
Reloc008318	dc.l	MonlbC002BF8
Reloc00831C	dc.l	MonlbC002C9C
Reloc008320	dc.l	MonlbC002D2A
Reloc008324	dc.l	MonlbC002D8E
Reloc008328	dc.l	MonlbC002F46	;movem
Reloc00832C	dc.l	MonlbC002F46
Reloc008330	dc.l	MonlbC00307C
Reloc008334	dc.l	MonlbC0030CC
Reloc008338	dc.l	MonlbC00316E
Reloc00833C	dc.l	MonlbC003222
Reloc008340	dc.l	MonlbC0032D6
Reloc008344	dc.l	MonlbC003318
Reloc008348	dc.l	MonlbC0033D2	;lea
Reloc00834C	dc.l	MonlbC00348C
Reloc008350	dc.l	MonlbC00353E
Reloc008354	dc.l	MonlbC0035AA	;dbcc
Reloc008358	dc.l	MonlbC003632	;bcc
Reloc00835C	dc.l	MonlbC0036BE	;moveq
Reloc008360	dc.l	MonlbC00375E	;add
Reloc008364	dc.l	MonlbC0039C6
Reloc008368	dc.l	MonlbC003C34
Reloc00836C	dc.l	MonlbC003C7A	;eor
Reloc008370	dc.l	MonlbC003D3C
Reloc008374	dc.l	MonlbC003F0A
	dc.l	0
Reloc00837C	dc.l	IllegalInstru.MSG
Reloc008380	dc.l	IllegalOperan.MSG
Reloc008384	dc.l	myascii.msg
Reloc008388	dc.l	MissingOperan.MSG
abcdef.MSG	dc.b	'0123456789abcdef',0,0
MonlbL00839E	dc.l	0
MonlbW0083A2	dc.w	0
	dc.w	0
ABCDEFabcdef9.MSG	dc.b	'ABCDEFabcdef9876543210',0
MonlbB0083BD	dc.b	10
	dc.b	11
	dc.b	12
	dc.b	13
	dc.b	14
	dc.b	15
	dc.b	10
	dc.b	11
	dc.b	12
	dc.b	13
	dc.b	14
	dc.b	15
	dc.b	9
	dc.b	8
	dc.b	7
	dc.b	6
	dc.b	5
	dc.b	4
	dc.b	3
	dc.b	2
	dc.b	1
	dc.b	0
	dc.b	0
r.MSG	dc.b	'r',0,0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	'r+',0,0
	dc.b	0
	dc.b	2
	dc.b	'w',0,0
	dc.b	0
	dc.b	3
	dc.b	1
	dc.b	'w+',0,0
	dc.b	3
	dc.b	2
	dc.b	'a',0,0
	dc.b	0
	dc.b	9
	dc.b	1
	dc.b	'a+',0,0
	dc.b	9
	dc.b	2
	dc.b	'x',0,0
	dc.b	0
	dc.b	5
	dc.b	1
	dc.b	'x+',0,0
	dc.b	5
	dc.b	2
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
abcdef.MSG0	dc.b	'0123456789abcdef',0,0
MonlbL00841C	dc.l	0
	dc.l	0
	dc.l	0
MonlbB008428	dc.b	1
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	1
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
MonlbL008432	dc.l	0
	dc.l	0
	dc.l	0
	dc.b	1
MonlbB00843F	dc.b	1
	dc.b	0
	dc.b	0
MonlbW008442	dc.w	1
	dc.w	0
	dc.w	0
MonlbL008448	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	$1020000
	dc.l	$10000
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
MonlbL0085D4	dc.l	0
MonlbL0085D8	dc.l	0
MonlbW0085DC	dc.w	$20
	dc.w	$2020
	dc.w	$2020
	dc.w	$2020
	dc.w	$2020
	dc.w	$3030
	dc.w	$3030
	dc.w	$3020
	dc.w	$2020
	dc.w	$2020
	dc.w	$2020
	dc.w	$2020
	dc.w	$2020
	dc.w	$2020
	dc.w	$2020
	dc.w	$2020
	dc.w	$2090
	dc.w	$4040
	dc.w	$4040
	dc.w	$4040
	dc.w	$4040
	dc.w	$4040
	dc.w	$4040
	dc.w	$4040
	dc.w	$400C
	dc.w	$C0C
	dc.w	$C0C
	dc.w	$C0C
	dc.w	$C0C
	dc.w	$C40
	dc.w	$4040
	dc.w	$4040
	dc.w	$4040
	dc.w	$909
	dc.w	$909
	dc.w	$909
	dc.w	$101
	dc.w	$101
	dc.w	$101
	dc.w	$101
	dc.w	$101
	dc.w	$101
	dc.w	$101
	dc.w	$101
	dc.w	$101
	dc.w	$101
	dc.w	$4040
	dc.w	$4040
	dc.w	$4040
	dc.w	$A0A
	dc.w	$A0A
	dc.w	$A0A
	dc.w	$202
	dc.w	$202
	dc.w	$202
	dc.w	$202
	dc.w	$202
	dc.w	$202
	dc.w	$202
	dc.w	$202
	dc.w	$202
	dc.w	$202
	dc.w	$4040
	dc.w	$4040
	dc.w	$2000
	dc.w	0


;**** Uninitialized variable space ****

MonlbL008660	ds.l	5
MonlbL008674	ds.l	12
	ds.b	2
CurrentCharPtr	ds.l	1
CurrentPC	ds.l	1
MonlbW0086AE	ds.w	1
MonlbL0086B0	ds.l	1
OpcodeTableIndex	ds.w	1
MonlbL0086B6	ds.l	1
MonlbL0086BA	ds.l	1
MonlbB0086BE	ds.b	2
MonlbW0086C0	ds.w	1
MonlbW0086C2	ds.w	1
MonlbL0086C4	ds.l	1
MonlbL0086C8	ds.l	1
MonlbL0086CC	ds.l	1
MonlbL0086D0	ds.l	1
MonlbL0086D4	ds.l	10
MonlbL0086FC	ds.l	1
MonlbW008700	ds.w	1
MonlbW008702	ds.w	1
MonlbL008704	ds.l	1
MonlbL008708	ds.l	1
MonlbL00870C	ds.l	1
MonlbL008710	ds.l	1
MonlbB008714	ds.b	1
MonlbB008715	ds.b	1
MonlbL008716	ds.l	13
	ds.b	2
MonlbB00874C	ds.b	8
MonlbB008754	ds.b	$10
MonlbB008764	ds.b	2
MonlbL008766	ds.l	1
MonlbL00876A	ds.l	1
MonlbL00876E	ds.l	1
MonlbL008772	ds.l	1
MonlbL008776	ds.l	1
MonlbL00877A	ds.l	1
MonlbL00877E	ds.l	1
MonlbL008782	ds.l	1
MonlbL008786	ds.l	1
MonlbL00878A	ds.l	1
MonlbL00878E	ds.l	1
MonlbL008792	ds.l	1
MonlbL008796	ds.l	1
MonlbL00879A	ds.l	1
MonlbL00879E	ds.l	1
MonlbL0087A2	ds.l	1
MonlbL0087A6	ds.l	1
MonlbL0087AA	ds.l	1
MonlbL0087AE	ds.l	1
MonlbL0087B2	ds.w	1
MonlbW0087B4	ds.w	1
MonlbW0087B6	ds.w	1
MonlbL0087B8	ds.l	1
MonlbL0087BC	ds.l	1
	ds.b	2
MonlbW0087C2	ds.w	1
MonlbW0087C4	ds.w	1
MonlbW0087C6	ds.w	1
MonlbL0087C8	ds.l	1
MonlbB0087CC	ds.b	2
MonlbL0087CE	ds.l	1
MonlbW0087D2	ds.w	1
MonlbL0087D4	ds.l	1
_ExecBase	ds.l	1
_InputHandle	ds.l	1
MonlbW0087E0	ds.w	1
_OutputHandle1	ds.l	1
MonlbW0087E6	ds.w	1
_OutputHandle2	ds.l	1
MonlbW0087EC	ds.w	$34
MonlbW008854	ds.w	1
_DOSBase	ds.l	1
MonlbL00885A	ds.l	1
MonlbL00885E	ds.l	1
	ds.b	2
	even
