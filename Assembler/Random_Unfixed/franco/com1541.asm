* 64-serial bus driver routine
*   BY - Sean Godsell

sysbase     equ   4
IECbus      equ   $bfe101
direction   equ   $bfe301
disable     equ   -120
enable      equ   -126
forbid      equ   -132
permit      equ   -138
write       equ   -48
read        equ   -42
allocmemy   equ   -198
openmylib   equ   -408
open        equ   -30
close       equ   -36
output      equ   -60
input       equ   -54
closemylib  equ   -414
memory      equ   65536+4096
freememy    equ   -210
MEMF_PUBLIC equ   1
MEMF_CLEAR  equ   $10000
lock        equ   -84
unlock      equ   -90
ioerr       equ   -132
examine     equ   -102
exnext      equ   -108
currentdir  equ   -126
deletefile  equ   -72
access_read equ   -2
err_no_ent  equ   232
findtask    equ   -294
pr_CLI      equ   $ac
pr_MsgPort  equ   $5c
WaitPort    equ   -384
GetMsg      equ   -372

   movem.l  d1-d7/a0-a6,-(sp)
*------ Open Dos -----------------
   move.l   sysbase,a6
   lea      dosname(pc),a1
   moveq    #0,d0
   jsr      openmylib(a6)
   move.l   d0,dosbase
   beq      bye_prg

*----- Check if Workbench --------
   move.l   sysbase,a6
   move.l   #0,a1
   jsr      findtask(a6)
   move.l   d0,a4
   tst.l    pr_CLI(a4)
   bne.s    open_my_window

   lea      pr_MsgPort(a4),a0
   move.l   sysbase,a6
   jsr      WaitPort(a6)
   lea      pr_MsgPort(a4),a0
   move.l   sysbase,a6
   jsr      GetMsg(a6)

   clr.l    -(a7)
   move.l   d0,-(a7)
   move.l   #8,workbench
   move.l   d0,a2
   move.l   $24(a2),d0
   beq.s    open_my_window
   move.l   dosbase,a6
   move.l   d0,a0
   move.l   (a0),d1
   jsr      currentdir(a6)

open_my_window:
   move.l   dosbase,a6
   lea      console(pc),a0
   move.l   a0,d1
   move.l   #1005,d2
   jsr      open(a6)
   move.l   d0,conhandle
   beq      close_dos

*------ allocate ram -------------
   move.l   amountofram,d0
   move.l   #MEMF_CLEAR+MEMF_PUBLIC,d1
   move.l   sysbase,a6
   jsr      allocmemy(a6)
   move.l   d0,memoryarea
   beq      close_con
   add.l    #4096,d0
   move.l   d0,dataarea
   move.b   #$38,direction       ;set direction for bus
   bra      print_help_s

getkeyinput
   bsr      printprompt
   bsr      readkeys
   move.w   #7,d0
   lea      commandtab(pc),a0
lookcommands
   move.l   (a0)+,a1             ;command to look at
   move.l   memoryarea,a2        ;key input area
scanline:
   move.b   (a1)+,d1
   beq.s    found_comm
   cmp.b    #65,(a2)
   blt.s    no_make_low
   and.b    #$df,(a2)
no_make_low:
   cmp.b    (a2)+,d1
   beq.s    scanline
   dbra     d0,lookcommands
   bra.s    getkeyinput
found_comm:
   clr.b    (a2)
   clr.l    d1
find_next_arg:
   addq.b   #1,d1
   beq.s    setup_find_end_arg
   cmp.b    #' ',0(a2,d1.w)
   beq.s    find_next_arg
setup_find_end_arg:
   add.l    d1,a2
   move.l   a2,sec_arg
   clr.b    d1
   clr.b    d2
find_end_arg:
   cmp.b    #$a,(a2)
   beq.s    got_the_end_arg
   cmp.b    #'"',(a2)
   bne.s    checkquote2
   tst.b    d1
   bne.s    got_the_end_arg
   moveq    #1,d1
checkquote2:
   tst.b    d1
   bne.s    add_to_line2
   cmp.b    #' ',(a2)
   beq.s    got_the_end_arg
add_to_line2:
   addq.l   #1,a2
   addq.b   #1,d2
   bne.s    find_end_arg
