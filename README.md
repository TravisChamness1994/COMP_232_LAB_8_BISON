# COMP 232 Lab 8 - Lexing and Parsing with Flex and Bison

Download [this project](./lab_8_bison.zip). It will serve as a starting point for your lab.

Bison is a tool which allows for the generation of a parser from a configuration file. Like we did for Flex in the last lab, we will cover a minimal introduction to Bison here. You will want to refer to [this tutorial](./resources/LexAndYaccTutorial.pdf) for a more detailed overview throughout the lab.

In this lab, you will create a lexer using Flex and a parser using Bison in order to evaluate expressions in **Cambridge-Polish Notation (CPN)**.

## Cambridge-Polish Notation

CPN is a notation which lists functions and their operands enclosed together in parenthesis. For example, the arithmetic expression `1+2` in CPN would be `(+ 1 2)` or `(add 1 2)` (our implementation will use the latter representation).

CPN expressions are **nestable**. That is, a CPN expression can be used as one of the operands in a function. For example, the expression `(sub 3 (add 1 2))` is valid and would evaluate to `0` (note here that `sub` is subtraction).

You will be making a lexer and parser for expressions in CPN from the following grammar:

```
<program> ::= <expr> EOL | QUIT
<expr> ::= <number> | <f_expr>
<f_expr> ::= ( FUNC <expr> ) | ( FUNC <expr> <expr> ) 
<number> ::= INT | FLOAT
```

Note that the grammar is incomplete; it does not include definitions for the tokens `FUNC`, `INT`, `FLOAT`, `QUIT` and `EOL`. These will be defined as follows:

* `FUNC` : One of the following strings (function names):
	* "neg"
	* "abs"
	* "exp"
	* "log"
	* "sqrt"
	* "add"
	* "sub"
	* "mult"
	* "div"
	* "rem"
* `INT`: an optional `+` or `-` sign, followed by one or more digits.
* `FLOAT`: an optional `+` or `-`, one or more digits, a decimal point (period), and 0 or more trailing digits.
* `QUIT`: the string "quit".
* `EOL`: the newline character `\n`

## Lexing with Flex and Bison

### Defining Grammar Elements with Bison

The task of tokenization is a bit more complex than it was in the previous lab, because the lexer will interact with the parser.

Open `calc.y`, the Yacc file for this project, and `calc.l`, the Lex file for this project. (Bison and Flex are free tools based on Yacc and Lex, proprietary equivalents, and their scanner and parser configuration files are identical). 

Like the `.l` file, the `.y` file is divided into three sections by two lines containing `%%`; these three sections are for **definitions**, **rules** and **subroutines** respectively. Before the lexer can be filled out in `calc.l`, it is necessary to fill out the **definitions** section of `calc.y`; this section will enumerate the tokens and **types** (the grammar elements above tokens). It will also specify what data types will be used to house the data for said tokens and types.

This definitions section has already been filled out, but you will need to ensure you understand it in order to properly interact with it in the scanner!

`calc.y`'s definitions section has the following contents:

```bison
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
```

