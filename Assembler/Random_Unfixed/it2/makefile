#DEBUG  = -dDEBUG=1
DEBUG  =

#LIBS   = lib:lc.lib lib:amiga.lib define _SysBase = _AbsExecBase
LIBS   = lib:lc.lib lib:amiga.lib define _SysBase = 4

#LC1FLAGS = -cwusf -b -d $(DEBUG) -d2
LC1FLAGS =  -cwusf -b -d $(DEBUG) -i/
LC2FLAGS = -v

netdnet-server: netdnet-server.d
   @blink from $+ to $@ nodebug

netser-server: netser-server.d
   @blink from $+ to $@ nodebug

netpar-server: netpar-server.d
   @blink from $+ to $@ nodebug

netsing-server: netsing-server.d
   @blink from $+ to $@ nodebug

netdnet-server.d:  main.o /subs.o file.o dir.o io.o lock.o /sendpkt.o\
       device.o volume.o dispatch.o netdnet.o /iodnet.o /dnetlib.o /debug.o\
       /timer.o /request.o
  @echo >ram:tmp.with "from $+"
  @assign blinkwith:
  @blink with ram:tmp.with SC SD VERBOSE BATCH to $@ lib $(LIBS)\
         map netdnet-server.map hx

netsing-server.d:  main.o /subs.o file.o dir.o io.o lock.o /sendpkt.o\
             device.o volume.o dispatch.o netsing.o iosing.o /debug.o\
             /timer.o /request.o
  @echo >ram:tmp.with "from $+"
  @assign blinkwith:
  @blink with ram:tmp.with SC SD VERBOSE BATCH to $@ lib $(LIBS)

netser-server.d:  main.o /subs.o file.o dir.o io.o lock.o /sendpkt.o\
             device.o volume.o dispatch.o netser.o /ioser.o /debug.o /timer.o\
             /request.o
  @echo >ram:tmp.with "from $+"
  @assign blinkwith:
  @blink with ram:tmp.with SC SD VERBOSE BATCH to $@ lib $(LIBS)

netpar-server.d:  main.o /subs.o file.o dir.o io.o lock.o /sendpkt.o\
             device.o volume.o dispatch.o netpar.o /iopar.o /debug.o /timer.o\
             /request.o
  @echo >ram:tmp.with "from $+"
  @assign blinkwith:
  @blink with ram:tmp.with SC SD VERBOSE BATCH to $@ lib $(LIBS)

main.o : main.c server.h /netcomm.h
 @echo "Compiling $<"
 @lc1 -. $(LC1FLAGS) -oram:temp.q $<
 @lc2 -. $(LC2FLAGS) -y -o$@ ram:temp.q

/dnetlib.o : /dnetlib.c
 @echo "Compiling $<"
 @lc1 -. $(LC1FLAGS) -oram:temp.q $<
 @lc2 -. $(LC2FLAGS) -y -o$@ ram:temp.q
