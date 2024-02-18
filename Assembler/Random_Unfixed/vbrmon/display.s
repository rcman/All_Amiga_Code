;*** Routine to disassemble Copper lists in memory and output a listing ***

;John Veldthuis
;21 Ngatai Street
;Manaia, Taranaki, 4851
;New Zealand

**	Entry	A4 = Start of Copper List
**		D7 = Length of Copper List (in instructions = 4 bytes)

Unassemble:
	moveq	#10,d7
	bsr	GetArg
	movea.l	d0,a4
	bcc.b	.skipthis
	move.l	a3,a4
	bra.b	Disassem
.skipthis:
	bsr	GetArg
	bcs.b	Disassem

;End address in d0.l
	sub.l	a4,d0
	bmi.b	Disassem
	lsr.l	#2,d0
	move.l	d0,d7

1$:
;	lea	(Noadd,pc),a0
;	tst.l	(a0)			;test if address wanted
;	bne.b	2$

Disassem:
	tst.l	d7
	bne.b	1$
	move.l	a4,a3
	rts

1$	move.l	a4,-(sp)
	pea	(AddString,pc)
	bsr	PrintLong
	adda.w	#8,sp
2$	subq.l	#1,d7
	moveq	#0,d4
	move.l	d4,d5
	move.w	(a4)+,d4
	move.w	(a4)+,d5
	btst	#0,d4
	beq	Move
	bsr	GetMask
	btst	#0,d5
	beq.b	Wait
	lea	(SkipIns,pc),a0
	bra.b	PutRest
Wait
	cmpi.l	#$7f,(HP,a5)
	bne.b	1$
	cmpi.l	#$ff,(VP,a5)
	bne.b	1$
	lea	(CEndins,pc),a0
	bsr	Print
	rts

1$:

PutRest	move.l	(HP,a5),-(sp)
	move.l	(VP,a5),-(sp)
	pea	(WaitIns,pc)
	bsr	PrintLong
	add.w	#12,sp
	cmpi.l	#$7f,(HM,a5)
	bne.b	PutMask
	cmpi.l	#$7f,(VM,a5)
	bne.b	PutMask
PutLF	btst	#15,d5			;Test Blitter finished disable
	bne.b	1$
	lea	(BFDis,pc),a0
	bsr	Print
1$	lea	(LineFeed,pc),a0
	bsr	Print
	bra	Disassem

PutMask	move.l	(HM,a5),-(sp)
	move.l	(VM,a5),-(sp)
	pea	(MaskIns,pc)
	bsr	PrintLong
	add.w	#12,sp
	bra	PutLF

Move	lsr.l	#1,d4
	and.w	#$ff,d4
	lsl.l	#1,d4			;offset * 2
	lea	(Table,pc),a0
	move.w	(a0,d4.w),d0		;Get Discribtion address
	lea	(StrBase,pc),a1
	add.w	d0,a1
	move.l	a1,-(sp)		;save addres of string
	move.l	d5,-(sp)		;save data
	pea	(MoveIns,pc)
	bsr	PrintLong
	add.w	#12,sp
	bra	Disassem

GetMask	move.l	d4,d0
	lsr.l	#8,d0
	and.l	#$ff,d0			;get VP
	move.l	d4,d1
	lsr.l	#1,d1
	and.l	#$7f,d1			;Get HP
	move.l	d0,(VP,a5)
	move.l	d1,(HP,a5)
	move.l	d5,d0
	lsr.l	#8,d0
	and.l	#$7f,d0
	move.l	d0,(VM,a5)
	move.l	d5,d0
	lsr.l	#1,d0
	and.l	#$7f,d0
	move.l	d0,(HM,a5)
Endit	rts

