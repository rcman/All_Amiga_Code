
	include "include/myintuition.i"
	include "include/mydos.i"

start:
	OpenDos
	iferr	Errordos
	OpenIntuition
	iferr	Errorint
	OpenScreen
	iferr	Errorscn
	OpenWindow
	iferr	Errorwin

;	Open	filename,new
;	iferr	Erroropening

;	lea	start(pc),a1		;buffer pointer
;	move.l	#endpgmer-start,d0	;length
;	Write	a1,d0

;	Close

Erroropening:

; port 0-mouse or 1-joy
	WaitForButton

Endpgm:
	CloseWindow
Errorwin:
	CloseScreen
Errorscn:
	CloseIntuition
Errorint:
	CloseDos
Errordos:
	rts

; Data Area ------------------------------------

filename	dc.b	'SeanGodsell',0
		cnop	0,2

	WindowNOB	0,320,200,Y
	Screen		'Screen',320,200,4

	SetupIntuitionData
	SetupDosData