got_the_end_arg:
   move.b   #0,(a2)

*-- check all commands ----------------
   cmp.b    #4,d0             ;check endcli
   beq      endprg

   tst.b    d0                ;check $
   bne.s    no_dir
   move.l   memoryarea,filename
   bsr      getafile
   tst.b    z90
   bne.s    no_dir
   bsr      printdir

no_dir:
   cmp.b    #1,d0             ;check cd
   bne.s    no_one
   move.l   memoryarea,location
   bsr      changedirectory
   clr.w    d0

no_one:
   cmp.b    #3,d0             ;check copy
   bne      no_copy
   addq.l   #1,a2
find_next_arg2:
   cmp.b    #' ',(a2)+
   beq.s    find_next_arg2
   subq.l   #1,a2
   move.l   a2,third_arg
   clr.b    d1
find_end_arg2:
   cmp.b    #$a,(a2)
   beq.s    got_the_end_arg2
   cmp.b    #'"',(a2)
   bne.s    no_quote3
   tst.b    d1
   bne.s    got_the_end_arg2
   moveq    #1,d1
no_quote3:
   tst.b    d1
   bne.s    no_space_pl3
   cmp.b    #' ',(a2)
   beq.s    got_the_end_arg2
no_space_pl3:
   addq.l   #1,a2
   bne.s    find_end_arg2
got_the_end_arg2:
   move.b   #0,(a2)
   move.l   third_arg,a0
   cmp.b    #$33,(a0)
   blt      getkeyinput

*-- from argument ----------------
   move.l   sec_arg,a0
   bsr      check1541
   cmp.b    #':',(a0)
   bne.s    no_load_1541
   cmp.b    #'"',1(a0)
   bne.s    add_two_filename
   add.l    #1,filename
add_two_filename:
   add.l    #2,filename
   bsr      getafile
   tst.b    z90
   bne.s    no_copying
   bra.s    save_third_arg
no_load_1541:
   bsr      readinfile

*-- to argument ------------------
save_third_arg:
   move.l   third_arg,a0
   bsr      check1541
   cmp.b    #':',(a0)
   bne.s    no_save_1541
   cmp.b    #'"',1(a0)
   bne.s    add_two_filename2
   add.l    #1,filename
add_two_filename2:
   add.l    #2,filename
   move.l   filename,a0
   tst.b    (a0)
   beq.s    no_copying
   bsr      saveafile
   bra.s    no_copying
no_save_1541:
   bsr      saveamigafile
no_copying:
   clr.w    d0

no_copy:
   cmp.b    #2,d0             ;check help
   bne.s    no_help
print_help_s:
   lea      titlescreen(pc),a1
   move.l   a1,d2
   move.l   #dirname-titlescreen,d3
   bsr      print
   clr.w    d0

no_help:
   cmp.b    #6,d0             ;check print
   bne.s    no_print

   move.l   sec_arg,a0
   bsr      check1541
   cmp.b    #':',(a0)
   bne.s    no_load_1541_2
   cmp.b    #'"',1(a0)
   bne.s    add_two_filename4
   add.l    #1,filename
add_two_filename4:
   add.l    #2,filename
   bsr      getafile
   tst.b    z90
   bne.s    no_printing
   bra.s    start_the_print
no_load_1541_2:
   bsr      readinfile        *
start_the_print:
   bsr      printfile
no_printing:
   clr.w    d0

no_print:
   cmp.b    #5,d0             ;check list
   bne.s    no_list
   move.l   dataarea,location
   bsr      getdiramiga
   clr.w    d0

no_list:
   cmp.b    #7,d0
   bne.s    anothercomm
   move.l   sec_arg,a0
   bsr      check1541
   cmp.b    #':',(a0)
   bne.s    no_delete_1541
   cmp.b    #'"',1(a0)
   bne.s    no_add1_to_del
   add.l    #1,filename
no_add1_to_del:
   move.l   filename,a0
   move.b   #'S',(a0)
   move.b   #':',1(a0)
   bsr      delete_1541
anothercomm:
   bra      getkeyinput
no_delete_1541:
   move.l   filename,d1
   move.l   dosbase,a6
   jsr      deletefile(a6)
   bra      getkeyinput

