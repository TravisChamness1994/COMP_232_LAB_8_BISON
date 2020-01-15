#ifndef __calc_h_
#define __calc_h_

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <math.h>
#include <stdbool.h>

// The following include file is generated automatically by CMake
// (along the scanner and the parser)
// It will include an enum of all of the token types returned in calc.l
// This is why we haven't made our own enum with the necessary token types.
// It will probably be underlined in red FOREVER. Don't ask me to help you fix that.
#include "parser.h"

// declaring the following Bison functions limits compiler warnings
int yyparse(void);
int yylex(void);
void yyerror(char *, ...);

typedef enum func_type
{
    NEG,
    ABS,
    EXP,
    LOG,
    SQRT,
    ADD,
    SUB,
    MULT,
    DIV,
    REM,
    OTHER // stranger danger
} FUNC_TYPE;

typedef enum
{
    INT_TYPE,
    FLOAT_TYPE,
    NULL_NUMBER
} NUM_TYPE;

typedef struct number
{
    NUM_TYPE type;
    double value;
} NUMBER;

NUMBER *createNumber(NUM_TYPE type, double value);
void printNumber(FILE *stream, NUMBER *number);
NUMBER *calc(char *func, NUMBER *op1, NUMBER *op2);


#endif
