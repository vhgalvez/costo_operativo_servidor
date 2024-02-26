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
consumo_watts=125 # Consumo constante en Watts para este ejemplo
consumo_kwh_por_hora=$(echo "scale=3; $consumo_watts / 1000" | bc)

# Función para crear el directorio de salida si no existe
crear_directorio() {
    if [ ! -d "$directorio_salida" ]; then
        mkdir -p "$directorio_salida"
    fi
}

# Función auxiliar para formatear la salida de costos
formatear_costo() {
    local costo=$1
    LC_NUMERIC=C
    if (( $(echo "$costo < 1" | bc -l) )); then
        printf "%.2f céntimos de euro" "$(echo "$costo * 100" | bc)"
    else
        printf "%.2f euros" "$costo"
    fi
}

# Función para calcular el costo desde el último reinicio
calcular_costo_desde_reinicio() {
    # Obtener el tiempo en horas desde el último reinicio
    ultimo_reinicio=$(last reboot -F | head -1 | awk '{print $5, $6, $7, $8, $9}')
    ultimo_reinicio_sec=$(date -d "$ultimo_reinicio" +%s)
    ahora_sec=$(date +%s)
    horas_operativas=$(echo "scale=2; ($ahora_sec - $ultimo_reinicio_sec) / 3600" | bc)

    # Calcular el costo
    consumo_kwh=$(echo "$consumo_kwh_por_hora * $horas_operativas" | bc)
    costo=$(echo "$consumo_kwh * $costo_kwh" | bc)
    echo "Tiempo operativo desde el último reinicio: $horas_operativas horas" >> "$archivo_salida"
    echo "Costo desde el último reinicio: $(formatear_costo $costo)" >> "$archivo_salida"
}

# Función para escribir los resultados en el archivo de salida
escribir_resultados() {
    echo "Reporte de Consumo de Energía" > "$archivo_salida"
    echo "Fecha y Hora de Reporte: $fecha_hora" >> "$archivo_salida"
    echo "-----------------------------------------" >> "$archivo_salida"
    calcular_costo_desde_reinicio
}

main() {
    crear_directorio
    escribir_resultados
}

main
