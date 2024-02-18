/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1987 The Software Distillery.  All Rights Reserved */
/* |. o.| || This program may not be distributed without the permission of   */
/* | .  | || the authors:                                          BBS:      */
/* | o  | ||   John Toebes     Dave Baker                                    */
/* |  . |//                                                                  */
/* ======                                                                    */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Volume Manipulation */
/* RmtCurentVol  RmtRenameDisk RmtDiskInfo RmtInfo */

#include "server.h"

void RmtInfo(global, pkt)
GLOBAL global;
struct DosPacket *pkt;
{
   BUG(("RmtInfo\n"));

   if(!global->infodata &&
      !(global->infodata = (struct InfoData *)
             DosAllocMem(global, sizeof(struct InfoData))))
   {
      BUG(("******* OUT OF MEMORY - can't get InfoData\n"));
      global->RP.Arg1 = DOS_FALSE;
      global->RP.Arg2 = ERROR_NO_FREE_STORE;
      return;
   }
   pkt->dp_Arg1 = global->RP.Arg1;
   pkt->dp_Arg2 = (LONG)global->infodata;

   Dispatch(global);

   MQ(global->infodata, global->RP.Data, sizeof(struct InfoData));

   global->RP.DLen = sizeof(struct InfoData);
}

void RmtNetKludge(global, pkt)
GLOBAL global;
struct DosPacket *pkt;
{
   struct MsgPort *newport;

   if(!(newport=(struct MsgPort *)DeviceProc(global->RP.Data)))
   {
      BUG(("********DeviceProc of %s Failed\n", global->RP.Data));
      BUGGETC
      pkt->dp_Res1 = DOS_FALSE;
      pkt->dp_Res2 = ERROR_OBJECT_NOT_FOUND;
      return;
   }
   global->RP.RDevice = (RPTR)(global->dosport = newport);
   pkt->dp_Res1 = DOS_TRUE;
   pkt->dp_Res2 = 0L;

   global->n.run++;

   BUG(("RmtNetKludge: New RDevice %lx\n", newport));
}

