* Dis, 680000 disassembler
* Greg Lee, Feb. 6, 1986
*
* The program Dis, this source code, and
* the accompanying document are in the public domain
*

* To ma with Metacomco assembler (v10.178):
*  assem dis.s -o dis.o -c W150000
*  alink dis.o to dis

	idnt  Dis

	section  one

lref	macro
_LVO\1	equ	-6*(\2+4)
	endm

call  macro
	jsr	_LVO\1(A6)
	endm
print macro
	lea	\1,A0
	bsr	msg
	endm
char  macro
	move.b	#'\1',D0
	bsr	prtchr
	endm
comma macro
	move.b	#',',D0
	bsr	prtchr
	endm
ifnot macro
	cmp.b	#'\1',D0
	bne	\2
	endm

SysBase	equ	4


*--Definitions of library references


*	Exec
	lref	AllocMem,29
	lref	FreeMem,31
	lref	OpenLibrary,88

*	AmigaDOS
	lref	Open,1
	lref	Close,2
	lref	Read,3
	lref	Write,4
	lref	Input,5
	lref	Output,6
	lref	DeleteFile,8
	lref	IoErr,18
	lref	LoadSeg,21
	lref	UnLoadSeg,22


SegMax	equ	255
SymMax	equ	3200
IbufLen	equ	80

main
	lea	symtab,A0	* to find symtab when debugging
	clr.l	(A0)
	lea	segtable,A0
	clr.l	(A0)

	bsr	ioinit
********************** end initialization **************
*  A6 holds DOS pointer; A5 holds address to show
*  D5 has code; D6 has type; D7 has address offset
	moveq	#0,D7

	print	hello
	bsr	leftprint


	lea	main,A5
	move.l	A5,lastadr
.mloop
	move.b	#0,kflag
	moveq	#50,D0
	bsr	column
	char	*
	bsr	getstr
	cmp.b	#1,D3
	bne	1$
	move.w	reqlines,linecount
	bra	.mdoit

1$	clr.b	bflag

	ifnot	r,10$
	bsr	symread
	bra	.mloop

10$
	ifnot	s,11$
	bsr	symsave
	bra	.mloop

11$
	cmp.b	#2,D3
	beq	3$

	ifnot	=,12$
	bsr	addsym
	move.l	lastadr,A5
	bra	.mdoit
12$
	ifnot	/,13$
	bsr	getaddress
	beq	.mloop
	move.l	D0,A5
	bra	.mloop
13$
	ifnot	o,14$
	bsr	getaddress
	beq	.mloop
	move.l	D0,D7
	bra	.mdoit
14$
	ifnot	w,15$
	bsr	getnum
	bne	.mloop
	move.l	D2,D0
	bsr	findword
	bra	2$

15$
	ifnot	W,16$
	bsr	getaddress
	beq	.mloop
	bsr	findWord
	bra	2$

16$
	ifnot	f,17$
	bsr	fload
	bra	2$
17$
	ifnot	k,18$
	bsr	ksave
	bra	.mloop
18$
	ifnot	n,19$
	bsr	getnum
	bne	.mloop
	move.w	D2,reqlines
	move.w	D2,linecount
	bra	.mdoit

19$
	move.b	D0,lastcmd
	bsr	getaddress
	beq	.mdoit
	bsr	realaddress
	add.l	D7,D0
	move.l	D0,A5
	bra	.mdoit


2$	tst.l	D0
	beq	.mloop
	move.l	D0,A5
	bra	.mdoit


3$	cmp.b	lastcmd,D0
	beq	31$
	move.l	lastadr,A5
31$
	cmp.b	#'>',D0
	bne	32$
	bsr	nextfseg
	bra	2$
32$
	cmp.b	#'<',D0
	bne	33$
	bsr	firstfseg
	bra	2$
33$
	cmp.b	#'q',D0
	beq	.mdone

	ifnot	o,34$
	move.l	lastadr,D7
	bra	.mdoit

34$
	ifnot	?,35$
	print	helpmsg
	print	helpmsg2
	print	helpmsg3
	bsr	leftprint
	bra	.mloop
35$
	ifnot	t,36$
	move.b	tflag,D0
	not.b	D0
	move.b	D0,tflag
	bra	.mloop
36$
	ifnot	p,6$
	move.b	pflag,D0
	not.b	D0
	move.b	D0,pflag
	bra	.mloop

6$	move.b	D0,lastcmd

.mdoit
	move.b	#1,kflag
	move.l	khandle,D0
	bne	2$
1$	move.l	A5,lastadr
	bsr	shlabel
	bsr	aline
	bsr	dline
	bsr	iline
	tst.w	linecount
	bmi	.mloop
2$	bsr	newline
	bra	1$

.mdone
	bsr	funload
	move.l	khandle,D1
	beq	1$
	call	Close
1$	moveq	#0,D0	* no error return
.mreturn
	rts
********************* end main ************************



findword
	move.l	D0,D2
	move.l	A5,A0
1$	cmp.w	(A0)+,D2
	bne	2$
	move.l	A0,D0
	subq.l	#2,D0
	rts
2$	cmp.l	#$80000,A0
	bcs	1$
	cmp.l	#$FFFFFE,A0
	bhi	4$
	cmp.l	#$FC0000,A0
	bhi	1$
	move.l	#$FC0000,A0
	bra	1$
4$	moveq	#0,D0
	rts

findWord
	move.l	D0,D2
	move.l	A5,A0
	bsr	1$
	tst.l	D0
	bne	5$
	move.l	A5,A0
	addq.l	#2,A0
1$	cmp.l	(A0)+,D2
	bne	2$
	move.l	A0,D0
	subq.l	#4,D0
	rts
2$	cmp.l	#$80000,A0
	bcs	1$
	cmp.l	#$FFFFFE,A0
	bhi	4$
	cmp.l	#$FC0000,A0
	bhi	1$
	move.l	#$FC0000,A0
	bra	1$
4$	moveq	#0,D0
5$	rts


addsym
	move.b	stfflag,D0
	bne	sayisfull
	move.l	lastadr,D0
	bsr	pseudoaddress
	sub.l	D7,D0
	move.l	endsym,A1
	lea	endsymtab,A0
	cmp.l	A0,A1
	bhi	marksyfull
	beq	marksyfull
	lea	ibuf,A0
	addq.l	#1,A0
	cmp.b	#'*',(A0)
	beq	1$
	lea	symtab,A1
1$	move.l	(A1),D1
	beq	2$
	cmp.l	D1,D0
	beq	2$
	addq.l	#6,A1
	bra	1$
2$	move.l	D0,(A1)+
	move.w	farea,D2
	move.w	D2,(A1)+
	tst.l	D1
	bne	20$
	clr.l	(A1)
	move.l	A1,endsym
20$
	lea	sarea,A1
	add.w	D2,A1
	lea	endsarea,A2
	cmp.l	A2,A1
	bhi	marksyfull
	beq	marksyfull
	moveq	#0,D3
	move.l	A1,-(SP)

	addq.l	#1,A1
3$	move.b	(A0)+,D0
	cmp.b	#' ',D0
	blt	4$
	move.b	D0,(A1)+
	addq.b	#1,D3
	bra	3$
4$	cmp.l	A2,A1
	bhi	marksfull
	beq	marksfull

	move.l	(SP)+,A1
	move.b	D3,(A1)

	addq	#1,D3
	add.w	D3,D2
	move.w	D2,farea
5$	rts
marksyfull
	move.b	#1,stfflag
	move.l	endsym,A1
	subq.l	#6,A1
	clr.l	(A1)
	move.l	A1,endsym
sayisfull
	move.w	#-1,linecount
	print	fullmsg
	bra	leftprint

buildsym
	move.b	bflag,D1
	beq	8$
	move.b	stfflag,D1
	bne	sayisfull
	lea	obuf,A0
	moveq	#8,D3

	move.w	#ByteSize,D1
	and.w	D6,D1
	beq	2$
	subq.l	#1,A0
	move.l	A0,-(SP)
	move.b	D3,(A0)+
	addq	#1,D3
	move.b	#'.',(A0)+
	cmp.w	#LongSize,D1
	beq	3$
	move.b	#'w',(A0)
	cmp.w	#WordSize,D1
	beq	1$
	move.b	#'b',(A0)
