%{
#include "lisp.h"

extern "C"{
	extern int yylex(void);
	void yyerror(const char *s);
}

stack<char> operators;
symbol symtab[107];

%}
%left PLS '-'
%left MPLY '/' 
%token <n> NUMBER 
%token <str> PLS MPLY PRTNUM DEFINE FUN MOD IF PRTBOOL
%token <n> CMP EQL LOG 
%token <s> ID
%type <a> exp explist plus minus numop multiply divide funbody
%type <a> funcall modulus cmp equal ifexp logop funexp
%type <sl> idlist funid 
%type <n> line program
%type <pl> paramlist
%%
program : 	
			line 
		|	program line 
		;
line	:	
		
			exp
			{
				;
			}
		|	'(' PRTNUM exp ')'
			{
				cout << eval($3) << endl;
			}
		|	'(' PRTBOOL exp ')'
			{
				if(eval($3) != 0) cout << "#t" << endl;
				else cout << "#f" << endl;
			} 
		|	defstmt
			{
				;
			}
		;	
defstmt	:
			'(' DEFINE ID exp ')'
			{
				nameduserdef($3,$4);
			}
		;

explist	:	
			exp 
			{ 
				$$ = $1;	
			}
		|	explist exp 
			{	
				$$ = newast('L',$2, $1);
			}
		;
exp		:	
			numop	{ $$ = $1;}
		|	logop	{ $$ = $1;}
		|	funcall	{ $$ = $1;}
		|	funexp	{ $$ = $1;}
		|	ifexp	{ $$ = $1;}
		|	ID 		{ $$ = newref($1);}
		|	NUMBER	{ $$ = newnum($1);}
		;
logop	:
			'(' LOG explist exp ')'
			{
				$$ = newast($2+'0',$3,$4);
			}
		|	'(' LOG exp ')'
			{
				$$ = newast($2+'0',$3,NULL);
			}
		;
ifexp	:
			'(' IF exp exp exp ')'
			{
				$$ = newflow('I',$3,$4,$5);
			}
funexp	:
			'('FUN funid funbody ')' 
			{
				$$ = newuserdef($3,$4);
			}
		;
funbody :
			defstmt exp { $$ = $2;}
		|	exp { $$ = $1; }
		;

funid	:
			'(' ')'{ $$ = NULL;}
		|	'(' idlist ')' { $$ = $2;} 
		;
idlist	:	
			ID { $$ = newsymlist($1,NULL);}
		|	ID idlist { $$ = newsymlist($1,$2);}
		;
funcall :
			'(' funexp ')'
			{
				$$ = newcall($2,NULL);
			}
		|	'(' ID ')'{
				$$ = newnamedcall($2,NULL);				
			}
		|	'(' funexp paramlist ')'
			{
				$$ = newcall($2,$3);				
			}
		|	'(' ID paramlist ')'
			{
				$$ = newnamedcall($2,$3);				
			}
		;

paramlist:
			exp{
				cout << "param list" << endl;
				$$ = newparamlist($1,NULL);
			}

		|	exp paramlist
			{
				$$ = newparamlist($1,$2);
			}
		
		;


numop	:	
			plus	
			{ $$ = $1;}
		|	minus	
			{ $$ = $1;}
		|	multiply
			{ $$ = $1;}
		|	divide
			{ $$ = $1;}
		|	modulus
			{ $$ = $1;}
		|	cmp	
			{ $$ = $1;}
		|	equal
			{ $$ = $1;}	
		;
	
plus	:	
			'(' PLS explist exp ')'
			{		
				$$ = newast('+',$3,$4);
			}
		;
minus	:	
			'(' '-' exp exp ')' 
			{
				$$ = newast('-',$3,$4);
				cout << "minus" << endl;
			}
		;
multiply:	
			'(' MPLY explist exp ')' 
			{
				$$ = newast('*',$3,$4);
			}
		;

divide	:	
			'(' '/' exp exp ')' 
			{
				$$ = newast('/',$3,$4);
			}
		;
modulus :
			'(' MOD exp exp ')'
			{
				$$ = newast('%',$3,$4);
			}
