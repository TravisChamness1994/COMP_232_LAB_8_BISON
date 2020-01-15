%option noyywrap
%option nounput
%option noinput

%{
    #include "calc.h"
%}


func        "neg"|"abs"|"exp"|"sqrt"|"add"|"sub"|"mult"|"div"|"rem"|"log"|"pow"|"max"|"min"

%%

{func} {
    yylval.sval = (char *) calloc(sizeof(char), strlen(yytext) + 1);
    strcpy(yylval.sval, yytext);
    fprintf(stderr,"lex: FUNC sval = %s\n", yylval.sval);
    fflush(stderr);
    return FUNC;
}



[\n] {
    fprintf(stderr, "lex: EOL\n");
    fflush(stderr);
    YY_FLUSH_BUFFER;
    return EOL;
}

[\t ] {}; /* skip whitespace */

. {
    fprintf(stderr, "ERROR: invalid character: >>%s<<\n", yytext);
    fflush(stderr);
}

%%

#include <stdio.h>
#include <stdlib.h>

size_t readline(char **lineptr, size_t *n, FILE *stream, size_t n_terminate) {
    char *bufptr = NULL;
    char *p = bufptr;
    size_t size;
    int c;

    if (lineptr == NULL) {
        return -1;
    }
    if (stream == NULL) {
        return -1;
    }
    if (n == NULL) {
        return -1;
    }
    bufptr = *lineptr;
    size = *n;

    c = fgetc(stream);
    if (c == EOF) {
        return -1;
    }
    if (bufptr == NULL) {
        bufptr = malloc(128);
        if (bufptr == NULL) {
            return -1;
        }
        size = 128;
    }
    p = bufptr;
    while(c != EOF) {
        if ((p - bufptr + 1 + n_terminate) > (size)) {
            int offset = p - bufptr;
            size = size + 128;
            bufptr = realloc(bufptr, size);
            if (bufptr == NULL) {
                return -1;
            }
            p = bufptr + offset;
        }
        *p++ = c;
        if (c == '\n') {
            break;
        }
        c = fgetc(stream);
    }

    while( n_terminate > 0)
    {
        *p++ = '\0';
        n_terminate--;
    }

    *n = p - bufptr;
    bufptr = realloc(bufptr, *n);
    *lineptr = bufptr;

    return p - bufptr;
}


int main(int argc, char **argv) {
    bool printInputs = false;

    //freopen("/dev/null", "w", stderr);

    //freopen(argv[1], "r", stdin);
    //printInputs = true;

    char *s_expr_str;
    size_t s_expr_str_len;
    size_t s_expr_postfix_padding = 2;
    YY_BUFFER_STATE buffer;
    while (true) {
        printf("\n> ");
        s_expr_str = NULL;
        s_expr_str_len = 0;
        readline(&s_expr_str, &s_expr_str_len, stdin, s_expr_postfix_padding);
        if (printInputs)
        {
            printf("%s", s_expr_str);
        }
        buffer = yy_scan_buffer(s_expr_str, s_expr_str_len);
        yyparse();
        yy_delete_buffer(buffer);
    }

    free(s_expr_str);
}
