%{
    #include "calc.h"
%}

%union
{
    double dval;
    char *sval;
    struct number *nval;
}

%token <sval> FUNC
%token <dval> INT FLOAT
%token LPAREN RPAREN EOL QUIT

%type <nval> expr f_expr number

%%

program:
    expr EOL {
        fprintf(stderr, "yacc: program ::= expr EOL\n");
        fflush(stderr);
        printNumber(stdout, $1);
    }
    | QUIT {
        fprintf(stderr, "yacc: program ::= QUIT\n");
        fflush(stderr);
        exit(0);
    };

expr:
    number {
        fprintf(stderr, "yacc: expr ::= number\n");
        fflush(stderr);
        printNumber(stderr, $1);
        $$ = $1;
    }
    | f_expr {
        fprintf(stderr, "yacc: expr ::= f_expr\n");
        fflush(stderr);
        $$ = $1;
    }
    | {
        $$ = NULL;
    };

%%