cmp 	:
			'(' CMP exp exp ')'
			{
				$$ = newast($2+'0',$3,$4);
			}
equal   :	
			'(' EQL explist exp ')'
			{
				
				$$ = newast($2+'0',$3,$4);
			}




%%
void yyerror (const char *message){
        
        printf ("%s \n",message);
        exit(0);

}
int isGreater(int a, int b){
	if(a > b) return 1;
	else return 0;
}

int isLesser(int a, int b){
	if(a < b) return 1;
	else return 0;
}
ast* newast(int nodetype, ast*l, ast*r){
	
	ast* a = (ast*) malloc(sizeof(ast));
	a->nodetype = nodetype;
	a->l = l;
	a->r = r;
	if( a->l && a->l->nodetype == 'L'){
		a->l->parent = a;
	}
	if( a->r && a->r->nodetype == 'L'){
		a->r->parent = a;
	}
	return a;
}
ast* newnum(int n){
	numval* a = (numval*) malloc(sizeof(numval));
	a->nodetype = 'K';
	a->number = n;
	return (ast*) a;
}
ast* newcmp(int cmptype, ast* l, ast* r){
	ast* a = (ast*) malloc(sizeof(ast));
	a->nodetype = '0'+ cmptype;
	a->l = l;
	a->r = r;
	return a;
}
ast* newflow(int nodetype, ast*cond,ast* tl, ast*el){
	flow* a = (flow*) malloc(sizeof(flow));
	a->nodetype = nodetype;
	a->cond = cond;
	a->tl = tl;
	a->el = el;
	return (ast*)a;	
}
ast* newnamedcall( symbol* f, pmlist* l){
	
	namedcall* n = (namedcall*) malloc(sizeof(namedcall));
	n->nodetype = 'F';

	pmlist* tmp = l;
	pmlist* prev = NULL;
	while(tmp){
		if(tmp->a->nodetype == 'D'){
			ast* d = tmp->a;
			f->func = ((fnexp*)d)->func;
			f->syms = ((fnexp*)d)->syms;
			if(prev == NULL){
				l = tmp->next;
				free(tmp);
				tmp = tmp->next;
			}
			else{
				prev->next = tmp->next;
				free(tmp);
				tmp = tmp->next;
			}
		}
		else{
			prev = tmp;
			tmp = tmp->next;
		}
		
	}
	n->name = f;
	n->pl = l;
	cout << "in named call " << endl;
	return (ast*)n;
}
ast* newcall(ast* f, pmlist *l){
	call* a = (call*) malloc(sizeof(call));
	a->nodetype = 'C';
	a->func = ((fnexp*)f)->func;
	a->syms = ((fnexp*)f)->syms;
	a->pl = l;
	return (ast*)a;
}
symlist* newsymlist(symbol* sym, symlist*next){
	symlist* sl = (symlist*) malloc(sizeof(symlist));
	sl->sym = sym;
	sl->next = next;
	return sl;
}
pmlist* newparamlist(ast* l, pmlist*next){
	pmlist* pl = (pmlist*)malloc(sizeof(pmlist));

	pl->a = l;
	
	pl->next = next;
	return pl;
}
ast* newref(symbol* s){
	symref* a = (symref*)malloc(sizeof(symref));
	a->nodetype = 'N';
	a->s = s;
	return (ast*)a;
}
unsigned symhash(char *sym){
	unsigned int hash = 0;
	unsigned c;
	while(c = *sym++) hash = hash*9 ^ c;
	return hash;
}
symbol* lookup(char* sym ){
	symbol* sp = &symtab[symhash(sym)%107];
	int scount = 107;

	while(--scount >= 0){
		if(sp->name && !strcmp(sp->name,sym)){ return sp;}
		if(!sp-> name){
			sp->name = strdup(sym);
			sp->value = 0;
			sp->func = NULL;
			sp-> syms = NULL;
			return sp;
		} 
		if(++sp >= symtab+107) sp = symtab;
	}
	exit(0);
}
ast* newuserdef(symlist* syms, ast* func){
	fnexp* a = (fnexp*)malloc(sizeof(fnexp));
	a->nodetype = 'D';
	a->syms = syms;
	a->func = func;
	
	return (ast*)a;
}
void nameduserdef(symbol* name, ast* d){
	if(d->nodetype == 'D'){
		name->func = ((fnexp*)d)->func;
		name->syms = ((fnexp*)d)->syms;
	}
	if(d->nodetype == 'F'){
		int dummy = eval(d);
		ast* t = ((namedcall*)d)->name->func;
		name->func = ((fnexp*)t)->func;
		name->syms = ((fnexp*)t)->syms;
	}
	else
		name->value = eval(d);
}
int evalfn(ast* fn, symlist* osl, pmlist* params){
	if(!params){
		return eval(fn);
	}

	symlist* sl;
	pmlist* pms;
	int* oldval, *newval;
	int nargs,v;

	sl = osl;
	pms = params;
	for(nargs = 0; sl; sl= sl->next)
		nargs++;
	oldval = (int*)malloc(nargs * sizeof(int));
	newval = (int*)malloc(nargs * sizeof(int));
	for(int i = 0; i < nargs; i++){
		newval[i] = eval(pms-> a);
		pms = pms-> next;		
	}

	sl = osl;
	for(int i = 0; i < nargs; i++){
		symbol* s = sl->sym;
		oldval[i] = s->value;
		s->value = newval[i];
		sl = sl->next;
	}
	free(newval);
	if(fn->nodetype == 'D'){
		return 0;	
	}
	v = eval(fn);
	sl = osl;
	for(int i = 0 ; i < nargs; i++){
		symbol* s = sl->sym;
		s->value = oldval[i];
		sl = sl->next;
	}
	free(oldval);
	return v;
}

