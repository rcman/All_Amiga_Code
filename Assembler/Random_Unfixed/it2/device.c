/* Device.c - Device support routines */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1987 The Software Distillery. All Rights Reserved*/
/* |. o.| || This program may not be distributed without the permission of */
/* | .  | || the author.                                           BBS:    */
/* | o  | ||   John Toebes    Dave Baker                     (919)-471-6436*/
/* |  . |//                                                                */
/* ======                                                                  */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "server.h"

int InitDevice(global)
GLOBAL global;
{
   int rc;
   struct StandardPacket *sp;
   BUGP("InitDevice: Entry")
   BUG(("InitDevice: Entry\n"));

   if ((global->n.devport = (struct MsgPort *)CreatePort(NULL,0))==NULL)
   {
      BUG(("********CreatePort Failed\n"));
      BUGR("Can't init server")
      return(1);        /* error in createport */
   }  

   if(!(sp = global->stdpkt = (struct StandardPacket *)
      AllocMem(sizeof(struct StandardPacket),MEMF_CLEAR)))
   {
      BUG(("********Couldn't allocate StandardPacket!!\n"));
      BUGR("No memory!")
      return(1);
   }
   sp->sp_Msg.mn_Node.ln_Name = (char *)(global->pkt= &(sp->sp_Pkt));
   sp->sp_Pkt.dp_Link = &(sp->sp_Msg);

   if(!(global->dosport=(struct MsgPort *)DeviceProc("ROOT:")) &&
      !(global->dosport=(struct MsgPort *)DeviceProc("SYS:")))
   {
      BUG(("********DeviceProc of ROOT: and SYS: Failed\n"));
      BUGR("No DeviceProc")
      return(1);
   }
   global->RP.RDevice = (RPTR)global->dosport;

   OpenTimer(global, global->n.port);

   rc = InitRDevice(global);

   BUGP("InitDevice: Exit")
   return(rc);
}

int TermDevice(global)
GLOBAL global;
{
   CloseTimer(global);
   TermRDevice(global);
   return(1);
}

void RmtDie(global, pkt)
GLOBAL global;
struct DosPacket *pkt;
{
   if(--global->n.run == 1) global->n.run = 0;
}
