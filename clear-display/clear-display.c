/*
 * Copyright 2020 Martin E. Zahnd <mzahnd@itba.edu.ar>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to 
 * deal in the Software without restriction, including without limitation the 
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
 * sell copies of the Software, and to permit persons to whom the Software is 
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in 
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
 * THE SOFTWARE.
*/

/*
    Turns on the outmost corners
*/

#include <stdio.h>
#include "disdrv.h"
#include "termlib.h"

int main(void)
{
    // Inicializa myPoint en (0,0).
    // Inicializa el display
    disp_init();
    // Limpia todo el display
    disp_clear();

    dcoord_t myPoint ={};

    // Esquina superior izquierda
    myPoint.x = DISP_MIN;
    myPoint.y = DISP_MIN;
    disp_write(myPoint, D_ON);

    // Esquina superior derecha
    myPoint.x = DISP_MAX_X;
    myPoint.y = DISP_MIN;
    disp_write(myPoint, D_ON);

    // Esquina inferior izquierda
    myPoint.x = DISP_MIN;
    myPoint.y = DISP_MAX_Y;
    disp_write(myPoint, D_ON);

    // Esquina inferior derecha
    myPoint.x = DISP_MAX_X;
    myPoint.y = DISP_MAX_Y;
    disp_write(myPoint, D_ON);

    // Actualiza el display con las nuevas cuatro coordenadas.
    disp_update();

    return 0;
}

