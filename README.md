# ITBA Raspberry Pi

En este repositorio se encuentran distintos scripts y pequeños programas utilizados para crear las imagenes que utilizan las Raspberry Pi de la cátedra Programación 1 del Instituto Tecnológico de Buenos Aires.

## Organización general del repositorio
Cada script o programa se encuentra en una carpeta distinta de este repositorio.
Cada carpeta contiene su propio README.md con las indicaciones pertinentes (qué hace el código en esa rama, cómo se instala, cómo se ejecuta, etc.).

## Breve descripción del contenido en cada carpeta 
- **autohotspot**: Script encargado de crear automáticamente un punto de acceso (hotspot) cuando no hay conexión WiFi.
- **clear-display**: Limpia el display matricial al iniciar la Raspberry Pi.
- **cloner**: Script para crear imágenes y realizar copias de las mismas en una o múltimples MicroSD.
- **ledboard**: Permite probar el correcto funcionamiento de la plaqueta con 8 LEDs.
- **ledcontrol**: Permite habilitar y deshabilitar el uso de los pines 23 y 24 por el *autohotspot* ya que interfieren con el funcionamiento de la plaqueta de 8 LEDs.
- **setwifi**: Permite establecer las credenciales de la red WiFi.
- **version-mgmt**: Script sencillo para editar y leer un archivo con la versión de la imagen instalada en una determinada RPi. Útil al momento de verificar que los alumnos hayan grabado bien la imagen.

## Utilizar este repositorio
Clonar el repositorio completo mediante
```
git clone https://github.com/mzahnd/ITBA_RaspberryPi
```
Actualmente todos los scripts están escritos en Bash, por lo que debería ser idealmente clonado en una máquina virtual o computadora ejecutando Linux. Si esto no es posible, se puede hacer sobre la misma RPi, con cuidado de no dejar el repo en la imagen grabada para los alumnos.

# Licencias
Exceptuando los scripts de terceros, detallados debajo, todo se encuentra bajo la siguiente licencia.

> MIT License
> 
> Copyright (c) 2021 Martín E. Zahnd \<mzahnd@itba.edu.ar>
> 
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
> 
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Licencia autohotspot
El código original del autohotspot se encuentra bajo la siguiente licencia.

> You may share this script on the condition a reference to RaspberryConnect.com must be included in copies or derivatives of this script. 

Toda modificación hecha en base al mismo junto a los archivos luego creados se encuentran bajo licencia MIT.

## Licencia de PiShrink
Licenciado bajo licencia MIT (previamente citada).

> The MIT License (MIT)
>
> Copyright (c) 2016 Drew Bonasera