1$	addq.l	#1,A0
	cmp.b	#'0',(A0)
	beq	3$
	bra	5$

2$	move.l	A0,-(SP)
	move.b	#7,(A0)+
	move.w	#SubCall,D1
	and.w	D1,D6
	beq	3$
	move.b	#'R',(A0)+
	bra	5$
3$	move.b	#'l',(A0)+
4$	cmp.b	#'0',(A0)
	bne	5$
	move.b	#'a',(A0)+
	cmp.b	#'0',(A0)
	bne	5$
	move.b	#'b',(A0)
5$
	move.l	endsym,A1
	lea	endsymtab,A0
	cmp.l	A0,A1
	bhi	marksfull
	beq	marksfull
	move.l	D0,(A1)+
	move.w	farea,D2
	move.w	D2,(A1)+
	clr.l	(A1)
	move.l	A1,endsym
	lea	sarea,A1
	add.w	D2,A1
	lea	endsarea,A0
	cmp.l	A0,A1
	bhi	marksfull
	beq	marksfull
	add.w	D3,D2
	move.w	D2,farea

	move.l	(SP)+,A0
	bra	7$
6$	move.b	(A0)+,(A1)+
7$	dbra	D3,6$
8$	rts
9$	addq.l	#4,SP
	rts
marksfull
	addq.l	#4,SP
	bra	marksyfull


shlabel
	move.l	A5,D0
	bsr	pseudoaddress
	move.l	D0,D2
	sub.l	D7,D2
	clr.l	D1
	move.b	#'i',D3
	lea	sarea,A1
	lea	symtab,A0
	bra	2$
1$	addq.l	#2,A0
2$	move.l	(A0)+,D0
	beq	5$
	cmp.l	D0,D2
	beq	3$
	bls	1$
	cmp.l	D0,D1
	bhi	1$
	move.l	D0,D1
	move.w	(A0)+,D0
	cmp.b	#'*',1(A1,D0.W)
	beq	2$
	move.b	#'i',D3
	cmp.b	#'.',1(A1,D0.W)
	bne	2$
	move.b	2(A1,D0.W),D3
	bra	2$

3$	moveq	#-1,D1
	move.w	(A0)+,D0
	cmp.b	#'*',1(A1,D0.W)
	beq	4$
	move.b	#'i',D3
	cmp.b	#'.',1(A1,D0.W)
	bne	4$
	move.b	2(A1,D0.W),D3
	cmp.b	#2,0(A1,D0.W)
	beq	2$
4$	movem.l  D1-D3/A0/A1,-(SP)
	lea	0(A1,D0.W),A0
	cmp.b	#'R',1(A0)
	bne	40$
	move.l	A0,-(SP)
	bsr	newline
	move.l	(SP)+,A0
40$
	bsr	substlocal
	bsr	msg
	bsr	newline
	movem.l	(SP)+,D1-D3/A0/A1
	bra	2$

5$	tst.l	D1
	bmi	6$	* change this
	beq	6$
	cmp.b	#'l',D3
	bne	6$
	eor	D1,D2
	and.b	#%11,D2
	beq	6$
	move.b	#'b',D3
6$	move.b	D3,itype
	rts

substlocal
	lea	lastlocal,A1
	cmp.b	#'B',lastcmd
	bne	30$
	cmp.b	#7,(A0)
	bne	30$
	cmp.b	#'l',1(A0)
	bne	30$
	move.b	#'0',D0
	cmp.b	#'z',(A1)
	bne	1$
	move.b	D0,(A1)
	move.b	D0,1(A1)
	move.b	D0,2(A1)
1$	add.b	#1,2(A1)
	cmp.b	#'9',2(A1)
	ble	2$
	move.b	D0,2(A1)
	add.b	#1,1(A1)
	cmp.b	#'9',1(A1)
	ble	2$
	move.b	D0,1(A1)
	add.b	#1,(A1)
	cmp.b	#'9',(A1)
	bgt	6$
2$	moveq	#4,D1
	cmp.b	(A1)+,D0
	bne	3$
	subq	#1,D1
	cmp.b	(A1)+,D0
	bne	3$
	subq	#1,D1
	cmp.b	(A1)+,D0
3$	subq	#1,A1
	move.l	A0,D0
	move.b	D1,(A0)+
	bra	5$
4$	move.b	(A1)+,(A0)+
5$	dbra	D1,4$
	move.l	D0,A0
6$	rts
30$
	move.b	#'z',(A1)
	rts

lastlocal
	dc.b	'zzz$'

shopdlabel
	movem.l  D1-D3/A0/A1,-(SP)
	bsr	pseudoaddress
	bra	.shpdlbl
shoplabel
	movem.l  D1-D3/A0/A1,-(SP)
	bsr	pseudoaddress
	moveq	#0,D2
	sub.l	D7,D0
	tst.l	D1
	bne	.shplbl
.shpdlbl
	moveq	#-1,D2
.shplbl
	lea	symtab,A0
1$	move.l	(A0)+,D1
	beq	5$
	cmp.l	D1,D0
	bne	2$
	move.w	(A0),D1
	lea	sarea,A0
	add.w	D1,A0
	cmp.b	#'*',1(A0)
	beq	5$
	cmp.b	#2,(A0)
	bne	10$
	cmp.b	#'.',1(A0)
	beq	5$
10$
	bsr	msg
	bra	7$
2$	addq.l	#2,A0
	bra	1$
5$	tst.l	D2
	beq	50$
	tst.l	D0
	beq	50$
	move.l	D0,-(SP)
	char	$
	move.l	(SP)+,D0
50$
	cmp.l	#$FFFFFF,D0
	bhi	6$
	movem.l  D0/D2,-(SP)
	tst.l	D0
	bne	51$
	char	0
	bra	52$
51$
	bsr	show6x
52$
	movem.l  (SP)+,D0/D2
	tst.l	D2
	bne	7$
	tst.l	D0
	beq	7$
	bsr	buildsym
	bra	7$
6$	bsr	show8x
7$	movem.l  (SP)+,D1-D3/A0/A1
	rts

getaddress
	bsr	getnum
	bne	findsym
	move.l	D2,D0
	bne	1$
	cmp.l	#1,D0
1$	rts

findsym
	moveq	#0,D3
	move.b	ilen,D3
	subq.b	#2,D3
	lea	ibuf,A0
	move.b	D3,(A0)

	lea	symtab,A1
2$	move.l	(A1)+,D0
	beq	30$
	move.l	D3,D1
	move.w	(A1)+,D2

	move.l	A0,-(SP)
	move.l	A1,-(SP)
	lea	sarea,A1
	add.w	D2,A1
3$	cmp.b	(A1)+,(A0)+
	dbne	D1,3$
	beq	4$
	move.l	(SP)+,A1
	move.l	(SP)+,A0
	bra	2$
4$	addq.l	#8,SP
30$
	tst.l	D0
	rts

aline
	cmp.b	#'a',lastcmd
	bne	.mreturn
	bsr	showadr
	moveq	#7,D0
	bsr	column
	move.w	#32,D3
	move.b	D3,olen
	lea	obuf,A0
	subq.w	#1,D3
1$	move.b	(A5)+,D0
	cmp.b	#' ',D0
	blt	2$
	cmp.b	#127,D0
	blt	3$
2$	move.b	#'.',D0
3$	move.b	D0,(A0)+
	dbra	D3,1$
	print	olen
	rts

dline
	cmp.b	#'d',lastcmd
	bne	.mreturn
	bsr	wordalign
	bsr	showadr
	moveq	#7,D0
	bsr	column

	bsr	1$
	nop
1$	bsr	2$
	nop
2$	move.l	(A5)+,D0
	bsr	show8x
	bra	prtspc

checkcwbreak
	move.l	A5,D0
	addq.l	#2,D0
	bra	.ccbrk1

checkcbreak
	move.l	A5,D0