*-- check if 1541 ----------------
check1541:
   move.l   a0,filename
   move.b   (a0)+,d0
   cmp.b    #'9',d0
   bgt.s    no_1541_ok
   sub.b    #$30,d0
   move.b   d0,zBA
no_1541_ok:
   rts

* save the stuff -----------------
saveafile:
   bsr      setup_1541_header
   move.b   #$61,zB9
   bsr      Open_file_on_IEC
   tst.b    z90
   bne      error_on_1541
   move.b   zBA,d0
   bsr      Send_Listen
   move.b   zB9,d0
   bsr      Send_ATN
;   tst.b    z90
;   bne      error_on_1541

   move.l   dataarea,a0
   subq.l   #2,a0
   move.w   #$108,(a0)
   move.l   filelength,a1

savebytes_to1541:
   move.l   a1,-(sp)
   move.b   (a0)+,d0
   bsr      IECOUT
   move.l   (sp)+,a1
   cmp.l    a0,a1
   bne.s    savebytes_to1541

   bsr      SEND_UNLISTEN
   bsr      Close_File
error_on_1541:
   rts

* delete a file on 1541 ----------
delete_1541:
   bsr      setup_1541_header
   move.b   #$6f,zB9
   bsr      Open_file_on_IEC
   bsr      Close_File
   rts

* read in stuff ------------------
setup_1541_header:
   move.l   dataarea,location
   move.w   #$5555,z94
   move.w   #$5555,zA3
   move.b   #$60,zB9
   move.b   #0,z90
   move.l   #IECbus,a2
   rts

getafile:
   bsr      setup_1541_header
   bsr      Open_file_on_IEC
   tst.b    z90
   beq.s    no_endprg
   rts
no_endprg:
   move.b   zBA,d0         ;device number
   bsr      Send_Talk
   move.b   zB9,d0
   bsr      Send_Secondary_Address
   move.l   location,a0    ;address to save bytes
   bsr      IECIN
   bsr      IECIN
   btst.b   #1,z90
   beq.s    load_bytes_in
   rts

load_bytes_in:
   move.b   #$fd,d0
   and.b    z90,d0         ;clear time-out bit
   move.b   d0,z90         ;store status
   bsr      IECIN          ;Get_byte_from_IEC- get program byte
   move.b   z90,d1
   lsr.b    #2,d1
   bcs.s    load_bytes_in
   move.b   d4,(a0)+       ;save program byte
   btst.b   #6,z90         ;check status out
   beq.s    load_bytes_in
   move.l   a0,filelength

   bsr      SEND_UNTALK
   bsr      Close_File
   clr.b    z90
   rts

*----- print out the directory ------------
printdir:
   move.l   filelength,a0
   moveq    #0,d0
   bsr      printnumber
   lea      reverse(pc),a1
   bsr      printrev
   move.l   location,d2
   addq.l   #6,d2
   move.l   #25,d3
   bsr      print
   add.l    #26,d2
   lea      noreverse(pc),a1
   bsr      printrev
   bsr      printlf

printmore:
   move.l   d2,a1
   clr.l    d0
   move.w   (a1)+,d0
   ror.w    #8,d0

   cmp.l    a0,a1
   ble.s    keeppdir
   rts
keeppdir:
   bsr      printnumber
   move.l   a1,d2
   bsr      print
   bsr      printlf
   add.l    #30,d2
   bra.s    printmore

* Go back to Amiga Dos --------------------
endprg:
   move.l   amountofram,d0
   move.l   memoryarea,a1
   move.l   sysbase,a6
   jsr      freememy(a6)

close_con:
   move.l   dosbase,a6
   move.l   conhandle,d1
   jsr      close(a6)

close_dos:
   move.l   sysbase,a6
   move.l   dosbase,a1
   jsr      closemylib(a6)

bye_prg:
   add.l    workbench,a7
   movem.l  (sp)+,d1-d7/a0-a6
   clr.l    d0
   rts

* open the file on the IEC-bus (1541) -----
Open_file_on_IEC:
   move.b   zBA,d0            ;device number
   bsr.s    Send_Listen
   move.b   zB9,d0
   or.b     #$f0,d0
   bsr      Send_ATN
   move.l   filename,a0
   move.w   #100,d6
