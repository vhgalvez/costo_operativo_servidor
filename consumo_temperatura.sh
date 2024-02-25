#!/bin/bash

# Comprobación para evitar la ejecución como root
if [ "$(id -u)" -eq 0 ]; then
    echo "Este script no debe ser ejecutado como root. Por favor, ejecute como un usuario regular."
    exit 1
fi

# Configura el comportamiento del script para manejar errores y variables no definidas.
set -e
set -o errexit  # Finaliza el script si un comando falla.
set -o nounset  # Finaliza el script si se intenta usar una variable no declarada.

# Definición de variables globales.
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
    costo_mensual=$(echo "scale=2; $consumo_kwh_por_dia * $dias_por_mes * $costo_kwh" | bc)
}

# Función para calcular el tiempo de funcionamiento y el costo asociado.
calcular_tiempo_funcionamiento() {
    inicio=$(date -d "$(uptime -s)" +%s)
    ahora=$(date +%s)
    segundos_encendido=$((ahora - inicio))
    horas_encendido=$(echo "scale=2; $segundos_encendido / 3600" | bc)
    costo_por_tiempo_encendido=$(echo "scale=2; $consumo_kwh_por_hora * $horas_encendido * $costo_kwh" | bc)
}

# Función para escribir los resultados en el archivo de salida de forma más legible.
escribir_resultados() {
    echo "Métrica                            Valor" > "$archivo_salida"
    echo "-------                            -----" >> "$archivo_salida"
    echo "Fecha y Hora:                      $(date)" >> "$archivo_salida"
    echo "Temperatura:                       $temperatura°C" >> "$archivo_salida"
    echo "Consumo de energía estimado:       ${consumo_watts} W" >> "$archivo_salida"
    echo "Consumo por hora estimado:         ${consumo_kwh_por_hora} kWh" >> "$archivo_salida"
    echo "Costo por hora estimado:           €${costo_por_hora}" >> "$archivo_salida"
    echo "Consumo por día estimado:          ${consumo_kwh_por_dia} kWh/día" >> "$archivo_salida"
    echo "Costo mensual estimado:            €${costo_mensual}" >> "$archivo_salida"
    echo "Tiempo encendido:                  ${horas_encendido} horas" >> "$archivo_salida"
    echo "Costo por el tiempo encendido hoy: €${costo_por_tiempo_encendido}" >> "$archivo_salida"
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
