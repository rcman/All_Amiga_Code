/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\
* |_o_o|\\ Copyright (c) 1988 The Software Distillery.  All Rights Reserved *
* |. o.| ||          Written by Doug Walker                                 *
* | .  | ||          The Software Distillery                                *
* | o  | ||          235 Trillingham Lane                                   *
* |  . |//           Cary, NC 27513                                         *
* ======             BBS:(919)-471-6436                                     *
\* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "server.h"

void Dispatch(global)
GLOBAL global;
{
   BUG(("Dispatch: Entry\n"))

   /* This must be done each time - do not try to move it to InitDevice */
   global->stdpkt->sp_Pkt.dp_Port = global->n.port;

#if 1
   if(global->RP.RDevice == NULL || global->RP.RDevice == (RPTR)1)
      global->RP.RDevice = (RPTR)global->dosport;
 
   PutMsg((struct MsgPort *)global->RP.RDevice, 
          (struct Message *)global->stdpkt);
#else
   PutMsg(global->dosport, (struct Message *)global->stdpkt);
#endif

   WaitPort(global->n.port);

   GetMsg(global->n.port);

   BUG(("Dispatch: local RC = %lx, %lx\n", 
         global->pkt->dp_Res1, global->pkt->dp_Res2));
   global->RP.Arg1 = global->pkt->dp_Res1;
   global->RP.Arg2 = global->pkt->dp_Res2;

   return;
}