sendmore:
   move.b   (a0)+,d0
   beq.s    endsendc
   cmp.b    #65,d0
   blt.s    no_lower_c
   and.b    #$df,d0
no_lower_c:
   bsr      IECOUT
   dbra     d6,sendmore
endsendc:
   bsr      SEND_UNLISTEN
   rts

*------------------------------------------
Send_Talk:                 ;ED09
   or.b     #$40,d0
   bra.s    talk_listen
*------------------------------------------
Send_Listen:               ;ED0C
   or.b     #$20,d0
talk_listen:
THE_CALL:
   move.l   d0,-(sp)          ;push data
   tst.b    z94
   bpl.s    Ready_byte_out

   ror.w    zA3

   bsr      Out_put_Byte

   ror.w    z94
   ror.w    zA3

Ready_byte_out:
   move.l   (sp)+,d0
   bsr      disableint
   move.w   d0,z95         ;recall & store data
   nop
   nop
   nop
   nop
   bsr      Output_1       ;AND 11011111
   and.b    #$f8,d0
   cmp.b    #$38,d0        ;compare bus-status
   bne.s    No_CLK_high
   bsr      CLK_HIGH       ;AND 11101111
No_CLK_high:
   or.b     #$08,(a2)        ;set ATN
   bsr      time_wait
PREPARE_DRIVE:
   bsr      disableint
   bsr      CLK_LOW        ;OR  00010000
   bsr      Output_1

Wait_one_milli:
   move.w   #$150,d0
Wait_B8:
   sub.w    #1,d0          ;8
   bne.s    Wait_B8        ;10,12

*-------------------------------------------
Out_put_Byte:
   bsr      disableint
   bsr      Output_1       ;AND 11011111
   bsr      Wait_for_bus_change
   bcs      DEVICE_NOT_PRESENT

   bsr      CLK_HIGH       ;AND 11101111
   tst.b    zA3
   bpl.s    Wait_data_clr
Wait_data_0:
   bsr      Wait_for_bus_change
   bcc.s    Wait_data_0
Wait_data_1:
   bsr      Wait_for_bus_change
   bcs.s    Wait_data_1
Wait_data_clr:
   bsr      Wait_for_bus_change
   bcc.s    Wait_data_clr
   bsr      CLK_LOW        ;OR  00010000
   moveq    #$7,d5         ;set bit counter for serial output

Get_another_bit:
   move.b   (a2),d0      ;64-$DD00
   cmp.b    (a2),d0      ;see if buss changed
   bne.s    Get_another_bit
   asl.b    #1,d0
   bsr      time_wait
   bcc      TIME_OUT

   ror.w    z95
   bcs.s    ITS_A_ONE
   bsr      Output_0       ;OR  00100000
   bne.s    STROBE_CLK
ITS_A_ONE:
   bsr      Output_1       ;AND 11011111
STROBE_CLK:
   bsr      CLK_HIGH
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   move.b   (a2),d0
   and.b    #$DF,d0
   or.b     #$10,d0
   move.b   d0,(a2)
   nop
   nop
   nop
   nop
   dbra     d5,Get_another_bit

   move.w   #$1000,d1
go_here_please:
   bsr      Wait_for_bus_change
   bcc.s    all_done_get
   dbra     d1,go_here_please
   bra.s    TIME_OUT
all_done_get:
   bsr      enableint
   rts

*-----------------------------------
DEVICE_NOT_PRESENT:
   move.b   #$80,d0
   bra.s    SET_ST_DEL_CH
TIME_OUT:
   move.b   #$03,d0
SET_ST_DEL_CH:
   bsr      Set_status_routine
   bsr      enableint
   lsr.w    clc
   bcc      GO_ATN_DELAY_CLK

*----------------------------------
;Send secondary address
Send_ATN:
   move.w   d0,z95
   bsr      PREPARE_DRIVE  ;out-put with ATN
SETBACK_ATN:
   move.b   (a2),d0      ;get bus info
   and.b    #$f7,d0        ;set back ATN (11110111)
   move.b   d0,(a2)      ;save bus info
   bsr      time_wait
   rts

