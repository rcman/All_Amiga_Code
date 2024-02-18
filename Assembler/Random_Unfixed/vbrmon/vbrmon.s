;VBRMon - The ultimate investigative tool!

;Some of this code is...
;Copyright (c) 1991 by Dan Babcock

;...other parts are copyrighted by their respective authors:
;Dan Zenchelsky
;Andreas Hommel
;John Veldthuis
;Dave Campbell
;SCA

;Any personal use of this program is fine. All commercial use is
;forbidden.

;Note!!! The copyright notices in the program are present only
;to discourage people from selling this program. They are not
;meant to restrict its use in any way, nor to detract from the
;contributions of so many fine people (see the credits)!!!!!!

;Ok, that was the formal stuff; now have fun!

;--------------------
;Dan Babcock
;P.O. Box 1532
;Southgate, MI  48195
;USA
;--------------------

;Based on:

;RomCrack disassembly
;Made with ReSource on November 30, 1990

 comment |

Version history:

V1.00 - Works well (at least for me :-))
V1.01 - Now displays INTREQR and DMACONR along with the register dump.
        Added joystick autofire feature
V1.02 - Added copper disassembler
        Fixed rare keyboard problem
        Improved right mouse button check
        Fixed printer output bug
        Eliminated LED flashing (do you miss it?)
V1.03 - Added offset hunt command (taken from CM - thanks!)
        Fixed bug in regular hunt routine
        Added guru trapping option
V1.04 - Added command history
        Uses commands longer than one character
        Added save/restore registers commands
        Register modify is now useful (revised J, added XMOD)

Known bugs as of V1.04:

* Move-to-CCR and Move-to-SR immediate are not disassembled correctly.
* The mini-assembler clobbers a word of adjacent data when assembling
  move instructions.

|

	exeobj
	errfile	'ram:assem.output'
	objfile	'vbrmon'
	MC68010
	super

color0	equ	$180
color1	equ	$182
bpl1pth	equ	$E0

led_vblank_counter	equ	$8c	;byte
cursor_vblank_counter	equ	$8d	;byte
cursor_value	equ	$8e	;word
cursor_memory_location	equ	$90	;longword
ascii_key_pressed	equ	$99	;byte
last_ascii_key_pressed	equ	$9A	;byte
cursor_x_position	equ	$94	;word
cursor_y_position	equ	$96	;word
keyboard_shifted_flag	equ	$98	;byte
chars_in_linebuffer_flag	equ	$A2	;byte
line_buffer_ptr	equ	$A0	;word
line_buffer	equ	$1b18	;160 bytes (?)
charmap	equ	$1118	;2560 bytes

	movem.l	d2-d7/a2-a6,-(sp)
	move.l	sp,(lbL002610)
	movea.l	(4),a6
	movea.l	a0,a5
	move.w	d0,d5

;Make a copy of ExecBase
	lea	(ExecData,pc),a0
	move.l	(4).w,a1
	move.l	a1,(a0)+
	move.w	#ChkSum+1,d0
..	move.b	(a1)+,(a0)+
	dbra	d0,..

	lea	(NMI,pc),a0
	move.l	($7c),(a0)

;Check for >512K Agnus
	cmp.l	#$80000,(MaxLocMem,a6)
	bne.b	.SkipOldAgnusJunk

	cmp.b	#60,(VBlankFrequency,a6)
	bne.b	.skipntscjunk
	not.w	(VideoMode)
.skipntscjunk:

.SkipOldAgnusJunk:
	suba.l	a1,a1
	jsr	(_LVOFindTask,a6)
	movea.l	d0,a4
	move.l	a4,(lbL002604)
	moveq	#$21,d0
	lea	(doslibrary.MSG),a1
	jsr	(_LVOOpenLibrary,a6)
	move.l	d0,(DosBase)
	move.l	(pr_CLI,a4),d0
	beq	lbC0000CA
	lsl.l	#2,d0
	movea.l	d0,a0
	movea.l	($10,a0),a0
	adda.l	a0,a0
	adda.l	a0,a0
	lea	(lbL00266C),a2
	lea	(lbL00261C),a3
	moveq	#1,d2
	moveq	#0,d0
	move.b	(a0)+,d0
	move.l	a2,(a3)+
	subq.w	#1,d0
lbC000062:
	move.b	(a0)+,(a2)+
	dbra	d0,lbC000062

	clr.b	(a2)+
lbC00006A:
	subq.w	#1,d5
	ble.b	lbC0000A4
	move.b	(a5)+,d0
	cmp.b	#$20,d0
	ble.b	lbC00006A
	addq.l	#1,d2
	move.l	a2,(a3)+
	bra.b	lbC000080

lbC00007C:
	subq.w	#1,d5
	move.b	(a5)+,d0
lbC000080:
	cmp.b	#$22,d0
	beq.b	lbC000094
	cmp.b	#$20,d0
	ble.b	lbC000090
	move.b	d0,(a2)+
	bra.b	lbC00007C

lbC000090:
	clr.b	(a2)+
	bra.b	lbC00006A

lbC000094:
	subq.w	#1,d5
	ble.b	lbC0000A4
	move.b	(a5)+,d0
	cmpi.b	#$22,d0
	beq.b	lbC00007C
	move.b	d0,(a2)+
	bra.b	lbC000094

lbC0000A4:
	clr.b	(a2)+
	pea	(lbL00261C)
	move.l	d2,-(sp)
	movea.l	(DosBase),a6
	jsr	(_LVOInput,a6)
	move.l	d0,d1
	push	d0
	SYS	IsInteractive
	addq.l	#4,sp
	tst.l	d0
	beq	DoOpenWindow
	move.l	(-4,sp),d0
	move.l	d0,(StdInput)
	jsr	(_LVOOutput,a6)
	move.l	d0,(StdOutput)
	bra.b	lbC00012A

lbC0000CA:

;Start of Workbench support code

	lea	(pr_MsgPort,a4),a0
	jsr	(_LVOWaitPort,a6)
	lea	(pr_MsgPort,a4),a0
	jsr	(_LVOGetMsg,a6)
	move.l	d0,(lbL002618)
	movea.l	d0,a2
	move.l	d0,-(sp)
	movea.l	($24,a2),a0
	move.l	(a0),d1
	movea.l	(DosBase),a6
	jsr	(_LVOCurrentDir,a6)

DoOpenWindow:
	move.l	#CON016640110R.MSG,d1
	move.l	#MODE_OLDFILE,d2
	movea.l	(DosBase),a6
	jsr	(_LVOOpen,a6)
	move.l	d0,(ConFileHandle)
	move.l	d0,(StdInput)
	move.l	d0,(StdOutput)
	lsl.l	#2,d0
	movea.l	d0,a0
	move.l	(fh_Type,a0),(pr_ConsoleTask,a4)
lbC000128:
	clr.l	-(sp)
lbC00012A:
	bsr	lbC000190
	moveq	#0,d7
lbC000130:
	move.l	(ConFileHandle),d1
	beq.b	lbC000142
	movea.l	(DosBase),a6
	jsr	(_LVOClose,a6)
lbC000142:
	movea.l	(DosBase),a1
	movea.l	(4),a6
	jsr	(_LVOCloseLibrary,a6)
	tst.l	(lbL002618)
	beq.b	lbC000166
	jsr	(_LVOForbid,a6)
	movea.l	(lbL002618),a1
	jsr	(_LVOReplyMsg,a6)
lbC000166:
	move.l	d7,d0
	movea.l	(lbL002610),sp
	movem.l	(sp)+,d2-d7/a2-a6
	rts

lbC000174:
	move.l	d0,d7
	move.l	(ConFileHandle),d1
	beq.b	lbC000142
	move.l	#$4C4B40,d2
	movea.l	(DosBase),a6
	jsr	(_LVOWaitForChar,a6)
	bra.b	lbC000130

lbC000190:
	lea	(CHW.MSG,pc),a4
	lea	(lbL00276C),a2
	moveq	#0,d3
	move.l	(4,sp),d0
	movea.l	(8,sp),a5
	cmpi.w	#2,d0
	blt.b	lbC0001BE
	cmpi.w	#4,d0
	bne.b	lbC0001B4
	seq	d3
	bra.b	lbC0001BE

lbC0001B4:
	pea	(FormatROMCrac.MSG)
	bra	lbC000460

lbC0001BE:
	lea	($4E,a4),a1
	movea.l	(4),a6
	jsr	(_LVOFindResident,a6)
	movea.l	d0,a3
	tst.l	d0
	beq	lbC00022A
lbC0001D0:
	tst.b	d3
	bne.b	lbC0001EA
	pea	(ROMCrackisalr.MSG)
	bsr	lbC000520
	addq.l	#4,sp
	bsr	lbC0004B4
	cmpi.b	#'y',(a2)
	beq.b	lbC0001F4
	cmpi.b	#'Y',(a2)
	beq.b	lbC0001F4
lbC0001EA:
	pea	(ROMCrackstill.MSG)
	bra	lbC000460

;VBRCrack already installed - user wants to kill it

lbC0001F4:
	lea	(-$34,a3),a4
	clr.l	(14,a3)
	movea.l	(4).w,a6

;Concept: Whatever is pointing to me, point to what I am pointing to

	lea	(KickMemPtr,a6),a0
	lea	(4,a4),a1
	move.l	a0,d0
.nohit:
	move.l	d0,a0
	move.l	(a0),d0
	beq.b	.done
	cmp.l	d0,a1
	bne.b	.nohit
	move.l	(a1),(a0)
.done:

	lea	($2c,a4),a1
	move.l	(KickTagPtr,a6),a0
	cmp.l	a0,a1
	beq.b	.easy
.getnext:
	move.l	(a0)+,d0
	beq.b	.hard
	move.l	d0,d1
	bclr	#31,d0
	cmp.l	d0,a1
	beq.b	.foundit
	bclr	#31,d1
	beq.b	.getnext
	move.l	d1,a0
	bra.b	.getnext
.foundit:
	btst	#31,d1
	beq.b	.hard	;This case is very unlikely
	move.l	($30,a4),(-4,a0)
	bra.b	.hard

.easy:
	move.l	($30,a4),(KickTagPtr,a6)
.hard:
	SYS	SumKickData
	move.l	d0,(KickCheckSum,a6)

	lea	(OhTenFlag,pc),a0
	tst.w	(a0)
	beq.b	.skip
	SYS	SuperState
	sub.l	a2,a2
	dc.l	$4E7BA801
	bsr	MyUserState
.skip:
	move.l	(NMI-chw.msg,a4),($7c)

	bsr	lbC00046A	;free memory
	pea	(ROMCrackkille.MSG)
	bra	lbC000460

lbC00022A:
	movea.l	(4),a6

;Check for the presence of a 68010 or higher
	lea	(OhTenFlag,pc),a0
	move.w	(AttnFlags,a6),(a0)

	move.l	(KickTagPtr,a6),d0
	beq.b	lbC00024E
.l1:
	movea.l	d0,a0
.loop:
	move.l	(a0)+,d0
	beq.b	.noproblem
	bpl.b	.cont
	bclr	#31,d0
	bra.b	.l1

.cont:
	move.l	d0,a3
	cmpi.l	#'CHW!',(-$34,a3)
	beq	lbC0001D0
	bra.b	.loop

.noproblem:
lbC00024E:

lbC00025E:
	move.l	($14,a4),d4
	clr.l	($14,a4)
	move.l	($1C,a4),d5
	clr.l	($1C,a4)
	move.l	($24,a4),d6
	clr.l	($24,a4)
lbC000276:
	bsr	lbC00046A
	tst.b	d3
	beq.b	lbC00028A
	movea.l	(4,a5),a0
	bsr	lbC0004D4
	move.l	d0,d4
	bra.b	lbC0002A8

lbC00028A:
	move.l	d4,-(sp)
	move.l	($18,a4),-(sp)
	pea	(WhereshallIpu.MSG)
	bsr	lbC000520
	adda.w	#12,sp
	bsr	lbC0004B4
	move.l	d4,d0
	bsr	lbC0004D2
lbC0002A8:
	bclr	#0,d0
	move.l	d0,d2
	bmi.b	lbC00028A
	movea.l	d2,a1
	move.l	($18,a4),d0
	movea.l	(4),a6
	jsr	(_LVOAllocAbs,a6)
	move.l	d0,($14,a4)
	bne.b	lbC0002D4
	move.l	d2,-(sp)
	pea	(Theresnofreem.MSG)
	bsr	lbC000520
	addq.l	#8,sp
	bra.b	lbC00028A

lbC0002D4:

;Relocate adr in d0
;For assembler

	movem.l	d0-d7/a0-a6,-(sp)
	move.l	d0,d1
	lea	(chw.msg,pc),a0
	move.l	a0,d0
	jsr	Relocate
myreloc3	equ	*-4
	movem.l	(sp)+,d0-d7/a0-a6

	move.l	d2,d4
	tst.b	d3
	beq.b	lbC0002E6
	movea.l	(8,a5),a0
	bsr	lbC0004D4
	move.l	d0,d5
	bra.b	lbC000304

lbC0002E6:
	move.l	d5,-(sp)
	move.l	($20,a4),-(sp)
	pea	(VideoRAMldbyt.MSG)
	bsr	lbC000520
	adda.w	#12,sp
	bsr	lbC0004B4
	move.l	d5,d0
	bsr	lbC0004D2
lbC000304:
	bclr	#0,d0
	move.l	d0,d2
	bmi.b	lbC0002E6
	movea.l	d2,a1
	movea.l	(4),a6
	jsr	(_LVOTypeOfMem,a6)
	andi.l	#2,d0
	bne.b	lbC00032E
	move.l	d2,-(sp)
	pea	(HeytheresnoCH.MSG)
	bsr	lbC000520
	addq.w	#8,sp
	bra.b	lbC0002E6

lbC00032E:
	movea.l	d2,a1
	move.l	($20,a4),d0
	movea.l	(4),a6
	jsr	(_LVOAllocAbs,a6)
	move.l	d0,($1C,a4)
	bne.b	lbC000352
	move.l	d2,-(sp)
	pea	(Theresnofreem.MSG)
	bsr	lbC000520
	addq.l	#8,sp
	bra.b	lbC0002E6

lbC000352:
	move.l	d2,d5
	tst.b	d3
	beq.b	lbC000364
	movea.l	(12,a5),a0
	bsr	lbC0004D4
	move.l	d0,d6
	bra.b	lbC000382

lbC000364:
	move.l	d6,-(sp)
	move.l	($28,a4),-(sp)
	pea	(Workspaceldby.MSG)
	bsr	lbC000520
	adda.w	#12,sp
	bsr	lbC0004B4
	move.l	d6,d0
	bsr	lbC0004D2
lbC000382:
	bclr	#0,d0
	move.l	d0,d2
	bmi.b	lbC000364
	movea.l	d2,a1
	move.l	($28,a4),d0
	movea.l	(4),a6
	jsr	(_LVOAllocAbs,a6)
	move.l	d0,($24,a4)
	bne.b	lbC0003AE
	move.l	d2,-(sp)
	pea	(Theresnofreem.MSG)
	bsr	lbC000520
	addq.l	#8,sp
	bra.b	lbC000364

lbC0003AE:

;Clear Workspace area

	move.l	d2,a0	;address
	move.l	($28,a4),d0	;length
..	clr.b	(a0)+
	subq.l	#1,d0
	bne.b	..

	move.l	d2,d6
	tst.b	d3
	bne.b	lbC0003E8
	movem.l	d4-d6,-(sp)
	pea	(Program06lxVi.MSG)
	bsr	lbC000520
	adda.w	#$10,sp
	clr.b	(a2)
	bsr	lbC0004B4
	cmpi.b	#'c',(a2)
	bne.b	lbC0003E0
	bsr	lbC00046A
	pea	(Operationcanc.MSG)
	bra	lbC000460

lbC0003E0:
	cmpi.b	#'y',(a2)
	bne	lbC000276
lbC0003E8:
	movea.l	a4,a0
	movea.l	d4,a1
	move.l	($18,a4),d0
	subq.w	#1,d0
lbC0003F2:
	move.b	(a0)+,(a1)+
	dbra	d0,lbC0003F2

	movea.l	d4,a4
	lea	($4E,a4),a0
	move.l	a0,(14,a4)
	move.l	a0,($42,a4)
	lea	($57,a4),a0
	move.l	a0,($46,a4)
	lea	($34,a4),a0
	move.l	a0,($2C,a4)
	move.l	a0,($36,a4)
	adda.l	($18,a4),a0
	move.l	a0,($3A,a4)
	lea	(kickstart-chw.msg,a4),a0
	move.l	a0,($4A,a4)
	movea.l	(4),a6
	lea	(DebugVector-CHW.MSG,a4),a0
	move.l	a0,d0
	movea.w	#_LVODebug,a0
	movea.l	a6,a1
	jsr	(_LVOSetFunction,a6)
	movea.l	(4),a6

	lea	(4,a4),a0
	move.l	(KickMemPtr,a6),(a0)	;chain
	move.l	a0,(KickMemPtr,a6) 

	lea	($2C,a4),a0
	move.l	(KickTagPtr,a6),(4,a0)
	beq.b	.NoChain
	bset	#7,(4,a0)
.NoChain:
	move.l	a0,(KickTagPtr,a6) 

	jsr	(_LVOSumKickData,a6)
	move.l	d0,(KickCheckSum,a6)

	jsr	(myreset-chw.msg,a4)

	tst.w	(OhTenFlag-chw.msg,a4)
	bne.b	.ok
	pea	(SomewhatOK.msg)
	bra.b	.somewhatOK
.ok:
	pea	(ROMCrackiniti.MSG)
.somewhatOK:
lbC000460:
	bsr	lbC000520
	moveq	#0,d0
	bra	lbC000174

;Free VBRCrack memory (that's been AllocAbs'ed)

lbC00046A:
	move.l	($14,a4),d0
	beq.b	lbC000482
	movea.l	d0,a1
	move.l	($18,a4),d0
	movea.l	(4),a6
	jsr	(_LVOFreeMem,a6)
	clr.l	($14,a4)
lbC000482:
	move.l	($1C,a4),d0
	beq.b	lbC00049A
	movea.l	d0,a1
	move.l	($20,a4),d0
	movea.l	(4),a6
	jsr	(_LVOFreeMem,a6)
	clr.l	($1C,a4)
lbC00049A:
	move.l	($24,a4),d0
	beq.b	lbC0004B2
	movea.l	d0,a1
	move.l	($28,a4),d0
	movea.l	(4),a6
	jsr	(_LVOFreeMem,a6)
	clr.l	($24,a4)
lbC0004B2:
	rts

lbC0004B4:
	movem.l	d2/d3,-(sp)
	move.l	(StdInput),d1
	move.l	a2,d2
	moveq	#$20,d3
	movea.l	(DosBase),a6
	jsr	(_LVORead,a6)
	movem.l	(sp)+,d2/d3
	rts

lbC0004D2:
	movea.l	a2,a0
lbC0004D4:
	tst.b	(a0)
	beq.b	lbC00050A
	cmpi.b	#10,(a0)
	beq.b	lbC00050A
	moveq	#0,d0
lbC0004E0:
	move.b	(a0)+,d1
	cmpi.b	#'$',d1
	beq.b	lbC0004E0
	cmpi.b	#' ',d1
	ble.b	lbC00050A
	cmpi.b	#'A',d1
	blt.b	lbC0004FA
	subi.b	#'7',d1
	bra.b	lbC0004FE

lbC0004FA:
	subi.b	#'0',d1
lbC0004FE:
	andi.b	#15,d1
	lsl.l	#4,d0
	or.b	d1,d0
	bra.b	lbC0004E0

	moveq	#-1,d0
lbC00050A:
	rts

	move.l	a3,-(sp)
	movea.l	(8,sp),a3
	movea.l	(12,sp),a0
	lea	($10,sp),a1
	bsr.b	lbC000554
	movea.l	(sp)+,a3
	rts

lbC000520:
	movea.l	(4,sp),a0
	lea	(8,sp),a1
	movem.l	d2/d3/a3/a6,-(sp)
	lea	(-$100,sp),sp
	movea.l	sp,a3
	bsr.b	lbC000554
	move.l	d0,d3
	beq.b	lbC00054A
	move.l	(StdOutput),d1
	move.l	a3,d2
	movea.l	(DosBase),a6
	jsr	(_LVOWrite,a6)
lbC00054A:
	lea	($100,sp),sp
	movem.l	(sp)+,d2/d3/a3/a6
	rts

lbC000554:
	movem.l	a2/a3/a6,-(sp)
	lea	(lbC000574,pc),a2
	movea.l	(4),a6

;$fc2124 in 1.3
	jsr	(_LVORawDoFmt,a6)
	moveq	#-1,d0
lbC000566:
	tst.b	(a3)+
	dbeq	d0,lbC000566

	not.l	d0
	movem.l	(sp)+,a2/a3/a6
	rts

