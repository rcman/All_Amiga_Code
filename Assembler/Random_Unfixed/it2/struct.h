#ifndef DSTRUCT
#define DSTRUCT


struct BUFDATA
{
struct Gadget Gadget1;
struct Gadget Gadget2;
struct Gadget Gadget3;
struct PropInfo Gadget1SInfo;
int    pos;
int    size;
char   buf[1];
};

union STDATA
{
   APTR data;
   struct BUFDATA *bdata;
   struct FileInfoBlock *fib;
   struct FileHandle *fh;
   struct FileLock *lock;
   struct InfoData *info;
};

#define WNAMELEN 20

struct STNODE
{
   struct STNODE *next, *prev;
   int len;              /* Length of this allocation, for convenience   */
   int num;              /* Number of the node within its type           */
   int type;             /* One of the ST_ defines above                 */
   union STDATA d;       /* Points to the mem allocted for the struct    */
   char wname[WNAMELEN]; /* Name of the window                           */
   char *oname;          /* Name of the object associated with it        */
   struct Window *w;     /* Points to the window opened to display it    */
};

struct STGLOB
{
   struct STNODE *stlist;/* Linked list of STNODE structures             */
   struct STNODE *unlist;/* Linked list of unlinked nodes                */
   int count[ST_NUM];    /* How many of each type there are              */
   struct MsgPort *Port; /* Message port to use for comm with Intuition  */
};

#define DOTEXT(y, format, val) \
   sprintf(data, format, val); \
   PrintIText(n->w->RPort, &IText, 0, y);


void stfhnew(struct NewWindow **, struct IntuiText **, struct STNODE *);
void stlocknew(struct NewWindow **, struct IntuiText **, struct STNODE *);
void stfibnew(struct NewWindow **, struct IntuiText **, struct STNODE *);
void stinfnew(struct NewWindow **, struct IntuiText **, struct STNODE *);
void stbufnew(struct NewWindow **, struct IntuiText **, struct STNODE *);


int stfhdisp(struct STNODE *);
int stlockdisp(struct STNODE *);
int stfibdisp(struct STNODE *);
int stinfdisp(struct STNODE *);
int stbufdisp(struct STNODE *);
int stbufmove(struct STNODE *, int);


#endif