.ccbrk1
	bsr	pseudoaddress
	tst.l	D1
	beq	2$
	sub.l	D7,D0
	lea	symtab,A0
1$	move.l	(A0)+,D1
	beq	3$
	addq.l	#2,A0
	cmp.l	D0,D1
	bne	1$
2$	tst.l	D0
3$	rts

iline
	cmp.b	#'B',lastcmd
	beq	101$
	cmp.b	#'b',lastcmd
	bne	100$
	move.b	#1,bflag
	bra	101$
100$
	cmp.b	#'l',lastcmd
	bne	.mreturn
101$
	bsr	showadr

	moveq	#8,D0
	move.b	tflag,D1
	beq	102$
	moveq	#3,D0
102$
	bsr	column

	move.b	itype,D0
	move.l	D0,-(SP)

	cmp.b	#'w',D0
	beq	1$
	cmp.b	#'l',D0
	bne	107$
* covering up references on next
*  word boundary to be avoided
	bsr	checkcwbreak
	bne	105$
	move.l	(SP),D0
	bra	1$
105$
	move.b	#'b',D0
	move.l	D0,(SP)
107$
	cmp.b	#'b',D0
	beq	1$
	cmp.b	#'c',D0
	bne	103$
	lea	dcbinst,A0
	bra	104$
103$
	cmp.b	#'a',D0
	bne	5$
	move.b	#'b',D0
1$	lea	dcinst,A0
	move.b	D0,4(A0)
104$
	bsr	msg
	bra	6$

5$	bsr	showi

6$	moveq	#18,D0
	move.b	tflag,D1
	beq	50$
	moveq	#13,D0
50$
	bsr	column

	move.l	(SP)+,D0

	cmp.b	#'c',D0
	bne	600$
	moveq	#0,D0
501$
	addq.l	#1,D0
	addq.l	#1,A5
	move.l	D0,-(SP)
	pea	503$
	pea	502$
	bra	62$
502$
	addq.l	#4,SP
	move.l	(SP)+,D0
	move.b	(A5),D1
	cmp.b	-1(A5),D1
	beq	501$
	bra	504$
503$
	move.l	(SP)+,D0
504$
	bsr	show4x
	comma
	move.b	-1(A5),D0
	bra	show2x

600$
	cmp.b	#'b',D0
	bne	7$

	bra	61$
60$
	comma
61$
	move.b	(A5)+,D0
	bsr	show2x
	pea	60$
62$
	move.b	printhead,D0
	cmp.b	#40,D0
	bhi	63$
	bsr	checkcbreak
	beq	64$
63$
	addq.l	#4,SP
64$
	rts


7$	cmp.b	#'a',D0
	bne	8$
	bra	74$

70$
	addq.l	#4,SP
	move.b	#'''',D0
	bsr	prtchr
71$
	comma
72$
	move.b	(A5)+,D0
	bsr	show2x
	pea	73$
	bra	62$
73$
	comma
74$
	cmp.b	#' ',(A5)
	bcs	72$
	cmp.b	#126,(A5)
	bhi	72$

	move.b	#'''',D0
	bsr	prtchr
	pea	77$
75$
	move.b	(A5)+,D0
	cmp.b	#'''',D0
	bne	750$
	bsr	prtchr
	move.b	#'''',D0
750$
	bsr	prtchr
	pea	76$
	bra	62$
76$
	cmp.b	#' ',(A5)
	bcs	70$
	cmp.b	#126,(A5)
	bhi	70$
	bra	75$
77$
	move.b	#'''',D0
	bra	prtchr

8$	bsr	wordalign

	cmp.b	#'w',D0
	bne	9$

	bra	81$
80$
	comma
81$
	move.w	(A5)+,D0
	bsr	show4x
	pea	80$
	bra	62$

9$	cmp.b	#'l',D0
	bne	showarg

	bra	91$
90$
	comma
91$
	move.l	(A5)+,D0
	bsr	shopdlabel
	pea	90$
	bra	62$


itype	dc.b	'i'
dcinst	dc.b	4,'dc.w'
dcbinst	dc.b	5,'dcb.b'
	cnop	0,2

* search table for instruction
showi
	bsr	wordalign

	move.w	(A5)+,D5	* get machine code
	move.b	#$C0,D1		* extract size field for later
	and.b	D5,D1
	move.b	D1,isize
	lea	mtab,A0
	moveq	#8,D2		* to pass name (6) and arg type (2)
1$	move.w	D5,D1		* start search -- copy code to D1
	and.w	(A0)+,D1	* use mask
	cmp.w	(A0)+,D1	* desired op code?
	adda	D2,A0		* point next entry
	bne	1$		* if not, try next
	move.w	-(A0),D6	* get arg type
	lea	olen,A1		* ready copy name to obuf
	moveq	#6,D2		* length of name
	move.b	D2,(A1)+
	adda	D2,A1		* after place for name in obuf
	subq	#1,D2		* move 6 bytes
2$	move.b	-(A0),-(A1)	* move the name
	dbra	D2,2$
* here code in D5 and arg type in D6
* now do condition code
	move.l	A1,A0
	addq.l	#1,A0
	cmp.b	#'@',(A0)+
	beq	20$
	cmp.b	#'@',(A0)+
	bne	21$
20$
	subq.l	#1,A0
	move.w	D5,D0
	lsr.w	#7,D0
	and.w	#%00011110,D0  * cond. code times 2
	lea	condlets,A3
	add.w	D0,A3
	move.b	(A3)+,(A0)+
	move.b	(A3),(A0)
21$
* adjust size and mode for MOVEP
	move.w	D5,D0
	and.w	#%1111000100111000,D0
	cmp.w	#%0000000100001000,D0
	bne	22$
	or.w	#%0000000000100000,D5	* mode is x(An)
	or.b	#%10000000,isize
	bra	23$	* so size like that of MOVEM
22$
* adjust size for MOVEM
	move.w	#FlagMovem,D0
	and.w	D6,D0
	beq	24$
23$
	sub.b	#%1000000,isize
	add.b	#1,olen
	bra	3$
24$
	move.w	#Size,D0
	and.w	D6,D0
	beq	..shx
3$	cmp.b	#'.',(A1)+
	bne	3$
	move.b	isize,D0
	move.b	#'l',(A1)
	cmp.b	#LongSize,D0
	beq	4$
	move.b	#'w',(A1)
	cmp.b	#WordSize,D0
	beq	4$
	move.b	#'b',(A1)
	move.b	#ByteSize,D0
4$	or.b	D0,D6
..shx
	print	olen
	rts

* display operand(s) -- code in D5 and type in D6
showarg
	move.w	D5,D0	* check for no operand
	and.w	#%1111111111111000,D0
	cmp.w	#%0100111001110000,D0
	bne	100$
	rts
100$
	lea	nameUSP,A0
	move.w	D5,D0	* move to/from USP
	and.w	#%1111111111110000,D0
	cmp.w	#%0100111001100000,D0
	bne	311$
	move.w	D5,D0	* make mode An
	and.w	#%1111111111000111,D5
	move.w	#%0000000000001000,D1
	or.w	D1,D5
	and.w	D1,D0	* test dir.
	bne	310$
300$
	move.l	A0,-(SP)
	bsr	101$
	comma
	move.l	(SP)+,A0
	bra	msg
310$
	bsr	msg
	bra	105$
311$
	cmp.w	#%0100111001000000,D0	* TRAP ?
	bne	312$
	char	#
	move.w	D5,D0
	and.w	#%00001111,D0
	bra	show2x
312$
	lea	nameSR,A0
	and.w	#%1111111111000000,D0
	cmp.w	#%0100000011000000,D0
	beq	310$
	cmp.w	#%0100011011000000,D0
	beq	300$
	lea	nameCCR,A0
	cmp.w	#%0100010011000000,D0
	beq	300$

	move.w	D6,D0	* second operand reg in 1st field?
	and.w	#ARegField2,D0
	beq	201$
	cmp.w	#RegField1,D0
	beq	201$
	bsr	101$	* do first operand
	comma
	move.w	D6,D1
	moveq	#001,D0	* assign An mode
	and.w	#ARegField2,D1
	cmp.w	#ARegField2,D1
	beq	200$
	moveq	#0,D0	* else is RegField2, so assign Dn mode
