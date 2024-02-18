/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1987, 1988 The Software Distillery.  All Rights  */
/* |. o.| || Reserved.  This program may not be distributed without the    */
/* | .  | || permission of the authors:                            BBS:    */
/* | o  | ||   John Toebes     Doug Walker    Dave Baker                   */
/* |  . |//                                                                */
/* ======                                                                  */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Process Control */

/* ActDie ActInhibit ActFlush ActTimer */
#include "handler.h"

void ActDie(global, pkt)
GLOBAL global;
struct DosPacket *pkt;              /* a pointer to the dos packet sent       */
{
   struct NetNode *netnode;
   BUG(("ActDie\n"));
   global->n.run = 0;
   global->RP.Type = pkt->dp_Type;

   for(netnode=global->netchain.next; netnode; netnode=netnode->next)
   {
      if(netnode->status == NODE_UP && netnode->RootLock.RDevice)
      {
         BUGBSTR("Shutting down node ", netnode->name);
         RemotePacket(global, &netnode->RootLock);
         netnode->status = NODE_DEAD;
      }
   }
}

void ActInhibit(global, pkt)
GLOBAL global;
struct DosPacket *pkt;              /* a pointer to the dos packet sent       */
{
   BUG(("ActInhibit: %ld\n", pkt->dp_Arg1));
   pkt->dp_Res1 = DOS_TRUE;
   if(pkt->dp_Arg1 == 0)
   {
      /* Since the DISKCHANGE command uses ACTION_INHIBIT instead of */
      /* ACTION_DISK_CHANGE, do a ACTION_DISK_CHANGE just in case    */
      ActDiskChange(global, pkt);
   }
}

void ActFlush(global, pkt)
GLOBAL global;
struct DosPacket *pkt;
{
   BUG(("ActFlush\n"));
}

#if 0
void ActTimer(global, pkt)
GLOBAL global;
struct DosPacket *pkt;        /* a pointer to the dos packet sent */
{
   BUG(("ActTimer\n"));

   if (global->run == -1)
      global->run = 0;
   else
      PostTimerReq(global);

   /* Prevent them from replying to the message */
   global->reply = 0;
}
#endif
