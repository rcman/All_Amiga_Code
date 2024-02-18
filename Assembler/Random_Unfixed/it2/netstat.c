#include <exec/types.h>
#include <exec/memory.h>
#include <intuition/intuition.h>
#include <graphics/gfxmacros.h>
#include <graphics/rastport.h>
#include <libraries/dos.h>
#include <proto/intuition.h>
#include <proto/dos.h>
#include <proto/exec.h>
#include <proto/graphics.h>
#include <string.h>
#include "netstat.h"

#define MAXSTATS 300
#define XOFF      10
#define YOFF      40
#define TIMEINTERVAL 1
#define YMARGIN   12
#define MINPEAK  400
#define TEXT1   (6*8) 
#define TEXT2   (25*8)
#define XMARGIN   12
#define MKBADDR(x)      ((BPTR)((long)x >> 2))

struct NewWindow NewWindowStructure1 = {
   0,0,
   XOFF+MAXSTATS+XMARGIN, YOFF+YMARGIN+50,
   0,1,
   MENUPICK+CLOSEWINDOW+REFRESHWINDOW+NEWSIZE,
   WINDOWDRAG+WINDOWDEPTH+WINDOWCLOSE+WINDOWSIZING+SIMPLE_REFRESH,
   NULL,
   NULL,
   "Software Distillery NET: Status",
   NULL,
   NULL,
   XOFF+MAXSTATS+XMARGIN,YOFF+YMARGIN+20,
   9999,9999,
   WBENCHSCREEN
};

int xsize = 300;
int ysize = 100;
int yscale = 100;
long peak = 0;

void main(int, char **);
void MemCleanup(void);
void refresh(void);
void QueueTimer(struct timerequest *, ULONG);
void setscale(void);
void update(void);
int dispvals(void);
void DeleteIOReq(struct IOStdReq *);
long sendpkt(struct MsgPort *, long, long*, long);
struct IOStdReq *CreateIOReq(struct MsgPort *, int);

/* Global variables */

struct Window *Window;
struct TmpRas tmpras;
long wstats[MAXSTATS], rstats[MAXSTATS];
int statpos;


void main(argc, argv)
int argc;
char **argv;
{
   WORD areabuffer[300];
   struct IntuiMessage *message;
   int run;
   ULONG portmask, waitmask, windmask, timemask;
/* struct MenuItem *item; */
   struct MsgPort *port;
   struct AreaInfo myAreaInfo;
   struct statmsg *statmsg;
   struct MsgPort *proc;
   long args[8];
   struct timerequest *timerreq;
   struct MsgPort     *timerport;

   timerreq            = NULL;
   timerport           = NULL;
   proc                = NULL;
   Window              = NULL;
   port                = NULL;
   args[0]             = 0;
   if ((IntuitionBase = (struct IntuitionBase *)
 		       OpenLibrary("intuition.library", 0)) == NULL) goto done;
   if ((GfxBase = (struct GfxBase *)
		 OpenLibrary("graphics.library", 0)) == NULL) goto done;
   if ((Window = OpenWindow(&NewWindowStructure1)) == NULL) goto done;

   if ((port = CreatePort("netstat_port", 0)) == NULL) goto done;
   if ((timerport = CreatePort(NULL, 0)) == NULL) goto done;
   if ((timerreq  = (struct timerequest *)
           CreateIOReq(timerport, sizeof(struct timerequest))) == NULL)
 	   goto done;
   if (OpenDevice(TIMERNAME, UNIT_VBLANK, (struct IORequest *)timerreq, 0))
   	   goto done;

   InitArea(&myAreaInfo, areabuffer, 175);
   Window->RPort->AreaInfo = &myAreaInfo;
   Window->RPort->TmpRas = InitTmpRas(&tmpras, AllocRaster(600, 175),
					       RASSIZE(600, 175));
   if ((argc > 1) &&
       ((proc = (struct MsgPort *)DeviceProc(argv[1])) != NULL))
      {
      args[0] = 0x40000002;
      args[1] = MKBADDR(port);
      sendpkt(proc, 2010, args, 2);
      }

   memset((char *)wstats, 0, sizeof(wstats));
   memset((char *)rstats, 0, sizeof(rstats));
   statpos = 0;
   peak = 0;
   ysize = Window->Height-(YOFF+YMARGIN);
   if (ysize < 20) ysize = 20;
   setscale();
   refresh();

   run = 0;

   windmask = 1 << Window->UserPort->mp_SigBit;
   portmask = 1 << port->mp_SigBit;
   timemask = (1 << timerport->mp_SigBit);
   QueueTimer(timerreq, TIMEINTERVAL);
   while(run == 0)
      {
      waitmask = Wait(windmask | portmask | timemask);
      if (waitmask & timemask)
         {
         /* get rid of the message */
         (void)GetMsg(timerport);
         QueueTimer(timerreq, TIMEINTERVAL);
         /* Also, we want to scroll the entire thing left one pixel */
         update();

         statpos ++;
         if (statpos >= MAXSTATS)
            statpos = 0;
         wstats[statpos] = rstats[statpos] = 0;
         }
      if (waitmask & portmask)
         {
         statmsg = (struct statmsg *)GetMsg(port);
         if (statmsg->direction)
            rstats[statpos] += statmsg->count;
         else
            wstats[statpos] += statmsg->count;
         ReplyMsg((struct Message *)statmsg);
         }
      if (waitmask & windmask)
         {
         while ((message = (struct IntuiMessage *)
	                   GetMsg(Window->UserPort)) != NULL)
            {
            switch(message->Class)
               {
               case CLOSEWINDOW:
                  run = -1;
                  break;
#if 0
               case MENUPICK:
	          item = ItemAddress(&MenuList1, message->Code);
                  switch(item->Command)
                     {
                     case 1:
                         run = 1;
                     default:
                         run = 1;
                         break;
                     }
                  break;
#endif

               case NEWSIZE:
               case REFRESHWINDOW:
                  ysize = Window->Height-(YOFF+YMARGIN);
                  if (ysize < 20) ysize = 20;
                  setscale();
                  refresh();
		  break;

               default:
                  break;
               }
            ReplyMsg((struct Message *)message);
            }
         }
      }

   Wait(timemask);

   Window->RPort->TmpRas = NULL;
   FreeRaster(tmpras.RasPtr, 600, 175);

done:
   if (args[0] && proc != NULL)
      {
      args[1] = 0;
      sendpkt(proc,2010,args,2);
      }

   /* Reply to any outstanding messages */
   while(statmsg = (struct statmsg *)GetMsg(port)) 
      ReplyMsg((struct Message *)statmsg);

   if (timerreq != NULL)
      {
      if (timerreq->tr_node.io_Device != NULL)
         {
         AbortIO( (struct IORequest *)timerreq );
         CloseDevice((struct IORequest *)timerreq);
         }
      DeleteIOReq((struct IOStdReq *)timerreq);
      }
  if (timerport != NULL)     DeletePort(timerport);
  if (Window != NULL) CloseWindow(Window);
  if (IntuitionBase != NULL) CloseLibrary((struct Library *)IntuitionBase);
  if (GfxBase != NULL)       CloseLibrary((struct Library *)GfxBase);
  if (port != NULL)          DeletePort(port);
  XCEXIT(0L);
}

