
	SECTION section

;	NOLIST
;	include	"mydev.i"
;	LIST

   include  "exec/types.i"
   include  "exec/ables.i"
   include  "exec/alerts.i"
   include  "exec/devices.i"
   include  "exec/errors.i"
   include  "exec/initializers.i"
   include  "exec/io.i"
   include  "exec/libraries.i"
   include  "exec/lists.i"
   include  "exec/memory.i"
   include  "exec/nodes.i"
   include  "exec/resident.i"
   include  "libraries/dos.i"
   include  "libraries/dosextens.i"
   include  "asmsupp.i"


;---------------------------------------------------------------------
;
;  device command definitions
;
;---------------------------------------------------------------------

;      DEVINIT
;      DEVCMD   MYDEV_FOO
;      DEVCMD   MYDEV_BAR
;      DEVCMD   MYDEV_END      ; place marker -- first illegal command #

	LIBINIT
	LIBDEF	Dev_BeginIO
	LIBDEF	Dev_AbortIO
	LIBDEF	Dev_Func

;---------------------------------------------------------------------
;
;  device data structures
;
;---------------------------------------------------------------------

; maximum number of units in this device
MD_NUMUNITS    EQU      4

   STRUCTURE   MyDev,LIB_SIZE
      ULONG       md_ExecBase
      ULONG       md_SegList
      ULONG       md_DosBase
      STRUCT      md_Units,MD_NUMUNITS*4
      UBYTE       md_Flags
      UBYTE       md_pad
      LABEL       MyDev_Sizeof

   STRUCTURE   MyDevMsg,MN_SIZE
      APTR        mdm_Device
      APTR        mdm_Unit
      APTR        mdm_Iob
      LABEL       MyDevMsg_Sizeof

   STRUCTURE   MyDevUnit,UNIT_SIZE
      UBYTE       mdu_UnitNum
      UBYTE	  mdm_pad
      APTR        mdu_Process
      STRUCT      mdu_Msg,MyDevMsg_Sizeof
      LABEL       MyDevUnit_Sizeof

      ;---------- state bit for unit stopped
      BITDEF      MDU,STOPPED,2

; stack size and priority for the process we will create
MYDEV_STACKSIZE  EQU      $500
MYDEV_PRIORITY   EQU      0

MYDEVNAME         MACRO
                  DC.B     'mydev.device',0
                  ENDM


	XDEF	BeginIO
	XDEF	AbortIO
	XDEF	Close
	XDEF	DevFunc
	XDEF	DevInit
	XDEF	Expunge
	XDEF	ExtFunc
	XDEF	Open
	XDEF	myName

;	XDEF	_AbsExecBase
_AbsExecBase	EQU	$4

	XLIB	OpenLibrary
	XLIB	CloseLibrary
	XLIB	Alert
	XLIB	FreeMem
	XLIB	Remove
	XLIB	FindTask
	XLIB	AllocMem
	XLIB	CreateProc
	XLIB	PutMsg
	XLIB	RemTask
	XLIB	ReplyMsg
	XLIB	Signal
	XLIB	GetMsg
;	XLIB	Wait
	XLIB	WaitPort
	XLIB	AllocSignal
	XLIB	SetTaskPri

;_LVOCreateProc	EQU	-138

	INT_ABLES

	DEVINIT
	DEVCMD	MYDEVCMD
	DEVCMD	MYDEV_END


DevStart:
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
	


MYPRIORITY	EQU	0
VERSION:	EQU	1
REVISION:	EQU	2

initDevDescrip:
	DC.W	RTC_MATCHWORD
	DC.L	initDevDescrip
	DC.L	EndDevCode
	DC.B	RTF_AUTOINIT
	DC.B	VERSION
	DC.B	NT_DEVICE
	DC.B	MYPRIORITY
	DC.L	myName
	DC.L	DevIdString
	DC.L	DevInit

subSysName:
myName:		MYDEVNAME


DevIdString	dc.b	'Seans Device for Parallal Communications',13,10,0

dosName:	DOSNAME

	DS.W	0

DevInit:
	DC.L	MyDev_Sizeof
	DC.L	funcTable
	DC.L	dataTable
	DC.L	initRoutine

