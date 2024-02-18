/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1988, 1989 The Software Distillery.  All Rights  */
/* |. o.| || Reserved.  This program may not be distributed without the    */
/* | .  | || permission of the authors:                            BBS:    */
/* | o  | ||   John Toebes     Doug Walker    Dave Baker                   */
/* |  . |//                                                                */
/* ======                                                                  */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


/* If PARANOID is defined >0, requesters will pop up for debugging */
/* during the startup.  No need to define it unless we die before  */
/* getting far enough to start up debugging.                       */

#define PARANOID 0

/* Defining CPR >0 will link in code to do a busy wait when the CPRWAIT */
/* debug packet is received.  This allows CPR to catch the NET: task    */
/* and lets us proceed with debugging;  if we are WAITing when CPR      */
/* catches us, we're dead in the water.                                 */
#define CPR 0

/* Defining DEBUG >0 will link in code to print stuff to any debugging  */
/* filehandles provided us by HANDD.  This slows us down quite a bit    */
/* since the BUG macros all call a subroutine to print their messages   */
/* even if we aren't debugging anything at the moment.                  */

#ifdef DEBUG
#undef DEBUG
#endif

#define DEBUG 0


/* The NOEXT define is set by the including .c program to prevent system */
/* include files from being reincluded here.  It is only used in dnetlib */
#ifndef NOEXT
#include <exec/types.h>
#include <exec/nodes.h>
#include <exec/lists.h>
#include <exec/ports.h>
#include <exec/libraries.h>
#include <exec/devices.h>
#include <exec/io.h>
#include <exec/memory.h>
#include <exec/interrupts.h>
#include <intuition/intuition.h>
#include <devices/console.h>
#include <devices/timer.h>
#include <libraries/dos.h>
#include <libraries/dosextens.h>
#include <libraries/filehandler.h>
#include <string.h>
#include <stdlib.h>
#ifdef MANX
#define U_ARGS(a) ()    /* No support for prototypes - oh well */
#else
#define U_ARGS(a) a     /* prototype checking to ensure all is well */
#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/timer.h>
#endif
#endif

#ifndef min
#define min(a,b) ((a)<(b)?(a):(b))
#endif

/* A macro to make good SAS Institute programmers feel at home */
#define MQ(f,t,l) memcpy((char *)t,(char *)f,(int)l);

#define MBSTR(f,t) memcpy((char *)t,(char *)f,(int)(*((char *)f))+1);
#define BSTRLEN(s) ((int)(*((char *)(s))))

#undef GLOBAL
/* my version of BADDR() has no problems with casting */
#undef  BADDR
#define BADDR(x)        ((APTR)((long)x << 2))
#define MKBADDR(x)      ((BPTR)((long)x >> 2))

/* Define a few packet types that may not be in the system include files */

#ifdef ACTION_END
#undef ACTION_END
#endif
#ifdef ACTION_SEEK
#undef ACTION_SEEK
#endif

#define ACTION_FIND_WRITE       1004L
#define ACTION_FIND_INPUT       1005L /* please refer to DOS Tech. Ref. */
#define ACTION_FIND_OUTPUT      1006L
#define ACTION_END              1007L
#define ACTION_SEEK             1008L
#ifndef ACTION_MORE_CACHE
#define ACTION_MORE_CACHE       18L
#endif
#ifndef ACTION_FLUSH
#define ACTION_FLUSH            27L
#endif
#define ACTION_SET_FILE_DATE    34L
#define ACTION_SET_RAW_MODE     994L

/* Private packets */
#define ACTION_HANDLER_DEBUG    2010L
#define ACTION_SET_TRANS_TYPE   2011L
#define ACTION_NETWORK_HELLO    2012L


#define ACTION_NETWORK_KLUDGE   4674764L   /* Temporary until ROOT: done */


#define ERROR_NODE_DOWN   ERROR_OBJECT_NOT_FOUND

#define DOS_FALSE        0L
#define DOS_TRUE        -1L           /* BCPL "TRUE" */

typedef char *RPTR;    /* Pointer to remote node's memory    */

typedef int (*fptr)();

#define RNAMELEN 16    /* Max 16 byte names for remote nodes */

typedef struct TimerPacket {
   struct timerequest tm_req;
   struct DosPacket   tm_pkt;
};


/* Define a struct to communicate with the NETSTAT program */
#define NTI_TRANSMIT 0 
#define NTI_RECEIVE  1

struct NetTransInfo
{
   struct Message m;
   long nti_bytes;      /* Number of bytes since last request */
   int  nti_direction;  /* NTI_TRANSMIT or NTI_RECEIVE        */
};

/* The following defines the network buffer size.  Reads/writes larger */
/* than this amount will be broken up into smaller chunks.             */
/* Really should be set by querying the other side.                    */
#define NETBUFSIZE 1024   /* Maximum amount of meaningful data to send */
#define FILENAMELEN 120  /* Length of a filename */

struct RPacket       /* Packet sent to remote node */
{
   LONG Type;          /* Type of request (AmigaDos packet type)       */
   RPTR RDevice;       /* Pointer to remote MsgPort to send packet to  */
   LONG Arg1,          /* Equivalent to dp_Arg? in normal devices      */
        Arg2,          /* when transmitting, dp_Res? when receiving    */
        Arg3,
        Arg4;
   long DLen;          /* Length of data in Data buffer                */
   char Data[NETBUFSIZE]; /* Data buffer                               */
};

#define RPSIZE (sizeof(struct RPacket) - NETBUFSIZE)

struct NetGlobal
{
   struct Process       *self;       /* my process                         */
   struct MsgPort       *port;       /* our message port                   */
   struct MsgPort       *devport;    /* msg port for device io             */
   struct MsgPort       *infoport;   /* msg port for device status info    */
   struct TimerPacket   *timerpkt;   /* pkt used for timer request         */
   APTR                 devptr;      /* Device-defined                     */
   int    run;                       /* flag to continue running           */
   int    reply;                     /* flag to inhibit replying to message*/
   long   ErrorCount;                /* Error count for current volume     */
   short  histimeout;                /* Other side's timeout length        */
   short  mytimeout;                 /* My timeout length                  */
   char   *devname;                  /* pointer to device name             */
   /* These are the fields of the autorequest structure we want to create  */
   struct IntuiText line1;           /* Top Line of requester              */
   struct IntuiText line2;           /* Second Line of requester           */
   struct IntuiText line3;           /* Bottom Line of requester           */
   struct IntuiText retrytxt;        /* Retry information                  */
   struct IntuiText canceltxt;       /* CANCEL information                 */
   char   buf3[16];                  /* Buffer to hold unit information    */
   int    inuse_trans, inuse_rec;    /* NetTransInfo struct is in use      */
   long   inf_trans, inf_rec;        /* Bytes trans & rec while nti in use */
   struct NetTransInfo ntirec;       /* Send receive info to stat window   */
   struct NetTransInfo ntitrans;     /* Send transmit info to stat window  */
   union /* Union of driver-specific data - max one entry per driver */
   {
      struct MsgPort *LisPort;  /* For DNET protocol                   */
   } d;
};

typedef struct
{
   struct NetGlobal n;
   struct RPacket RP;
   struct DosPacket     *pkt;        /* the packet we are processing       */
} *NGLOBAL;