lbC000574:
	move.b	d0,(a3)+
	rts

;Start of resident RomCrack code

CHW.MSG:
	db	'CHW!',0,0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	10
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	3
lbL00058C:
	dl	$D0000
	dl	TheEnd-CHW.MSG
lbL000594:
BitmapPtr:
	dl	$E0000
	dl	$5000
lbL00059C:
GlobalPtr:
	dl	$F0000
datasize:
	dl	MyExtensions
	dl	0
	dl	0
lbL0005AC:
	dw	$4AFC
	dl	0
	dl	0
	db	1	;RT_FLAGS
	db	1	;RT_VERSION
	db	9	;RT_TYPE
	db	90	;RT_PRI
	dl	0	;RT_NAME
	dl	0	;RT_IDSTRING
	dl	0	;RT_INIT

	dc.b	'VBRMon',0
	dc.b	'VBRMon V1.04 (not for distribution)',$a,0
	even

kickstart:
	bra.b	myreset

OhTenFlag:	dc.w	0
NMI:	dc.l	0
MyRTE:	rte

;********************************
;My equates
;********************************

NumLines	equ	30	;number of command lines to remember

;********************************
;My data area extension structure
;********************************

StackSize	equ	4096

	setso	$1b6a
Vectors:	soval
	setso	$1B6A+1024
MyData:	soval
ThisHuntList:	so.b	30
HuntList:	so.l	36
OldNMI:	so.l	1
MainSP:	so.l	1
MySP:	so.l	1
MyIntenar:	so.w	1
MyDmaconr:	so.w	1
Fire:	so.b	1
VirtCount:	so.b	1
GuruTrapFlag:	so.b	1
NotOff:	so.b	1
ExitModFlag:	so.b	1
MyPad:	so.b	1	;for word alignment

;The following is used by the copper disassembler
VP:	so.l	1
HP:	so.l	1
VM:	so.l	1
HM:	so.l	1

HistoryPtr:	so.w	1
ViewHistoryPtr	so.w	1
CmdHistory:	so.b	80*NumLines	;offset $203E
MyStack:	so.b	StackSize
MyExtensions:	soval

;Debug vector entry point

DebugVector:
lbC0005F6:
	move.l	($80).w,-(sp)
	push	a0
	lea	(DirectHandler,pc),a0
	move.l	a0,($80).w
	pop	a0
	trap	#0
ReturnAdr:
	move.l	(sp)+,($80).w
	rts

;	lea	(Debug.MSG,pc),a0
;	bra	lbC000608

;Reset entry point
;Rather than entering RomCrack, all we want to do is set up the VBR, then
;leave...

myreset:
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	(GlobalPtr,pc),a2

;Put the system into ntsc or pal...
	lea	(VideoMode,pc),a0
	tst.w	(a0)
	bne.b	.ntsc
	move.w	#32,($dff1dc)
	bra.b	.skipntsc
.ntsc:
	move.w	#0,($dff1dc)
.skipntsc:

	clr.b	(GuruTrapFlag,a2)
	add.w	#$1b6a,a2
	move.l	a2,a3
	move.w	#255,d0
	lea	(Handler,pc),a0
..	move.l	a0,(a3)+
	dbra	d0,..

	lea	(DeciGel,pc),a0
	move.l	a0,($20,a2)
	lea	(DirectHandler,pc),a0
	move.l	a0,($7c,a2)

	move.l	(4).w,a6

	lea	(OhTenFlag,pc),a0
	tst.w	(a0)
	bne.b	.yep

;The user doesn't have a 68010, so set up for a GOMF button instead
	lea	(DirectHandler,pc),a0
	move.l	a0,($7c)
	bra.b	.TheEnd

.yep:
	SYS	SuperState
	dc.l	$4E7BA801
	bsr	MyUserState
;	SYS	UserState
.TheEnd:

;* new code
	cmp.l	#-1,(LastAlert,a6)
	beq.b	.NoGuru
	bsr	DebugVector
.NoGuru:
	movem.l	(sp)+,d0-d7/a0-a6
	rts

MyUserState:
;(The one in ROM is buggy)
	move.l  (sp)+,d1
	move.l  sp,usp
	movea.l d0,sp
	movea.l a5,a0
	lea     mus(pc),a5
	jmp     -$1E(a6)
mus	movea.l a0,a5
	move.l  d1,$02(sp)
	andi.w  #$DFFF,(sp)
	rte

DeciGel:
;Converts move from SR instructions to move from CCR
;Not perfect, but in practice it works fine

	movem.l	D0/A0,-(SP)
	movea.l	(10,SP),A0
	move.w	(A0),D0
	andi.w	#$FFC0,D0
	cmpi.w	#$40C0,D0
	bne.b	lbC00037A
	bset	#1,(A0)
	movem.l	(SP)+,D0/A0
	rte

lbC00037A:
	movem.l	(SP)+,D0/A0
	move.l	($20),-(sp)
	rts

;generic handler
;This amazingly simple piece of code is the heart of this program!

Handler:

;	btst	#5,(_custom+intreqr+1)
;	bne.b	NoHit


	btst	#6,($bfe001)
	beq.b	Hit1
	btst	#5,(_custom+intreqr+1)
	bne.b	Virt
NoHit:
;	and.w	#$0FFF,(6,a7)
	move.l	a0,-(sp)
	move.w	10(a7),a0
	move.l	(a0),-(sp)	
	move.l	4(sp),a0
	rtd	#4

Virt:
	move.l	a5,-(sp)
	move.l	(GlobalPtr,pc),a5
	tst.b	(fire,a5)
	beq.b	EndVirt
	subq.b	#1,(VirtCount,a5)
	bpl.b	EndVirt
	move.b	#2,(VirtCount,a5)

	btst	#0,(fire,a5)
	beq.b	VirtTest1

;Do fire 0 autofire
	bchg	#6,($bfe001)

VirtTest1:
	btst	#1,(fire,a5)
	beq.b	EndVirt

;Do fire 1 autofire
	bchg	#7,($bfe001)

EndVirt:
	move.l	(sp)+,a5
	bra.b	NoHit

Hit1:
	move.w	(_custom+potinp),-(sp)
	move.w	#$FFFE,(_custom+potgo)

;Delay approx. 200us (too small? unneccessarily big? I have no idea)
	movem.l	d0/a0,-(sp)
	move.l	#$bfe001,a0
	move.w	#$46,d0
..	move.b	(a0),(a0)
	dbra	d0,..
	movem.l	(sp)+,d0/a0

	btst	#2,(_custom+potinp)
	beq.b	DH1
	move.w	(sp)+,(_custom+potgo)
	bra	NoHit

DH1:
	addq.w	#2,sp
DirectHandler:
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(_custom+intenar),d7
	move.w	#$7FFF,(_custom+intena)
	movea.l	(GlobalPtr,pc),a5
	lea	($ce,a5),a1
	move.l	sp,a0
	move.w	#60/4-1,d0
..	move.l	(a0)+,(a1)+
	dbra	d0,..

	lea	(OhTenFlag,pc),a2
	move.l	sp,d0
	moveq	#68,d1
	tst.w	(a2)
	bne.b	.skipload
	moveq	#66,d1
.skipload:
	add.l	d1,d0
	move.l	d0,(a1)+
	move.l	usp,a0
	move.l	a0,(a1)+
	move.w	60(a7),(a1)+
	move.l	62(a7),(a1)+	;program counter
	moveq	#0,d0
	move.w	66(a7),d0		;vector
	and.w	#$0FFF,d0
	move.l	d0,a3

	tst.w	(a2)
	bne.b	.skipforce
	lea	(ReturnAdr,pc),a0
	move.w	#$7c,a3
	move.l	62(a7),a1
	cmp.l	a0,a1
	bne.b	.skipforce
	move.w	#$80,a3
.skipforce:
	move.l	(ExecData,pc),a6
;	bra	Hit

;lbC0005FC:
;	move.w	#$120,(_custom+dmacon)
;	lea	(RESET.MSG,pc),a0
;lbC000608:
;	movea.l	(GlobalPtr,pc),a1
;	movem.l	d0-d7/a0-a7,(a1)
;	movea.l	a0,a3
;	movea.l	(4).w,a6
;	lea	(lbC0005F6,pc),a0
;	move.l	a0,d0
;	movea.w	#_LVODebug,a0
;	movea.l	a6,a1
;	jsr	(_LVOSetFunction,a6)
;	lea	(DebugHit,pc),a5
;	jsr	(_LVOSupervisor,a6)
;	movea.l	(GlobalPtr,pc),a1
;	movem.l	(a1),d0-d7/a0-a7
;	rts

;DebugHit:
;	movem.l	d0-d7/a0-a6,-(sp)

;*** RomCrack main entry point
;Note: Must be in supervisor mode first!

Hit:

;Disable the NMI function (to avoid invoking RomCrack multiple times).
	lea	(MyRTE,pc),a0
	move.l	a0,($1be6,a5)
	move.l	($7c),(OldNMI,a5)
	lea	(OhTenFlag,pc),a1
	tst.w	(a1)
	bne.b	.skipthis
	move.l	a0,($7c)
.skipthis:

;Switch into PAL mode (if possible/necessary)
	lea	(VideoMode,pc),a0
	tst.w	(a0)
	bne.b	.SkipIfNTSC
	move.w	#32,($dff1dc)
.SkipIfNTSC:

;	lea	(my.MSG,pc),a3
;lbC000638:
	move.w	#$2700,SR	;disallow interrupts
	move.l	sp,(MySP,a5)
	lea	(MyStack,a5),sp
	add.w	#StackSize,sp

;Save certain CIA registers
	move.b	($bfee01),-(sp)	;CRA
	move.b	($bfe401),-(sp)	;talo
	move.b	($bfe501),-(sp)	;tahi

;Set up CIA regs for keyboard usage
	move.b	#0,($bfee01)	;CRA
	move.b	#$FF,($bfe401)	;talo
	move.b	#$FF,($bfe501)	;tahi
	move.b	#$88,($bfed01)	;int

;Perform a keyboard handshake
	ori.b	#$40,($BFEE01)
	clr.b	($bfec01)
	move.l	#$bfe001,a0
	move.w	#$46,d0
..	move.b	(a0),(a0)
	dbra	d0,..
	andi.b	#$BF,($BFEE01)

	move.l	usp,a0
	move.l	a0,-(sp)
	lea	($DFF000),a4
	move.w	d7,-(sp)	;d7 contains intenar
;	movea.l	(GlobalPtr,pc),a5
	move.w	d7,(MyIntenar,a5)
	move.w	(dmaconr,a4),(MyDmaconr,a5)
;	move.w	d7,(4,a5)
;	move.w	(dmaconr,a4),(4,a5)

;	move.w	(intenar,a4),-(sp)
	move.w	(dmaconr,a4),-(sp)
;	move.w	#$7FFF,(intena,a4)
	move.w	#$01AF,(dmacon,a4)
	bsr	Main	;go to main
	move.w	#$7FFF,d1
	move.w	(sp)+,d0
	bset	#15,d0
	move.w	d1,(dmacon,a4)
	move.w	d0,(dmacon,a4)
	move.w	(sp)+,d0
	bset	#15,d0
	move.w	d1,(intena,a4)
;	move.w	d1,(intreq,a4)
	move.w	d0,(intena,a4)
	movea.l	(sp)+,a0
	move.l	a0,usp

;Restore certain CIA registers
	move.b	(sp)+,($bfe501)	;tahi
	move.b	(sp)+,($bfe401)	;talo
	move.b	(sp)+,($bfee01)	;CRA

	movea.l	(GlobalPtr,pc),a5
	move.l	(MySP,a5),sp
	move.w	#$5200,(_custom+bplcon0)
;	move.l	(GlobalPtr,pc),a2
;	add.w	#$1b6a,a2
;	dc.l	$4E7BA801

;Restore NMI ability
	move.l	(OldNMI,a5),($7c)
	lea	(DirectHandler,pc),a0
	move.l	a0,($1be6,a5)

;Now exit or exit with modify...
	tst.b	(ExitModFlag,a5)
	bne.b	Exitwithmodify
	movem.l	(sp)+,d0-d7/a0-a6
	rte
Exitwithmodify:
	add.w	#60,sp

	move.l	($ce+60,a5),sp	;restore ssp
	move.l	($ce+64,a5),a0
	move.l	a0,usp	;restore user stack pointer

	move.w	($ce+68,a5),sr	;restore statis register
	movem.l	($ce+70,a5),d0	;return PC
	movem.l	d0,-(sp)	;movem does not affect the flags!!
	movem.l	($ce,a5),d0-d7
	movem.l	d0-d7,-(sp)
	movem.l	($ce+32,a5),d0-d6
	movem.l	d0-d6,-(sp)
	movem.l	(sp)+,a0-a6
	movem.l	(sp)+,d0-d7
	rts

Quit:

;Restore system state
	movea.l	(GlobalPtr,pc),a5
	cmp.l	#'SAVE',(a5)
	bne	NoSave
	move.w	#$4000,(_custom+intena)	;ints off!
	move.w	#$7FFF,(_custom+dmacon)
	move.l	($84,a5),($1bd2,a5)
	move.l	($88,a5),($1bd6,a5)
	move.l	($80,a5),($1b7a,a5)
	lea	(4,a5),a4

;Restore memory
	sub.l	a0,a0
	moveq	#3,d0
.RM:
	move.l	(a4)+,a3
	move.w	#(128*1024)/4-1,d1
..
	move.w	(_custom+vhposr),($dff180)
	move.l	(a3)+,(a0)+
	dbra	d1,..
	dbra	d0,.RM

	move.l	(a4)+,(_custom+cop1lc)
	move.w	(_custom+copjmp1),d0	;strobe

	move.l	(a4)+,a0
	move.l	a0,usp
	move.l	(a4)+,sp
	move.w	#0,sr	;user mode
	move.l	(a4)+,a0

	move.w	#$7FFF,d1
	move.w	(a4)+,d0
	bset	#15,d0
	move.w	d1,(_custom+intena)
	move.w	d1,(_custom+intreq)
	move.w	d0,(_custom+intena)
	move.w	(a4)+,d0
	bset	#15,d0
	move.w	d1,(_custom+dmacon)
	move.w	d0,(_custom+dmacon)

	move.b	(a4)+,($bfee01)
	move.b	(a4)+,($bfef01)
	move.b	(a4)+,($bfde00)
	move.b	(a4)+,($bfdf00)

;Check fast mem checksum
;	move.l	#$200000,a1
;	move.l	#$200000/4,d0
;	moveq	#0,d1
;..	add.l	(a1)+,d1
;	subq.l	#1,d0
;	bne.b	..
;	cmp.l	(a4)+,d1
;	beq.b	.ok

;	move.w	#-1,d0
;..	move.w	#$0f00,($dff180)
;	dbra	d0,..

.ok:
	move.b	#$7F,($bfed01)
	move.b	#$8D,($bfed01)	;enable ints

	jmp	(a0)

NoSave:
	lea	(nosave.msg,pc),a0
	sub.l	a1,a1
	bsr	Print
	rts

nosave.msg:
	dc.b	'Sorry, system state not saved. Run BOOTSAVE'
	dc.b	' first.',$a,0
	even

Main:

;Clear workspace

	push	a5
	add.w	#$40,a5
	move.w	#($CE-$41),d0
..	clr.b	(a5)+
	dbra	d0,..
	add.w	#$4a,a5
	move.w	#$1a51,d0
..	clr.b	(a5)+
	dbra	d0,..
	pop	a5

;;Clear more workspace...

;	lea	(SecondSectionToClear,a5),a0
;	move.w	#ClearLen,d0
;..	clr.b	(a0)+
;	subq.w	#1,d0
;	bne.b	..

;Disable sprites
	move.w	#$144,d0
	move.w	#7,d1
.DS	move.w	#0,(a4,d0.w)
	move.w	#0,(2,a4,d0.w)
	addq.w	#8,d0
	dbra	d1,.DS

	st	(chars_in_linebuffer_flag,a5)
	move.w	#$2C81,(diwstrt,a4)
	move.w	#$2CC1,(diwstop,a4)
	move.w	#$3C,(ddfstrt,a4)
	move.w	#$D4,(ddfstop,a4)
	clr.w	(bpl1mod,a4)
	move.w	#$9200,(bplcon0,a4)
	move.w	#0,(color0,a4)
	move.w	#$FFF,(color1,a4)
	move.w	#$8300,(dmacon,a4)	;enable bit plane DMA

	lea	(OhTenFlag,pc),a0
	tst.w	(a0)
	bne.b	.skipvec

	move.l	($10),($80,a5)
	lea	(lbC0008A6,pc),a0
	move.l	a0,($10)
	move.l	($68),($84,a5)
	lea	(lbC000F6C,pc),a0
	move.l	a0,($68)
	move.l	($6C),($88,a5)
	lea	(lbC000ECE,pc),a0
	move.l	a0,($6C)
	bra.b	.skipvec1

.skipvec:
	move.l	($1b7a,a5),($80,a5)
	lea	(lbC0008A6,pc),a0
	move.l	a0,($1b7a,a5)
	move.l	($1bd2,a5),($84,a5)
	lea	(lbC000F6C,pc),a0
	move.l	a0,($1bd2,a5)
	move.l	($1bd6,a5),($88,a5)
	lea	(lbC000ECE,pc),a0
	move.l	a0,($1bd6,a5)

.skipvec1:
	move.w	#$C028,(intena,a4)	;enable ports (2) and VBL (3)
	move.w	#$2000,SR

	bsr	lbC000CA0
	lea	(ROMCRACKGAMMA.MSG,pc),a0
	bsr	lbC000A8C
	bsr	lbC000A9C
	move.w	#0,(cursor_x_position,a5)
	move.w	#$1E,(cursor_y_position,a5)
	bsr	lbC000A9C
	move.w	#0,(cursor_x_position,a5)
	move.w	#$1F,(cursor_y_position,a5)
	lea	(PresstheHELPk.MSG,pc),a0
	bsr	lbC000A8C

	bsr	lbC000C7E
	bsr	lbC000C02
	move.w	#$1F40,d0
	moveq	#2,d2
	move.w	(AttnFlags,a6),d1
	btst	#AFB_68020,d1
	bne.b	lbC000780
	moveq	#1,d2
	btst	#AFB_68010,d1
	bne.b	lbC00077C
	moveq	#0,d2
lbC00077C:
	move.w	#$BB8,d0
lbC000780:
	move.w	d0,($9E,a5)
	move.w	d2,-(sp)
	move.l	(GlobalPtr,pc),-(sp)
	move.l	(BitmapPtr,pc),-(sp)
	move.l	(lbL00058C,pc),-(sp)
	pea	(ROMCracksmemo.MSG,pc)
	bsr	PrintLong
	adda.w	#$12,sp

	moveq	#-1,d0
	move.l	(LastAlert,a6),d2
	move.l	(LastAlert+4,a6),d3
	move.l	d0,(LastAlert,a6)
	cmp.l	d0,d2
	beq.b	lbC0007E6
;	bra.b	lbC0007E6
	movea.l	d3,a0
;	move.l	(10,a0),-(sp)
;	move.l	d3,-(sp)
	lea	(lbL0015E6,pc),a1
lbC0007BC:
	cmp.l	(a1)+,d2
	beq.b	lbC0007CA
	tst.l	(a1)+
	bne.b	lbC0007BC
;	pea	(Wellahem.MSG,pc)
;	bra.b	lbC0007D4
	bra.b	NoGuru

lbC0007CA:
	movem.l	d0-d7,-(sp)
	movem.l	($180),d0-d7
	movem.l	d0-d7,($ce,a5)
	movem.l	($1A0),d0-d7
	movem.l	d0-d7,($ee,a5)
	movem.l	(sp)+,d0-d7

	move.l	(10,a0),-(sp)
	move.l	d3,-(sp)
	move.l	(a1),d0
	lea	(lbL0015E6,pc),a0
	pea	(a0,d0.l)
lbC0007D4:
	move.l	d3,-(sp)
	move.l	d2,-(sp)
	pea	(GuruMeditatio.MSG,pc)
	bsr	PrintLong
	adda.w	#$18,sp
	bra.b	lbC0007F2

;Go here if no gurus
NoGuru:
lbC0007E6:
;	pea	(a3)
	move.l	a3,-(sp)
	pea	(NogurusROMCra.MSG,pc)
	bsr	PrintLong
	addq.w	#8,sp
lbC0007F2:
	bsr	lbC000A4C
	bsr	lbC0009E2

	move.l	($114,a5),a3	;start with program counter as
				;current address
;VBRCrack main loop

lbC000800:
	tst.b	(chars_in_linebuffer_flag,a5)
	beq.b	lbC00080A
	bsr	PrintPeriod	;print a '.'
lbC00080A:
lbC000814:
	move.w	(line_buffer_ptr,a5),d1
	bsr	_GetChar
	beq.b	lbC000800

	cmpi.b	#' ',d0
	beq.b	lbC000800
	cmpi.b	#'.',d0
	beq.b	lbC000800

	lea	(Commands,pc),a0
	lea	(base,pc),a1
	bra.b	.Entry
