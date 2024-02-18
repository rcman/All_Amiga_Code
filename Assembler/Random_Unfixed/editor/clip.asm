
; Find Next line forwards -----------------------

findlinef:
	move.l	lineptre,a1		;get end line ptr
       	moveq	#0,d1
       	moveq	#lfcramt,d2
finderokf:
	cmp.b	#0,(a1)
	beq.s	jumpoutfindf

	cmp.b	#10,(a1)
	bne.s	contforwf
	subq.l	#1,d2
	cmp.b	#10,1(a1)
	bne.s	contforwf

	addq.l	#1,a1
	move.l	a1,lineptrs
	bra.s	jumpoutfindf

contforwf:
	add.l	d2,a1
	move.l	a1,lineptrs		;save to start line ptr
	cmp.b	#10,(a1)
	beq.s	jumpoutfindf

finderokf2:
	cmp.b	#0,(a1)
	beq.s	lookahead2
	cmp.b	#10,(a1)
	beq.s	lookahead2
	cmp.b	#13,(a1)
	beq.s	lookahead2
	addq.l	#1,d1
	addq.l	#1,a1
	bra.s	finderokf2
lookahead2:
	subq.l	#1,a1

	cmp.l	#0,d1
	beq.s	jumpoutfindf
	subq.l	#1,d1

jumpoutfindf:	
	move.l	a1,lineptre
	move.l	d1,lengthofline
	rts


; Find Next line backwards -----------------------

findlineb:
	move.l	lineptrs,a1		; get start line ptr
	move.l	Memarea,a2
	moveq	#0,d1
finderokb:
	cmp.b	#0,(a1)
	beq.s	jumpoutfindb

	cmp.b	#10,-2(a1)
	bne.s	contbackw
	cmp.b	#0,-2(a1)
	bne.s	contbackw
	subq.l	#1,a1
	move.l	a1,lineptre
	bra.s	jumpoutfindb

contbackw:
	subq.l	#lfcramt,a1
	cmp.l	a2,a1
	ble.s	jumpoutfindb

	move.l	a1,lineptre

finderokb2:
	cmp.b	#0,(a1)
	beq.s	lookback2
	cmp.b	#10,(a1)
	beq.s	lookback2
	cmp.b	#13,(a1)
	beq.s	lookback2
	addq.l	#1,d1
	subq.l	#1,a1
	bra.s	finderokb2
lookback2:
	addq.l	#1,a1

	cmp.l	#0,d1
	beq.s	jumpoutfindb
	subq.l	#1,d1

jumpoutfindb:	
	move.l	a1,lineptrs
	move.l	d1,lengthofline
	rts

