/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1987, 1988 The Software Distillery.  All Rights  */
/* |. o.| || Reserved.  This program may not be distributed without the    */
/* | .  | || permission of the authors:                            BBS:    */
/* | o  | ||   John Toebes     Doug Walker    Dave Baker                   */
/* |  . |//                                                                */
/* ======                                                                  */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "server.h"

/* Eventually, make this table work for me - flag significant args,     */
/* flag args that point into the data table.  This will take care of    */
/* everything but Examine, ExNext, Read and Write with no special funcs */

/******************************************************************************/
/******************************************************************************/
/********************* Dispatch table to handle all packets *******************/
/******************************************************************************/
/******************************************************************************/
#define BP1 1
#define BP2 2
#define BP3 4
#define BP4 8

typedef void (*ifuncp)(GLOBAL, struct DosPacket *);
struct LookupTable
   {
   ifuncp subr;
   int flags;
   };

#define LO_FIRST 0
#define LO_LAST  34
struct LookupTable lowork[LO_LAST+1] = {
   { NULL,              0  | 0  | 0  | 0   }, /*  0 - ACTION_NIL            */
   { NULL,              0  | 0  | 0  | 0   }, /*  1 - Unknown               */
   { NULL,              BP1| BP2| BP3| 0   }, /*  2 - ACTION_GET_BLOCK      */
   { NULL,              0  | BP2| BP3| 0   }, /*  3 - Unknown               */
   { NULL,              BP1| BP2| BP3| 0   }, /*  4 - ACTION_SET_MAP        */
   { RmtDie,            0  | 0  | 0  | 0   }, /*  5 - ACTION_DIE            */
   { NULL,              0  | 0  | 0  | 0   }, /*  6 - ACTION_EVENT          */
   { NULL,              BP1| 0  | 0  | 0   }, /*  7 - ACTION_CURRENT_VOLUME */
   { RmtLock,           BP1| BP2| 0  | 0   }, /*  8 - ACTION_LOCATE_OBJECT  */
   { NULL,              BP1| BP2| 0  | 0   }, /*  9 - ACTION_RENAME_DISK    */
   { NULL,              0  | 0  | 0  | 0   }, /* 10 - Unknown               */
   { NULL,              0  | 0  | 0  | 0   }, /* 11 - Unknown               */
   { NULL,              0  | 0  | 0  | 0   }, /* 12 - Unknown               */
   { NULL,              0  | 0  | 0  | 0   }, /* 13 - Unknown               */
   { NULL,              0  | 0  | 0  | 0   }, /* 14 - Unknown               */
   { RmtUnLock,         BP1| 0  | 0  | 0   }, /* 15 - ACTION_FREE_LOCK      */
   { RmtDelete,         BP1| BP2| 0  | 0   }, /* 16 - ACTION_DELETE_OBJECT  */
   { RmtRename,         BP1| BP2| BP3| BP4 }, /* 17 - ACTION_RENAME_OBJECT  */
   { NULL,              0  | 0  | 0  | 0   }, /* 18 - ACTION_MORE_CACHE     */
   { RmtDupLock,        BP1| 0  | 0  | 0   }, /* 19 - ACTION_COPY_DIR       */
   { NULL,              0  | 0  | 0  | 0   }, /* 20 - ACTION_WAIT_CHAR      */
   { RmtSetProtection,  0  | BP2| BP3| 0   }, /* 21 - ACTION_SET_PROTECT    */
   { RmtCreateDir,      BP1| BP2| 0  | 0   }, /* 22 - ACTION_CREATE_DIR     */
   { RmtExamine,        BP1| BP2| 0  | 0   }, /* 23 - ACTION_EXAMINE_OBJECT */
   { RmtExNext,         BP1| BP2| 0  | 0   }, /* 24 - ACTION_EXAMINE_NEXT   */
   { NULL,              BP1| 0  | 0  | 0   }, /* 25 - ACTION_DISK_INFO      */
   { RmtInfo,           BP1| BP2| 0  | 0   }, /* 26 - ACTION_INFO           */
   { NULL,              0  | 0  | 0  | 0   }, /* 27 - ACTION_FLUSH          */
   { RmtSetComment,     0  | BP2| BP3| BP4 }, /* 28 - ACTION_SET_COMMENT    */
   { RmtParent,         BP1| 0  | 0  | 0   }, /* 29 - ACTION_PARENT         */
   { NULL,              BP1| 0  | 0  | 0   }, /* 30 - ACTION_TIMER          */
   { NULL,              0  | 0  | 0  | 0   }, /* 31 - ACTION_INHIBIT        */
   { NULL,              BP1| 0  | 0  | 0   }, /* 32 - ACTION_DISK_TYPE      */
   { NULL,              0  | 0  | 0  | 0   }, /* 33 - ACTION_DISK_CHANGE    */
   { NULL,              0  | 0  | 0  | 0   }  /* 34 - ACTION_SET_FILE_DATE  */
      };