funcTable:
	DC.L	Open
	DC.L	Close
	DC.L	Expunge
	DC.L	ExtFunc

	DC.L	BeginIO
	DC.L	AbortIO

	DC.L	DevFunc
	DC.L	ExtFunc
	DC.L	ExtFunc
	DC.L	ExtFunc
	DC.L	ExtFunc
	DC.L	ExtFunc
	DC.L	ExtFunc
	DC.L	ExtFunc
	DC.L	ExtFunc
	DC.L	ExtFunc
	DC.L	ExtFunc
	DC.L	ExtFunc
	DC.L	ExtFunc
	DC.L	ExtFunc

	DC.L	-1

dataTable:
	INITBYTE	LN_TYPE,NT_DEVICE
	INITLONG	LN_NAME,myName
	INITBYTE	LIB_FLAGS,LIBF_SUMUSED!LIBF_CHANGED
	INITWORD	LIB_VERSION,VERSION
	INITWORD	LIB_REVISION,REVISION
	INITLONG	LIB_IDSTRING,DevIdString
	DC.L	0

initRoutine:
;	move.b	#0,30(a1)

	move.l	a5,-(sp)
	move.l	d0,a5
	move.l	a6,md_ExecBase(a5)

	move.l	a0,md_SegList(a5)

	lea	dosName(pc),a1
	moveq	#0,d0
	CALLSYS	OpenLibrary
	move.l	d0,md_DosBase(a5)
	bne.s	init_DosOK

;	move.l	#'poky',$80040
	ALERT	AG_OpenLib!AO_DOSLib

init_DosOK:

;	Put Your initialization here ........
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	d0,a6
	jsr	-60(a6)		; write data to output screen
	move.l	d0,outhandle
	movem.l	(sp)+,d0-d7/a0-a6


	move.l	a5,d0
	move.l	(sp)+,a5
;	move.l	#'Sean',$80000

	rts

seancode:
	dc.b	'Here we print',13,10,0
	cnop	0,4
outhandle:
	dc.l	0

printseancode:
	movem.l	d0-d7/a0-a6,-(sp)
	lea	seancode(pc),a2
	move.l	a2,d2
	move.l	#15,d3
	move.l	outhandle,d1
	jsr	-48(a6)		; write data to output screen
	movem.l	(sp)+,d0-d7/a0-a6
	rts

;--------------------------------------------------------------
; registers: a6-dev.ptr,  a1-ioreq.ptr,  d0-unitnum,  d1-flags
;

Open:
	movem.l	d2/a2-a4,-(sp)

	bsr	InitUnit

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

;	move.l	#'stg3',$80004

	move.l	(a4),d0
	beq.s	Open_Error

Open_UnitOK:

	bsr	printseancode

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
;	move.b	#IOERR_OPENFAIL,IO_ERROR(a2)
	move.b	#$fe,IO_ERROR(a2)
	bra.s	Open_End


;---------------------------------------------------------------
;registers	a6-dev.ptr,  a1-ioreq.ptr
;

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

;---------------------------------------------------------------
;registers	a6-dev.ptr
;

Expunge:
	movem.l	d2/a5-a6,-(sp)
	move.l	a6,a5
	move.l	md_ExecBase(a5),a6

	tst.w	LIB_OPENCNT(a5)
	beq	1$

	bset	#LIBB_DELEXP,md_Flags(a5)
	moveq	#0,d0
	bra.s	Expunge_End

1$:
	move.l	md_SegList(a5),d2
	move.l	a5,a1
	CALLSYS	Remove

; Device specific closings here .......

	move.l	md_DosBase(a5),a1
	CALLSYS	CloseLibrary

	moveq	#0,d0
	move.l	a5,a1
	move.l	LIB_NEGSIZE(A5),D0

	sub.l	d0,a1
	add.w	LIB_POSSIZE(a5),d0

	CALLSYS	FreeMem

	move.l	d2,d0

Expunge_End:
	movem.l	(sp)+,d2/a5-a6
	rts


ExtFunc:
	moveq	#0,d0
	rts

;---------------------------------------------------------------
;registers	a6-dev.ptr,  a3-scratch,  d2-unit no.
;

InitUnit:
	movem.l	d2-d4,-(sp)

;	move.b	#$0,30(a1)

	move.l	#MyDevUnit_Sizeof,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	LINKSYS	AllocMem,md_ExecBase(a6)

	tst.l	d0
	beq	InitUnitEnd

	move.l	d0,a3
	move.b	d2,mdu_UnitNum(a3)	;26

	move.b	#NT_MSGPORT,LN_TYPE(a3)

