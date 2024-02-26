#!/bin/bash

# Evita la ejecución como root
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
    local fecha_inicio=$(echo "$linea" | awk '{print $6, $7, $8, $9}')
    local fecha_fin=$(echo "$linea" | awk '{print $11, $12, $13, $14}')
    local inicio_sec=$(date -d "$fecha_inicio" +%s 2>/dev/null || echo "")
    local fin_sec=$(date -d "$fecha_fin" +%s 2>/dev/null || echo "")

    # Comprueba si fin_sec es menor que inicio_sec o si están vacíos y ajusta
    if [[ -z "$inicio_sec" || -z "$fin_sec" || "$fin_sec" -lt "$inicio_sec" ]]; then
        echo "Error en la línea: $linea" >&2
        return
    fi

    local duracion_sec=$((fin_sec - inicio_sec))
    local horas=$(echo "scale=2; $duracion_sec / 3600" | bc)

    local costo=$(calcular_costo $horas)
    echo "$(date -d "@$inicio_sec" "+%Y-%m-%d %H:%M"): $horas horas, Costo: $costo" >> "$archivo_salida"
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

