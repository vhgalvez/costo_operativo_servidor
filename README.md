# Costo Operativo del Servidor

Este repositorio contiene un script de Bash diseñado para monitorear y registrar la temperatura y el consumo de energía de un sistema Linux. Además, calcula el costo estimado diario, mensual y por el tiempo de funcionamiento actual del sistema, ayudando a comprender el impacto económico del consumo energético del servidor.

## Características

- **Monitoreo de Temperatura:** Registra la temperatura actual del sistema para mantener un seguimiento y prevenir posibles problemas de sobrecalentamiento.
- **Cálculo de Consumo de Energía:** Calcula el consumo de energía en tiempo real del servidor, proporcionando una estimación en kWh.
- **Estimación de Costos:** Evalúa el costo por hora y el costo acumulado durante el tiempo de funcionamiento del servidor, basado en el precio por kWh definido por el usuario.

## Cómo Usar

Para utilizar este script, sigue los siguientes pasos:

1. Clona el repositorio en tu servidor Linux:
   
```bash
git clone https://github.com/vhgalvez/costo_operativo_servidor.git
```
1. Navega al directorio del script:

```bash
cd costo_operativo_servidor
```

1. Otorga permisos de ejecución al script:
   
```bash
sudo chown -R $USER:$USER /home/$USER/costo_operativo_servidor
```


1. Ejecuta el script:
   
```bash
./costo_operativo_servidor.sh
```

El script generará un archivo de salida con la fecha y hora de ejecución, que contendrá la temperatura y el consumo de energía del sistema, así como el costo estimado basado en el precio por kWh definido por el usuario.
## Requisitos

- Sistema operativo Linux con `bash`
- `bc` para cálculos matemáticos
- `sensors` de `lm_sensors` para el monitoreo de la temperatura y el consumo energético

## Créditos

Este script fue desarrollado por [Victor H. Galvez](https://github.com/vhgalvez). Visita el repositorio en GitHub para más detalles y actualizaciones: [costo_operativo_servidor](https://github.com/vhgalvez/costo_operativo_servidor.git).

## Licencia

Este proyecto está licenciado bajo [MIT License](LICENSE). Para más detalles, por favor revisa el archivo `LICENSE` en el repositorio.
Este README.md ofrece una guía completa sobre qué hace el script, cómo configurarlo y ejecutarlo, además de proporcionar créditos adecuados al autor y el enlace al repositorio de GitHub. Puedes ajustar cualquier sección según sea necesario para que coincida con los detalles específicos o adicionales que quieras incluir sobre el script o su funcionamiento
