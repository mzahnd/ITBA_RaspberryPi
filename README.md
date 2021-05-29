<<<<<<< HEAD
# ITBA Raspberry Pi

En este repositorio se encuentran distintos scripts y pequeños programas utilizados para crear las imagenes que utilizan las Raspberry Pi de la cátedra Programación 1 del Instituto Tecnológico de Buenos Aires.

## Organización general del repositorio
Cada script o programa se encuentra en una rama (branch) distinta de este repositorio con la finalidad de mantener su correcta separación al mismo tiempo en que se mantienen _todas las piezas del rompecabezas en la misma caja_.
Cada rama contiene su propio README con las indicaciones pertinentes (qué hace el código en esa rama, cómo se instala, cómo se ejecuta, etc.).

## Breve descripción de cada rama
- **master**: Únicamente contiene este README y el archivo con la licencia.
- **clearDisplay**: Limpia el display matricial al iniciar la Raspberry Pi.
- **setWiFi**: Permite establecer las credenciales de la red WiFi.

## Utilizar este repositorio
Clonar el repositorio completo mediante
```
git clone https://github.com/mzahnd/ITBA_RaspberryPi
```

A continuación, cambiar a la rama con la cual se desea trabajar empleando los siguientes comandos.
```
git branch                      # Muestra la actual (con un * a la izquierda)
git branch -a                   # Muestra todas las ramas en el repositorio
git checkout autohotspot        # Cambia a la rama 'autohotspot' (reemplazar esto último por la rama deseada).
```

---

# AutoHotspot

## ¿Qué hago?
Este script intenta conectarse a una red inalámbrica previamente configurada en `/etc/wpa_supplicant/wpa_supplicant.conf`.
En caso de no lograrlo, entra en modo hotspot permitiendo el acceso a la Raspberry Pi desde su propia red inalámbrica.

La IP de la Raspberry Pi en modo hotspot es `10.0.0.5`.


## Instrucciones

Editar el archivo `autohotspot_switch` y cambiar las siguientes variables
- `LEDS_ENABLE` 1 para habilitar el uso de leds de estado (por defecto); 0 para deshabilitar.
- `LEDS_AMMOUNT` Acepta como válido un 2 (por defecto) ó 3, el primero es para utilizar los leds de la placa de display matricial+joystick, el segundo para utilizar 3 leds, originalmente conectados en los pines (BCM) 5, 13 y 26. ^[Estos pueden ser modificados cambiando los valores en la tabla `LEDS3_GPIO` dentro del archivo `autohotspot_ledcontrol`.] ^[Ver también [Raspberry Pi Pinout](https://pinout.xyz/)]

Copiar los archivos que se encuentran en la carpeta `scruot` dentro de `/usr/bin/`.

Copiar el archivo dentro de la carpeta `service` en `/etc/systemd/system/` y ejecutar
```console
~]# systemctl enable autohotspot.service
~]# systemctl start autohotspot.service
```

## Tabla con el significado de los LEDs

### 3 LEDs
Tabla con el significado de cada LED o combinación de ellos.

| WAIT | HSPT | WIFI | |
|:---:|:---:|:---:|:---|
| X |   |   | Cargando |
|   | X |   | Modo Hotspot |
| X | X |   | Modo Hotspot. No fue posible establecer la conexión con la red Wi-Fi. |
|   |   | X | Conectado a la red Wi-Fi |
| X | X | X | No se encontró ningún dispositivo Wi-Fi |

> Cuando no es posible establecer la conexión a una red Wi-Fi suele ser a causa de haber ingresado una contraseña incorrecta.

| Nombre del led | Pin de salida (BCM) |
| :---: | :---: |
| WAIT | 5 | 
| HSPT | 13 |
| WIFI | 26 |

### 2 LEDs
Tabla con el significado de cada LED o combinación de ellos.

| WAIT/HSPT | WIFI | |
|:---:|:---:|:---|
| X | X | Cargando |
| X |   | Modo Hotspot |
| X |   | Modo Hotspot. No fue posible establecer la conexión con la red Wi-Fi. |
|   | X | Conectado a la red Wi-Fi |
| X | X | No se encontró ningún dispositivo Wi-Fi |

> Cuando no es posible establecer la conexión a una red Wi-Fi suele ser a causa de haber ingresado una contraseña incorrecta.

| Nombre del led | Plaqueta de Joystick + Display matricial |
| :---: | :---: |
| WAIT/HSPT | D3 (rojo) | 
| WIFI | D4 (verde) |

## Fuente
El script original fue tomado de la siguiente publicación en [Raspberry Connect](https://www.raspberryconnect.com/). 

[Raspberry Pi - Auto WiFi Hotspot Switch - Direct Connection](https://www.raspberryconnect.com/projects/65-raspberrypi-hotspot-accesspoints/158-raspberry-pi-auto-wifi-hotspot-switch-direct-connection)

Al mismo se le realizaron modificaciones principalmente con el objetivo de poder utilizar LEDs como indicadores del estado de conexión.

---

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

# Licencias
El código original del autohotspot se encuentra bajo la siguiente licencia.
> You may share this script on the condition a reference to RaspberryConnect.com must be included in copies or derivatives of this script. 

Toda modificación hecha en base al mismo junto a los archivos luego creados se encuentran bajo licencia MIT.

> MIT License
> 
> Copyright (c) 2020 Martín E. Zahnd \<mzahnd@itba.edu.ar>
> 
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
> 
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
