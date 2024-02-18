	SECTION section

	NOLIST
	include	"exec/types.i"
	include "exec/nodes.i"
	include	"exec/lists.i"
	include	"exec/libraries.i"
	include "exec/devices.i"
	include	"exec/io.i"
	include	"exec/alerts.i"
	include "exec/initializers.i"
	include	"exec/memory.i"
	include	"exec/resident.i"
	include "exec/ables.i"
	include	"exec/errors.i"
	include	"libraries/dos.i"
	include "libraries/dosextens.i"

	include	"asmsupp.i"

	include	"mydev.i"

	LIST

	XDEF	Init
	XDEF	Open
	XDEF	Close
	XDEF	Expunge
	XDEF	Null
	XDEF	myName
	XDEF	BeginIO
	XDEF	AbortIO
;	XDEF	_AbsExecBase
_AbsExecBase	EQU	$4

	XLIB	OpenLibrary
	XLIB	CloseLibrary
	XLIB	Alert
	XLIB	FreeMem
	XLIB	Remove
	XLIB	FindTask
	XLIB	AllocMem
	XLIB	CreatProc
	XLIB	PutMsg
	XLIB	RemTask
	XLIB	ReplyMsg
	XLIB	Signal
	XLIB	GetMsg
	XLIB	Wait
	XLIB	WaitPort
	XLIB	AllocSignal
	XLIB	SetTaskPri

_LVOCreateProc	EQU	-138

	INT_ABLES

FirstAddress:
	moveq	#0,d0
	rts


;	move.l	#mp_Sigbit,d0
;	move.l	#MP_SIGBIT,d0
;	move.l	#mp_Flags,d0
;	move.l	#MP_FLAGS,d0
;	move.l	#UNIT_FLAGS,d0

;	move.l	#IO_DEVICE,$380000
;	move.l	#IO_UNIT,$380004
;	move.l	#IO_COMMAND,$380008
;	move.l	#IO_FLAGS,$38000c
;	move.l	#IO_ERROR,$380010
;	move.l	#IO_ACTUAL,$380014
;	move.l	#IO_LENGTH,$380018
;	move.l	#IO_DATA,$38001C
;	move.l	#IO_OFFSET,$380020
	


MYPRI	EQU	0

initDDescrip:
	DC.W	RTC_MATCHWORD
	DC.L	initDDescrip
	DC.L	EndCode
	DC.B	RTF_AUTOINIT
	DC.B	VERSION
	DC.B	NT_DEVICE
	DC.B	MYPRI
	DC.L	myName
	DC.L	idString
	DC.L	Init

subSysName:
myName:		MYDEVNAME

VERSION:	EQU	1

REVISION:	EQU	17

idString	dc.b	'Seans Device for Parallal Communications',13,10,0

dosName:	DOSNAME

	DS.W	0

Init:
	DC.L	MyDev_Sizeof
	DC.L	funcTable
	DC.L	dataTable
	DC.L	initRoutine

funcTable:
	DC.L	Open
	DC.L	Close
	DC.L	Expunge
	DC.L	Null

	DC.L	BeginIO
	DC.L	AbortIO

	DC.L	-1

dataTable:
	INITBYTE	LH_TYPE,NT_DEVICE
	INITLONG	LN_NAME,myName
	INITBYTE	LIB_FLAGS,LIBF_SUMUSED!LIBF_CHANGED
	INITWORD	LIB_VERSION,VERSION
	INITWORD	LIB_REVISION,REVISION
	INITLONG	LIB_IDSTRING,idString
	DC.L	0

initRoutine:
	move.b	#0,30(a1)
	move.l	a5,-(sp)
	move.l	d0,a5
	move.l	a6,md_SysLib(a5)

	move.l	a0,md_SegList(a5)

	lea	dosName(pc),a1
	moveq	#0,d0
	CALLSYS	OpenLibrary
	move.l	d0,md_DosLib(a5)
	bne.s	init_DosOK


;	move.l	#'poky',$80040
	ALERT	AG_OpenLib!AO_DOSLib

init_DosOK:

;	Put Your initialization here ........

	move.l	a5,d0
	move.l	(sp)+,a5
;	move.l	#'Sean',$80000

	rts

