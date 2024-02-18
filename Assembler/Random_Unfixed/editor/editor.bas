DIM text$(1000)

OPEN "com1:9600,n,8,1" AS #1

l=0 : sl=1 :c=0 : r=0 : ins=0

' PRINT #1,CHR$(26);CHR$(13);

'FOR i=1 TO 100
'  a$=STR$(i): IF LEN(a$)=2 THEN a$=" 0"+RIGHT$(a$,1)
'  text$(i)=a$
'NEXT i

GOSUB printdata

mainloop:
  a$=INPUT$(1,1)
'  PRINT sl,l,r,ASC(a$)
  IF a$=CHR$(13) THEN GOSUB newline
  IF a$=CHR$(21) AND c>0 THEN GOSUB goleft
  IF a$=CHR$(6) AND c<79 THEN GOSUB goright
  IF a$=CHR$(10) AND sl+l<999 AND sl+l<r THEN GOSUB godown
  IF a$=CHR$(26) AND l+sl>1 THEN GOSUB goup
  IF a$=CHR$(8) AND c>0 THEN GOSUB backspace
  IF a$=CHR$(127) THEN GOSUB deletetext
  IF a$=CHR$(27) THEN GOSUB checkesc
  IF a$=CHR$(9) THEN ins=ins+1:IF ins>1 THEN ins=0
  IF a$=CHR$(2) THEN c=0:GOSUB printwhereonline
  IF a$=CHR$(5) THEN GOSUB goendofline
'  IF a$=CHR$(4) AND sl+l<999 THEN GOSUB godown10
'  IF a$=CHR$(21) AND sl+l>1 THEN GOSUB goup10

  IF LEN(text$(sl+l))>78 THEN mainloop
  IF a$<CHR$(32) OR c>79 OR a$=CHR$(127) THEN mainloop

  text$(sl+l)=LEFT$(text$(sl+l),c)+a$+MID$(text$(sl+l),(c+1+ins),80)
  c=c+1:tc=c
  IF c>15 THEN tmp=INT(c/10)*6 ELSE tmp=0
  PRINT #1,CHR$(13);text$(sl+l);CHR$(16);CHR$(c+tmp);
  GOTO mainloop


goup:
  flag=0
  sl=sl-1:IF sl<1 THEN sl=1:l=l-1:flag=1:GOSUB printdata
  IF flag=0 THEN PRINT #1,a$;
  printthelines:
  c=tc  
  IF c>LEN(text$(sl+l)) THEN c=LEN(text$(sl+l))
  IF c>15 THEN tmp=INT(c/10)*6 ELSE tmp=0
  PRINT #1,CHR$(16);CHR$(c+tmp);
  RETURN

godown:
  sl=sl+1:IF sl>24 THEN sl=24:l=l+1:PRINT #1,CHR$(10);CHR$(13);text$(sl+l) ELSE PRINT #1,a$;
  GOTO printthelines

goleft:
  IF c<1 THEN RETURN
  c=c-1:tc=c
  PRINT #1,a$;
  RETURN

goright:
  IF c>79 THEN RETURN
  c=c+1
  IF c>LEN(text$(sl+l)) THEN c=LEN(text$(sl+l)) ELSE PRINT #1,a$;
  tc=c
  RETURN
    
backspace:
  text$(sl+l)=LEFT$(text$(sl+l),c-1)+MID$(text$(sl+l),c+1,80)
  c=c-1
  tc=c
  printwhereonline:
  IF c>15 THEN tmp=INT(c/10)*6 ELSE tmp=0
  PRINT #1,CHR$(13);text$(sl+l);" ";CHR$(16);CHR$(c+tmp);
  RETURN

goendofline:
  c=LEN(text$(sl+l)):IF c>78 THEN c=78
  tc=c
  GOTO printwhereonline
  
deletetext:
  tc=c
  text$(sl+l)=LEFT$(text$(sl+l),c)+MID$(text$(sl+l),c+2,80)
  PRINT #1,CHR$(13);text$(sl+l);" ";CHR$(16);CHR$(c+tmp);
  RETURN
  
newline:
  IF ins=1 THEN GOTO skipchop
  t$=MID$(text$(sl+l),c+1,80):text$(sl+l)=LEFT$(text$(sl+l),c)
  FOR i=r+1 TO sl+l+1 STEP -1:text$(i+1)=text$(i):NEXT i
  text$(sl+l+1)=t$
  GOSUB printdata
  GOSUB printlinesto
  skipchop:  
  c=0:tc=c
  r=r+1
  sl=sl+1:IF sl>24 THEN sl=24:l=l+1:PRINT #1,CHR$(10);CHR$(13);text$(sl+l) ELSE PRINT #1,CHR$(10)
  RETURN

