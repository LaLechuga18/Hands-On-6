# Hands-On-6
# Integrantes
- Angel Sebastian Garnica Carbajal
- Jair Ruvalcaba Prieto

# Descripción
Este proyecto implementa un compilador básico en C usando Flex y Bison.
Permite analizar código en un subconjunto de C y detectar errores semánticos como:
- Variables no declaradas.
- Redeclaración de variables o funciones.
- Manejo de scopes locales y globales.
- Llamadas a funciones no declaradas.

# Archivos del proyecto
- lexer.l: Analizador léxico (tokens, identificadores, números, operadores).
- parser.y: Analizador sintáctico y semántico (tabla de símbolos, scopes).
- input.c: Código de prueba para verificar el compilador.

# Cómo usarlo
1. Generar lexer y parser:
   - bison -d parser.y
   - flex lexer.l
   - gcc lex.yy.c y.tab.c -o hands-on-6.exe
2. Ejecutar el compilador sobre un archivo de prueba:
   - Get-Content input.c | .\compilador.exe  (PowerShell)
   - type input.c | compilador.exe  (CMD)
3. Ver la salida: declaraciones, asignaciones y errores semánticos.