Open:
	movem.l	d2/a2-a4,-(sp)
	move.l	a1,a2

;	move.l	#'stg1',$80000

	moveq	#MD_NUMUNITS,d2
	cmp.l	d2,d0
	bcc.s	Open_Error

	move.l	d0,d2
	lsl.l	#2,d0

	lea.l	md_Units(a6,d0.l),a4
	move.l	(a4),d0
	bne.s	Open_UnitOK

;	move.l	#'stg2',$80000

	bsr	InitUnit

;	move.l	#'stg3',$80004

	move.l	(a4),d0
	beq.s	Open_Error

Open_UnitOK:
	move.l	d0,a3
	move.l	d0,IO_UNIT(a2)

	addq.w	#1,LIB_OPENCNT(a6)
	addq.w	#1,UNIT_OPENCNT(a3)

	bclr	#LIBB_DELEXP,md_Flags(a6)
Open_End:
	movem.l	(sp)+,d2/a2-a4
;	move.l	#'Sean',$80000

	rts

Open_Error:
	move.b	#IOERR_OPENFAIL,IO_ERROR(a2)
	bra.s	Open_End


Close:
	movem.l	a2/a3,-(sp)
	move.l	a1,a2
	move.l	IO_UNIT(a2),a3

	moveq.l	#-1,d0
	move.l	d0,IO_UNIT(a2)
	move.l	d0,IO_DEVICE(a2)

	subq.w	#1,UNIT_OPENCNT(a3)
	bne.s	Close_Device

	bsr	ExpungeUnit

Close_Device:
	subq.w	#1,LIB_OPENCNT(a6)
	bne.s	Close_End
	btst	#LIBB_DELEXP,md_Flags(a6)
	beq.s	Close_End

	bsr	Expunge

Close_End:
	movem.l	(sp)+,a2/a3
	rts


Expunge:
	movem.l	d2/a5/a6,-(sp)
	move.l	a6,a5
	move.l	md_SysLib(a5),a6

	tst.w	LIB_OPENCNT(a5)
	beq	1$

	bset	#LIBB_DELEXP,md_Flags(a5)
	moveq	#0,d0
	bra.s	Expunge_End

1$:
	move.l	md_SegList(a5),d2
	move.l	a5,a0
	CALLSYS	Remove

; Device specific closings here .......

	move.l	md_DosLib(a5),a1
	CALLSYS	CloseLibrary

	move.l	a5,a1
	move.l	LIB_NEGSIZE(A5),D0

	sub.l	d0,a1
	add.l	LIB_POSSIZE(a5),d0

	CALLSYS	FreeMem

	move.l	d2,d0
Expunge_End:
	movem.l	(sp)+,d2/a5/a6
	rts

Null:
	moveq	#0,d0
	rts


InitUnit:
	movem.l	d2/d3/d4,-(sp)

	move.b	#$0,30(a1)

	move.l	#MyDevUnit_Sizeof+20,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	LINKSYS	AllocMem,md_SysLib(a6)

	tst.l	d0
	beq	InitUnit_End

	move.l	d0,a3
	move.b	d2,mdu_UnitNum(a3)	;26

;	move.l	d0,a3
;	move.b	d2,mdu_UnitNum(a3)	;26

;	set up the unit process

	move.l	#MYPROCSTACKSIZE,d4
	move.l	#myproc_seglist,d3
	lsr.l	#2,d3
	moveq	#MYPROCPRI,d2
	move.l	#myName,d1
	LINKSYS	CreateProc,md_DosLib(a6)

;	move.l	d0,$80100
;        move.l  a3,$80104
;	move.l	#MP_SIGTASK,$80108
;	move.l	#mdu_UnitNum,$80100
;	move.l	#mdu_pad,$80104
;	move.l	#pr_MsgPort,$80104

;	move.l	#mdu_Msg,$80108
;	move.l	#mdu_Process,$8010c
;	move.l	#mdu_Process,$8010c


	tst.l	d0
	beq	InitUnit_FreeUnit

	move.l	d0,mdu_Process(a3)	;44
	move.l	d0,a0
	lea	-pr_MsgPort(a0),a0	;5C was -pr_


	move.l	a0,MP_SIGTASK(a3)	;10