.CmdMainLoop:
	move.w	d1,(line_buffer_ptr,a5)
.Cmdinnerloop:
	tst.b	(chars_in_linebuffer_flag,a5)
	bne.b	.miss1

	bsr	_GetChar
	cmp.b	#' ',d0
	beq.b	.miss
.Entry:
	bsr	Uppercase
	move.b	(a0)+,d2
	cmp.b	d0,d2
	bne.b	.miss
	tst.b	(a0)	;end of match string?
	beq.b	.Hit
	bra.b	.Cmdinnerloop

.miss1:
	clr.b	(chars_in_linebuffer_flag,a5)
.miss:
	tst.b	(a0)+
	bne.b	.miss
	bsr	MakeEven
	addq.l	#2,a0	;skip over offset-address
	tst.b	(a0)	;end of command table?
	bne.b	.CmdMainLoop
	bra	EndCmdSearch

.Hit:
	addq.l	#1,a0
	bsr	MakeEven
	adda.w	(a0)+,a1

	movem.l	d0-d7/a0-a2/a4-a6,-(sp)
	move.l	sp,(MainSP,a5)
	jsr	(a1)
ReturnToMain:
	movem.l	(sp)+,d0-d7/a0-a2/a4-a6
	lea	(_bflag,pc),a0
	clr.b	(a0)
	bra	lbC000800

MakeEven:
	push	d0
	move.l	a0,d0
	btst	#0,d0
	beq.b	.skip
	addq.l	#1,a0
.skip:
	pop	d0
	rts

EndCmdSearch:
lbC000836:
	bsr	lbC000AC6
	bsr	lbC000AAE
	st	(chars_in_linebuffer_flag,a5)
	bra	lbC000800

Commands:
lbL000844:

;Note: Long commands (i.e. supersets of other commands) must go first.
;Commands may be any length.

	dc.b	'RESTORE',0
	even
	dc.w	RestoreState-base

	dc.b	'SAVE',0
	even
	dc.w	SaveState-base

	dc.b	'GURU',0
	even
	dc.w	GuruTrapping-base

	dc.b	'FIRE',0
	even
	dc.w	Autofire-base

	dc.b	'INFO',0
	even
	dc.w	Info-base

	dc.b	'XMOD',0
	even
	dc.w	ExitMod-base

	dc.b	'TC',0
	even
	dc.w	ZCompare-base

	dc.b	':',0
	dc.w	MemMod-base

	dc.b	'J',0
	dc.w	jump-base

	dc.b	'M',0
	dc.w	MemDump-base

	dc.b	'D',0
	dc.w	Disassemble-base

	dc.b	'P',0
	dc.w	PrintToggle-base

	dc.b	'R',0
	dc.w	RegDump-base

	dc.b	'Q',0
	dc.w	Quit-base

	dc.b	'T',0
	dc.w	Transfer-base

	dc.b	'X',0
	dc.w	Exit-base

	dc.b	'E',0
	dc.w	Install-base

	dc.b	'N',0
	dc.w	togglentsc-base

	dc.b	'H',0
	dc.w	Hunt-base

	dc.b	'L',0
	dc.w	ListHunts-base

	dc.b	'?',0
	dc.w	Calculate-base

	dc.b	'C',0
	dc.w	Compare-base

	dc.b	'F',0
	dc.w	Fill-base

	dc.b	'B',0
	dc.w	SetBase-base

	dc.b	'A',0
	dc.w	StartAssembler-base

	dc.b	'S',0
	dc.w	FindTrack-base

	dc.b	'U',0
	dc.w	Unassemble-base

	dc.b	'O',0
	dc.w	HuntPC-base

	dw	0

base:

SaveState:

 comment |

Format of state:

D0-D7	(long)
A0-A6	(long)
SSP	(long)
USP	(long)
SR	(word)
PC	(long)
INTENAR	(word)
DMACONR	(word)

|

	bsr	GetArg
	bcs.b	.end
	move.l	d0,a1
	lea	($ce,a5),a0
	move.w	#73,d0
..	move.b	(a0)+,(a1)+
	dbra	d0,..
	move.w	(MyIntenar,a5),(a1)+
	move.w	(MyDmaconr,a5),(a1)+
.end:
	rts

RestoreState:
	bsr	GetArg
	bcs.b	.end
	move.l	d0,a1
	lea	($ce,a5),a0
	move.w	#73,d0
..	move.b	(a1)+,(a0)+
	dbra	d0,..
	move.w	(a1)+,(MyIntenar,a5)
	move.w	(a1)+,(MyDmaconr,a5)
.end:
	rts

GuruTrapping:
	not.b	(GuruTrapFlag,a5)
	beq.b	.off
	lea	(DirectHandler,pc),a2
	lea	(GuruTrapOn,pc),a0
.Guru1:
	bsr.b	.GuruSub
	rts
.off:
	lea	(Handler,pc),a2
	lea	(GuruTrapOff,pc),a0
	bra.b	.Guru1

.GuruSub:
	sub.l	a1,a1
	lea	(OhTenFlag,pc),a4
	tst.w	(a4)
	beq.b	.SkipVBR
	lea	(Vectors,a5),a1
.SkipVBR:
	move.l	a2,(3*4,a1)	;address error
	move.l	a2,(4*4,a1)	;illegal instruction
	move.l	a2,(5*4,a1)	;divide by zero
	move.l	a2,(10*4,a1)	;line 1010 emulator
	move.l	a2,(11*4,a1)	;line 1111 emulator
	bsr	Print
	rts

GuruTrapOn:	dc.b	'Guru trapping now ON.',$a,0
GuruTrapOff:	dc.b	'Guru trapping now OFF.',$a,0
	even

HuntPC:
	bsr	GetArg
	bcs	HPC_NoArg
	move.l	d0,d7

	move.l	d7,d4
	move.l	d7,d5
	sub.l	#32772,d4
	bcc.b	.ok
	moveq	#0,d4
.ok:
	add.l	#32772,d5

	bclr	#0,d4
	bclr	#0,d5
	move.l	d4,a1
	move.l	d5,a2

	lea	(HuntList,a5),a4
	moveq	#36,d3	;hunt list size

EL_PCRELH_Loop1:
	moveq	#9,d6

EL_PCRELH_Loop:
	cmp.l	a2,a1
	bhi	EL_NH_Finished
	move.w	(a1)+,d0
	move.w	d0,d1
	and.w	#$001f,d1
	cmp.w	#$001a,d1
	beq	EL_PCRELH_FoundABranch

;Not a PC-relative reference. Maybe its a branch reference.
	move.w	d0,d1
	and.w	#$f000,d1
	cmp.w	#$6000,d1
	bne	EL_PCRELH_Loop

;Yes, it's a branch reference.

	tst.b	d0
	beq	EL_RELH_LongBranch

	move.b	d0,d1
	ext.w	d1
	ext.l	d1
	add.l	a1,d1
	cmp.l	d1,d7
	bne	EL_PCRELH_Loop
	bra	EL_PCRELH_FoundOne

EL_RELH_LongBranch:
EL_PCRELH_FoundABranch:
	move.w	(a1),d1
	ext.l	d1
	add.l	a1,d1
	cmp.l	d1,d7
	bne	EL_PCRELH_Loop

EL_PCRELH_FoundOne:

;Found a hit at address (-2,a1) - print it
	move.l	a1,d0
	subq.l	#2,d0

	subq.l	#1,d3
	bmi.b	.SkipHL
	move.l	d0,(a4)+
.SkipHL:

	move.l	d0,-(sp)
	pea	(Format,pc)
	bsr	PrintLong
	addq.w	#8,sp
	subq.l	#1,d6
	beq.b	EL_PCRELH_Loop1
	lea	(MySpace,pc),a0
	bsr	Print
	bra	EL_PCRELH_Loop

EL_NH_Finished:
	lea	(MyCR,pc),a0
	bsr	Print

HPC_NoArg:
	rts

Autofire:
	bsr	GetArg
	bcs.b	.NoArg
	tst.l	d0
	beq.b	.Port0
	subq.l	#1,d0
	beq.b	.Port1
.NoArg:
;Perhaps display current status if nothing given as arg?
	and.b	#$3F,($bfe201)
	clr.b	(fire,a5)
	lea	(fire.msg,pc),a0
	bsr	Print
	rts
.Port0:
	or.b	#$40,($bfe201)
	bset	#0,(fire,a5)
	rts
.Port1:
	or.b	#$80,($bfe201)
	bset	#1,(fire,a5)
	rts

fire.msg:
	dc.b	'Autofire is now turned OFF.',$a,0
	even

*
*	FindTrack -- By Daniel Zenchelsky
*				1/1/91
*

ciabtblo	EQU $bfd600	;Timer B low
ciabtbhi	EQU $bfd700	;Timer B high
ciabicr 	EQU $bfdd00	;Interrupt control register
ciabcrb 	EQU $bfdf00	;Timer B control

FindTrack:

; Drive in d0 on entry
; Returns current track # in d0 on exit

	bsr	GetArg
	bcs	.EndFT
	lea	(NoDrive.msg,pc),a0
	moveq	#0,d1
	cmp.l	d1,d0
	bcs	.NoDrive
	moveq	#3,d1
	cmp.l	d1,d0
	bhi	.NoDrive	
	move.l	d0,d7

	lea	(FTFmt,pc),a0

	move.b ($BFD100),-(SP)
	move.b (ciabcrb),-(SP)
	move.b (ciabtbhi),-(SP)
	move.b (ciabtblo),-(SP)

	move.l d0,d2

	bsr setup_delay

;;	move.b #$7D,($BFD100)	; All drives disabled -- motor on
	or.b #$78,($BFD100)	;Deselect all drives

;	bsr.b delay

	addq.l #3,d2		; set d0 to proper bit for drive
;	move.l d2,-(SP)		; save it for later

	bclr.b d2,($BFD100)		; select drive
	bset.b #1,($BFD100)		; set direction to outward (towards 0)

	moveq	#0,d2		; clear counter

1$:	btst #4,($BFE001)		; check if we're at track 0
	beq.b 2$			; exit if we are

	bset.b #0,($bfd100)
	bclr.b #0,($BFD100)		; pulse disk step
	bset.b #0,($BFD100)

	bsr delay4		; delay 4 milliseconds

	addq.l #1,d2		; add one to counter
	cmp.w #90,d2
	bne.b 1$
	lea	(NoDrive.msg,pc),a0
	bra.b	.Restore

2$:	moveq #5,d3
3$:	bsr delay3		; delay 18 milliseconds
	dbra d3,3$

	bclr #1,($BFD100)		; set direction to inward

	move.l d2,d3		; init counter
	beq.b 5$			; bail out if we're at track 0

	subq.l #1,d3

4$:	bclr #0,($BFD100)		; pulse disk step
	bset #0,($BFD100)

	bsr delay3		; delay 3 milliseconds
	dbra d3,4$		; loop

5$:	move.l d2,d0		; set return value to track #

.Restore:
;	move.b #$FD,($BFD100)	; All drives disabled -- motor off
;	move.l (SP)+,d1		; get saved value
;	bclr.b d1,($BFD100)		; select drive
	move.b (SP)+,(ciabtblo)
	move.b (SP)+,(ciabtbhi)
	move.b (SP)+,(ciabcrb)
	move.b (SP)+,($BFD100)

.NoDrive:
	move.l	d0,-(sp)
	move.l	d7,-(sp)
	pea	(a0)
	bsr	PrintLong
	add.w	#12,sp
.EndFT:
	rts

FTFmt:	dc.b	'Drive %ld currently on track %ld.',$a,0
	even
NoDrive.msg:	dc.b	'No such drive!',$a,0
	even

; ------------------------------

setup_delay:

;----Setup, only do once
;----This sets timer B to one-shot mode.

	move.b	(ciabcrb),d0	    ;Set control register B on CIAB
	andi.b	#%11000000,d0	    ;Don't trash the 60/50Hz flag
	ori.b	#%00001000,d0	    ;or serial direction bits
	move.b	d0,(ciabcrb)
	move.b	(ciabicr),d0
;	move.b	#%01111111,(ciabicr)  ;Clear all 8520 interrupts
	rts

delay3:

;----Set time (low byte THEN high byte)
;----And the low order with $ff
;----Shift the high order by 8
	move.b	#(2148&255),(ciabtblo)
	move.b	#(2148>>8),(ciabtbhi)

;----Wait for the timer to count down
busy_loop:
	btst.b	#1,(ciabicr)	    ;Wait for timer expired flag
	beq.b	busy_loop
	rts

delay4:
	move.b	#(2864&255),(ciabtblo)
	move.b	#(2864>>8),(ciabtbhi)
	bra.b	busy_loop


ZCompare:
;Special triple compare (used for finding cheats)
;First, grab the memory range
	push	a3
	bsr	GetArg
	bcs.b	.NoArg
	movea.l	d0,a2	;mem1a
	bsr	GetArg
	bcs.b	.NoArg
	move.l	d0,a3	;mem1b
	cmp.l	a2,a3
	bls.b	.NoArg
	sub.l	a2,a3
	move.l	a3,d7
	bsr	GetArg
	bcs.b	.NoArg
	move.l	d0,a3	;mem2	
	bsr	GetArg
	bcs.b	.NoArg
	move.l	d0,a4	;mem3

.StartSearch1:
	moveq	#4,d4
.StartSearch:
	subq.l	#1,d7
	bmi.b	.EndSearch
	cmp.b	(a2)+,(a3)+
	beq.b	.L1
.L2:
	addq.w	#1,a4
	bra.b	.StartSearch
.L1:
	move.b	(-1,a3),d0
	cmp.b	(a4),d0
	beq.b	.L2

;We have a match at a4
	moveq	#0,d1
	move.b	(a4),d1
	move.l	d1,-(sp)
	move.b	d0,d1
	move.l	d1,-(sp)
	move.l	a4,-(sp)
	addq.w	#1,a4
	pea	(ZFormat,pc)
	bsr	PrintLong
	add.w	#16,sp
	subq.l	#1,d4
	bne.b	.StartSearch
	lea	(MyCR,pc),a0
	bsr	Print
	bra.b	.StartSearch1

.EndSearch:
	lea	(MyCR,pc),a0
	bsr	Print

.NoArg:
	pop	a3
	rts

ZFormat:
	dc.b	'%08lx:%02lx -> %02lx ',0
	even

Info:
	lea	(Info.msg,pc),a0
	bsr	Print
	rts

SetBase:
	lea	(_dformat,pc),a0
	move.b	(a0),d7
	move.b	#10,(a0)
	bsr	GetArg
	bcs.b	.ShowBase
	move.b	d0,(a0)
	rts

.ShowBase:
	move.b	d7,(a0)
	moveq	#0,d0
	move.b	(_dformat,pc),d0
	move.l	d0,-(sp)
	pea	(SB.msg,pc)
	bsr	PrintLong
	addq.l	#8,sp
	rts

SB.msg:	dc.b	'Current base is %ld.',$a,0
	even

Compare:
;Compare one memory block to another, printing any differences

;First, grab the memory range
	push	a3
	bsr	GetArg
	bcs.b	.NoArg
	movea.l	d0,a2	;mem1
	bsr	GetArg
	bcs.b	.NoArg
	move.l	d0,a3	;mem2
	bsr	GetArg
	bcs.b	.NoArg
	move.l	d0,a4	;mem3	

.StartSearch1:
	moveq	#9,d4
.StartSearch:
	move.l	a2,a0
.ContSearch:
	cmp.l	a2,a3
	bcs.b	.EndSearch
	cmp.b	(a2)+,(a4)+
	beq.b	.StartSearch

;We have a match at a0
	move.l	a0,-(sp)
	pea	(Format,pc)
	bsr	PrintLong
	addq.w	#8,sp
	subq.l	#1,d4
	beq.b	.StartSearch1
	lea	(MySpace,pc),a0
	bsr	Print
	bra.b	.StartSearch

.EndSearch:
;	cmp.l	#36,d5
;	beq.b	.NoArg
	lea	(MyCR,pc),a0
	bsr	Print

.NoArg:
	pop	a3
	rts

Fill:
;First, grab the memory range
	push	a3
	bsr	GetArg
	bcs.b	.NoArg
	movea.l	d0,a2	;mem1
	bsr	GetArg
	bcs.b	.NoArg
	move.l	d0,a3	;mem2
	lea	(ThisHuntList,a5),a4
	move.l	a4,a6
	moveq	#29,d2
	moveq	#0,d7	;number of chars to compare
	bsr	GetArg
	bcs.b	.NoArg
	bra.b	.Enter
.GetByte:	bsr	GetArg
	bcs.b	.EndList
	addq.l	#1,d7
.Enter:
	move.b	d0,(a4)+
	dbra	d2,.GetByte
.EndList:
.StartSearch1:
	moveq	#9,d4
.StartSearch:
	move.l	a6,a4
	move.l	d7,d6
	move.l	a2,a0
.ContSearch:
	cmp.l	a2,a3
	bcs.b	.EndSearch
	move.b	(a4)+,(a2)+
	dbra	d6,.ContSearch
	bra.b	.StartSearch

.EndSearch:
.NoArg:
	pop	a3
	rts

Calculate:
	bsr	GetArg
	bcs.b	.EndCalc

;Print hex and decimal versions
	move.l	d0,-(sp)
	move.l	d0,-(sp)
	pea	(CalcFmt,pc)
	bsr	PrintLong
	lea	(12,sp),sp

;Print binary version
	move.l	d0,d1
	moveq	#31,d2
.binloop:
	move.b	#'0',d0
	lsl.l	#1,d1
	bcc.b	.skip1
	move.b	#'1',d0
.skip1:	bsr	PrintChar
	dbra	d2,.binloop
	lea	(MyCR,pc),a0
	bsr	Print

;Soak up excess args
..	bsr	GetArg
	bcc.b	..
.EndCalc:
	rts

CalcFmt:
	dc.b	'Hex: $%08lx',$a
CalcFmt1:
	dc.b	'Dec: %ld',$a
	dc.b	'Bin: %%'
	dc.b	0
	even

Hunt:
;Search a memory range for a series of bytes
;A3 contains the current address (not used)

;First, grab the memory range
	push	a3
	bsr	GetArg
	bcs.b	.NoArg
	movea.l	d0,a2
	bsr	GetArg
	bcs.b	.NoArg
	move.l	d0,a3
	lea	(ThisHuntList,a5),a4
	move.l	a4,a6
	moveq	#29,d2
	moveq	#0,d7	;number of chars to compare
	bsr	GetArg
	bcs.b	.NoArg
	bra.b	.Enter
.GetByte:	bsr	GetArg
	bcs.b	.EndList
	addq.l	#1,d7
.Enter:
	move.b	d0,(a4)+
	dbra	d2,.GetByte
.EndList:
	lea	(HuntList,a5),a1
	moveq	#36,d5	;hunt list size
.StartSearch1:
	moveq	#9,d4
.StartSearch:
	move.l	a2,a0
	move.l	a6,a4
	move.l	d7,d6
.ContSearch:
	cmp.l	a2,a3
	bcs.b	.EndSearch
	cmp.b	(a4)+,(a2)+
	bne.b	.AbortSearch	;was .StartSearch
	dbra	d6,.ContSearch

;We have a match at a0
	subq.l	#1,d5
	bmi.b	.SkipHL
	move.l	a0,(a1)+
.SkipHL:
	move.l	a0,-(sp)
	pea	(Format,pc)
	bsr	PrintLong
	addq.w	#8,sp
	subq.l	#1,d4
	beq.b	.StartSearch1
	lea	(MySpace,pc),a0
	bsr	Print
	bra.b	.StartSearch

.AbortSearch:
	move.l	a0,a2
	addq.l	#1,a2
	bra.b	.StartSearch

.EndSearch:
	cmp.l	#36,d5
	beq.b	.NoArg
	lea	(MyCR,pc),a0
	bsr	Print

.NoArg:
	pop	a3
Done:
	rts

Format:
	dc.b	'%08lx',0
MySpace:	dc.b	' ',0
MyCR:	dc.b	$a,0
	even

ListHunts:
	lea	(HuntList,a5),a1
	moveq	#36,d0
.Loop:
	moveq	#9,d1
.Loop1:
	move.l	(a1)+,-(sp)
	pea	(Format,pc)
	bsr	PrintLong
	addq.w	#8,sp
	subq.l	#1,d0
	beq.b	Done
	subq.l	#1,d1
	beq.b	.Loop
	lea	(MySpace,pc),a0
	bsr	Print
	bra.b	.Loop1	

MemMod:
lbC00086A:
	bsr	GetArg
	bcs.b	.endit
	move.l	d0,a3
.MM:
	bsr	GetArg
	bcs.b	lbC000874
	move.b	d0,(a3)+
	bra.b	.MM
.endit:
lbC000874:
	rts

