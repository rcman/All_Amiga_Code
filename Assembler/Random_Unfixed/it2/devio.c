/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\
* |_o_o|\\ Copyright (c) 1988 The Software Distillery.  All Rights Reserved *
* |. o.| ||          Written by Doug Walker                                 *
* | .  | ||          The Software Distillery                                *
* | o  | ||          235 Trillingham Lane                                   *
* |  . |//           Cary, NC 27513                                         *
* ======             BBS:(919)-471-6436                                     *
\* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "handler.h"

int RemotePacket(global, nptr)
GLOBAL global;
NETPTR nptr;
{
#if DEBUG
   if(nptr->RDevice == NULL)
   {
      BUGR("Bad NPTR to RPacket")
      BUG(("************ RemotePacket on root! ************\n"));
      return(1);
   }
   else
      BUG(("RemotePacket: RDevice %lx\n", nptr->RDevice));
#endif

#ifndef SMALLPACKET
   global->RP.serverid = nptr->NetNode->id;
   MBSTR(nptr->NetNode->name, global->RP.server);
#endif
   global->RP.RDevice = nptr->RDevice;
   
   if(nptr->NetNode->status == NODE_CRASHED) 
      ReSync(global, nptr->NetNode->ioptr);

   if(nptr->NetNode->status != NODE_UP ||
      PutRPacket(global, nptr->NetNode->ioptr) || 
      GetRPacket(global, nptr->NetNode->ioptr))
   {
      BUG(("RemotePacket: No connection\n"));
      if(nptr->NetNode->status == NODE_UP) global->upnodes--;
      nptr->NetNode->status = NODE_CRASHED;
      global->pkt->dp_Res1 = NULL;
      global->pkt->dp_Res2 = ERROR_NODE_DOWN;
      return(1);
   }
   else
   {
      BUG(("RemotePacket: Received codes %lx, %lx\n", 
         global->RP.Arg1, global->RP.Arg2));
      global->pkt->dp_Res1 = global->RP.Arg1;
      global->pkt->dp_Res2 = global->RP.Arg2;

      /* The other side may have decided to change our RDevice */
      nptr->RDevice = global->RP.RDevice;
      return(0);
   }
}