;	move.b	#PA_IGNORE,MP_FLAGS(a3)
	move.b	#PA_SIGNAL,MP_FLAGS(a3)

;	move.l	#'Chrs',$80000

	lea	mdu_Msg(a3),a1		;28

;	move.l	a1,$80000
;	move.l	#mdu_Msg,$80004
;	move.l	a3,$80008

	move.l	a3,mdm_Unit(a1)
	move.l	a6,mdm_Device(a1)
	move.l	d0,a0

;	move.l	#'hisg',$80010

	LINKSYS	PutMsg,md_SysLib(a6)

	move.l	d2,d0
	lsl.l	#2,d0
	move.l	a3,md_Units(a6,d0.l)

InitUnit_End:

	movem.l	(sp)+,d2/d3/d4
	rts

InitUnit_FreeUnit:
	bsr	FreeUnit
	bra.s	InitUnit_End

FreeUnit:
	move.l	a3,a1
	move.l	#MyDevUnit_Sizeof+20,d0
	LINKSYS	FreeMem,md_SysLib(a6)
	rts

ExpungeUnit:
	move.l	d2,-(sp)

	move.l	mdu_Process(a3),a1
	lea	-(pr_MsgPort)(a1),a1
	LINKSYS	RemTask,md_SysLib(a6)

	moveq	#0,d2
	move.b	mdu_UnitNum(a3),d2

	bsr	FreeUnit

	lsl.l	#2,d2
	clr.l	md_Units(a6,d2.l)

	move.l	(sp)+,d2
	rts


;-------------------------------------------------------
; here begins the device specific functions
;-------------------------------------------------------

cmdtable:
	DC.L	Invalid
	DC.L	MyReset
	DC.L	Read
	DC.L	Write
	DC.L	Update
	DC.L	Clear
	DC.L	MyStop
	DC.L	Start
	DC.L	Flush
	DC.L	Foo
	DC.L	Bar
cmdtable_end:

IMMEDIATES	EQU	$000001C3	;THESE ARE NOT QUEUED

; BeginIO	start all incoming io.  The IO is either queued up
;		for the unit task or processed immediately.

BeginIO:
	move.l	a3,-(sp)

;	move.l	'ioum',$80030


	move.l	IO_UNIT(a1),a3

	move.w	IO_COMMAND(a1),d0
	cmp.w	#MYDEV_END,d0
	bcc	BeginIO_NoCmd

	DISABLE	a0

	move.w	#IMMEDIATES,D1
	btst	d0,d1
	bne.s	BeginIO_Immediate

	btst	#MDUB_STOPPED,UNIT_FLAGS(a3)
	bne.s	BeginIO_QueueMsg

	bset	#UNITB_ACTIVE,UNIT_FLAGS(a3)
	beq.s	BeginIO_Immediate


BeginIO_QueueMsg:
	BSET	#UNITB_INTASK,UNIT_FLAGS(a3)
	bclr	#IOB_QUICK,IO_FLAGS(a1)

	ENABLE	a0

	move.l	a3,a0
	LINKSYS	PutMsg,md_SysLib(a6)
	bra.s	BeginIO_End

BeginIO_Immediate:
	ENABLE	a0

	bsr	PerformIO

BeginIO_End:
	move.l	(sp)+,a3
	rts

BeginIO_NoCmd:
	move.b	#IOERR_NOCMD,IO_ERROR(a1)
	bra.s	BeginIO_End


PerformIO:
	move.l	a2,-(sp)

;	move.l	#'MOMY',$80000

	move.l	a1,a2

	move.w	IO_COMMAND(a2),d0
	lsl.w	#2,d0
	lea	cmdtable(pc),a0

	move.l	0(a0,d0.w),a0

	jsr	(a0)

	move.l	(sp)+,a2
	rts

TermIO:
	move.w	IO_COMMAND(a1),d0
	move.w	#IMMEDIATES,d1
	btst	d0,d1
	bne.s	TermIO_Immediate

	btst	#UNITB_INTASK,UNIT_FLAGS(a3)
	bne.s	TermIO_Immediate

	bclr	#UNITB_ACTIVE,UNIT_FLAGS(a3)