Install:
;Fix ExecBase and re-install VBRCrack

	lea	(ExecData,pc),a0
	move.l	(a0)+,a1
	move.l	a1,a6
	move.l	a6,(4).w
	move.w	#ChkSum+1,d0
..	move.b	(a0)+,(a1)+
	dbra	d0,..

	lea	($2c+chw.msg,pc),a0
	move.l	a0,(KickTagPtr,a6)
	lea	(4+chw.msg,pc),a0
	move.l	a0,(KickMemPtr,a6)
	bsr	SumKickData
	move.l	d0,(KickCheckSum,a6)

	lea	(install.msg,pc),a0
	sub.l	a1,a1
	bsr	Print
	rts

;********************************************************************
;***************************** SumKickData **************************
;********************************************************************

SumKickData:
	movem.l	D2-D4,-(SP)
	lea	(KickMemPtr,A6),A0
	movem.l	(A0),D3/D4
	clr.l	(A0)+
	clr.l	(A0)+
	moveq	#-1,D0
	move.l	D3,D2
lbC000014:
	tst.l	D2
	beq.b	lbC00002C
	movea.l	D2,A0
	move.l	(A0),D2
	move.w	(14,A0),D1
	add.w	D1,D1
	addi.w	#4,D1
	bsr	SumlbC000052
	bra.b	lbC000014

lbC00002C:
	move.l	D4,D2
	beq.b	SumlbC000044
	movea.l	D2,A0
	bra.b	SumlbC000036

lbC000034:
	add.l	D2,D0
SumlbC000036:
	move.l	(A0)+,D2
	beq.b	SumlbC000044
	bpl.b	lbC000034
	bclr	#$1F,D2
	movea.l	D2,A0
	bra.b	SumlbC000036

SumlbC000044:
	movem.l	D3/D4,(KickMemPtr,A6)
	movem.l	(SP)+,D2-D4
	rts

lbC000050:
	add.l	(A0)+,D0
SumlbC000052:
	dbra	D1,lbC000050
	rts

;*************************************************************************
;****************************** End of SumKickData ***********************
;*************************************************************************

ExecData:
	dcb.b	ChkSum+6,0

install.msg:
	dc.b	'ExecBase corrected. Reinstalled.',$a,0
	even

togglentsc:
	lea	(VideoMode,pc),a0
	not.w	(a0)
	beq.b	.pal
	move.w	#$fcc1,(diwstop+_custom)
	move.w	#0,($dff1dc)
	rts
.pal:
	move.w	#$2cc1,(diwstop+_custom)
	move.w	#32,($dff1dc)
	rts

VideoMode:
	dc.w	0	;zero = PAL, $FFFF = NTSC

jump:
	bsr	GetArg
	bcs.b	.L1
	sub.l	a2,a2
	lea	(OhTenFlag,pc),a0
	tst.w	(a0)
	beq.b	.skipvbr1
	dc.l	$4E7BA801	;move a2,vbr
.skipvbr1:
	bclr	#0,d0
	move.l	d0,a3
	push	a3

	pea	(.return,pc)
	push	a3
	movem.l	($ce,a5),d0-d7
	movem.l	d0-d7,-(sp)
	movem.l	($ee,a5),d0-d6
	movem.l	d0-d6,-(sp)
	movem.l	(sp)+,a0-a6
	movem.l	(sp)+,d0-d7
	rts
.return:
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	(GlobalPtr,pc),a2
	lea	($ce,a2),a1
	move.w	#60/4-1,d0
..	move.l	(sp)+,(a1)+
	dbra	d0,..

	pop	a3

	add.w	#$1b6a,a2
	lea	(OhTenFlag,pc),a0
	tst.w	(a0)
	beq.b	.skipvbr2
	dc.l	$4E7BA801	;move a2,vbr
.skipvbr2:
.L1:
	rts

;	move.l	d0,($114,a5)
;lbC000880:
;	movem.l	d0-d7/a0-a7,($40,a5)
;	bsr	lbC000A4C
;	movea.l	($10A,a5),sp
;	move.l	a0,usp
;	bclr	#7,($112,a5)
;	move.l	($114,a5),-(sp)
;	move.w	($112,a5),-(sp)
;	movem.l	($CE,a5),d0-d7/a0-a6
;	rte

lbC0008A6:
	move.l	a5,-(sp)
	movea.l	(GlobalPtr,pc),a5
	movem.l	d0-d7/a0-a6,($CE,a5)
	move.l	(sp)+,($102,a5)
	move.l	usp,a0
	move.l	a0,($10E,a5)
	move.w	(sp)+,($112,a5)
	move.l	(sp)+,($114,a5)
	move.l	sp,($10A,a5)
	movem.l	($40,a5),d0-d7/a0-a7
	bra	lbC0009E2

MemDump:
	bsr	GetArg
	bcs.b	lbL0008E4
	movea.l	d0,a3
	bsr	GetArg
	bcs.b	lbL0008E4
	movea.l	d0,a2
	bra.b	lbC0008E8

lbL0008E4:
	lea	($80,a3),a2

lbC0008E8:
	cmp.b	#$1b,(ascii_key_pressed,a5)
	beq.b	.EndMD
	movea.l	a3,a0
	bsr	lbC000D2A
	bsr	lbC000AC2
	movea.l	a3,a0
	bsr	lbC000D52
	bsr	lbC000AB2
	lea	($10,a3),a3
	cmpa.l	a2,a3
	blt.b	lbC0008E8
.EndMD:
	rts

Disassemble:
	suba.w	#$40,sp
	bsr	GetArg
	bcs.b	lbC000922
	bclr	#0,d0
	movea.l	d0,a3
	bsr	GetArg
	bcs.b	lbC000922
	movea.l	d0,a2
	moveq	#-1,d2
	bra.b	lbC000928

lbC000922:
	move.l	a3,d0
	bclr	#0,d0
	move.l	d0,a3
	lea	($800,a3),a2
	moveq	#9,d2
lbC000928:
	cmp.b	#$1b,(ascii_key_pressed,a5)
	beq.b	EndDis
	movea.l	a3,a0
	bsr	lbC000D12	;print address
	move.w	(a3),d0
	bsr	lbC000CD4	;print opcode (hex)
	bsr	lbC000ABE	;print 2 spaces
	movea.l	sp,a0
	movea.l	a3,a1
	bsr	lbC00187A
	movea.l	d0,a3
	move.b	d1,d3
	movea.l	sp,a0

.scan:
	move.b	(a0)+,d0
	beq.b	.endscan
	cmp.b	#9,d0
	bne.b	.scan
	move.b	#4,(-1,a0)
	bra.b	.scan
.endscan:

	movea.l	sp,a0
	bsr	lbC000A8C	;print
	tst.b	d3
	beq.b	lbC000954
	moveq	#$31,d0
	bsr	lbC000A9E
lbC000954:
	cmpa.l	a2,a3
	dbge	d2,lbC000928
EndDis:
	adda.w	#$40,sp
	rts

PrintToggle:
	btst	#0,($BFD000)
	bne.b	lbC000976
	not.b	($9D,a5)
	move.b	($9D,a5),($BFE301)
lbC000976:
	rts

RegDump:
	bsr	lbC000D7E
	beq.b	lbC0009E2
	bsr	Uppercase
	
;;;	move.b	d0,($80000)

	cmpi.b	#'D',d0
	bne.b	lbC00098E
	bsr	lbC000E94
	bcs	lbC000A4A
	bra.b	lbL0009B8

lbC00098E:
	cmpi.b	#'A',d0
	bne.b	lbC0009A0
	bsr	lbC000E94
	bcs	lbC000A4A
	addq.w	#8,d0
	bra.b	lbL0009B8

lbC0009A0:
	cmpi.b	#'P',d0
	bne	lbC000A4A
	bsr	lbC000D7E
	bsr	UpperCase
	cmpi.b	#'C',d0
	bne	lbC000A4A
	moveq	#70,d0
	bra.b	lbC0009BE

lbL0009B8:
	and.w	#$f,d0
	lsl.w	#2,d0

lbC0009BE:
	lea	($CE,a5),a2
	adda.w	d0,a2
	bsr	lbC000D7E
	cmpi.b	#'=',d0
	bne	lbC000A4A	;print '?'
	bsr	GetArg

;	move.l	d0,($80000)

	move.l	d0,(a2)
	bclr	#0,($10D,a5)	;force SSP to even (not needed)
	bclr	#0,($117,a5)	;force PC to even address
	rts

lbC0009E2:
	lea	(D008lx08lx08l.MSG,pc),a0
;	move.l	a5,a1
	lea	($CE,a5),a1
	bsr	Print
	suba.w	#$40,sp
	movea.l	sp,a0
	movea.l	($114,a5),a1
	bsr	lbC00187A
	movea.l	sp,a0
	bsr	lbC000A8C
	adda.w	#$40,sp
;	rts

;Print INTENAR and DMACONR too
	moveq	#0,d0
	move.w	(MyDmaconr,a5),d0
	move.l	d0,-(sp)
	move.w	(MyIntenar,a5),d0
	move.l	d0,-(sp)
	pea	(regfmt,pc)
	bsr	PrintLong
	add.w	#12,sp
	rts

regfmt:
	dc.b	'INTENAR=$%04lx    '
	dc.b	'DMACONR=$%04lx'
	dc.b	$a,0
	even

Transfer:
	bsr	GetArg
	bcs.b	lbC000A4A
	movea.l	d0,a2
	bsr	GetArg
	bcs.b	lbC000A4A
	move.l	d0,d2
	bsr	GetArg
	bcs.b	lbC000A4A
	movea.l	d0,a0
lbC000A20:
	move.b	(a2)+,(a0)+
	cmpa.l	d2,a2
	blt.b	lbC000A20
	rts

ExitMod:
	st	(ExitModFlag,a5)
	bra.b	Exit1
Exit:
	clr.b	(ExitModFlag,a5)
Exit1:
	move.w	#$2700,SR
	lea	(OhTenFlag,pc),a0
	tst.w	(a0)
	bne.b	.skipvec

;Restore
	move.l	($84,a5),($68)
	move.l	($88,a5),($6C)
	move.l	($80,a5),($10)

.skipvec:
	move.l	($84,a5),($1bd2,a5)
	move.l	($88,a5),($1bd6,a5)
	move.l	($80,a5),($1b7a,a5)
;	bclr	#1,($BFE001)
	add.w	#60,sp
	rts

lbC000A4A:
	bra	lbC000AAE

lbC000A4C:

;examine this closer
;????
	lea	(lbL0005AC,pc),a1
	lea	($918,a5),a0
	move.l	a1,-(a0)
;	move.l	a0,($10A,a5)
	lea	(charmap,a5),a0
	move.l	a1,-(a0)
;	move.l	a0,($10E,a5)
	rts

 comment |

[ original version ]

PrintLong:
lbC000A66:
	movea.l	(4,sp),a0
	lea	(8,sp),a1
Print:
lbC000A6E:
	movem.l	a2/a3,-(sp)
	lea	(lbC000A82,pc),a2
	movea.l	a5,a3
	jsr	(_LVORawDoFmt,a6)
	movem.l	(sp)+,a2/a3
	rts
|

PrintLong:
;All registers (especially d0) must be saved, but A5 must not be
;saved
	movem.l	a0/a1/a5,-(sp)
;**
	movea.l	(GlobalPtr,pc),a5
	movea.l	(4+12,sp),a0
	lea	(8+12,sp),a1
	bsr.b	Print
	movem.l	(sp)+,a0/a1/a5
	rts

MyChar: dc.b 0,0

PrintChar:
;Enter with a char in d0.b
;Note!! Kills a0

	lea	(MyChar,pc),a0
	move.b	d0,(a0)

Print:
	cmp.b	#$1b,(ascii_key_pressed,a5)
	bne.b	.skipthis
	move.l	(MainSP,a5),sp
	bra	ReturnToMain

.skipthis:
	movem.l	d0/d1/a0-a3,-(sp)
	lea	(lbC000A82,pc),a2
	movea.l	a5,a3
	bsr	RawDoFmt
	movem.l	(sp)+,d0/d1/a0-a3
	rts

;Print:
;	push	a1
;	sub.l	a1,a1
;	bsr.b	Print1
;	pop	a1
;	rts

;***********************************************************
;******************** RawDoFmt *****************************
;***********************************************************

lbC000000:	moveq	#-1,D2
lbC000002:	tst.b	(A0)+
	dbeq	D2,lbC000002

	neg.l	D2
	subq.w	#1,D2
	rts

lbC00000E:	clr.l	D0
	clr.l	D2
lbC000012:	move.b	(A4)+,D2
	cmpi.b	#$30,D2
	bcs.b	lbC000032
	cmpi.b	#$39,D2
	bhi.b	lbC000032
	add.l	D0,D0
	move.l	D0,D1
	add.l	D0,D0
	add.l	D0,D0
	add.l	D1,D0
	subi.b	#$30,D2
	add.l	D2,D0
	bra.b	lbC000012

lbC000032:	subq.l	#1,A4
	rts

lbC000036:	tst.l	D4
	beq.b	lbC00006E
	bmi.b	lbC000040
	neg.l	D4
	bra.b	lbC000044

lbC000040:	move.b	#$2D,(A5)+
lbC000044:	lea	(lbL000078,pc),A0	;was a bug! (not pos indep)
	clr.w	D1
lbC00004C:	move.l	(A0)+,D2
	beq.b	lbC00006E
	moveq	#-1,D0
lbC000052:	add.l	D2,D4
	dbgt	D0,lbC000052

	sub.l	D2,D4
	addq.w	#1,D0
	bne.b	lbxC000062
	tst.w	D1
	beq.b	lbC00004C
lbxC000062:	moveq	#-1,D1
	neg.b	D0
	addi.b	#$30,D0
	move.b	D0,(A5)+
	bra.b	lbC00004C

lbC00006E:	neg.b	D4
	addi.b	#$30,D4
	move.b	D4,(A5)+
	rts

lbL000078:
	dl	$3B9ACA00
	dl	$5F5E100
	dl	$989680
	dl	$F4240
	dl	$186A0
	dl	$2710
	dl	$3E8
	dl	$64
	dl	10
	dl	0

lbC0000A0:	tst.l	D4
	beq.b	lbC00006E
	clr.w	D1
	btst	#2,D3
	bne.b	lbC0000B2
	moveq	#3,D2
	swap	D4
	bra.b	lbC0000B4

lbC0000B2:	moveq	#7,D2
lbC0000B4:	rol.l	#4,D4
	move.b	D4,D0
	andi.b	#15,D0
	bne.b	lbC0000C2
	tst.w	D1
	beq.b	lbC0000D6
lbC0000C2:	moveq	#-1,D1
	cmpi.b	#9,D0
	bhi.b	lbC0000D0
	addi.b	#$30,D0
	bra.b	lbC0000D4

lbC0000D0:	addi.b	#$37,D0
lbC0000D4:	move.b	D0,(A5)+
lbC0000D6:	dbra	D2,lbC0000B4

	rts

RawDoFmt:	movem.l	D2-D6/A2-A5,-(SP)
	link.w	A6,#-$10
	move.l	A1,-(SP)
	movea.l	A0,A4
lbC0000E8:
	move.b	(A4)+,D0
	beq.b	lbC0000F6
	cmpi.b	#$25,D0
	beq.b	lbC000100
lbC0000F2:
	jsr	(A2)
	bra.b	lbC0000E8

lbC0000F6:
	jsr	(A2)
	unlk	A6
	movem.l	(SP)+,D2-D6/A2-A5
	rts

lbC000100:
	lea	(-$10,A6),A5
	clr.w	D3
	cmpi.b	#$2D,(A4)
	bne.b	lbC000112
	bset	#0,D3
	addq.l	#1,A4
lbC000112:
	cmpi.b	#$30,(A4)
	bne.b	lbC00011C
	bset	#1,D3
lbC00011C:
	bsr	lbC00000E
	move.w	D0,D6
	clr.l	D5
	cmpi.b	#$2E,(A4)
	bne.b	lbC000132
	addq.w	#1,A4
	bsr	lbC00000E
	move.w	D0,D5
lbC000132:
	cmpi.b	#$6C,(A4)
	bne.b	lbC00013E
	bset	#2,D3
	addq.w	#1,A4
lbC00013E:
	move.b	(A4)+,D0
	cmpi.b	#$64,D0
	bne.b	lbC00014E
	bsr.b	lbC00015C
	bsr	lbC000036
	bra.b	lbC000196

lbC00014E:
	cmpi.b	#$78,D0
	bne.b	lbC00017C
	bsr.b	lbC00015C
	bsr	lbC0000A0
	bra.b	lbC000196

lbC00015C:
	btst	#2,D3
	bne.b	lbC000170
	movea.l	(4,SP),A1
	move.w	(A1)+,D4
	move.l	A1,(4,SP)
	ext.l	D4
	rts

lbC000170:
	movea.l	(4,SP),A1
	move.l	(A1)+,D4
	move.l	A1,(4,SP)
	rts

lbC00017C:
	cmpi.b	#$73,D0
	bne.b	lbC00018A
	movea.l	(SP),A1
	movea.l	(A1)+,A5
	move.l	A1,(SP)
	bra.b	lbC00019C

lbC00018A:
	cmpi.b	#$63,D0
	bne	lbC0000F2
	bsr.b	lbC00015C
	move.b	D4,(A5)+
lbC000196:
	clr.b	(A5)
	lea	(-$10,A6),A5
lbC00019C:
	movea.l	A5,A0
	bsr	lbC000000
	tst.w	D5
	beq.b	lbC0001AA
	cmp.w	D5,D2
	bhi.b	lbC0001AC
lbC0001AA:
	move.w	D2,D5
lbC0001AC:
	sub.w	D5,D6
	bpl.b	lbC0001B2
	clr.w	D6
lbC0001B2:
	btst	#0,D3
	bne.b	lbC0001C0
	bsr.b	lbC0001D2
	bra.b	lbC0001C0

lbC0001BC:
	move.b	(A5)+,D0
	jsr	(A2)
lbC0001C0:
	dbra	D5,lbC0001BC

	btst	#0,D3
	beq	lbC0000E8
	bsr.b	lbC0001D2
	bra	lbC0000E8

lbC0001D2:
	move.b	#$20,D2
	btst	#1,D3
	beq.b	lbC0001E6
	move.b	#$30,D2
	bra.b	lbC0001E6

lbC0001E2:
	move.b	D2,D0
	jsr	(A2)
lbC0001E6:
	dbra	D6,lbC0001E2
	rts

;****************************************************************
;********************** End of RawDoFmt *************************
;****************************************************************

;RawDoFmt output routine
lbC000A82:
	movem.l	d0-d7/a0-a6,-(sp)
;	move.l	a5,-(sp)
	movea.l	a3,a5
	bsr.b	lbC000AC6
;	movea.l	(sp)+,a5
	movem.l	(sp)+,d0-d7/a0-a6
	rts

lbC000A8C:
	move.l	a2,-(sp)
	movea.l	a0,a2
lbC000A90:
	move.b	(a2)+,d0
	beq.b	lbC000A98
	bsr.b	lbC000AC6
	bra.b	lbC000A90

lbC000A98:
	movea.l	(sp)+,a2
	rts

lbC000A9C:
	moveq	#$4F,d0
lbC000A9E:
	move.l	d2,-(sp)
	move.w	d0,d2
lbC000AA2:
	moveq	#$2D,d0
	bsr.b	lbC000AC6
	dbra	d2,lbC000AA2

	move.l	(sp)+,d2
	bra.b	lbC000AB2

lbC000AAE:
	moveq	#'?',d0
	bsr.b	lbC000AC6
lbC000AB2:
	moveq	#10,d0
	bra.b	lbC000AC6

lbC000AB6:
	moveq	#$3A,d0
	bra.b	lbC000AC6

PrintPeriod:
	moveq	#$2E,d0
	bra.b	lbC000AC6

lbC000ABE:
	bsr	lbC000AC2
lbC000AC2:
	move.b	#$20,d0

;Output routine used by RawDoFmt (for screen output & printer)
lbC000AC6:
	tst.b	($9D,a5)	;test if printer output enabled
	beq.b	lbC000ADC	;go if not enabled
lbC000ACC:
	cmp.b	#4,d0
	bne.b	.skipfix
	move.b	#9,d0
.skipfix:
	btst	#0,($BFD000)
	bne.b	lbC000ACC
	move.b	d0,($BFE101)
lbC000ADC:
	movea.l	(cursor_memory_location,a5),a0
	clr.l	(cursor_memory_location,a5)
	move.b	(cursor_value,a5),(a0)
	cmpi.b	#$20,d0
	bcc	lbC000BAA
	cmpi.b	#10,d0	;CR?
	beq	lbC000BEE
	cmpi.b	#$10,d0
	bne.b	lbC000B10
lbC000AFE:
	cmpi.w	#3,(cursor_y_position,a5)
	beq	lbC000C02
	subq.w	#1,(cursor_y_position,a5)
	bra	lbC000C02

