/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1987, 1988 The Software Distillery.  All Rights  */
/* |. o.| || Reserved.  This program may not be distributed without the    */
/* | .  | || permission of the authors:                            BBS:    */
/* | o  | ||   John Toebes     Doug Walker    Dave Baker                   */
/* |  . |//                                                                */
/* ======                                                                  */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Directory Manipulation */
/*  RmtCreateDir RmtExamine RmtExNext RmtParent */
#include "server.h"

void RmtCreateDir(global,pkt)
GLOBAL global;
struct DosPacket *pkt;
/* Arg1 - Lock */
/* Arg2 - name */
/* Arg3 (optional) Attributes */
{
   BUG(("RmtCreateDir\n"));
   BUGBSTR("Creating directory '%s'\n", global->RP.Data);

   pkt->dp_Arg1 = global->RP.Arg1;
   MBSTR(global->RP.Data, global->fib);
   pkt->dp_Arg2 = (LONG)MKBADDR(global->fib);
   pkt->dp_Arg3 = global->RP.Arg3;

   Dispatch(global);

   global->RP.DLen = 0;
}

void RmtExamine(global, pkt)
GLOBAL global;
struct DosPacket *pkt;
/* Arg1: Lock of object to examine */
/* Arg2: FileInfoBlock to fill in */
{
#if DEBUG
   struct FileInfoBlock *fib;
#endif
   BUG(("RmtExamine/RmtExNext - lock %lx\n", global->RP.Arg1));

   pkt->dp_Arg1 = global->RP.Arg1;
   pkt->dp_Arg2 = (LONG)MKBADDR(global->fib);
   MQ(global->RP.Data, global->fib, sizeof(struct FileInfoBlock));

   Dispatch(global);

#if DEBUG
   fib = (struct FileInfoBlock *)global->fib;
   BUG(("RmtEx: FIB name='%s' size=%ld numblocks=%ld\n", 
      fib->fib_FileName+1, fib->fib_Size, fib->fib_NumBlocks));
#endif

   MQ(global->fib, global->RP.Data, sizeof(struct FileInfoBlock));

   global->RP.DLen = sizeof(struct FileInfoBlock);
}

void RmtParent(global,pkt)
GLOBAL global;
struct DosPacket *pkt;
/* Arg1 - Lock */
{
   BUG(("RmtParent\n"));

   pkt->dp_Arg1 = global->RP.Arg1;

   Dispatch(global);

   global->RP.DLen = 0;
}