200$
	bsr	ex11.10.9
	bra	showea
201$
	move.w	D5,D0	* test for DBcc
	and.w	#%1111000011111000,D0
	cmp.w	#%0101000011001000,D0
	bne	202$
	and.w	#%0000000000000111,D5	* make it look like:
	or.w	#%0001010111000000,D5	*  MOVE EA=x(PC) EA=modeDn,reg
202$
	move.w	D6,D0	* test for CMPM
	and.w	#FlagCmpm,D0
	beq	203$
	and.w	#%0000111000000111,D5	* make like MOVE.B with m. (An)+
	or.w	#%0001000011011000,D5
203$
	move.w	D6,D0
	and.w	#PreDecr,D0
	beq	204$
	move.w	D5,D1
	and.w	#%0000111000000111,D5	* save reg's
	or.w	#%0001000000000000,D5	* fake MOVE.B
	and.w	#%0000000000001000,D1	* reg or mem?
	beq	204$
	or.w	#%0000000100100000,D5	* if mem, modes are -(An)
204$
	move.w	D5,D0
	and.w	#%1100000000000000,D0
	bne	101$
	move.w	D5,D0
	and.w	#%0011000000000000,D0	* check for move with 2 EA's
	beq	101$
	bsr	101$	* got one -- do source
	comma
* move 1st EA to pos'n of 2nd
	bsr	ex11.10.9
	move.w	D5,D0
	and.w	#%0000000111000000,D0
	lsr.w	#3,D0
	and.w	#%1111000000000000,D5
	or.w	D1,D5
	or.w	D0,D5
101$
	move.w	D5,D0	* test for bit static
	and.w	#%1111111100000000,D0
	cmp.w	#%0000100000000000,D0
	bne	111$
	char	#
	move.w	(A5)+,D1
	and.w	#%0000000000011111,D1
	bra	108$
111$
	move.w	D6,D0
	and.w	#SmallImmed,D0
	beq	103$
	move.w	D5,D0	* test for shift inst. with Dn source
	and.w	#%1111000000100000,D0
	cmp.w	#%1110000000100000,D0
	bne	112$
	and.w	#%1111111111000111,D5	* zero bits for Dn mode
	bra	104$	* go extract Dn field
112$
	cmp.w	#%1110000000000000,D0
	bne	102$
	and.w	#%1111111111000111,D5
102$
	and.w	#%1111000000000000,D0
	cmp.w	#%0111000000000000,D0	* check for moveq
	bne	109$
	char	#
	clr.w	D0
	move.b	D5,D0
	bpl	110$
	move.l	D0,-(SP)
	char	-
	move.l	(SP)+,D0
	ext.w	D0
	neg.w	D0
110$
	bra	show2x
109$
* here is addq, subq, or shift inst. with 3 bit immed. data
	char	#
	bsr	ex11.10.9	* so extract the data
	tst.w	D1	* 0 represents 8
	bne	108$
	moveq	#8,D1
108$
	move.w	D1,D0
	bsr	show2x
	bra	105$	* show comma and continue
103$
	move.w	D6,D0
	and.w	#ARegField2,D0
	cmp.w	#RegField1,D0
	bne	106$
104$
	clr.w	D0	* mode 0
	bsr	ex11.10.9
	bsr	showea
105$
	comma
106$
	move.w	D6,D0
	and.w	#Displ,D0
	beq	.sarg3
* here it's a branch
	move.w	D5,D0
	ext.w	D0	* test for displ in next word
	bne	.shoffs2
shoffs
	move.w	(A5)+,D0
.shoffs1
	ext.l	D0
	subq.l	#2,D0	* since added before pc advanced
.shoffs2
	ext.l	D0	* add displ to pc
	add.l	A5,D0
	bra	shoplabel
.sarg3
	move.w	D6,D0	* MOVEM ?
	and.w	#FlagMovem,D0
	beq	.sarg5
	move.w	D5,D0
	and.w	#%0000010000000000,D0
	beq	.sarg4
	move.w	(A5)+,D0	* mask is here, even if EA is 1st arg
	move.w	D0,-(SP)
	bsr	.sarg5
	comma
	move.w	(SP)+,D0
	bra	mmask1
.sarg4
	bsr	mmask
	comma
.sarg5
	move.w	D5,D0	* change mode for LINK & UNLK
	and.w	#%1111111111110000,D0
	cmp.w	#%0100111001010000,D0
	bne	.sarg6
	btst	#3,D5	* LINK?
	bne	1$
	bsr	1$
	comma
	char	#
	move.w	(A5)+,D0
	bra	shsigned4x
1$	and.w	#%1111111111000111,D5
	or.w	#%0000000000001000,D5
.sarg6
	move.w	D6,D0
	and.w	#EffAdr,D0
	beq	.mreturn	* was '.shstub'
* here source is effective address
	move.w	D6,D0
	and.w	#Immed,D0
	beq	4$
	bsr	imsrce
	comma
4$	move.w	D5,D0
	and.w	#%0111111,D0
	move.w	D0,D1	* save eff. adr
	cmp.w	#%0111010,D0
	beq	shoffs	* pc with displacement?
* + abs. short and long, immediate
	cmp.w	#%0111000,D0	* abs. short?
	bne	40$
	move.w	(A5)+,D0
	bra	show4x
40$
	cmp.w	#%0111001,D0	* abs. long?
	bne	5$
	move.l	(A5)+,D0
	bra	shoplabel
5$	cmp.w	#%0111100,D0	* immediate?
	beq	imsrce.d
	cmp.w	#%0111011,D0	* pc with index?
	beq	50$
	and.w	#%0111000,D0	* other mode 7 illegal
	cmp.w	#%0111000,D0
	beq	.shstub
50$
* here mode not 7 unless pc with index
	move.w	D1,D0
	and.w	#%0000111,D1	* get reg bits
	and.w	#%0111000,D0	* get mode bits
	lsr.b	#3,D0
showea
	bsr	depmode
	lea	olen,A0
	move.b	D3,(A0)
	bra	msg

depmode
	clr.b	D3	* holds length
	lea	obuf,A0
	dbra	D0,6$
*Dn
50$
	move.b	#'D',D0
	bsr	depbyte
	bra	depreg
6$	dbra	D0,7$
*An
60$
	cmp.b	#7,D1
	bne	61$
	move.b	#'S',D0
	bsr	depbyte
	move.b	#'P',D0
	bra	depbyte
61$
	move.b	#'A',D0
	bsr	depbyte
	bra	depreg
7$	dbra	D0,8$
*(An)
70$
	move.b	#'(',D0
	bsr	depbyte
	bsr	60$
	move.b	#')',D0
	bra	depbyte
8$	dbra	D0,9$
*(An)+
	bsr	70$
	move.b	#'+',D0
	bra	depbyte
9$	dbra	D0,10$
*-(An)
	move.b	#'-',D0
	bsr	depbyte
	bra	70$
10$
	dbra	D0,11$
*x(An)
*??
	move.w	(A5)+,D0
	bsr	shsigned4x
	bra	70$
11$
	dbra	D0,12$
*x(An,D/An.)
*??
	move.w	(A5),D0
	ext.w	D0
	bsr	shsigned4x
	move.b	#'(',D0
	bsr	depbyte
	bsr	60$
*111$
	move.b	#',',D0
	bsr	depbyte
111$
	move.w	(A5),D1	* get number of index reg
	moveq	#12,D0
	lsr.w	D0,D1
	and.w	#%0111,D1
	move.w	(A5),D0	* An or Dn?
	bmi	112$
	bsr	50$
	bra	113$
112$
	bsr	60$
113$
	move.b	#'.',D0
	bsr	depbyte
	move.b	#'w',D0
	move.w	(A5)+,D1
	btst	#11,D1	* .W or .L ?
	beq	114$
	move.b	#'l',D0
114$
	bsr	depbyte
	move.b	#')',D0
	bra	depbyte
