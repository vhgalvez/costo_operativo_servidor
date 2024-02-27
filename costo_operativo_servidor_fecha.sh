#!/bin/bash

# Prevenir ejecución como root
if [ "$(id -u)" -eq 0 ]; then
    echo "Este script no debe ser ejecutado como root. Por favor, ejecute como un usuario regular."
    exit 1
fi

set -euo pipefail

LC_NUMERIC=C
fecha_hora=$(date "+%Y-%m-%d_%H-%M-%S")
directorio_salida="/home/$USER/costo_operativo_servidor"
archivo_salida="${directorio_salida}/reporte_consumo_${fecha_hora}.txt"
costo_kwh=0.189 # Costo por kWh
consumo_watts=125 # Consumo en watts del servidor
consumo_kwh_por_hora=$(echo "scale=3; $consumo_watts / 1000" | bc) # Conversión a kWh

# Crear directorio si no existe
crear_directorio() {
    mkdir -p "$directorio_salida"
}

# Calcular el costo dado el número de horas
calcular_costo() {
    local horas=$1
    local consumo_kwh=$(echo "$horas * $consumo_kwh_por_hora" | bc)
    local costo=$(echo "$consumo_kwh * $costo_kwh" | bc)
    printf "%.2f euros\n" "$costo"
}

# Procesar cada línea del comando 'last -F reboot'
procesar_linea() {
    local linea="$1"
    # Extraer información de fecha y hora de inicio y fin
    local fecha=$(echo "$linea" | awk '{print $5, $6, $7}')
    local hora_inicio=$(echo "$linea" | awk '{print $8}')
    local hora_fin=$(echo "$linea" | awk '{print $10}' | sed 's/-//')
    
    # Ajustar "still running" a la hora actual
    if [[ "$hora_fin" == *"still"* ]]; then
        hora_fin=$(date "+%H:%M")
    fi

    # Convertir a segundos para calcular duración
    local inicio_sec=$(date -d "$fecha $hora_inicio" +%s)
    local fin_sec=$(date -d "$fecha $hora_fin" +%s)
    local duracion_sec=$((fin_sec - inicio_sec))
    local horas=$(echo "scale=2; $duracion_sec / 3600" | bc)

    # Calcular costo
    local costo=$(calcular_costo "$horas")
    echo "$(date -d "@$inicio_sec" "+%Y-%m-%d"): $horas horas, Costo: $costo" >> "$archivo_salida"
}

# Generar el reporte
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
