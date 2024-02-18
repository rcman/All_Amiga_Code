/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1987, 1988 The Software Distillery.  All Rights  */
/* |. o.| || Reserved.  This program may not be distributed without the    */
/* | .  | || permission of the authors:                            BBS:    */
/* | o  | ||   John Toebes     Doug Walker    Dave Baker                   */
/* |  . |//                                                                */
/* ======                                                                  */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/* Lock.c - lock manipulation */
/* RmtLock, RmtDupLock, RmtUnLock */

/*-------------------------------------------------------------------------*/
/* Structure of a Lock:                                                    */
/*   struct FileLock {                                                     */
/*      BPTR fl_Link;             Next lock in the chain of device locks   */
/*      LONG fl_Key;              Block number of directory or file header */
/*      LONG fl_Access;           Shared Read (-2) or Exclusive Write (-1) */
/*      struct MsgPort * fl_Task; Handler process for Lock (Us)            */
/*      BPTR fl_Volume;           Node in DevInfo structure for Lock       */
/*      };                                                                 */
/*-------------------------------------------------------------------------*/
#include "server.h"

void RmtLock(global, pkt)
GLOBAL global;
struct DosPacket *pkt;
{
   BUG(("RmtLock: lock %lx\n", global->RP.Arg1));
   BUGBSTR("Locking filename = ", global->RP.Data);

   pkt->dp_Arg1 = global->RP.Arg1;
   MBSTR(global->RP.Data, global->fib);
   pkt->dp_Arg2 = (LONG)MKBADDR(global->fib);
   pkt->dp_Arg3 = global->RP.Arg3;        /* Mode             */

   Dispatch(global);

   global->RP.DLen = 0;
}

void RmtDupLock(global, pkt)
GLOBAL global;
struct DosPacket *pkt;
{
   BUG(("RmtDupLock\n"));
   pkt->dp_Arg1 = global->RP.Arg1;

   Dispatch(global);

   global->RP.DLen = 0;
}

void RmtUnLock(global, pkt)
GLOBAL global;
struct DosPacket *pkt;
{
   BUG(("RmtUnLock\n"));
   pkt->dp_Arg1 = global->RP.Arg1;

   Dispatch(global);

   global->RP.DLen = 0;
}