12$
	move.w	(A5),D0
	ext.w	D0
	movem.l  D1/D3/A0,-(SP)
	bsr	.shoffs2
	movem.l  (SP)+,D1/D3/A0
	move.b	#'(',D0
	bsr	depbyte
	bra	111$


shsigned4x
	movem.l  D1/D3/A0,-(SP)
	tst.w	D0
	bpl	1$
	neg.w	D0
	move.w	D0,-(SP)
	char	-
	move.w	(SP)+,D0
1$	bsr	show4x
	movem.l  (SP)+,D1/D3/A0
	rts
  
mmask
	move.w	(A5)+,D0 * get mask
mmask1
* if '-(An)', reverse bits
	move.w	D5,D1
	and.w	#%0000000000111000,D1
	cmp.w	#%0000000000100000,D1
	bne	20$
	move.w	#15,D3
10$
	roxr.w	#1,D0
	roxl.w	#1,D1
	dbra	D3,10$
	move.w	D1,D0
20$
	clr.b	D2	* last bit not set
	clr.l	D1	* start with bit 0
	clr.b	D3	* no bytes deposited yet
	lea	obuf,A0  * deposit bytes here

1$	btst	D1,D0
	bne	2$
	clr.b	D2
	bra	4$
* have bit 1 -- should we just put in '-'?
2$	addq.b	#1,D1	* glance next bit
	tst.b	D2	* last bit set?
	beq	3$
	cmp.b	#8,D1	* last D-register?
	beq	3$
	cmp.b	#9,D1	* first A-register?
	beq	3$
	cmp.b	#16,D1	* was last register?
	beq	3$
	btst	D1,D0	* end of range?
	beq	3$
	cmp.b	#'-',D2	* already have hyphen?
	beq	5$
	move.b	#'-',D2
	move.b	D2,(A0)+
	addq.b	#1,D3
	bra	5$
3$	subq.b	#1,D1
	bsr	mdepreg
	st	D2
4$	addq.b	#1,D1
5$	cmp.b	#16,D1
	blt	1$
	lea	olen,A0
	move.b	D3,(A0)
	bra	msg

mdepreg
	movem.l  D0/D1,-(SP)
	tst.b	D3
	beq	1$
	cmp.b	#'-',D2
	beq	1$
	move.b	#'/',D0
	bsr	depbyte
1$	move.b	#'D',D0
	cmp.b	#8,D1
	blt	2$
	move.b	#'A',D0
2$	bsr	depbyte
	and.b	#%0111,D1
	bsr	depreg
	movem.l  (SP)+,D0/D1
	rts

depreg
	move.b	#'0',D0
	add.b	D1,D0
depbyte
	move.b	D0,(A0)+
	addq.b	#1,D3
	rts

ex11.10.9
	move.w	D5,D1
	and.w	#%0000111000000000,D1
	lsr.w	#4,D1
	lsr.w	#5,D1
	rts

.shstub
	print	_astub
	rts

_astub	dc.b	6,'oprand'
smodenames
nameSR	dc.b	2,'SR'
nameCCR	dc.b	3,'CCR'
nameUSP	dc.b	3,'USP'
	cnop	0,2

imsrce.d
	move.w	D6,D0
	and.w	#StatusMode,D0
	beq	imsrce
	lea	smodenames,A0
	move.w	D6,D0
	and.w	#ByteSize,D0
	cmp.w	#WordSize,D0
	bne	msg
	lea	3(A0),A0
	bra	msg
imsrce
	char	#
	move.w	D6,D0
	and.w	#ByteSize,D0
	cmp.w	#LongSize,D0
	bne	1$

	move.l	(A5),D0
	bsr	pseudoaddress	* no symbol if ref. outside file
	move.l	(A5)+,D0
	tst.l	D1
	bne	shopdlabel
	move.l	D0,-(SP)
	char	$
	move.l	(SP)+,D0
	bra	show8x

1$	cmp.w	#WordSize,D0
	beq	2$
	move.w	(A5)+,D0
	bra	showbyte
2$	move.w	(A5)+,D0
	bra	show4x

wordalign
	move.l	D0,-(SP)
	move.l	A5,D0
	bclr	#0,D0
	move.l	D0,A5
	move.l	(SP)+,D0
	rts


showadr
	move.l	A5,D0
	bsr	pseudoaddress
	tst.l	D1
	bne	2$
	move.w	#-1,linecount
	addq.l	#4,SP
1$	rts
2$	move.b	tflag,D1
	bne	1$
	sub.l	D7,D0
	bmi	show8x
show6x
	bsr	binhex
	lea	obuf,A0
	addq	#1,A0
	move.b	#6,(A0)
	bra	msg
showbyte
	cmp.b	#' ',D0
	blt	show2x
	cmp.b	#126,D0
	bhi	show2x
	move.l	D0,-(SP)
	cmp.b	#'''',D0
	bne	1$
	bsr	prtchr
1$	move.b	#'''',D0
	bsr	prtchr
	move.l	(SP)+,D0
	bsr	prtchr
	move.b	#'''',D0
	bra	prtchr

show2x
	cmp.b	#9,D0
	bhi	1$
	add.b	#$30,D0
	bra	prtchr
1$	bsr	binhex
	lea	obuf,A0
	addq	#5,A0
	move.b	#'$',(A0)
	subq.l	#1,A0
	move.b	#3,(A0)
	bra	msg
show4x
	cmp.w	#$FF,D0
	bls	show2x
	bsr	binhex
	lea	obuf,A0
	addq	#3,A0
	move.b	#'$',(A0)
	subq.l	#1,A0
	move.b	#5,(A0)
	bra	msg
show8x
	bsr	binhex
	lea	olen,A0
	bra	msg


* D0 to hex in obuf
binhex
	move.b	#8,olen
	lea	obuf,A0
	add.l	#8,A0
	lea	hextab,A1
	moveq	#7,D1
1$	move.l	D0,D2
	and.l	#15,D2
	move.b	0(A1,D2),-(A0)
	lsr.l	#4,D0
	dbra	D1,1$
	rts

getsnum
	movem.l  D0/D1,-(SP)
	move.b	#'0',D1
	bra	.gtnm

* hex in ibuf to D2
getnum
	lea	ibuf,A0
	addq.l	#1,A0
	movem.l  D0/D1,-(SP)
	move.b	(A0)+,D1
.gtnm
	clr.l	D2
	clr.l	D0
	cmp.b	#'0',D1	* is it a decimal digit?
	bcs	9$
	cmp.b	#'9',D1
	bhi	9$

	lea	hextab,A1
1$	moveq	#15,D3
2$	cmp.b	0(A1,D3),D1
	dbeq	D3,2$
	bne	8$	* if not hex digit, done
	lsl.l	#4,D2
	add.l	D3,D2
	move.b	(A0)+,D1
	addq.b	#1,D0
	cmp.b	#'a',D1
	blt	1$
	sub.b	#32,D1
	bra	1$
8$	move.b	D0,D3
	cmp.l	D2,D2	* signal ok
9$	movem.l  (SP)+,D0/D1
	rts

hextab	dc.b	'0123456789ABCDEF'

symread
	moveq	#0,D0
	move.w	D0,farea
	move.b	D0,bufchcount
	move.l	D0,bufptr
	move.b	D0,stfflag

	move.w	#SymMax,-(SP)
	lea	symtab,A1
1$	subq.w	#1,(SP)
	beq	10$
	move.l	A1,-(SP)
	bsr	readln
	move.l	(SP)+,A1
	tst.b	D3
	bne	2$
10$
	addq	#2,SP
	move.l	A1,endsym
	clr.l	(A1)	* terminate table
	rts

2$	movem.l  D3/A1,-(SP)
	bsr	getsnum		* leaves A0 at beginning of symbol
	move.b	D3,D0
	movem.l  (SP)+,D3/A1
	sub.b	D0,D3		* just scanned 9(?) bytes
	move.l	D2,(A1)+	* put number in table
	move.w	farea,D2
	move.w	D2,(A1)+
	move.l	A1,-(SP)
	lea	sarea,A1
	add.w	D2,A1

	move.b	D3,(A1)+	* length to table
	add.w	D3,D2
	addq.w	#1,D2
	move.w	D2,farea

