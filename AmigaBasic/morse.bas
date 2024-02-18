       
DIM l$(40),code$(40)

FOR i=1 TO 36:READ l$(i),code$(i):NEXT i


mainloop:
   CLS
   PRINT "Programmed by - Sean Godsell"
   PRINT
   PRINT "Enter 'End Program' to Exit"
   PRINT
   PRINT "Enter a Time Duration (2000-10000)."
   INPUT t:IF t<100 OR t>10000 THEN mainloop
   PRINT
   
   WHILE a$<>"END PROGRAM"
       PRINT "Enter a Sentence."
       INPUT a$: GOSUB upper
       IF a$<>"END PROGRAM" THEN GOSUB morse
   WEND          

   END

upper:
   b$=""
   FOR i=1 TO LEN(a$)
       c$=MID$(a$,i,1):IF c$>="a" AND c$<="z" THEN c$=CHR$(ASC(c$)-32)
       b$=b$+c$
   NEXT i
   a$=b$
   RETURN

morse:
   FOR i=1 TO LEN(a$)
       c$=MID$(a$,i,1)
       GOSUB LookupCode
       GOSUB playcode
   NEXT i
   RETURN

LookupCode:
   j=0 : p$=""
lookit:
   j=j+1
   IF c$<>l$(j) AND j<37 THEN lookit
   p$=code$(j)
   RETURN
   
playcode:
   FOR x=1 TO LEN(p$)
      l=1
      IF MID$(p$,x,1)="-" THEN l=2
      SOUND 1300,l
      FOR u=1 TO t:NEXT u
   NEXT x
   FOR x=1 TO 400:NEXT x
   RETURN


DATA A,".-"
DATA B,"-..."
DATA C,"-.-."
DATA D,"-.."
DATA E,"."
DATA F,"..-."
DATA G,"--."
DATA H,"...."
DATA I,".."
DATA J,".---"
DATA K,"-.-"
DATA L,".-.."
DATA M,"--"
DATA N,"-."
DATA O,"---"
DATA P,".--."
DATA Q,"--.-"
DATA R,".-."
DATA S,"..."
DATA T,"-"
DATA U,"..-"
DATA V,"...-"
DATA W,".--"
DATA X,"-..-"
DATA Y,"-.--"
DATA Z,"--.."
DATA 1,".----"
DATA 2,"..---"
DATA 3,"...--"
DATA 4,"....-"
DATA 5,"....."
DATA 6,"-...."
DATA 7,"--..."
DATA 8,"---.."
DATA 9,"----."
DATA 0,"-----"