lbC000B10:
	cmpi.b	#$11,d0
	beq	lbC000BF2
	cmpi.b	#$12,d0
	bne.b	lbC000B34
	subq.w	#1,(cursor_x_position,a5)
	cmpi.w	#$FFFF,(cursor_x_position,a5)
	bgt	lbC000C02
	move.w	#$4F,(cursor_x_position,a5)
	bra.b	lbC000AFE

lbC000B34:
	cmpi.b	#8,d0
	bne.b	lbC000B5E
	tst.w	(cursor_x_position,a5)
	beq	lbC000C02
	subq.w	#1,(cursor_x_position,a5)
	bsr	lbC000AC2
	movea.l	(cursor_memory_location,a5),a0
	clr.l	(cursor_memory_location,a5)
	move.b	(cursor_value,a5),(a0)
	subq.w	#1,(cursor_x_position,a5)
	bra	lbC000C02

lbC000B5E:
	cmpi.b	#$13,d0
	beq	lbC000BE2
	cmpi.b	#7,d0	;delete
	bne.b	lbC000B7A
	move.w	#0,(cursor_x_position,a5)
	move.w	#3,(cursor_y_position,a5)
	bra	lbC000C02

lbC000B7A:
	cmpi.b	#9,d0	;Tab?
	bne	lbC000B90

;Update cursor position according to tab logic

 comment |	- Old tab -
	move.w	(cursor_x_position,a5),d0
	andi.w	#$F8,d0	;round up to nearest 8
	addq.w	#8,d0
	move.w	d0,(cursor_x_position,a5)
|

	move.w	(cursor_x_position,a5),d0
	divu.w	#8,d0
	swap	d0
	sub.w	#8,d0
	neg.w	d0
	add.w	d0,(cursor_x_position,a5)

	bra	lbC000C02

;************* Handle command line history *************

DoHistory:

	movem.l	d0-d2/a0-a2,-(sp)

	move.w	(ViewHistoryPtr,a5),d1
	mulu.w	#80,d1
	lea	(CmdHistory,a5),a0
	add.l	d1,a0
	tst.b	(a0)
	beq.b	.EndHistory

;update charmap
	move.w	(cursor_x_position,a5),d2	;save
	move.w	#-1,(cursor_x_position,a5)
	st	(NotOff,a5)
	move.w	#79,d1
	move.l	a0,a1

.PrintLoop:
	move.b	(a1)+,d0
	bsr	PrintChar
	dbra	d1,.PrintLoop

	move.w	d2,d0
	bsr	MoveX	;restore

	clr.b	(NotOff,a5)
.EndHistory:
	movem.l	(sp)+,d0-d2/a0-a2
	rts

UpdateViewHistoryPtr:

;Enter with ptr delta (usually -1 or 1) in d0.w
;uses d1,d2,a0

	movem.l	d1-d2/a0,-(sp)
	move.w	(ViewHistoryPtr,a5),d1
	add.w	d0,d1
	bmi.b	.setmax
	cmp.w	#NumLines,d1
	bhi.b	.setzero	;go if d1 > NumLines

.Finish:
;Make sure the next entry is non-zero
	move.w	d1,d2
	mulu.w	#80,d1
	lea	(CmdHistory,a5),a0
	add.l	d1,a0
	tst.b	(a0)
	beq.b	.EndHistory1

	move.w	d2,(ViewHistoryPtr,a5)
.EndHistory1:
	movem.l	(sp)+,d1-d2/a0
	rts
.setmax:
	move.w	#NumLines,d1
	bra.b	.Finish
.setzero:
	moveq	#0,d1
	bra.b	.Finish

;*******************************************************

lbC000B90:

;Check for shifted cursor up/down, and do command history
	cmp.b	#12,d0	;shifted cursor up?
	bne.b	.Next
	moveq	#-1,d0
	bsr	UpdateViewHistoryPtr
	bsr	DoHistory
	bra	lbC000C02
.Next:
	cmp.b	#13,d0	;shifted cursor down?
	bne.b	.Done
	moveq	#1,d0
	bsr	UpdateViewHistoryPtr
	bsr	DoHistory
	bra	lbC000C02
.Done:

	cmpi.b	#11,d0
	bne.b	lbC000B9C
	bsr	lbC000C7E
	bra.b	lbC000C02

lbC000B9C:
	cmp.b	#4,d0
	bne.b	.skipspecial
	move.w	#25,(cursor_x_position,a5)
.skipspecial:
	bra.b	lbC000C02

	movea.l	(cursor_memory_location,a5),a0
	clr.l	(cursor_memory_location,a5)
	move.b	(cursor_value,a5),(a0)

;low level print routine

LowPrint:
lbC000BAA:
	move.w	d0,-(sp)
	bsr	lbC000C18
	move.w	(sp)+,d0
	move.b	d0,(a0)
	move.l	d2,-(sp)
	btst	#7,d0
	sne	d2
	andi.w	#$7F,d0
	subi.b	#$20,d0
	bpl.b	lbC000BC6
	moveq	#$60,d0
lbC000BC6:
	lsl.w	#3,d0
	lea	(charset,pc),a1
	adda.w	d0,a1
	bsr.b	lbC000C24
	moveq	#7,d0
lbC000BD2:
	move.b	(a1)+,d1
	eor.b	d2,d1
	move.b	d1,(a0)
	adda.w	#80,a0
	dbra	d0,lbC000BD2

	move.l	(sp)+,d2
lbC000BE2:
	addq.w	#1,(cursor_x_position,a5)
	cmpi.w	#80,(cursor_x_position,a5)
	blt.b	lbC000C02
lbC000BEE:
	clr.w	(cursor_x_position,a5)
lbC000BF2:
	cmpi.w	#28,(cursor_y_position,a5)
	bne.b	lbC000BFE
	bsr.b	lbC000C38
	bra.b	lbC000C02

lbC000BFE:
	addq.w	#1,(cursor_y_position,a5)

lbC000C02:
	clr.b	(cursor_vblank_counter,a5)
	bsr.b	lbC000C24
	adda.w	#80*7,a0
	move.b	(a0),(cursor_value,a5)

;magic kludge #2001
	cmp.b	#$FF,(a0)
	bne.b	.skip
	clr.b	(cursor_value,a5)
.skip:

	tst.b	(NotOff,a5)
	bne.b	.skipnot
	not.b	(a0)
.skipnot:
	move.l	a0,(cursor_memory_location,a5)
	rts

;****************************************
MoveX:

;Move the cursor to a X value in d0.w
;Takes into account cursor blinking effects

	movem.l	d0/a0,-(sp)
	move.l	(cursor_memory_location,a5),a0
	move.b	(cursor_value,a5),(a0)
	move.w	d0,(cursor_x_position,a5)
	bsr	lbC000C02
	movem.l	(sp)+,d0/a0
	rts

;****************************************


lbC000C18:
	lea	(charmap,a5),a0
	moveq	#80,d0
	mulu.w	(cursor_y_position,a5),d0
	bra.b	lbC000C30

lbC000C24:
	movea.l	(BitmapPtr,pc),a0
	move.w	(cursor_y_position,a5),d0
	mulu.w	#640,d0
lbC000C30:
	add.w	(cursor_x_position,a5),d0
	adda.w	d0,a0
	rts

lbC000C38:
	btst	#3,(keyboard_shifted_flag,a5)
	bne.b	lbC000C38
	move.w	#$1F3,d0
	lea	($1208,a5),a0
	lea	($50,a0),a1
lbC000C4C:
	move.l	(a1)+,(a0)+
	dbra	d0,lbC000C4C

	moveq	#$27,d0
lbC000C54:
	move.w	#$2020,(a0)+
	dbra	d0,lbC000C54

	move.w	#$F9F,d0
	movea.l	(BitmapPtr,pc),a0
	lea	($780,a0),a0
	lea	($280,a0),a1
lbC000C6C:
	move.l	(a1)+,(a0)+
	dbra	d0,lbC000C6C

	move.w	#$9F,d0
lbC000C76:
	clr.l	(a0)+
	dbra	d0,lbC000C76

	rts

lbC000C7E:
	bsr.b	lbC000CBE
	move.w	#$103F,d0
	movea.l	(BitmapPtr,pc),a0
	lea	($780,a0),a0
lbC000C8C:
	clr.l	(a0)+
	dbra	d0,lbC000C8C

	move.w	#0,(cursor_x_position,a5)
	move.w	#3,(cursor_y_position,a5)
	rts

ClearScreen:
lbC000CA0:
	bsr.b	lbC000CBE
	move.w	#$13FF,d0
	movea.l	(BitmapPtr,pc),a0
lbC000CAA:
	clr.l	(a0)+
	dbra	d0,lbC000CAA

	move.w	#0,(cursor_x_position,a5)
	move.w	#0,(cursor_y_position,a5)
	rts

lbC000CBE:
	move.w	#$4FF,d0
	lea	(charmap,a5),a0
lbC000CC6:
	move.w	#$2020,(a0)+
	dbra	d0,lbC000CC6

	rts

lbC000CD0:
	moveq	#1,d1
	bra.b	lbC000CDE

lbC000CD4:
	moveq	#3,d1
	bra.b	lbC000CDE

lbC000CD8:
	moveq	#7,d1	;digits-1
	bra.b	lbC000CDE

	moveq	#7,d1
lbC000CDE:
	move.l	d2,-(sp)
	clr.w	-(sp)
lbC000CE2:
	move.b	d0,d2
	lsr.l	#4,d0
	andi.w	#15,d2
	move.b	(ABCDEFHa.MSG,pc,d2.w),d2
	move.w	d2,-(sp)
	dbra	d1,lbC000CE2

lbC000CF4:
	move.w	(sp)+,d0
	beq.b	lbC000CFE
	bsr	lbC000AC6
	bra.b	lbC000CF4

lbC000CFE:
	move.l	(sp)+,d2
	rts

ABCDEFHa.MSG:
	db	'0123456789ABCDEF'
	even

lbC000D12:
	move.l	a2,-(sp)
	movea.l	a0,a2
	bsr	PrintPeriod	;"."
	bsr	lbC000AB6	;":"
	move.l	a2,d0
	bsr.b	lbC000CD8	;number
;	bsr	lbC000AB6	;":"
	bsr	lbC000AC2
	movea.l	(sp)+,a2
	rts

lbC000D2A:
	movem.l	d2/a2,-(sp)
	movea.l	a0,a2
	bsr.b	lbC000D12
	move.w	#15,d2
lbC000D36:
	move.b	(a2)+,d0
	bsr.b	lbC000CD0
	bsr	lbC000AC2
	cmpi.w	#8,d2
	bne.b	lbC000D48
	bsr	lbC000AC2
lbC000D48:
	dbra	d2,lbC000D36

	movem.l	(sp)+,d2/a2
	rts

lbC000D52:
	movem.l	d2/a2,-(sp)
	movea.l	a0,a2
;	move.b	#$27,d0	;"'"
	move.b	#'`',d0
	bsr	lbC000AC6
	bsr	lbC000AC2
	moveq	#15,d2
lbC000D66:
	move.b	(a2)+,d0
	cmpi.b	#$20,d0
	bcc.b	lbC000D70
	moveq	#$60,d0
lbC000D70:
	bsr	lbC000AC6
	dbra	d2,lbC000D66

	movem.l	(sp)+,d2/a2
	rts

;Get a character from the line buffer, and if the line buffer is empty,
;wait for a line of input.

lbC000D7E:
GetChar:
	tst.b	(chars_in_linebuffer_flag,a5)
	beq	lbC000D88
	bsr	lbC000D98	;get line

;Store command line in 'history' buffer
;uses d1,d2,a0,a1

	movem.l	d1-d2/a0-a1,-(sp)
	lea	(line_buffer,a5),a0

;Check for a "null line"...and don't save it
	cmp.w	#$2E00,(a0)
	beq.b	.EndHistory
	cmp.l	#$20202020,(a0)
	beq.b	.EndHistory

	lea	(CmdHistory,a5),a1
	move.w	(HistoryPtr,a5),d2

;Compare against the last entered line -- if the same, don't store
	move.w	d2,d1
	subq.w	#1,d1
	bpl.b	.ok
	move.w	#NumLines,d1
.ok:	mulu.w	#80,d1
	add.l	d1,a1
	cmp.b	(a1)+,d0
	bne.b	.Different
	move.w	#78,d1
..	cmpm.b	(a0)+,(a1)+
	dbne	d1,..
	beq	.EndHistory1

.Different:
	lea	(line_buffer,a5),a0
	lea	(CmdHistory,a5),a1
	move.w	d2,d1
	mulu.w	#80,d2
	add.l	d2,a1
	move.b	d0,(a1)+
	move.w	#78,d2
..	move.b	(a0)+,(a1)+
	dbra	d2,..
	cmp.w	#NumLines,d1
	beq.b	.full
	addq.w	#1,(HistoryPtr,a5)
	move.w	(HistoryPtr,a5),(ViewHistoryPtr,a5)
	bra.b	.EndHistory
.full:
	clr.w	(HistoryPtr,a5)
.EndHistory1:
	move.w	(HistoryPtr,a5),(ViewHistoryPtr,a5)
.EndHistory:
	movem.l	(sp)+,d1-d2/a0-a1
	bra	GetChar

lbC000D88:
	bsr	lbC000E26
	addq.w	#1,(line_buffer_ptr,a5)
	tst.b	d0
	seq	(chars_in_linebuffer_flag,a5)
	rts

_GetChar:
	movem.l	d1-d7/a0-a6,-(sp)
	movea.l	(GlobalPtr,pc),a5
	bsr	GetChar
	and.l	#$ff,d0

 comment |
	push	d0
	bsr	PrintChar
	move.l	d0,-(sp)
	pea	(MyByte,pc)
	bsr	PrintLong
	addq.l	#8,sp
	pop	d0

|
	movem.l	(sp)+,d1-d7/a0-a6
	rts

lbC000D98:
	bsr.b	lbC000DE6
	cmpi.b	#10,d0
	beq.b	lbC000DA6
	bsr	lbC000ADC
	bra.b	lbC000D98

lbC000DA6:
	bsr	lbC000AC6
	bsr	lbC000C18
	suba.w	#80,a0
	lea	(line_buffer,a5),a1
	moveq	#79,d1
	moveq	#0,d0
lbC000DBA:
	move.b	(a0)+,d0
	bsr.b	lbC000E34
;	bsr	lbC000E4C	;uppercase

;Look at this
;	cmpi.b	#$27,d0	;"'"
	cmpi.b	#'`',d0	;"'"
	bne.b	lbC000DCC
	clr.b	(a1)
	bra.b	lbC000DDC

lbC000DCC:
	move.b	d0,(a1)+
	dbra	d1,lbC000DBA

lbC000DD2:
	cmpi.b	#$20,-(a1)
	beq.b	lbC000DD2
	clr.b	(1,a1)
lbC000DDC:
	clr.w	(line_buffer_ptr,a5)
	clr.b	(chars_in_linebuffer_flag,a5)
	rts

lbC000DE6:
	move.w	($A4,a5),d1
	beq.b	lbC000DE6
	move.w	#$4000,(intena,a4)
	subq.w	#1,d1
	move.w	d1,($A4,a5)
	lea	($A6,a5),a0
	move.b	(a0),d0
lbC000DFE:
	move.b	(1,a0),(a0)+
	dbra	d1,lbC000DFE

	move.w	#$C000,(intena,a4)
	cmpi.b	#$15,d0
	bne.b	lbC000E24
	movem.l	d0/d1/a0/a1,-(sp)
	lea	(CommandListMs.MSG,pc),a0
	bsr	lbC000A8C
	movem.l	(sp)+,d0/d1/a0/a1
	bra.b	lbC000DE6

lbC000E24:
	rts

;GetChar
;_GetChar:
lbC000E26:
	lea	(line_buffer,a5),a0
	adda.w	(line_buffer_ptr,a5),a0
	moveq	#0,d0
	move.b	(a0),d0
	rts

lbC000E34:
;	cmpi.b	#'.',d0
;	beq.b	lbC000E48
;	cmpi.b	#',',d0
;	beq.b	lbC000E48
;	cmpi.b	#'$',d0
;	beq.b	lbC000E48
	rts

lbC000E48:
	moveq	#$20,d0
	rts

Uppercase:
lbC000E4C:
	cmpi.b	#'a',d0
	blt.b	lbC000E5C
	cmpi.b	#'z',d0
	bgt.b	lbC000E5C
	subi.b	#$20,d0
lbC000E5C:
	rts

MyByte:
	dc.b	'GetChar: "%08lx"',$a,0
	even

;****************************************************************
;********************* Parse, by Dan Zenchelsky *****************
;****************************************************************

GetArg:
_parse:
;	move.w	#80,d7

 comment |
.GA1:
	bsr	_GetChar
	and.l	#$ff,d0

	push	d0
	bsr	PrintChar
	move.l	d0,-(sp)
	pea	(MyByte,pc)
	bsr	PrintLong
	addq.l	#8,sp
	pop	d0

	tst.b	d0
	beq.b	.end
	cmp.b	#$0a,d0
	beq.b	.end
	cmp.b	#$0d,d0
	beq.b	.end

;	dbra	d7,.GA1
	bra	.GA1
.end:
	move.w	#1,ccr
	moveq	#0,d0
	rts
|

	MOVEM.L	d1-D7/a0-a6,-(SP)

;	lea	(_bflag,pc),a0
;	clr.b	(a0)


;	lea	(Enter,pc),a0
;	bsr	Print

	lea	(ParseData,pc),a4

	tst.b	(_strflag-parsedata,a4)
	bne.b	.normal
.loop:
	bsr	_Test
	cmp.b	#' ',d0
	bne.b	.normal
	bsr	_Get
	bra.b	.loop

.normal:
	MOVEQ	#$20,D5
	MOVEQ	#0,D4
	BSR	_Test
	MOVEQ	#$27,D1	;"'"
	CMP.B	D1,D0
	BNE.b	zbc000146
	not.b	(1,a4)
;	MOVE.B	#1,(1,A4)
	BSR	_Get
zbc000146:

	BSR	_Test
	MOVE.B	(3,A4),D1
	CMP.B	D1,D0
	BNE	.Cont

	CLR.B	(1,A4)
	lea	(_bflag,pc),a0
	clr.b	(a0)

	move.w #1,CCR
	movem.l	(sp)+,d1-D7/a0-a6
	rts

.Cont:
	TST.B	(1,A4)
	BEQ.b	zbc00016A
	BSR	_Test
	MOVEQ	#$27,D1
	CMP.B	D1,D0
	BEQ.b	zbc000162
	BSR	_Get
	EXT.W	D0
	EXT.L	D0
	BRA	zbc00029C

zbc000162	BSR	_Get
	CLR.B	(1,A4)
zbc00016A	BSR	_Test
	MOVEQ	#$20,D1
	CMP.B	D1,D0
	BNE.b	zbc00017A
	BSR	_Get
	BRA.b	zbc00016A

zbc00017A	BSR	_GetExp
	MOVE.L	D0,D4
zbc000180	BSR	_Test
	MOVEQ	#$20,D1
	CMP.B	D1,D0
	BEQ	zbc000274
	BSR	_Test
	MOVE.B	(3,A4),D1
	CMP.B	D1,D0
	BEQ	zbc000274
	BSR	_Get
	MOVE.L	D0,D6
	EXT.W	D6
	EXT.L	D6
	MOVE.L	D6,D0
	MOVEQ	#$26,D1
	SUB.L	D1,D0
	BEQ.b	zbc0001CC
	SUBQ.L	#4,D0
	BEQ	zbc00024A
	SUBQ.L	#1,D0
	BEQ.b	zbc0001EC
	SUBQ.L	#2,D0
	BEQ.b	zbc0001EC
	SUBQ.L	#2,D0
	BEQ	zbc00024A
	MOVEQ	#$2F,D1
	SUB.L	D1,D0
	BEQ.b	zbc0001CC
	MOVEQ	#$1E,D1
	SUB.L	D1,D0
	BNE.b	zbc000180
zbc0001CC	MOVEQ	#$20,D0
	CMP.L	D0,D5
	BEQ.b	zbc0001E2
	MOVE.L	D5,-(SP)
	MOVE.L	D7,-(SP)
	MOVE.L	D4,-(SP)
	BSR	_calc
	LEA	(12,SP),SP
	MOVE.L	D0,D4
zbc0001E2	MOVE.L	D6,D5
	BSR	_GetExp
	MOVE.L	D0,D7
	BRA.b	zbc000180

zbc0001EC	MOVEQ	#$26,D0
	CMP.L	D0,D5
	BEQ.b	zbc000220
	MOVEQ	#$7C,D0
	CMP.L	D0,D5
	BEQ.b	zbc000220
	MOVEQ	#$5E,D0
	CMP.L	D0,D5
	BEQ.b	zbc000220
	MOVEQ	#$20,D0
	CMP.L	D0,D5
	BEQ.b	zbc000214
	MOVE.L	D5,-(SP)
	MOVE.L	D7,-(SP)
	MOVE.L	D4,-(SP)
	BSR	_calc
	LEA	(12,SP),SP
	MOVE.L	D0,D4
