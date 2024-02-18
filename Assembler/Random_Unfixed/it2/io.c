/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1987, 1988 The Software Distillery.  All Rights  */
/* |. o.| || Reserved.  This program may not be distributed without the    */
/* | .  | || permission of the authors:                            BBS:    */
/* | o  | ||   John Toebes     Doug Walker    Dave Baker                   */
/* |  . |//                                                                */
/* ======                                                                  */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* File Access:            */
/* RmtRead RmtWrite RmtSeek RmtWaitForChar    */
/* RmtFindwrite RmtFindin RmtFindout RmtEnd   */

#include "server.h"

static long CurrentPos U_ARGS((GLOBAL, struct DosPacket *));

static long CurrentPos(global, pkt)
GLOBAL global;
struct DosPacket *pkt;
{
   pkt->dp_Type = ACTION_SEEK;
   pkt->dp_Arg1 = ((struct FileHandle *)global->RP.Arg1)->fh_Arg1;
   pkt->dp_Arg2 = 0L;
   pkt->dp_Arg3 = OFFSET_CURRENT;
   Dispatch(global);
   return(pkt->dp_Res1);
}

/*-------------------------------------------------------------------------*/
/*                                                                         */
/*                 RmtRead( global, pkt )                                  */
/*                                                                         */
/*-------------------------------------------------------------------------*/

void RmtRead(global,pkt)
GLOBAL global;
struct DosPacket *pkt;
/* Arg1: APTR EFileHandle */
/* Arg2: APTR Buffer      */
/* Arg3: Length           */
{
   long toread, amount, total, offset;

   BUG(("RmtRead of %d bytes\n", global->RP.Arg3));

   /* 1. Seek 0 to get current position in file
    * 2. Dispatch read (max NETBUFSIZE bytes)
    * 3. If error, seek back to original pos
    * 4. Reply to other side
    * 5. If more to read, go back to (2)
    */
   if((offset = CurrentPos(global, pkt))<0)
   {
      BUG(("RmtRead: Seek failed, code %d\n", pkt->dp_Res2));
      global->RP.Arg1 = pkt->dp_Res1;
      global->RP.Arg2 = pkt->dp_Res2;
      return;
   }

   BUG(("RmtRead: Seek done, position is %d\n", offset));

   /* Arg1 was set by the CurrentPos function to be the filehandle */
   pkt->dp_Type = ACTION_READ;
   pkt->dp_Arg2 = (LONG)global->RP.Data;
   toread       = global->RP.Arg3;

   for(total=0; toread; total+=amount, toread-=amount)
   {
      /* If this isn't the first time, wait for confirmation */
      if(total) GetRPacket(global, global->n.devptr);

      pkt->dp_Arg3 = min(toread, NETBUFSIZE);
      BUG(("RmtRead: Amount is %d, to read is %d\n", pkt->dp_Arg3, toread));
      Dispatch(global);

      global->RP.DLen = pkt->dp_Res1;
      if(PutRPacket(global, global->n.devptr)) pkt->dp_Res1 = -1;

      /* If there was EOF or some kind of error, quit */

      if((amount=pkt->dp_Res1) == 0) break;  /* Normal EOF */

      if(amount < 0)
      {
         if(offset >= 0)
         {
            /* Seek back to the original pos */
            pkt->dp_Type = ACTION_SEEK;
            pkt->dp_Arg2 = offset;
            pkt->dp_Arg3 = OFFSET_BEGINNING;
            Dispatch(global);
         }
         break;
      }
   }
   BUG(("RmtRead: Done reading, returning\n"));
   global->n.reply = 0;  /* Don't resend the last packet */
}

/*-------------------------------------------------------------------------*/
/*                                                                         */
/*                      RmtWrite( global, pkt )                            */
/*                                                                         */
/*-------------------------------------------------------------------------*/