TermIO_Immediate:
	btst	#IOB_QUICK,IO_FLAGS(a1)
	bne.s	TermIO_End

	LINKSYS	ReplyMsg,md_SysLib(a6)

TermIO_End:
	rts


AbortIO:
;-----------------------------------------------------------
;	here begins the function that implement the device commands
;	all functions are called with:
;		a1 -- a pointer to the io request block
;		a2 -- another pointer to the iob
;		a3 -- a pointer to the unit
;		a6 -- a pointer to the device
; Commands that conflict the 68000 instructions have a "My" prepended
; to them.
;------------------------------------------------------------

Invalid:
	move.b	#IOERR_NOCMD,IO_ERROR(a1)
	bsr	TermIO
	rts

MyReset:
	;!!! fill me in !!!.........
	;!!! fill me in !!!.........
	;!!! fill me in !!!.........
	;!!! fill me in !!!.........
	;!!! fill me in !!!.........

;Read command acts as an infinite source of nulls. It Clears
;the user's buffer and marks that many bytes as having been read.
;
Read:
	move.l	IO_DATA(a1),a0
	move.l	IO_LENGTH(a1),d0
	move.l	d0,IO_ACTUAL(a1)

	;---- deal with a zero length read
	beq.s	Read_End

	;---- now copy the data
	moveq	#0,d1

Read_Loop:
	move.b	d1,(a0)+
	subq.l	#1,d0
	bne.s	Read_Loop

Read_End:
	bsr	TermIO
	rts


; the Write command acts as bith bucket.  It clears acknowledges all
; the bytes the user has tried to write to it.

Write:
	move.l	IO_LENGTH(a1),IO_ACTUAL(a1)

	bsr	TermIO
	rts

; Update and Clear are internal buffering commands. Update forces all
; io out to its final resting spot, and does not return until the is 
; done.  Clear invalidates all internal buffers. Since this device
; has no internal buffers, these commands do not apply.

Update:
Clear:
	bra	Invalid

; the Stop command stop all future io requests from being
; processed until a start command is received. The Stop
; command is Not stackable: e.g. no matter how many stops
; have been issued, it only takes one start to restart
; processing.

MyStop:
	bset	#MDUB_STOPPED,UNIT_FLAGS(a3)

	bsr	TermIO
	rts

Start:
	bsr	InternalStart

	move.l	a2,a1
	bsr	TermIO
	rts

InternalStart:
	;---- turn processing bak on
	bclr	#MDUB_STOPPED,UNIT_FLAGS(a3)

	;---- kick the task to start it moving
	move.l	a3,a1
	moveq	#0,d0
	move.l	MP_SIGBIT(a3),d1
	bset	d1,d0
	LINKSYS	Signal,md_SysLib(a3)
	rts

; Flush pulls all io requests off the queue and sends them back.
; We must be careful not to destroy work in progress, and also
; that we do not let some io requests slip by.

; Some funny magic goes on with the STOPPED bit in here. Stop is
; defined as not being reentrant.  We therefore save the old state
; of the bit and then restor it later.  This keeps us from 
; needing to DISABLE in flush. It also fails miserably if someone
; does a start in the middle of a flush.

Flush:
	movem.l	d2/a6,-(sp)
	move.l	md_SysLib(a6),a6

	bset	#MDUB_STOPPED,UNIT_FLAGS(a3)
	sne	d2

Flush_Loop:
	move.l	a3,a0
	CALLSYS	GetMsg

	tst.l	d0
	beq.s	Flush_End

	move.l	d0,a1
	move.b	#IOERR_ABORTED,IO_ERROR(a1)
	CALLSYS	ReplyMsg

	bra.s	Flush_Loop

Flush_End:
	move.l	d2,d0
	movem.l	(sp)+,d2/a6

	tst.b	d0
	beq.s	1$

	bsr	InternalStart
1$:
	move.l	a2,a1
	bsr	TermIO

	rts

; Foo and Bar are two device specific commands that are provided just
; to show you how to add your own commands. The currently return that
; no work was done.

Foo:
Bar:
	moveq	#0,d0
	move.l	d0,IO_ACTUAL(a1)
	bsr	TermIO
	rts

