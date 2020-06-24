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

