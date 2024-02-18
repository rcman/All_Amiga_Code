
AddPort		equ	-354
;AllocMem	equ	-198
AllocSignal	equ	-330
FreeSignal	equ	-336
PutMsg		equ	-366
GetMsg		equ	-372
WaitPort	equ	-384
FindTask	equ	-294
sysbase		equ	4
FindPort	equ	-390

;	moveq	#-1,d0
;	move.l	sysbase,a6
;	jsr	AllocSignal(a6)
;	cmp.b	#$ff,d0
;	beq	endpgm

;	move.b	d0,signal

;	move.l	#0,a1
;	move.l	sysbase,a6
;	jsr	FindTask(a6)
;	move.l	d0,thistask

	lea	MyPort(pc),a1
;	move.l	a1,$68000

;	move.l	sysbase,a6
;	jsr	AddPort(a6)

	lea	portname(pc),a1
	move.l	sysbase,a6
	jsr	FindPort(a6)

	move.l	d0,a0
	beq.s	endpgm

	move.l	#'OKAY',$68010
;	lea	Mes(pc),a1
	move.l	sysbase,a6
	jsr	GetMsg(a6)

	move.l	d0,$68100		;pointer to the Message

	move.l	d1,$68104
	move.l	a0,$68108
	move.l	a1,$6810c
	

endpgm:
	rts
	
;signal:		dc.l	0

portname:	dc.b	'SeanPort',0
		cnop	0,2

MyPort:		dc.l	0
		dc.l	0
		dc.b	4		;mesgport
		dc.b	0		;priority
		dc.l	portname

flags:		dc.b	0		;mpflags
signal:		dc.b	0		;mpsigbit
thistask:	dc.l	0		;Pointer to this task

		dc.l	0		;lh_head
		dc.l	0		;lh_tail
		dc.l	0		;lh_tailpred
		dc.b	0		;type
		dc.b	0		;pad


		dc.l	0,0,0,0,0

lames:
		dc.b	'Hello Message',0
		cnop	0,2

Mes:		dc.l	0
		dc.l	0
		dc.b	5		;message
		dc.b	0		;priority
		dc.l	lames

		dc.l	0

		dc.w	100		;length of message

		dc.b	'Cows fly North for winter',0
		cnop	0,2


