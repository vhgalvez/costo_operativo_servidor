#!/bin/bash

# Comprobación para evitar la ejecución como root
if [ "$(id -u)" -eq 0 ]; then
    echo "Este script no debe ser ejecutado como root. Por favor, ejecute como un usuario regular."
    exit 1
fi

set -e
set -o errexit  # Finaliza el script si un comando falla.
set -o nounset  # Finaliza el script si se intenta usar una variable no declarada.

fecha_hora=$(date "+%Y-%m-%d_%H-%M-%S")
directorio_salida="/home/$USER/costo_operativo_servidor"
archivo_salida="${directorio_salida}/salida_consumo_temperatura_${fecha_hora}.txt"
costo_kwh=0.189
horas_por_dia=24
dias_por_mes=30

# Función para crear el directorio de salida si no existe.
crear_directorio() {
    if [ ! -d "$directorio_salida" ]; then
        mkdir -p "$directorio_salida"
    fi
}

# Función para capturar los datos de los sensores y calcular el consumo.
capturar_datos() {
    temperatura=$(sensors | grep -i 'core 0' | awk '{print $3}')
    consumo_watts=$(sensors | grep -i 'power1' | awk '{print $2}' | sed 's/W//')
    consumo_kwh_por_hora=$(echo "scale=3; $consumo_watts / 1000" | bc)
    costo_por_hora=$(echo "scale=2; $consumo_kwh_por_hora * $costo_kwh" | bc)
    consumo_kwh_por_dia=$(echo "scale=2; $consumo_kwh_por_hora * $horas_por_dia" | bc)
    costo_por_dia=$(echo "scale=2; $consumo_kwh_por_dia * $costo_kwh" | bc)
    consumo_kwh_mensual=$(echo "scale=2; $consumo_kwh_por_dia * $dias_por_mes" | bc)
    costo_mensual=$(echo "scale=2; $consumo_kwh_mensual * $costo_kwh" | bc)
}

# Función para calcular el tiempo de funcionamiento y el costo asociado.
calcular_tiempo_funcionamiento() {
    inicio=$(date -d "$(uptime -s)" +%s)
    ahora=$(date +%s)
    segundos_encendido=$((ahora - inicio))
    horas_encendido=$(echo "scale=2; $segundos_encendido / 3600" | bc)
    consumo_kwh_encendido=$(echo "scale=2; $consumo_kwh_por_hora * $horas_encendido" | bc)
    costo_por_tiempo_encendido=$(echo "scale=2; $consumo_kwh_encendido * $costo_kwh" | bc)
}

# Función para obtener la información del último reinicio y calcular el tiempo operativo desde entonces.
calcular_tiempo_desde_ultimo_reinicio() {
    # Obtener la fecha y hora del último reinicio del sistema.
    last_reboot_time=$(last reboot -F | head -n 1 | awk '{print $5, $6, $7, $8, $9}')
    # Convertir la fecha y hora del último reinicio en segundos desde la época.
    last_reboot_seconds=$(date -d "$last_reboot_time" +%s)
    # Obtener la hora actual en segundos desde la época.
    now_seconds=$(date +%s)
    # Calcular la diferencia en segundos.
    uptime_seconds=$((now_seconds - last_reboot_seconds))
    # Convertir segundos en horas.
    uptime_hours=$(echo "scale=2; $uptime_seconds / 3600" | bc)
    echo "Tiempo desde el último reinicio: $uptime_hours horas"
}

# Define una función auxiliar para formatear la salida de costos
formatear_costo() {
    local costo=$1
    # Convertir a céntimos si el valor es menor que 1 euro
    if (( $(echo "$costo < 1" | bc -l) )); then
        # Formatear a dos decimales y agregar 'céntimos de euro'
        printf "%.2f céntimos de euro" "$(echo "$costo * 100" | bc)"
    else
        # Formatear a dos decimales y agregar 'euros'
        printf "%.2f euros" "$costo"
    fi
}

# Función para escribir los resultados en el archivo de salida de forma más legible.
escribir_resultados() {
    echo "Métrica                                         Valor" > "$archivo_salida"
    echo "-------                                         -----" >> "$archivo_salida"
    echo "" >> "$archivo_salida"
    echo "Temperatura Promedio de los Núcleos:            $temperatura" >> "$archivo_salida"
    echo "Consumo de Energía (Watts):                     $consumo_watts W" >> "$archivo_salida"
    echo "" >> "$archivo_salida"
    echo "Costos:" >> "$archivo_salida"
    echo "Métrica                                         Valor" >> "$archivo_salida"
    echo "-------                                         -----" >> "$archivo_salida"
    echo "" >> "$archivo_salida"
    echo "Costo por hora estimado:                        $(formatear_costo $costo_por_hora)" >> "$archivo_salida"
    echo "Costo por día estimado:                         $(formatear_costo $costo_por_dia)" >> "$archivo_salida"
    echo "Costo mensual estimado:                         $(formatear_costo $costo_mensual)" >> "$archivo_salida"
    echo "Tiempo desde el último reinicio:                $(calcular_tiempo_desde_ultimo_reinicio)" >> "$archivo_salida"
    echo "Tiempo encendido:                               ${horas_encendido} horas" >> "$archivo_salida"
    echo "Costo por el tiempo encendido hoy:              $(formatear_costo $costo_por_tiempo_encendido)" >> "$archivo_salida"
    echo "" >> "$archivo_salida"
    echo "Resultados guardados en $archivo_salida."
}


# Función principal que orquesta la ejecución del script.
main() {
    crear_directorio
    capturar_datos
    calcular_tiempo_funcionamiento
    escribir_resultados
}

# Ejecución de la función principal.
main

# Fin del script.
exit 0
