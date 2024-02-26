#!/bin/bash

# Comprobación para evitar la ejecución como root
if [ "$(id -u)" -eq 0 ]; then
    echo "Este script no debe ser ejecutado como root. Por favor, ejecute como un usuario regular."
    exit 1
fi

set -e
set -o errexit
set -o nounset

fecha_hora=$(date "+%Y-%m-%d_%H-%M-%S")
directorio_salida="/home/$USER/costo_operativo_servidor"
archivo_salida="${directorio_salida}/salida_consumo_temperatura_${fecha_hora}.txt"
costo_kwh=0.189
consumo_watts=125 # Ajusta este valor según tu sistema
consumo_kwh_por_hora=$(echo "scale=3; $consumo_watts / 1000" | bc)

# Función para crear el directorio de salida si no existe
crear_directorio() {
    mkdir -p "$directorio_salida"
}

# Función para calcular el costo en base a las horas de funcionamiento
calcular_costo() {
    local horas=$1
    local consumo_kwh=$(echo "$horas * $consumo_kwh_por_hora" | bc)
    local costo=$(echo "$consumo_kwh * $costo_kwh" | bc)
    echo $(printf "%.2f" $costo)
}

# Función para procesar cada línea de "last -F reboot"
procesar_linea() {
    local linea=$1
    local fecha=$(echo $linea | awk '{print $5, $6, $7}')
    local inicio=$(echo $linea | awk '{print $8}')
    local fin=$(echo $linea | awk '{print $9}')

    if [[ "$fin" == *"still"* ]]; then
        fin=$(date "+%H:%M")
    fi

    local inicio_sec=$(date -d "$fecha $inicio" +%s)
    local fin_sec=$(date -d "$fecha $fin" +%s)
    local duracion_sec=$(($fin_sec-$inicio_sec))
    local horas=$(echo "scale=2; $duracion_sec / 3600" | bc)

    local costo=$(calcular_costo $horas)

    echo "$fecha: $horas horas, Costo: €$costo" >> "$archivo_salida"
}

# Generar el reporte
generar_reporte() {
    echo "Reporte de Consumo Energético - $fecha_hora" > "$archivo_salida"
    echo "-------------------------------------------" >> "$archivo_salida"
    last -F reboot | while read line; do
        procesar_linea "$line"
    done
}

main() {
    crear_directorio
    generar_reporte
}

main