#define HI_FIRST 1004
#define HI_LAST  1008
struct LookupTable hiwork[5] = {
   { RmtFindwrite,      BP1| BP2| BP3| 0   }, /* ACTION_FIND_WRITE  - 1004 */
   { RmtFindwrite,      BP1| BP2| BP3| 0   }, /* ACTION_FIND_INPUT  - 1005 */
   { RmtFindwrite,      BP1| BP2| BP3| 0   }, /* ACTION_FIND_OUTPUT - 1006 */
   { RmtEnd,            0  | 0  | 0  | 0   }, /* ACTION_END         - 1007 */
   { RmtSeek,           0  | 0  | 0  | 0   }  /* ACTION_SEEK        - 1008 */
   };

#define USER_FIRST 2010
#define USER_LAST  2012
struct LookupTable userwork[3] = {
   { RmtSetDebug,       0  | 0  | 0  | 0   }, /* ACTION_HANDLER_DEBUG 2010 */
   { NULL,              BP1| 0  | 0  | 0   }, /* ACTION_SET_TRANS_TYPE2011 */
   { NULL,              BP1| 0  | 0  | 0   }, /* ACTION_NETWORK_HELLO 2012 */
   };

struct DosLibrary *DOSBase;

void _main(x)
char *x;
{
   ifuncp             subr;
   int                action;
   struct global      global;

   DOSBase = (struct DosLibrary *)OpenLibrary(DOSNAME,0);

   /* Initialize our global data structure */
   memset((char *)&global, 0, sizeof(struct global));
   global.n.self   = (struct Process *) FindTask(0L);  /* find myself        */
   global.n.run    = 1;
   global.n.port   = &(global.n.self->pr_MsgPort);
                 /* install our taskid ...   */
   if(!(global.fib = (char *)
             DosAllocMem(&global, 2*sizeof(struct FileInfoBlock))))
   {
      global.n.run = 0;
   }

   /* Initialize the intuitext structures for the requesters we might have   */
   /* to display                                                             */
   /* Because we have no scruples we can cheat and do this with a couple of  */
   /* long word assignments.  We leave the acual C code commented out here   */
   /* so that if this structure ever changed we will still be able to work   */
#if 0
   global.n.line1.FrontPen = global.n.line1.BackPen = -1;
   global.n.line1.DrawMode = JAM1;
   global.n.line1.LeftEdge = global.n.line1.TopEdge = 4;
   global.n.line2 = global.n.line1;
   global.n.line3 = global.n.line1;
   global.n.retrytxt = global.n.line1;
   global.n.canceltxt = global.n.line1;
#else
   *(long *)&global.n.line1.FrontPen     = 0x00010000L | (JAM1<<8);
   *(long *)&global.n.line1.LeftEdge     = 0x00040004L;  /* 4,4  */
   *(long *)&global.n.line2.FrontPen     = 0x00010000L | (JAM1<<8);
   *(long *)&global.n.line2.LeftEdge     = 0x0004000EL;  /* 4,14 */
   *(long *)&global.n.line3.FrontPen     = 0x00010000L | (JAM1<<8);
   *(long *)&global.n.line3.LeftEdge     = 0x00040018L;  /* 4,24 */
   *(long *)&global.n.retrytxt.FrontPen  = 0x00010000L | (JAM1<<8);
   *(long *)&global.n.retrytxt.LeftEdge  = 0x00040004L;
   *(long *)&global.n.canceltxt.FrontPen = 0x00010000L | (JAM1<<8);
   *(long *)&global.n.canceltxt.LeftEdge = 0x00040004L;
#endif
   global.n.retrytxt.IText = "Retry";
   global.n.canceltxt.IText = "Cancel";


   /* Should get startup info from external config file */
   if(InitDevice(&global))
   {
      BUG(("****** ERROR INITIALIZING\n"));
#if DEBUG
      /* Can't use BUGR - need &global, not global */       
      request(&global, REQ_GENERAL, "Can't init");
#endif
   }
   else
   while(global.n.run)   /* start of the real work */
   {
      if(GetRPacket(&global, global.n.devptr))
      {
         if(!ReSync(&global, global.n.devptr)) continue;
         break;
      }

      BUG(("Execute: action #%ld arg1 %lx\n", 
           global.RP.Type, global.RP.Arg1));

      switch(action = global.pkt->dp_Type = global.RP.Type)
         {
         case ACTION_NETWORK_KLUDGE:
            subr = RmtNetKludge;
            break;
         
         case ACTION_READ:
            subr = RmtRead;
            break;
         case ACTION_WRITE:
            subr = RmtWrite;
            break;

         case ACTION_SET_RAW_MODE:
            subr = NULL;
            break;

         case ACTION_FIND_WRITE:  /* 1004 */
         case ACTION_FIND_INPUT:  /* 1005 */
         case ACTION_FIND_OUTPUT: /* 1006 */
         case ACTION_END:         /* 1007 */
         case ACTION_SEEK:        /* 1008 */
            subr = hiwork[action-HI_FIRST].subr;
            break;

         case ACTION_HANDLER_DEBUG:  /* 2010 */
         case ACTION_SET_TRANS_TYPE: /* 2011 */
         case ACTION_NETWORK_HELLO:  /* 2012 */
            subr = userwork[action-USER_FIRST].subr;
            break;

         default:            
            if ((action >= LO_FIRST) && (action <= LO_LAST))
               {
               subr = lowork[action-LO_FIRST].subr;
               }
            else
               subr = NULL;
         }
 
      if(subr != NULL)
      {
         global.n.reply = 1;
         (*subr)(&global, global.pkt);
      }
      else
      {
         global.RP.Arg1 = DOS_FALSE;
         global.RP.Arg2 = ERROR_ACTION_NOT_KNOWN;
         BUG(("Unknown packet type %ld\n",global.RP.Type));
      }

      /* Now return the packet to them */
      if (global.n.reply && 
          PutRPacket(&global, global.n.devptr) &&
          ReSync(&global, global.n.devptr))
         break;
  
      BUG(("-----\n"));
   }

   TermDevice(&global);

   BUGTERM()  
}

#define DEBUG_SPECIAL 0x40000000   /* Mask for handler-defined dbg type*/
#define DEBUG_SERVER  0x20000000   /* Mask indicating server command   */
#define DEBUG_SERVWT  0x10000000   /* Wait for debugger to catch us    */

void RmtSetDebug(global, pkt)
GLOBAL global;
struct DosPacket *pkt;
{
#if DEBUG
   BUG(("RmtSetDebug: Entry, arg1 %lx\n", global->RP.Arg1))
   if(global->RP.Arg1 == DEBUG_SERVWT) 
      cprwait(global);
   else if(global->RP.Arg1) 
      BUGINIT()
   else
      BUGTERM()

#endif
   pkt->dp_Res1 = DOS_TRUE;
}
