* LPR command      by Sean Godsell
*    This program loads & prints text files to the printer
*    and it will not need the PRT: requirements from the disk
*
* The folling are my own includes. Now the assembler does not have
* to go out and read any includes off the disk.

sysbase        equ   4
lock           equ   -84            dos
unlock         equ   -90            dos
examine        equ   -102           dos
write          equ   -48            dos
read           equ   -42            dos
open           equ   -30            dos
close          equ   -36            dos
delay          equ   -198           dos
openmylib      equ   -408           exec
closemylib     equ   -414           exec
findtask       equ   -294           exec
addtask        equ   -282           exec
remtask        equ   -288           exec
allocmemy      equ   -198           exec
freememy       equ   -210           exec
autorequest    equ   -348           intuition
porta          equ   $bfe101        cia
dirporta       equ   $bfe301        cia
portsig        equ   $bfd000        cia
direction      equ   255
MEMF_PUBLIC    equ   1
MEMF_CLEAR     equ   $10000
MODE_OLDFILE   equ   1005
ACCESS_READ    equ   -2
lenfile        equ   $7c
seconds        equ   10
version        equ   0

*  open up the DOS library --------------------
   movem.l  d1-d7/a0-a6,-(sp)
   move.l   sysbase,a6
   lea      dosname(pc),a1
   moveq    #0,d0
   jsr      openmylib(a6)
   move.l   d0,dosbase
   beq      openerror
*  allocate memory for examine ----------------
alloctheram
   move.l   amtofRAM,d0
   move.l   #MEMF_PUBLIC+MEMF_CLEAR,d1
   move.l   sysbase,a6
   jsr      allocmemy(a6)
   tst.l    d0
   beq      openerror
   move.l   d0,areaofRAM
*  look at the file ---------------------------
   movem.l  (sp)+,d1-d7/a0-a6
   movem.l  d1-d7/a0-a6,-(sp)
   clr.w    d0
fixuprequest:
   cmp.b    #$20,0(a0,d0.w)
   beq.s    foundasp
   cmp.b    #$a,0(a0,d0.w)
   beq.s    foundasp
   addq.b   #1,d0
   bne.s    fixuprequest
foundasp:
   move.b   #0,0(a0,d0.w)
   move.l   a0,d1
   move.l   #ACCESS_READ,d2
   move.l   dosbase,a6
   jsr      lock(a6)
   tst.w    d0
   beq      openerror2
   move.l   areaofRAM,d2
   move.l   d0,locker
   move.l   d0,d1
   jsr      examine(a6)
   move.l   areaofRAM,a0
   cmp.w    #0,4(a0)
   bne.s    itsafile
   bsr.s    unlocker
   bra      openerror2
unlocker:
   move.l   locker,d1
   jsr      unlock(a6)
   rts
itsafile:
   move.l   lenfile(a0),filelength
   bsr.s    unlocker
   bsr      deallocateram
* allocate enough ram just for the length of the file --------
   move.l   filelength,d0
   addq.l   #8,d0
   move.l   d0,amtofRAM
   move.l   #MEMF_PUBLIC+MEMF_CLEAR,d1
   move.l   sysbase,a6
   jsr      allocmemy(a6)
   move.l   d0,areaofRAM
   beq      openerror
* open up the file and read it in -------------
   movem.l  (sp)+,d1-d7/a0-a6
   movem.l  d1-d7/a0-a6,-(sp)
   move.l   a0,d1
   move.l   #MODE_OLDFILE,d2
   move.l   dosbase,a6
   jsr      open(a6)
   move.l   d0,filehand
   beq      openerror2
   move.l   d0,d1
   move.l   areaofRAM,d2
   move.l   amtofRAM,d3
   jsr      read(a6)
   move.l   filehand,d1
   jsr      close(a6)
* get intution Base ---------------------------
   move.l   sysbase,a6
   lea      intuitlib(pc),a1
   move.l   #version,d0
   jsr      openmylib(a6)
   move.l   d0,intuitionbase
   beq      openerror2
* got file now print it out -------------------
   move.l   areaofRAM,a0
   move.l   amtofRAM,d2
   clr.l    d0
printmain:
   move.b   0(a0,d0.l),d1
   bsr      printbyte
   add.l    #1,d0
   cmp.l    d0,d2
   bne.s    printmain
   bra      openerror3
printbyte:
   movem.l  d0-d2/a0,-(sp)
lookforsig:
   move.b   #direction,dirporta
   move.b   portsig,d0
   eor.b    #4,d0
   and.b    #7,d0
   bne.s    noprinting
   move.b   d1,porta
   cmp.b    #$a,d1
   bne.s    nocr
   move.b   #$d,d1
   bra.s    lookforsig
nocr:
   movem.l  (sp)+,d0-d2/a0
   rts
noprinting:
   move.l   d1,-(sp)
   and.b    #6,d0
   beq.s    dontprinterr
   move.l   intuitionbase,a6
   move.l   #0,a0
   lea      BodyText(pc),a1
   lea      PositiveText(pc),a2
   lea      NegativeText(pc),a3
   move.l   #0,d0
   move.l   #$9000,d1
   move.l   #300,d2
   move.l   #70,d3
   jsr      autorequest(a6)
   tst.l    d0
   bne.s    dontprinterr
   add.l    #$18,a7
   bra      openerror3
dontprinterr:
   move.l   (sp)+,d1
   bra      lookforsig
* clean up shop -------------------------------
deallocateram:
   move.l   areaofRAM,a1
   move.l   amtofRAM,d0
   move.l   sysbase,a6
   jsr      freememy(a6)
   rts
openerror3:
   move.l   sysbase,a6
   move.l   intuitionbase,a1
   jsr      closemylib(a6)
openerror2:
   bsr      deallocateram
openerror:
   move.l   dosbase,a1
   move.l   sysbase,a6
   jsr      closemylib(a6)
   movem.l  (sp)+,d1-d7/a0-a6
   clr.l    d0
   rts
* data ----------------------------------------
dosname        dc.b  'dos.library',0
intuitlib      dc.b  'intuition.library',0
               cnop  0,2
BodyText       dc.b  0,1   Frontpen, Backpen
               dc.b  2     Drawmode
               dc.w  20    Leftedge
               dc.w  15    Topedge
               dc.l  0     TextAttr
               dc.l  mytext   pointer to my text
               dc.l  0     next text to come
PositiveText   dc.b  1,0
               dc.b  1
               dc.w  6
               dc.w  3
               dc.l  0
               dc.l  postext
               dc.l  0
NegativeText   dc.b  1,0
               dc.b  1
               dc.w  6
               dc.w  3
               dc.l  0
               dc.l  negtext
               dc.l  0
mytext         dc.b  'Sean!   Printer Not Ready!',0
negtext        dc.b  'Cancel',0
postext        dc.b  'Retry',0
               cnop  0,2
dosbase        ds.l  1
intuitionbase  ds.l  1
locker         ds.l  1
filehand       ds.l  1
areaofRAM      ds.l  1
amtofRAM       dc.l  512
filelength     ds.l  1
   end