Table	dw	bltddat1-StrBase
	dw	dmaconr1-StrBase
	dw	vposr1-StrBase
	dw	vhposr1-StrBase
	dw	dskdatr1-StrBase
	dw	joy0dat1-StrBase
	dw	joy1dat1-StrBase
	dw	clxdat1-StrBase
	dw	adkconr1-StrBase
	dw	pot0dat1-StrBase
	dw	pot1dat1-StrBase
	dw	potinp1-StrBase
	dw	serdatr1-StrBase
	dw	dskbytr1-StrBase
	dw	intenar1-StrBase
	dw	intreqr1-StrBase
	dw	dskptr1-StrBase
	dw	dskptr21-StrBase
	dw	dsklen1-StrBase
	dw	dskdat1-StrBase
	dw	refptr1-StrBase
	dw	vposw1-StrBase
	dw	vhposw1-StrBase
	dw	copcon1-StrBase
	dw	serdat1-StrBase
	dw	serper1-StrBase
	dw	potgo1-StrBase
	dw	joytest1-StrBase
	dw	strequ1-StrBase
	dw	strvbl1-StrBase
	dw	strhor1-StrBase
	dw	strlong1-StrBase
	dw	bltcon01-StrBase
	dw	bltcon11-StrBase
	dw	bltafwm1-StrBase
	dw	bltalwm1-StrBase
	dw	bltcpt1-StrBase
	dw	bltcpt21-StrBase
	dw	bltbpt1-StrBase
	dw	bltbpt21-StrBase
	dw	bltapt1-StrBase
	dw	bltapt21-StrBase
	dw	bltdpt1-StrBase
	dw	bltdpt21-StrBase
	dw	bltsize1-StrBase
	dw	pad2d01-StrBase
	dw	pad2d11-StrBase
	dw	pad2d21-StrBase
	dw	bltbmod1-StrBase
	dw	bltbmod1-StrBase
	dw	bltamod1-StrBase
	dw	bltdmod1-StrBase
	dw	pad3401-StrBase
	dw	pad3411-StrBase
	dw	pad3421-StrBase
	dw	pad3431-StrBase
	dw	bltcdat1-StrBase
	dw	bltbdat1-StrBase
	dw	bltadat1-StrBase
	dw	pad3b01-StrBase
	dw	pad3b11-StrBase
	dw	pad3b21-StrBase
	dw	pad3b31-StrBase
	dw	dsksync1-StrBase
	dw	cop1lc1-StrBase
	dw	cop1lc21-StrBase
	dw	cop2lc1-StrBase
	dw	cop2lc21-StrBase
	dw	copjmp11-StrBase
	dw	copjmp21-StrBase
	dw	copins1-StrBase
	dw	diwstrt1-StrBase
	dw	diwstop1-StrBase
	dw	ddfstrt1-StrBase
	dw	ddfstop1-StrBase
	dw	dmacon1-StrBase
	dw	clxcon1-StrBase
	dw	intena1-StrBase
	dw	intreq1-StrBase
	dw	adkcon1-StrBase
	dw	aud0ac_ptr1-StrBase
	dw	aud0ac_ptr21-StrBase
	dw	aud0ac_len1-StrBase
	dw	aud0ac_per1-StrBase
	dw	aud0ac_vol1-StrBase
	dw	aud0ac_dat1-StrBase
	dw	aud0ac_pad01-StrBase
	dw	aud0ac_pad11-StrBase
	dw	aud1ac_ptr1-StrBase
	dw	aud1ac_ptr21-StrBase
	dw	aud1ac_len1-StrBase
	dw	aud1ac_per1-StrBase
	dw	aud1ac_vol1-StrBase
	dw	aud1ac_dat1-StrBase
	dw	aud1ac_pad01-StrBase
	dw	aud1ac_pad11-StrBase
	dw	aud2ac_ptr1-StrBase
	dw	aud2ac_ptr21-StrBase
	dw	aud2ac_len1-StrBase
	dw	aud2ac_per1-StrBase
	dw	aud2ac_vol1-StrBase
	dw	aud2ac_dat1-StrBase
	dw	aud2ac_pad01-StrBase
	dw	aud2ac_pad11-StrBase
	dw	aud3ac_ptr1-StrBase
	dw	aud3ac_ptr21-StrBase
	dw	aud3ac_len1-StrBase
	dw	aud3ac_per1-StrBase
	dw	aud3ac_vol1-StrBase
	dw	aud3ac_dat1-StrBase
	dw	aud3ac_pad01-StrBase
	dw	aud3ac_pad11-StrBase
	dw	bplpt01-StrBase
	dw	bplpt021-StrBase
	dw	bplpt11-StrBase
	dw	bplpt121-StrBase
	dw	bplpt21-StrBase
	dw	bplpt221-StrBase
	dw	bplpt31-StrBase
	dw	bplpt321-StrBase
	dw	bplpt41-StrBase
	dw	bplpt421-StrBase
	dw	bplpt51-StrBase
	dw	bplpt521-StrBase
	dw	pad7c01-StrBase
	dw	pad7c11-StrBase
	dw	pad7c21-StrBase
	dw	pad7c31-StrBase
	dw	bplcon01-StrBase
	dw	bplcon11-StrBase
	dw	bplcon21-StrBase
	dw	pad831-StrBase
	dw	bpl1mod1-StrBase
	dw	bpl2mod1-StrBase
	dw	pad8601-StrBase
	dw	pad8611-StrBase
	dw	bpldat01-StrBase,bpldat11-StrBase,bpldat21-StrBase
	dw	bpldat31-StrBase,bpldat41-StrBase,bpldat51-StrBase
	dw	pad8e01-StrBase,pad8e11-StrBase
	dw	sprpt01-StrBase,sprpt021-StrBase,sprpt11-StrBase
	dw	sprpt121-StrBase
	dw	sprpt21-StrBase,sprpt221-StrBase,sprpt31-StrBase
	dw	sprpt321-StrBase
	dw	sprpt41-StrBase,sprpt421-StrBase,sprpt51-StrBase
	dw	sprpt521-StrBase
	dw	sprpt61-StrBase,sprpt621-StrBase,sprpt71-StrBase
	dw	sprpt721-StrBase
	dw	spr0pos1-StrBase,spr0ctl1-StrBase
	dw	spr0dataa1-StrBase,spr0datab1-StrBase
	dw	spr1pos1-StrBase,spr1ctl1-StrBase
	dw	spr1dataa1-StrBase,spr1datab1-StrBase
	dw	spr2pos1-StrBase,spr2ctl1-StrBase
	dw	spr2dataa1-StrBase,spr2datab1-StrBase
	dw	spr3pos1-StrBase,spr3ctl1-StrBase
	dw	spr3dataa1-StrBase,spr3datab1-StrBase
	dw	spr4pos1-StrBase,spr4ctl1-StrBase
	dw	spr4dataa1-StrBase,spr4datab1-StrBase
	dw	spr5pos1-StrBase,spr5ctl1-StrBase
	dw	spr5dataa1-StrBase,spr5datab1-StrBase
	dw	spr6pos1-StrBase,spr6ctl1-StrBase
	dw	spr6dataa1-StrBase,spr6datab1-StrBase
	dw	spr7pos1-StrBase,spr7ctl1-StrBase
	dw	spr7dataa1-StrBase,spr7datab1-StrBase
	dw	color01-StrBase,color11-StrBase
	dw	color21-StrBase,color31-StrBase
	dw	color41-StrBase,color51-StrBase
	dw	color61-StrBase,color71-StrBase
	dw	color81-StrBase,color91-StrBase
	dw	color101-StrBase,color111-StrBase
	dw	color121-StrBase,color131-StrBase
	dw	color141-StrBase,color151-StrBase
	dw	color161-StrBase,color171-StrBase
	dw	color181-StrBase,color191-StrBase
	dw	color201-StrBase,color211-StrBase
	dw	color221-StrBase,color231-StrBase
	dw	color241-StrBase,color251-StrBase
	dw	color261-StrBase,color271-StrBase
	dw	color281-StrBase,color291-StrBase
	dw	color301-StrBase,color311-StrBase

