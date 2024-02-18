/*
 * MyCLI - a replacement for the standard AmigaDos CLI
 * Programmed by Mike Schwartz (C)1985 MS Software, All Rights Reserved!
 * Feel free to give this software away, in any form, for no charge only.
 * Feel free to donate to:
 * MS Software
 * 344 Fay Way
 * Mountain View, CA 94043
 */

#include "exec/types.h"
#include "exec/exec.h"
#include "libraries/dos.h"
#include "libraries/dosextens.h"
#include "devices/serial.h"

/*
 * External functions
 */
extern   unsigned char        *stpblk();
extern   unsigned char        *AllocMem();
extern   struct   MsgPort     *CreatePort();
extern   struct   FileLock    *CreateDir();
extern   struct   FileLock    *CurrentDir();
extern   struct   FileLock    *Lock();
extern   struct   FileHandle  *Open();

/*
 * forward references
 */
int   capture(), cd(), copy(), date(), define_function_key(), delete(),
      dir(), delete(), endcli(), help(), md(), newcli(), offline(),
      rename(), setprompt(), setcomment(), TerminalMode(), time(), type(),
      whatis();

/*
 * Tables
 */
struct {
   unsigned char  *cmdname;
   int            (*cmdfunc)();
   } command_table[] = {
   (unsigned char *)"capture", &capture,
   (unsigned char *)"cd", &cd,
   (unsigned char *)"chdir", &cd,
   (unsigned char *)"copy", &copy,
   (unsigned char *)"date", &date,
   (unsigned char *)"define", &define_function_key,
   (unsigned char *)"def", &define_function_key,
   (unsigned char *)"delete", &delete,
   (unsigned char *)"del", &delete,
   (unsigned char *)"dir", &dir,
   (unsigned char *)"erase", &delete,
   (unsigned char *)"endcli", &endcli,
   (unsigned char *)"help", &help,
   (unsigned char *)"makedir", &md,
   (unsigned char *)"md", &md,
   (unsigned char *)"newcli", &newcli,
   (unsigned char *)"online", &TerminalMode,
   (unsigned char *)"offline", &offline,
   (unsigned char *)"rename", &rename,
   (unsigned char *)"ren", &rename,
   (unsigned char *)"prompt", &setprompt,
   (unsigned char *)"setcomment", &setcomment,
   (unsigned char *)"terminal", &TerminalMode,
   (unsigned char *)"time", &time,
   (unsigned char *)"type", &type,
   (unsigned char *)"whatis", &whatis,
   (unsigned char *)"\0", &help,
   };

unsigned char  *help_messages[] = {
   "capture    = capture file from modem",
   "cd         = current directory",
   "chdir      = current directory",
   "copy       = copy from one file to another",
   "date       = show current date and time",
   "def        = define a function key",
   "define     = define a function key",
   "del        = delete file or subdirectory",
   "delete     = delete file or subdirectory",
   "dir        = directory",
   "erase      = delete file or subdirectory",
   "endcli     = exit to previous cli",
   "help       = print this list",
   "makedir    = make a new subdirectory",
   "md         = make a new directory",
   "newcli     = birth another mycli task",
   "online     = enter or re-enter dumb terminal mode",
   "offline    = terminate communication",
   "ren        = rename a file or directory",
   "rename     = rename a file or directory",
   "prompt     = change system prompt",
   "setcomment = tag a file with a comment string",
   "terminal   = enter or re-enter dumb terminal mode",
   "time       = show current time",
   "type       = view a file, or ascii file transmit",
   "whatis     = converts AmigaDos Error Codes to text",
   0};

unsigned char  *function_key_definitions[20] = {
   0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0
   };

struct   {
   int   code;
   unsigned char  *message;
   } errorcodes[] = {

      103,    "insufficient free store",
      104,    "task table full",
      120,    "argument line invalid or too long",
      121,    "file is not an object module",
      122,    "invalid resident library during load",
      203,    "object already exists",
      204,    "directory not found",
      205,    "object not found",
      206,    "invalid window",
      210,    "invalid stram component name",
      212,    "object not of required type",
      213,    "disk not validated",
      214,    "disk write-protected",
      215,    "rename across devices attempted",
      216,    "directory not empty",
      218,    "device not mounted",
      220,    "comment too big",
      221,    "disk full",
      222,    "file is protected from deletion",
      223,    "file is protected from writing",
      224,    "file is protected from reading",
      225,    "not a DOS disk",
      226,    "no disk in drive",
      209,    "packet request type unknown",
      211,    "invalid object lock",
      219,    "seek error",
      232,    "no more entries in directory",
      0, 0};

/*
 * Globals
 */
struct   FileLock       *worklock;
struct   InfoData       disk_info;
struct   FileInfoBlock  fib;
struct   FileHandle     *workfp;

