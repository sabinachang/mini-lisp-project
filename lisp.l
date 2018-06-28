%{
#include "lisp.h"
#include "lisp2.tab.h"
#include <stdlib.h>
#include <string.h>
extern "C"{
	int yylex(void);
}
extern stack<char> operators;
extern symbol symtab[107];

%}
number (0|[1-9][0-9]*|-[1-9][0-9]*)
id [a-z]([a-z]|[0-9]|"-")*
mod mod
or or
and and
not not
if if
true #t
false #f
define define
fun fun
prtnum print-num
prtbool print-bool
%option noyywrap
%%
{number} {
		yylval.n = atoi(yytext);
		return NUMBER;
	}
{if} {
		yylval.str = strdup(yytext);
		return IF;
	}
{or} {
		yylval.n = 4;
		return LOG;
	}
{and} {
		yylval.n = 5;
		return LOG;
	}
{not} {
		yylval.n = 6;
		return LOG;
	}
{fun} {
		yylval.str = strdup(yytext);
		return FUN;
}
{mod}  {
		yylval.str = strdup(yytext);
		return MOD;
}
{prtnum}	{
		yylval.str = strdup(yytext);
		return PRTNUM;
	}
{define} {
	yylval.str = strdup(yytext);
	return DEFINE;
}
{prtbool}	{
		yylval.str = strdup(yytext);
		return PRTBOOL;
}
{false} {	
		yylval.n = 0;
		return NUMBER;
		
	}
{true} {
		yylval.n = 1;
		return NUMBER;
	}
\+ {
		yylval.str = strdup(yytext);
		operators.push('+');
		return PLS;
}
\* {
		yylval.str = strdup(yytext);
		operators.push('*');
		return MPLY;
	}
"<"	{
		yylval.n = 1;
		return CMP;
	}
">" {
		yylval.n = 2;
		return CMP;
	}
"="	{
		yylval.n = 3;
		return EQL;
	}
{id} {
	
	yylval.s = lookup(yytext);
	return ID;
}
[ \t\r]+
.	{return yytext[0];}
%%