int eval(ast*a){
	int v;
	switch(a->nodetype){
	case '+': v = eval(a->l) + eval(a->r); break;
	case '*': v = eval(a->l) * eval(a->r); break;
	case '-': v = eval(a->l) - eval(a->r); break;
	case '/': v = eval(a->l) / eval(a->r); break;
	case '%': v = eval(a->l) % eval(a->r); break;

	case '1': v = (eval(a->l) < eval(a->r))? 1 : 0; break;
	case '2': v = (eval(a->l) > eval(a->r))? 1 : 0; break;
	case '3': v = (eval(a->l) == eval(a->r))? 1 : 0; break;
	case '4': v = (eval(a->l) || eval(a->r))? 1 : 0; break;
	case '5': v = (eval(a->l) && eval(a->r))? 1 : 0; break;
	case '6':{ v = (eval(a->l) == 0)? 1 : 0; break;}
	
	case 'L': 
		{
			ast* prnt = a->parent;
			
			while(prnt->nodetype == 'L'){
				prnt = prnt->parent;
			}
						
				int l = eval(a->l);
			    int r = eval(a->r);
			
				if(prnt->nodetype == '+'){
					v = l+r;
				}
				if(prnt->nodetype == '*'){
					v = l*r;
				}
				if(prnt->nodetype == '='){
					v = (r == l)?1:0;
				}
				if(prnt->nodetype == '4'){
					v = (r || l)? 1: 0;
				}
				if(prnt->nodetype == '5'){
					v = (r && l)? 1 : 0;
				}
						
			break;
		}
	case 'I':
		{	
			if(eval(((flow*)a)->cond) != 0){
				
				v = eval( ((flow*)a)->tl);
			}
			else{
				
				v = eval(((flow*)a)->el);
				
			}
			break;
		}
	case 'F':
		{

			v = evalfn(((namedcall*)a)->name->func,((namedcall*)a)->name->syms,((namedcall*)a)->pl);
			break;
		}
	case 'C':
		{
			v = evalfn(((call*)a)->func,((call*)a)->syms,((call*)a)->pl);
			break;
		}

	case 'N': v = ((symref*)a)->s->value;break;
	case 'K': v = ((numval*)a)->number;break;
	}
	return v;
}
void freeparamlist(pmlist* pl){
	pmlist* p ;
	while(pl){
		p = pl->next;
		free(pl);
		pl = p;
	}
}

int main(int argc, char * argv[]){
	
	yyparse();
	return 0;
}