unsigned char     work[512];
unsigned char     buf[512];
unsigned char     work2[512];
unsigned char     temp[80];

/*
 * MyCli globals
 */
struct   FileHandle     *mycli_infp;
struct   FileHandle     *mycli_outfp;

unsigned char     *prompt_string = 0;
unsigned char     current_directory[80];
int      mycli_id = 1;

/*
 * Terminal emulator stuff
 */
struct   Message        *mymessage;
struct   IOExtSer       *ModemReadRequest;
struct   IOExtSer       *ModemWriteRequest;

unsigned char  *WelcomeMessage = "Entering Terminal Mode\nUse ^C for command mode\n";
unsigned char  *GoodbyeMessage = "Disconnected\n";
unsigned char  *OfflineMessage = "--- Offline ---\n";
unsigned char  *OnlineMessage = "--- Online ---\n";

unsigned char     rs_in[2], rs_out[2];
int      bdoneflag = 0;
int      TermEcho = 0;
int      modem_online = 0;
int      capturing_file = 0;
struct   FileHandle  *capture_fp;

main(argc, argv)
int   argc;
unsigned char  *argv[];
{
   if (argc == 2)
      mycli_id = atoi(argv[1]);
   sprintf(work, "Raw:0/%d/639/%d/MyCli[%d]", (mycli_id-1)*8, 199-(mycli_id-1)*16, mycli_id);
   mycli_infp = Open(work, MODE_NEWFILE);
   if (mycli_infp == 0) {
      printf("Can't open window\n");
      exit(1);
      }
   mycli_outfp = mycli_infp;
   sprintf(work, "%c[80uMyCli\nProgrammed By Mike Schwartz\n(C)1985 MS Software, all rights reserved!\n\n", 0x1b);
   WriteWork();

   current_directory[0] = '\0';
   cd("df0:");
   setprompt("$_$r  $d  $n  $p  $r  $t  $n$_>");
   batchfile("df0:autoexec.bat");

   while (1) {
      showprompt();
      getcommand(buf);
      CommandInterpreter(buf);
      }
   }

WriteWork() {
   Write(mycli_outfp, work, strlen(work));
   }

/*
 * Declaring fh as a local in this routine, batch files may be nested
 * as deep as the stack and memory will allow.
 */
batchfile(batchname)
unsigned char  *batchname;
{
   int      i;
   struct   FileHandle  *fh;

   fh = Open(batchname, MODE_OLDFILE);
   if (fh != 0) {
      while (1) {
         for (i = 0; ; i++) {
            if (Read(fh, &buf[i], 1) == 0) {
               buf[i] = '\0';
               showprompt();
               sprintf(work, "%s\n", buf);
               WriteWork();
               CommandInterpreter(stpblk(buf));
               Close(fh);
               return !0;
               }
            if (buf[i] == 0x0a)
               break;
            }
         buf[i] = '\0';
         showprompt();
         sprintf(work, "%s\n", buf);
         WriteWork();
         CommandInterpreter(stpblk(buf));
         }
      }
   else
      return 0;
   }

CommandInterpreter(command)
unsigned char  *command;
{
   int   i;

   command = stpblk(command);
   /*
    * Scan through the command table for the string and invoke the function
    *    to do the actual work of the command.  Each of these commands is
    *    defined below, and the functions each take a pointer to the
    *    string containing the arguments passed the command line.
    */
   for (i=0; command_table[i].cmdname[0] != '\0'; i++)
      if (
         strncmp(command,
              command_table[i].cmdname,
              strlen(command_table[i].cmdname))
               == 0) {
         (*command_table[i].cmdfunc)
            (stpblk(&command[strlen(command_table[i].cmdname)]));
         goto FinishedCommand;
         }
   /*
    * Not found, so look for it on the disk.
    */
   executive(stpblk(&command[0]));
FinishedCommand:
   }

executive(s)
unsigned char  *s;
{
   struct   FileLock *fl;
   unsigned char     *pc;

   /*
    * get the first token off of the command line into work.
    */
   pc = work;
   while ((*pc = *s) != ' ' && *pc != '\0') {
      pc++;
      s++;
      }
   *pc = '\0';
   strcpy(work2, work);       /* save first token in work2 */

   /*
    * check for MyCLI batch file invocation.
    */
   strcat(work, ".bat");
   fl = Lock(work, ACCESS_READ);
   if (fl != 0) {             /* MyCLI batch file exists */
      UnLock(fl);             /* free the lock obtained */
      batchfile(work);        /* execute the batch file */
      goto execfini;          /* done our work */
      }
   /*
    * skip forward to 1st argument.  This is what is passed as arguments
    * to the executed cli batch file or amigados program to be invoked.
    */
   s = stpblk(s);
   /*
    * .cli files are batch files to be run by the
    * standard cli, using the execute command.
    */
   strcpy(work, work2);       /* preserve the first token again */
   strcat(work2, ".cli");
   fl = Lock(work2, ACCESS_READ);
   if (fl == 0)               /* cli batch file doesn't exist */
      strcpy(work2, work);    /* restore first token */
   UnLock(fl);                /* free the lock obtained */
   if (*s != '\0') {          /* parameters are to be passed */
      strcat(work2, " ");     /* add a space */
      strcat(work2, s);       /* and the parameters */
      }
   if (!Execute(work2, 0, mycli_outfp))
      doserr();
execfini:
   }