zbc000214	MOVE.L	D6,D5
	BSR	_GetExp
	MOVE.L	D0,D7
	BRA	zbc000180

zbc000220	MOVEQ	#$20,D0
	CMP.L	D0,D5
	BEQ.b	zbc00023E
	BSR	_GetExp
	MOVE.L	D6,-(SP)
	MOVE.L	D0,-(SP)
	MOVE.L	D7,-(SP)
	BSR	_calc
	LEA	(12,SP),SP
	MOVE.L	D0,D7
	BRA	zbc000180

zbc00023E	BSR	_GetExp
	MOVE.L	D0,D7
	MOVE.L	D6,D5
	BRA	zbc000180

zbc00024A	MOVEQ	#$20,D0
	CMP.L	D0,D5
	BEQ.b	zbc000268
	BSR	_GetExp
	MOVE.L	D6,-(SP)
	MOVE.L	D0,-(SP)
	MOVE.L	D7,-(SP)
	BSR	_calc
	LEA	(12,SP),SP
	MOVE.L	D0,D7
	BRA	zbc000180

zbc000268	BSR	_GetExp
	MOVE.L	D0,D7
	MOVE.L	D6,D5
	BRA	zbc000180

zbc000274	MOVEQ	#$20,D0
	CMP.L	D0,D5
	BEQ.b	zbc00028A
	MOVE.L	D5,-(SP)
	MOVE.L	D7,-(SP)
	MOVE.L	D4,-(SP)
	BSR	_calc
	LEA	(12,SP),SP
	MOVE.L	D0,D4
zbc00028A	BSR	_Test
	MOVE.B	(3,A4),D1
	CMP.B	D1,D0
	BEQ.b	zbc00029A
	BSR	_Get
zbc00029A	MOVE.L	D4,D0
zbc00029C

;;	MOVEM.L	(SP)+,D4-D7
	move.w	#0,ccr
	movem.l	(sp)+,d1-D7/a0-a6

 comment |
	and.l	#$ff,d0
	push	d0
	bsr	PrintChar
	move.l	d0,-(sp)
	pea	(MyByte1,pc)
	bsr	PrintLong
	addq.l	#8,sp
	pop	d0

;	move.w	#10,d2
;.L1:
;	move.w	#-1,d1
;.L2:	subq.w	#1,d1
;	bne.b	.L2
;	dbra	d2,.L1
	move.w	#0,ccr
|

	RTS

MyByte1:
	dc.b	'Parse: "%08lx"',$a,0
	even


_Get:
	TST.B	(2,A4)
	BEQ.b	zbc000010
	CLR.B	(2,A4)
	BRA.b	zbc000016

zbc000010	BSR	_GetChar
	MOVE.B	D0,($108,A4)
zbc000016	MOVE.B	($108,A4),D0
	RTS

_Test	TST.B	(2,A4)
	BNE.b	zbc00002E
	MOVE.B	#1,(2,A4)
	BSR	_GetChar
	MOVE.B	D0,($108,A4)
zbc00002E	MOVE.B	($108,A4),D0
	RTS

_hextobin	MOVE.L	D7,-(SP)
	MOVE.B	(11,SP),D7
	MOVEQ	#$30,D0
	CMP.B	D0,D7
	BLT.b	zbc00004A
	MOVEQ	#$39,D1
	CMP.B	D1,D7
	BGT.b	zbc00004A
	SUB.B	#$30,D7
zbc00004A	MOVEQ	#$61,D0
	CMP.B	D0,D7
	BLT.b	zbc00005A
	MOVEQ	#$66,D0
	CMP.B	D0,D7
	BGT.b	zbc00005A
	SUB.B	#$57,D7
zbc00005A	MOVEQ	#$41,D0
	CMP.B	D0,D7
	BLT.b	zbc00006A
	MOVEQ	#$46,D0
	CMP.B	D0,D7
	BGT.b	zbc00006A
	SUB.B	#$37,D7
zbc00006A	MOVE.L	D7,D0
	MOVE.L	(SP)+,D7
	RTS

_getnum	LINK.w	A5,#-$10
	MOVEM.L	D5-D7,-(SP)
	MOVEQ	#0,D7
	MOVEQ	#1,D6
	MOVE.B	(0,A4),D5
	BSR.b	_Test
	MOVE.B	D0,D1
	EXT.W	D1
	SUB.W	#$24,D1	;'$'
	BEQ.b	zbc00009E
	SUBQ.W	#1,D1
	BEQ.b	zbc0000A6
	SUB.W	#$3A,D1
	BNE.b	zbc0000AC	;check for '_'
	MOVEQ	#10,D5
	BSR	_Get
	BRA.b	zbc0000AC

zbc00009E	MOVEQ	#$10,D5
	BSR	_Get
	BRA.b	zbc0000AC

zbc0000A6	MOVEQ	#2,D5
	BSR	_Get
zbc0000AC	BSR	_Test
	MOVEQ	#$2D,D1	;'-'
	CMP.B	D1,D0
	BNE.b	zbc0000C4
	BSR	_Get
	MOVE.L	D6,D0
	MOVEQ	#-$1,D1
	JSR	(zbc0004C6,PC)
	MOVE.L	D0,D6
zbc0000C4	BSR	_Test
	EXT.W	D0
	EXT.L	D0
	LEA	(5,A4),A0
	BTST	#7,(0,A0,D0.L)
	BEQ.b	zbc000106
	MOVE.L	D5,D0
	EXT.W	D0
	EXT.L	D0
	MOVE.L	D7,D1
	JSR	(zbc0004C6,PC)
	MOVE.L	D0,(12,SP)
	BSR	_Get
	EXT.W	D0
	EXT.L	D0
	MOVE.L	D0,-(SP)
	BSR	_hextobin
	ADDQ.W	#4,SP
	EXT.W	D0
	EXT.L	D0
	MOVE.L	(12,SP),D1
	ADD.L	D0,D1
	MOVE.L	D1,D7
	BRA.b	zbc0000C4

zbc000106	MOVE.L	D6,D0
	MOVE.L	D7,D1
	JSR	(zbc0004C6,PC)
	MOVEM.L	(SP)+,D5-D7
	UNLK	A5
	RTS

_paren	MOVEM.L	D4-D7,-(SP)
	MOVEQ	#$20,D5
	BSR	_Get
	BSR	_GetExp
	MOVE.L	D0,D4
zbc0002B2	BSR	_Test
	MOVEQ	#$29,D1
	CMP.B	D1,D0
	BEQ	zbc0003B2
	BSR	_Test
	MOVE.B	(3,A4),D1
	CMP.B	D1,D0
	BEQ	zbc0003B2
	BSR	_Test
	MOVEQ	#$20,D1
	CMP.B	D1,D0
	BEQ	zbc0003B2
	BSR	_Get
	MOVE.L	D0,D6
	EXT.W	D6
	EXT.L	D6
	MOVE.L	D6,D0
	MOVEQ	#$26,D1
	SUB.L	D1,D0
	BEQ.b	zbc00030A
	SUBQ.L	#4,D0
	BEQ	zbc000388
	SUBQ.L	#1,D0
	BEQ.b	zbc00032A
	SUBQ.L	#2,D0
	BEQ.b	zbc00032A
	SUBQ.L	#2,D0
	BEQ	zbc000388
	MOVEQ	#$2F,D1
	SUB.L	D1,D0
	BEQ.b	zbc00030A
	MOVEQ	#$1E,D1
	SUB.L	D1,D0
	BNE.b	zbc0002B2
zbc00030A	MOVEQ	#$20,D0
	CMP.L	D0,D5
	BEQ.b	zbc000320
	MOVE.L	D5,-(SP)
	MOVE.L	D7,-(SP)
	MOVE.L	D4,-(SP)
	BSR	_calc
	LEA	(12,SP),SP
	MOVE.L	D0,D4
zbc000320	MOVE.L	D6,D5
	BSR	_GetExp
	MOVE.L	D0,D7
	BRA.b	zbc0002B2

zbc00032A	MOVEQ	#$26,D0
	CMP.L	D0,D5
	BEQ.b	zbc00035E
	MOVEQ	#$7C,D0
	CMP.L	D0,D5
	BEQ.b	zbc00035E
	MOVEQ	#$5E,D0
	CMP.L	D0,D5
	BEQ.b	zbc00035E
	MOVEQ	#$20,D0
	CMP.L	D0,D5
	BEQ.b	zbc000352
	MOVE.L	D5,-(SP)
	MOVE.L	D7,-(SP)
	MOVE.L	D4,-(SP)
	BSR	_calc
	LEA	(12,SP),SP
	MOVE.L	D0,D4
zbc000352	MOVE.L	D6,D5
	BSR	_GetExp
	MOVE.L	D0,D7
	BRA	zbc0002B2

zbc00035E	MOVEQ	#$20,D0
	CMP.L	D0,D5
	BEQ.b	zbc00037C
	BSR	_GetExp
	MOVE.L	D6,-(SP)
	MOVE.L	D0,-(SP)
	MOVE.L	D7,-(SP)
	BSR	_calc
	LEA	(12,SP),SP
	MOVE.L	D0,D7
	BRA	zbc0002B2

zbc00037C	BSR	_GetExp
	MOVE.L	D0,D7
	MOVE.L	D6,D5
	BRA	zbc0002B2

zbc000388	MOVEQ	#$20,D0
	CMP.L	D0,D5
	BEQ.b	zbc0003A6
	BSR	_GetExp
	MOVE.L	D6,-(SP)
	MOVE.L	D0,-(SP)
	MOVE.L	D7,-(SP)
	BSR	_calc
	LEA	(12,SP),SP
	MOVE.L	D0,D7
	BRA	zbc0002B2

zbc0003A6	BSR	_GetExp
	MOVE.L	D0,D7
	MOVE.L	D6,D5
	BRA	zbc0002B2

zbc0003B2	MOVEQ	#$20,D0
	CMP.L	D0,D5
	BEQ.b	zbc0003C8
	MOVE.L	D5,-(SP)
	MOVE.L	D7,-(SP)
	MOVE.L	D4,-(SP)
	BSR	_calc
	LEA	(12,SP),SP
	MOVE.L	D0,D4
zbc0003C8	BSR	_Test
	MOVE.B	(3,A4),D1
	CMP.B	D1,D0
	BEQ.b	zbc0003DE
	BSR	_Test
	MOVEQ	#$20,D1
	CMP.B	D1,D0
	BNE.b	zbc0003E2
zbc0003DE	MOVE.L	D4,D0
	BRA.b	zbc0003E8

zbc0003E2	BSR	_Get
	MOVE.L	D4,D0
zbc0003E8	MOVEM.L	(SP)+,D4-D7
	RTS

_calc	MOVEM.L	D5-D7,-(SP)
	MOVE.L	($10,SP),D7
	MOVE.L	($14,SP),D6
	MOVE.B	($1B,SP),D5
	MOVE.B	D5,D0
	EXT.W	D0
	SUB.W	#$26,D0
	BEQ.b	zbc000446
	SUBQ.W	#4,D0
	BEQ.b	zbc00042E
	SUBQ.W	#1,D0
	BEQ.b	zbc000426
	SUBQ.W	#2,D0
	BEQ.b	zbc00042A
	SUBQ.W	#2,D0
	BEQ.b	zbc00043A
	SUB.W	#$2F,D0
	BEQ.b	zbc00044E
	SUB.W	#$1E,D0
	BEQ.b	zbc00044A
	BRA.b	zbc000450

zbc000426	ADD.L	D6,D7
	BRA.b	zbc000450

zbc00042A	SUB.L	D6,D7
	BRA.b	zbc000450

zbc00042E	MOVE.L	D7,D0
	MOVE.L	D6,D1
	JSR	(zbc0004C6,PC)
	MOVE.L	D0,D7
	BRA.b	zbc000450

zbc00043A	MOVE.L	D7,D0
	MOVE.L	D6,D1
	JSR	(zbc0004C0,PC)
	MOVE.L	D0,D7
	BRA.b	zbc000450

zbc000446	AND.L	D6,D7
	BRA.b	zbc000450

zbc00044A	OR.L	D6,D7
	BRA.b	zbc000450

zbc00044E	EOR.L	D6,D7
zbc000450	MOVE.L	D7,D0
	MOVEM.L	(SP)+,D5-D7
	RTS

_GetExp	MOVEM.L	D5-D7,-(SP)
	MOVEQ	#0,D7
	MOVEQ	#1,D6
	BSR	_Test
	MOVEQ	#$7E,D1
	CMP.B	D1,D0
	BNE.b	zbc000470
	BSR	_Get
	MOVEQ	#1,D7
zbc000470	BSR	_Test
	MOVEQ	#$2D,D1
	CMP.B	D1,D0
	BNE.b	zbc000488
	BSR	_Get
	MOVE.L	D6,D0
	MOVEQ	#-$1,D1
	JSR	(zbc0004C6,PC)
	MOVE.L	D0,D6
zbc000488	BSR	_Test
	MOVEQ	#$28,D1
	CMP.B	D1,D0
	BNE.b	zbc00049A
	BSR	_paren
	MOVE.L	D0,D5
	BRA.b	zbc0004A0

zbc00049A	BSR	_getnum
	MOVE.L	D0,D5
zbc0004A0	TST.L	D7
	BNE.b	zbc0004AE
	MOVE.L	D6,D0
	MOVE.L	D5,D1
	JSR	(zbc0004C6,PC)
	BRA.b	zbc0004B8

zbc0004AE	MOVE.L	D6,D0
	MOVE.L	D5,D1
	JSR	(zbc0004C6,PC)
	NOT.L	D0
zbc0004B8	MOVEM.L	(SP)+,D5-D7
	RTS

	dc.w	0

zbc0004C0	BRA	_CXD33

zbc0004C6	BRA	__CXM33

; -----------------------

__CXM33	MOVEM.L	D2/D3,-(SP)
	MOVE.L	D0,D2
	MOVE.L	D1,D3
	SWAP	D2
	SWAP	D3
	MULU.w	D1,D2
	MULU.w	D0,D3
	MULU.w	D1,D0
	ADD.W	D3,D2
	SWAP	D2
	CLR.W	D2
	ADD.L	D2,D0
	MOVEM.L	(SP)+,D2/D3
	RTS

_CXD33	TST.L	D0
	BPL	zbc00061A
	NEG.L	D0
	TST.L	D1
	BPL	zbc000610
	NEG.L	D1
	BSR	_CXD22
	NEG.L	D1
	RTS

zbc000610	BSR	_CXD22
	NEG.L	D0
	NEG.L	D1
	RTS

zbc00061A	TST.L	D1
	BPL	_CXD22
	NEG.L	D1
	BSR	_CXD22
	NEG.L	D0
	RTS

_CXD22	MOVE.L	D2,-(SP)
	SWAP	D1
	MOVE.W	D1,D2
	BNE	zbc000654
	SWAP	D0
	SWAP	D1
	SWAP	D2
	MOVE.W	D0,D2
	BEQ	zbc000644
	tst.w	d1
	beq.b	ByZero
	DIVU.w	D1,D2
	MOVE.W	D2,D0
zbc000644	SWAP	D0
	MOVE.W	D0,D2
	tst.w	d1
	beq.b	ByZero
	DIVU.w	D1,D2
	MOVE.W	D2,D0
	SWAP	D2
	MOVE.W	D2,D1
ByZero:
	MOVE.L	(SP)+,D2
	RTS

zbc000654	MOVE.L	D3,-(SP)
	MOVEQ	#$10,D3
	CMP.W	#$80,D1
	BCC	zbc000664
	ROL.L	#8,D1
	SUBQ.W	#8,D3
zbc000664	CMP.W	#$800,D1
	BCC	zbc000670
	ROL.L	#4,D1
	SUBQ.W	#4,D3
zbc000670	CMP.W	#$2000,D1
	BCC	zbc00067C
	ROL.L	#2,D1
	SUBQ.W	#2,D3
zbc00067C	TST.W	D1
	BMI	zbc000686
	ROL.L	#1,D1
	SUBQ.W	#1,D3
zbc000686	MOVE.W	D0,D2
	LSR.L	D3,D0
	SWAP	D2
	CLR.W	D2
	LSR.L	D3,D2
	SWAP	D3

	tst.w	d1
	beq.b	ByZero1
	DIVU.w	D1,D0
	MOVE.W	D0,D3
	MOVE.W	D2,D0
	MOVE.W	D3,D2
	SWAP	D1
	MULU.w	D1,D2
	SUB.L	D2,D0
	BCC	zbc0006AA
	SUBQ.W	#1,D3
	ADD.L	D1,D0
zbc0006A8	BCC.b	zbc0006A8
zbc0006AA	MOVEQ	#0,D1
	MOVE.W	D3,D1
	SWAP	D3
	ROL.L	D3,D0
	SWAP	D0
	EXG	D0,D1
ByZero1:
	MOVE.L	(SP)+,D3
	MOVE.L	(SP)+,D2
	RTS

parsedata:
_dformat	dc.b	$10	; $10 == HEX
_strflag	dc.b 0
_bflag	dc.b 0
_EOB		dc.b 0	; End of buffer char

__ctype	dc.l	$202020
	dc.l	$20202020
	dc.l	$20202828
	dc.l	$28282820
	dc.l	$20202020
	dc.l	$20202020
	dc.l	$20202020
	dc.l	$20202020
	dc.l	$20481010
	dc.l	$10101010
	dc.l	$10101010
	dc.l	$10101010
	dc.l	$10848484
	dc.l	$84848484
	dc.l	$84848410
	dc.l	$10101010
	dc.l	$10108181
	dc.l	$81818181
	dc.l	$1010101
	dc.l	$1010101
	dc.l	$1010101
	dc.l	$1010101
	dc.l	$1010101
	dc.l	$10101010
	dc.l	$10108282
	dc.l	$82828282
	dc.l	$2020202
	dc.l	$2020202
	dc.l	$2020202
	dc.l	$2020202
	dc.l	$2020202
	dc.l	$10101010
	dc.l	$20202020
	dc.l	$20202020
	dc.l	$20202828
	dc.l	$28282820
	dc.l	$20202020
	dc.l	$20202020
	dc.l	$20202020
	dc.l	$20202020
	dc.l	$20481010
	dc.l	$10101010
	dc.l	$10101010
	dc.l	$10101010
	dc.l	$10848484
	dc.l	$84848484
	dc.l	$84848410
	dc.l	$10101010
	dc.l	$10108181
	dc.l	$81818181
	dc.l	$1010101
	dc.l	$1010101
	dc.l	$1010101
	dc.l	$1010101
	dc.l	$1010101
	dc.l	$10101010
	dc.l	$10108282
	dc.l	$82828282
	dc.l	$2020202
	dc.l	$2020202
	dc.l	$2020202
	dc.l	$2020202
	dc.l	$2020202
	dc.l	$10101010
	dc.l	$20000000
_bchar	dc.l	0

; -----------------------

;****************************************************************
;********************* End of Parse *****************************
;****************************************************************

 comment |
;GetArg:
;OldGetArg:
	movem.l	d2/d3,-(sp)
	clr.l	d2
	clr.l	d3
	tst.b	(chars_in_linebuffer_flag,a5)
	bne.b	lbC000E86
lbC000E6C:
	bsr	lbC000E26
	cmpi.b	#$20,d0
	bne.b	lbC000E7A
	bsr	lbC000D7E
	bra.b	lbC000E6C

lbC000E7A:
	bsr.b	lbC000E94
	bcs.b	lbC000E86
	moveq	#3,d3
	lsl.l	#4,d2
	or.b	d0,d2
	bra.b	lbC000E7A

lbC000E86:
	move.l	d2,d0
	move.w	d3,d1
	movem.l	(sp)+,d2/d3
	cmpi.w	#1,d1

	bcs.b	.end
	push	d0
	bsr	PrintChar
	move.l	d0,-(sp)
	pea	(MyByte,pc)
	bsr	PrintLong
	addq.l	#8,sp
	pop	d0
	move.w	#0,ccr
.end:
	rts
|

lbC000E94:
 	bsr	lbC000E26
	cmpi.b	#'0',d0
	blt.b	lbC000EAE
	cmpi.b	#'9',d0
	ble.b	lbC000EB4
	cmpi.b	#'A',d0
	blt.b	lbC000EAE
	cmpi.b	#'F',d0
	ble.b	lbC000EB4
lbC000EAE:
	move.w	#1,CCR
	rts

lbC000EB4:
	bsr	lbC000D7E
	subi.b	#'0',d0
	cmpi.b	#10,d0
	blt.b	lbC000EC4
	subq.b	#7,d0
lbC000EC4:
	andi.w	#15,d0
	move.w	#0,CCR
	rts


