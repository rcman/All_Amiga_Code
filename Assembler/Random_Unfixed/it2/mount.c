/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* |_o_o|\\ Copyright (c) 1987, 1988 The Software Distillery.  All Rights  */
/* |. o.| || Reserved.  This program may not be distributed without the    */
/* | .  | || permission of the authors:                            BBS:    */
/* | o  | ||   John Toebes     Doug Walker    Dave Baker                   */
/* |  . |//                                                                */
/* ======                                                                  */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Volume Manipulation */
/* mount */
#include "handler.h"

/* Define a BCPL volume name as a default */
#define NETNAME "\7Network"

void DisMount(global)
GLOBAL global;
{
   struct DeviceList *volume;
   struct DosInfo *info;
   struct RootNode *root;

   BUG(("Dismount: Entry\n"));

   /* start at the root of the device list */
   root   = (struct RootNode   *)DOSBase->dl_Root;
   info   = (struct DosInfo    *)BADDR(root->rn_Info);
   volume = (struct DeviceList *)BADDR(info->di_DevInfo);

   /* See if we have a current volume that we have to get rid of ? */
   /* Make sure there are no outstanding locks for the volume */
   if ((global->volume != NULL) && (global->volume->dl_Lock == NULL))
      {
      /* This volume needs to be removed from the list */
      /* First locate it on the list */
      Forbid();

      /* is it at the head of the list? */
      if (volume == global->volume)
         /* sure enough, just get rid of it */
         info->di_DevInfo = volume->dl_Next;
      else
         {
         /* Find it in the list */
         while(volume != NULL &&
            (struct DeviceList *)(BADDR(volume->dl_Next)) != global->volume)
            volume = (struct DeviceList *)BADDR(volume->dl_Next);

         /* if we found it then take it out of the chain */
         if (volume != NULL)
            volume->dl_Next = global->volume->dl_Next;
         }
      Permit();

      if (global->volume)
         {
         DosFreeMem((char *)global->volume);
         }
      }

   global->volume = NULL;
}

void Mount(global, name)
GLOBAL global;
char *name;
{
   struct DeviceList *volume;
   struct DosInfo *info;
   struct RootNode *root;
   short newlen; /* Cause memcmp to use the most efficient code */

   BUGP("Mount: Entry")
   BUG(("Mount: Entry\n"));

   global->n.ErrorCount = 0;

   if(name == NULL) name = NETNAME;
   newlen = *name + 1;

   /* Now find it on the device list. */
   /* First start at the root of the device list */
   root   = (struct RootNode   *)DOSBase->dl_Root;
   info   = (struct DosInfo    *)BADDR(root->rn_Info);
   volume = (struct DeviceList *)BADDR(info->di_DevInfo);

   BUGBSTR("Volume name is : ", name);

   /* Can't let the system change the list underneath us...        */
   Forbid();
   
   /* Now run through the list until we come up empty OR we find it */
   while(volume != NULL)
      {
      if (volume->dl_Type == DLT_VOLUME                               &&
          !memcmp(name, (char *)BADDR(volume->dl_Name), newlen)    &&
          volume->dl_VolumeDate.ds_Days   == 0L                       &&
          volume->dl_VolumeDate.ds_Minute == 0L                       &&
          volume->dl_VolumeDate.ds_Tick   == 0L)
         break;
      volume = (struct DeviceList *)BADDR(volume->dl_Next);
      }

   Permit();

   BUG(("mount: Volume is %08lx\n", volume));

   /* OK, now did we find it? */
   if (volume != NULL)
      {
      BUGP("Got volume")
      BUG(("Got a matching node\n"));

      /* Sure did, We probably need to check to see if another handler has */
      /* it to work with, but for now we assume only onw such volume can   */
      /* exist.  This was a problem with all but the latest version of 1.2 */
      /* If we have write access, we should probably nudge the ticks by one*/
      /* just to make it unique                                            */
      }
   else
      /* No such volume is known to the system.  So we will just have to   */
      /* allocate a node to put everything on.                             */
      {
      BUGP("No volume")
      volume = (struct DeviceList *)
               DosAllocMem(global, sizeof(struct DeviceList)+newlen);

      BUG(("Created new node at %08lx\n", volume));

      /* Note that volume+1 gets us to the extra memory we allocated.  */
      /* Just a lot simpler to write that in C than ...+sizeof(...)    */
      MQ(name, (char *)(volume + 1), newlen);
      volume->dl_VolumeDate.ds_Days   = 3800L;
      volume->dl_VolumeDate.ds_Minute = 
      volume->dl_VolumeDate.ds_Tick   = 0L;
      volume->dl_Name = (BSTR)MKBADDR((volume + 1));
      volume->dl_Lock = NULL;
      volume->dl_Type = DLT_VOLUME;

      /* Also we need to link it into the list */
      Forbid();
      volume->dl_Next = info->di_DevInfo;
      info->di_DevInfo = MKBADDR(volume);
      Permit();
      }

   /* Now we can own the volume by giving it our task id */
   volume->dl_Task = global->n.port;
   volume->dl_DiskType = ID_DOS_DISK;

   /* all set up, remember what our base volume is */
   global->volume = volume;

   BUGP("Mount: Exit")
}