checkesc:
  a$=INPUT$(1,1)
  IF a$="4" AND c>0 THEN a$=CHR$(8):GOSUB goleft
  IF a$="6" AND c<79 THEN a$=CHR$(6):GOSUB goright
  IF a$="2" AND sl+l<999 THEN a$=CHR$(10):GOSUB godown
  IF a$="8" AND sl+l>1 THEN a$=CHR$(26):GOSUB goup
  IF a$="1" THEN c=0:a$="":GOTO printwhereonline
  IF a$="3" THEN a$="":GOTO goendofline
  IF a$="D" OR a$="d" AND sl+l<999 THEN GOSUB godown10
  IF a$="U" OR a$="u" AND sl+l>1 THEN GOSUB goup10
  IF a$="L" OR a$="l" THEN loadfile
  IF a$="I" OR a$="i" THEN ins=ins+1:IF ins>1 THEN ins=0 :a$="":RETURN ELSE a$="":RETURN
  IF a$="S" OR a$="s" THEN savefile
  IF a$="Q" OR a$="q" THEN PRINT #1,CHR$(12):SYSTEM
  IF a$="K" OR a$="k" THEN deleteline
  IF a$="T" OR a$="t" THEN gototop
  IF a$="B" OR a$="b" THEN gotobottom
  IF a$<>CHR$(27) THEN checkesc
  RETURN

godown10:
  l=l+12:IF sl+l>r THEN l=r-sl
  GOSUB printdata
  printlinesto:
  c=tc
  PRINT #1,CHR$(11);CHR$(sl+31)
  IF c>15 THEN tmp=INT(c/10)*6 ELSE tmp=0
  PRINT #1,CHR$(13);text$(sl+l);" ";CHR$(16);CHR$(c+tmp);
  IF LEN(text$(sl+l))<c THEN c=LEN(text$(sl+l))
  GOTO printwhereonline

goup10:
  l=l-12:IF l<0 THEN l=0 : sl=sl-12:IF sl<1 THEN sl=1
  GOSUB printdata
  GOTO printlinesto

gototop:
  sl=1:l=0:c=0
  GOSUB printdata
  a$=""
  RETURN

gotobottom:
  IF r<24 THEN sl=r: c=0:GOTO printthis
  sl=24:l=r-23:c=0
printthis:
  GOSUB printdata
  PRINT #1,CHR$(11);CHR$(sl+31)
  a$=""
  RETURN

deleteline:
  IF r=0 OR r<sl+l THEN a$="":RETURN
  FOR i=sl+l TO r
    text$(i)=text$(i+1)
  NEXT i
  r=r-1 :c=0
  GOSUB printdata
  PRINT #1,CHR$(11);CHR$(sl+31)
  a$=""
  RETURN
     
printdata:
  cnt=1
  PRINT #1,CHR$(12);
  FOR i=l+1 TO l+24
    PRINT #1,text$(i);
    cnt=cnt+1
    IF cnt<25 THEN PRINT #1,CHR$(10)
  NEXT i
  PRINT #1,CHR$(1);
  RETURN

loadfile:
  PRINT #1,CHR$(13);CHR$(11);CHR$(29);CHR$(27);"KEnter File Name to Load :";
  GOSUB getfilename
  IF n$="" THEN endload
  OPEN n$ FOR INPUT AS #2
  r=1
readmore:
  LINE INPUT #2,a$:text$(r)=LEFT$(a$,79)
  r=r+1
  IF NOT EOF(2) THEN readmore
  CLOSE #2
endload:
  GOSUB printdata
  PRINT #1,CHR$(11);CHR$(sl+31)
  IF c>15 THEN tmp=INT(c/10)*6 ELSE tmp=0
  PRINT #1,CHR$(13);text$(sl+l);" ";CHR$(16);CHR$(c+tmp);
  a$=""
  RETURN

savefile:
  PRINT #1,CHR$(13);CHR$(11);CHR$(29);CHR$(27);"KEnter File Name to Save :";
  IF r=0 THEN PRINT #1,CHR$(13);"There is nothing to save <Press a Key>.";:a$=INPUT$(1,1):GOTO endsave
  GOSUB getfilename
  IF n$="" THEN endsave
  OPEN n$ FOR OUTPUT AS #2
  sr=1
savemore:
  PRINT #2,text$(sr)
  sr=sr+1
  IF sr<>r THEN savemore
  CLOSE #2
endsave:
  GOSUB printdata
  PRINT #1,CHR$(11);CHR$(sl+31)
  IF c>15 THEN tmp=INT(c/10)*6 ELSE tmp=0
  PRINT #1,CHR$(13);text$(sl+l);" ";CHR$(16);CHR$(c+tmp);
  a$=""
  RETURN

getfilename:
  n$="":nc=0
getthename:
  a$=INPUT$(1,1)
  IF a$=CHR$(8) AND nc>0 THEN PRINT #1,a$;" ";a$;:n$=LEFT$(n$,LEN(n$)-1) :nc=nc-1
  IF a$=CHR$(13) THEN RETURN
  IF a$<CHR$(32) THEN getthename
  PRINT #1,a$;
  n$=n$+a$
  nc=nc+1
  GOTO getthename

