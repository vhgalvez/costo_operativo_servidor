#!/bin/bash

# Este script monitorea y registra la temperatura y el consumo de energía de un sistema Linux,
# calculando además el costo mensual estimado basado en el consumo detectado y el costo por hora.

# Configura el comportamiento del script para manejar errores y variables no definidas.
set -e
set -o errexit  # Finaliza el script si un comando falla.
set -o nounset  # Finaliza el script si se intenta usar una variable no declarada.

# Definición de variables globales.
fecha_hora=$(date "+%Y-%m-%d_%H-%M-%S")
directorio_salida="/home/victory/infra_code/consumo"
archivo_salida="${directorio_salida}/salida_consumo_temperatura_${fecha_hora}.txt"
horas_funcionamiento=24
dias_mes=30
costo_kwh=0.189

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
    consumo_kwh=$(echo "scale=2; $consumo_watts / 1000" | bc) # Consumo por hora en kWh.
    costo_por_hora=$(echo "scale=2; $consumo_kwh * $costo_kwh" | bc)
    costo_mensual=$(echo "scale=2; $consumo_kwh * $horas_funcionamiento * $dias_mes * $costo_kwh" | bc)
}

# Función para calcular el tiempo de funcionamiento y el costo asociado.
calcular_tiempo_funcionamiento() {
    inicio=$(date -d "$(uptime -s)" +%s)
    ahora=$(date +%s)
    segundos_encendido=$((ahora - inicio))
    horas_encendido=$(echo "$segundos_encendido / 3600" | bc -l)
    costo_por_tiempo_encendido=$(echo "scale=2; $consumo_kwh * $horas_encendido * $costo_kwh" | bc)
}

# Función para escribir los resultados en el archivo de salida.
escribir_resultados() {
    echo "Fecha y Hora: $(date)" > "$archivo_salida"
    echo "Temperatura: $temperatura" >> "$archivo_salida"
    echo "Consumo de energía estimado: $consumo_watts W" >> "$archivo_salida"
    echo "Consumo por hora estimado: $consumo_kwh kWh" >> "$archivo_salida"
    echo "Costo por hora estimado: $costo_por_hora €" >> "$archivo_salida"
    echo "Consumo mensual estimado: $consumo_kwh kWh/día" >> "$archivo_salida"
    echo "Costo mensual estimado: $costo_mensual €" >> "$archivo_salida"
    echo "Tiempo encendido: $horas_encendido horas" >> "$archivo_salida"
    echo "Costo por el tiempo encendido hoy: $costo_por_tiempo_encendido €" >> "$archivo_salida"
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