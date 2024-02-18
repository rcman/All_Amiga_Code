
/*
 *  DNET.H
 *
 *  DNET (c)Copyright 1988, Matthew Dillon, All Rights Reserved.
 *
 */

#define DNET_H

#ifdef LATTICE
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
#include <proto/exec.h>
#include <proto/dos.h>

#define U_ARGS(a) a

#else

#define U_ARGS(a) ()    /* No support for prototypes - oh well */

#endif


typedef unsigned char   ubyte;
typedef unsigned short  uword;
typedef unsigned long   ulong;

typedef struct MsgPort      PORT;
typedef struct timerequest  IOT;
typedef struct IOStdReq     IOR;
typedef struct List         LIST;
typedef struct Node         NODE;
typedef struct Process      PROC;
typedef struct Message      MSG;

#include "channel.h"

#ifndef MAX(a,b)
#define MAX(a,b) (((a)>(b))?(a):(b))
#endif

#define PKT struct _PKT
#define PNODE   struct _PNODE

#define BTOC(yow)           ((ubyte *)((long)(yow) << 2))
#define DNETPORTNAME        "DNET.UNIT."
#define OFFSET(ptr,elem)    ((long)((char *)&(ptr)->elem - (char *)(ptr)))

#define EMPTY   0       /*  empty (sent)                    */
#define READY   1       /*  data ready (not sent yet)       */

#define MAXCHAN 128     /*  Max # of channels supported     */
#define SYNC    0xFF    /*  SYNC character                  */
#define MAXPKT  200     /*  maximum packet size             */
#define MINPKT  32      /*  minimum maximum packet size
                            (for priority scheme)           */

#define OVERHEAD    7   /*  for packets with data           */

PNODE {
    NODE    node;
    char    name[32];
    ulong   seg;
};

PKT {
    uword   iolength;   /*  send: length of packet, recv: length of data    */
    ubyte   state;      /*  EMPTY, READY     */

    ubyte   sync;       /*  THE PACKET      */
    ubyte   ctl;
    ubyte   cchk;
    ubyte   lenh;
    ubyte   lenl;
    ubyte   data[MAXPKT+2];
};

/*  RECEIVER STATES    */
#define RS_SYNC 0           /*  Waiting for sync                */
#define RS_CTL  1           /*  Waiting for command             */
#define RS_CCHK 2           /*  Waiting for check byte          */
#define RS_LEN1 3           /*  Waiting for MSB length byte     */
#define RS_LEN2 4           /*  Waiting for LSB length byte     */
#define RS_DATA 5           /*  Waiting for data & checksum     */

#define DNCMD_OPEN      32  /*  Application open                */
#define DNCMD_SOPEN     33  /*  Server open                     */
#define DNCMD_CLOSE     34  /*  Close a channel                 */
#define DNCMD_EOF       35  /*  Will no longer write to channel */

#define DNCMD_WRITE     36  /*  Write data to a channel         */
#define DNCMD_QUIT      37  /*  Kill the DNET server            */
#define DNCMD_IOCTL     38

/*  REQUEST TYPES    */
#define RTO_REQ         1   /*  Network read timeout            */
#define WTO_REQ         2   /*  Network write-ack timeout       */
#define RNET_REQ        3   /*  Network read data               */
#define WNET_REQ        4   /*  Network write data sent         */
#define PKT_REQ         5   /*  Returned packets from servers   */
#define OPEN_REQ        6
#define IGWNET_REQ      7

/* PACKET CONTROL BYTE */
#define PKF_SEQUENCE    0xE0    /*  Sequence #                  */
#define PKF_DATA        0x10    /*  1-65535 bytes               */
#define PKF_RESERVED    0x08    /*  reserved bit                */
#define PKF_MASK        0x07    /*  command mask                */

