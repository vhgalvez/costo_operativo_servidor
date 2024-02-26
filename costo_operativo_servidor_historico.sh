#!/bin/bash

LC_NUMERIC=C

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
    printf "%.2f" $(echo "$costo" | bc)
}

procesar_linea() {
    local linea="$1"
    # Extracción y corrección de las fechas de inicio y fin
    # ... código para manejar las fechas de inicio y fin ...

    local costo=$(calcular_costo $horas)
    # Asegura que se imprima la fecha en el formato deseado y maneja el costo correctamente
    echo "$(date -d "@$inicio_sec" "+%Y-%m-%d"): $horas horas, Costo: €$costo" >> "$archivo_salida"
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