* move the symbol
	subq	#1,D3
3$	move.b	(A0)+,(A1)+
	dbra	D3,3$
	move.l	(SP)+,A1
	bra	1$



* return A0 pointing to line and D3 length of line
readln
	move.l	bufptr,A0
	move.l	A0,-(SP)
	moveq	#0,D3	* no chars in line yet
* back to here when was necessary to read more from file
.rdln.cont
	moveq	#0,D2
	move.b	bufchcount,D2
	bmi	5$	* this means file is exhausted
	beq	.rdln.more

	subq.b	#1,D2
2$	cmp.b	#10,(A0)+
	beq	4$
	addq.b	#1,D3
3$	dbra	D2,2$
* ran out of chars -- go get more
	bra	.rdln.more
* have one line -- check not empty
4$	tst.b	D3
	bne	5$
	move.l	A0,(SP)	* replace pointer to ret.
	bra	3$
5$	move.l	A0,bufptr
	move.b	D2,bufchcount
	move.l	(SP)+,A0
	rts


.rdln.more
* have partial line in buffer with D3 chars in it
	move.l	(SP)+,A1	* beginning of partial line
* while D3>0 move chars back to beginning of buffer
	lea	ibuf,A0
	move.l	A0,-(SP)	* for ret.
	move.l	D3,-(SP)
	subq.b	#1,D3
	bmi	7$	* if line was of 0 length
6$	move.b	(A1)+,(A0)+
	dbra	D3,6$

* if file is not yet open, A1 will be 0, since
*  that is initial value of bufptr
7$	move.l	A1,D0
	bne	8$

* open the file
	bsr	seename
	move.l	#1005,D2
	call	Open
	tst.l	D0
	bne	71$
	bsr	.symerr
	addq.l	#8,SP	* ptr and char count were on stack
	moveq	#0,D3
	rts
71$
	move.l	D0,symhandle

* fill remainder of buffer with 80-(D3) chars
8$	move.l	#80,D3
	move.l	(SP)+,D0
	sub.b	D0,D3
	move.l	D0,-(SP)

	lea	ibuf,A1
	add.l	D0,A1
* save where to continue processing line
	move.l	A1,-(SP)

	move.l	symhandle,D1
	move.l	A1,D2
	call	Read

	tst.b	D0
	bne	9$
	move.l	symhandle,D1
	call	Close
	st	D0
9$	move.b	D0,bufchcount

	move.l	(SP)+,A0	* continue processing here
	move.l	(SP)+,D3	* chars scanned so far
	bra	.rdln.cont


seename
	lea	ibuf,A0
	addq.l	#1,A0
	tst.b	(A0)
	bne	1$
	lea	symfilename,A0
1$	move.l	A0,D1
	rts

symsave
	bsr	seename
	move.l	D1,-(SP)
	call	DeleteFile
	move.l	(SP)+,D1
	move.l	#1006,D2
	call	Open
	tst.l	D0
	beq	.symerr

	move.l	D0,D1	* keep handle in D1 throughout
	lea	symtab,A1
1$	move.l	(A1)+,D0
	beq	.symclose
	movem.l  D1/A1,-(SP)
	bsr	binhex
	movem.l  (SP)+,D1/A1

	move.w	(A1)+,D2
*	lea	SymLen-4(A1),A0
	move.l	A1,-(SP)	* save pointer to next symtab entry
	lea	sarea,A1
	add.w	D2,A1

	lea	obuf,A0
	move.l	A0,-(SP)	* save for pass to WRITE
	lea	8(A0),A0
	move.b	#' ',(A0)+
	moveq	#0,D3
	move.b	(A1)+,D3	* length of symbol
	move.l	D3,D2		* count letters to move
	add.w	#10,D3		* chars to write
	subq	#1,D2
2$	move.b	(A1)+,(A0)+
	dbra	D2,2$
	move.b	#10,(A0)

	move.l	(SP)+,D2	* obuf is buffer
	movem.l  D1/D3,-(SP)	* save handle & len
	call	Write
	movem.l  (SP)+,D1/D3

	move.l	(SP)+,A1
	cmp.l	D0,D3
	beq	1$	* loop if OK
	bsr	.symclose
	bra	.symerr
.symclose
	call	Close
	rts
.symerr
	call	IoErr
	jmp	show4x

funload
	move.l	fileseg,D1
	beq	1$
	call	UnLoadSeg
	moveq	#0,D0
	move.l	D0,fileseg
	move.l	D0,foreseg
	move.l	D0,segtable
1$	rts

fload
	bsr	funload
	bsr	seename
	call	LoadSeg
	move.l	D0,fileseg
	beq	.linkseg
	move.b	#-1,pflag
	move.w	#SegMax,D3
	lea	segtable,A0
	move.l	D0,A1
1$	add.l	A1,A1
	add.l	A1,A1
	move.l	A1,D1
	addq.l	#4,D1
	move.l	D1,(A0)+
	move.l	-4(A1),D1
	subq.l	#8,D1
	move.l	D1,(A0)+
	clr.l	(A0)
	subq.w	#1,D3
	beq	.linkseg
	move.l	(A1),A1
	move.l	A1,D1
	bne	1$
.linkseg
	tst.l	D0
	beq	2$
	lsl.l	#2,D0
	move.l	D0,A5
	move.l	(A5)+,D0
	move.l	D0,foreseg
	move.l	A5,D0
2$	rts

firstfseg
	move.l	fileseg,D0
	bra	.linkseg

nextfseg
	move.l	foreseg,D0
	bra	.linkseg

pseudoaddress
	moveq	#-1,D1
	move.b	pflag,D1
	beq	2$
	lea	segtable,A0
	moveq	#0,D4
1$	move.l	(A0)+,D1
	beq	2$
	move.l	(A0)+,D2
	add.l	D2,D4
	move.l	D0,D3
	sub.l	D1,D3
	bmi	1$
	cmp.l	D2,D3
	bge	1$
	sub.l	D2,D4
	add.l	D4,D3
	move.l	D3,D0
2$	rts

realaddress
	move.b	pflag,D1
	beq	2$
	lea	segtable,A0
	moveq	#0,D4
1$	move.l	(A0)+,D1
	beq	2$
	move.l	(A0)+,D2
	add.l	D2,D4
	move.l	D0,D3
	cmp.l	D4,D3
	bge	1$
	sub.l	D2,D4
	sub.l	D4,D3
	add.l	D3,D1
	move.l	D1,D0
2$	rts

ksave
	lea	ibuf,A0
	addq.l	#1,A0
	tst.b	(A0)
	bne	1$
	rts
1$	move.l	A0,D1
	move.l	D1,-(SP)
	call	DeleteFile
	move.l	(SP)+,D1
	move.l	#1006,D2
	call	Open
	move.l	D0,khandle
	tst.l	D0
	beq	.symerr
	rts

khandle		dc.l	0
fileseg		dc.l	0
foreseg		dc.l	0
symhandle	dc.l	0
bufptr		dc.l	0
bufchcount	dc.b	0
symfilename	dc.b	'symtab',0
	cnop	0,2

* string from console to obuf
getstr
	move.l	ihandle,D1
	lea	ibuf,A1
	move.l	A1,D2
	moveq	#80,D3
	move.l	A1,-(SP)
	call	Read
	move.l	(SP)+,A1
	move.b	#0,-1(A1,D0.W)
	move.b	D0,ilen
	move.b	D0,D3
	move.b	(A1),D0
leftprint
	move.b	#0,printhead
	rts

column
	move.b	D0,D3
	sub.b	printhead,D0
	beq	2$
	bpl	1$
	move.w	D3,-(SP)
	bsr	newline
	move.w	(SP)+,D0
1$	move.b	D0,splen
	lea	splen,A0
	bra	msg
2$	rts

newline
	sub.w	#1,linecount
	move.b	#10,D0
	bsr	prtchr
	bra	leftprint
prtspc
	move.b	#' ',D0
* char in D0 to console
prtchr
	move.b	D0,obuf
	move.l	ohandle,D1
	lea	obuf,A1
	move.l	A1,D2
	moveq	#1,D3
	bra	.msg1