;	move.l	d0,a3
;	move.b	d2,mdu_UnitNum(a3)	;26

;	set up the unit process

	move.l	#MYDEV_STACKSIZE,d4
	move.l	#MyDevProcSegList,d3
	lsr.l	#2,d3
	moveq	#MYDEV_PRIORITY,d2
	move.l	#myName,d1
	LINKSYS	CreateProc,md_DosBase(a6)

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
	beq	InitUnitFreeUnit

	move.l	d0,mdu_Process(a3)	;44
	move.l	d0,a0
	lea	-pr_MsgPort(a0),a0	;5C was -pr_


	move.b	#PA_IGNORE,MP_FLAGS(a3)
;	move.b	#PA_SIGNAL,MP_FLAGS(a3)
	move.l	a0,MP_SIGTASK(a3)	;10

;	move.l	#'Chrs',$80000

	lea	mdu_Msg(a3),a1		;28

;	move.l	a1,$80000
;	move.l	#mdu_Msg,$80004
;	move.l	a3,$80008

	move.l	a3,mdm_Unit(a1)
	move.l	a6,mdm_Device(a1)
	move.b	#NT_MESSAGE,LN_TYPE(a1)
	move.l	d0,a0

;	move.l	#'hisg',$80010

	LINKSYS	PutMsg,md_ExecBase(a6)

	move.b	mdu_UnitNum(a3),d0
;	move.l	d2,d0
	lsl.l	#2,d0
	move.l	a3,md_Units(a6,d0.l)

InitUnitEnd:

	movem.l	(sp)+,d2-d4
	rts

InitUnitFreeUnit:
	bsr	FreeUnit
	bra.s	InitUnitEnd

FreeUnit:
	move.l	a3,a1
	move.l	#MyDevUnit_Sizeof,d0
	LINKSYS	FreeMem,md_ExecBase(a6)
	rts

ExpungeUnit:
	move.l	d2,-(sp)

	move.l	mdu_Process(a3),a1
	lea	-(pr_MsgPort)(a1),a1
	LINKSYS	RemTask,md_ExecBase(a6)

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

cmdTable:
	DC.L	Invalid
	DC.L    MyReset
	DC.L	Read
	DC.L	Write
	DC.L	Update
	DC.L	Clear
	DC.L    MyStop
	DC.L	Start
	DC.L	Flush
	DC.L	Custom
;	DC.L	Bar
cmdTable_end:

IMMEDIATE	EQU	$000001C2	;THESE ARE NOT QUEUED

; BeginIO	start all incoming io.  The IO is either queued up
;		for the unit task or processed immediately.

BeginIO:
	move.l	a3,-(sp)

;	move.l	'ioum',$80030


	move.l	IO_UNIT(a1),a3

	moveq	#0,d0
	move.w	IO_COMMAND(a1),d0
	cmp.w	#MYDEV_END,d0
	bcc	BeginIO_BadCmd

	DISABLE	a0

	btst	#IOB_QUICK,IO_FLAGS(a1)
	bne.s	BeginIO_Immediate

	move.w	#IMMEDIATE,D1
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

	move.l	mdu_Msg(a3),a2
	move.l	a1,mdm_Iob(a2)
	move.l	a2,a1
	move.l	mdu_Process(a3),a0
;	move.l	a3,a0
	LINKSYS	PutMsg,md_ExecBase(a6)
	bra	BeginIO_End

BeginIO_Immediate:
	ENABLE	a0
	bsr	ExecuteIO

BeginIO_End:
	move.l	(sp)+,a3
	rts

BeginIO_BadCmd:
	move.b	#IOERR_NOCMD,IO_ERROR(a1)
	bra.s	BeginIO_End


ExecuteIO:
	move.l	a2,-(sp)

;	move.l	#'MOMY',$80000

	move.l	a1,a2

	move.b	#0,IO_ERROR(a2)

	moveq	#0,d0
	move.w	IO_COMMAND(a2),d0
	lsl.w	#2,d0
	lea	cmdTable(pc),a0
	move.l	0(a0,d0.w),a0

	jsr	(a0)

	move.l	(sp)+,a2
	rts

