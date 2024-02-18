/* Timer.c - Timer support routines */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1987 The Software Distillery.  All Rights Reserved */
/* |. o.| || This program may not be distributed without the permission of   */
/* | .  | || the author.                                           BBS:      */
/* | o  | ||   John Toebes    Dave Baker                     (919)-471-6436  */
/* |  . |//                                                                  */
/* ======                                                                    */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define NETCOMMON
#include "netcomm.h"
#include "proto.h"

int OpenTimer(global, port)
NGLOBAL global;    
struct MsgPort *port;
{
   int error;

   /* assumes that a msg port has been allocated */   

   if ((global->n.timerpkt = (struct TimerPacket *)
                CreateExtIO(port, sizeof(struct TimerPacket)))== NULL)
     return(1);

   global->n.timerpkt->tm_req.tr_node.io_Message.mn_Node.ln_Name = 
                              (char *)&(global->n.timerpkt->tm_pkt);
   global->n.timerpkt->tm_pkt.dp_Link =
                     &(global->n.timerpkt->tm_req.tr_node.io_Message);
   global->n.timerpkt->tm_pkt.dp_Port = port;

   error = OpenDevice(TIMERNAME, UNIT_MICROHZ, 
                     (struct IORequest *)&(global->n.timerpkt->tm_req), 0);

   return(error);
}

void CloseTimer(global)
NGLOBAL global;
{
   if (global->n.timerpkt != NULL)
      {
      CloseDevice((struct IORequest *)&(global->n.timerpkt->tm_req));
      DeleteExtIO((struct IORequest *)global->n.timerpkt,
                   sizeof(struct TimerPacket));
      global->n.timerpkt = NULL;
      }

}

void PostTimerReq(global, time)
NGLOBAL global;
int time;  /* tenths of a second */
{
   /* Fill in the timer packet values */
   /* that is the fields required for the timer device timerequest struct */
   /* and the necessary fields of the DosPacket struct                    */
   /* nothing like using 35 meg of store to accomplish a simple task      */
   /* oh well ! this is a 68K machine right ?                             */ 
   /* some of them get trampled on so fill them all */

   if (global->n.timerpkt != NULL)
      {
      time *= 100000;
      global->n.timerpkt->tm_req.tr_node.io_Command = TR_ADDREQUEST;
      global->n.timerpkt->tm_req.tr_time.tv_secs = time/100000;
      global->n.timerpkt->tm_req.tr_time.tv_micro = time%100000;

      global->n.timerpkt->tm_pkt.dp_Type = ACTION_TIMER;
      
      /* Async IO so we don't sleep here for the msg */
     
      SendIO((struct IORequest *)&global->n.timerpkt->tm_req);
      }
}