doserr() {
   sprintf(buf, "%d", IoErr());
   whatis(buf);
   }

capture(s)
unsigned char  *s;
{
   if (!modem_online) {
      sprintf(work, "%c[36mCapture Error: not online%c[0m\n", 0x1b, 0x1b);
      WriteWork();
      }
   else if (capturing_file) {
      Close(capture_fp);
      sprintf(work, "%c[36mCapture Completed%c[0m\n", 0x1b, 0x1b);
      WriteWork();
      capturing_file = 0;
      }
   else {
      capture_fp = Open(s, MODE_NEWFILE);
      if (capture_fp == 0)
         doserr();
      else {
         capturing_file = !0;
         sprintf(work,
                 "%c[36mCapturing File - capture again to terminate%c[0m\n",
                 0x1b, 0x1b);
         WriteWork();
         }
      }
   }

cd(s)
unsigned char  *s;
{
   int   i;

   strcpy(temp, current_directory);
   if (*s == '\0') {
      sprintf(work, "%-30s\n", current_directory);
      WriteWork();
      }
   else {
      if (*s == '/') {
         s++;
         for (i=strlen(current_directory);
              current_directory[i] != '/' && current_directory[i] != ':';
              i--);
         current_directory[i+1] = '\0';
         strcat(current_directory, s);
         }
      else if (stpchr(s, ':') == 0) {
         if (current_directory[strlen(current_directory)-1] != ':')
            strcat(current_directory, "/");
         strcat(current_directory, s);
         }
      else
         strcpy(current_directory, s);
      worklock = Lock(current_directory, ACCESS_READ);
      if (worklock == 0) {
         doserr();
         strcpy(current_directory, temp);
         }
      else if (Examine(worklock, &fib)) {
         if (fib.fib_DirEntryType > 0) {
            worklock = CurrentDir(worklock);
            if (worklock != 0)
               UnLock(worklock);
            }
         else {
            sprintf(work, "%c[36mCD Error: not a directory (%d) %c[0m\n",
                    0x1b, fib.fib_DirEntryType, 0x1b);
            WriteWork();
            strcpy(current_directory, temp);
            }
         }
      else
         doserr();
      }
   }

copy(s)
unsigned char  *s;
{
   unsigned    char  *pc;
   struct      FileHandle  *copyin;
   struct      FileHandle  *copyout;
   int         iosize;
   int         actual;
   unsigned    char        *copybuf;

   if (strncmp(s, "from", 4) == 0)
      s = stpblk(&s[4]);
   for (pc = s; !isspace(*pc); pc++);
   *pc++ = '\0';
   pc = stpblk(pc);
   if (strncmp(pc, "to", 2) == 0)
      pc = stpblk(&pc[2]);

/*  printf("copy from %s to %s\n", s, pc);  */
   /*
    * check from filename for console.
    */
   if (strncmp(s, "con:", 4) == '*')
      copyin = mycli_infp;
   else
      copyin = Open(s, MODE_OLDFILE);
   if (copyin == 0)
      doserr();
   /*
    * second parameter
    */
   else {
      /*
       * console device?
       */
      if (strncmp(pc, "con:", 4) == 0)
         copyout = mycli_outfp;
      /*
       * no second parameter?
       */
      else if (*pc == '\0') {
         /*
          * separate filename from path specification/filename
          * or device:path/filename or simple filename
          * in from field.
          */
         pc = &s[strlen(s)-1];   /* end of string */
         while (pc != s && *pc != ':' && *pc != '/')
            pc--;
         /*
          * build an appropriate file specification for output
          * file.
          */
         strcpy(work, current_directory);
         /*
          * from device:filespec?
          */
         if (*pc == ':') {
            pc++;
            strcat(work, pc);
            }
         else {
            strcat(work, "/");
            /*
             * don't want //
             */
            if (*pc == '/')
               pc++;
            strcat(work, pc);
            }
/*  printf("Openning %s for output\n", work);  */
         copyout = Open(work, MODE_NEWFILE);
         }
      else {
/*  printf("Openning %s for output\n", pc);  */
        copyout = Open(pc, MODE_NEWFILE);
         }
      if (copyout == 0) {
         doserr();
         Close(copyin);
         }
      else {
         /*
          * here is how to determine the length of a
          * file.  This is the most desirable Amount
          * to read from the from file, because it
          * requires one head seek, and allows the
          * entire track buffer to be used for the
          * read.
          */
         iosize = Seek(copyin, 0, OFFSET_END);
         iosize = Seek(copyin, 0, OFFSET_BEGINING);

         /*
          * maybe there isn't enough memory to hold
          * the entire from file.  the following
          * algorithm determines whether 1/2 the
          * file file, 1/4, 1/8, etc., will fit
          * in memory at a time.  if 512 bytes can't
          * be allocated, then there is not enough
          * memory to do the copy at all.
          */
         do {
            copybuf = AllocMem(iosize, MEMF_PUBLIC|MEMF_CLEAR);
            if (copybuf == 0)
               iosize = iosize/2;
            }
         while (copybuf == 0 & iosize > 512);
         if (copybuf == 0) {
            sprintf(work,
                    "%c[36mCopy Error: Not Enough Memory%c[0m\n",
                    0x1b, 0x1b);
            WriteWork();
            }
         else
            do {
               actual = Read(copyin, copybuf, iosize);
               if (Write(copyout, copybuf, actual) != actual) {
                  doserr();
                  break;
                  }
               }
            while (actual == iosize);
         if (copyin != mycli_infp)
            Close(copyin);
         if (copyout != mycli_outfp)
            Close(copyout);
         FreeMem(copybuf, iosize);
         }
      }
   }

