#include <exec/types.h>
#include <exec/memory.h>
#include <exec/nodes.h>
#include <exec/lists.h>
#include <exec/ports.h>
#include <libraries/dos.h>
#include <libraries/dosextens.h>
#include <libraries/filehandler.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <proto/exec.h>
#include <proto/dos.h>

#undef GLOBAL
/* my version of BADDR() has no problems with casting */
#undef  BADDR
#define BADDR(x)        ((APTR)((long)x << 2))
#define MKBADDR(x)      ((BPTR)((long)x >> 2))

#define ACTION_HANDLER_DEBUG    2010L
#define DEBUG_SPECIAL 0x40000000
#define DEBUG_WAIT    0x40000001
#define DEBUG_SERVER  0x20000000
#define DEBUG_SERVWT  0x10000000

char windowname[50] = "CON:0/1/640/160/Debug ";

LONG sendpkt(struct MsgPort *, long, long*, long, long*);

void main(argc, argv)
int argc;
char **argv;
{
   struct MsgPort *proc;
   long myargs[8];
   long myres[2];
   char *filename, *cmdname, *devname;
   int freeflag, server, handler;

   cmdname = argv[0];
   if(argc != 3 && argc != 4 && argc != 5)
   {
USAGE:
      fprintf(stderr, 
         "Usage: %s device <SERVER|BOTH> [OPEN|CLOSE|WAIT] <logfile>\n",
         cmdname);
      return;
   }
   devname = argv[1];

   if ((proc = (struct MsgPort *)DeviceProc(devname)) == NULL)
   {
      fprintf(stderr, "Unable to get a device proc for %s\n", devname);
      goto USAGE;
   }

   handler = 0;
   if((server=(!stricmp(argv[2], "SERVER"))) ||
      (server=handler=(!stricmp(argv[2], "BOTH"))))
   {
      if(argc < 4) goto USAGE;
      argc--, argv++;
   }
   else
      handler = 1;

   if(!stricmp(argv[2], "WAIT"))
   {
      freeflag = 0;
      myargs[0] = DEBUG_WAIT;
   }
   else if(!stricmp(argv[2], "CLOSE"))
   {
      freeflag = 1;
      myargs[0] = 0;
   }
   else if(!stricmp(argv[2], "OPEN"))
   {
      freeflag = 1;
      myargs[0] = 1;
      if(handler)
      {
         if(argc == 4) filename = argv[3];
         else
         {
            strcat(windowname, devname);
            strcat(windowname, "/a");
            filename = windowname;
         }
         if(!(myargs[1] = (long)Open(filename, 1006)))
         {
            fprintf(stderr, "Can't open output %s '%s'\n",
               (argc == 4 ? "file" : "window"), filename);
            goto USAGE;
         }
      }
   }
   else
   {
      fprintf(stderr, "Unknown debugging command '%s'\n", argv[2]);
      goto USAGE;
   }

   if(handler)
   {
      sendpkt(proc,ACTION_HANDLER_DEBUG,myargs,2,myres);
      if(freeflag && myres[0] != 0 && myres[1])
         Close((BPTR)myres[1]);
   }

   if(server)
   {
      myargs[0] |= (DEBUG_SERVER|DEBUG_SPECIAL);
      sendpkt(proc,ACTION_HANDLER_DEBUG,myargs,2,myres);
   }

}

LONG sendpkt(pid,action,args,nargs,res)
struct MsgPort *pid;  /* process indentifier ... (handlers message port ) */
LONG action,          /* packet type ... (what you want handler to do )   */
     args[],          /* a pointer to a argument list           */
     nargs,           /* number of arguments in list            */
     res[];           /* pointer to 2 longs for result, or NULL */
   {
   struct MsgPort        *replyport;
   struct StandardPacket *packet;
 
   LONG  count, lres, *pargs;

   replyport = (struct MsgPort *) CreatePort(NULL,0);
   if(!replyport) return(0L);

   packet = (struct StandardPacket *) 
      AllocMem((long)sizeof(struct StandardPacket),MEMF_PUBLIC|MEMF_CLEAR);
   if(!packet) 
      {
      DeletePort(replyport);
      return(0L);
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

   if(res)
   {
      lres = res[0] = packet->sp_Pkt.dp_Res1;
      res[1] = packet->sp_Pkt.dp_Res2;
   }

   FreeMem((char *)packet,(long)sizeof(struct StandardPacket));
   DeletePort(replyport); 

   return(lres);
}
