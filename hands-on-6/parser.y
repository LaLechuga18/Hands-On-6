%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>



void yyerror(const char *s);
int yylex(void);

/* ======================
   ANALISIS SEMANTICO
   ====================== */

typedef struct Simbolo {
    char* nombre;
    char* tipo;          // int, float, función, etc.
    int num_parametros;  // si es función
    struct Simbolo* sig;
} Simbolo;

typedef struct Tabla {
    Simbolo* head;
} Tabla;

typedef struct Scope {
    Tabla* tabla_local;
    struct Scope* scope_padre;
} Scope;

Scope* scope_actual = NULL;
Tabla* tabla_global = NULL;

/* Crear nuevo scope */
void push_scope() {
    Scope* nuevo = (Scope*) malloc(sizeof(Scope));
    nuevo->tabla_local = (Tabla*) malloc(sizeof(Tabla));
    nuevo->tabla_local->head = NULL;
    nuevo->scope_padre = scope_actual;
    scope_actual = nuevo;
}

/* Salir de scope */
void pop_scope() {
    Scope* tmp = scope_actual;
    scope_actual = scope_actual->scope_padre;

    Simbolo* s = tmp->tabla_local->head;
    while(s) {
        Simbolo* aux = s;
        s = s->sig;
        free(aux->nombre);
        free(aux->tipo);
        free(aux);
    }
    free(tmp->tabla_local);
    free(tmp);
}

/* Agregar símbolo */
int agregar_simbolo(const char* nombre, const char* tipo, int num_parametros) {
    Simbolo* s = scope_actual->tabla_local->head;
    while(s) {
        if(strcmp(s->nombre, nombre) == 0) return 0; // redeclaración
        s = s->sig;
    }
    Simbolo* nuevo = (Simbolo*) malloc(sizeof(Simbolo));
    nuevo->nombre = strdup(nombre);
    nuevo->tipo = strdup(tipo);
    nuevo->num_parametros = num_parametros;
    nuevo->sig = scope_actual->tabla_local->head;
    scope_actual->tabla_local->head = nuevo;
    return 1;
}

/* Buscar símbolo en scopes */
Simbolo* buscar_simbolo(const char* nombre) {
    Scope* s = scope_actual;
    while(s) {
        Simbolo* sym = s->tabla_local->head;
        while(sym) {
            if(strcmp(sym->nombre, nombre) == 0) return sym;
            sym = sym->sig;
        }
        s = s->scope_padre;
    }
    return NULL;
}
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

%type <str> type

/* Resolver conflicto shift/reduce del dangling else */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

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

preprocessor_directive:
      '#' INCLUDE '<' ID '.' ID '>' { printf("Include: <%s.%s>\n", $4, $6); }
    | '#' INCLUDE ID { printf("Include: %s\n", $3); }
    | '#' DEFINE ID NUMBER { printf("Define: %s = %d\n", $3, $4); }
    | '#' DEFINE ID { printf("Define: %s\n", $3); }
    ;

decl:
      global_decl
    | func_decl
    ;

global_decl:
      type ID ';' {
          if(!agregar_simbolo($2, $1, 0))
              yyerror("Error: redeclaracion de variable global");
          else
              printf("Declaracion global: %s\n", $2);
      }
    ;

type:
      INT
    | FLOAT
    | DOUBLE
    | CHAR
    | VOID
    | SHORT
    ;

func_decl:
      type ID '(' param_list_opt ')' block {
          if(!agregar_simbolo($2, $1, 0))
              yyerror("Error: redeclaracion de funcion");
          else
              printf("Funcion declarada: %s\n", $2);
      }
    ;

param_list_opt:
      /* vacio */
    | param_list
    ;

param_list:
      param_list ',' param
    | param
    ;

param:
      type ID {
          if(!agregar_simbolo($2, $1, 0))
              yyerror("Error: redeclaracion de parametro");
          else
              printf("Parametro: %s\n", $2);
      }
    ;

block:
      '{' { push_scope(); }
      local_decl_list stmt_list
      '}' { pop_scope(); }
    ;

local_decl_list:
      local_decl_list local_decl
    | /* vacío */
    ;

local_decl:
      type ID ';' {
          if(!agregar_simbolo($2, $1, 0))
              yyerror("Error: redeclaracion de variable local");
          else
              printf("Variable local: %s\n", $2);
      }
    ;

stmt_list:
      stmt_list stmt
    | /* vacio */
    ;

stmt:
      expr ';'
    | ID '=' expr ';' {
          if(!buscar_simbolo($1))
              yyerror("Error: variable no declarada");
          else
              printf("Asignacion a: %s\n", $1);
      }
    | RETURN expr ';' { printf("Return statement\n"); }
    | func_call ';'
    | block
    | if_stmt
    ;

if_stmt:
      IF '(' expr ')' stmt %prec LOWER_THAN_ELSE
    | IF '(' expr ')' stmt ELSE stmt
    ;

func_call:
      ID '(' arg_list_opt ')' {
          Simbolo* f = buscar_simbolo($1);
          if(!f) yyerror("Error: funcion no declarada");
          else
              printf("Llamada a funcion: %s\n", $1);
      }
    ;

arg_list_opt:
      /* vacio */
    | arg_list
    ;

arg_list:
      arg_list ',' expr
    | expr
    ;

expr:
      NUMBER { $$ = $1; }
    | ID {
          if(!buscar_simbolo($1))
              yyerror("Error: variable no declarada");
          $$ = 0;
      }
    | func_call { $$ = 0; }
    | expr '+' expr { $$ = $1 + $3; }
    | expr '-' expr { $$ = $1 - $3; }
    | expr '*' expr { $$ = $1 * $3; }
    | expr '/' expr { $$ = $1 / $3; }
    | '(' expr ')' { $$ = $2; }
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

    tabla_global = (Tabla*) malloc(sizeof(Tabla));
    tabla_global->head = NULL;
    scope_actual = (Scope*) malloc(sizeof(Scope));
    scope_actual->tabla_local = tabla_global;
    scope_actual->scope_padre = NULL;

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
        printf("   Analisis completado exitosamente :D \n");
        printf("=================================================\n");
    } else {
        printf("\n=================================================\n");
        printf("   Analisis completado con errores :c\n");
        printf("=================================================\n");
    }

    if (argc > 1) {
        fclose(yyin);
    }

    return result;
}
