# clearDisplay

## ¿Qué hago?
Me ejecuto una (única) vez al iniciar el sistema operativo, borro el display matricial y enciendo las cuatro esquinas exteriores de la matriz.

## Instrucciones
clearDisp.c tiene que ser compilado con las librerías `disdrv` y `termlib`.
Su ejecutable compilado debe ser guardado en /usr/bin/ con el nombre clearDisp (full path: `/usr/bin/clearDisp`).
Luego, se copia el archivo `clearDisp.service` en `/etc/systemd/system/` (full: `/etc/systemd/system/clearDisp.service`) y se ejecuta el siguiente comando:
```
~]# systemctl enable clearDisp.service
```
De este modo, queda habilitado el servicio y se ejecutará la próxima vez que se incie la Raspberry Pi.

> Notar que sólo se verá el efecto que realiza el mismo si se inicia la Raspberry Pi con el display matricial conectado.

## Aclaraciones
Este es un servicio del tipo `oneshot`. Es decir, se ejecuta **una única vez** al inciar el sistema operativo.
Luego, **no** realiza interferencia alguna con el display matricial y su uso.

Si se quiere probar la correcta instalación del mismo, luego de haberlo habilitado, es posible ejecutar el siguiente comando.
```
~]# systemctl start clearDisp.service
```
## Licencia
> MIT License
> 
> Copyright (c) 2020 Martín E. Zahnd \<mzahnd@itba.edu.ar>
> 
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
> 
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
