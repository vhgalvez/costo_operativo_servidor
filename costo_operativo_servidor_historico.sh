#!/bin/bash

# Evita la ejecución como root
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
consumo_watts=125
consumo_kwh_por_hora=$(echo "scale=3; $consumo_watts / 1000" | bc)

crear_directorio() {
    mkdir -p "$directorio_salida"
}

calcular_costo() {
    local horas=$1
    local consumo_kwh=$(echo "$horas * $consumo_kwh_por_hora" | bc)
    local costo=$(echo "$consumo_kwh * $costo_kwh" | bc)
    echo $(printf "%.2f" $costo)
}

procesar_linea() {
    local linea="$1"
    local fecha_inicio=$(echo "$linea" | awk '{print $6, $7, $8, $9}')
    local fecha_fin=$(echo "$linea" | awk '{print $11, $12, $13, $14}')
    local fecha_fin_corr=$(echo "$linea" | grep -oP '(\d{4}-\d{2}-\d{2} \d{2}:\d{2})' | tail -1)

    if [[ -z "$fecha_fin_corr" ]]; then
        fecha_fin_corr=$(date "+%Y-%m-%d %H:%M")
    fi

    local inicio_sec=$(date -d "$fecha_inicio" +%s)
    local fin_sec=$(date -d "$fecha_fin_corr" +%s)
    local duracion_sec=$((fin_sec - inicio_sec))
    local horas=$(echo "scale=2; $duracion_sec / 3600" | bc)

    if (( $(echo "$horas < 0" | bc -l) )); then
        horas=0
    fi

    local costo=$(calcular_costo $horas)
    echo "$(date -d "$fecha_inicio" "+%Y-%m-%d"): $horas horas, Costo: €$costo" >> "$archivo_salida"
}

generar_reporte() {
    echo "Reporte de Consumo Energético - $fecha_hora" > "$archivo_salida"
    echo "-------------------------------------------" >> "$archivo_salida"
    last -F reboot | grep -v wtmp | tac | while read -r line ; do
        procesar_linea "$line"
    done
}

main() {
    crear_directorio
    generar_reporte
}

main
