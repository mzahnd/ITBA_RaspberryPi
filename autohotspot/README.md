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