date(s)
unsigned char  *s;
{
   struct   DateStamp   dss;

   DateStamp(&dss);
   dates(work, &dss);
   strcat(work, "\n");
   WriteWork();
   }

define_function_key(s)
unsigned char  *s;
{
   int   i;

   if (s[0] == '\0')
      for (i=0; i<20; i++) {
         if (function_key_definitions[i]) {
            sprintf(work, "F%-2d = %s\n", i+1, function_key_definitions[i]);
            WriteWork();
            }
         }
   else if (s[0] == 'f' || s[0] == 'F') {
      s++;
      i = atoi(s);
      if (i < 1 || i > 20) {
         sprintf(work, "%c[36mInvalid function key%c[0m\n", 0x1b, 0x1b);
         WriteWork();
         }
      else {
         i--;
         if (function_key_definitions[i])
            FreeMem(function_key_definitions[i], strlen(function_key_definitions[i])+1);
         while (isdigit(*s))
            s++;
         s = stpblk(s);
         if (*s != '\0') {
            function_key_definitions[i] = AllocMem(strlen(s)+1, MEMF_PUBLIC|MEMF_CLEAR);
            if (function_key_definitions[i] == 0) {
               sprintf(work, "%c[36mDefine Error: not enough memory%c[0m\n",
                        0x1b, 0x1b);
               WriteWork();
               }
            else
               strcpy(function_key_definitions[i], s);
            }
         }
      }
   else {
      sprintf(work,
              "%c[36mDefine Error: invalid function key specified%c[0m\n",
              0x1b, 0x1b);
      WriteWork();
      }
   }

delete(s)
unsigned char  *s;
{
   if (!DeleteFile(s))
      doserr();
   }

dir(s)
unsigned char  *s;
{
   int   filecount, bytecount, blockcount, dircount;

   filecount = bytecount = blockcount = dircount = 0;

   if (*s == '\0')
      strcpy(work, current_directory);
   else
      strcpy(work, s);
   worklock = Lock(work, ACCESS_READ);
   if (worklock == 0)
      doserr();
   else {
      if (!Examine(worklock, &fib))
         doserr();
      else {
         sprintf(buf, "\nDirectory of %s\n", work);
         Write(mycli_outfp, buf, strlen(buf));
         if (!Info(worklock, &disk_info))
            doserr();
         else {
            sprintf(work,
"%c[7m    Unit: %2d Errors: %3d  BlockSize: %3d Blocks: %4d  Blocks Used: %4d    %c[0m\n",
               0x1b,
               disk_info.id_UnitNumber,
               disk_info.id_NumSoftErrors,
               disk_info.id_BytesPerBlock,
               disk_info.id_NumBlocks,
               disk_info.id_NumBlocksUsed,
               0x1b);
            WriteWork();
            }
         sprintf(work,
          "%c[7m%-30s Prot  Size  Blocks Comment                   %c[0m\n",
          0x1b, "FileName", 0x1b);
         WriteWork();
         if (fib.fib_DirEntryType < 0) {
            showfib();
            if (fib.fib_DirEntryType > 0)
               dircount++;
            else
               filecount++;
            bytecount += fib.fib_Size;
            blockcount += fib.fib_NumBlocks;
            }
         else
            while(ExNext(worklock, &fib)) {
               showfib();
               if (fib.fib_DirEntryType > 0)
                  dircount++;
               else
                  filecount++;
               bytecount += fib.fib_Size;
               blockcount += fib.fib_NumBlocks;
               if (!pause())
                  break;
               }
         sprintf(work, "%c[7m%3d Subdirectories %3d Files %7d Bytes %6d Blocks %7d Bytes Free %c[0m\n",
            0x1b,
            dircount, filecount, bytecount, blockcount,
            (disk_info.id_NumBlocks - disk_info.id_NumBlocksUsed) *
                                             disk_info.id_BytesPerBlock,
            0x1b);
         WriteWork();
         UnLock(worklock);
         }
      }
   }