*--------------------------
Send_Secondary_Address:
   move.w   d0,z95
   bsr      PREPARE_DRIVE
   bsr      disableint
   bsr      Output_0
   bsr      SETBACK_ATN
   bsr      CLK_HIGH
Wait_data_high:
   bsr      Wait_for_bus_change
   bmi.s    Wait_data_high
   bsr      enableint
   rts

*------------------------------------
IECOUT:           ;output byte on IEC-bus
   move.w   z94,d2
   tst.w    d2
   bmi.s    it_neg_noroll
   ror.w    #1,d2
   bne.s    STORE_DByte
it_neg_noroll:
   movem.l  d0/d2,-(sp)
   bsr      Out_put_Byte
   movem.l  (sp)+,d0/d2
STORE_DByte:
   move.w   d2,z94
   move.w   d0,z95
   lsr.w    clc
   rts

*------------------------------------
SEND_UNTALK:
   bsr      disableint
   bsr      CLK_LOW     ;OR  00010000
   move.b   (a2),d0
   or.b     #$08,d0     ;set ATN
   move.b   d0,(a2)
   bsr      time_wait

   move.b   #$5f,d0
   bra.s    uning_talk_listen

*------------------------------------
SEND_UNLISTEN:
   move.b   #$3f,d0
uning_talk_listen:
   bsr      THE_CALL
GO_ATN_DELAY_CLK:
   bsr      SETBACK_ATN
Wait_CLK_H_out_1:
   move.b   #18,d0
Wait_40_micro_sec:
   sub.b    #1,d0
   bne.s    Wait_40_micro_sec
   bsr      CLK_HIGH    ;AND  11101111
   bra      Output_1    ;AND  11011111

*------------------------------------
IECIN:         ;Get character from IEC-bus
   bsr      disableint
   move.b   #0,d5
   bsr      CLK_HIGH    ;AND  11101111
Keep_waiting:
   bsr      Wait_for_bus_change
   bpl.s    Keep_waiting

do_over:
   bsr      Output_1    ;AND  11011111
   move.w   #$180,d4

CHECKING_TIME:
   sub.w    #1,d4
   beq.s    The_CLK_is_high
   bsr      Wait_for_bus_change
   bmi.s    CHECKING_TIME
   bpl.s    Read_in_Byte

The_CLK_is_high:
   tst.b    d5
   beq.s    not_ready
   move.b   #$02,d0
   bra      SET_ST_DEL_CH

not_ready:
   bsr      Output_0    ;OR   00100000
   bsr      CLK_HIGH    ;AND  11101111
   move.b   #$40,d0     ;EOF
   bsr      Set_status_routine
   add.b    #1,d5
   bra.s    do_over

;----------------------------------
Read_in_Byte:
   move.w   #$07,d6              ;counter for 8 bits
   clr.l    d4
Just_wait_bus:
   move.b   (a2),d0
   cmp.b    (a2),d0
   bne.s    Just_wait_bus
   asl.b    #1,d0
   bpl.s    Just_wait_bus
   roxr.b   #1,d4
still_wait_bus:
   move.b   (a2),d0
   cmp.b    (a2),d0
   bne.s    still_wait_bus
   asl.b    #1,d0
   bmi.s    still_wait_bus
   dbra     d6,Just_wait_bus  ;decrease counter

   bsr      Output_0          ;OR   00100000
   btst.b   #6,z90            ;status
   beq.s    no_EOF
   bsr      Wait_CLK_H_out_1  ;delay,clock-high,output-1
no_EOF:
   bsr      enableint
   lsr.b    clc
   rts

*------------------------------------
CLK_HIGH:         ;serial frequency on
   move.b   (a2),d0      ;get bus info
   and.b    #$ef,d0        ;11101111
   move.b   d0,(a2)      ;save bus info
   bsr      time_wait
   rts

*------------------------------------
CLK_LOW:          ;serial frequency off
   move.b   (a2),d0      ;get bus info
   or.b     #$10,d0        ;00010000
   move.b   d0,(a2)
   bsr      time_wait
   rts

*------------------------------------
Output_1:         ;output a bit '1'
   move.b   (a2),d0
   and.b    #$df,d0        ;11011111
   move.b   d0,(a2)
   bsr      time_wait
   rts

