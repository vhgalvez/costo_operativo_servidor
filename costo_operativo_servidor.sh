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
horas_por_dia=24
dias_por_mes=30

crear_directorio() {
    if [ ! -d "$directorio_salida" ]; then
        mkdir -p "$directorio_salida"
    fi
}

capturar_datos() {
    # Captura la temperatura promedio de los núcleos.
    temperatura=$(sensors | grep -E 'Core [0-9]+:' | awk '{print $3}' | sed 's/+//g' | awk '{sum+=$1} END {print sum/NR "°C"}')
    # Captura el consumo de energía.
    consumo_watts=$(sensors | grep -m 1 'power1:' | awk '{print $2}' | sed 's/W//')
    consumo_kwh_por_hora=$(echo "scale=3; $consumo_watts / 1000" | bc)
    costo_por_hora=$(echo "scale=2; $consumo_kwh_por_hora * $costo_kwh" | bc)
    consumo_kwh_por_dia=$(echo "scale=2; $consumo_kwh_por_hora * $horas_por_dia" | bc)
    costo_por_dia=$(echo "scale=2; $consumo_kwh_por_dia * $costo_kwh" | bc)
    consumo_kwh_mensual=$(echo "scale=2; $consumo_kwh_por_dia * $dias_por_mes" | bc)
    costo_mensual=$(echo "scale=2; $consumo_kwh_mensual * $costo_kwh" | bc)
}

calcular_tiempo_funcionamiento() {
    inicio=$(date -d "$(uptime -s)" +%s)
    ahora=$(date +%s)
    segundos_encendido=$((ahora - inicio))
    horas_encendido=$(echo "scale=2; $segundos_encendido / 3600" | bc)
    consumo_kwh_encendido=$(echo "scale=2; $consumo_kwh_por_hora * $horas_encendido" | bc)
    costo_por_tiempo_encendido=$(echo "scale=2; $consumo_kwh_encendido * $costo_kwh" | bc)
}

escribir_resultados() {
    echo "Métrica                                         Valor" > "$archivo_salida"
    echo "-------                                         -----" >> "$archivo_salida"
    echo "" >> "$archivo_salida"
    echo "Temperatura Promedio de los Núcleos:            $temperatura" >> "$archivo_salida"
    echo "Consumo de Energía (Watts):                     $consumo_watts W" >> "$archivo_salida"
    echo "" >> "$archivo_salida"

    # Define una función para convertir y formatear el costo.
    formatear_costo() {
        local costo=$1
        if (( $(echo "$costo < 1" | bc -l) )); then
            echo "$(echo "$costo * 100" | bc) céntimos de euro"
        else
            echo "$costo euros"
        fi
    }

    echo "Consumo por hora estimado:                      ${consumo_kwh_por_hora} kWh" >> "$archivo_salida"
    echo "Costo por hora estimado:                        $(formatear_costo $costo_por_hora)" >> "$archivo_salida"
    echo "" >> "$archivo_salida"
    echo "Consumo por día estimado:                       ${consumo_kwh_por_dia} kWh" >> "$archivo_salida"
    echo "Costo por día estimado:                         $(formatear_costo $costo_por_dia)" >> "$archivo_salida"
    echo "" >> "$archivo_salida"
    echo "Consumo mensual estimado:                       ${consumo_kwh_mensual} kWh" >> "$archivo_salida"
    echo "Costo mensual estimado:                         $(formatear_costo $(echo "$costo_mensual / 100" | bc -l))" >> "$archivo_salida"
    echo "" >> "$archivo_salida"
    echo "Tiempo encendido:                               ${horas_encendido} horas" >> "$archivo_salida"
    echo "Consumo por el tiempo encendido hoy:            ${consumo_kwh_encendido} kWh" >> "$archivo_salida"
    echo "Costo por el tiempo encendido hoy:              $(formatear_costo $costo_por_tiempo_encendido)" >> "$archivo_salida"
    echo "" >> "$archivo_salida"
    echo "Resultados guardados en $archivo_salida."
}

# Asegúrate de definir y calcular las variables de costo correctamente antes de llamar a esta función.



main() {
    crear_directorio
    capturar_datos
    calcular_tiempo_funcionamiento
    escribir_resultados
}

main
exit 0