;-----------------------------------------------------------------------
; here begins the process related routines
;
; Aprocess is provided so that queued requests may be processed at
; a later time.
;
; Register Usage
;================
; a3 -- unit pointer
; a6 -- syslib pointer
; a5 -- device pointer
; a4 -- task (NOT process) pointer
; d7 -- wait mask
;
;------------------------------------------------------------------------

; some dos magic.  A process is started at the first executable address
; after a segment list.  We hand craft a segment list here.  See the
; DOS technical reference if you really need to know more about this.

	cnop	0,4	;long word allign
	DC.L	16	;segment length -- any number will do
myproc_seglist:
	DC.L	0	;pointer to next segment

; the next instruction after the segment list is the first executable address

Proc_Begin:
	move.l	_AbsExecBase,a6
	;----- wait for our first packet

;	move.l	#'tvtm',$80000

	sub.l	a1,a1			;<my task> = FindTask(0)
	CALLSYS FindTask
	move.l	d0,a0
	move.l	d0,a4			;save task in a4

	move.l	a4,$7fff0
	move.l	18(a4),$80000
	move.l	22(a4),$80004
	move.l	26(a4),$80008
	move.l	30(a4),$8000c

	lea	pr_MsgPort(a0),a0	;get msg port for my processes
	CALLSYS WaitPort

	move.l	$7fff0,a4
	move.l	18(a4),$80010
	move.l	22(a4),$80014
	move.l	26(a4),$80018
	move.l	30(a4),$8001c


	;----- take msg off the port
	move.l	d0,a1
	move.l	d0,a2			;save the message
	CALLSYS	Remove

	;----- get our parameters out of it
	move.l	mdm_Device(a2),a5	;a5 is now our device
	move.l	mdm_Unit(a2),a3

	;----- Allocate the right signal
	moveq	#-1,d0			;-1 is any signal at all
	CALLSYS	AllocSignal
	move.b	d0,MP_SIGBIT(a3)
	move.b	#PA_SIGNAL,MP_FLAGS(a3)

	;----- change the bit number into a mask, and save in d7
	moveq	#0,d7
	bset	d0,d7

;----- OK, kids, we are done with initialization.  We now
;----- can start the main loop of the driver.  It goes
;----- like this.  Because we had the port marked PA_IGNORE
;----- for a while (in InitUnit) we jump to the getmsg
;----- code on entry.
;----- 
;----- 		wait for a message
;----- 		lock the device
;----- 		get a message. if no message unlock device and loop
;----- 		dispatch the message
;----- 		loop back to get a message
;----- 
;----- 

	bra.s	Proc_CheckStatus

	;----- main loop: wait for a new message
Proc_MainLoop:
	move.l	d7,d0
	CALLSYS	Wait

	move.l	$7fff0,a4
	move.l	18(a4),$80020
	move.l	22(a4),$80024
	move.l	26(a4),$80028
	move.l	30(a4),$8002c

Proc_CheckStatus:
	;----- see if we are stopped
	btst	#MDUB_STOPPED,UNIT_FLAGS(a3)
	bne.s	Proc_MainLoop		;device is stopped

	;----- lock the device
	bset	#UNITB_ACTIVE,UNIT_FLAGS(a3)
	bne.s	Proc_MainLoop		;device in use

	;----- get the next request
Proc_NextMessage:

	add.l	#1,$7fff8

	move.l	a3,a0
	CALLSYS	GetMsg

;	move.l	#'Girl',$80004
;	move.l	d0,$80008
;	move.l	a3,$8000c
;	move.l	#UNIT_FLAGS,$80010

	tst.l	d0
	beq.s	Proc_Unlock		;no message?

	;----- do this request
	move.l	d0,a1
	exg	a5,a6			;put device ptr in right place
	bsr	PerformIO
	exg	a5,a6			;get syslib back in a6

	bra.s	Proc_NextMessage

	;----- no more messages. back ourselves out.
Proc_Unlock:
	and.b	#$ff&(UNITB_ACTIVE!UNITB_INTASK),UNIT_FLAGS(a3)
	bra	Proc_MainLoop

Proc_Fail:
	;----- we come here on initialization failures
	bsr	FreeUnit
	rts

;----------------------------------------------------------------
; EndCode is a marker that show the end of your code.
; 
; 
;----------------------------------------------------------------

EndCode:
	END

