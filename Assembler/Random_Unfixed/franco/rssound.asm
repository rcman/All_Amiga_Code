* This program digitizes sounds
* plays and loads & saves sound samples
*       programmed by  Sean Godsell

sysbase     equ   4
openmylib   equ   -408
closemylib  equ   -414
version     equ   0
openwindow  equ   -204
closewindow equ   -72
printitext  equ   -216
refreshgadgets equ   -222
setmenustrip   equ   -264
clearmenustrip equ   -54
addgadget   equ   -42
wait        equ   -318
delay       equ   -198
exnext      equ   -108
examine     equ   -102
close       equ   -36
open        equ   -30
lock        equ   -84
read        equ   -42
write       equ   -48
unlock      equ   -90
ioerr       equ   -132
access_read equ   -2
allocmemy   equ   -198
freememy    equ   -210
forbid      equ   -132
permit      equ   -138
intena      equ   $dff09a
intreq      equ   $dff09c
totalram    equ   $2000+$2000
minimummem  equ   $1000
MEMF_CHIP   equ   2
MEMF_CLEAR  equ   $10000
MODE_OLDFILE   equ   1005
MODE_NEWFILE   equ   1006
err_no_ent  equ   232

draw        equ   -246
setbpen     equ   -348
setapen     equ   -342
movepen     equ   -240
rectfill    equ   -306
scrollraster   equ   -396

   movem.l  d1-d7/a0-a6,-(sp)
* open libraries -------------
   move.l   sysbase,a6
   lea      intuitlib(pc),a1
   move.l   #29,d0                version
   jsr      openmylib(a6)
   move.l   d0,intuitionbse
   beq      error
   lea      gfxbaselib(pc),a1
   move.l   #version,d0
   jsr      openmylib(a6)
   move.l   d0,gfxbase
   beq      error2
   lea      dosbaselib(pc),a1
   move.l   #version,d0
   jsr      openmylib(a6)
   move.l   d0,dosbase
   beq      error3
* open the window ------------
   move.l   intuitionbse,a6
   lea      mywindow(pc),a0
   jsr      openwindow(a6)
   move.l   d0,window
   beq      error4
* allocate some ram ----------
   bsr      allocate_wave
   move.w   #4,whichwave
   bsr      allocate_wave
   clr.w    whichwave
* find the raster port ------------
   move.l   window,a0
   move.l   $32(a0),rasterport
   bsr      draw_box
   bsr      placemapsamp
   bsr      printstartendout

* main loop -----------------------**************
mainloop:
   bsr      drawpeekmeter
   move.l   window,a0
   btst.b   #5,$1a(a0)
   beq.s    mainloop
   btst.b   #6,$bfe001
   bne.s    mainloop
   clr.l    d0
   clr.l    d1
   move.w   $c(a0),d1        y - coor
   move.w   $e(a0),d0        x - coor
   cmp.w    #610,d0
   bgt      checkgadgets         ****
   cmp.w    #10,d0
   blt      checkgadgets
   cmp.w    #132,d1
   blt      checkgadgets
   cmp.w    #196,d1
   bgt      checkgadgets
* place edit line on wave map -----
waittoplacelinek:
   btst.b   #6,$bfe001
   beq.s    waittoplacelinek
   move.l   d0,-(sp)
   move.w   d0,whereonwave
   bsr      placemapsamp
   move.l   rasterport,a1
   move.l   gfxbase,a6
   move.l   #1,d0
   jsr      setapen(a6)
   move.l   (sp)+,d0
   move.l   d0,-(sp)
   move.l   #132,d1
   jsr      movepen(a6)
   move.l   #196,d1
   move.l   (sp)+,d0
   jsr      draw(a6)          ;draw a line

