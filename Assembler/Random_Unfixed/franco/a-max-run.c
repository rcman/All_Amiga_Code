#include <exec/types.h>
#include <exec/exec.h>
#include <libraries/dos.h>
#include <libraries/dosextens.h>

struct FileHandle *outfp;

main()
   {

   outfp=Output();
   Execute("Execute a-max_startup",0,outfp);


   }
