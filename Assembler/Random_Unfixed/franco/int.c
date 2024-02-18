
   #include<exec/types.h>
   #include<exec/nodes.h>
   #include<exec/lists.h>
   #include<exec/libraries.h>
   #include<exec/io.h>
   #include<exec/memory.h>
   #include<exec/interrupts.h>
   #include<stdio.h>

   struct Interrupt *VertBIntr;
   long count;

   main()
   {
      extern void VertBServer();

      /* allocate an Interrupt node structure: */
      VertBIntr = AllocMem(500,MEMF_PUBLIC);
      /* sizof(struct Interrupt *),MEMF_PUBLIC); */
      if (VertBIntr == 0) {
         printf("not enough memory for interrupt");
         exit(100);
      }

      /* initialize the Interrupt node: */
      VertBIntr->is_Node.ln_Type = NT_INTERRUPT;
      VertBIntr->is_Node.ln_Pri  = -60;
      VertBIntr->is_Node.ln_Name = "Sean Godsell";
      VertBIntr->is_Data = &count;
      VertBIntr->is_Code = VertBServer;

      /* put the new interrupt server into action: */
      AddIntServer (5,VertBIntr);

      while (getchar() != 'q');  /* wait for user to type 'q' */

      RemIntServer (5,VertBIntr);
      printf("%ld vertical blanks occurred",count);
      FreeMem(VertBIntr,sizeof(struct Interrupt *));

   }