void setscale()
{
/* Now recalculate the scale */
if (peak < MINPEAK)
   yscale = MINPEAK/ysize;
else
   yscale = (peak*5)/(ysize*4);

}
int dispvals()
{
char buf[80];
long reads, writes, perf;
struct RastPort *rp = Window->RPort;
static long lr, lw, lp, lk;

reads = rstats[statpos];
writes = wstats[statpos];
perf = reads+writes;

/* Have we hit a new high? */
if (perf > peak)
   {
   peak = perf;
   /* Will this shoot off the end of the graph ? */
   if ((peak/yscale) > ysize)
      {
      setscale();
      return(1);
      }
   }

SetAPen(rp, 0);
if (lp != perf || lr != reads)
   RectFill(rp, XOFF+TEXT1, YOFF-28, XOFF+TEXT1+(7*8), YOFF-1);
if (lk != peak || lw != writes)
   RectFill(rp, XOFF+TEXT2, YOFF-28, XOFF+TEXT2+(7*8), YOFF-1);

lp = perf;
lr = reads;
lk = peak;
lw = writes;

SetAPen(rp, 3);
sprintf(buf, "%7d", perf);
Move(rp, XOFF+TEXT1, YOFF-20);
Text(rp, buf, 7);

sprintf(buf, "%7d", peak);
Move(rp, XOFF+TEXT2, YOFF-20);
Text(rp, buf, 7);

sprintf(buf, "%7d", reads);
Move(rp, XOFF+TEXT1, YOFF-10);
Text(rp, buf, 7);

sprintf(buf, "%7d", writes);
Move(rp, XOFF+TEXT2, YOFF-10);
Text(rp, buf, 7);
return(0);
}

void update()
{
short rsize, wsize;
struct RastPort *rp = Window->RPort;

if (dispvals())
   {
   refresh();
   return;
   }

ScrollRaster(rp, 1, 0, XOFF, YOFF, XOFF+xsize, YOFF+ysize);
/* Now update the data for the one we just finished */
rsize = rstats[statpos]/yscale;
wsize = wstats[statpos]/yscale;
/* Now display the line at the right place for the read and then the write */
Move(rp, XOFF+MAXSTATS, YOFF+ysize);
if (rsize)
   {
   SetAPen(rp, 2);
   Draw(rp, XOFF+MAXSTATS, YOFF+ysize-rsize);
   }
if (wsize)
   {
   SetAPen(rp, 3);
   Draw(rp, XOFF+MAXSTATS, YOFF+ysize-rsize-wsize);
   }
/* And put a point where the limit is */
SetAPen(rp, 1);
WritePixel(rp, XOFF+MAXSTATS, YOFF+ysize-(peak/yscale));
}

