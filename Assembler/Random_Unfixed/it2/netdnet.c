/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\
* |_o_o|\\ Copyright (c) 1988 The Software Distillery.  All Rights Reserved *
* |. o.| ||          Written by Doug Walker                                 *
* | .  | ||          The Software Distillery                                *
* | o  | ||          235 Trillingham Lane                                   *
* |  . |//           Cary, NC 27513                                         *
* ======             BBS:(919)-471-6436                                     *
\* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "netdnet.h"
#include "server.h"

#if CPR
char *dbgwind = "CON:0/0/640/160/NETDNET-SERVER/a";
#endif

#if 0
int ReSync(global, ioptr)
GLOBAL global;
APTR ioptr;
{
   char c;
   BUG(("ReSync: Entry\n"))

   if(ioptr)
   {
      DEof((struct DChannel *)ioptr);

      if(DRead((struct DChannel *)ioptr, &c, 1) == 1) return(0);
   }
   WaitPort(global->n.d.LisPort);
   if(!(global->n.devptr = (APTR)DAccept(global->n.d.LisPort)) )
   {
      BUG(("Failed\n"))
      return(1);
   }
   BUG(("Succeeded!\n"))
   return(0);
}
#else
int ReSync(global, ioptr)
GLOBAL global;
APTR ioptr;
{
   return(1);
}
#endif

int InitRDevice(global)
GLOBAL global;
{
   BUGP("InitRDevice: Entry")

   global->n.d.LisPort = DListen(PORT_FHANDLER);

   WaitPort(global->n.port);
   ReplyMsg(GetMsg(global->n.port));  /* Tell DNET we are here */

   if(!global->n.d.LisPort)
   {
      BUG(("InitRDevice: Can't init, LisPort %lx\n", global->n.d.LisPort));
      BUGR("Null LisPort");
      return(1);
   }

   /* Wait for a DNET request */
   Wait(1<<global->n.d.LisPort->mp_SigBit);

   if(!(global->n.devptr = (APTR)DAccept(global->n.d.LisPort)))
   {
      BUG(("InitRDevice: Can't DAccept\n"))
      BUGR("No DAccept")
   }

   global->n.histimeout = DNETTIMEOUT;
   global->n.mytimeout  = 0;

   BUGP("InitRDevice: Exit")

   return(0);
}

int TermRDevice(global)
GLOBAL global;
{
   
   if(global->n.d.LisPort)
   {
      DNAAccept(global->n.d.LisPort);
      DUnListen(global->n.d.LisPort);
   }
   DeletePort(global->n.devport);
   return(0);
}