showfib() {
   sprintf(work, "%-30s ", fib.fib_FileName);
   WriteWork();
   if (fib.fib_DirEntryType > 0) {
      sprintf(work, "SubDirectory       ");
      WriteWork();
      }
   else {
      sprintf(work, "%c%c%c%c %6d %6d ",
            (fib.fib_Protection&FIBF_READ) ? ' ' : 'R',
            (fib.fib_Protection&FIBF_WRITE) ? ' ' : 'W',
            (fib.fib_Protection&FIBF_EXECUTE) ? ' ' : 'E',
            (fib.fib_Protection&FIBF_DELETE) ? ' ' : 'D',
            fib.fib_Size,
            fib.fib_NumBlocks);
      WriteWork();
      }
   sprintf(work, "%s\n", fib.fib_Comment);
   WriteWork();
   }

endcli(s)
unsigned char  *s;
{
   if (modem_online) {
      sprintf(work, "%c[36mTerminal Mode Error: Modem still online%c[0m\n",
              0x1b, 0x1b);
      WriteWork();
      }
   else {
      Close(mycli_outfp);
      exit(0);
      }
   }

help(s)
unsigned char  *s;
{
   int   i;

   sprintf(work,
           "%c[7m          MyCli Help          %c[0m\n", 0x1b, 0x1b);
   WriteWork();
   for (i=0; help_messages[i]; i++) {
      sprintf(work, "%s\n", help_messages[i]);
      WriteWork();
      if (!pause())
         break;
      }
   sprintf(work, "%c[7m          End of Help         %c[0m\n", 0x1b, 0x1b);
   WriteWork();
   }

md(s)
unsigned char  *s;
{
   worklock = CreateDir(s);
   if (worklock == 0)
      doserr();
   else
      UnLock(worklock);
   }

newcli(s)
unsigned char  *s;
{
   sprintf(work, "run mycli %d", mycli_id+1);
   if (!Execute(work, 0, mycli_outfp))
      doserr();
   }

offline(s)
unsigned char  *s;
{
   modem_online = 0;
   }

rename(s)
unsigned char  *s;
{
   unsigned char  *pc;

   for (pc = s; !isspace(*pc); pc++);
   *pc++ = '\0';
   pc = stpblk(pc);
   if (strncmp(pc, "to", 2) == 0)
      pc = stpblk(&pc[2]);
   if (!Rename(s, pc))
      doserr();
   }

setcomment(s)
unsigned char  *s;
{
   unsigned char  *pc;

   for (pc = s; *pc != ' ' && *pc != '\t' && *pc != '\0'; pc++);
   *pc++ = '\0';
   pc = stpblk(pc);
   if (!SetComment(s, pc))
      doserr();
   }

setprompt(s)
unsigned char  *s;
{
   if (prompt_string != 0)
      FreeMem(prompt_string, strlen(prompt_string)+1);
   prompt_string = AllocMem(strlen(s)+1, MEMF_PUBLIC|MEMF_CLEAR);
   if (prompt_string == 0) {
      sprintf(work, "AllocMem failed\n");
      WriteWork();
      prompt_string = 0;
      }
   strcpy(prompt_string, s);
   }

