# Guía para Instalar lm_sensors y Monitorear Temperatura y Consumo en Rocky Linux

## Instalación de lm_sensors

1. **Abrir una terminal.**

2. **Instalar lm_sensors**

   Ejecuta el siguiente comando para instalar lm_sensors:

   ```bash
   sudo dnf install lm_sensors
   sudo sensors-detect
   ```

3. **Comprobar la instalación**

   Comprueba que lm_sensors está correctamente instalado y funcionando:

   ```bash
   sensors
   ```

## Uso del Script para Monitoreo

1. **Creación del script**

   Crea un archivo llamado `consumo_temperatura.sh`.

2. **Contenido del script**

   Copia y pega el contenido del script proporcionado en tu nuevo archivo.

3. **Hacer el script ejecutable**

   Concede permisos de ejecución al script:

   ```bash
   sudo chown -R $USER:$USER /home/$USER/costo_operativo_servidor
   ```

4. **Ejecutar el script**

   Inicia el script con el siguiente comando para ver la temperatura y el consumo de energía:

   ```bash
   ./costo_operativo_servidor.sh
   ```

Siguiendo estos pasos podrás instalar lm_sensors y utilizar un script para monitorear eficazmente la temperatura y el consumo de energía en tu sistema Rocky Linux. Además, este proceso incluirá el cálculo del costo mensual basado en tus variables de consumo.
```

cat salida_consumo_temperatura_2024-02-25_21-11-47.txt

# comando para ver la temperatura y el consumo de energía en Rocky Linux manualmente

   ```bash
sudo sh -c 'sensors > /home/victory/infra_code/info/consumo_temperatura.txt'
```
rtetdf

# https://www.linuxtotal.com.mx/index.php?cont=distintas-maneras-uptime


Cambiar la propiedad del directorio y sus archivos al usuario actual (ya lo has hecho, pero lo incluyo para completitud):
bash
Copy code
sudo chown -R $USER:$USER /home/$USER/costo_operativo_servidor
Otorgar permisos de ejecución al script:
bash
Copy code
chmod +x ./costo_operativo_servidor.sh
Ejecutar el script como usuario regular (no como root):
bash
Copy code
./costo_operativo_servidor.sh
Con estos pasos, tu script costo_operativo_servidor.sh debería ejecutarse correctamente, mostrando la salida deseada sin errores de permisos.