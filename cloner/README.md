# RPi Cloner

## ¿Qué hago?
Este script (conjunto de scripts, en realidad) permite crear un archivo .img a partir de una Micro SD con un sistema Raspbian dentro y clonar un archivo .img en una o varias Micro SD.

## Instrucciones
Ejecutar únicamente el script `runMe.sh`. Este hará todo el trabajo (incluso el de marcar los subscripts como ejecutables cuando sea necesario) e indicará los pasos a seguir.

```
~]$ chmod +x runMe.sh
~]$ ./runMe.sh
```

El archivo `Cloner_ShortManual.pdf` brinda un breve manual de cómo utilizar el script para clonar una imagen en una o varias tarjetas Micro SD.
El markdown de este PDF se encuentra en la carpeta `markdown`, junto con las imágenes utilizadas para crearlo.

> **NOTA:** Tener en cuenta que este script está pensado para ejecutarse sobre imágenes creadas para las Rasberry Pi de la cátedra Programación 1 del ITBA, por lo que edita archivos incluídos dentro de estas imágenes (como el de autohotspot).
> Si se desea utilizar en otros proyectos debe leerse el código fuente con detenimiento y realizar las modificaciones pertinentes.

## Organización del código fuente
A continuación se explica brevemente cómo está organizado el código fuente.

Code tree
```
 .
 ├── runMe.sh
 └── scripts
     ├── cloner
     │   ├── burnImageinSD.sh
     │   ├── cloner.sh
     │   ├── createImage.sh
     │   └── pishrink
     │       ├── LICENSE
     │       ├── pishrink.log
     │       ├── pishrink.sh
     │       └── README.md
     ├── common
     │   ├── changeHostname.sh
     │   ├── checkExistence.sh
     │   ├── colors.sh
     │   ├── getFilePathName.sh
     │   ├── getImage.sh
     │   ├── getMicroSD.sh
     │   └── runScript.sh
     └── creator
         ├── prepareRPi.sh
         ├── sdCreator.sh
         └── setWiFi.sh
```

### runMe.sh
Script principal.
Verifica que se cumplan las dependencias necesarias y actúa a su vez de "menú principal".
Depende de: 
- `scripts/common/colors.sh`
- `scripts/common/runScript.sh`

### scripts/common
Estos scripts realizan funciones comúnes para aquellos que se encuentran en `scripts/cloner` y `scripts/creator`.

#### changeHostname.sh
Permite modificar el nombre del hotspot de la imagen grabada.
Depende de:
- `colors.sh`
- `getFilePathName.sh`
- `checkExistence.sh`

#### checkExistence.sh
Verifica si un archivo existe, es legible y tiene o no tamaño mayor a cero.

#### colors.sh
Simple tabla con colores. Casi todos los scripts hacen uso de este.

#### getFilePathName.sh
Contiene dos funciones, que permiten obtener el nombre de un archivo o la dirección donde se encuentra el mismo.

#### getImage.sh
Permite al usuario ingresar un archivo de imagen para clonar.
depende de:
- `colors.sh`.

#### getMicroSD.sh
Guía al usuario para poder detecta tarjetas Micro SD conectadas en la computadora. Es capaz de detectar si se conecta más de una a la vez y permite elegir al usuario cómo proceder.
Depende de:
- `colors.sh`.

#### runScript.sh
Permite ejecutar otro script con sus argumentos correspondientes.
Depende de:
- `getFilePathName.sh`

### scripts/cloner
Scripts para crear una imagen a partir de una Micro SD o clonar la misma en una o varias Micro SD.

#### burnImageinSD.sh
Graba una imagen en una o varias Micro SD. Utiliza `dd`.
También llama a las funciones de `../scripts/common/changeHostname.sh` para cambiar el nombre del Hotspot.

Depende de:
- `../common/changeHostname.sh`
- cloner.sh (Utiliza las dependencias del mismo)

#### cloner.sh
Menú principal de la utilidad para clonar.

Depende de:
- `../common/colors.sh`
- `../common/getFilePathName.sh`
- `../common/checkExistence.sh`
- `../common/runScript.sh`
- `../common/getMicroSD.sh`
- `../common/getImage.sh`
- `../common/changeHostname.sh`
- `burnImageinSD.sh` (a su vez este depende de `cloner.sh`)
- `createImage.sh` (a su vez este depende de `cloner.sh`)
- `pishrink/pishrink.sh`

#### createImage.sh
Crea una imagen (y le asigna extensión `.img`) comprimida (con PiShrink) a partir de una MicroSD. Utiliza `dd`.

Depende de:
- cloner.sh (Utiliza las dependencias del mismo)
- `pishrink/pishrink.sh`

#### pishrink
Utilizado para comprimir la imagen creada a partir de la Micro SD. Contiene su propio README.
[Repositorio de PiShrink](https://github.com/Drewsif/PiShrink)

### scripts/creator
El único script que tiene sentido dentro de esta carpeta es `sdCreator.sh`, cuya funcionalidad, por ahora, es imprimir un mensaje de que no está terminado.
Forma parte del TODO.
Depende de:
- `../common/colors.sh`
- `../common/runScript.sh`

## TODO
La función de crear una imagen está incompleta. El script es únicamente capaz de clonar Micro SDs (crear imágenes y grabarlas en otra(s) Micro SD(s)).

