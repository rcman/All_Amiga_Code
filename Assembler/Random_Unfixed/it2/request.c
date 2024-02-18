/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1988 The Software Distillery.  All Rights Reserved */
/* |. o.| || This program may not be distributed without the permission of   */
/* | .  | || the authors:                             BBS: (919) 481-6436    */
/* | o  | ||   John Toebes     John Mainwaring    Jim Cooper                 */
/* |  . |//    Bruce Drake     Gordon Keener      Dave Baker                 */
/* ======                                                                    */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#define NETCOMMON
#include "netcomm.h"
#include "proto.h"
#include <proto/intuition.h>

int request(global, reqnum, msg)
NGLOBAL global;
int reqnum;
char *msg;
{
/* Possible requesters that we can see at this time */
/* 1: 
      You MUST replace volume
       xxxxx
      in Unit 0 !!!

   2: I/O Error on volume
       xxxxx
      in Unit 0

   ?: Unknown Error with volume
       xxxxx
      in Unit 0
*/

#if 0
   if (global->volume == NULL)
#endif
      {
      *(long *)&global->n.line3.LeftEdge     = 0x0004000EL;  /* 4,4  */
      global->n.line1.NextText = &global->n.line2;
      }
#if 0
   else
      {
      global->n.line1.NextText = &global->n.line2;
      global->n.line2.IText = (UBYTE *)BADDR(global->volume->dl_Name)+1;
      global->n.line2.NextText = &global->n.line3;
      }
#endif
   global->n.line3.IText = (UBYTE *)&global->n.buf3;
   *(long *)&global->n.buf3[0] = ('i'<<24)|('n'<<16)|(' '<<8)|'U';
   *(long *)&global->n.buf3[4] = ('n'<<24)|('i'<<16)|('t'<<8)|' ';
   *(long *)&global->n.buf3[8] = ('0'<<24)|(' '<<16)|('!'<<8)|'!';
   /*global->n.buf3[8] += global->unitnum;*/
   global->n.buf3[12] = 0;

   switch(reqnum)
      {
      case REQ_MUST:
         global->n.line1.IText = "You MUST replace volume";
         break;
      case REQ_ERROR:
         global->n.line1.IText = "I/O Error on volume";
         global->n.buf3[9] = 0;
         break;
      case REQ_GENERAL:
         global->n.line1.IText = msg;
         global->n.buf3[9] = 0;
         break;
      default:
         global->n.line1.IText = "Unknown error on volume";
         break;
      }

   /* Now we need to put up the requester */
   if (IntuitionBase == NULL)
      IntuitionBase = (struct IntuitionBase *)OpenLibrary("intuition.library",0);
   /* We probably should check and put up an alert.. but later on that */

   /* Now display the requester */
   return(AutoRequest(NULL, &global->n.line1,
                            &global->n.retrytxt,   &global->n.canceltxt,
                            DISKINSERTED,        0,
                            320,                 72));
}