showprompt() {
   unsigned char     *pc;
   struct   DateStamp   dss;

   if (prompt_string == 0) {
      sprintf(work, "MyCli rev. 1.00\n");
      WriteWork();
      }
   else {
      pc = prompt_string;
      while (1) {
         switch(*pc) {
            case '\0':
               break;
            case '$':
               pc++;
               switch(*pc) {
                  case '\0':
                     continue;
                  case 'd':
                  case 'D':
                     DateStamp(&dss);
                     dates(work, &dss);
                     WriteWork();
                     break;
                  case 't':
                  case 'T':
                     DateStamp(&dss);
                     times(work, &dss);
                     WriteWork();
                     break;
                  case 'v':
                  case 'V':
                     sprintf(work, "MyCli rev. 1.00");
                     WriteWork();
                     break;
                  case 'p':
                  case 'P':
                     sprintf(work, "%s", current_directory);
                     WriteWork();
                     break;
                  case 'r':         /* reverse video */
                  case 'R':
                     sprintf(work, "%c[7m", 0x1b);
                     WriteWork();
                     break;
                  case 'n':         /* normal video */
                  case 'N':
                     sprintf(work, "%c[0m", 0x1b);
                     WriteWork();
                     break;
                  case '_':
                     strcpy(work, "\n");
                     WriteWork();
                     break;
                  }
               pc++;
               continue;
            default:
               sprintf(work, "%c", *pc++);
               WriteWork();
               continue;
            }
         break;
         }
      }
   }

TerminalMode(s)
unsigned char  *s;
{
   modem_online = !0;      /* signal that modem is live !!! */
   if (initialize()) {     /* set baud rate, etc. */
      Write(mycli_outfp, WelcomeMessage, strlen(WelcomeMessage));
      while (modem_online) {
         bdoneflag = 0;    /* terminal mode on flag */
         Write(mycli_outfp, OnlineMessage, strlen(OnlineMessage));
         while (!bdoneflag) {
            check_keyboard();
            check_modem();
            }
         Write(mycli_outfp, OfflineMessage, strlen(OfflineMessage));
         showprompt();
         getcommand(buf);
         CommandInterpreter(buf);
         }
      cleanup();
      }
   modem_online = 0;
   }

time(s)
unsigned char  *s;
{
   struct   DateStamp   dss;

   DateStamp(&dss);
   times(work, &dss);
   strcat(work, "\n");
   WriteWork();
   }

type(s)
unsigned char  *s;
{
   int   len, len2;
   unsigned char c;

   workfp = Open(s, MODE_OLDFILE);
   if (workfp == 0)
      doserr();
   else {
      do {
         len = Read(workfp, buf, 512);
         for (len2 = 0; len2 < len; len2++) {
            Write(mycli_outfp, &buf[len2], 1);
            if (modem_online) {
               rs_out[0] = buf[len2];
               DoIO(ModemWriteRequest);
               if (!TermEcho) {        /* characters will be echoed back */
                  WaitIO(ModemReadRequest); /* get the echoed character */
                  c = rs_in[0];
                  BeginIO(ModemReadRequest);
                  }
               }
            if (!pause()) {
               len = 0;
               break;
               }
            }
         }
         while (len == 512);
      sprintf(work, "\n%c[36m*** End of File%c[0m\n", 0x1b, 0x1b);
      WriteWork();
      Close(workfp);
      }
   }

whatis(s)
unsigned char  *s;
{
   int   errorcode;
   int   i;

   if (*s < '0' || *s > '9') {
      sprintf(work, "Invalid errorcode specified\n");
      WriteWork();
      }
   else {
      errorcode = atoi(s);
      if (errorcode) {
         for (i=0; errorcodes[i].code; i++)
            if (errorcodes[i].code == errorcode)
               break;
         if (errorcodes[i].code == errorcode)
            strcpy(work, errorcodes[i].message);
         else
            strcpy(work, "undocumented AmigaDos error code");
         sprintf(buf, "%c[36mAmigaDos Error %d: %s%c[0m\n", 0x1b, errorcode,
                 work, 0x1b);
         Write(mycli_outfp, buf, strlen(buf));
         }
      }
   }

/*
 * get the date and make it into a printable string
 */
unsigned char  *months[12] = {
   "January", "Febuary", "March", "April", "May", "June",
   "July", "August", "September", "October", "November", "December"
   };

UBYTE dayspermonth1[12] = {   /* leap years */
   31, 29, 31, 30, 31, 30,
   31, 31, 30, 31, 30, 31
   };

UBYTE dayspermonth2[12] = {   /* non leap years */
   31, 28, 31, 30, 31, 30,
   31, 31, 30, 31, 30, 31
   };

dates(s, dss)
unsigned char  *s;
struct DateStamp *dss;
{
   int   year;
   int   month;
   int   day;

   year = 1978;
   day = dss->ds_Days;
   while (day >= 366) {
      if ( (year-1976) % 4 == 0) {
         day -= 366;
         year++;
         }
      else if ( (year-1976) % 4 != 0 && day >= 365) {
         day -= 365;
         year++;
         }
      }
   if ( (year-1976) % 4 == 0) {
      day = day % 366;
      for (month = 0; day > dayspermonth1[month]; month++)
         day -= dayspermonth1[month];
      }
   else {
      day = day % 365;
      for (month = 0; day > dayspermonth2[month]; month++)
         day -= dayspermonth2[month];
      }
   sprintf(s, "%s %d, %d", months[month], day+1, year);
   }

