
	include	':sourcec/include/franco.i'

	OpenDos
	IFERR	error

	move.l	#$76abde39,d0

;	PrintHexNum
;	PrintCRLF

	AddPort		SGFGPort

;	SendMsg		OurMsg

	GetMsg		portname,msgget

	GetMsg		portname,msgget

	move.l	d0,a1
	move.w	18(a1),d3	;length of message
	move.l	20(a1),d0
	PrintHexNum

	RemovePort	portname

	CloseDos
error:
	clr.l	d0
	rts


msgget:	dc.l	0,0

	Setup_Dos_Data
	Setup_Msg



portname:	dc.b	'SGFGPort',0
		cnop	0,2

SGFGPort:	dc.l	0
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

OurMsg:		dc.l	0
		dc.l	0
		dc.b	5		;message
		dc.b	0		;priority
		dc.l	lames

		dc.l	0

		dc.w	100		;length of message

		dc.b	'Cows fly North for winter',0
		cnop	0,2


	end

