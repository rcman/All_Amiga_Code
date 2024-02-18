/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1987, 1988 The Software Distillery.  All Rights  */
/* |. o.| || Reserved.  This program may not be distributed without the    */
/* | .  | || permission of the authors:                            BBS:    */
/* | o  | ||   John Toebes     Doug Walker    Dave Baker                   */
/* |  . |//                                                                */
/* ======                                                                  */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* File Manipulation  */
/*  ActDelete ActRename ActSetProtection ActSetComment */
#include "server.h"

void RmtDelete(global, pkt)
GLOBAL global;
struct DosPacket *pkt;              /* a pointer to the dos packet sent   */
/* Arg1: Lock	*/
/* Arg2: Name	*/
{
   BUG(("RmtDelete, lock %lx\n", global->RP.Arg1));
   BUGBSTR("File to delete is ", global->RP.Data);

   pkt->dp_Arg1 = global->RP.Arg1;
   MBSTR(global->RP.Data, global->fib);
   pkt->dp_Arg2 = (LONG)MKBADDR(global->fib);

   Dispatch(global);

   global->RP.DLen = 0;
}

void RmtRename(global,pkt)
GLOBAL global;
struct DosPacket *pkt;
/* Arg1: FromLock	*/
/* Arg2: FromName	*/
/* Arg3: ToLock		*/
/* Arg4: ToName		*/
{
   char *name;
   BUG(("RmtRename\n"));
   BUGBSTR("Renaming ", global->RP.Data);
   BUGBSTR("New Name ", global->RP.Data+FILENAMELEN);

   pkt->dp_Arg1 = global->RP.Arg1;
   MBSTR(global->RP.Data, global->fib);
   pkt->dp_Arg2 = (LONG)MKBADDR(global->fib);
   pkt->dp_Arg3 = global->RP.Arg3;
   name = ((char *)global->fib)+FILENAMELEN;
   MBSTR(global->RP.Data+FILENAMELEN, name);
   pkt->dp_Arg4 = (LONG)MKBADDR(name);

   Dispatch(global);

   global->RP.DLen = 0;
}

void RmtSetProtection(global, pkt)
GLOBAL global;
struct DosPacket *pkt;
/* Arg1: Unused */
/* Arg2: Lock */
/* Arg3: Name */
/* Arg4: Mask of protection */
{
   BUG(("RmtSetProtection\n"));

   BUGBSTR("File to protect: ", global->RP.Data);

   pkt->dp_Arg2 = global->RP.Arg2;
   MBSTR(global->RP.Data, global->fib);
   pkt->dp_Arg3 = (LONG)MKBADDR(global->fib);
   pkt->dp_Arg4 = global->RP.Arg4;

   Dispatch(global);

   global->RP.DLen = 0;
}

void RmtSetComment(global,pkt)
GLOBAL global;
struct DosPacket *pkt;              /* a pointer to the dos packet sent       */
/* Arg1: Unused */
/* Arg2: Lock */
/* Arg3: Name */
/* Arg4: Comment */
{
   char *comment;
   BUG(("RmtSetComment\n"));

   BUGBSTR("File to Comment: ", global->RP.Data);
   BUGBSTR("New Comment Str: ", global->RP.Data+FILENAMELEN);

   pkt->dp_Arg2 = global->RP.Arg2;
   MBSTR(global->RP.Data, global->fib);
   pkt->dp_Arg3 = (LONG)MKBADDR(global->fib);
   comment = ((char *)global->fib)+FILENAMELEN;
   MBSTR(global->RP.Data+FILENAMELEN, comment);
   pkt->dp_Arg4 = (LONG)MKBADDR(comment);

   Dispatch(global);

   global->RP.DLen = 0;
}
