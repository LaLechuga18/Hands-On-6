%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);
%}

%union {
    int ival;
    char *str;
}

/* Tokens */
%token <str> ID
%token <ival> NUMBER

%token INT FLOAT DOUBLE CHAR VOID SHORT
%token RETURN INCLUDE DEFINE
%token IF ELSE
%token INCREMENT

/* Resolver conflicto shift/reduce del dangling else */
%right ELSE

/* Precedencia de operadores */
%left '+' '-'
%left '*' '/'

%type <ival> expr

%%

program:
      translation_unit
    ;

translation_unit:
      external_decl
    | translation_unit external_decl
    ;

external_decl:
      preprocessor_directive
    | decl
    ;

/* ---------------------- */
/* DIRECTIVAS PREPROCESADOR */
/* ---------------------- */
preprocessor_directive:
      '#' INCLUDE any_tokens
        { printf("Include directive\n"); }
    | '#' DEFINE ID NUMBER
        { printf("Define: %s = %d\n", $3, $4); }
    | '#' DEFINE ID any_tokens
        { printf("Define: %s\n", $3); }
    | '#' DEFINE ID
        { printf("Define: %s\n", $3); }
    ;

any_tokens:
      any_token
    | any_tokens any_token
    ;

any_token:
      ID
    | NUMBER
    | '<'
    | '>'
    | '.'
    | ','
    ;

decl:
      global_decl
    | func_decl
    ;

/* ---------------------- */
/* DECLARACIONES GLOBALES */
/* ---------------------- */
global_decl:
      type ID ';'
        { printf("Declaracion global: %s\n", $2); }
    ;

/* -------------- */
/* TIPOS DE DATO  */
/* -------------- */
type:
      INT
    | FLOAT
    | DOUBLE
    | CHAR
    | VOID
    | SHORT
    ;

/* ----------------------- */
/* DECLARACION DE FUNCION */
/* ----------------------- */
func_decl:
      type ID '(' param_list_opt ')' block
        { printf("Funcion declarada: %s\n", $2); }
    ;

/* Parametros */
param_list_opt:
      /* vacio */
    | param_list
    ;

param_list:
      param_list ',' param
    | param
    ;

param:
      type ID
        { printf("Parametro: %s\n", $2); }
    ;

/* -------- */
/* BLOQUES  */
/* -------- */
block:
      '{' local_decl_list stmt_list '}'
    ;

/* declaraciones locales dentro de funciones */
local_decl_list:
      local_decl_list local_decl
    | /* vacío */
    ;

local_decl:
      type ID ';'
        { printf("Variable local: %s\n", $2); }
    ;

/* ----------- */
/* INSTRUCCIONES */
/* ----------- */
stmt_list:
      stmt_list stmt
    | /* vacio */
    ;

stmt:
      expr_stmt
    | assign_stmt
    | return_stmt
    | call_stmt
    | block
    | if_stmt
    ;

expr_stmt:
      expr ';'
    ;

assign_stmt:
      ID '=' expr ';'
        { printf("Asignacion a: %s\n", $1); }
    ;

return_stmt:
      RETURN expr ';'
        { printf("Return statement\n"); }
    ;

call_stmt:
      func_call ';'
    ;

/* ----------------- */
/* SENTENCIAS IF     */
/* ----------------- */
if_stmt:
      IF '(' expr ')' stmt
    | IF '(' expr ')' stmt ELSE stmt
    ;

/* ----------------- */
/* LLAMADAS A FUNCION */
/* ----------------- */
func_call:
      ID '(' arg_list_opt ')'
        { printf("Llamada a funcion: %s\n", $1); }
    ;

arg_list_opt:
      /* vacio */
    | arg_list
    ;

arg_list:
      arg_list ',' expr
    | expr
    ;

/* ----------------- */
/* EXPRESIONES       */
/* ----------------- */
expr:
      NUMBER
        { $$ = $1; }
    | ID
        { $$ = 0; }
    | func_call
        { $$ = 0; }
    | expr '+' expr
        { $$ = $1 + $3; }
    | expr '-' expr
        { $$ = $1 - $3; }
    | expr '*' expr
        { $$ = $1 * $3; }
    | expr '/' expr
        { $$ = $1 / $3; }
    | '(' expr ')'
        { $$ = $2; }
    ;

%%

void yyerror(const char *s) {
    extern int linea;
    fprintf(stderr, "Error de sintaxis en linea %d: %s\n", linea, s);
}

int main(int argc, char **argv) {
    extern FILE *yyin;
    
    printf("=================================================\n");
    printf("  COMPILADOR BASICO - Lexer + Parser\n");
    printf("=================================================\n\n");
    
    if (argc > 1) {
        FILE *f = fopen(argv[1], "r");
        if (!f) {
            fprintf(stderr, "Error: No se pudo abrir el archivo '%s'\n", argv[1]);
            return 1;
        }
        yyin = f;
        printf("Analizando archivo: %s\n\n", argv[1]);
    } else {
        printf("Leyendo desde entrada estandar...\n\n");
    }
    
    int result = yyparse();
    
    if (result == 0) {
        printf("\n=================================================\n");
        printf("  Analisis completado exitosamente :D\n");
        printf("=================================================\n");
    } else {
        printf("\n=================================================\n");
        printf("  Analisis completado con errores :c\n");
        printf("=================================================\n");
    }
    
    if (argc > 1) {
        fclose(yyin);
    }
    
    return result;
}