TerminateIO:
	moveq	#0,d0
	move.w	IO_COMMAND(a1),d0
	move.w	#IMMEDIATE,d1
	btst	d0,d1
	bne.s	TerminateIO_Immediate

	btst	#UNITB_INTASK,UNIT_FLAGS(a3)
	bne.s	TerminateIO_Immediate

	bclr	#UNITB_ACTIVE,UNIT_FLAGS(a3)

TerminateIO_Immediate:
	btst	#IOB_QUICK,IO_FLAGS(a1)
	bne.s	TerminateIO_End

	LINKSYS	ReplyMsg,md_ExecBase(a6)

TerminateIO_End:
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
	rts

AbortIO_End:
	rts

Invalid:
	move.b	#IOERR_NOCMD,IO_ERROR(a1)
	bsr	TerminateIO
	rts


MyReset:

	move.l	#0,IO_ACTUAL(a1)
	;!!! fill me in !!!.........
	;!!! fill me in !!!.........
	;!!! fill me in !!!.........
	;!!! fill me in !!!.........
	;!!! fill me in !!!.........
	rts

;Read command acts as an infinite source of nulls. It Clears
;the user's buffer and marks that many bytes as having been read.
;
Read:
	move.l	IO_DATA(a1),a0
	move.l	IO_LENGTH(a1),d0
;	move.l	d0,IO_ACTUAL(a1)
	moveq	#0,d2
	move	#0,ccr

	;---- deal with a zero length read
	beq.s	ReadEnd

	;---- now copy the data
;	moveq	#0,d1
	move.l	#1,d1

ReadLoop:
	move.b	d1,(a0)+
	add.l	#1,d2
	subq.l	#1,d0
	bne.s	ReadLoop

ReadEnd:
	move.l	d0,IO_ACTUAL(a1)
	bsr	TerminateIO
	rts


; the Write command acts as bith bucket.  It clears acknowledges all
; the bytes the user has tried to write to it.

Write:
	move.l	IO_LENGTH(a1),IO_ACTUAL(a1)

	bsr	TerminateIO
	rts

; Update and Clear are internal buffering commands. Update forces all
; io out to its final resting spot, and does not return until the is 
; done.  Clear invalidates all internal buffers. Since this device
; has no internal buffers, these commands do not apply.

Update:
	bra	Invalid

Clear:
	bra	Invalid

; the Stop command stop all future io requests from being
; processed until a start command is received. The Stop
; command is Not stackable: e.g. no matter how many stops
; have been issued, it only takes one start to restart
; processing.

MyStop:
	bset	#MDUB_STOPPED,UNIT_FLAGS(a3)
	move.l	#0,IO_ACTUAL(a1)
	bsr	TerminateIO
	rts

Start:
	bsr	InternalStart

	move.l	a2,a1
	move.l	#0,IO_ACTUAL(a1)
	bsr	TerminateIO
	rts

InternalStart:
	;---- turn processing bak on
	bclr	#MDUB_STOPPED,UNIT_FLAGS(a3)

	;---- kick the task to start it moving
;	move.l	a3,a1
	moveq	#0,d0
	moveq	#0,d1
	move.b	MP_SIGBIT(a3),d1
	bset	d1,d0
	move.l	a3,a1
	LINKSYS	Signal,md_ExecBase(a3)
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
	move.l	md_ExecBase(a6),a6

	bset	#MDUB_STOPPED,UNIT_FLAGS(a3)
	sne	d2

FlushLoop:
	move.l	a3,a0
	CALLSYS	GetMsg

	tst.l	d0
	beq.s	FlushEnd

	move.l	d0,a1
	move.b	#IOERR_ABORTED,IO_ERROR(a1)
	CALLSYS	ReplyMsg

	bra.s	FlushLoop

FlushEnd:
	move.l	d2,d0
	movem.l	(sp)+,d2/a6

	tst.b	d0
	beq.s	1$

	bsr	InternalStart
1$:
	move.l	a2,a1
	bsr	TerminateIO

	rts

; Foo and Bar are two device specific commands that are provided just
; to show you how to add your own commands. The currently return that
; no work was done.

Custom:
Bar:
;	moveq	#0,d0
;	move.l	d0,IO_ACTUAL(a1)
	bsr	TerminateIO
	rts