#define PKCMD_WRITE     1       /*  A DATA packet               */
#define PKCMD_CHECK     2       /*  Request ACK or NAK for win  */
#define PKCMD_ACK       3       /*  ACK a window                */
#define PKCMD_NAK       4       /*  NAK a window                */
#define PKCMD_RESTART   5       /*  Restart                     */
#define PKCMD_ACKRSTART 6       /*  Restart Acknowledge         */
#define PKCMD_RESERVE3  7
/*  CHANNEL COMMANDS    */
#define SCMD_SWITCH     0x00    /*  switch active channel #     */
#define SCMD_OPEN       0x01    /*  open a channel              */
#define SCMD_CLOSE      0x02    /*  close a channel             */
#define SCMD_ACKCMD     0x03    /*  ack an open/close request   */
#define SCMD_EOFCMD     0x04    /*  Reof or Weof                */
#define SCMD_QUIT       0x05    /*  crash dnet                  */
#define SCMD_IOCTL      0x06    /*  ioctl                       */

#define SCMD_DATA       0x08    /*  stream command, DATA        */

#define CHAN_FREE       0x01    /*  free channel                */
#define CHAN_ROPEN      0x02    /*  remote open, wait port msg  */
#define CHAN_LOPEN      0x03    /*  local open, wait reply      */
#define CHAN_OPEN       0x04
#define CHAN_CLOSE      0x05    /*  see flags                   */
#define CHANF_ROK       0x01    /*  NOT read eof                */
#define CHANF_WOK       0x02    /*  remote will accept data     */
#define CHANF_LCLOSE    0x04
#define CHANF_RCLOSE    0x08

struct DChannel {
    PORT    port;             /*  receive data, replies      */
    PORT    *dnetport;        /* dnet's master port          */
    LIST    rdylist;          /* ready to be read            */
    uword   chan;             /* channel # for open channels */
    ubyte   eof;              /* channel remotely closed/eof */
    ubyte   filler;
    int     qlen;             /* allowed write queue size    */
    int     queued;           /* current # packets queued    */
};

extern void  *ArbitrateNext();

#ifndef NOEXT
extern IOT Rto;                /*  Read-Timeout/reset          */
extern IOT Wto;                /*  Write-Timeout/retry         */
extern IOR *RNet;              /*  read-request                */
extern IOR *WNet;              /*  write-request               */
extern PKT Pkts[9];
extern PKT *Raux;              /*  next packet in              */
extern PKT *RPak[4];
extern PKT *WPak[4];
extern PORT *DNetPort;         /*  Remote Command/Control in       */
extern PORT *IOSink;           /*  Return port for ALL IO          */
extern CHAN Chan[MAXCHAN];
extern LIST TxList;            /*  For pending DNCMD_WRITE reqs.   */
extern LIST SvList;
extern ubyte Rto_act;
extern ubyte Wto_act;
extern uword RChan;
extern uword WChan;
extern uword RPStart;
extern uword WPStart;
extern uword WPUsed;
extern uword RState;
extern ubyte DDebug;
extern ubyte Restart;
extern ubyte DeldQuit;
extern ubyte AutoHangup;
extern ulong NumCon;
extern ulong WTimeoutVal;
extern ulong RTimeoutVal;
extern long Baud;
extern char *HostName;      /*   The Amiga's HostName    */

extern ubyte RestartPkt[3];
extern ubyte AckPkt[8][3];
extern ubyte NakPkt[8][3];
extern ubyte CheckPkt[8][3];
#endif

#ifdef LATTICE
/* One #ifdef LATTICE is worth 1000 U_ARGS macros! */
PORT *DListen(uword);
void DUnListen(PORT *);
PORT *DAccept(PORT *);
DNAAccept(PORT *);
void DPri(struct DChannel *, int);
PORT *DOpen(char * /*host*/, uword /*portnum*/, 
            char /*txpri*/, char /*rxpri*/);
int DNRead(struct DChannel *, char *, int);
int DRead(struct DChannel *, char *, int);
void DQueue(struct DChannel *, int);
DWrite(struct DChannel *, char *, int);
void DEof(struct DChannel *);
void DIoctl(struct DChannel *, ubyte, uword, ubyte);
int DQuit(char *);
void DClose(struct DChannel *);
void WaitMsg(IOR *);
int WaitQueue(struct DChannel *, IOR *);

#endif

