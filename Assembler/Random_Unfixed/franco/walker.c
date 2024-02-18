#include <exec/types.h>
#include <exec/exec.h>
#include <libraries/dos.h>
#include <libraries/dosextens.h>

struct FileHandle *outfp;

main()
   {

   outfp=Output();
   Execute("Execute dh0:s/Walker",0,outfp);


   }