times(s, dss)
unsigned char  *s;
struct DateStamp *dss;
{
   int   hours, minutes, seconds;

   seconds = dss->ds_Tick / 50;
   seconds %= 60;
   minutes = dss->ds_Minute;
   hours = minutes / 60;
   minutes %= 60;
   if (hours == 0)
      hours = 24;
   sprintf(s, "%d:%02d:%02d.%d ", (hours>12)?hours-12:hours, minutes,
           seconds, (dss->ds_Tick % 50)*2);
   if (hours < 12)
      strcat(s, "in the morning");
   else if (hours == 12)
      strcat(s, "noon");
   else if (hours < 19)
      strcat(s, "in the afternoon");
   else if (hours < 21)
      strcat(s, "in the evening");
   else if (hours == 24)
      strcat(s, "midnight");
   else
      strcat(s, "at night");
   }

unsigned char  scr_csts() {
   unsigned char inbuf[2];

   if (WaitForChar(mycli_infp, 1) == 0)
      return 0;
   Read(mycli_infp, &inbuf[0], 1);
   return inbuf[0];
   }

pause() {
   unsigned char inbuf[2];

   switch(scr_csts()) {
      case ' ':
         while ((inbuf[0] = scr_csts()) != ' ')
            if (inbuf[0] == 0x1b) {
               return 0;
               }
         return !0;
      case 0x1b:
         return 0;
      default:
         return !0;
      }
   }

getcommand(s)
unsigned char  *s;
{
   unsigned char  c;
   unsigned col;

   col = 0;
   while (1) {
      Read(mycli_infp, &c, 1);
      switch(c) {
         case 8:
            if (col) {
               c = 8;
               Write(mycli_outfp, &c, 1);
               c = ' ';
               Write(mycli_outfp, &c, 1);
               c = 8;
               Write(mycli_outfp, &c, 1);
               col--;
               }
            continue;
         case 10:
         case 13:
            sprintf(work, "\n");
            WriteWork();
            s[col++] = '\0';
            break;
         case 0x1b:
         case 24:
            while (col) {
               c = 8;
               Write(mycli_outfp, &c, 1);
               c = ' ';
               Write(mycli_outfp, &c, 1);
               c = 8;
               Write(mycli_outfp, &c, 1);
               col--;
               }
            continue;
         case 0x9b:
            if (process_event(&s[col])) {
               strcat(s, "\n");
               Write(mycli_outfp, &s[col], strlen(&s[col]));
               break;
               }
            continue;
         default:
            s[col++] = c;
            Write(mycli_outfp, &c, 1);
            continue;
         }
      break;
      }
   }

/*
 * this function converts an incoming ANSI escape sequence
 * and processes it.  A buffer is passed where any function
 * key expansion is to take place. If the buffer is modified
 * for any reason, this function returns true.
 */
process_event(cmd_line)
unsigned char  *cmd_line;
{
   int   i;
   unsigned char  c;
   char  event_buffer[32];

   i = 0;
   while (1) {
      Read(mycli_infp, &c, 1);
      event_buffer[i] = c;
      if (c == '~' || c == '|')
         break;
      i++;
      }
   event_buffer[i+1] = '\0';
   if (event_buffer[i] == '~') {
      if (event_buffer[0] == '?') {
         strcpy(cmd_line, "help");
         return !0;
         }
      else if (isdigit(event_buffer[0])) {
         if (function_key(atoi(event_buffer), cmd_line))
            return !0;
         }
      }
   return 0;
   }

/*
 * if a definition for the function key fkey exists (0-19), then
 * the translation for the function key is copied to the string
 * s, and this function returns !0.  Otherwise, now translation
 * exists, and this function returns 0.
 */
function_key(fkey, s)
int   fkey;
unsigned char  *s;
{
   int   i;

   if (function_key_definitions[fkey] != 0) {
      for (i=0; function_key_definitions[fkey][i] != '\0'; i++)
         s[i] = function_key_definitions[fkey][i];
      s[i] = '\0';
      return !0;
      }
   return 0;
   }

