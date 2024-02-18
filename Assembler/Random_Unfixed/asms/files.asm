* Program Written By: Franco Gaetan
* Date: January 1, 1992
* Description:
* This program opens a file and reads in data.
*

open 		equ	-30
close		equ	-36
Mode_old	equ	1005
Mode_new	equ	1006
read		equ	-42



		move.l	#Mode_old,d2
		bsr	openfile
		beq	error
		move.l	#field,d2
		bsr	readdata
		move.l	d0,d6
		bsr	closefile
		rts
	

readdata:
		move.l	dosbase,a6
		move.l	filehd,d1
		move.l	#$ff,d3
		jsr	read(a6)
		rts


openfile:
		move.l	dosbase,a6
		move.l	#filename,d1
		jsr	open(a6)
		move.l	d0,filehd
		rts


error:
closefile:	
		move.l	dosbase,a6
		move.l	filehd,d1
		jsr	close(a6)
		rts

field:		ds.l	2000
dosbase:	dc.l	0
filehd:		dc.l	0
filename:	dc.b	'testfile',0
		cnop	0,2