DevFunc:
	move.l	a3,-(sp)

	move.l	#MD_NUMUNITS,d2
	cmp.l	d2,d0
	bcc.s	DevFuncError

	lsl.l	#2,d0
	move.l	md_Units(a6,d0.l),a3
	cmp.l	#0,a3
	beq.s	DevFuncError

	move.w	UNIT_OPENCNT(a3),d0

DevFuncExit:
	move.l	(sp)+,a3
	rts

DevFuncError:
	move.l	#-1,d0
	bra.s	DevFuncExit

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

MyDevProcStart:
	cnop	0,4	;long word allign
	DC.L	16	;segment length -- any number will do
MyDevProcSegList:
	DC.L	0	;pointer to next segment

; the next instruction after the segment list is the first executable address

MyDevProcBegin:
	move.l	_AbsExecBase,a6
	;----- wait for our first packet

;	move.l	#'tvtm',$80000

	sub.l	a1,a1			;<my task> = FindTask(0)
	CALLSYS FindTask
	move.l	d0,a0
	move.l	d0,a4			;save task in a4

;	move.l	a4,$7fff0
;	move.l	18(a4),$80000
;	move.l	22(a4),$80004
;	move.l	26(a4),$80008
;	move.l	30(a4),$8000c

	lea	pr_MsgPort(a0),a0	;get msg port for my processes
	move.l	a0,d4
	CALLSYS WaitPort

;	move.l	$7fff0,a4
;	move.l	18(a4),$80010
;	move.l	22(a4),$80014
;	move.l	26(a4),$80018
;	move.l	30(a4),$8001c


	;----- take msg off the port
	move.l	d0,a1
	move.l	d0,a2			;save the message
	CALLSYS	Remove

	;----- get our parameters out of it
	move.l	d2,a2
	move.l	mdm_Device(a2),a5	;a5 is now our device
	move.l	mdm_Unit(a2),a3

	;----- Allocate the right signal
	move.l	a5,d5
	move.l	a3,d3

	moveq	#-1,d0			;-1 is any signal at all
	CALLSYS	AllocSignal

	move.l	d3,a3
	move.b	d0,MP_SIGBIT(a3)
	move.b	#PA_SIGNAL,MP_FLAGS(a3)

;	;----- change the bit number into a mask, and save in d7
;	moveq	#0,d7
;	bset	d0,d7

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

	bra.s	MyDevProcCheckStatus

	;----- main loop: wait for a new message
MyDevProcMainLoop:
;	move.l	d7,d0
;	CALLSYS	Wait
	move.l	d4,a0
	CALLSYS	WaitPort

;	move.l	$7fff0,a4
;	move.l	18(a4),$80020
;	move.l	22(a4),$80024
;	move.l	26(a4),$80028
;	move.l	30(a4),$8002c

MyDevProcCheckStatus:
	;----- see if we are stopped
	move.l	d3,a3
	btst	#MDUB_STOPPED,UNIT_FLAGS(a3)
	bne.s	MyDevProcMainLoop		;device is stopped

	;----- lock the device
	bset	#UNITB_ACTIVE,UNIT_FLAGS(a3)
	bne.s	MyDevProcMainLoop		;device in use

	;----- get the next request
MyDevProcNextMessage:

;	add.l	#1,$7fff8

;	move.l	a3,a0
	move.l	d4,a0
	CALLSYS	GetMsg

;	move.l	#'Girl',$80004
;	move.l	d0,$80008
;	move.l	a3,$8000c
;	move.l	#UNIT_FLAGS,$80010

	tst.l	d0
	beq.s	MyDevProcUnlock		;no message?

	;----- do this request
;	move.l	d0,a1
	move.l	d0,a2
	move.l	d3,a3
	move.l	mdm_Iob(a2),a1
	exg	a5,a6			;put device ptr in right place
	bsr	ExecuteIO
	exg	a5,a6			;get syslib back in a6

	bra.s	MyDevProcNextMessage

	;----- no more messages. back ourselves out.
MyDevProcUnlock:
	and.b	#$ff&(UNITB_ACTIVE!UNITB_INTASK),UNIT_FLAGS(a3)
	bra	MyDevProcMainLoop

MyDevProcFail:
	;----- we come here on initialization failures
	bsr	FreeUnit
	rts

;----------------------------------------------------------------
; EndCode is a marker that show the end of your code.
; 
; 
;----------------------------------------------------------------
EndDevCode:
EndCode:
	END