;* edit the sound samples ---------
;   sub.l    #10,d0
;   movem.l  d0/d1,-(sp)         y/x - coor
;   move.l   samplelow,a0
;   clr.l    d3
;   move.b   0(a0,d1.w),d3
;   move.l   rasterport,a1
;   move.l   gfxbase,a6
;   move.l   d1,-(sp)
;   moveq    #1,d0
;   jsr      setapen(a6)
;   move.l   (sp)+,d0
;   lsl.w    #3,d0               multiply by 8
;   add.l    #359,d0
;   movem.l  d0/d3/a0,-(sp)
;   bsr      topwave
;   moveq    #3,d0
;   move.l   rasterport,a1
;   jsr      setapen(a6)
;   movem.l  (sp)+,d0/d3/a0
;   movem.l  (sp)+,d3/d4
;   tst.w    topbottomw
;   beq.s    its_topw
;   or.b     #$80,d3
;   bra.s    savenewsample
;its_topw:
;   eor.b    #$7f,d3
;savenewsample:
;   move.b   d3,0(a0,d4.w)           save back a new sample
;   bsr      topwave
;   bra      mainloop
checkgadgets:
   lea      rperiodgadget(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkleftgad
   lea      rperiodgadget(pc),a0
   clr.b    d1
   bsr.s    scrollrightleft
   bra.s    checkleftgad

scrollrightleft:
   move.l   #$11000,d0
waitforfright1:
   movem.l  d0/d1/a0,-(sp)
   bsr      converttoasc3
   movem.l  (sp)+,d0/d1/a0
   movem.l  d0/d1/a0,-(sp)
waitforfright:
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    endcheckright
   sub.l    #1,d0
   bne.s    waitforfright
   movem.l  (sp)+,d0/d1/a0
   cmp.l    #$1000,d0
   bgt.s    gofast2
   moveq    #5,d0
   bra.s    waitforfright1
gofast2:
   sub.l    #$2000,d0
   bra.s    waitforfright1
endcheckright:
   movem.l  (sp)+,d0/d1/a0
   rts

checkleftgad:
   lea      lperiodgadget(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkrightgad2
   lea      lperiodgadget(pc),a0
   clr.b    d1
   bsr      scrollrightleft
*-------------------------
checkrightgad2:
   lea      rperiodgadget2(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkleftgad2
   lea      rperiodgadget2(pc),a0
   moveq    #4,d1
   bsr      scrollrightleft
*----------------------------
checkleftgad2:
   lea      lperiodgadget2(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkrightgad3
   lea      lperiodgadget2(pc),a0
   moveq    #4,d1
   bsr      scrollrightleft
*-------------------------
checkrightgad3:
   lea      rperiodgadget3(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkleftgad3
   lea      rperiodgadget3(pc),a0
   moveq    #8,d1
   bsr      scrollrightleft
*----------------------------
checkleftgad3:
   lea      lperiodgadget3(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    setthestartwave
   lea      lperiodgadget3(pc),a0
   moveq    #8,d1
   bsr      scrollrightleft
*-----------------------------
setthestartwave:
   lea      setstartofw(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq      settheendwave

   lea      startline(pc),a0
   move.w   whichwave,d4
   move.w   whereonwave,d0
   move.w   $a(a0,d4.w),d1
   cmp.w    d0,d1
   ble.s    settheendwave
   move.w   d0,2(a0,d4.w)
   bsr.s    dowavecalc
   move.l   d1,$10(a0,d4.w)
   tst.w    d4
   bne.s    convertstartwave
   lea      startwhtext(pc),a0
   bra      doubledrawr
convertstartwave:
   lea      startwhtext2(pc),a0
   bra      doubledrawr

dowavecalc:
   sub.w    #10,d0
   lea      samplelowa(pc),a0
   move.l   8(a0,d4.w),d1
   sub.l    0(a0,d4.w),d1
   divu     #600,d1
   move.l   d1,-(sp)
   mulu     d0,d1
   move.l   (sp)+,d0
   swap     d0
   tst.w    d0
   beq.s    nodividebyz
   move.l   #600,d2
   move.w   whereonwave,d3
   ext.l    d3
   sub.w    #10,d3
   beq.s    nodividebyz
   divu     d3,d2
   ext.l    d2
   ext.l    d0
   divu     d2,d0
   ext.l    d0
   add.l    d0,d1
nodividebyz:
   add.l    0(a0,d4.w),d1
   rts

settheendwave:
   lea      setendofw(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkwave1
   lea      startline(pc),a0
   move.w   whichwave,d4
   clr.l    d0
   move.w   whereonwave,d0
   move.w   $2(a0,d4.w),d1
   cmp.w    d0,d1
   bge.s    checkwave1
   move.w   d0,$a(a0,d4.w)
   bsr      dowavecalc
   move.l   d1,$18(a0,d4.w)
   tst.w    d4
   bne.s    convertendwave
   lea      endwhtext(pc),a0
   bra.s    doubledrawr
convertendwave:
   lea      endwhtext2(pc),a0
doubledrawr:
   clr.b    d3
   lea      dectable(pc),a1
   moveq    #5,d4
   bsr      convert
   bsr      placemapsamp

checkwave1:
   lea      wave1gadget(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkwave2
   clr.w    whichwave
   bra      refreshwaves
checkwave2:
   lea      wave2gadget(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq      checkzoomin
   move.w   #4,whichwave
refreshwaves:
   btst.b   #6,$bfe001
   beq.s    refreshwaves
startrefwave12:
   lea      wave2gadget(pc),a1
   lea      wave1gadget(pc),a0
   tst.w    whichwave
   bne.s    itswave1
   move.w   #$84,$c(a0)
   bra.s    thatsitwave
itswave1:
   move.w   #$84,$c(a1)
thatsitwave:
   move.l   window,a1
   move.l   #0,a2
   move.l   intuitionbse,a6
   jsr      refreshgadgets(a6)
   lea      wave1gadget(pc),a0
   and.w    #$ff7f,$c(a0)
   lea      wave2gadget(pc),a0
   and.w    #$ff7f,$c(a0)
   tst.w    whichwave
   beq.s    changetextfwave
   lea      startwhtext2(pc),a0
   lea      endwhtext2(pc),a1
   lea      totaltext2(pc),a2
   bra.s    dothatwavechange
changetextfwave:
   lea      startwhtext(pc),a0
   lea      endwhtext(pc),a1
   lea      totaltext(pc),a2
dothatwavechange:
   move.l   a0,startchangewt
   move.l   a1,endchangewt
   move.l   a2,totalchangewt
   bsr      printstartendout
   bsr      placemapsamp

checkzoomin:
   lea      zoomgadget(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkzoomout
waittozoom:
   btst.b   #6,$bfe001
   beq.s    waittozoom
   move.w   whichwave,d4
   lea      startline(pc),a0
   lea      samplelowa(pc),a1
   move.l   8(a1,d4.w),d1
   sub.l    0(a1,d4.w),d1
;   cmp.l    #600,d1
;   ble.s    checkzoomout
   move.w   #10,2(a0,d4.w)
   move.w   #610,$a(a0,d4.w)
   move.l   $18(a1,d4.w),8(a1,d4.w)
   move.l   $10(a1,d4.w),0(a1,d4.w)
   bsr      placemapsamp

checkzoomout:
   lea      zoomoutgadget(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkloop
waittozoomout:
   btst.b   #6,$bfe001
   beq.s    waittozoomout
   move.w   whichwave,d4
   lea      amountoframa(pc),a0
   move.l   0(a0,d4.w),d0
   divu     #600,d0

   lea      startline(pc),a0
   lea      samplelowa(pc),a1
   move.l   $10(a1,d4.w),d1
   divu     d0,d1
   add.l    #10,d1
   move.w   d1,2(a0,d4.w)
   move.l   $18(a1,d4.w),d1
   divu     d0,d1
   add.l    #10,d1
   move.w   d1,$a(a0,d4.w)

   lea      amountoframa(pc),a2
   clr.l    0(a1,d4.w)
   move.l   0(a2,d4.w),8(a1,d4.w)
   bsr      placemapsamp

checkloop:
   lea      loopgadget(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkloop2
waittoloop:
   btst.b   #6,$bfe001
   beq.s    waittoloop
   lea      oncetext(pc),a0
   eor.w    #1,loop1
   tst.w    loop1
   beq.s    noloopchange
   lea      looptext(pc),a0
noloopchange:
   move.l   a0,looptextp
   bsr      printstartendout

checkloop2:
   lea      loopgadget2(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkonoff
waittoloop2:
   btst.b   #6,$bfe001
   beq.s    waittoloop2
   lea      oncetext(pc),a0
   eor.w    #1,loop2
   tst.w    loop2
   beq.s    noloopchange2
   lea      looptext(pc),a0
noloopchange2:
   move.l   a0,looptextp2
   bsr      printstartendout

checkonoff:
   lea      soundonoffg(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkonoff2
waittoonoff:
   btst.b   #6,$bfe001
   beq.s    waittoonoff
   lea      ontext(pc),a0
   eor.w    #1,onoff1
   tst.w    onoff1
   beq.s    noonoffchange
   lea      offtext(pc),a0
noonoffchange:
   move.l   a0,soundonofftp
   bsr      printstartendout

checkonoff2:
   lea      soundonoffg2(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkplay
waittoonoff2:
   btst.b   #6,$bfe001
   beq.s    waittoonoff2
   lea      ontext(pc),a0
   eor.w    #1,onoff2
   tst.w    onoff2
   beq.s    noonoffchange2
   lea      offtext(pc),a0
noonoffchange2:
   move.l   a0,soundonofftp2
   bsr      printstartendout

checkplay:
   lea      playgadget(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq      checkrecord
waittoplay:
   btst.b   #6,$bfe001
   beq.s    waittoplay
   lea      amountoframa(pc),a0
   lea      samplelowa2(pc),a1
   move.w   whichwave,d4
   move.l   8(a0,d4.w),d1
   add.l    0(a1,d4.w),d1
   move.w   #$80,$dff09c            Clear Audio-0 Interrup request
   move.l   d1,$dff0a0              Set the audio start address

   move.l   8(a1,d4.w),d1
   sub.l    0(a1,d4.w),d1
   lsr.l    #1,d1
   move.w   d1,$dff0a4              Set the audio Length
;   move.l   d1,-(sp)

   lea      knobs(pc),a0
   move.l   0(a0,d4.w),a1
   move.w   (a1),d0
   lsr.w    #1,d0
   eor.w    #63,d0
   move.w   d0,$dff0a8              Set the Volume
   move.l   8(a0,d4.w),a1
   move.l   (a1),d0
   move.w   d0,$dff0a6              Set the Period or duration
   move.w   #$8201,$dff096          Enable Audio-0 DMA
;   move.w   #$80,$dff09c
;   move.l   (sp)+,d1
waitforstopsound:
;   btst.b   #6,$bfe001
;   bne.s    waitforstopsound

   move.w   $dff01e,d0              Read in Interrupt request bits
   btst.b   #7,d0                   Is the Audio-0 channel block done!
   beq.s    waitforstopsound        Branch back if not done
;   move.w   #$80,$dff09c
;   dbra     d1,waitforstopsound
   move.w   #$1,$dff096             Disable Audio-0 DMA

;----------------------------------
checkrecord:
   lea      recordgadget(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkmemory
waittorecrd:
   btst.b   #6,$bfe001
   beq.s    waittorecrd
   move.l   sysbase,a6
   jsr      forbid(a6)              forbid all tasks
   move.w   #$4000,intena           disable interrupts
   move.l   readdelay,d1
   move.w   whichwave,d4
   lea      amountoframa(pc),a0
   lea      samplelowa2(pc),a1
   move.l   8(a0,d4.w),a2           start address for storing sound samples
   add.l    0(a1,d4.w),a2
   move.l   8(a0,d4.w),a3           end address
   add.l    8(a1,d4.w),a3
getmysound:
   btst.b   #6,$bfe001
   beq.s    endrecordsound
   move.l   d1,-(sp)
waittorecord:
   dbra     d1,waittorecord
   move.l   (sp)+,d1
waittogetbyte
   btst.b   #0,$bfd000
   bne.s    waittogetbyte
   move.b   $bfe101,d0
   eor.b    #$80,d0
   move.b   d0,(a2)+
   cmp.l    a3,a2
   bne.s    getmysound
endrecordsound:
   move.w   #$c000,intena
   move.l   sysbase,a6
   jsr      permit(a6)
   bsr      placemapsamp

checkmemory:
   lea      memorygadget(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checksave
   bsr      memoryloop
   bra      closewindow2
checksave:
   lea      savegadget(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkload
   bsr      savefile
   bra      closewindow2

checkload:
   lea      loadgadget(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    checkclose
   clr.l    d1
   bsr      loadfile
   bra      closewindow2
checkclose:
   lea      FgadgetS(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq      mainloop

* terminate the program ----------
error6:
   clr.w    whichwave
   bsr      deallocate_memory
   move.w   #$4,whichwave
   bsr      deallocate_memory
error5:
   move.l   window,a0
   move.l   intuitionbse,a6
   jsr      closewindow(a6)
error4:
   move.l   dosbase,a1
   move.l   sysbase,a6
   jsr      closemylib(a6)
error3:
   move.l   gfxbase,a1
   jsr      closemylib(a6)
error2:
   move.l   intuitionbse,a1
   jsr      closemylib(a6)
error:
   clr.l    d0
   movem.l  (sp)+,d1-d7/a0-a6
   rts
* allocate ram for the wave ------- your only alternative is to catch it !!
allocate_wave:
   move.w   whichwave,d4
   lea      amountoframa(pc),a0
   move.l   0(a0,d4.w),d0
   bsr.s    allocate_memory
   beq      no_memory_all
   move.l   d0,d1
   lea      amountoframa(pc),a0
   lea      samplelowa(pc),a1
   move.w   whichwave,d4
   add.l    0(a0,d4.w),d1              get end area
   move.l   d0,8(a0,d4.w)              store start area
   move.l   #0,0(a1,d4.w)
   move.l   #0,$10(a1,d4.w)

   move.l   d1,$10(a0,d4.w)            store end area
   move.l   0(a0,d4.w),8(a1,d4.w)
   move.l   0(a0,d4.w),$18(a1,d4.w)

   lea      startline(pc),a1
   move.w   #10,2(a1,d4.w)
   move.w   #609,$a(a1,d4.w)
   move.l   8(a0,d4.w),a1
   move.l   $10(a0,d4.w),a2
clroutthewave:
   move.b   #$80,(a1)+
   cmp.l    a1,a2
   bne.s    clroutthewave
no_memory_all:
   rts
allocate_examine:
   move.l   #$1000,d0
   bsr.s    allocate_memory
   beq.s    no_memory_all
   move.l   d0,examinearea
   rts
allocate_memory:
   move.l   #MEMF_CHIP+MEMF_CLEAR,d1
   move.l   sysbase,a6
   jsr      allocmemy(a6)
   tst.l    d0
   rts
deallocate_memory:
   lea      amountoframa(pc),a0
   move.w   whichwave,d4
   move.l   0(a0,d4.w),d0
   move.l   8(a0,d4.w),a1
   bra.s    deallocate_ram
deallocate_examine:
   move.l   examinearea,a1
   move.l   #$1000,d0
deallocate_ram:
   move.l   sysbase,a6
   jsr      freememy(a6)
   rts
* convert binary to ascii --------
converttoasc3:
   cmp.b    #8,d1
   bne.s    converttoasc2
   move.w   #4,num_chars3
   lea      lperiodgadget3(pc),a0
   move.w   $c(a0),d0
   and.w    #$80,d0
   beq.s    itgoingright3
   sub.l    #1,readdelay
   tst.l    readdelay
   bpl.s    convertnum3
   move.l   #9999,readdelay
   bra.s    convertnum3
itgoingright3:
   add.l    #1,readdelay
   cmp.l    #9999,readdelay
   blt.s    convertnum3
   clr.l    readdelay
convertnum3:
   lea      readbuffa(pc),a0
   move.l   readdelay,d1
   bra      mainconvert

converttoasc2:
   tst.b    d1
   beq.s    converttoasc
   move.w   #4,num_char_per2
   lea      lperiodgadget2(pc),a0
   move.w   $c(a0),d0
   and.w    #$80,d0
   beq.s    itgoingright2
   sub.l    #1,per2k
   tst.l    per2k
   bpl.s    convertnum2
   move.l   #9999,per2k
   bra.s    convertnum2
itgoingright2:
   add.l    #1,per2k
   cmp.l    #9999,per2k
   blt.s    convertnum2
   clr.l    per2k
convertnum2:
   lea      per2buffa(pc),a0
   move.l   per2k,d1
   bra.s    mainconvert

converttoasc:
   move.w   #4,num_char_per
   lea      lperiodgadget(pc),a0
   move.w   $c(a0),d0
   and.w    #$80,d0
   beq.s    itgoingright
   sub.l    #1,per1k
   tst.l    per1k
   bpl.s    convertnum
   move.l   #9999,per1k
   bra.s    convertnum
itgoingright:
   add.l    #1,per1k
   cmp.l    #9999,per1k
   blt.s    convertnum
   clr.l    per1k
convertnum:
   lea      per1buffa(pc),a0
   move.l   per1k,d1
mainconvert:
   lea      dectable+8(pc),a1
   clr.b    d3
   move.w   #3,d4
convert:
   move.l   (a1)+,d0
   cmp.l    d0,d1
   blt.s    placezero
minusdec:
   sub.l    d0,d1
   bmi.s    placeasc
   addq.b   #1,d3
   bra.s    minusdec
placeasc:
   add.l    d0,d1
placezero:
   add.b    #$30,d3
   move.b   d3,(a0)+
   clr.b    d3
   dbra     d4,convert
   lea      periodtextsh(pc),a1
   bsr      printnameoutrast1
printstartendout:
   lea      startwheretext(pc),a1
   bsr      printnameoutrast1
   rts
* draw a box routine -------------
draw_box:
   move.l   rasterport,a1
   move.l   gfxbase,a6
   moveq    #3,d0
   jsr      setapen(a6)
   moveq    #9,d0
   move.l   #131,d1
   jsr      movepen(a6)
   move.l   #611,d0
   move.l   #131,d1
   jsr      draw(a6)
   move.l   #611,d0
   move.l   #197,d1
   jsr      draw(a6)
   moveq    #9,d0
   move.l   #197,d1
   jsr      draw(a6)
   moveq    #9,d0
   move.l   #131,d1
   jsr      draw(a6)

   moveq    #82,d0
   moveq    #45,d1
   jsr      movepen(a6)
   move.l   #128,d0
   moveq    #45,d1
   jsr      draw(a6)
   move.l   #128,d0
   move.l   #54,d1
   jsr      draw(a6)
   moveq    #82,d0
   moveq    #54,d1
   jsr      draw(a6)
   moveq    #82,d0
   moveq    #45,d1
   jsr      draw(a6)

   moveq    #82,d0
   move.l   #72,d1
   jsr      movepen(a6)
   move.l   #128,d0
   move.l   #72,d1
   jsr      draw(a6)
   move.l   #128,d0
   move.l   #81,d1
   jsr      draw(a6)
   moveq    #82,d0
   move.l   #81,d1
   jsr      draw(a6)
   moveq    #82,d0
   move.l   #72,d1
   jsr      draw(a6)

   moveq    #83,d0
   move.l   #86,d1
   jsr      movepen(a6)
   move.l   #128,d0
   move.l   #86,d1
   jsr      draw(a6)
   move.l   #128,d0
   move.l   #95,d1
   jsr      draw(a6)
   moveq    #83,d0
   move.l   #95,d1
   jsr      draw(a6)
   moveq    #83,d0
   move.l   #86,d1
   jsr      draw(a6)
clearbigwavescrn:
   moveq    #2,d0
   move.l   rasterport,a1
   move.l   gfxbase,a6
   jsr      setapen(a6)
   moveq    #10,d0
   move.l   #132,d1
   move.l   #610,d2
   move.l   #196,d3
   jsr      rectfill(a6)
   rts
* place 30 samples in box --------
placemapsamp:
   bsr      clearbigwavescrn
   movem.l  d0-d7/a0-a6,-(sp)
   move.l   #1,d0
   move.l   rasterport,a1
   move.l   gfxbase,a6
   jsr      setapen(a6)
   moveq    #10,d0
   move.l   #164,d1
   jsr      movepen(a6)

   move.w   whichwave,d4
   lea      amountoframa(pc),a0    ;amountoframa
   move.l   $20(a0,d4.w),d0
   sub.l    $18(a0,d4.w),d0
   cmp.l    #600,d0
   bge.s    dontmake600
   move.l   #600,d0
dontmake600:
   divs     #300,d0                 ;number of bytes to group for one plot
   ext.l    d0
   move.l   $8(a0,d4.w),a1          ;get start address
   move.l   a1,a2
   add.l    $18(a0,d4.w),a1
   add.l    $20(a0,d4.w),a2         ;got end address
   clr.l    d4
   clr.l    d3

s_average_samples:
   move.l   d0,d1                   ;move number of bytes to group for one
   clr.l    d2
averagesamples:
   move.b   (a1)+,d3
   add.l    d3,d2                   ;add all the bytes
   cmp.l    a1,a2
   ble.s    endthisaverage
   subq.l   #1,d1                   ;sub and check amount to grab
   bne.s    averagesamples          ;branch back if not finished getting avg
endthisaverage:
   move.l   d0,d1
   divu     d1,d2
   ext.l    d2
   bsr      plotmapsamples             ;plot the sample
   cmp.w    #600,d4
   ble.s    s_average_samples

noplacemaps:
   lea      startline(pc),a0
   move.w   whichwave,d4
   move.l   rasterport,a1
   move.l   gfxbase,a6
   move.l   #3,d0
   movem.l  d4/a0,-(sp)
   jsr      setapen(a6)
   movem.l  (sp)+,d4/a0
   move.l   0(a0,d4.w),d0
   move.l   #132,d1
   movem.l  d0/d4/a0,-(sp)
   jsr      movepen(a6)
   movem.l  (sp)+,d0/d4/a0
   move.l   #196,d1
   movem.l  d4/a0,-(sp)
   jsr      draw(a6)
   movem.l  (sp)+,d4/a0
   move.l   8(a0,d4.w),d0
   move.l   #132,d1
   movem.l  d0/d4/a0,-(sp)
   jsr      movepen(a6)
   movem.l  (sp)+,d0/d4/a0
   move.l   #196,d1
   jsr      draw(a6)
   movem.l  (sp)+,d0-d7/a0-a6
   rts
plotmapsamples:
   movem.l  d0-d7/a0-a6,-(sp)
   move.l   d4,d0
   add.w    #10,d0
   move.l   d2,d1
   lsr.l    #2,d1
   add.l    #132,d1
   move.l   rasterport,a1
   move.l   gfxbase,a6
   jsr      draw(a6)
   movem.l  (sp)+,d0-d7/a0-a6
   addq.l   #2,d4
   rts
* scroll edit window left --------
;scrollleft:
;   move.l   samplehigh,a0
;   move.l   endsamplea,a2
;   cmp.l    a0,a2
;   beq.s    noscroll
;   moveq    #8,d4                scroll left 8 pix
;   bsr.s    scrollmywind
;   move.l   samplehigh,a0
;   bsr.s    plotasamp
;   add.l    #1,samplehigh
;   add.l    #1,samplelow
;noscroll:
;   rts
;* scroll edit window right -------
;scrollright:
;   move.l   samplelow,a0
;   move.l   startsamplea,a2
;   cmp.l    a0,a2
;   beq.s    noscroll
;   moveq    #-8,d4               scroll right 8 pix
;   bsr.s    scrollmywind
;   sub.l    #1,samplelow
;   sub.l    #1,samplehigh
;   move.l   samplelow,a0
;   bsr.s    plotasamp
;   rts
;* scroll the raster --------------
;scrollmywind:
;   move.l   rasterport,a1
;   move.l   gfxbase,a6
;   moveq    #1,d0
;   jsr      setbpen(a6)
;   move.l   d4,d0
;   moveq    #0,d1
;   move.l   #359,d2
;   moveq    #51,d3
;   move.l   #607,d4
;   move.l   #179,d5
;   jsr      scrollraster(a6)
;   rts
;* plot a sound sample byte -------
;plotasamp:
;   move.b   (a0),d3
;   move.l   rasterport,a1
;   move.l   gfxbase,a6
;   moveq    #3,d0
;   jsr      setapen(a6)
;   move.l   samplelow,a2
;   cmp.l    a0,a2             check what side to draw too
;   bne.s    leftdrawl
;   move.l   #359,d0           right x - coordinates
;   bra.s    topwave
;leftdrawl:
;   move.l   #599,d0           left x - coordinates
;topwave:
;   tst.w    topbottomw        test which way I have to draw
;   bne.s    bottomwave
;   tst.b    d3
;   bmi.s    endplotsamp
;   move.l   #179,d1
;   sub.l    d3,d1
;   move.l   #179,d3
;   move.l   d0,d2
;   addq.l   #8,d2
;   jsr      rectfill(a6)
;   bra.s    endplotsamp
;bottomwave:
;   tst.b    d3
;   bpl.s    endplotsamp
;   and.b    #$7f,d3
;   moveq    #51,d1
;   add.l    d1,d3
;   move.l   d0,d2
;   addq.l   #8,d2
;   jsr      rectfill(a6)
;endplotsamp:
;   rts
* create a little window ---------
makewindow:
   move.l   intuitionbse,a6
   lea      littlewindow(pc),a0
   jsr      openwindow(a6)
   move.l   d0,window2
   bne.s    window2end
   add.l    #4,a7
   bsr      deallocate_examine
   bra      error5
window2end:
   move.l   d0,a0
   move.l   $32(a0),rasterport2
   rts
* close the little window --------
closewindow2:
   move.l   intuitionbse,a6
   move.l   window2,a0
   jsr      closewindow(a6)
   bra      startrefwave12

* get the dir --------------------
getdir:
   clr.w    numofFiles
   clr.w    ncounter
   move.l   dosbase,a6
   lea      dirname(pc),a1
   move.l   a1,d1
   move.l   #access_read,d2
   jsr      lock(a6)
   move.l   d0,loc
   tst.l    d0
   beq      endgetdir
* examine directory ----
   move.l   d0,d1
   move.l   examinearea,d2
   move.l   d2,d3
   add.l    #$200,d3
   move.l   d3,dfilenames
   jsr      examine(a6)
   move.l   examinearea,a0
   move.l   $4(a0),d0               check if its a file
   bmi      unlockdir               branch if not a directory
* get all file names ---
getnextfile:
   move.l   loc,d1
   move.l   examinearea,d2
   jsr      exnext(a6)
   jsr      ioerr(a6)
   cmp.l    #err_no_ent,d0
   beq.s    unlockdir2
   move.l   examinearea,a0
   move.l   $4(a0),d0         check to see if its a directory
   bpl.s    getnextfile       branch if its a directory
* store file names -----
   add.l    #$8,a0            pointer to the file name
   move.l   dfilenames,a1     pointer to ram area of all the file names
   moveq    #29,d0
storefilename:
   move.b   0(a0,d0.w),0(a1,d0.w)
   dbra     d0,storefilename
   add.l    #30,dfilenames
   add.w    #1,numofFiles       ; add 1 to the file counter
   bra.s    getnextfile
unlockdir2:
   lea      lookgads(pc),a0
   clr.l    $2(a0)
   clr.l    $6(a0)
   lea      knobstr6(pc),a0
   move.w   #58,$6(a0)
   move.w   numofFiles,d0
   subq.w   #6,d0
   bmi.s    unlockdir
   moveq    #58,d1
   sub.w    d0,d1
   move.w   d1,6(a0)
unlockdir:
   move.l   loc,d1
   jsr      unlock(a6)
endgetdir:
   rts

* load a requested file in -------
loadfile:
   bsr      allocate_examine
   beq.s    endgetdir
   bsr      getdir
   lea      littlewindname(pc),a0
   lea      loadtext(pc),a1
   move.l   a1,(a0)
   lea      Intloadt(pc),a0
   move.l   a1,$c(a0)
   lea      scrolldwngad(pc),a1
   move.l   a1,littlewgad
   lea      sloffsetprop(pc),a1
   move.l   a1,proggadprop
   bsr      makewindow
   bsr      printoutfiles
   bsr      printdirnfile
   bsr      drawastrg
mainloop2:
   move.l   window2,a0
   btst.b   #6,$bfe001
   bne.s    mainloop2
   clr.l    d0
   clr.l    d1
   move.w   $c(a0),d0        y - coor
   move.w   $e(a0),d1        x - coor
   cmp.w    #240,d1
   bgt      scrollupname
   cmp.w    #4,d1
   blt      scrollupname
   cmp.w    #12,d0
   blt      scrollupname
   cmp.w    #59,d0
   bgt      scrollupname
* refesh dir gadget --------------
   sub.w    #12,d0
   lsr.l    #3,d0             divide by 8
   cmp.w    numofFiles,d0
   bge.s    mainloop2
   add.w    ncounter,d0
   moveq    #30,d2
   mulu     d2,d0
   move.l   examinearea,a0
   add.l    #$200,a0
   add.l    d0,a0
   lea      programname(pc),a1  ;pointer to ram area of all the file names
   moveq    #29,d0
   clr.l    d2
storefilename2:
   move.b   0(a0,d0.w),d1
   move.b   d1,0(a1,d0.w)
   tst.b    d1
   beq.s    storefilencon
   tst.b    d2
   bne.s    storefilencon
   move.l   d0,d2
   addq.l   #1,d2
storefilencon:
   dbra     d0,storefilename2
   lea      proginfoprop(pc),a0
   move.w   d2,$10(a0)
   clr.w    $8(a0)
   clr.w    $c(a0)
   lea      dirgadprop(pc),a0
   move.l   window2,a1
   move.l   #0,a2
   move.l   intuitionbse,a6
   jsr      refreshgadgets(a6)
scrollupname:
   lea      scrollupngad(pc),a0
   move.w   $c(a0),d0
   and.w    #$80,d0
   beq.s    scrolldwname
   move.w   ncounter,d0
   addq.w   #6,d0
   cmp.w    numofFiles,d0
   bge.s    scrolldwname
   add.w    #1,ncounter
   moveq    #30,d1
   mulu     d1,d0
   move.l   examinearea,a0
   add.l    #$200,a0
   add.l    d0,a0
   move.w   #52,printfycoor
   move.l   a0,printftp
   moveq    #8,d1
   bsr.s    scrollmyrast2
   bsr      printfilen
   bra.s    waitfornexts
scrolldwname:
   lea      scrolldwngad(pc),a0
   move.w   $c(a0),d0
   and.w    #$80,d0
   beq.s    checkproplook
   move.w   ncounter,d0
   cmp.w    #0,d0
   beq      mainloop2
   sub.w    #1,ncounter
   sub.w    #1,d0
   move.w   #12,printfycoor
   moveq    #30,d1
   mulu     d1,d0
   move.l   examinearea,a0
   add.l    #$200,a0
   add.l    d0,a0
   move.l   a0,printftp
   moveq    #-8,d1
   bsr.s    scrollmyrast2
   bsr      printfilen
   bra.s    waitfornexts
scrollmyrast2:
   moveq    #0,d0
   moveq    #6,d2
   moveq    #12,d3
   move.l   #239,d4
   moveq    #59,d5
   move.l   gfxbase,a6
   move.l   rasterport2,a1
   jsr      scrollraster(a6)
   rts
waitfornexts:
   move.l   #$ffff,d0
waitforscroll2:
   dbra     d0,waitforscroll2
checkproplook:
   lea      lookfilegad(pc),a0
   move.w   $c(a0),d0
   and.w    #$80,d0
   beq.s    checkdirstr
keepwaitingforok:
   move.w   $c(a0),d0
   and.w    #$80,d0
   bne.s    keepwaitingforok
clrandprint6:
   move.l   rasterport2,a1
   move.l   gfxbase,a6
   moveq    #0,d0
   jsr      setapen(a6)
   moveq    #6,d0
   moveq    #12,d1
   move.l   #239,d2
   moveq    #59,d3
   jsr      rectfill(a6)
   lea      knobstr6(pc),a0
   move.w   $2(a0),ncounter
   bsr      printoutfiles
checkdirstr:
   lea      dirgadprop(pc),a0
   move.w   $c(a0),d0
   and.w    #$80,d0
   beq.s    checklload
waitdirstr:
   move.w   $c(a0),d0
   and.w    #$80,d0
   bne.s    waitdirstr
   bsr      getdir
   move.l   window2,a1
   lea      lookfilegad(pc),a0
   move.l   #0,a2
   move.l   intuitionbse,a6
   jsr      refreshgadgets(a6)
   bra      clrandprint6
checklload:
   lea      loadlgad(pc),a0
   move.w   $c(a0),d0
   and.w    #$80,d0
   beq      checklcancel
   bra      loadtherefile
checklcancel:
   lea      cancelgad(pc),a0
   move.w   $c(a0),d0
   and.w    #$80,d0
   beq      mainloop2
   bsr      deallocate_examine
   rts
* printout the file names --------
printoutfiles:
   move.w   numofFiles,d0
   move.w   #12,printfycoor
   move.w   #5,d1
   move.l   examinearea,a1
   move.w   ncounter,d2
   move.w   #30,d3
   mulu     d3,d2
   add.l    d2,a1
   add.l    #$200,a1
   move.l   a1,printftp
startprintfiles:
   tst.w    d0
   beq.s    nomoreprintf
   subq.w   #1,d0
   movem.l  d0/d1,-(sp)
   bsr.s    printfilen
   add.l    #30,printftp
   add.w    #8,printfycoor
   movem.l  (sp)+,d0/d1
   dbra     d1,startprintfiles
nomoreprintf:
   rts
* print routine --------
printfilen:
   lea      printftext(pc),a1
   move.l   rasterport2,a0
   moveq    #6,d0
   moveq    #0,d1
   move.l   intuitionbse,a6
   jsr      printitext(a6)
   rts
printdirnfile:
   lea      loadoffstext(pc),a1
printdirnfile2:
   move.l   rasterport2,a0
printthatnameout2:
   move.l   #110,d0
   moveq    #61,d1
   move.l   intuitionbse,a6
   jsr      printitext(a6)
   rts
printnameoutrast1:
   move.l   rasterport,a0
   bra.s    printthatnameout2
* save a file --------------------
savefile:
   bsr      allocate_examine
   beq.s    nomoreprintf
   lea      littlewindname(pc),a0
   lea      savetext(pc),a1
   move.l   a1,(a0)
   lea      Intloadt(pc),a0
   move.l   a1,$c(a0)
   lea      cancelgad(pc),a1
   move.l   a1,littlewgad
   lea      startosprop(pc),a1
   move.l   a1,proggadprop
   bsr      makewindow
   lea      dirnametext(pc),a1
   bsr.s    printdirnfile2
   lea      startoffstext(pc),a1
   bsr      printdirnfile2
   bsr      drawjstrg
   bsr      drawjstrg2
mainloop3:
   lea      loadlgad(pc),a0
   move.w   $c(a0),d0
   and.w    #$80,d0
   beq.s    cancel3g
   bra      savetherefile
cancel3g:
   lea      cancelgad(pc),a0
   move.w   $c(a0),d0
   and.w    #$80,d0
   beq      mainloop3
   rts
drawastrg:
   move.l   gfxbase,a6
   move.l   rasterport2,a1
   moveq    #4,d0
   moveq    #11,d1
   jsr      movepen(a6)
   move.l   #241,d0
   moveq    #11,d1
   jsr      draw(a6)
   move.l   #241,d0
   moveq    #60,d1
   jsr      draw(a6)
   moveq    #4,d0
   moveq    #60,d1
   jsr      draw(a6)
   moveq    #4,d0
   moveq    #11,d1
   jsr      draw(a6)
   moveq    #108,d0
   moveq    #103,d1
   jsr      movepen(a6)
   move.l   #177,d0
   moveq    #103,d1
   jsr      draw(a6)
   move.l   #177,d0
   moveq    #112,d1
   jsr      draw(a6)
   moveq    #108,d0
   moveq    #112,d1
   jsr      draw(a6)
   moveq    #108,d0
   moveq    #103,d1
   jsr      draw(a6)
drawjstrg:
   move.l   gfxbase,a6
   move.l   rasterport2,a1
   moveq    #4,d0
   moveq    #68,d1
   jsr      movepen(a6)
   move.l   #241,d0
   moveq    #68,d1
   jsr      draw(a6)
   move.l   #241,d0
   moveq    #77,d1
   jsr      draw(a6)
   moveq    #4,d0
   moveq    #77,d1
   jsr      draw(a6)
   moveq    #4,d0
   moveq    #68,d1
   jsr      draw(a6)
   moveq    #4,d0
   moveq    #85,d1
   jsr      movepen(a6)
   move.l   #241,d0
   moveq    #85,d1
   jsr      draw(a6)
   move.l   #241,d0
   moveq    #94,d1
   jsr      draw(a6)
   moveq    #4,d0
   moveq    #94,d1
   jsr      draw(a6)
   moveq    #4,d0
   moveq    #85,d1
   jsr      draw(a6)
   rts
drawjstrg2:
   moveq    #90,d0
   moveq    #26,d1
   jsr      movepen(a6)
   move.l   #170,d0
   moveq    #26,d1
   jsr      draw(a6)
   move.l   #170,d0
   moveq    #35,d1
   jsr      draw(a6)
   moveq    #90,d0
   moveq    #35,d1
   jsr      draw(a6)
   moveq    #90,d0
   moveq    #26,d1
   jsr      draw(a6)
   moveq    #90,d0
   moveq    #44,d1
   jsr      movepen(a6)
   move.l   #170,d0
   moveq    #44,d1
   jsr      draw(a6)
   move.l   #170,d0
   moveq    #53,d1
   jsr      draw(a6)
   moveq    #90,d0
   moveq    #53,d1
   jsr      draw(a6)
   moveq    #90,d0
   moveq    #44,d1
   jsr      draw(a6)
enddrawingbord
   rts
drawamem:
   move.l   gfxbase,a6
   move.l   rasterport2,a1
   moveq    #83,d0
   moveq    #24,d1
   jsr      movepen(a6)
   move.l   #185,d0
   moveq    #24,d1
   jsr      draw(a6)
   move.l   #185,d0
   moveq    #33,d1
   jsr      draw(a6)
   moveq    #83,d0
   moveq    #33,d1
   jsr      draw(a6)
   moveq    #83,d0
   moveq    #24,d1
   jsr      draw(a6)
   rts
* load that file in ----
loadtherefile:
   lea      sloffinfoprop(pc),a0
   move.l   $1c(a0),d0              get load offset
   lea      amountoframa(pc),a0
   move.w   whichwave,d4
   move.l   $10(a0,d4.w),d3         get end address
   add.l    $8(a0,d4.w),d0          add start address with load offset
   sub.l    d0,d3
   bmi      endloading
   movem.l  d0/d3,-(sp)          store start address
   bsr      getnamesready
   move.l   examinearea,a1
   bsr      openfile
   bne.s    readtherefilein
endloadingrest:
   movem.l  (sp)+,d0/d3
   bra.s    endloading
readtherefilein:
   move.l   d0,d1
   movem.l  (sp)+,d0/d3
   move.l   d1,-(sp)
   move.l   d0,d2
   move.l   dosbase,a6
   jsr      read(a6)
closeoffthefile:
   move.l   (sp)+,d1
   jsr      close(a6)
endloading:
   bsr      deallocate_examine
   rts
* save there dumb file --------------
savetherefile:
   lea      startoinfoprop(pc),a0
   move.l   $1c(a0),d2
   lea      endoinfoprop(pc),a0
   move.l   $1c(a0),d3
   cmp.l    d3,d2
   bgt      endloading
   lea      amountoframa(pc),a0
   move.w   whichwave,d4
   add.l    $8(a0,d4.w),d3
   add.l    $8(a0,d4.w),d2
   move.l   $10(a0,d4.w),d0
   cmp.l    d0,d3
   bgt      endloading
   sub.l    d2,d3
   movem.l  d2/d3,-(sp)
   bsr      getnamesready
   move.l   examinearea,d1
   move.l   #MODE_NEWFILE,d2
   move.l   dosbase,a6
   jsr      open(a6)
   tst.l    d0
   beq      endloadingrest
   movem.l  (sp)+,d2/d3
   move.l   d0,d1
   move.l   d1,-(sp)
   move.l   dosbase,a6
   jsr      write(a6)
   bra      closeoffthefile
* open up a file handle--------
openfile:
   move.l   a1,d1
   move.l   #MODE_OLDFILE,d2
   move.l   dosbase,a6
   jsr      open(a6)
   tst.l    d0
   rts
getnamesready:
   lea      dirname(pc),a1
   move.l   examinearea,a0
dirnameexarea:
   tst.b    (a1)
   beq.s    getprogramnamest
   move.b   (a1),(a0)+
   addq.l   #1,a1
   bra.s    dirnameexarea
getprogramnamest:
   tst.l    d0
   beq.s    endnamefile
   cmp.l    a1,a0
   beq      getprogramnameready
   cmp.b    #':',-1(a0)
   beq.s    getprogramnameready
   move.b   #'/',(a0)+
getprogramnameready:
   clr.l    d0
   lea      programname(pc),a1
   bra.s    dirnameexarea
endnamefile:
   clr.b    (a0)
   rts
* memory allocation routine ------
memoryloop:
   lea      memorytext(pc),a0
   lea      littlewindname(pc),a1
   move.l   a0,(a1)

   lea      loadlgad(pc),a0
   lea      memorytextp,a1
   move.l   a1,$1a(a0)
   lea      memorystrgad(pc),a2
   move.l   a2,(a0)
   lea      cancelgad(pc),a1
   move.l   a1,littlewgad

   bsr      makewindow
   lea      amtofmemtxt(pc),a1
   bsr      printdirnfile2
   bsr      drawamem
mainloop4:
   lea      clrwavegad(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq.s    reversewaver
   move.w   whichwave,d4
   lea      amountoframa(pc),a0
   move.l   8(a0,d4.w),a1
   move.l   $10(a0,d4.w),a2
starttheclrwave:
   move.b   #127,(a1)+
   cmp.l    a1,a2
   bne.s    starttheclrwave
   bra      endmemory4
reversewaver:

checkmemory2:
   lea      loadlgad(pc),a0         ;memory allocate gadget
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq      cancel4
   lea      memoryinfoprop(pc),a0
   move.l   $1c(a0),d1              ;Get the amount of ram
   tst.l    d1
   beq      endmemory4
   move.w   whichwave,d4
   lea      amountoframa(pc),a0
   move.l   0(a0,d4.w),d2           ;deallocate old amount
   movem.l  d1/d4/a0,-(sp)
   bsr      deallocate_memory       ;do it!
   movem.l  (sp)+,d1/d4/a0
   move.l   d1,0(a0,d4.w)
   bsr      allocate_wave           ;allocate new amount
   move.w   whichwave,d4
   lea      startline(pc),a0
   move.l   #10,0(a0,d4.w)
   move.l   #609,8(a0,d4.w)
   lea      amountoframa(pc),a0
   movem.l  d4/a0,-(sp)
   move.l   0(a0,d4.w),d1
   lea      totaltext(pc),a0
   tst.w    d4
   beq.s    gottotallowt
   lea      totaltext2(pc),a0
gottotallowt:
   lea      dectable(pc),a1
   clr.l    d3
   moveq    #5,d4
   bsr      convert
   movem.l  (sp)+,d4/a0
   movem.l  d4/a0,-(sp)
   lea      startwhtext(pc),a0
   tst.w    d4
   beq.s    gotstartlowtl
   lea      startwhtext2(pc),a0
gotstartlowtl:
   moveq    #0,d1
   lea      dectable(pc),a1
   clr.l    d3
   moveq    #5,d4
   bsr      convert
   movem.l  (sp)+,d4/a0
   move.l   0(a0,d4.w),d1
   lea      endwhtext(pc),a0
   tst.w    d4
   beq.s    gotendlowtl
   lea      endwhtext(pc),a0
gotendlowtl:
   lea      dectable(pc),a1
   clr.l    d3
   moveq    #5,d4
   bsr      convert
   bra.s    endmemory4
cancel4:
   lea      cancelgad(pc),a0
   move.w   $c(a0),d1
   and.w    #$80,d1
   beq      mainloop4
endmemory4:
   lea      loadlgad(pc),a0
   lea      Intloadt(pc),a1
   move.l   a1,$1a(a0)
   lea      dirgadprop(pc),a1
   move.l   a1,(a0)
   rts
*---------------------------------
drawpeekmeter:
   moveq    #2,d0
   move.l   rasterport,a1
   move.l   gfxbase,a6
   jsr      setapen(a6)
   clr.l    d1
   move.b   $bfe101,d1
   lsr.w    #2,d1
   move.l   d1,-(sp)
   add.l    #132,d1
   move.l   #616,d0
   move.l   #624,d2
   move.l   #196,d3
   jsr      rectfill(a6)
   move.l   rasterport,a1
   moveq    #3,d0
   jsr      setapen(a6)
   move.l   (sp)+,d1
   eor.b    #$3f,d1
   add.w    #132,d1
   move.l   #616,d0
   move.l   #624,d2
   move.l   #196,d3
   jsr      rectfill(a6)
   move.l   #1000,d0
waittopeekm:
   subq.l   #1,d0
   bne.s    waittopeekm
   rts
*--- data ------------------------
intuitlib      dc.b  'intuition.library',0
gfxbaselib     dc.b  'graphics.library',0
               cnop  0,2
dosbaselib     dc.b  'dos.library',0
               cnop  0,2
mywindow       dc.w  0            set left edge
               dc.w  0            set top edge
               dc.w  640           width
               dc.w  200           height
               dc.b  0             detail pen
               dc.b  1             block pen
               dc.l  0             IDCMPflags
               dc.l  $1204         Flags set depth arangers & close box
               dc.l  FgadgetS      gadgets
               dc.l  0             checkmark
               dc.l  Sean          text,  pointer to the name
               dc.l  0             screen
               dc.l  0             bitmap
               dc.w  0             minwidth
               dc.w  0             minheight
               dc.w  0             maxwidth
               dc.w  0             maxheight
               dc.w  1             type

littlewindow   dc.w  10
               dc.w  15
               dc.w  300
               dc.w  120
               dc.b  0,1      pens
               dc.l  0        IDCMPflags
               dc.l  $1200    Flags
littlewgad     dc.l  0        gadgets
               dc.l  0        checkmark
littlewindname dc.l  0        title name
               dc.l  0        screen
               dc.l  0        bitmap
               dc.w  0        minwidth
               dc.w  0        minheight
               dc.w  0        maxwidth
               dc.w  0        maxheight
               dc.w  1        type

FgadgetS       dc.l  wave1gadget   pointer to next gadget
               dc.w  0
               dc.w  0
               dc.w  31
               dc.w  10
               dc.w  $4          flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  mygimage    gadgerender
               dc.l  0 ;theimag  selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0 ;theimag  userdata

mygimage       dc.w  0
               dc.w  0
               dc.w  31
               dc.w  10
               dc.w  0
               dc.l  theimag
               dc.b  1,0
               dc.l  0

wave1gadget:   dc.l  wave2gadget pointer to next gadget
               dc.w  270
               dc.w  34
               dc.w  64
               dc.w  12
               dc.w  $84          flags
               dc.w  $103        activation
               dc.w  1           gadgetype
               dc.l  wave1image  gadgerender
               dc.l  0           selectrender
               dc.l  wave1textp  IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

wave1image     dc.w  0
               dc.w  0
               dc.w  64
               dc.w  12
               dc.w  0
               dc.l  boximagelc
               dc.b  1,0
               dc.l  0

wave2gadget    dc.l  lperiodgadget pointer to next gadget
               dc.w  270
               dc.w  62
               dc.w  64
               dc.w  12
               dc.w  $4          flags
               dc.w  $103        activation
               dc.w  1           gadgetype
               dc.l  wave2image  gadgerender
               dc.l  0           selectrender
               dc.l  wave2textp  IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

wave2image     dc.w  0
               dc.w  0
               dc.w  64
               dc.w  12
               dc.w  0
               dc.l  boximagelc
               dc.b  1,0
               dc.l  0

               cnop  0,2
theimag        dc.w  $ffff,$ffff
               dc.w  $c000,$0
               dc.w  $c1c0,$0840
               dc.w  $c220,$01f0
               dc.w  $c2a4,$4840
               dc.w  $c264,$4840
               dc.w  $c1e3,$8840
               dc.w  $c000,$0
               dc.w  $eaaa,$aaaa
               dc.w  $ffff,$ffff

               cnop  0,2
lperiodgadget  dc.l  lperiodgadget2 pointer to next gadget
               dc.w  64
               dc.w  45
               dc.w  16
               dc.w  9
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  lefteimage  gadgerender
               dc.l  0           selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

lefteimage     dc.w  0
               dc.w  0
               dc.w  16
               dc.w  9
               dc.w  0
               dc.l  arrowleft
               dc.b  1,0
               dc.l  0

               cnop  0,2
lperiodgadget2 dc.l  lperiodgadget3 pointer to next gadget
               dc.w  64
               dc.w  72
               dc.w  16
               dc.w  9
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  lefteimage2 gadgerender
               dc.l  0           selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

lefteimage2    dc.w  0
               dc.w  0
               dc.w  16
               dc.w  9
               dc.w  0
               dc.l  arrowleft
               dc.b  1,0
               dc.l  0

               cnop  0,2
lperiodgadget3 dc.l  rperiodgadget pointer to next gadget
               dc.w  64
               dc.w  86
               dc.w  16
               dc.w  9
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  lefteimage3 gadgerender
               dc.l  0           selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

lefteimage3    dc.w  0
               dc.w  0
               dc.w  16
               dc.w  9
               dc.w  0
               dc.l  arrowleft
               dc.b  1,0
               dc.l  0

               cnop  0,2
arrowleft      dc.w  $ffff
               dc.w  $c003
               dc.w  $c083
               dc.w  $c3f3
               dc.w  $cff3
               dc.w  $c3f3
               dc.w  $c083
               dc.w  $c003
               dc.w  $ffff

               cnop  0,2
rperiodgadget  dc.l  rperiodgadget2 pointer to next gadget
               dc.w  130
               dc.w  45
               dc.w  16
               dc.w  9
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  righteimage gadgerender
               dc.l  0           selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

righteimage    dc.w  0
               dc.w  0
               dc.w  16
               dc.w  9
               dc.w  0
               dc.l  arrowright
               dc.b  1,0
               dc.l  0

               cnop  0,2
rperiodgadget2 dc.l  rperiodgadget3 pointer to next gadget
               dc.w  130
               dc.w  72
               dc.w  16
               dc.w  9
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  righteimage2 gadgerender
               dc.l  0           selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

righteimage2   dc.w  0
               dc.w  0
               dc.w  16
               dc.w  9
               dc.w  0
               dc.l  arrowright
               dc.b  1,0
               dc.l  0

               cnop  0,2
rperiodgadget3 dc.l  loopgadget  pointer to next gadget
               dc.w  130
               dc.w  86
               dc.w  16
               dc.w  9
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  righteimage3 gadgerender
               dc.l  0           selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

righteimage3   dc.w  0
               dc.w  0
               dc.w  16
               dc.w  9
               dc.w  0
               dc.l  arrowright
               dc.b  1,0
               dc.l  0

               cnop  0,2
arrowright     dc.w  $ffff
               dc.w  $c003
               dc.w  $c103
               dc.w  $cfc3
               dc.w  $cff3
               dc.w  $cfc3
               dc.w  $c103
               dc.w  $c003
               dc.w  $ffff

               cnop  0,2
loopgadget     dc.l  loopgadget2 pointer to next gadget
               dc.w  196
               dc.w  36
               dc.w  16
               dc.w  9
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  loopimage   gadgerender
               dc.l  0           selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

loopimage      dc.w  0
               dc.w  0
               dc.w  16
               dc.w  9
               dc.w  0
               dc.l  arrowright
               dc.b  1,0
               dc.l  0

               cnop  0,2
loopgadget2    dc.l  soundonoffg pointer to next gadget
               dc.w  196
               dc.w  63
               dc.w  16
               dc.w  9
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  loopimage2  gadgerender
               dc.l  0           selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

loopimage2     dc.w  0
               dc.w  0
               dc.w  16
               dc.w  9
               dc.w  0
               dc.l  arrowright
               dc.b  1,0
               dc.l  0

               cnop  0,2
soundonoffg    dc.l  soundonoffg2 pointer to next gadget
               dc.w  196
               dc.w  46
               dc.w  16
               dc.w  9
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  onoffimage  gadgerender
               dc.l  0           selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

onoffimage     dc.w  0
               dc.w  0
               dc.w  16
               dc.w  9
               dc.w  0
               dc.l  arrowright
               dc.b  1,0
               dc.l  0

               cnop  0,2
soundonoffg2   dc.l  zoomgadget  pointer to next gadget
               dc.w  196
               dc.w  73
               dc.w  16
               dc.w  9
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  onoffimage2 gadgerender
               dc.l  0           selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

onoffimage2    dc.w  0
               dc.w  0
               dc.w  16
               dc.w  9
               dc.w  0
               dc.l  arrowright
               dc.b  1,0
               dc.l  0

               cnop  0,2
zoomgadget     dc.l  zoomoutgadget pointer to next gadget
               dc.w  50
               dc.w  120
               dc.w  56          width
               dc.w  8           height
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  zoomimage   gadgerender
               dc.l  0           selectrender
               dc.l  zoomtextp   IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

zoomimage      dc.w  0
               dc.w  0
               dc.w  1
               dc.w  1
               dc.w  0
               dc.l  nothingimage
               dc.b  1,0
               dc.l  0

zoomtextp      dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  0
               dc.w  0
               dc.l  0
               dc.l  zoomtext
               dc.l  0

               cnop  0,2
zoomoutgadget  dc.l  setstartofw pointer to next gadget
               dc.w  38
               dc.w  110
               dc.w  80          width
               dc.w  8           height
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  zoomoutimage gadgerender
               dc.l  0           selectrender
               dc.l  zoomouttextp IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

zoomoutimage   dc.w  0
               dc.w  0
               dc.w  1
               dc.w  1
               dc.w  0
               dc.l  nothingimage
               dc.b  1,0
               dc.l  0

zoomouttextp   dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  0
               dc.w  0
               dc.l  0
               dc.l  zoomouttext
               dc.l  0

nothingimage   dc.l  0
* ---------------------------------
               cnop  0,2
setstartofw    dc.l  setendofw
               dc.w  185
               dc.w  106
               dc.w  16
               dc.w  9
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgettype
               dc.l  setstartgad gadgetrender
               dc.l  0           selectrender
               dc.l  0           IntuitText
               dc.l  0           mutualExclude
               dc.l  0           specialinfo
               dc.w  0           gadget ID
               dc.l  0           userdata

setstartgad    dc.w  0
               dc.w  0
               dc.w  16
               dc.w  9
               dc.w  0
               dc.l  arrowright
               dc.b  1,0
               dc.l  0

setendofw      dc.l  savegadget
               dc.w  185
               dc.w  118
               dc.w  16
               dc.w  9
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgettype
               dc.l  setendgad   gadgetrender
               dc.l  0           selectrender
               dc.l  0           IntuitText
               dc.l  0           mutualExclude
               dc.l  0           specialinfo
               dc.w  0           gadget ID
               dc.l  0           userdata

setendgad      dc.w  0
               dc.w  0
               dc.w  16
               dc.w  9
               dc.w  0
               dc.l  arrowright
               dc.b  1,0
               dc.l  0

               cnop  0,2
savegadget:    dc.l  loadgadget
               dc.w  10             leftedge
               dc.w  15             topedge
               dc.w  64             width
               dc.w  12             height
               dc.w  4              flags
               dc.w  9              activation
               dc.w  1              gadgettype
               dc.l  saveimage      gadgetrender
               dc.l  0              selectrender
               dc.l  savetextp      IntuitText
               dc.l  0              mutualexclude
               dc.l  0              specialinfo
               dc.w  0              gadget ID
               dc.l  0              userdata

saveimage      dc.w  0
               dc.w  0
               dc.w  64
               dc.w  12
               dc.w  0
               dc.l  boximagelc  ;buttonimg
               dc.b  1,0
               dc.l  0

savetextp      dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.w  16          left edge
               dc.w  2           top edge
               dc.l  0           TextAttr
               dc.l  savetext    pointer to the text to print out
               dc.l  0           next text (Intuition Text)
               cnop  0,2

loadgadget:    dc.l  playgadget
               dc.w  75             leftedge
               dc.w  15             topedge
               dc.w  64             width
               dc.w  12             height
               dc.w  4              flags
               dc.w  9              activation
               dc.w  1              gadgettype
               dc.l  loadimage      gadgetrender
               dc.l  0              selectrender
               dc.l  loadtextp      IntuitText
               dc.l  0              mutualexclude
               dc.l  0              specialinfo
               dc.w  0              gadget ID
               dc.l  0              userdata

loadimage      dc.w  0
               dc.w  0
               dc.w  64
               dc.w  12
               dc.w  0
               dc.l  boximagelc ;buttonimg
               dc.b  1,0
               dc.l  0

loadtextp      dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.w  16          left edge
               dc.w  2           top edge
               dc.l  0           TextAttr
               dc.l  loadtext    pointer to the text to print out
               dc.l  0           next text (Intuition Text)
               cnop  0,2

playgadget     dc.l  recordgadget
               dc.w  140            leftedge
               dc.w  15             topedge
               dc.w  64             width
               dc.w  12             height
               dc.w  4              flags
               dc.w  9              activation
               dc.w  1              gadgettype
               dc.l  playimage      gadgetrender
               dc.l  0              selectrender
               dc.l  playtextp      IntuitText
               dc.l  0              mutualexclude
               dc.l  0              specialinfo
               dc.w  0              gadget ID
               dc.l  0              userdata

playimage      dc.w  0
               dc.w  0
               dc.w  64
               dc.w  12
               dc.w  0
               dc.l  boximagelc ;buttonimg
               dc.b  1,0
               dc.l  0

playtextp      dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.w  16          left edge
               dc.w  2           top edge
               dc.l  0           TextAttr
               dc.l  playtext    pointer to the text to print out
               dc.l  0           next text (Intuition Text)
               cnop  0,2

recordgadget   dc.l  memorygadget
               dc.w  205            leftedge
               dc.w  15             topedge
               dc.w  64             width
               dc.w  12             height
               dc.w  4              flags
               dc.w  9              activation
               dc.w  1              gadgettype
               dc.l  recordimage    gadgetrender
               dc.l  0              selectrender
               dc.l  rectextp       IntuitText
               dc.l  0              mutualexclude
               dc.l  0              specialinfo
               dc.w  0              gadget ID
               dc.l  0              userdata

recordimage    dc.w  0
               dc.w  0
               dc.w  64
               dc.w  12
               dc.w  0
               dc.l  boximagelc ;buttonimg
               dc.b  1,0
               dc.l  0

rectextp       dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.w  9           left edge
               dc.w  2           top edge
               dc.l  0           TextAttr
               dc.l  recordtext  pointer to the text to print out
               dc.l  0           next text (Intuition Text)
               cnop  0,2

memorygadget:  dc.l  volgadget
               dc.w  270            leftedge
               dc.w  15             topedge
               dc.w  64             width
               dc.w  12             height
               dc.w  4              flags
               dc.w  9              activation
               dc.w  1              gadgettype
               dc.l  memoryimage    gadgetrender
               dc.l  0              selectrender
               dc.l  memorytextp    IntuitText
               dc.l  0              mutualexclude
               dc.l  0              specialinfo
               dc.w  0              gadget ID
               dc.l  0              userdata

memoryimage    dc.w  0
               dc.w  0
               dc.w  64
               dc.w  12
               dc.w  0
               dc.l  boximagelc
               dc.b  1,0
               dc.l  0

memorytextp    dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.w  9          left edge
               dc.w  2           top edge
               dc.l  0           TextAttr
               dc.l  memorytxt   pointer to the text to print out
               dc.l  0           next text (Intuition Text)
               cnop  0,2

volgadget      dc.l  volgadget2  pointer to next
               dc.w  40          left edge
               dc.w  36          top edge
               dc.w  141         width
               dc.w  8           height
               dc.w  0           flags
               dc.w  0           activation
               dc.w  3           gadgettype
               dc.l  knobstruct  gadgetrender
               dc.l  0           selectrender
               dc.l  voltext     IntuitText
               dc.l  0           mutualExclude
               dc.l  volprop     specialinfo
               dc.w  0           gadget ID
               dc.l  0           userdata

volprop        dc.w  3           flags
               dc.w  1           horizPot
               dc.w  0           vertPot
               dc.w  0           HorizBody
               dc.w  0           VertBody
               dc.w  0           CWidth
               dc.w  0           CHeight
               dc.w  0           HPotRes
               dc.w  0           VPotRes
               dc.w  0           LeftBorder
               dc.w  0           TopBorder

voltext        dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.w  -30         left edge
               dc.w  1           top edge
               dc.l  0           TextAttr
               dc.l  volumet     pointer to the text to print out
               dc.l  0           next text (Intuition Text)
               cnop  0,2

knobstruct     dc.w  100           left edge
               dc.w  0           top edge
               dc.w  16          width
               dc.w  3           height
               dc.w  0           depth
               dc.l  0
               dc.b  1,0         planepick , planeOnOff
               dc.l  0           next image

volgadget2     dc.l  periodgadg1 pointer to next
               dc.w  40          left edge
               dc.w  63          top edge
               dc.w  142         width
               dc.w  8           height
               dc.w  0           flags
               dc.w  0           activation
               dc.w  3           gadgettype
               dc.l  volkstruct  gadgetrender
               dc.l  0           selectrender
               dc.l  voltext     IntuitText
               dc.l  0           mutualExclude
               dc.l  volprop2    specialinfo
               dc.w  0           gadget ID
               dc.l  0           userdata

volprop2       dc.w  3           flags
               dc.w  1           horizPot
               dcb.w  9,0

volkstruct     dc.w  0           left edge
               dc.w  0           top edge
               dc.w  16          width
               dc.w  3           height
               dc.w  0           depth
               dc.l  0
               dc.b  1,0         planepick , planeOnOff
               dc.l  0           next image

periodgadg1    dc.l  periodgadg2 pointer to next gadget
               dc.w  84          left edge
               dc.w  46          top edge
               dc.w  42          width
               dc.w  8           height
               dc.w  0           flags
               dc.w  $801        activation
               dc.w  4           gadettype
               dc.l  0           gadgetrender
               dc.l  0           selectrender
               dc.l  periodtext  IntuitText
               dc.l  0           MutualExclude
               dc.l  period1     SpecialInfo
               dc.w  0           gadget ID
               dc.l  0           user data

period1        dc.l  per1buffa   Buffer
               dc.l  0           undo buffer
               dc.w  0           BufferPos
               dc.w  5           MaxChars
               dc.w  0           DispPos
               dc.w  0           UndoPos
num_char_per   dc.w  0           NumChars
               dc.w  0           DispCount
               dc.w  0           CLeft
               dc.w  0           CTop
               dc.l  0           LayerPtr
per1k          dc.l  400         LongInt
               dc.l  0           AltkeyMap

periodtext     dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.w  -74         left edge
               dc.w  0           top edge
               dc.l  0           TextAttr
               dc.l  periodt1    pointer to the text to print out
               dc.l  0           next text (Intuition Text)
               cnop  0,2

periodtextsh   dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.w  -26         left edge
               dc.w  -15         top edge
               dc.l  0           TextAttr
               dc.l  per1buffa   pointer to the text to print out
               dc.l  periodtextsh2 next text (Intuition Text)
               cnop  0,2

periodgadg2    dc.l  readdelgad  pointer to next gadget
               dc.w  84          left edge
               dc.w  73          top edge
               dc.w  42          width
               dc.w  8           height
               dc.w  0           flags
               dc.w  $801        activation
               dc.w  4           gadettype
               dc.l  0           gadgetrender
               dc.l  0           selectrender
               dc.l  periodtext  IntuitText
               dc.l  0           MutualExclude
               dc.l  period2     SpecialInfo
               dc.w  0           gadget ID
               dc.l  0           user data

period2        dc.l  per2buffa   Buffer
               dc.l  0           undo buffer
               dc.w  0           BufferPos
               dc.w  5           MaxChars
               dc.w  0           DispPos
               dc.w  0           UndoPos
num_char_per2  dc.w  0           NumChars
               dc.w  0           DispCount
               dc.w  0           CLeft
               dc.w  0           CTop
               dc.l  0           LayerPtr
per2k          dc.l  400         LongInt
               dc.l  0           AltkeyMap

periodtextsh2  dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.w  -26         left edge
               dc.w  12          top edge
               dc.l  0           TextAttr
               dc.l  per2buffa   pointer to the text to print out
               dc.l  readtext2   next text (Intuition Text)
               cnop  0,2

*----- read delay gadget --------------------------
readdelgad     dc.l  0           pointer to next gadget
               dc.w  84          left edge
               dc.w  87          top edge
               dc.w  33          width
               dc.w  8           height
               dc.w  0           flags
               dc.w  $801        activation
               dc.w  4           gadettype
               dc.l  0           gadgetrender
               dc.l  0           selectrender
               dc.l  readtext    IntuitText
               dc.l  0           MutualExclude
               dc.l  readdel     SpecialInfo
               dc.w  0           gadget ID
               dc.l  0           user data

readdel        dc.l  readbuffa   Buffer
               dc.l  0           undo buffer
               dc.w  0           BufferPos
               dc.w  5           MaxChars
               dc.w  0           DispPos
               dc.w  0           UndoPos
num_chars3     dc.w  0           NumChars
               dc.w  0           DispCount
               dc.w  0           CLeft
               dc.w  0           CTop
               dc.l  0           LayerPtr
readdelay      dc.l  85          LongInt
               dc.l  0           AltkeyMap

readtext       dc.b  1,0         frontpen,backpen
               dc.b  1,0         drawmode
               dc.w  -18         left edge
               dc.w  10          top edge
               dc.l  0           TextAttr
               dc.l  readdelt    pointer to the text to print out
               dc.l  0           next text (Intuition Text)

readtext2      dc.b  1,0         frontpen,backpen
               dc.b  1,0         drawmode
               dc.w  -26         left edge
               dc.w  26          top edge
               dc.l  0           TextAttr
               dc.l  readbuffa   pointer to the text to print out
               dc.l  0           next text (Intuition Text)
* text --------------------------
               cnop  0,2
recordtext:    dc.b  'Record',0
               cnop  0,2
playtext:      dc.b  'Play',0
               cnop  0,2
loadtext:      dc.b  'Load',0
               cnop  0,2
savetext:      dc.b  'Save',0
               cnop  0,2
oncetext       dc.b  'Once ',0
               cnop  0,2
looptext       dc.b  'Cont.',0
               cnop  0,2
ontext         dc.b  'On ',0
               cnop  0,2
offtext        dc.b  'Off',0
               cnop  0,2
zoomtext:      dc.b  'Zoom In',0
               cnop  0,2
zoomouttext:   dc.b  'Whole Wave',0
               cnop  0,2
Sean:          dc.b  '    Sound Recorder  --  by Sean Godsell',0
               cnop  0,2
volumet:       dc.b  'Vol',0
               cnop  0,2
periodt1:      dc.b  'Period',0
               cnop  0,2
readdelt:      dc.b  'Read Delay',0
               cnop  0,2
drawername:    dc.b  'Drawer',0
               cnop  0,2
filenametext   dc.b  'File Name',0
               cnop  0,2
canceltext     dc.b  'Cancel',0
               cnop  0,2
loadofftext    dc.b  'Load Offset',0
               cnop  0,2
editmtext      dc.b  'Edit',0
               cnop  0,2
startostext    dc.b  'Start Offset',0
               cnop  0,2
endostext      dc.b  'End Offset',0
               cnop  0,2
wave1text      dc.b  'Wave 1',0
               cnop  0,2
wave2text      dc.b  'Wave 2',0
               cnop  0,2
memorytext     dc.b  'Allocate Memory',0
               cnop  0,2
memorytxt      dc.b  'Memory',0
               cnop  0,2
amountmemtext  dc.b  'Amount of memory',0
               cnop  0,2
cleartext      dc.b  'Clear',0
               cnop  0,2

* gadgets for load window -------
scrolldwngad   dc.l  scrollupngad         pointer to next gadget
               dc.w  255           leftedge
               dc.w  12           topedge
               dc.w  31          width
               dc.w  10          height
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  scroldwimage    gadgerender
               dc.l  0           selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

scroldwimage   dc.w  0
               dc.w  0
               dc.w  31
               dc.w  10
               dc.w  0
               dc.l  arrowup
               dc.b  1,0
               dc.l  0

arrowup        dc.w  $ffff,$fffe
               dc.w  $f003,$801e
               dc.w  $f01f,$f01e
               dc.w  $f0ff,$fe1e
               dc.w  $f007,$c01e
               dc.w  $f007,$c01e
               dc.w  $f007,$c01e
               dc.w  $f007,$c01e
               dc.w  $f007,$c01e
               dc.w  $ffff,$fffe

scrollupngad   dc.l  lookfilegad   pointer to next gadget
               dc.w  255           leftedge
               dc.w  88           topedge
               dc.w  31          width
               dc.w  10          height
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  scrolupimage    gadgerender
               dc.l  0           selectrender
               dc.l  0           IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

scrolupimage   dc.w  0
               dc.w  0
               dc.w  31
               dc.w  10
               dc.w  0
               dc.l  arrowdown
               dc.b  1,0
               dc.l  0

arrowdown      dc.w  $ffff,$fffe
               dc.w  $f007,$c01e
               dc.w  $f007,$c01e
               dc.w  $f007,$c01e
               dc.w  $f007,$c01e
               dc.w  $f007,$c01e
               dc.w  $f0ff,$fe1e
               dc.w  $f01f,$f01e
               dc.w  $f003,$801e
               dc.w  $ffff,$fffe

lookfilegad    dc.l  cancelgad   pointer to next gadget
               dc.w  255         left edge
               dc.w  24          top edge
               dc.w  31          width
               dc.w  62          height
               dc.w  3           flags
               dc.w  0           activation
               dc.w  3           gadettype
               dc.l  knobstr6         gadgetrender
               dc.l  0           selectrender
               dc.l  0           IntuitText
               dc.l  0           MutualExclude
               dc.l  lookgads    SpecialInfo
               dc.w  0           gadget ID
               dc.l  0           user data

lookgads       dc.w  4           flags
               dc.w  1           horizPot
               dc.w  1           vertPot
numberoffiles  dc.w  100           HorizBody
               dc.w  100           VertBody
               dc.w  0           CWidth
               dc.w  0           CHeight
               dc.w  0           HPotRes
               dc.w  0           VPotRes
               dc.w  0           LeftBorder
               dc.w  0           TopBorder

knobstr6:      dc.w  0
whereknobl     dc.w  0
               dc.w  23
               dc.w  58
               dc.w  0     depth
               dc.l  lookimage
               dc.b  1,0
               dc.l  0

lookimage      dcb.l 58,$ffffffff

cancelgad      dc.l  loadlgad         pointer to next gadget
               dc.w  224           leftedge
               dc.w  103           topedge
               dc.w  64          width
               dc.w  12          height
               dc.w  4           flags
               dc.w  9           activation
               dc.w  1           gadgetype
               dc.l  cancelimage    gadgerender
               dc.l  0           selectrender
               dc.l  Intcancelt     IntuiText
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

cancelimage    dc.w  0
               dc.w  0
               dc.w  64
               dc.w  12
               dc.w  0
               dc.l  boximagelc
               dc.b  1,0
               dc.l  0

Intcancelt     dc.b  1,0
               dc.b  1,0
               dc.w  9           leftedge
               dc.w  2           topedge
               dc.l  0
               dc.l  canceltext
               dc.l  0

boximagelc     dc.l  $ffffffff,$ffffffff
               dc.l  $c0000000,3
               dc.l  $c0000000,3
               dc.l  $c0000000,3
               dc.l  $c0000000,3
               dc.l  $c0000000,3
               dc.l  $c0000000,3
               dc.l  $c0000000,3
               dc.l  $c0000000,3
               dc.l  $c0000000,3
               dc.l  $c0000000,3
               dc.l  $ffffffff,$ffffffff

loadlgad       dc.l  dirgadprop         pointer to next gadget
               dc.w  10          leftedge     4
               dc.w  103         topedge      6
               dc.w  64          width        8
               dc.w  12          height       a
               dc.w  4           flags        c
               dc.w  9           activation   e
               dc.w  1           gadgetype    10
               dc.l  loadlimage  gadgerender  12
               dc.l  0           selectrender 16
               dc.l  Intloadt    IntuiText    1a
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

loadlimage     dc.w  0
               dc.w  0
               dc.w  64
               dc.w  12
               dc.w  0
               dc.l  boximagelc
               dc.b  1,0
               dc.l  0

Intloadt       dc.b  1,0
               dc.b  1,0
               dc.w  16          leftedge
               dc.w  2           topedge
               dc.l  0
               dc.l  loadtext
               dc.l  0

dirgadprop     dc.l  proggadprop pointer to next gadget
               dc.w  6           left edge
               dc.w  69          top edge
               dc.w  235         width
               dc.w  8           height
               dc.w  0           flags
               dc.w  1           activation
               dc.w  4           gadettype
               dc.l  0           gadgetrender
               dc.l  0           selectrender
               dc.l  0           IntuitText
               dc.l  0           MutualExclude
               dc.l  dirinfoprop SpecialInfo
               dc.w  0           gadget ID
               dc.l  0           user data

dirinfoprop    dc.l  dirname     Buffer
               dc.l  0           undo buffer
               dc.w  0           BufferPos
               dc.w  75          MaxChars
               dc.w  0           DispPos
               dc.w  0           UndoPos
               dc.w  0           NumChars
               dc.w  0           DispCount
               dc.w  0           CLeft
               dc.w  0           CTop
               dc.l  0           LayerPtr
               dc.l  0           LongInt
               dc.l  0           AltkeyMap

proggadprop    dc.l  sloffsetprop pointer to next gadget
               dc.w  6          left edge
               dc.w  86         top edge
               dc.w  235         width
               dc.w  8           height
               dc.w  0           flags
               dc.w  1           activation
               dc.w  4           gadettype
               dc.l  0           gadgetrender
               dc.l  0           selectrender
               dc.l  0           IntuitText
               dc.l  0           MutualExclude
               dc.l  proginfoprop SpecialInfo
               dc.w  0           gadget ID
               dc.l  0           user data

proginfoprop   dc.l  programname Buffer
               dc.l  0           undo buffer
               dc.w  0           BufferPos
               dc.w  39          MaxChars
               dc.w  0           DispPos
               dc.w  0           UndoPos
               dc.w  0           NumChars
               dc.w  0           DispCount
               dc.w  0           CLeft
               dc.w  0           CTop
               dc.l  0           LayerPtr
               dc.l  0           LongInt
               dc.l  0           AltkeyMap

sloffsetprop   dc.l  0           pointer to next gadget
               dc.w  110         left edge
               dc.w  104        top edge
               dc.w  65         width
               dc.w  8           height
               dc.w  0           flags
               dc.w  $c01        activation
               dc.w  4           gadettype
               dc.l  0           gadgetrender
               dc.l  0           selectrender
               dc.l  0           IntuitText
               dc.l  0           MutualExclude
               dc.l  sloffinfoprop SpecialInfo
               dc.w  0           gadget ID
               dc.l  0           user data

sloffinfoprop  dc.l  numbuffsl   Buffer
               dc.l  0           undo buffer
               dc.w  0           BufferPos
               dc.w  8           MaxChars
               dc.w  0           DispPos
               dc.w  0           UndoPos
               dc.w  0           NumChars
               dc.w  0           DispCount
               dc.w  0           CLeft
               dc.w  0           CTop
               dc.l  0           LayerPtr
               dc.l  0           LongInt
               dc.l  0           AltkeyMap

startosprop    dc.l  endosprop   pointer to next gadget
               dc.w  91          left edge
               dc.w  27          top edge
               dc.w  78          width
               dc.w  8           height
               dc.w  0           flags
               dc.w  $c01        activation
               dc.w  4           gadettype
               dc.l  0           gadgetrender
               dc.l  0           selectrender
               dc.l  0           IntuitText
               dc.l  0           MutualExclude
               dc.l  startoinfoprop SpecialInfo
               dc.w  0           gadget ID
               dc.l  0           user data

startoinfoprop dc.l  startbuffa  Buffer
               dc.l  0           undo buffer
               dc.w  0           BufferPos
               dc.w  8           MaxChars
               dc.w  0           DispPos
               dc.w  0           UndoPos
               dc.w  0           NumChars
               dc.w  0           DispCount
               dc.w  0           CLeft
               dc.w  0           CTop
               dc.l  0           LayerPtr
               dc.l  0           LongInt
               dc.l  0           AltkeyMap

endosprop      dc.l  0           pointer to next gadget
               dc.w  91          left edge
               dc.w  45          top edge
               dc.w  78          width
               dc.w  8           height
               dc.w  0           flags
               dc.w  $c01        activation
               dc.w  4           gadettype
               dc.l  0           gadgetrender
               dc.l  0           selectrender
               dc.l  0           IntuitText
               dc.l  0           MutualExclude
               dc.l  endoinfoprop SpecialInfo
               dc.w  0           gadget ID
               dc.l  0           user data

endoinfoprop   dc.l  endbuffa    Buffer
               dc.l  0           undo buffer
               dc.w  0           BufferPos
               dc.w  8           MaxChars
               dc.w  0           DispPos
               dc.w  0           UndoPos
               dc.w  0           NumChars
               dc.w  0           DispCount
               dc.w  0           CLeft
               dc.w  0           CTop
               dc.l  0           LayerPtr
               dc.l  0           LongInt
               dc.l  0           AltkeyMap

memorystrgad:  dc.l  clrwavegad  pointer to next gadget
               dc.w  84          left edge
               dc.w  25          top edge
               dc.w  100         width
               dc.w  8           height
               dc.w  0           flags
               dc.w  $801        activation
               dc.w  4           gadettype
               dc.l  0           gadgetrender
               dc.l  0           selectrender
               dc.l  0           IntuitText
               dc.l  0           MutualExclude
               dc.l  memoryinfoprop SpecialInfo
               dc.w  0           gadget ID
               dc.l  0           user data

memoryinfoprop dc.l  memorybuffa memorybuffa Buffer
               dc.l  0           undo buffer
               dc.w  0           BufferPos
               dc.w  12          MaxChars
               dc.w  0           DispPos
               dc.w  0           UndoPos
               dc.w  0           NumChars
               dc.w  0           DispCount
               dc.w  0           CLeft
               dc.w  0           CTop
               dc.l  0           LayerPtr
               dc.l  60000       LongInt
               dc.l  0           AltkeyMap

clrwavegad:    dc.l  0         pointer to next gadget
               dc.w  95          leftedge     4
               dc.w  60         topedge      6
               dc.w  64          width        8
               dc.w  12          height       a
               dc.w  4           flags        c
               dc.w  9           activation   e
               dc.w  1           gadgetype    10
               dc.l  clrwimage  gadgerender  12
               dc.l  0           selectrender 16
               dc.l  Intclrwt    IntuiText    1a
               dc.l  0
               dc.l  0           specialinfo
               dc.w  0           gadgetID
               dc.l  0           userdata

clrwimage      dc.w  0
               dc.w  0
               dc.w  64
               dc.w  12
               dc.w  0
               dc.l  boximagelc
               dc.b  1,0
               dc.l  0

Intclrwt       dc.b  1,0
               dc.b  1,0
               dc.w  12          leftedge
               dc.w  2           topedge
               dc.l  0
               dc.l  cleartext
               dc.l  0

dirnametext    dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.b  0           filler
               dc.w  0           leftedge
               dc.w  0           topedge
               dc.l  0           text font
               dc.l  drawername  text pointer
               dc.l  prognametext next text

prognametext   dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.b  0           filler
               dc.w  -10         leftedge
               dc.w  17          topedge
               dc.l  0           text font
               dc.l  filenametext text pointer
               dc.l  0           next text

loadoffstext   dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.b  0           filler
               dc.w  -16         leftedge
               dc.w  34          topedge
               dc.l  0           text font
               dc.l  loadofftext text pointer
               dc.l  dirnametext next text

startoffstext  dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  -27
               dc.w  -42
               dc.l  0
               dc.l  startostext
               dc.l  endoffstext

endoffstext    dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  -19
               dc.w  -24
               dc.l  0
               dc.l  endostext
               dc.l  0

wave1textp     dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  6
               dc.w  2
               dc.l  0
               dc.l  wave1text
               dc.l  0

wave2textp     dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  6
               dc.w  2
               dc.l  0
               dc.l  wave2text
               dc.l  0

startwheretext dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  95       leftedge
               dc.w  46       topedge
               dc.l  0
startchangewt  dc.l  startwhtext
               dc.l  endwheretext

endwheretext   dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  95
               dc.w  58
               dc.l  0
endchangewt    dc.l  endwhtext
               dc.l  totalwheretext

totalwheretext dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  95
               dc.w  34
               dc.l  0
totalchangewt  dc.l  totaltext
               dc.l  looptextstr

amtofmemtxt    dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  -40
               dc.w  -46
               dc.l  0
               dc.l  amountmemtext
               dc.l  0

looptextstr    dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  106
               dc.w  -24
               dc.l  0
looptextp      dc.l  oncetext
               dc.l  looptextstr2

looptextstr2   dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  106
               dc.w  3
               dc.l  0
looptextp2     dc.l  oncetext
               dc.l  soundonofftxt

soundonofftxt  dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  106
               dc.w  -14
               dc.l  0
soundonofftp   dc.l  ontext
               dc.l  soundonofftxt2

soundonofftxt2 dc.b  1,0
               dc.b  1
               dc.b  0
               dc.w  106
               dc.w  13
               dc.l  0
soundonofftp2  dc.l  offtext
               dc.l  0

printftext     dc.b  1,0         frontpen,backpen
               dc.b  1           drawmode
               dc.b  0           filler
               dc.w  0          leftedge
printfycoor    dc.w  0          topedge
               dc.l  0           text font
printftp       dc.l  0           text pointer
               dc.l  0           next text

intuitionbse   ds.l  1             \
gfxbase        ds.l  1              \
dosbase        ds.l  1               \
window         ds.l  1                bases & pointers
window2        ds.l  1               /
rasterport     ds.l  1              /
rasterport2    ds.l  1             /

loc            ds.l  1              \
examinearea    ds.l  1               \
dfilenames     ds.l  1                 files
numofFiles     ds.w  1               /
ncounter       ds.w  1              /

amountoframa   dc.l  60000
amountoframb   dc.l  60000
startsamplea   dc.l  0
startsampleb   dc.l  0
endsamplea     dc.l  0
endsampleb     dc.l  0

samplelowa     ds.l  1
samplelowb     ds.l  1
samplehigha    ds.l  1
samplehighb    ds.l  1

samplelowa2    ds.l  1
samplelowb2    ds.l  1
samplehigha2   ds.l  1
samplehighb2   ds.l  1
whichwave      dc.w  0

samplelow      ds.l  1
samplehigh     ds.l  1
whereonwave    dc.w  11

startline      dc.l  10
               dc.l  10
endline        dc.l  610
               dc.l  610

knobs          dc.l  knobstruct
               dc.l  volkstruct
               dc.l  per1k
               dc.l  per2k

dectable       dc.l  100000
               dc.l  10000
               dc.l  1000
               dc.l  100
               dc.l  10
               dc.l  1
loop1          dc.w  0
loop2          dc.w  0
onoff1         dc.w  0
onoff2         dc.w  0

numbuffsl      ds.b  10
dirname        dc.b  'df0:s_samples',0
               ds.b  50
programname    ds.b  40
startbuffa     ds.b  10
memorybuffa    dc.b  '60000'
               ds.b  9
endbuffa       ds.b  10
per1buffa      dc.b  '0400',0,0
per2buffa      dc.b  '0400',0,0
readbuffa      dc.b  '0085',0,0
startwhtext    dc.b  '000000 Start',0
               cnop  0,2
endwhtext      dc.b  '060000 End',0
               cnop  0,2
startwhtext2   dc.b  '000000',0
               cnop  0,2
endwhtext2     dc.b  '060000',0
               cnop  0,2
totaltext      dc.b  '060000 Total',0
               cnop  0,2
totaltext2     dc.b  '060000',0
