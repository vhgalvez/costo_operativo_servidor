#!/bin/bash

# Evita la ejecución como root
if [ "$(id -u)" -eq 0 ]; then
    echo "Este script no debe ser ejecutado como root. Por favor, ejecute como un usuario regular."
    exit 1
fi

set -e
set -o errexit
set -o nounset

# Variables globales
fecha_hora=$(date "+%Y-%m-%d_%H-%M-%S")
directorio_salida="/home/$USER/costo_operativo_servidor"
archivo_salida="${directorio_salida}/salida_consumo_temperatura_${fecha_hora}.txt"
costo_kwh=0.189
consumo_watts=125 # Ajuste este valor según su sistema
consumo_kwh_por_hora=$(echo "scale=3; $consumo_watts / 1000" | bc)

# Crea el directorio de salida si no existe
crear_directorio() {
    mkdir -p "$directorio_salida"
}

# Calcula el costo en base a las horas de funcionamiento
calcular_costo() {
    local horas=$1
    local consumo_kwh=$(echo "$horas * $consumo_kwh_por_hora" | bc)
    local costo=$(echo "$consumo_kwh * $costo_kwh" | bc)
    echo $(printf "%.2f" $costo)
}

# Procesa cada línea de "last reboot"
procesar_linea() {
    local fecha=$(echo $1 | awk '{print $5, $6, $7}')
    local inicio=$(echo $1 | awk '{print $8}')
    local fin=$(echo $1 | awk '{print $9}')

    # Ajusta para entradas "still running"
    if [[ "$fin" == *"still"* ]]; then
        fin=$(date "+%H:%M")
    fi

    # Calcula segundos de inicio y fin
    local inicio_sec=$(date -d "$fecha $inicio" +%s)
    local fin_sec=$(date -d "$fecha $fin" +%s)
    local duracion_sec=$(($fin_sec-$inicio_sec))
    local horas=$(echo "scale=2; $duracion_sec / 3600" | bc)

    local costo=$(calcular_costo $horas)

    echo "$fecha: $horas horas, Costo: €$costo" >> "$archivo_salida"
}

# Genera el reporte
generar_reporte() {
    echo "Reporte de Consumo Energético - $fecha_hora" > "$archivo_salida"
    echo "-------------------------------------------" >> "$archivo_salida"
    last -F reboot | grep -v wtmp | while read line; do
        procesar_linea "$line"
    done
}

main() {
    crear_directorio
    generar_reporte
}

main