*  message to console
msg
	move.l	ohandle,D1
	clr.l	D3
	move.b	(A0)+,D3
	move.l	A0,D2
.msg1
	add.b	D3,printhead
	movem.l  D2/D3,-(SP)
	call	Write
	movem.l  (SP)+,D2/D3
	move.l	khandle,D1
	beq	1$
	move.b	kflag,D0
	beq	1$
	call	Write
1$	rts

* obtain pointer to AmigaDOS
ioinit
	move.l	SysBase,A6	* ready call to OpenLibrary
	lea	libname,A1
	moveq	#0,D0
	call	OpenLibrary
	move.l	D0,A6
	move.l	D0,DOS_point
* obtain file handles for output and input opened by CLI
	call	Output
	move.l	D0,ohandle
	call	Input
	move.l	D0,ihandle
	rts
	cnop  0,4

	section  three,bss

DOS_point	ds.l  1
ohandle		ds.l  1
ihandle		ds.l  1

olen		ds.b  1
obuf		ds.b  80
ilen		ds.b  1
ibuf		ds.b  IbufLen
* now on word boundary

segtable	ds.l SegMax*2
		ds.l  1
symtab		ds.b  SymMax*6
endsymtab	ds.b  6
sarea		ds.b  SymMax*7
endsarea	ds.b  30

	section two,data

kflag		dc.b	0
tflag		dc.b	0
pflag		dc.b	0
bflag		dc.b	0
stfflag		dc.b	0

splen		dc.b	0
		dcb.b	80,' '
printhead	dc.b	0
lastcmd		dc.b	'l'
	cnop  0,2
reqlines	dc	20
linecount	dc	-1
farea		dc	0
lastadr		dc.l	0
endsym		dc.l	symtab

libname		dc.b	'dos.library',0
hello		dc.b	26,'Disassemble (? for info).',10
fullmsg		dc.b	1$-*-1
		dc.b	10,'Symbol table is full',10
1$
helpmsg		dc.b	1$-*-1
		dc.b	'l[addr]    list instructions',10
		dc.b	'd[addr]    dump in hex',10
		dc.b	'a[addr]    ascii dump',10
		dc.b	'/addr      address is this',10
		dc.b	'=<symbol>  add symbol to table',10
		dc.b	'r[<name>]  read file (symtab)',10
		dc.b	's[<name>]  save to file (symtab)',10
		dc.b	'q          quit',10
1$
helpmsg2	dc.b	1$-*-1
		dc.b	'w<num>     where is this word?',10
		dc.b	'W<addr>    where is this longword?',10
		dc.b	'f<name>    file to disassemble',10
		dc.b	'>          next code segment',10
		dc.b	'<          first code segment',10
		dc.b	'o[num]     offset addresses',10
1$
helpmsg3	dc.b	1$-*-1
		dc.b	'p          offset by segment toggle',10
		dc.b	'k<name>    keep output in file',10
		dc.b	't          trim toggle',10
		dc.b	'b[addr]    build symbols',10
		dc.b	'n<num>     print n lines after <CR>',10
1$

isize		dc.b	0

condlets	dc.b	't rahilscccsneeqvcvsplmigeltgtle'

Size		equ	%0000000000000001
EffAdr		equ	%0000000000000010
Displ		equ	%0000000000000100
Immed		equ	%0000000000001000
RegField1	equ	%0000000000010000
RegField2	equ	%0000000000100000
ARegField2	equ	%0000000000110000
ByteSize	equ	%0000000011000000
WordSize	equ	%0000000001000000
LongSize	equ	%0000000010000000
SmallImmed	equ	%0000000100000000
FlagMovem	equ	%0000001000000000
FlagCmpm	equ	%0000010000000000
StatusMode	equ	%0000100000000000
PreDecr		equ	%0001000000000000
SubCall		equ	%0010000000000000

	cnop  0,2
mtab
	dc	%1111111100000000,%0000000000000000
	dc.b	'or.   '
	dc	EffAdr!Size!Immed!StatusMode
	dc	%1111000110111000,%0000000100001000
	dc.b	'movep.'
	dc	EffAdr!RegField2
	dc	%1111000110111000,%0000000110001000
	dc.b	'movep.'
	dc	EffAdr!RegField1
	dc	%1111000111000000,%0000000100000000
	dc.b	'btst  '
	dc	EffAdr!RegField1
	dc	%1111000111000000,%0000000101000000
	dc.b	'bchg  '
	dc	EffAdr!RegField1
	dc	%1111000111000000,%0000000110000000
	dc.b	'bclr  '
	dc	EffAdr!RegField1
	dc	%1111000111000000,%0000000111000000
	dc.b	'bset  '
	dc	EffAdr!RegField1
	dc	%1111111100000000,%0000001000000000
	dc.b	'and.  '
	dc	EffAdr!Size!Immed!StatusMode
	dc	%1111111100000000,%0000010000000000
	dc.b	'sub.  '
	dc	EffAdr!Size!Immed
	dc	%1111111100000000,%0000011000000000
	dc.b	'add.  '
	dc	EffAdr!Size!Immed
	dc	%1111111111000000,%0000100000000000
	dc.b	'btst  '
	dc	EffAdr
	dc	%1111111111000000,%0000100001000000
	dc.b	'bchg  '
	dc	EffAdr
	dc	%1111111111000000,%0000100010000000
	dc.b	'bclr  '
	dc	EffAdr
	dc	%1111111111000000,%0000100011000000
	dc.b	'bset  '
	dc	EffAdr
	dc	%1111111100000000,%0000101000000000
	dc.b	'eor.  '
	dc	EffAdr!Size!Immed!StatusMode
	dc	%1111111100000000,%0000110000000000
	dc.b	'cmp.  '
	dc	EffAdr!Size!Immed
	dc	%1111000000000000,%0001000000000000
	dc.b	'move.b'
	dc	EffAdr!ByteSize
	dc	%1111000000000000,%0010000000000000
	dc.b	'move.l'
	dc	EffAdr!LongSize
	dc	%1111000000000000,%0011000000000000
	dc.b	'move.w'
	dc	EffAdr!WordSize
	dc	%1111111111000000,%0100000011000000
	dc.b	'move  '	* from SR
	dc	EffAdr
	dc	%1111111100000000,%0100000000000000
	dc.b	'negx. '
	dc	EffAdr!Size
	dc	%1111000111000000,%0100000110000000
	dc.b	'chk   '
	dc	EffAdr!RegField2
	dc	%1111000111000000,%0100000111000000
	dc.b	'lea   '
	dc	EffAdr!ARegField2
	dc	%1111111100000000,%0100001000000000
	dc.b	'clr.  '
	dc	EffAdr!Size
	dc	%1111111111000000,%0100010011000000
	dc.b	'move  '	* to CCR
	dc	EffAdr
	dc	%1111111100000000,%0100010000000000
	dc.b	'neg.  '
	dc	EffAdr!Size
	dc	%1111111111000000,%0100011011000000
	dc.b	'move  '	* to SR
	dc	EffAdr
	dc	%1111111100000000,%0100011000000000
	dc.b	'not.  '
	dc	EffAdr!Size
	dc	%1111111111000000,%0100100000000000
	dc.b	'nbcd  '
	dc	EffAdr
	dc	%1111111111111000,%0100100001000000
	dc.b	'swap  '
	dc	EffAdr
	dc	%1111111111111000,%0100100010000000
	dc.b	'ext.w '
	dc	EffAdr!WordSize
	dc	%1111111111111000,%0100100011000000
	dc.b	'ext.l '
	dc	EffAdr!LongSize
	dc	%1111111111000000,%0100100001000000
	dc.b	'pea   '
	dc	EffAdr
	dc	%1111111110000000,%0100100010000000
	dc.b	'movem.' ;has size!
	dc	EffAdr!FlagMovem
	dc	%1111111100000000,%0100101000000000
	dc.b	'tst.  '
	dc	EffAdr!Size
	dc	%1111111111000000,%0100101011000000
	dc.b	'tas   '
	dc	EffAdr
	dc	%1111111111111111,%0100101011111100
	dc.b	'illegl'
	dc	0
	dc	%1111111110000000,%0100110010000000
	dc.b	'movem.'
	dc	EffAdr!FlagMovem
	dc	%1111111111110000,%0100111001000000
	dc.b	'trap  '
	dc	0
	dc	%1111111111111000,%0100111001010000
	dc.b	'link  '
	dc	EffAdr
	dc	%1111111111111000,%0100111001011000
	dc.b	'unlk  '
	dc	EffAdr