Help		db	'Usage: Display <StartAddress> <Length>',10
		db	'       ([cpr] Display Machine List)',10
		db	'       ([noadd] Do not display Addresses',0
AddString
		db	'%08lx',0
MoveIns		db	'	cmove	#$%04lx,(%s)',10,0
SkipIns		db	'	cskip	$%02lx:$%02lx',0
WaitIns		db	'	cwait	$%02lx:$%02lx',0
CEndins		db	'	cend',10,0
BFDis		db	'1',0
LOFName		db	'   LOF Copper List',10,'=====================',10,10,0
SHFName		db	10,10,'   SHF Copper List',10,'=====================',10,10,0
MaskIns		db	'{$%02lx:$%02lx}',0
LineFeed	db	10,0

StrBase:

bltddat1	db "bltddat",0
dmaconr1	db "dmaconr",0
vposr1		db "vposr",0
vhposr1		db "vhposr",0
dskdatr1	db "dskdatr",0
joy0dat1	db "joy0dat",0
joy1dat1	db "joy1dat",0
clxdat1		db "clxdat",0
adkconr1	db "adkconr",0
pot0dat1	db "pot0dat",0
pot1dat1	db "pot1dat",0
potinp1		db "potinp",0
serdatr1	db "serdatr",0
dskbytr1	db "dskbytr",0
intenar1	db "intenar",0
intreqr1	db "intreqr",0
dskptr1		db "dskpth",0
dskptr21	db "dskpth+2",0
dsklen1		db "dsklen",0
dskdat1		db "dskdat",0
refptr1		db "refptr",0
vposw1		db "vposw",0
vhposw1		db "vhposw",0
copcon1		db "copcon",0
serdat1		db "serdat",0
serper1		db "serper",0
potgo1		db "potgo",0
joytest1	db "joytest",0
strequ1		db "strequ",0
strvbl1		db "strvbl",0
strhor1		db "strhor",0
strlong1	db "strlong",0
bltcon01	db "bltcon0",0
bltcon11	db "bltcon1",0
bltafwm1	db "bltafwm",0
bltalwm1	db "bltalwm",0
bltcpt1		db "bltcpth",0
bltcpt21	db "bltcpth+2",0
bltbpt1		db "bltbpth",0
bltbpt21	db "bltbpth+2",0
bltapt1		db "bltapth",0
bltapt21	db "bltapth+2",0
bltdpt1		db "bltdpth",0
bltdpt21	db "bltdpth+2",0
bltsize1	db "bltsize",0
pad2d01		db "pad2d[0]",0
pad2d11		db "pad2d[1]",0
pad2d21		db "pad2d[2]",0
bltcmod1	db "bltcmod",0
bltbmod1	db "bltbmod",0
bltamod1	db "bltamod",0
bltdmod1	db "bltdmod",0
pad3401		db "pad34[0]",0
pad3411		db "pad34[1]",0
pad3421		db "pad34[2]",0
pad3431		db "pad34[3]",0
bltcdat1	db "bltcdat",0
bltbdat1	db "bltbdat",0
bltadat1	db "bltadat",0
pad3b01		db "pad3b[0]",0
pad3b11		db "pad3b[1]",0
pad3b21		db "pad3b[2]",0
pad3b31		db "pad3b[3]",0
dsksync1	db "dsksync",0
cop1lc1		db "cop1lch",0
cop1lc21	db "cop1lch+2",0
cop2lc1		db "cop2lch",0
cop2lc21	db "cop2lch+2",0
copjmp11	db "copjmp1",0
copjmp21	db "copjmp2",0
copins1		db "copins",0
diwstrt1	db "diwstrt",0
diwstop1	db "diwstop",0
ddfstrt1	db "ddfstrt",0
ddfstop1	db "ddfstop",0
dmacon1		db "dmacon",0
clxcon1		db "clxcon",0
intena1		db "intena",0
intreq1		db "intreq",0
adkcon1		db "adkcon",0
aud0ac_ptr1	db "aud0+ac_ptr",0
aud0ac_ptr21	db "aud0+ac_ptr+2",0
aud0ac_len1	db "aud0+ac_len",0
aud0ac_per1	db "aud0+ac_per",0
aud0ac_vol1	db "aud0+ac_vol",0
aud0ac_dat1	db "aud0+ac_dat",0
aud0ac_pad01	db "aud0+ac_pad[0]",0
aud0ac_pad11	db "aud0+ac_pad[1]",0
aud1ac_ptr1	db "aud1+ac_ptr",0
aud1ac_ptr21	db "aud1+ac_ptr+2",0
aud1ac_len1	db "aud1+ac_len",0
aud1ac_per1	db "aud1+ac_per",0
aud1ac_vol1	db "aud1+ac_vol",0
aud1ac_dat1	db "aud1+ac_dat",0
aud1ac_pad01	db "aud1+ac_pad[0]",0
aud1ac_pad11	db "aud1+ac_pad[1]",0
aud2ac_ptr1	db "aud2+ac_ptr",0
aud2ac_ptr21	db "aud2+ac_ptr+2",0
aud2ac_len1	db "aud2+ac_len",0
aud2ac_per1	db "aud2+ac_per",0
aud2ac_vol1	db "aud2+ac_vol",0
aud2ac_dat1	db "aud2+ac_dat",0
aud2ac_pad01	db "aud2+ac_pad[0]",0
aud2ac_pad11	db "aud2+ac_pad[1]",0
aud3ac_ptr1	db "aud3+ac_ptr",0
aud3ac_ptr21	db "aud3+ac_ptr+2",0
aud3ac_len1	db "aud3+ac_len",0
aud3ac_per1	db "aud3+ac_per",0
aud3ac_vol1	db "aud3+ac_vol",0
aud3ac_dat1	db "aud3+ac_dat",0
aud3ac_pad01	db "aud3+ac_pad[0]",0
aud3ac_pad11	db "aud3+ac_pad[1]",0
bplpt01		db "bplpt",0
bplpt021	db "bplpt+2",0
bplpt11		db "bplpt+4",0
bplpt121	db "bplpt+6",0
bplpt21		db "bplpt+8",0
bplpt221	db "bplpt+10",0
bplpt31		db "bplpt+12",0
bplpt321	db "bplpt+14",0
bplpt41		db "bplpt+16",0
bplpt421	db "bplpt+18",0
bplpt51		db "bplpt+20",0
bplpt521	db "bplpt+22",0
pad7c01		db "pad7c[0]",0
pad7c11		db "pad7c[1]",0
pad7c21		db "pad7c[2]",0
pad7c31		db "pad7c[3]",0
bplcon01	db "bplcon0",0
bplcon11	db "bplcon1",0
bplcon21	db "bplcon2",0
pad831		db "pad83",0
bpl1mod1	db "bpl1mod",0
bpl2mod1	db "bpl2mod",0
pad8601		db "pad86[0]",0
pad8611		db "pad86[1]",0
bpldat01	db "bpldat",0
bpldat11	db "bpldat+2",0
bpldat21	db "bpldat+4",0
bpldat31	db "bpldat+6",0
bpldat41	db "bpldat+8",0
bpldat51	db "bpldat+10",0
pad8e01		db "pad8e[0]",0
pad8e11		db "pad8e[1]",0
sprpt01		db "sprpt",0
sprpt021	db "sprpt+2",0
sprpt11		db "sprpt+4",0
sprpt121	db "sprpt+8",0
sprpt21		db "sprpt+10",0
sprpt221	db "sprpt+12",0
sprpt31		db "sprpt+14",0
sprpt321	db "sprpt+16",0
sprpt41		db "sprpt+18",0
sprpt421	db "sprpt+20",0
sprpt51		db "sprpt+22",0
sprpt521	db "sprpt+24",0
sprpt61		db "sprpt+26",0
sprpt621	db "sprpt+28",0
sprpt71		db "sprpt+30",0
sprpt721	db "sprpt+32",0
spr0pos1	db "spr+sd_pos",0
spr0ctl1	db "spr+sd_ctl",0
spr0dataa1	db "spr+sd_dataa",0
spr0datab1	db "spr+sd_datab",0
spr1pos1	db "spr+8+sd_pos",0
spr1ctl1	db "spr+8+sd_ctl",0
spr1dataa1	db "spr+8+sd_dataa",0
spr1datab1	db "spr+8+sd_datab",0
spr2pos1	db "spr+16+sd_pos",0
spr2ctl1	db "spr+16+sd_ctl",0
spr2dataa1	db "spr+16+sd_dataa",0
spr2datab1	db "spr+16+sd_datab",0
spr3pos1	db "spr+24+sd_pos",0
spr3ctl1	db "spr+24+sd_ctl",0
spr3dataa1	db "spr+24+sd_dataa",0
spr3datab1	db "spr+24+sd_datab",0
spr4pos1	db "spr+32+sd_pos",0
spr4ctl1	db "spr+32+sd_ctl",0
spr4dataa1	db "spr+32+sd_dataa",0
spr4datab1	db "spr+32+sd_datab",0
spr5pos1	db "spr+40+sd_pos",0
spr5ctl1	db "spr+40+sd_ctl",0
spr5dataa1	db "spr+40+sd_dataa",0
spr5datab1	db "spr+40+sd_datab",0
spr6pos1	db "spr+48+sd_pos",0
spr6ctl1	db "spr+48+sd_ctl",0
spr6dataa1	db "spr+48+sd_dataa",0
spr6datab1	db "spr+48+sd_datab",0
spr7pos1	db "spr+56+sd_pos",0
spr7ctl1	db "spr+56+sd_ctl",0
spr7dataa1	db "spr+56+sd_dataa",0
spr7datab1	db "spr+56+sd_datab",0
color01		db "color",0
color11		db "color+2",0
color21		db "color+4",0
color31		db "color+6",0
color41		db "color+8",0
color51		db "color+10",0
color61		db "color+12",0
color71		db "color+14",0
color81		db "color+16",0
color91		db "color+18",0
color101	db "color+20",0
color111	db "color+22",0
color121	db "color+24",0
color131	db "color+26",0
color141	db "color+28",0
color151	db "color+30",0
color161	db "color+32",0
color171	db "color+34",0
color181	db "color+36",0
color191	db "color+38",0
color201	db "color+40",0
color211	db "color+42",0
color221	db "color+44",0
color231	db "color+46",0
color241	db "color+48",0
color251	db "color+50",0
color261	db "color+52",0
color271	db "color+54",0
color281	db "color+56",0
color291	db "color+58",0
color301	db "color+60",0
color311	db "color+62",0

	even

;not used
;Args	dx.l	1
;	dx.l	1
;	dx.l	1
;Noadd	dx.l	1

;used (need not be initialized to anything)
;VP	dx.l	1
;HP	dx.l	1
;VM	dx.l	1
;HM	dx.l	1

	end
