/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1987 The Software Distillery.  All Rights Reserved */
/* |. o.| || This program may not be distributed without the permission of   */
/* | .  | || the authors:                                          BBS:      */
/* | o  | ||   John Toebes     Dave Baker     John Mainwaring                */
/* |  . |//                                                                  */
/* ======                                                                    */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "netcomm.h"

/* defines for NetNode status field */
#define NODE_DEAD    0     /* The node has never been heard from       */
#define NODE_UP      1     /* The node is up and responding normally   */
#define NODE_CRASHED 2     /* The node was responding, but is now down */


/* There is one NetNode structure for each node in the network.  Within*/
/* the NetNode structure is a definition for the NetPtr structure.  A  */
/* NetPtr structure completely describes a FileHandle or Lock on a     */
/* remote system: The NetNode pointer points to the NetNode struct for */
/* the appropriate node;  the RDevice field gives the address ON THE   */
/* REMOTE NODE of the AmigaDOS device to communicate with;  the RPtr   */
/* field gives the address ON THE REMOTE NODE of the FileHandle or Lock*/
/* we are dealing with.  To handle the NULL lock, we put an instance of*/
/* the NetPtr struct in the NetNode struct.  The NetNode field points  */
/* to the top of the struct, the RDevice field is normal and the RPTR  */
/* field is NULL.                                                      */
/* The ioptr field of the NetNode contains information specific to the */
/* communications driver for the node.  I will eventually also put a   */
/* pointer to the MsgPort for the driver once I support multiple       */
/* drivers.                                                            */
struct NetNode
{
   struct NetNode *next;      /* Next Net Node in chain                */
   int status;                /* Last known status - see above         */
   char name[RNAMELEN+2];     /* Name of remote node                   */
   char devname[RNAMELEN+2];  /* TEMPORARY - name of remote device     */
   short id;                  /* ID of remote node (timestamp)         */
   APTR ioptr;                /* Driver-defined pointer                */
   /* The NetPtr instance here is a special case - its NetNode pointer */
   /* points to the root of its own struct, its RPtr pointer is NULL.  */
   /* It is used when a 'template' NETPTR is needed for the net node.  */
   struct NetPtr
   {
      struct NetNode *NetNode;   /* Ptr to network address information     */
      RPTR RDevice;              /* Address of remote MsgPort              */
      RPTR RPtr;                 /* Remote file system's lock/filehandle   */
   } RootLock;
};

/* The following typedef is used to represent both remote locks and    */
/* remote filehandles, since the same information is needed for both.  */
/* Using a single struct allows us to use it as a parm to RemotePacket */
/* whether we have a filehandle or a lock.                             */
typedef struct NetPtr *NETPTR;

typedef struct global
   {
   struct NetGlobal      n;          /* Globals in common with server      */
   struct RPacket       RP;          /* Data area for remote node          */
   struct DosPacket     *pkt;        /* the packet we are processing       */
   struct DeviceNode    *node;       /* our device node                    */
   struct DeviceList    *volume;     /* currently mounted volume           */
   struct NetNode       netchain;    /* Head of NetNode struct chain       */
   int    numnodes;                  /* Number of nodes in the chain       */
   int    upnodes;                   /* Number of up nodes in the chain    */
   long   unitnum;
   }* GLOBAL;

/* file.c */
void ActDelete        U_ARGS((GLOBAL, struct DosPacket *));
void ActRename        U_ARGS((GLOBAL, struct DosPacket *));
void ActSetComment    U_ARGS((GLOBAL, struct DosPacket *));
void ActSetProtection U_ARGS((GLOBAL, struct DosPacket *));
void ActSetFileDate   U_ARGS((GLOBAL, struct DosPacket *));

/* io.c */
void ActFindwrite U_ARGS((GLOBAL, struct DosPacket *));
#define ActFindin ActFindWrite
#define ActFindout ActFindWrite
void ActEnd       U_ARGS((GLOBAL, struct DosPacket *));
void ActRead      U_ARGS((GLOBAL, struct DosPacket *));
void ActWrite     U_ARGS((GLOBAL, struct DosPacket *));
void ActSeek      U_ARGS((GLOBAL, struct DosPacket *));

/* dir.c */
void ActCreateDir U_ARGS((GLOBAL, struct DosPacket *));
void ActExamine   U_ARGS((GLOBAL, struct DosPacket *));
#define ActExNext ActExamine
void ActParent    U_ARGS((GLOBAL, struct DosPacket *));

/* main.c */
void ActSetDebug  U_ARGS((GLOBAL, struct DosPacket *));

/* lock.c */
struct FileLock *CreateLock U_ARGS((GLOBAL, NETPTR /* nlock */, 
                                    RPTR /* RLock */, LONG /* Access */));
void FreeLock   U_ARGS((GLOBAL, struct FileLock *));
void ActLock    U_ARGS((GLOBAL, struct DosPacket *));
void ActDupLock U_ARGS((GLOBAL, struct DosPacket *));
void ActUnLock  U_ARGS((GLOBAL, struct DosPacket *));
int ParseName   U_ARGS((GLOBAL, char *, NETPTR *, char *));
struct NetNode *FindNode U_ARGS((GLOBAL, char *));

/* Process.c */
void ActDie     U_ARGS((GLOBAL, struct DosPacket *));
void ActInhibit U_ARGS((GLOBAL, struct DosPacket *));
void ActFlush   U_ARGS((GLOBAL, struct DosPacket *));
void ActTimer   U_ARGS((GLOBAL, struct DosPacket *));

/* volume.c */
void ActCurentVol  U_ARGS((GLOBAL, struct DosPacket *));
void ActRenameDisk U_ARGS((GLOBAL, struct DosPacket *));
void ActDiskInfo   U_ARGS((GLOBAL, struct DosPacket *));
void ActInfo       U_ARGS((GLOBAL, struct DosPacket *));
void ActNetKludge  U_ARGS((GLOBAL, struct DosPacket *));
void ActDiskChange U_ARGS((GLOBAL, struct DosPacket *));

/* device.c */
int GetDevice  U_ARGS((GLOBAL, struct FileSysStartupMsg *));
int InitDevice U_ARGS((GLOBAL));
int TermDevice U_ARGS((GLOBAL));
struct NetNode *AddNode U_ARGS((GLOBAL, char *, APTR));

/* Devio.c */
int RemotePacket U_ARGS((GLOBAL, NETPTR));

/* inhibit.c */
int inhibit  U_ARGS((struct MsgPort *, long));
long sendpkt U_ARGS((struct MsgPort *, long, long*, long));

/* mount.c */
void Mount         U_ARGS((GLOBAL, char *));
void DisMount      U_ARGS((GLOBAL));

/* Requester routine */
int  request         U_ARGS((GLOBAL, int, char *));
#define REQ_MUST    0
#define REQ_ERROR   1
#define REQ_GENERAL 2

/* Protocol-specific .c file: net#?.c */
InitRDevice U_ARGS((GLOBAL));
TermRDevice U_ARGS((GLOBAL, int));
void ActNetHello   U_ARGS((GLOBAL, struct DosPacket *));

#include "/proto.h"

