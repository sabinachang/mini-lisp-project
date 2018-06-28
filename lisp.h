#ifndef MAIN_HPP
#define MAIN_HPP

#include <iostream>
#include <vector>
#include <stdio.h>
#include <stack>
#include <cstdlib>
#include <string.h>
#include <map>
#include <string>
using namespace std;



struct ast{
	int nodetype;
	ast* l;
	ast* r;
	ast* parent = NULL;
};

struct symbol{
	char *name;
	int value;
	ast* func;
	struct symlist* syms;
};
struct symlist{
	symbol * sym;
	symlist* next;
};
struct fnexp{
	int nodetype;
	ast* func;
	symlist* syms;
};
struct pmlist{
	ast* a;
	pmlist* next;
};
struct namedcall{
	int nodetype; //F
	symbol* name;
	pmlist* pl;

};
struct call{
	int nodetype; //C
	ast*func;
	symlist* syms;
	pmlist* pl;
};
struct numval{
	int nodetype;
	int number;
};
struct symref{
	int nodetype;
	symbol* s;
};
struct flow{
	int nodetype;
	ast* cond;
	ast* tl;
	ast* el;
};

struct Type{
	int n;
	char* str;
	symbol *s;
	symlist *sl;
	pmlist *pl;
	ast* a;
	fnexp *fexp;
	
};
int isGreater(int a, int b);
int isLesser(int a, int b);
int eval(ast* a);
void dodef(symbol* name, symlist* sy);
ast* newast(int nodetype, ast*l, ast*r);
ast* newref(symbol*s);
ast* newnum(int n);
ast* newcmp(int cmptype, ast* l, ast* r);
ast* newuserdef(symlist* syms, ast* body);
ast* newflow(int nodetype, ast*cond,ast* tl, ast*el);
ast* newnamedcall( symbol* f, pmlist* l);
ast* newcall(ast* f, pmlist*l);
symlist* newsymlist(symbol* sym,symlist*next);
pmlist* newparamlist(ast* l, pmlist*next);
void nameduserdef(symbol*name, ast* d);
void symboldef(symbol*id, ast*v);
unsigned symhash(char *sym);
symbol* lookup(char*);
int evalfn(ast* fn , symlist*osl,pmlist* params);
void freeparamlist(pmlist*pl);


#define YYSTYPE Type
#endif
