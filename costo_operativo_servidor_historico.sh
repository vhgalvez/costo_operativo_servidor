#!/bin/bash

if [ "$(id -u)" -eq 0 ]; then
    echo "Este script no debe ser ejecutado como root. Por favor, ejecute como un usuario regular."
    exit 1
fi

set -e
set -o errexit
set -o nounset

LC_NUMERIC=C
fecha_hora=$(date "+%Y-%m-%d_%H-%M-%S")
directorio_salida="/home/$USER/costo_operativo_servidor"
archivo_salida="${directorio_salida}/salida_consumo_temperatura_${fecha_hora}.txt"
costo_kwh=0.189
consumo_watts=125
consumo_kwh_por_hora=$(echo "scale=3; $consumo_watts / 1000" | bc)

crear_directorio() {
    mkdir -p "$directorio_salida"
}

calcular_costo() {
    local horas=$(echo "$1" | awk '{print ($1>=0)?$1:0}') # Asegura que las horas sean no negativas
    local consumo_kwh=$(echo "$horas * $consumo_kwh_por_hora" | bc)
    local costo=$(echo "$consumo_kwh * $costo_kwh" | bc)
    echo $(printf "%.2f euros" $costo)
}

procesar_linea() {
    local linea="$1"
    # Asume formato de 'last -F' como "reboot system boot [fecha] [hora inicio] - [hora fin]"
    local fecha=$(echo "$linea" | awk '{print $7, $6, $8}')
    local hora_inicio=$(echo "$linea" | awk '{print $9}')
    local hora_fin=$(echo "$linea" | awk '{print $11}' | sed 's/-//')

    if [[ "$hora_fin" == *"still"* ]]; then
        hora_fin=$(date "+%H:%M")
    fi

    local inicio_sec=$(date -d "$fecha $hora_inicio" +%s)
    local fin_sec=$(date -d "$fecha $hora_fin" +%s)
    local duracion_sec=$((fin_sec - inicio_sec))
    local horas=$(echo "scale=2; $duracion_sec / 3600" | bc)

    local costo=$(calcular_costo $horas)
    echo "$(date -d "@$inicio_sec" "+%Y-%m-%d"): $horas horas, Costo: $costo" >> "$archivo_salida"
}

generar_reporte() {
    echo "Reporte de Consumo Energético - $fecha_hora" > "$archivo_salida"
    echo "-------------------------------------------" >> "$archivo_salida"
    last -F reboot | grep -v wtmp | grep -v "reboot system boot" | tac | while read -r line ; do
        procesar_linea "$line"
    done
}

main() {
    crear_directorio
    generar_reporte
}

main
