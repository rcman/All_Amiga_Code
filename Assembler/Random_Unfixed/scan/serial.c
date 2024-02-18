#include <exec/types.h>
#include <exec/nodes.h>
#include <exec/lists.h>
#include <exec/ports.h>
#include <exec/libraries.h>
#include <exec/devices.h>
#include <exec/io.h>
#include <devices/serial.h>

#define MEMF_PUBLIC 0x10000
#define MEMF_CLEAR 1

struct IOExtSer *IORser;
struct MsgPort *port;
char buffer[200];
extern struct MsgPort *CreatePort();
extern unsigned char *AllocMem();

extern struct IORequest *CreateStdIO();


main()
	{
	int error;
	int actual;
	unsigned long rbl;
	unsigned long brk;
	unsigned long baud;
	unsigned char rwl;
	unsigned char wwl;
	unsigned char sf;
	unsigned long t0;
	unsigned long t1;

	port=CreatePort(SERIALNAME,0);
	if (port==NULL) {
		printf("\nProblems during CreatePort");
		exit(100);
		}

	IORser=(struct IOExtSer *)CreateStdIO(port,sizeof(struct IOExtSer));

/*	IORser=(struct IOExtSer *)AllocMem(400,
		(long) MEMF_PUBLIC|MEMF_CLEAR);
	IORser->io_SerFlags = SERB_SHARED | SERB_XDISABLED; 
	IORser->IOSer.io_Message.mn_ReplyPort = port;
*/
	if (IORser == NULL)
		{
		printf("\nProblems during CreateExtIO");
		goto cleanup1;
		}

open:

	if ((error = OpenDevice(SERIALNAME,0,IORser,0)) != 0)  {
		printf("Serial device did not open, error = %ld\n",error);
		goto cleanup1;
		}

	rbl=4096;
	rwl=0x08;
	wwl=0x08;
	brk=750000;
	baud=2400;
	sf=0x00;
	t0=0x51040303;
	t1=0x03030303;

        printf("Gonna Set the Params\n");

	if ((error=SetParams(IORser,rbl,rwl,wwl,brk,baud,sf,t0,t1))!=0)  {
		printf("Set Parameters command returned an error: %ld",error);
		goto cleanup2;
		}

	printf("\nSerial Device opened and accepted parameters\n");

/*	WriteSer(IORser,"\n\0115Device opened ok\n\0115",-1);
*/
        WriteSer(IORser,"\33I\n",3);

	printf("\nTesting character exact-count output thru SendWaitWrite");
	SendWaitWrite(IORser,
		"User counts characters in string to send\n\015",-1);

	printf("\nTest string length of -1 (make system find end of string)");
	SendWaitWrite(IORser,
		"or if null terminated string, say '-1'\n\015",-1);

	printf("\nType 16 characters to send to amiga...");
	printf("\nIf no external terminal is attached, waits forever!!");
	WriteSer (IORser,
		"\n\015Typoe 16 characters to send to amiga\n\015",-1);
	actual=ReadSer(IORser,buffer,16);
	WriteSer (IORser,
		"\n\015You typed these printable characters:\n\015",-1);
	WriteSer (IORser,buffer,actual);
	WriteSer (IORser,"\n\015End of test\n\015",-1);
	WriteSer (IORser,"54321....exit\n\015",16);
	printf("\nTest completed!\n");

cleanup2:
	CloseDevice(IORser);
cleanup1:
	DeletePort(port);
	exit(0);

	}


SetParams(io,rbuf_len,rlen,wlen,brk,baud,sf,ta0,ta1)
struct IOExtSer *io;
unsigned long rbuf_len;
unsigned char rlen;
unsigned char wlen;
unsigned long brk;
unsigned long baud;
unsigned char sf;
unsigned long ta0;
unsigned long ta1;

	{
	int error;

	io->io_ReadLen=rlen;
	io->io_BrkTime=brk;
	io->io_Baud=baud;
	io->io_WriteLen=wlen;
	io->io_StopBits=0x01;
	io->io_RBufLen=rbuf_len;
	io->io_SerFlags=sf;
	io->IOSer.io_Command=SDCMD_SETPARAMS;
	io->io_TermArray.TermArray0=ta0;
	io->io_TermArray.TermArray1=ta1;

	if ((error=DoIO(io))!=0) {
		printf("serial.device setparams error %ld\n",error);
		}
	return(error);
	}

ReadSer(io,data,length)
struct IOExtSer *io;
char *data;
ULONG length;
	{
	int error;

	io->IOSer.io_Data=data;
	io->IOSer.io_Length=length;
	io->IOSer.io_Command=CMD_READ;

	if ((error=DoIO(io))!=0)  {
		printf("serial.device read error %ld\n",error);
		}
	return(io->IOSer.io_Actual);
	}

WriteSer(io,data,length)
struct IOExtSer *io;
char *data;
int length;
	{
	int error;

	io->IOSer.io_Data=data;
	io->IOSer.io_Length=length;
	io->IOSer.io_Command=CMD_WRITE;

	if ((error=DoIO(io))!=0)  {
		printf("serial.device write error %ld\n",error);
		}
	return(error);
	}


SendWaitWrite(io,data,length)
struct IOExtSer *io;
char *data;
int length;
	{
	int error;

	io->IOSer.io_Data=data;
	io->IOSer.io_Length=length;
	io->IOSer.io_Command=CMD_WRITE;

	SendIO(io);

	if ((error=WaitIO(io))!=0)  {
		printf("serial.device waitio error %ld\n",error);
		}
	return(io->IOSer.io_Actual);
	}