We will cover a brief description of what these lines mean; more insight can be found [here](https://www.gnu.org/software/bison/manual/html_node/Table-of-Symbols.html) (pdf [here](./resources/Bison3.5_TableOfSymbols.pdf)).

Let's start with the first part:

```bison
%{
    #include "calc.h"
%}
```

These three lines read the line `#include "calc.h"` directly into the parser that Bison generates based on the contents of the Yacc file.

Next, we have the union:

```bison
%union
{
    double dval;
    char *sval;
    struct number *nval;
}
```

The `%union` command in bison specifies the data types that semantic values (tokens and types) might have. So, this particular union denotes that the tokens and types in our grammar will have their data stored in data types `double`, `char *`, and `NUMBER *` (`struct number` and `NUMBER` are identical, check the typedef in `calc.h`).

This union is stored in a variable called `yylval`. Given a token with a string value (say, a token storing a function name), the corresponding string value could be accessed through the `char *` member of the `yylval` union as `yylval.sval`. Similarly, if a float token has data is stored in `double` form, that data could be accessed through `yylval.dval`.

Then, we have the definitions for the types of tokens:

```bison
%token <sval> FUNC
%token <dval> INT FLOAT
%token LPAREN RPAREN EOL QUIT
```

The line `%token <sval> FUNC` adds the token type `FUNC` to the lexer's enumerator listing all types of tokens. It also specifies that the data for a `FUNC` token will be referenced through a `char *` (because `sval` is the name of the `char *` in the `yylval` union).

The following line, `%token <dval> INT FLOAT` creates two more token types, `INT` and `FLOAT`, and specifies that their values will be stored in `double` form in `yylval.dval`.

Next, `%token LPAREN RPAREN EOL QUIT` creates four more token types, none of which require any additional data storage (the token type alone is enough to hold all data necessary for the token).

Finally, there are definitions for elements of the grammar which are above the token level, which Bison refers to as `types`:

```bison
%type <nval> expr f_expr number
```

This line defines three grammar elements: `expr`, `f_expr`, and `number`. It also specifies that the data for any given `expr`, `f_expr` or `number` will house its data in `yylval.nval`, a pointer to an instance of the `NUMBER` struct.

### Lexing with Flex

Now that all types of tokens have been defined, we can move on to lexing. Part of the **definitions** section of `calc.l` is complete, but the portion for defining regular expression shortcuts is incomplete; you'll need to complete it.

Then, you'll need to complete the **rules** section, denoting what to do when each type of token is encountered.

In both sections, the portion for function tokenization has been filled out. A definition has been provided of a regular expression matching all necessary function names:

```bison
func        "neg"|"abs"|"exp"|"sqrt"|...
```

as well as a corresponding rule to populate and return a `FUNC` token:

```bison
{func} {
    yylval.sval = (char *) calloc(sizeof(char), strlen(yytext) + 1);
    strcpy(yylval.sval, yytext);
    fprintf(stderr,"lex: FUNC sval = %s\n", yylval.sval);
    fflush(stderr);
    return FUNC;
}
```

Notice that the data encoded in the token (in this case its string value) is copied from the variable `yytext` (the lexer's storage for the current token string) to `yylval` (the parser's storage for the value of grammar elements).

Also note the debug `fprintf`, made to `stderr`, specifying what type of token is being constructed and what value it is being assigned. While these debug messages are not mandatory, if you don't include them in your lexer and then you ask for help, the answer you will receive is "you should add debug prints to your lexer!"

Some tokens have no value, so their rules will be as simple as a single return statement (i.e. `return LPAREN;`). Other tokens will have a value stored in another form; for instance, `INT` and `FLOAT` tokens will need to populate `yylval.dval` with the double value represented by the tokenized string (check out the manual entry for `strtod`).

The rules for `EOL` tokenization, skipping of whitespace and catching of invalid tokens have also been included:

```
[\n] {
    fprintf(stderr, "lex: EOL\n");
    fflush(stderr);
    YY_FLUSH_BUFFER;
    return EOL;
}

[\t ] ; /* skip whitespace */

. {
    fprintf(stderr, "ERROR: invalid character: >>%s<<\n", yytext);
    fflush(stderr);
}
```

The **subroutines** section of `calc.l` (i.e. the section after the second `%%`) has been filled out; it is where the main is housed. It also includes a definition for the `readLine` function, which reads a line from `stdin` and formats that line as Bison requires.

The code in this section **should not be edited** with two exceptions: 

First, in the main function, the first line is a call to `freopen` (which is commented in the lab download):

```c
freopen("/dev/null", "w", stderr);
```

When this line is uncommented, it will remove the red debug prints made by the lexer and parser to `stderr` by overwriting the `stderr` `FILE *` with a pointer to `/dev/null`, i.e. the void.

Second, there is another call to `freopen` followed immediately by a reassignment to the `printInputs` boolean. If these two lines are uncommented, they will allow you to get input from a file and to print the lines read from that file respectively, for ease of debugging. When these two lines are commented, you will have to type test inputs into the console.

## Parsing with Bison

Much like the Flex **rules** section specifies rules to translate sequences of characters into tokens, the Bison **rules** section specifies rules to process sequences of tokens (and higher grammar elements) using the productions in the grammar.

These rules very closely match the grammar itself. A couple rules have been provided. The first rule:

```bison
program:
    expr EOL {
        fprintf(stderr, "yacc: program ::= expr\n");
        fflush(stderr);
        printNumber(stdout, $1);
    }
    | QUIT {
        fprintf(stderr, "yacc: program ::= QUIT\n");
        fflush(stderr);
        exit(0);
    };
```
is the bison translation of the first production in the grammar:

```
<program> ::= <expr> EOL
``` 

Here, the `program` is the grammar element being produced; its value is refered to with the shorthand `$$`. Furthermore it is being produced as a product of a sequence of grammar elemtns in the form `expr EOL`, whose values are referenced with `$1` and `$2` respectively (and if there were a third element comprising the `program`, its value would be referenced with `$3`, and so on...).

Recall the type definitions in the section above:

```
%type <nval> expr f_expr number
```

We can see from this type definition (and the `%union` definition) that the data for an `expr` is stored in a `NUMBER *`. Note that there **is not type definition** for a `program`. The `program` type serves as an entry point, and in this case we just want to print the result of the `expr` comprising the program.

The block of C code contained within this rule specifies what should action should be taken when a `program` is produced from an `expr` followed by an `EOL` token.

In this case, we make a call to `printNumber` (declared in `calc.h` and defined in `calc.c`) and pass in the `NUMBER *` value of the `expr`, so whenever we enter a valid expression the evaluated result of that expression will be printed to `stdout`.

We also make a debug `fprintf` to `stderr`, much like those discussed during the tokenization process, specifying which production is being used. Again, these debug prints are not mandatory but I will not help debug parsers that are missing them!

The rules for `expr` creation are also provided:

```bison
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
```

and they match productions in the grammar (the extra empty production is to allow for empty programs consisting of just a newline):

```
<expr> ::= <number> | <f_expr>
```

As seen above, when a grammar element can be produced from several different sequences of elements, these options are separated with `|` (semantically, "or").

An `expr` differs from a `program` in a key way: an `expr` has a value. In the `expr ::= number` production, the line `$$ = $1;` assigns the `NUMBER *` value associated with the `number` element to the `expr` element being produced; in other words, if an `expr` is comprised of just a single `number`, then the `expr`'s value is that of the `number`. Recall, `$$` refers to the value of the element being produced (in this case the `expr`), and `$n` refers to the `n`'th element comprising the production (that is, the `n`'th element being **reduced**).

You must complete this rules section, by filling out rules for the remaining productions:

```
<f_expr> ::= ( FUNC <expr> ) | ( FUNC <expr> <expr> ) 
<number> ::= INT | FLOAT
```

An `f_expr` consists of parenthesis, a `FUNC` token (whose string value is the name of the function), and 1-2 `expr`s whose values serve as the operands for the specified function. A function called `calc` is declared in `calc.h` an defined in `calc.c`:

```c
NUMBER calc(char *func, NUMBER *op1, NUMBER *op2);
```

This function's purpose is to take in the name of a function in string form and the value(s) of the operand(s) in `NUMBER *` form and to calculate and return the result. We will cover **how** it should do so [later on](#eval-section).

For now, assume that the `calc` function works (because you'll make it work later). Use it in the `f_expr` productions to get the value of the `f_expr` being produced by passing in the function name (i.e. the value of the `FUNC` token) and the value(s) of the operand(s) (i.e. the values of the `expr`(s)).

For single-operand function calls (those using the production `f_expr ::= ( FUNC expr )`), `NULL` should be passed into the `calc` call in place of a second operand.

In the rules to produce `number` elements from `INT` and `FLOAT` tokens, the `createNumber` function should be called. It is declared in `calc.h` and defined in `calc.c` and has already been completed, but you will need to read its contents in order to determine how to use it!

## <a name="eval-section"></a> Evaluation

Once parsing is correct, evaluation of expressions comes down to completion of the functions called from the `calc` function in `calc.c`. These functions are all declared, but must be filled out (these are the `//TODO`s in `calc.c`).

The definitions of `evalNeg` and `evalAdd` have been provided as an example. If you're not sure what one of the functions is supposed to do, refer to the comments in the `resolveFunc` function near the top of `calc.c`.

The `resolveFunc` function has already been completed, but you should read the comment above it to see what it does and make sure that you understand its use in the `calc` function.

## Sample Run

The following is a successful sample run with the provided `input.txt` used as input.

As always, don't forget to construct test cases of your own and include sample runs with your own test inputs in your documentation!

```
> 1
INT : 1

> 1.0
FLOAT : 1.000000

> -1
INT : -1

> -1.5
FLOAT : -1.500000

> +1
INT : 1

> +1.50
FLOAT : 1.500000

> 10
INT : 10

> 10.15
FLOAT : 10.150000

> -10.50
FLOAT : -10.500000

> (neg 1)
INT : -1

> (neg 1.0)
FLOAT : -1.000000

> (abs 1)
INT : 1

> (abs -1)
INT : 1

> (abs 1.5)
FLOAT : 1.500000

> (abs -1.0)
FLOAT : 1.000000

> (exp 1)
FLOAT : 2.718282

> (exp 1.0)
FLOAT : 2.718282

> (exp 0)
FLOAT : 1.000000

> (exp 0.)
FLOAT : 1.000000

> (log 1)
FLOAT : 0.000000

> (log 1.0)
FLOAT : 0.000000

> (log 10)
FLOAT : 2.302585

> (log 0)
FLOAT : -inf

> (log -1)
FLOAT : nan

> (sqrt 1)
FLOAT : 1.000000

> (sqrt 1.0)
FLOAT : 1.000000

> (sqrt 0)
FLOAT : 0.000000

> (sqrt 0.0)
FLOAT : 0.000000

> (sqrt 4)
FLOAT : 2.000000

> (sqrt 4.0)
FLOAT : 2.000000

> (sqrt -1)
FLOAT : nan

> (sqrt -1.0)
FLOAT : nan

> (add 1 2)
INT : 3

> (add 1.0 2)
FLOAT : 3.000000

> (add 1 2.0)
FLOAT : 3.000000

> (add 1.0 2.0)
FLOAT : 3.000000

> (sub 2 1)
INT : 1

> (sub 2.0 1)
FLOAT : 1.000000

> (sub 2 1.0)
FLOAT : 1.000000

> (sub 2.0 1.0)
FLOAT : 1.000000

> (mult 2 3)
INT : 6

> (mult 2 3.0)
FLOAT : 6.000000

> (mult 2.0 3)
FLOAT : 6.000000

> (mult 2.0 3.0)
FLOAT : 6.000000

> (div 1 2)
INT : 0

> (div 1 2.0)
FLOAT : 0.500000

> (div 1.0 2)
FLOAT : 0.500000

> (div 1.0 2.0)
FLOAT : 0.500000

> (div 1 0)
INT : inf

> (div 1.0 0.0)
FLOAT : inf

> (div 0 0)
INT : nan

> (rem 8 3)
INT : 2

> (rem -8 3)
INT : -2

> (rem 8.0 3)
FLOAT : 2.000000

> (rem 8 3.0)
FLOAT : 2.000000

> (rem 8.0 3.0)
FLOAT : 2.000000

> (rem 1 0)
INT : nan

> (rem 1 0.0)
FLOAT : nan

> (add 1 (add 2 3))
INT : 6

> (add 1 (add 2.0 3))
FLOAT : 6.000000

> (log (exp 1))
FLOAT : 1.000000

> (exp (log 1))
FLOAT : 1.000000

> (add 1 (add 2 (add 3 (add 4  5))))
INT : 15

> quit
Process finished with exit code 0

```
