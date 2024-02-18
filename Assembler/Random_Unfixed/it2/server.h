/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1987 The Software Distillery.  All Rights Reserved */
/* |. o.| || This program may not be distributed without the permission of   */
/* | .  | || the authors:                                          BBS:      */
/* | o  | ||   John Toebes     Dave Baker     John Mainwaring                */
/* |  . |//                                                                  */
/* ======                                                                    */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "netcomm.h"

void checkdebug U_ARGS((void));

#if DEBUG
#define BUGCHECK() checkdebug();
#define BUGINIT()  initdebug(NULL);
#else
#define BUGCHECK()
#define BUGINIT()
#endif

typedef struct global
   {
   struct NetGlobal      n;          /* Globals in common with handler     */
   struct RPacket       RP;          /* Data area for remote node          */
   struct DosPacket     *pkt;        /* the packet we are processing       */
   struct StandardPacket *stdpkt;    /* Packet to send to local handlers   */
   struct MsgPort       *dosport;    /* msgport for DOS device to talk to  */
   struct RPacket       *rpptr;      /* Points to msg for singlemachine v  */
   char                 *fib;        /* For use by RmtExamine/RmtExNext    */
   struct InfoData      *infodata;   /* For use by RmtInfo                 */
   LONG   rootlock;                  /* Lock on root of ROOT:              */
   }* GLOBAL;

/* main.c */
void RmtSetDebug      U_ARGS((GLOBAL, struct DosPacket *));

/* file.c */
void RmtDelete        U_ARGS((GLOBAL, struct DosPacket *));
void RmtRename        U_ARGS((GLOBAL, struct DosPacket *));
void RmtSetComment    U_ARGS((GLOBAL, struct DosPacket *));
void RmtSetProtection U_ARGS((GLOBAL, struct DosPacket *));

/* io.c */
void RmtFindwrite U_ARGS((GLOBAL, struct DosPacket *));
#define RmtFindin RmtFindWrite
#define RmtFindout RmtFindWrite
void RmtEnd       U_ARGS((GLOBAL, struct DosPacket *));
void RmtRead      U_ARGS((GLOBAL, struct DosPacket *));
void RmtWrite     U_ARGS((GLOBAL, struct DosPacket *));
void RmtSeek      U_ARGS((GLOBAL, struct DosPacket *));

/* dir.c */
void RmtCreateDir U_ARGS((GLOBAL, struct DosPacket *));
void RmtExamine   U_ARGS((GLOBAL, struct DosPacket *));
#define RmtExNext RmtExamine
void RmtParent    U_ARGS((GLOBAL, struct DosPacket *));

/* lock.c */
void RmtLock    U_ARGS((GLOBAL, struct DosPacket *));
void RmtDupLock U_ARGS((GLOBAL, struct DosPacket *));
void RmtUnLock  U_ARGS((GLOBAL, struct DosPacket *));

/* volume.c */
void RmtInfo       U_ARGS((GLOBAL, struct DosPacket *));
void RmtNetKludge  U_ARGS((GLOBAL, struct DosPacket *));

/* device.c */
int InitDevice U_ARGS((GLOBAL));
int TermDevice U_ARGS((GLOBAL));
void RmtDie    U_ARGS((GLOBAL, struct DosPacket *));

/* Dispatch.c */
void Dispatch    U_ARGS((GLOBAL));

/* inhibit.c */
int inhibit  U_ARGS((struct MsgPort *, long));
long sendpkt U_ARGS((struct MsgPort *, long, long*, long));

/* volume.c */
void RmtInfo       U_ARGS((GLOBAL, struct DosPacket *));

/* net#?.c */
int InitRDevice    U_ARGS((GLOBAL));
int TermRDevice    U_ARGS((GLOBAL));

#include "/proto.h"