;Virtical blanking interrupt routine
lbC000ECE:
	movem.l	d0-d7/a0-a6,-(sp)
	lea	($DFF000),a4
	move.w	(intreqr,a4),d0
	andi.w	#$20,d0
	beq	lbC000F66
	move.w	d0,(intreq,a4)
	movea.l	(GlobalPtr,pc),a5
	move.l	(BitmapPtr,pc),(bpl1pth,a4)

	lea	(VideoMode,pc),a0
	tst.w	(a0)
	beq.b	.SkipNTSC

;For NTSC support
	move.l	(BitmapPtr,pc),d0
	add.l	#(8*3)*80,d0
	move.l	d0,(bpl1pth,a4)

.SkipNTSC:
;	bset	#1,($BFE001)
	addq.b	#1,(led_vblank_counter,a5)
	cmpi.b	#60,(led_vblank_counter,a5)
	blt.b	lbC000F12
	clr.b	(led_vblank_counter,a5)
;	bclr	#1,($BFE001)
lbC000F12:
	addq.b	#1,(cursor_vblank_counter,a5)
	cmpi.b	#14,(cursor_vblank_counter,a5)
	blt.b	lbC000F2C
	clr.b	(cursor_vblank_counter,a5)
	move.l	(cursor_memory_location,a5),d0
	beq.b	lbC000F2C
	movea.l	d0,a0
	not.b	(a0)
lbC000F2C:
	move.b	(ascii_key_pressed,a5),d0
	beq.b	lbC000F62
	cmp.b	(last_ascii_key_pressed,a5),d0
	bne.b	lbC000F5C
	cmpi.b	#$14,($9C,a5)
	beq.b	lbC000F46
	addq.b	#1,($9C,a5)
	bra.b	lbC000F66

lbC000F46:
	addq.b	#1,($9B,a5)
	cmpi.b	#3,($9B,a5)
	blt.b	lbC000F66
	clr.b	($9B,a5)
	bsr	lbC001010
	bra.b	lbC000F66

lbC000F5C:
	move.b	(ascii_key_pressed,a5),(last_ascii_key_pressed,a5)
lbC000F62:
	clr.b	($9C,a5)
lbC000F66:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;Keyboard interrupt routine
lbC000F6C:
	movem.l	d0-d7/a0-a6,-(sp)
	lea	($DFF000),a4
	movea.l	(GlobalPtr,pc),a5
	move.b	($BFED01),d0
	btst	#3,d0
	beq.b	lbC001004
	moveq	#0,d0
	move.b	($BFEC01),d0
	ori.b	#$40,($BFEE01)
	clr.b	($bfec01)
;	move.b	#$FF,($BFEC01)
	not.b	d0
	lsr.w	#1,d0
	bcs.b	lbC000FD6	;go if up stroke
	cmpi.b	#$60,d0	;~$60 = $9F
	blt.b	lbC000FB6
	cmpi.b	#$68,d0	;~$68 = $97
	bge.b	lbC000FEE
	bset	d0,(keyboard_shifted_flag,a5)
	bra.b	lbC000FF4

lbC000FB6:
	move.b	(keyboard_shifted_flag,a5),d1
	andi.b	#7,d1
	beq.b	lbC000FC4
	addi.w	#$60,d0
lbC000FC4:
	lea	(ascii.MSG,pc),a0
	move.b	(a0,d0.w),d0
	beq.b	lbC000FF4
	move.b	d0,(ascii_key_pressed,a5)
	bsr.b	lbC001010
	bra.b	lbC000FF4

lbC000FD6:
	cmpi.b	#$60,d0
	blt.b	lbC000FE8
	cmpi.b	#$68,d0
	bge.b	lbC000FEE
	bclr	d0,(keyboard_shifted_flag,a5)
	bra.b	lbC000FF4

lbC000FE8:
	clr.b	(ascii_key_pressed,a5)
;	bra.b	lbC000FF4

lbC000FEE:
;	move.w	#$F62,($182,a4)
lbC000FF4:
	move.l	#$bfe001,a0
	move.w	#$46,d0	;200us delay (85us is NOT enough!!!)
..	move.b	(a0),(a0)
	dbra	d0,..

;	move.w	($9E,a5),d0
;lbC000FF8:
;	dbra	d0,lbC000FF8

	andi.b	#$BF,($BFEE01)
lbC001004:
	move.w	#8,(intreq,a4)
	movem.l	(sp)+,d0-d7/a0-a6
	rte

lbC001010:
	move.w	($A4,a5),d1
	cmpi.w	#$28,d1
	bge.b	lbC001026
	lea	($A6,a5),a0
	move.b	d0,(a0,d1.w)
	addq.w	#1,($A4,a5)
lbC001026:
	rts

ascii.MSG:
	db	0,'1234567890-=\',0
	db	'0qwertyuiop[]',0
	db	'123asdfghjkl;''$',0
	db	'456<zxcvbnm,./',0,0
	db	'789 '
	db	8
	db	9
	db	10	;CR
	db	10	;CR
	db	$1B
	db	7	;delete [offset 70]
	db	0
	db	0
	db	0
	db	0
	db	0
	db	$10	;cursor up
	db	$11	;cursor down
	db	$13	;cursor right
	db	$12	;cursor down
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	$15
	db	'~!@#$%^&*()_'
	db	'+|',0
	db	'0QWERTYUIOP{}',0
	db	'123ASDFGHJKL:"\',0
	db	'456>ZXCVBNM<>?',0,0
	db	'789 '
	db	8
	db	9
	db	10
	db	10
	db	0
	db	11	;shifted delete
	db	0
	db	0
	db	0
	db	0
	db	0
	db	12	;shifted cursor up
	db	13	;shifted cursor down
	db	$13
	db	$12
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	$15

;Character set (for the first 97 ASCII characters)

	dc.b	'font!'
	even

charset:
;	incbin	'charset'
	incbin	'newfont'

Info.msg:
 db $a
 db 'This program owes its existence to RomCrack, '
 db 'written by the Swiss Cracking',$a,'Association in 1988. '
 db 'Credit goes to Andreas Hommel for the mini-assembler. ',$a
 db 'Thanks to John Veldthuis for the copper disassembler. Many thanks to'
 db ' Dave',$a,'Campbell for his commented version of RomCrack.',$a
 db 'Special thanks also due to Dan Zenchelsky for the expression '
 db 'evaluating',$a,'routine and his generous assistance with '
 db 'all aspects of this program.',$a
 db 'If you want to contact me (Dan Babcock) write to: ',$a,$a
 db 9,'P.O. Box 1532',$a,9,'Southgate, MI  48195',$a,9,'USA'
 db $a,0
	even

ROMCRACKGAMMA.MSG:
	db	'VBRMon V1.04 (March 22, 1991) - '
	db	'Copyright (C) 1991 by Dan Babcock',$A,0
PresstheHELPk.MSG:
	db	'Press the HELP key for a command overview.',$A,0
ROMCracksmemo.MSG:
	db	'VBRMon''s memory:  Code: $%08lx, Screen: $%'
;	db	'06lx, BSS: $%06lx,  CPU: 680%d0',$A,$A,0
	db	'08lx, Data: $%08lx',$A,$A,0
NogurusROMCra.MSG:
;	db	'No gurus, '
	db	'VBRMon invoked by '
	db	'vector $%03lx.',$A,$A,0
RESET.MSG:
	db	'RESET',0
Debug.MSG:
	db	'Debug()',0
GuruMeditatio.MSG:
	db	'Guru Meditation #%08lx.%08lx  (%s).',$A
	db	'Task address :  $%08lx,  Task Name : "%s".',$A
	db	'Everything is under control now.',$A,$A,0
D008lx08lx08l.MSG:
	db	'D0=%08lx %08lx %08lx %08lx %08lx %08lx %08lx'
	db	' %08lx',$A
	db	'A0=%08lx %08lx %08lx %08lx %08lx %08lx %08lx'
	db	10
	db	'SSP=%08lx USP=%08lx SR=%04x  PC=%08lx ',0,0
	even
lbL0015E6:
	dl	3
	dl	$48
	dl	4
	dl	$56
	dl	5
	dl	$6A
	dl	8
	dl	$79
	dl	10
	dl	$8D
	dl	11
	dl	$9B
	dl	$81000005
	dl	$A9
	dl	$81000009
	dl	$BD
	dl	$FB1C9A86
	dl	0
	dl	$41646472
	dl	$65737320
	dl	$4572726F
	dl	$7200496C
	dl	$6C656761
	dl	$6C20696E
	dl	$73747275
	dl	$6374696F
	dl	$6E004469
	dl	$76696465
	dl	$20627920
	dl	$7A65726F
	dl	$507269
	dl	$76696C65
	dl	$67652076
	dl	$696F6C61
	dl	$74696F6E
	dl	$4C696E
	dl	$652D4120
	dl	$6F70636F
	dl	$6465004C
	dl	$696E652D
	dl	$46206F70
	dl	$636F6465
	dl	$4D656D
	dl	$6F727920
	dl	$6C697374
	dl	$20636F72
	dl	$72757074
	dl	$4D656D
	dl	$6F727920
	dl	$6368756E
	dl	$6B206672
	dl	$65656420
	dl	$74776963
	dw	$6500
;Wellahem.MSG:
;	db	'Well, ahem...',0
CommandListMs.MSG:

;Help:

	db	10
;	db	10
;	db	'Command List:',$A

	db	' A <start>'
	db	9,9
	db	9
	db	' Assemble',$A

	db	' D <start> <end>'
	db	9
	db	9
	db	' Disassemble',$A

	db	' U <start> <end>'
	db	9
	db	9
	db	' Copper unassemble',$A

	db	' M <start> <end>'
	db	9
	db	9
	db	' Show memory (Hex and ASCII)',$A
	db	' : addr byte <byte>'
	db	9,9
	db	' Modify memory bytes',$A

	db	' T start end dest'
	db	9
	db	9
	db	' Transfer memory',$A

	db	' H start end byte <byte>'
	db	9
	db	' Hunt',$A

	db	' O addr'
	db	9,9,9,9
	db	' Hunt for offset (pc-rel or branch) reference',$A

	db	' L'
	db	9
	db	9
	db	9
	db	9
	db	' List hunts',$A

	db	' C start1 end1 start2'
	db	9,9
	db	' Compare memory, listing differences',$A

;	db	' Z mem1a mem1b mem2 mem3'
	db	' TC start1 end1 start2 start3'
;	db	9
	db	'    Triple compare (see doc for info)',$A

	db	' F start end byte <byte>'
	db	9
	db	' Fill memory',$A

	db	' J addr'
	db	9,9
	db	9
	db	9
	db	' Jump to address (via JSR)',$A
	db	' R<regname=value>'
	db	9
	db	9
	db	' Show or modify registers',$A
	db	' P'
	db	9
	db	9
	db	9
	db	9
	db	' Toggle Printer on/off',$A

	db	' X/XMOD'
	db	9
	db	9
	db	9,9
	db	' Exit/exit with modified registers',$A

;	db	' Q'
;	db	9
;	db	9
;	db	9
;	db	9
;	db	' Quit and restore lower 512K',$A

	db	' FIRE <port>'
	db	9
	db	9
	db	9
	db	' Joystick autofire',$A

	db	' E'
	db	9
	db	9
	db	9
	db	9
	db	' Fix ExecBase and reinstall VBRMon',$A

	db	' N'
	db	9
	db	9
	db	9
	db	9
	db	' Toggle NTSC/PAL',$A

	db	' GURU'
	db	9
	db	9
	db	9
	db	9
	db	' Enable guru trapping',$A

	db	' SAVE/RESTORE addr'
	db	9
	db	9
	db	' Save/restore registers (uses 78 bytes)',$A

	db	' S drivenumber'
	dcb.b	3,9
	db	' Step (find current track)',$A

	db	' ? expression'
	db	9
	db	9
	db	9
	db	' Calculate (including +,-,*,/,&,|,^,~,$,_,%)',$A

	db	' B <byte>'
	db	9
	db	9
	db	9
	db	' Set/view numeric base (always in decimal)',$A

	db	' INFO'
	db	9,9
	db	9
	db	9
	db	' Info about this program',$A

;	db	' Help-Key'
;	db	9
;	db	9
;	db	9
;	db	'Show this page',$A

;	db	' Shift/Delete key'
;	db	9
;	db	9
;	db	' Cursor home/clear screen',$A

; db ' Control key stops output till release. Escape key aborts.',$a

;	db	' Escape key'
;	db	9
;	db	9
;	db	9
;	db	' Abort',$A

;	db	' Control key'
;	db	9
;	db	9
;	db	9
;	db	' Stop output till release',$A

	db	'.',0
	even

lbC00187A:
	movem.l	d2-d7/a2-a4,-(sp)
	movea.l	a0,a3
	move.l	a1,d0
	bclr	#0,d0
	movea.l	d0,a4
	bsr.b	lbC0018A2
	move.b	#9,(a3)+
;	move.b	#4,(a3)+
	bsr	lbC001962
	move.b	#10,(a3)+
	clr.b	(a3)+
	move.l	a4,d0
	move.b	d7,d1
	movem.l	(sp)+,d2-d7/a2-a4
	rts

lbC0018A2:
	move.w	(a4)+,d5
	move.b	#$C0,d4
	and.b	d5,d4
	lea	(lbL001E8E,pc),a0
	moveq	#0,d2
lbC0018B0:
	move.w	d5,d1
	and.w	(a0)+,d1
	cmp.w	(a0)+,d1
	beq.b	lbC0018BE
	addq.w	#1,d2
	addq.w	#2,a0
	bra.b	lbC0018B0

lbC0018BE:
	move.w	(a0),d6
	bclr	#14,d6
	sne	d7
	lea	(ORIMOVEPMOVEP.MSG,pc),a0
lbC0018CA:
	movea.l	a3,a1
lbC0018CC:
	move.b	(a0)+,d0
	cmpi.b	#$2B,d0
	beq.b	lbC0018E4
	move.b	d0,(a1)+
	cmpi.b	#$5A,d0
	bcs.b	lbC0018CC
	bclr	#5,(-1,a1)
	bra.b	lbC0018E8

lbC0018E4:
	move.b	#$2E,(a1)+
lbC0018E8:
	dbra	d2,lbC0018CA

	movea.l	a1,a3
	lea	(-4,a3),a0
	cmpi.b	#$40,(a0)
	beq.b	lbC001900
	addq.l	#2,a0
	cmpi.b	#$40,(a0)
	bne.b	lbC001912
lbC001900:
	move.w	d5,d0
	lsr.w	#7,d0
	andi.w	#$1E,d0
	lea	(lbB001E48,pc),a2
	adda.w	d0,a2
	move.b	(a2)+,(a0)+
	move.b	(a2),(a0)
lbC001912:
	move.w	d5,d0
	andi.w	#$F138,d0
	cmpi.w	#$108,d0
	bne.b	lbC001928
	ori.w	#$20,d5
	ori.b	#$80,d4
	bra.b	lbC001930

lbC001928:
	move.w	#$200,d0
	and.w	d6,d0
	beq.b	lbC001936
lbC001930:
	subi.b	#$40,d4
	bra.b	lbC00193E

lbC001936:
	move.w	#1,d0
	and.w	d6,d0
	beq.b	lbC001960
lbC00193E:
	move.b	d4,d0
	move.b	#$4C,(a3)
	cmpi.b	#$80,d0
	beq.b	lbC00195C
	move.b	#$57,(a3)
	cmpi.b	#$40,d0
	beq.b	lbC00195C
	move.b	#$42,(a3)
	move.b	#$C0,d0
lbC00195C:
	or.b	d0,d6
	addq.w	#1,a3
lbC001960:
	rts

lbC001962:
	move.w	d5,d0
	andi.w	#$FFF8,d0
	cmpi.w	#$4E70,d0
	bne.b	lbC001970
	rts

lbC001970:
	lea	(USP.MSG,pc),a0
	move.w	d5,d0
	andi.w	#$FFF0,d0
	cmpi.w	#$4E60,d0
	bne.b	lbC0019A8
	move.w	d5,d0
	andi.w	#$FFC7,d5
	move.w	#8,d1
	or.w	d1,d5
	and.w	d1,d0
	bne.b	lbC0019A0
lbC001990:
	move.l	a0,-(sp)
	bsr	lbC001A72
	move.b	#$2C,(a3)+
	movea.l	(sp)+,a0
	bra	lbC001DAC

lbC0019A0:
	bsr	lbC001DAC
	bra	lbC001AFC

lbC0019A8:
	cmpi.w	#$4E40,d0
	bne.b	lbC0019BC
	move.b	#$23,(a3)+
	move.w	d5,d0
	andi.w	#15,d0
	bra	lbC001DE0

lbC0019BC:
	lea	(SR.MSG,pc),a0
	andi.w	#$FFC0,d0
	cmpi.w	#$40C0,d0
	beq.b	lbC0019A0
	cmpi.w	#$46C0,d0
	beq.b	lbC001990
	lea	(CCR.MSG,pc),a0
	cmpi.w	#$44C0,d0
	beq.b	lbC001990
	move.w	d6,d0
	andi.w	#$30,d0
	beq.b	lbC001A08
	cmp.w	#$10,d0
	beq.b	lbC001A08
	bsr	lbC001A72
	move.b	#$2C,(a3)+
	move.w	d6,d1
	moveq	#1,d0
	andi.w	#$30,d1
	cmp.w	#$30,d1
	beq.b	lbC001A00
	moveq	#0,d0
lbC001A00:
	bsr	lbC001D5A
	bra	lbC001BFA

lbC001A08:
	move.w	d5,d0
	andi.w	#$F0F8,d0
	cmp.w	#$50C8,d0
	bne.b	lbC001A1C
	andi.w	#7,d5
	or.w	#$15C0,d5
lbC001A1C:
	move.w	d6,d0
	andi.w	#$400,d0
	beq.b	lbC001A2C
	andi.w	#$E07,d5
	or.w	#$10D8,d5
lbC001A2C:
	move.w	d6,d0
	andi.w	#$1000,d0
	beq.b	lbC001A48
	move.w	d5,d1
	andi.w	#$E07,d5
	or.w	#$1000,d5
	andi.w	#8,d1
	beq.b	lbC001A48
	or.w	#$120,d5
lbC001A48:
	move.w	d5,d0
	andi.w	#$C000,d0
	bne.b	lbC001A72
	move.w	d5,d0
	andi.w	#$3000,d0
	beq.b	lbC001A72
	bsr.b	lbC001A72
	move.b	#$2C,(a3)+
	bsr	lbC001D5A
	move.w	d5,d0
	andi.w	#$1C0,d0
	lsr.w	#3,d0
	andi.w	#$F000,d5
	or.w	d1,d5
	or.w	d0,d5
lbC001A72:

;key routine?
	move.w	d5,d0
	andi.w	#$FF00,d0
	cmp.w	#$800,d0
	bne.b	lbC001A8A
	move.b	#'#',(a3)+
	move.w	(a4)+,d1
	andi.w	#$1F,d1
	bra.b	lbC001ADE

lbC001A8A:
	move.w	d6,d0
	andi.w	#$100,d0
	beq.b	lbC001AE6
	move.w	d5,d0
	andi.w	#$F020,d0
	cmp.w	#$E020,d0
	bne.b	lbC001AA4
	andi.w	#$FFC7,d5
	bra.b	lbC001AF2

lbC001AA4:
	cmp.w	#$E000,d0
	bne.b	lbC001AAE
	andi.w	#$FFC7,d5
lbC001AAE:
	andi.w	#$F000,d0
	cmp.w	#$7000,d0
	bne.b	lbC001AD0
	move.b	#$23,(a3)+
	move.b	d5,d0
	ext.w	d0
	bpl.b	lbC001ACC
	move.l	d0,-(sp)
	move.b	#$2D,(a3)+
	move.l	(sp)+,d0
	neg.w	d0
lbC001ACC:
	bra	lbC001DE0

;Notmoveq -- 
lbC001AD0:
	move.b	#$23,(a3)+

;Bug fix here: if no size extension printed than don't look at the opcode;
;instead, use 2 (word)

;	cmp.b	#'.',(-4,a3)
;	bne.b	hardcode4

	bsr	lbC001D5A
	tst.w	d1
	bne.b	lbC001ADE
	moveq	#8,d1
lbC001ADE:
	move.w	d1,d0
	bsr	lbC001DE0
	bra.b	lbC001AFC

;HardCode4:
;	move.w	#$0f00,$dff180
;	moveq	#4,d1
;	bra.b	lbC001ADE

lbC001AE6:
	move.w	d6,d0
	andi.w	#$30,d0
	cmpi.w	#$10,d0
	bne.b	lbC001B00
lbC001AF2:
	clr.w	d0
	bsr	lbC001D5A
	bsr	lbC001BFA
lbC001AFC:
	move.b	#$2C,(a3)+
