
#include <stdio.h>

	extern printdata();

char buf[30000];
int l=0, sl=1, c=0, r=0, ins=0;

/*
main()
	{
	char a=' ';

	while(a!='Q' && a!='q')
		{
		a=getc(stdin);
		printf("%c\n",c);
		if (a=='\r') newline();
		if (a=='\025' && c>0) goleft();
		if (a=='\006') goright();
		if (a=='\012') godown();
		if (a=='\032') goup();
		if (a=='\010' && c>0) backspace();
		if (a=='\144') deletetext();
		if (a=='\033') checkesc();
		if (a=='\011') {
				ins++;
				if (ins>1) ins=0;
				}
		if (a=='\002') {
				c=0;
				printwhereonline();
				}
		if (a=='\005') goendofline();
		while(a>0x1f && c<80 && a!=0x7f)
			{
			buf
			c++;
			tc=c;
			if (c>15)
				tmp=c/10*6;
			else
				tmp=0;
			printf(

			}

		}

	}
*/
printdata(char *s)
	{
	printf("%s");
	}