void refresh()
{
int i, j;
short rsize, wsize;
struct RastPort *rp = Window->RPort;
char *p;

SetAPen(rp, 0);
RectFill(rp, XOFF, YOFF, XOFF+MAXSTATS+1, YOFF+ysize);

p = "Total:        Bps    Peak:        Bps";
SetAPen(rp, 1);
Move(rp, XOFF, YOFF-20);
Text(rp, p, strlen(p));

p = "Reads:        Bps  Writes:        Bps";
Move(rp, XOFF, YOFF-10);
Text(rp, p, strlen(p));

SetAPen(rp, 3);
p = " � 1989 The Software Distillery";
Move(rp, XOFF, YOFF+ysize+9);
Text(rp, p, strlen(p));
dispvals();

SetAPen(rp, 1);
SetDrMd(rp, JAM1);
Move(rp, XOFF-1, YOFF);
Draw(rp, XOFF-1, YOFF+1+ysize);
Draw(rp, XOFF+1+xsize, YOFF+1+ysize);

i = statpos+1;
for (j = 0; j < MAXSTATS; j++)
   {
   if (i >= MAXSTATS) i = 0;
   rsize = rstats[i]/yscale;
   wsize = wstats[i]/yscale;
   /* Now display the line at the right place for the read and then the write */
   Move(rp, XOFF+j, YOFF+ysize);
   if (rsize)
      {
      SetAPen(rp, 2);
      Draw(rp, XOFF+j, YOFF+ysize-rsize);
      }
   if (wsize)
      {
      SetAPen(rp, 3);
      Draw(rp, XOFF+j, YOFF+ysize-rsize-wsize);
      }
   i++;
   }
SetAPen(rp, 1);
Move(rp, XOFF, YOFF+ysize-(peak/yscale));
Draw(rp, XOFF+MAXSTATS, YOFF+ysize-(peak/yscale));
}

/************************************************************************/
/* Queue a timer to go off in a given number of seconds                 */
/************************************************************************/
void QueueTimer(tr, seconds)
struct timerequest *tr;
ULONG seconds;
{
   tr->tr_node.io_Command = TR_ADDREQUEST;   /* add a new timer request */
   tr->tr_time.tv_secs =  seconds;        	/* seconds */
   tr->tr_time.tv_micro = 0;
   SendIO( (struct IORequest *)tr );
}


struct IOStdReq *CreateIOReq(port, size)
struct MsgPort *port;
int size;
{
   register struct IOStdReq *ioReq;

   if ((ioReq = (struct IOStdReq *)
                AllocMem(size, MEMF_CLEAR | MEMF_PUBLIC)) != NULL)
      {
      ioReq->io_Message.mn_Node.ln_Type = NT_MESSAGE;
      ioReq->io_Message.mn_Node.ln_Pri  = 0;
      ioReq->io_Message.mn_Length       = size;
      ioReq->io_Message.mn_ReplyPort    = port;
      }
   return(ioReq);
}

void DeleteIOReq(ioReq)
register struct IOStdReq *ioReq;
{
   ioReq->io_Message.mn_Node.ln_Type = 0xff;
   ioReq->io_Device = (struct Device *) -1;
   ioReq->io_Unit = (struct Unit *) -1;

   FreeMem( (char *)ioReq, ioReq->io_Message.mn_Length);
}

LONG sendpkt(pid,action,args,nargs)
struct MsgPort *pid;  /* process indentifier ... (handlers message port ) */
LONG action,          /* packet type ... (what you want handler to do )   */
     args[],          /* a pointer to a argument list */
     nargs;           /* number of arguments in list  */
   {
   struct MsgPort        *replyport;
   struct StandardPacket *packet;
 
   LONG  count, *pargs, res1;

   replyport = (struct MsgPort *) CreatePort(NULL,0);
   if(!replyport) return(NULL);

   packet = (struct StandardPacket *) 
      AllocMem((long)sizeof(struct StandardPacket),MEMF_PUBLIC|MEMF_CLEAR);
   if(!packet) 
      {
      DeletePort(replyport);
      return(NULL);
      }

   packet->sp_Msg.mn_Node.ln_Name = (char *)&(packet->sp_Pkt);
   packet->sp_Pkt.dp_Link         = &(packet->sp_Msg);
   packet->sp_Pkt.dp_Port         = replyport;
   packet->sp_Pkt.dp_Type         = action;

   /* copy the args into the packet */
   pargs = &(packet->sp_Pkt.dp_Arg1);       /* address of first argument */
   for(count=0;count < nargs;count++) 
      pargs[count]=args[count];
 
   PutMsg(pid,(struct Message *)packet); /* send packet */

   WaitPort(replyport);
   GetMsg(replyport); 

   res1 = packet->sp_Pkt.dp_Res1;

   FreeMem((char *)packet,(long)sizeof(struct StandardPacket));
   DeletePort(replyport); 

   return(res1);
}

void MemCleanup(){}