*MOVE to USP
*MOVE from USP
	dc	%1111111111110000,%0100111001100000
	dc.b	'move  '	*  USP
	dc	EffAdr
	dc	%1111111111111111,%0100111001110000
	dc.b	'reset '
	dc	0
	dc	%1111111111111111,%0100111001110001
	dc.b	'nop   '
	dc	0
	dc	%1111111111111111,%0100111001110010
	dc.b	'stop  '
	dc	0
	dc	%1111111111111111,%0100111001110011
	dc.b	'rte   '
	dc	0
*RTD
	dc	%1111111111111111,%0100111001110101
	dc.b	'rts   '
	dc	0
	dc	%1111111111111111,%0100111001110110
	dc.b	'trapv '
	dc	0
	dc	%1111111111111111,%0100111001110111
	dc.b	'rtr   '
	dc	0
*MOVEC
	dc	%1111111111000000,%0100111010000000
	dc.b	'jsr   '
	dc	EffAdr!SubCall
	dc	%1111111111000000,%0100111011000000
	dc.b	'jmp   '
	dc	EffAdr
	dc	%1111000011111000,%0101000011001000
	dc.b	'db@@  '
	dc	EffAdr * lie required by showarg
	dc	%1111111111000000,%0101000111000000
	dc.b	'sf    '
	dc	EffAdr
	dc	%1111000011000000,%0101000011000000
	dc.b	's@@   '
	dc	EffAdr
	dc	%1111000100000000,%0101000000000000
	dc.b	'addq. '
	dc	EffAdr!Size!SmallImmed
	dc	%1111000100000000,%0101000100000000
	dc.b	'subq. '
	dc	EffAdr!Size!SmallImmed
	dc	%1111111100000000,%0110000100000000
	dc.b	'bsr   '
	dc	Displ!SubCall
	dc	%1111111100000000,%0110000000000000
	dc.b	'bra   '
	dc	Displ
	dc	%1111000000000000,%0110000000000000
	dc.b	'b@@   '
	dc	Displ
	dc	%1111000100000000,%0111000000000000
	dc.b	'moveq '
	dc	RegField2!SmallImmed
	dc	%1111000111000000,%1000000011000000
	dc.b	'divu  '
	dc	EffAdr!RegField2
	dc	%1111000111110000,%1000000100000000
	dc.b	'sbcd  '
	dc	EffAdr!PreDecr
	dc	%1111000111000000,%1000000111000000
	dc.b	'divs  '
	dc	EffAdr!RegField2
	dc	%1111000100000000,%1000000000000000
	dc.b	'or.   '
	dc	EffAdr!Size!RegField2
	dc	%1111000100000000,%1000000100000000
	dc.b	'or.   '
	dc	EffAdr!Size!RegField1
	dc	%1111000111000000,%1001000011000000
	dc.b	'sub.w '
	dc	EffAdr!WordSize!ARegField2
	dc	%1111000111000000,%1001000111000000
	dc.b	'sub.l '
	dc	EffAdr!LongSize!ARegField2
	dc	%1111000100110000,%1001000100000000
	dc.b	'subx. '
	dc	EffAdr!Size!PreDecr
	dc	%1111000100000000,%1001000000000000
	dc.b	'sub.  '
	dc	EffAdr!Size!RegField2
	dc	%1111000100000000,%1001000100000000
	dc.b	'sub.  '
	dc	EffAdr!Size!RegField1
	dc	%1111000111000000,%1011000011000000
	dc.b	'cmp.w '
	dc	EffAdr!WordSize!ARegField2
	dc	%1111000111000000,%1011000111000000
	dc.b	'cmp.l '
	dc	EffAdr!LongSize!ARegField2
	dc	%1111000100000000,%1011000000000000
	dc.b	'cmp.  '
	dc	EffAdr!Size!RegField2
	dc	%1111000100111000,%1011000100001000
	dc.b	'cmpm. '
	dc	EffAdr!Size!FlagCmpm
	dc	%1111000100000000,%1011000100000000
	dc.b	'eor.  '
	dc	EffAdr!Size!RegField1
	dc	%1111000111110000,%1100000100000000
	dc.b	'abcd  '
	dc	EffAdr!PreDecr
	dc	%1111000111000000,%1100000011000000
	dc.b	'mulu  '
	dc	EffAdr!RegField2
	dc	%1111000111111000,%1100000101000000
	dc.b	'exg   '
	dc	EffAdr!RegField2
	dc	%1111000111111000,%1100000101001000
	dc.b	'exg   '
	dc	EffAdr!ARegField2
	dc	%1111000111111000,%1100000110001000
	dc.b	'exg   '
	dc	EffAdr!RegField2
	dc	%1111000111000000,%1100000111000000
	dc.b	'muls  '
	dc	EffAdr!RegField2
	dc	%1111000100000000,%1100000000000000
	dc.b	'and.  '
	dc	EffAdr!Size!RegField2
	dc	%1111000100000000,%1100000100000000
	dc.b	'and.  '
	dc	EffAdr!Size!RegField1
	dc	%1111000111000000,%1101000011000000
	dc.b	'add.w '
	dc	EffAdr!WordSize!ARegField2
	dc	%1111000111000000,%1101000111000000
	dc.b	'add.l '
	dc	EffAdr!LongSize!ARegField2
	dc	%1111000100110000,%1101000100000000
	dc.b	'addx. '
	dc	EffAdr!Size!PreDecr
	dc	%1111000100000000,%1101000000000000
	dc.b	'add.  '
	dc	EffAdr!Size!RegField2
	dc	%1111000100000000,%1101000100000000
	dc.b	'add.  '
	dc	EffAdr!Size!RegField1

	dc	%1111111111000000,%1110000011000000
	dc.b	'asr   '
	dc	EffAdr
	dc	%1111111111000000,%1110000111000000
	dc.b	'asl   '
	dc	EffAdr
	dc	%1111111111000000,%1110001011000000
	dc.b	'lsr   '
	dc	EffAdr
	dc	%1111111111000000,%1110001111000000
	dc.b	'lsl   '
	dc	EffAdr
	dc	%1111111111000000,%1110010011000000
	dc.b	'roxr  '
	dc	EffAdr
	dc	%1111111111000000,%1110010111000000
	dc.b	'roxl  '
	dc	EffAdr
	dc	%1111111111000000,%1110011011000000
	dc.b	'ror   '
	dc	EffAdr
	dc	%1111111111000000,%1110011111000000
	dc.b	'rol   '
	dc	EffAdr

	dc	%1111000100011000,%1110000000000000
	dc.b	'asr.  '
	dc	EffAdr!Size!SmallImmed
	dc	%1111000100011000,%1110000100000000
	dc.b	'asl.  '
	dc	EffAdr!Size!SmallImmed
	dc	%1111000100011000,%1110000000001000
	dc.b	'lsr.  '
	dc	EffAdr!Size!SmallImmed
	dc	%1111000100011000,%1110000100001000
	dc.b	'lsl.  '
	dc	EffAdr!Size!SmallImmed
	dc	%1111000100011000,%1110000000010000
	dc.b	'roxr. '
	dc	EffAdr!Size!SmallImmed
	dc	%1111000100011000,%1110000100010000
	dc.b	'roxl. '
	dc	EffAdr!Size!SmallImmed
	dc	%1111000100011000,%1110000000011000
	dc.b	'ror.  '
	dc	EffAdr!Size!SmallImmed
	dc	%1111000100011000,%1110000100011000
	dc.b	'rol.  '
	dc	EffAdr!Size!SmallImmed

	dc	0,0
	dc.b	'????  '
	dc	0

	end