*------------------------------------
Output_0:
   move.b   (a2),d0
   or.b     #$20,d0
   move.b   d0,(a2)
   bsr      time_wait
   rts

*------------------------------------
Wait_for_bus_change:
   move.b   (a2),d0
   cmp.b    (a2),d0
   bne.s    Wait_for_bus_change
   asl.b    #1,d0
   bsr      time_wait
   rts

*-------------------------------
Get_status:
   move.b   z90,d0
Set_status_routine:
   or.b     z90,d0
   move.b   d0,z90
   rts

*--------------------------------
enableint:
   move.w   #$c000,$dff09a
   rts

*--------------------------------
disableint:
   move.w   #$4000,$dff09a
   rts

*--------------------------------
Close_File:
   move.b   zBA,d0
   bsr      Send_Listen
   move.b   zB9,d0
   and.b    #$ef,d0
   or.b     #$e0,d0
   bsr      Send_ATN
   bsr      SEND_UNLISTEN
   rts

*--- print the number out -------
; D0.l=number to print out
printnumber:
   movem.l  d0-d7/a0-a6,-(sp)
   lea      dectable(pc),a0
   lea      charbuff(pc),a1
   move.l   a1,d2
   move.w   #$5,d4
   clr.b    d3
   clr.b    d6
   tst.l    d0
   bne.s    convert
   clr.w    d4
   bra.s    printzero0

convert:
   clr.b    d3
   move.l   (a0)+,d1
   cmp.l    d1,d0
   blt.s    printzero
minusdec:
   sub.l    d1,d0
   bmi.s    printasc
   addq.b   #1,d3
   bra.s    minusdec
printasc:
   add.l    d1,d0
   moveq    #1,d6
printzero:
   tst.b    d6
   beq.s    dontprint
printzero0:
   add.b    #$30,d3
   move.b   d3,charbuff
   moveq    #1,d3
   bsr      print
dontprint:
   dbra     d4,convert
   move.b   #$20,charbuff
   bsr      print
   movem.l  (sp)+,d0-d7/a0-a6
   rts

*--- print in reverse -----------
printrev:
   movem.l  d2/d3,-(sp)
   move.l   #8,d3
   move.l   a1,d2
   bsr      print
   movem.l  (sp)+,d2/d3
   rts

*--------------------------------
printprompt:
   movem.l  d0-d3/a0-a3,-(sp)
   move.w   #'> ',charbuff
   lea      charbuff(pc),a1
   bra.s    print2
printlf:
   movem.l  d0-d3/a0-a3,-(sp)
   lea      crlf(pc),a1
print2:
   move.l   #2,d3
   move.l   a1,d2
   bra.s    print_it
printmultspc:
   movem.l  d0-d3/a0-a3,-(sp)
   lea      spaces(pc),a0
   move.l   a0,d2
   bra.s    print_it
print:
   movem.l  d0-d3/a0-a3,-(sp)
print_it:
   move.l   conhandle,d1
   move.l   dosbase,a6
   jsr      write(a6)
   movem.l  (sp)+,d0-d3/a0-a3
   rts

*--------------------------------
readkeys:
   move.l   conhandle,d1
   move.l   memoryarea,d2
   move.l   #255,d3
   move.l   dosbase,a6
   jsr      read(a6)
   move.b   d0,zB7      ;length read in
   move.l   memoryarea,a0
   add.w    d0,a0
   moveq    #8,d0
nullkeyline:
   move.b   #0,(a0)+
   dbra     d0,nullkeyline
   rts

*--------------------------------
time_wait:
   nop
   nop
   nop
   nop   ;
   nop
   nop
   nop
   nop   ;
   nop
   nop
   nop
   rts

*------------------------------
;print the file that is in the buffer
printfile:
   bsr      setup_1541_header
   move.b   #$4,zBA
   move.l   filename,a0
   clr.b    (a0)
   bsr      Open_file_on_IEC

   tst.b    z90
   bne      error_on_printer
   move.b   zBA,d0
   bsr      Send_Listen
   move.b   zB9,d0
   bsr      Send_ATN
;   tst.b    z90
;   bne      error_on_printer

   move.l   dataarea,a0
   move.l   filelength,a1
