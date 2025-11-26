%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

int linea = 1;
%}

DIGITO          [0-9]
LETRA           [a-zA-Z]
IDENTIFICADOR   {LETRA}({LETRA}|{DIGITO}|_)*
NUMERO          {DIGITO}+
ESPACIO         [ \t]+

%%

"/*"([^*]|\*+[^*/])*\*+"/"  { /* Comentario de bloque */ }
"//".*                      { /* Comentario de línea */ }

"int"           { return INT; }
"float"         { return FLOAT; }
"double"        { return DOUBLE; }
"char"          { return CHAR; }
"void"          { return VOID; }
"short"         { return SHORT; }
"return"        { return RETURN; }
"include"       { return INCLUDE; }
"define"        { return DEFINE; }
"if"            { return IF; }
"else"          { return ELSE; }

{IDENTIFICADOR} { 
    yylval.str = strdup(yytext); 
    return ID; 
}

{NUMERO}        { 
    yylval.ival = atoi(yytext); 
    return NUMBER; 
}

"++"            { return INCREMENT; }
"+"             { return '+'; }
"-"             { return '-'; }
"*"             { return '*'; }
"/"             { return '/'; }
"="             { return '='; }
"("             { return '('; }
")"             { return ')'; }
"{"             { return '{'; }
"}"             { return '}'; }
";"             { return ';'; }
","             { return ','; }
"#"             { return '#'; }
"<"             { return '<'; }
">"             { return '>'; }
"."             { return '.'; }

{ESPACIO}       { /* ignorar */ }
\n              { linea++; }

.               { /* ignorar caracteres desconocidos */ }

%%

int yywrap() {
    return 1;
}