initialize() {
   ModemReadRequest = (struct IOExtSer *)AllocMem(sizeof(*ModemReadRequest),
                      MEMF_PUBLIC | MEMF_CLEAR);
   ModemReadRequest->io_SerFlags = SERF_SHARED | SERF_XDISABLED;
   ModemReadRequest->IOSer.io_Message.mn_ReplyPort =
                                            CreatePort("Read_RS",0);
   if (OpenDevice(SERIALNAME, NULL, ModemReadRequest, NULL)) {
      sprintf(work, "%c[36mCan't open serial read device%c[0m\n",
              0x1b, 0x1b);
      WriteWork();
      DeletePort(ModemReadRequest->IOSer.io_Message.mn_ReplyPort);
      FreeMem(ModemReadRequest, sizeof(*ModemReadRequest));
      return 0;
      }
   ModemReadRequest->IOSer.io_Command = CMD_READ;
   ModemReadRequest->IOSer.io_Length = 1;
   ModemReadRequest->IOSer.io_Data = (APTR) &rs_in[0];

   ModemWriteRequest = (struct IOExtSer *)AllocMem(sizeof(*ModemWriteRequest),
                      MEMF_PUBLIC | MEMF_CLEAR);
   ModemWriteRequest->io_SerFlags = SERF_SHARED | SERF_XDISABLED;
   ModemWriteRequest->IOSer.io_Message.mn_ReplyPort =
                                                  CreatePort("Write_RS",0);
   if (OpenDevice(SERIALNAME, NULL, ModemWriteRequest, NULL)) {
      sprintf(work, "%c[36mCan't open serial write device%c[0m\n",
              0x1b, 0x1b);
      WriteWork();
      DeletePort(ModemReadRequest->IOSer.io_Message.mn_ReplyPort);
      FreeMem(ModemReadRequest, sizeof(*ModemReadRequest));
      DeletePort(ModemWriteRequest->IOSer.io_Message.mn_ReplyPort);
      FreeMem(ModemWriteRequest, sizeof(*ModemWriteRequest));
      return 0;
      }
   ModemWriteRequest->IOSer.io_Command = CMD_WRITE;
   ModemWriteRequest->IOSer.io_Length = 1;
   ModemWriteRequest->IOSer.io_Data = (APTR) &rs_out[0];

   ModemReadRequest->io_SerFlags = SERF_SHARED | SERF_XDISABLED;
   ModemReadRequest->io_Baud = 1200;
   ModemReadRequest->io_ReadLen = 8;
   ModemReadRequest->io_WriteLen = 8;
   ModemReadRequest->io_CtlChar = 1L;
   ModemReadRequest->IOSer.io_Command = SDCMD_SETPARAMS;
   DoIO(ModemReadRequest);
   ModemReadRequest->IOSer.io_Command = CMD_READ;
   BeginIO(ModemReadRequest);
   return !0;
   }

cleanup() {
   CloseDevice(ModemReadRequest);
   DeletePort(ModemReadRequest->IOSer.io_Message.mn_ReplyPort);
   FreeMem(ModemReadRequest, sizeof(*ModemReadRequest));

   CloseDevice(ModemWriteRequest);
   DeletePort(ModemWriteRequest->IOSer.io_Message.mn_ReplyPort);
   FreeMem(ModemWriteRequest, sizeof(*ModemWriteRequest));

   Write(mycli_outfp, GoodbyeMessage, strlen(GoodbyeMessage));
   }

check_keyboard() {
   unsigned char  *pc;

   if (WaitForChar(mycli_infp, 1)) {
      Read(mycli_infp, &rs_out[0], 1);
      switch ((unsigned char)rs_out[0]) {
         case 0x03:                          /* escape to command mode */
            bdoneflag = !0;
            break;
         case 0x9b:                          /* ANSI keyboard stuff */
            if (process_event(&buf[0])) {    /* send the translation */
               pc = &buf[0];
               while (*pc != '\0') {
                  rs_out[0] = *pc++;
                  if (TermEcho)
                     Write(mycli_outfp, &rs_out[0], 1);
                  DoIO(ModemWriteRequest);
                  check_modem();
                  }
               rs_out[0] = '\n';
               if (TermEcho)
                  Write(mycli_outfp, &rs_out[0], 1);
               DoIO(ModemWriteRequest);
               rs_out[0] = '\r';
               DoIO(ModemWriteRequest);
               }
            break;
         case 0x05:                    /* toggle keystroke echo */
            TermEcho = !TermEcho;
            sprintf(work, "%c[36mEcho %s%c[0m\n", 0x1b, TermEcho?"ON":"OFF",
                      0x1b);
            WriteWork();
            break;
         default:
            if (TermEcho)
               Write(mycli_outfp, &rs_out[0], 1);
            DoIO(ModemWriteRequest);
         }
      }
   }

/*
 * Check to see of the Read Request IO has completed from the modem.
 */
check_modem() {
   if (CheckIO(ModemReadRequest)) {
      WaitIO(ModemReadRequest);
      rs_in[0] &= 0x7f;
      Write(mycli_outfp, &rs_in[0], 1);
      if (capturing_file)
         Write(capture_fp, &rs_in[0], 1);
      BeginIO(ModemReadRequest);
      }
   }