printbytes_to_printer:
   move.w   #2000,d0
waittoprint:
   subq.w   #1,d0
   bne.s    waittoprint
   move.l   a1,-(sp)
   move.b   (a0)+,d0
   bsr      IECOUT
   move.l   (sp)+,a1
   cmp.l    a0,a1
   bne.s    printbytes_to_printer

   bsr      SEND_UNLISTEN
   bsr      Close_File
error_on_printer:
   rts


   rts

*------------------------------
getdiramiga:
   lea      ramer(pc),a0
   move.l   a0,d1
   bsr      no_ram_dev

   moveq    #0,d1
   move.l   sec_arg,a0
   move.l   location,$60000
   cmp.b    #$33,(a0)
   ble.s    no_sec_arg_dir
   move.l   a0,d1
no_sec_arg_dir:
no_ram_dev:
   bsr      getlock_exam
   bmi      printjust1file

* get all file names ----------
getnextfile:
   move.l   loc,d1
   move.l   location,d2
   jsr      exnext(a6)
   jsr      ioerr(a6)
   cmp.l    #err_no_ent,d0
   beq.s    unlockdir2
   move.l   location,a0
   move.l   dfilenames,a1
* store file names ------------
   moveq    #37,d0
storefilename:
   move.b   0(a0,d0.w),0(a1,d0.w)
   dbra     d0,storefilename
   move.l   $7c(a0),(a1)
   add.l    #38,dfilenames
   add.w    #1,numofFiles
   bra.s    getnextfile

printjust1file:
   move.l   location,a0
   move.l   $7c(a0),(a0)
   moveq    #1,d0
   bra.s    printfilenames

unlockdir2:
   move.w   numofFiles,d0
   tst.w    d0
   beq      unlockdir

no_file_top:
   move.l   location,a0
   add.l    #$200,a0
printfilenames:
   add.l    #8,a0
   clr.l    d1
lookfornullfn:
   tst.b    0(a0,d1.w)
   beq.s    gotnullname
   addq.w   #1,d1
   bra.s    lookfornullfn
gotnullname:
   move.l   a0,d2
   move.l   d1,d3
   bsr      print
   moveq    #30,d3
   sub.w    d1,d3
   bsr      printmultspc
   tst.w    -2(a0)
   bmi.s    its_a_file
   lea      dirname(pc),a1
   move.l   a1,d2
   moveq    #5,d3
   bsr      print
   bra.s    do_a_lfcr
its_a_file:
   move.l   d0,-(sp)
   move.l   -8(a0),d0
   bsr      printnumber
   move.l   (sp)+,d0
do_a_lfcr:
   bsr      printlf
   add.l    #30,a0
   subq.w   #1,d0
   bne      printfilenames

unlockdir:
   move.l   loc,d1
   jsr      unlock(a6)
   rts

*------------------------------
getlock_exam:
   clr.w    numofFiles
   clr.w    ncounter
   move.l   dosbase,a6
   move.l   #access_read,d2
   jsr      lock(a6)
   move.l   d0,loc
   beq.s    endgetdir
* examine directory -----------
   move.l   d0,d1
   move.l   location,d2
   move.l   d2,a0
   clr.l    (a0)
   clr.l    4(a0)
   clr.l    8(a0)
   move.l   d2,d3
   add.l    #$200,d3
   move.l   d3,dfilenames
   jsr      examine(a6)
   tst.l    d0
   bne.s    found_something
   bsr      unlockdir
   bra.s    endgetdir
found_something:
   move.l   location,a0
   tst.l    $4(a0)
   rts
endgetdir:
   add.l    #4,a7
   rts

* -- change directory comm ----
changedirectory:
   move.l   sec_arg,a0
   move.l   a0,d1
   cmp.b    #$33,(a0)
   bgt.s    change_dir
   rts
change_dir:
   bsr      getlock_exam
   bmi      unlockdir
   move.l   loc,d1
   jsr      currentdir(a6)
   move.l   d0,d1
   jsr      unlock(a6)
   rts