void RmtWrite(global,pkt)
GLOBAL global;
struct DosPacket *pkt;
/* Arg1: APTR EFileHandle */
/* Arg2: APTR Buffer */
/* Arg3: Length */
{
   long offset;
   BUG(("RmtWrite\n"));

   if((offset = CurrentPos(global, pkt))<0)
   {
      BUG(("RmtWrite: Seek failed, code %d\n", pkt->dp_Res2));
      global->RP.Arg1 = pkt->dp_Res1;
      global->RP.Arg2 = pkt->dp_Res2;
      return;
   }

   pkt->dp_Type = ACTION_WRITE;
   pkt->dp_Arg2 = (LONG)global->RP.Data;

   while(1)
   {
      pkt->dp_Arg3 = global->RP.Arg3;
      Dispatch(global);

      global->RP.DLen = 0;
      if(PutRPacket(global, global->n.devptr)) pkt->dp_Res1 = -1;
      if(pkt->dp_Res1 == -1)
      {
         if(offset >= 0)
         {
            /* Seek back to where we started */
            pkt->dp_Type = ACTION_SEEK;
            pkt->dp_Arg2 = offset;
            pkt->dp_Arg3 = OFFSET_BEGINNING;
            Dispatch(global);
         }
         break;
      }
      if(global->RP.Arg4 == 0) break;  /* no more to write */

      GetRPacket(global, global->n.devptr);
   }
   global->n.reply = 0;  /* Don't reply twice */
}

/*-------------------------------------------------------------------------*/
/*                                                                         */
/*                       RmtSeek( global, pkt )                            */
/*                                                                         */
/*-------------------------------------------------------------------------*/

void RmtSeek(global,pkt)
GLOBAL global;
struct DosPacket *pkt;              /* a pointer to the dos packet sent      */
/* Arg1: APTR EFileHandle */
/* Arg2: Position */
/* Arg3: Mode */
{
   BUG(("RmtSeek\n"));
   pkt->dp_Arg1 = ((struct FileHandle *)global->RP.Arg1)->fh_Arg1;
   pkt->dp_Arg2 = global->RP.Arg2;
   pkt->dp_Arg3 = global->RP.Arg3;

   Dispatch(global);

   global->RP.DLen = 0;
}

/*-------------------------------------------------------------------------*/
/*                                                                         */
/*                    RmtFindwrite( global, pkt )                          */
/*                                                                         */
/*-------------------------------------------------------------------------*/

void RmtFindwrite(global,pkt)
GLOBAL global;
struct DosPacket *pkt;              /* a pointer to the dos packet sent    */
/* ARG1: FileHandle to fill in */
/* ARG2: Lock for file relative to */
/* Arg3: Name of file */
{
   struct FileHandle *fh;
   BUG(("RmtFindwrite, lock %lx\n", global->RP.Arg2));
   BUGBSTR("Filename = ", global->RP.Data);

   if(!(fh=(struct FileHandle *)
              DosAllocMem(global, sizeof(struct FileHandle))))
   {
      global->RP.Arg1 = DOS_FALSE;
      global->RP.Arg2 = ERROR_NO_FREE_STORE;
      return;
   }
   BUG(("Allocated FileHandle = %lx\n", fh));

   pkt->dp_Arg1 = (LONG)MKBADDR(fh);
   pkt->dp_Arg2 = global->RP.Arg2;
   MBSTR(global->RP.Data, global->fib);
   pkt->dp_Arg3 = (LONG)MKBADDR(global->fib);

   Dispatch(global);

   /* If the open was successful, return the allocated filehandle as Arg3 */
   if(pkt->dp_Res1 == DOS_FALSE) DosFreeMem((char *)fh);
   else global->RP.Arg3 = (LONG)fh;

   global->RP.DLen = 0;
}

/*-------------------------------------------------------------------------*/
/*                                                                         */
/*                       RmtEnd( global, pkt )                             */
/*                                                                         */
/*-------------------------------------------------------------------------*/

void RmtEnd( global, pkt )
GLOBAL global;
struct DosPacket *pkt;              /* a pointer to the dos packet sent    */
{
   struct FileHandle *fh;
   BUG(("RmtEnd, freeing %lx\n", global->RP.Arg1));

   pkt->dp_Arg1 = (fh=(struct FileHandle *)global->RP.Arg1)->fh_Arg1;

   Dispatch(global);

   DosFreeMem((char *)fh);

   global->RP.DLen = 0;
}