lbC001B00:
	move.w	d6,d0
	andi.w	#4,d0
	beq.b	lbC001B1A
	move.w	d5,d0
	ext.w	d0
	bne.b	lbC001B12
	move.w	(a4)+,d0
	subq.w	#2,d0
lbC001B12:
	ext.l	d0
	add.l	a4,d0
	bra	lbC001E0C

lbC001B1A:
	move.w	d6,d0
	andi.w	#$200,d0
	beq.b	lbC001B42
	move.w	d5,d0
	andi.w	#$400,d0
	beq.b	lbC001B3A
	move.w	(a4)+,d0
	move.w	d0,-(sp)
	bsr.b	lbC001B42
	move.b	#$2C,(a3)+
	move.w	(sp)+,d0
	bra	lbC001CC6

lbC001B3A:
	bsr	lbC001CC4
	move.b	#$2C,(a3)+
lbC001B42:
	move.w	d5,d0
	andi.w	#$FFF0,d0
	cmpi.w	#$4E50,d0
	bne.b	lbC001B6C
	btst	#3,d5
	bne.b	lbC001B64
	bsr.b	lbC001B64
	move.b	#$2C,(a3)+
	move.b	#$23,(a3)+
	move.w	(a4)+,d0
	bra	lbC001DF2

lbC001B64:
	andi.w	#$FFC7,d5
	ori.w	#8,d5
lbC001B6C:
	move.w	d6,d0
	andi.w	#2,d0
	beq	lbC001D6C
	move.w	d6,d0
	andi.w	#8,d0
	beq.b	lbC001B86
	bsr	lbC001D8A
	move.b	#$2C,(a3)+
lbC001B86:
	move.w	d5,d0
	andi.w	#$3F,d0
	move.w	d0,d1
	cmpi.w	#$3A,d0
	bne.b	lbC001BA8
	move.w	(a4)+,d0
	subq.w	#2,d0
	ext.l	d0
	add.l	a4,d0
	bsr	lbC001E0C
	lea	(PC.MSG,pc),a0
	bra	lbC001DAC

lbC001BA8:
	cmpi.w	#$38,d0
	bne.b	lbC001BBE
	move.w	(a4)+,d0
	bsr	DsmPutByte
	move.b	#$2E,(a3)+	;'.'
	move.b	#$57,(a3)+	;'W'
	rts

lbC001BBE:
	cmp.w	#$39,d0
	bne.b	lbC001BD4
	move.l	(a4)+,d0
	bsr	lbC001E0C
	move.b	#$2E,(a3)+
	move.b	#$4C,(a3)+
	rts

lbC001BD4:
	cmpi.w	#$3C,d0
	beq	lbC001D6E
	cmpi.w	#$3B,d0
	beq.b	lbC001BEE
	andi.w	#$38,d0
	cmp.w	#$38,d0
	beq	lbC001D66
lbC001BEE:
	move.w	d1,d0
	andi.w	#$38,d0
	andi.w	#7,d1
	lsr.b	#3,d0
lbC001BFA:
	dbra	d0,lbC001C06

lbC001BFE:
	move.b	#$44,(a3)+
	bra	lbC001D50

lbC001C06:
	dbra	d0,lbC001C22

lbC001C0A:
	cmpi.b	#7,d1
	bne.b	lbC001C1A
	move.b	#$53,(a3)+
	move.b	#$50,(a3)+
	rts

lbC001C1A:
	move.b	#$41,(a3)+
	bra	lbC001D50

lbC001C22:
	dbra	d0,lbC001C32

lbC001C26:
	move.b	#$28,(a3)+
	bsr.b	lbC001C0A
	move.b	#$29,(a3)+
	rts

lbC001C32:
	dbra	d0,lbC001C3E

	bsr.b	lbC001C26
	move.b	#$2B,(a3)+
	rts

lbC001C3E:
	dbra	d0,lbC001C48

	move.b	#$2D,(a3)+
	bra.b	lbC001C26

lbC001C48:
	dbra	d0,lbC001C60

	move.w	(a4)+,d0
	btst	#15,d6
	bne.b	lbC001C5A
	bsr	lbC001DF2
	bra.b	lbC001C5E

lbC001C5A:
	bsr	lbC001DB6
lbC001C5E:
	bra.b	lbC001C26

lbC001C60:
	dbra	d0,lbC001CAA

	move.b	(1,a4),d0
	ext.w	d0
	beq.b	lbC001C70
	bsr	lbC001DF2
lbC001C70:
	move.b	#$28,(a3)+
	bsr.b	lbC001C0A
	move.b	#$2C,(a3)+
lbC001C7A:
	move.b	(a4),d1
	lsr.b	#4,d1
	andi.w	#7,d1
	btst	#7,(a4)
	bmi.b	lbC001C8E
	bsr	lbC001BFE
	bra.b	lbC001C92

lbC001C8E:
	bsr	lbC001C0A
lbC001C92:
	move.b	#$2E,(a3)+
	moveq	#$57,d0
	move.w	(a4)+,d1
	btst	#11,d1
	beq.b	lbC001CA2
	moveq	#$4C,d0
lbC001CA2:
	move.b	d0,(a3)+
	move.b	#$29,(a3)+
	rts

lbC001CAA:
	move.w	(a4),d0
	ext.w	d0
	bsr	lbC001B12
	move.b	#$28,(a3)+
	move.b	#$50,(a3)+
	move.b	#$43,(a3)+
	move.b	#$2C,(a3)+
	bra.b	lbC001C7A

lbC001CC4:
	move.w	(a4)+,d0
lbC001CC6:
	move.w	d5,d1
	andi.w	#$38,d1
	cmpi.w	#$20,d1
	bne.b	lbC001CDE
	moveq	#15,d2
lbC001CD4:
	roxr.w	#1,d0
	roxl.w	#1,d1
	dbra	d2,lbC001CD4

	move.w	d1,d0
lbC001CDE:
	clr.b	d2
	clr.l	d1
	clr.b	d3
lbC001CE4:
	btst	d1,d0
	bne.b	lbC001CEC
	clr.b	d2
	bra.b	lbC001D1A

lbC001CEC:
	addq.b	#1,d1
	tst.b	d2
	beq.b	lbC001D14
	cmpi.b	#8,d1
	beq.b	lbC001D14
	cmpi.b	#9,d1
	beq.b	lbC001D14
	cmpi.b	#$10,d1
	beq.b	lbC001D14
	btst	d1,d0
	beq.b	lbC001D14
	cmpi.b	#$2D,d2
	beq.b	lbC001D1C
	moveq	#$2D,d2
	move.b	d2,(a3)+
	bra.b	lbC001D1C

lbC001D14:
	subq.b	#1,d1
	bsr.b	lbC001D24
	st	d2
lbC001D1A:
	addq.b	#1,d1
lbC001D1C:
	cmpi.b	#$10,d1
	blt.b	lbC001CE4
	rts

lbC001D24:
	movem.l	d0/d1,-(sp)
	tst.b	d3
	beq.b	lbC001D36
	cmpi.b	#$2D,d2
	beq.b	lbC001D36
	move.b	#$2F,(a3)+
lbC001D36:
	moveq	#$44,d0
	cmpi.b	#8,d1
	blt.b	lbC001D40
	moveq	#$41,d0
lbC001D40:
	move.b	d0,(a3)+
	andi.b	#7,d1
	bsr.b	lbC001D50
	st	d3
	movem.l	(sp)+,d0/d1
	rts

lbC001D50:
	move.b	#$30,d0
	add.b	d1,d0
	move.b	d0,(a3)+
	rts

lbC001D5A:
	move.w	d5,d1
;	and.w	#$ffc0,d1
;	cmp.w	#$44fc,d1
;	bne.b	.notccr
;	moveq	#4,d1
;	rts
;.notccr:

	andi.w	#$E00,d1
	lsr.w	#4,d1
	lsr.w	#5,d1
	rts

lbC001D66:
	lea	(ILLEGALMODE7.MSG,pc),a0
	bra.b	lbC001DAC

lbC001D6C:
	rts

lbC001D6E:
	move.w	d6,d0
	andi.w	#$800,d0
	beq.b	lbC001D8A
	lea	(SR.MSG,pc),a0
	move.w	d6,d0
	andi.w	#$C0,d0
	cmpi.w	#$C0,d0
	bne.b	lbC001DAC
	addq.l	#3,a0	;note dirty addressing
	bra.b	lbC001DAC

lbC001D8A:
	move.b	#$23,(a3)+	;'#'
	move.w	d6,d0
	andi.w	#$C0,d0
	cmpi.w	#$80,d0
	bne.b	lbC001D9E
	move.l	(a4)+,d0
	bra	lbC001E10

lbC001D9E:
	cmpi.w	#$40,d0
	bne.b	lbC001DA8

;not used for sr/ccr

	move.w	(a4)+,d0
	bra.b	DsmPutByte

lbC001DA8:
	move.w	(a4)+,d0
	bra.b	lbC001DE0

lbC001DAC:
	tst.b	(a0)
	beq.b	lbC001DB4
	move.b	(a0)+,(a3)+
	bra.b	lbC001DAC

lbC001DB4:
	rts

lbC001DB6:
	clr.w	-(sp)
	ext.l	d0
	bpl.b	lbC001DC2
	move.b	#$2D,(a3)+
	neg.l	d0
lbC001DC2:
	divu.w	#10,d0
	swap	d0
	addi.b	#$30,d0
	move.w	d0,-(sp)
	clr.w	d0
	swap	d0
	tst.w	d0
	bne.b	lbC001DC2
lbC001DD6:
	move.w	(sp)+,d0
	beq.b	lbC001DDE
	move.b	d0,(a3)+
	bra.b	lbC001DD6

lbC001DDE:
	rts

lbC001DE0:
	cmpi.b	#9,d0
	bhi.b	lbC001DEE
	addi.b	#$30,d0
	move.b	d0,(a3)+
	rts

;Put byte routine
lbC001DEE:
	moveq	#1,d1
	bra.b	lbC001E12

lbC001DF2:
	movem.l	d1/a0/a1,-(sp)
	tst.w	d0
	bpl.b	lbC001E00
	neg.w	d0
	move.b	#$2D,(a3)+	;'-'
lbC001E00:
	bsr.b	DsmPutByte
	movem.l	(sp)+,d1/a0/a1
	rts

DsmPutByte:
	moveq	#3,d1	;print a byte
	bra.b	lbC001E12

lbC001E0C:
;	moveq	#5,d1
	moveq	#7,d1	;***
	bra.b	lbC001E12

lbC001E10:
	moveq	#7,d1
lbC001E12:
	move.l	d2,-(sp)
	clr.w	-(sp)
lbC001E16:
	move.b	d0,d2
	lsr.l	#4,d0
	andi.w	#15,d2
	move.b	(lbB001E38,pc,d2.w),d2
	move.w	d2,-(sp)
	dbra	d1,lbC001E16

	move.b	#$24,(a3)+
lbC001E2C:
	move.w	(sp)+,d0
	beq.b	lbC001E34
	move.b	d0,(a3)+
	bra.b	lbC001E2C

lbC001E34:
	move.l	(sp)+,d2
	rts

lbB001E38:
	db	$30
	db	$31
	db	$32
	db	$33
	db	$34
	db	$35
	db	$36
	db	$37
	db	$38
	db	$39
	db	$41
	db	$42
	db	$43
	db	$44
	db	$45
	db	$46
lbB001E48:
	db	$54
	db	$20
	db	$52
	db	$41
	db	$48
	db	$49
	db	$4C
	db	$53
	db	$43
	db	$43
	db	$43
	db	$53
	db	$4E
	db	$45
	db	$45
	db	$51
	db	$56
	db	$43
	db	$56
	db	$53
	db	$50
	db	$4C
	db	$4D
	db	$49
	db	$47
	db	$45
	db	$4C
	db	$54
	db	$47
	db	$54
	db	$4C
	db	$45
ILLEGALMODE7.MSG:
	db	'ILLEGALMODE7',0
	db	'BADMODE',0
SR.MSG:
	db	'SR',0
CCR.MSG:
	db	'CCR',0
USP.MSG:
	db	'USP',0
PC.MSG:
	db	'(PC)',0,0
lbL001E8E:
	dl	$FF000000
	dl	$80BF1B8
	dl	$1080022
	dl	$F1B80188
	dl	$12F1C0
	dl	$1000012
	dl	$F1C00140
	dl	$12F1C0
	dl	$1800012
	dl	$F1C001C0
	dl	$12FF00
	dl	$200080B
	dl	$FF000400
	dl	$BFF00
	dl	$600000B
	dl	$FFC00800
	dl	$2FFC0
	dl	$8400002
	dl	$FFC00880
	dl	$2FFC0
	dl	$8C00002
	dl	$FF000A00
	dl	$80BFF00
	dl	$C00000B
	dl	$F0001000
	dl	$C2F000
	dl	$20000082
	dl	$F0003000
	dl	$42FFC0
	dl	$40C00002
	dl	$FF004000
	dl	$3F1C0
	dl	$41800022
	dl	$F1C041C0
	dl	$32FF00
	dl	$42000003
	dl	$FFC044C0
	dl	$2FF00
	dl	$44000003
	dl	$FFC046C0
	dl	$2FF00
	dl	$46000003
	dl	$FFC04800
	dl	$2FFF8
	dl	$48400002
	dl	$FFF84880
	dl	$42FFF8
	dl	$48C00082
	dl	$FFC04840
	dl	$2FF80
	dl	$48800202
	dl	$FFFF4AFC
	dl	$FF00
	dl	$4A000003
	dl	$FFC04AC0
	dl	$2FF80
	dl	$4C800202
	dl	$FFF04E40
	dl	$FFF8
	dl	$4E500002
	dl	$FFF84E58
	dl	$2FFF0
	dl	$4E600002
	dl	$FFFF4E70
	dl	$FFFF
	dl	$4E710000
	dl	$FFFF4E72
	dl	$FFFF
	dl	$4E734000
	dl	$FFFF4E75
	dl	$4000FFFF
	dl	$4E760000
	dl	$FFFF4E77
	dl	$4000FFC0
	dl	$4E80A002
	dl	$FFC04EC0
	dl	$C002F0F8
	dl	$50C80002
	dl	$FFC051C0
	dl	$2F0C0
	dl	$50C00002
	dl	$F1005000
	dl	$103F100
	dl	$51000103
	dl	$FF006100
	dl	$2004FFFF
	dl	$60004004
	dl	$FF006000
	dl	$4004F0FF
	dl	$60000004
	dl	$F0006000
	dl	$4F100
	dl	$70000120
	dl	$F1C080C0
	dl	$22F1F0
	dl	$81001002
	dl	$F1C081C0
	dl	$22F100
	dl	$80000023
	dl	$F1008100
	dl	$13F1C0
	dl	$90C00072
	dl	$F1C091C0
	dl	$B2F130
	dl	$91001003
	dl	$F1009000
	dl	$23F100
	dl	$91000013
	dl	$F1C0B0C0
	dl	$72F1C0
	dl	$B1C000B2
	dl	$F100B000
	dl	$23F138
	dl	$B1080403
	dl	$F100B100
	dl	$13F1F0
	dl	$C1001002
	dl	$F1C0C0C0
	dl	$22F1F8
	dl	$C1400022
	dl	$F1F8C148
	dl	$32F1F8
	dl	$C1880022
	dl	$F1C0C1C0
	dl	$22F100
	dl	$C0000023
	dl	$F100C100
	dl	$13F1C0
	dl	$D0C00072
	dl	$F1C0D1C0
	dl	$B2F130
	dl	$D1001003
	dl	$F100D000
	dl	$23F100
	dl	$D1000013
	dl	$FFC0E0C0
	dl	$2FFC0
	dl	$E1C00002
	dl	$FFC0E2C0
	dl	$2FFC0
	dl	$E3C00002
	dl	$FFC0E4C0
	dl	$2FFC0
	dl	$E5C00002
	dl	$FFC0E6C0
	dl	$2FFC0
	dl	$E7C00002
	dl	$F118E000
	dl	$103F118
	dl	$E1000103
	dl	$F118E008
	dl	$103F118
	dl	$E1080103
	dl	$F118E010
	dl	$103F118
	dl	$E1100103
	dl	$F118E018
	dl	$103F118
	dl	$E1180103
	dl	0
	dw	0
ORIMOVEPMOVEP.MSG:
	db	'ORI+MOVEP+MOVEP+BTStBCHgBCLrBSEtANDI+SUBI+AD'
	db	'DI'
	db	'+BTST.bBCHG.bBCLR.bBSET.bEORI+CMPI+MOVE.bMOV'
	db	'E.lMOVE.wMOVeNEGX+CHkLEA.lCLR+MOVeNEG+MOVeNO'
	db	'T+NBCdSWApEXT.wEXT.lPEaMOVEM+ILLEGAlTST+TAsM'
	db	'OVEM+TRApLINkUNLkMOVeRESEtNOpSTOpRTeRTsTRAPv'
	db	'RTrJSrJMpDB@cSfS@cADDQ+SUBQ+BSrBRA.lBRA.sB@C'
	db	'.lB@C.sMOVEqDIVuSBCdDIVsOR+OR+SUBA.wSUBA.lSU'
	db	'BX+SUB+SUB+CMPA.wCMPA.lCMP+CMPM+EOR+ABCdMULu'
	db	'EXgEXgEXgMULsAND+AND+ADDA.wADDA.lADDX+ADD+AD'
	db	'D+ASrASlLSrLSlROXrROXlROrROlASR+ASL+LSR+LSL+'
	db	'ROXR+ROXL+ROR+ROL+UNKNOWn',0
	db	'ENDE'
	even

	include	"display.s"	;copper disassembler
	include	"hd:misc/asm2/asm.s"	;mini-assembler

TheEnd:

	SECTION romcrack4rs0022E8,DATA
doslibrary.MSG:
	db	'dos.library',0
CON016640110R.MSG:
	db	'CON:0/16/640/110/VBRMon V1.04 - '
	db	'Copyright (C) 1991 by Dan Babcock',0
	even
FormatROMCrac.MSG:
	db	'Format: `VBRMon'' or `VBRMon $code $chip'
	db	' $data''',$A,0

;Need68010.msg:
;	db	'Sorry, a 68010 or higher is needed to use VBRMon'
;	db	'.',$a,0
;KickMemPtrocc.MSG:
;	db	'KickMemPtr occuppied, can''t install VBRCrac'
;	db	'k!',$A,0
;KickTagPtrocc.MSG:
;	db	'KickTagPtr occuppied, can''t install VBRCrac'
;	db	'k!',$A,0
HeytheresnoCH.MSG:
	db	'Hey, there''s no CHIP memory at $%08lx!',$A,0
Theresnofreem.MSG:
	db	'There''s no free memory at $%08lx, try again'
	db	'!',$A,0
Operationcanc.MSG:
	db	'Operation cancelled, VBRMon not activated.'
	db	10
	db	0
ROMCrackisalr.MSG:
	db	'VBRMon is already active!',$A
	db	'Do you want to kill it (y/n) ?  ',0
ROMCrackkille.MSG:
	db	'VBRMon killed, resources freed.',$A,0
ROMCrackstill.MSG:
	db	'VBRMon still active.',$A,0
ROMCrackiniti.MSG:
	db	'VBRMon initialized successfully. '
	db	'Press both mouse buttons to invoke.'
	db	$a,0
SomewhatOK.MSG:
	db	'VBRMon initialized somewhat successfully. '
	db	'I hope you have a GOMF button.'
	db	$a,0

WhereshallIpu.MSG:
	db	'VBRMon V1.04 - '
	db	'Copyright (C) 1991 by Dan Babcock',$a,$a

	db	'Where shall I put the VBRMon program (%ld '
	db	'bytes) ($%08lx) :  $',0
VideoRAMldbyt.MSG:
	db	'Video-RAM (%ld bytes of CHIP memory) ($%08lx'
	db	') :  $',0
Workspaceldby.MSG:
	db	'Workspace (%ld bytes) ($%08lx) :  $',0
Program06lxVi.MSG:
	db	10
	db	'Program: $%08lx,  Video-RAM: $%08lx, Workspa'
	db	'ce: $%08lx',$A
	db	'Is this correct ('
	db	$1B
	db	'[33my'
	db	$1B
	db	'[0mes / '
	db	$1B
	db	'[33mn'
	db	$1B
	db	'[0mo / '
	db	$1B
	db	'[33mc'
	db	$1B
	db	'[0mancel) ?  ',0
	even

	include	"hd:misc/asm2/relocate.asm"

	SECTION romcrack4rs002600,BSS
DosBase:
	ds.l	1
lbL002604:
	ds.l	1
StdInput:
	ds.l	1
StdOutput:
	ds.l	1
lbL002610:
	ds.l	1
ConFileHandle:
	ds.l	1
lbL002618:
	ds.l	1
lbL00261C:
	ds.l	$14
lbL00266C:
	ds.l	$40
lbL00276C:
	ds.l	9
	end