*-- read in an amiga file -----
readinfile:
   move.l   filename,d1
   move.l   #1005,d2
   move.l   dosbase,a6
   jsr      open(a6)
   move.l   d0,loc
   beq.s    no_read_amiga_f

   move.l   d0,d1
   move.l   dataarea,d2
   move.l   #65536,d3
   move.l   dosbase,a6
   jsr      read(a6)
   move.l   dataarea,d1
   tst.l    d0
   bne.s    no_end_reach
   add.l    #$65536,d1
   bra.s    close_read
no_end_reach:
   add.l    d0,d1
close_read:
   move.l   d1,filelength

   move.l   loc,d1
   jsr      close(a6)
no_read_amiga_f:
   rts

*-- save buffer to the amiga --
saveamigafile:
   tst.l    filelength
   beq.s    no_save_amiga_f
   move.l   filename,d1
   move.l   #1006,d2
   move.l   dosbase,a6
   jsr      open(a6)
   move.l   d0,loc
   beq.s    no_save_amiga_f

   move.l   d0,d1
   move.l   dataarea,d2
   move.l   filelength,d3
   sub.l    dataarea,d3
   move.l   dosbase,a6
   jsr      write(a6)

   move.l   loc,d1
   jsr      close(a6)
no_save_amiga_f:
   rts

* -- data ---------------------
starttext
dosname     dc.b  'dos.library',0
            cnop  0,2
console     dc.b  'CON:80/40/450/124/COMMODORE 1541 - File Manager.',0
            cnop  0,2
titlescreen dc.b  '   Created by - Sean Godsell',$a,$d
            dc.b  '-------------------------------',$a,$d
            dc.b  '$      - dir 1541          CD     - change dir',$a,$d
            dc.b  'LIST   - Amiga files       ENDCLI - exit program',$A,$D
            dc.b  'HELP   - display this menu',$a,$d
            dc.b  'PRINT  - this will print files to the IECbus (dev #4)'
            dc.b  $a,$d
            dc.b  'DELETE - files on amiga or 1541. eg: delete 9:name',$a,$d
            dc.b  'COPY   - files from amiga to 1541 or visversa',$A,$D
            dc.b  '    eg:   copy 8:1541name amiganame',$a,$d
            dc.b  '       - this will copy a file from the 1541',$a,$d
            dc.b  '         (device #8) to the Amiga',$a,$d
            dc.b  $a
            cnop  0,2
dirname     dc.b  '-Dir-'
            cnop  0,2
ramer       dc.b  'ram:',$a,0
spaces      dcb.b 30,32
crlf        dc.b  $a,$d
reverse     dc.b  27,$9b,'34;41m'
noreverse   dc.b  27,'[m',0,0,0,0,0
endtext

dosbase     dc.l  0
amountofram dc.l  memory
memoryarea  dc.l  0        ;zBB
conhandle   dc.l  0
workbench   dc.l  0
charbuff    dc.b  0,0
dataarea    dc.l  0
location    dc.l  0
filelength  dc.l  0
filename    dc.l  0
loc         dc.l  0
sec_arg     dc.l  0
third_arg   dc.l  0
numofFiles  dc.w  0
ncounter    dc.w  0
dfilenames  dc.l  0

dectable    dc.l  100000
            dc.l  10000
            dc.l  1000
            dc.l  100
            dc.l  10
            dc.l  1

z90         dc.b  00       ;status flags        (90)
            cnop  0,2
z94         dc.w  $5555    ;Serial bus-output b (94) ;aa
z95         dc.w  $ff
zA3         dc.w  $5555
zB7         dc.b  1        ;filelength
zB9         dc.b  $60      ;second address
zBA         dc.b  8        ;device number
            cnop  0,2
clc         dc.w  0

commandtab  dc.l  deletec     ;7
            dc.l  printc      ;6
            dc.l  listamiga   ;5
            dc.l  endclic     ;4
            dc.l  copyc       ;3
            dc.l  helpc       ;2
            dc.l  cddir       ;1
            dc.l  dir1541     ;0

dir1541     dc.b  '$',0
listamiga   dc.b  'LIST',0
endclic     dc.b  'ENDCLI',0
copyc       dc.b  'COPY',0
cddir       dc.b  'CD',0
printc      dc.b  'PRINT',0
helpc       dc.b  'HELP',0
deletec     dc.b  'DELETE',0
            end

