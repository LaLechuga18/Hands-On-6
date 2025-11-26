#include <stdio.h>

int x;
float y;

int suma(int a, int b) {
    int resultado;
    resultado = a + b;
    return resultado;
}

void prueba() {
    int z;
    z = x + 10;   // uso variable global
    //y = w;      // esto debería dar error: w no declarada

    {
        int z;    // shadowing: z local al bloque
        z = 5;
        x = z;
    }

    //int z;      // redeclaracion en el mismo scope: error
}

int main() {
    x = 5;
    y = 3.14;
    int total;
    total = suma(x, 10);
    
    if (total > 10) 
        x = total;
    else 
        y = 0;

    prueba();

    return 0;
}
