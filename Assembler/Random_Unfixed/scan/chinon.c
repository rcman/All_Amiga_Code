/***********************************************************************
 *
 *  DISPLAY Chinon images    by Sean Godsell
 *
 ***********************************************************************/

#include <stdio.h>
#include <exec/types.h>
#include <intuition/intuition.h>
#include <intuition/intuitionbase.h>
#include <functions.h>


#undef   NULL
#define   NULL   ((void *)0)

struct   GfxBase           *GfxBase;
struct   IntuitionBase     *IntuitionBase;
struct   RastPort          *rp;
struct   ViewPort          *vp;
struct   BitMap            *bitm;
struct   Window            *w;
struct   Screen            *screen;
struct   IntuiMessage      *message;
struct   NewScreen   ns =  {
            0L,0L,640L,400L,4L,
            0,1,LACE,
            CUSTOMSCREEN,NULL,
            (UBYTE *)"Page Scanner - By Sean Godsell",
            NULL,NULL
            };
struct   NewWindow   nw =  {
            0L,0L,640L,400L,0L,1L,
            MOUSEBUTTONS|CLOSEWINDOW,
            ACTIVATE|WINDOWCLOSE|BORDERLESS,
            NULL,NULL,
            (UBYTE *)"Page Scanner - By Sean Godsell",
            NULL,NULL,
            0L,0L,640L,400L,CUSTOMSCREEN 
            };

FILE      *fp = NULL;
unsigned  char   line[128];
int       maxx,maxy,maxc;
int       cpix,cr,cg,cb,count,pos;
char      *bitp1;
 
main()
    {
    unsigned long class;
    unsigned short code;
    int       i,x,y,val,bflg;

    GfxBase = (struct GfxBase *)OpenLibrary("graphics.library",0L);
    if (GfxBase == NULL) exit(100);

    IntuitionBase = 
          (struct IntuitionBase *)OpenLibrary("intuition.library",0L);

    if (IntuitionBase == NULL) {
          CloseLibrary(GfxBase);
          exit(200);
          }

    screen = (struct Screen *)OpenScreen(&ns);
    if (screen == NULL) {
          CloseLibrary(IntuitionBase);
          CloseLibrary(GfxBase);
          exit(300);
           }

    nw.Screen = screen;
    w         = (struct Window *)OpenWindow(&nw);

    if (w == NULL) {
             CloseScreen(screen);
             CloseLibrary(IntuitionBase);
             CloseLibrary(GfxBase);
             exit(400);
             }

    vp    = &screen->ViewPort;
    rp    = w->RPort;
    bitm  = &screen->BitMap;
    bitp1 = bitm->Planes[0];

    for(i=1600;i<8000;i++)
          *bitp1++=0xAA;

    if (x < 640 && y < 400) {
             /* SetAPen(rp,(long)(cpix & 0x3F));*/
             WritePixel(rp,(long)x,(long)y);
             }




    /* wait here until we get a close window message */
    while (1)
          {
           WaitPort(w->UserPort);
           while ((message=(struct IntuiMessage *)GetMsg(w->UserPort))!=NULL)
                 {
                 class   = message->Class;
                 code    = message->Code;
                 ReplyMsg(message);

                 if (class == CLOSEWINDOW) error(NULL);
                 }
          }

   }



error(msg)
char *msg;
    {
    if (msg) {
   puts("ERROR: ");
   puts(msg);
   puts("\n");
   }
    CloseWindow(w);
    CloseScreen(screen);
    CloseLibrary(IntuitionBase);
    CloseLibrary(GfxBase);
    if (fp != NULL && fp != stdin) fclose(fp);
    if (msg) exit(-1);
    else     exit(0);
    }

