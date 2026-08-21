# FONGAL Cajamarca — Base de Datos Corporativa

Proyecto final del curso **Base de Datos II**. Diseño, normalización e implementación en **PostgreSQL** de la base de datos corporativa de FONGAL Cajamarca, una organización ganadera y agropecuaria que articula tres líneas de negocio: gestión asociativa/ganadera, operación comercial y gestión ferial.

## Integrantes

| Persona | Rol |
|---|---|
| Julcamoro Gutty Antony David      | Coordinador |
| Acuña Alarcón José Carlos         | Colaborador |
| Alvarado Minchan Cristian Paul    | Colaborador |
| Castañeda Ruiz Angel Danny        | Colaborador |

**Docente:** Dr. Ing. Jaime Llanos Bardales — Cajamarca, Perú, 2026.

## Descripción

FONGAL centraliza en un único modelo de datos sus tres líneas de negocio, evitando la duplicación de identidades de socios/clientes/expositores y preservando la trazabilidad de las operaciones. El modelo está organizado en 6 módulos funcionales:

1. Personas y Asociatividad
2. Gestión Ganadera y Pecuaria
3. Ferias y Eventos
4. Comercial y Ventas
5. Talento Humano
6. Seguridad, Usuarios y Accesos (RBAC)

## Motor de base de datos

PostgreSQL.

## Estructura del repositorio

```
├── TAREA - INFORME FINAL PROYECTO BASE DE DATOS CAP 6.docx   Informe completo del proyecto
├── README.md
└── Anexos/
    ├── Diagrama BD_FONGAL.png              
    ├── SCRIPT_BD_FONGAL_V2.sql             
    ├── Archivos_CSV/                       Datos exportados desde TurismoPeru_ADJG (SQL Server)
    │   ├── Consultas_Obtencion_CSV.sql      
    │   ├── cargo.csv 
    │   ├── departamento.csv
    │   ├── provincia.csv
    │   ├── distrito.csv
    │   ├── persona.csv
    │   └── direccion.csv
    ├── Carga_Datos/
    │   ├── Carga_Datos_Estaticos.sql        
    │   ├── Carga_Masiva_ADJG_a_Fongal.sql   
    │   ├── Script_Ejecucion_ToolsPSQL.sql   
    │   └── Script_Limpieza_Tildes.sql       
    └── Objetos_BD/                          
        ├── Procedimientos_Almacenados/        6 procedimientos almacenados
        ├── Vistas/                            10 vistas
        ├── Indices/                           10 indices
        └── Triggers/                          10 triggers
```

## Cómo desplegar la base de datos

1. Ejecutar `Anexos/SCRIPT_BD_FONGAL_V2.sql` — crea el esquema `fongal` y todas las tablas.
2. Ejecutar `Anexos/Carga_Datos/Carga_Datos_Estaticos.sql` — carga los datos de prueba del proyecto.
3. *(Opcional)* Ejecutar `Anexos/Carga_Datos/Script_Ejecucion_ToolsPSQL.sql` — carga masiva adicional de datos reales tomados de TurismoPeru_ADJG (requiere los CSV de `Archivos_CSV/` en la ruta indicada dentro del script).
4. *(Opcional)* Ejecutar `Anexos/Carga_Datos/Script_Limpieza_Tildes.sql` si se detectan nombres geográficos duplicados por tildes.
5. Ejecutar los archivos de `Anexos/Objetos_BD/` (procedimientos, vistas, índices y triggers) para completar el modelo de negocio.

## Funcionalidades destacadas

- Modelo normalizado (1FN a BCNF) con integridad referencial completa.
- 10 consultas de negocio, 10 funciones, 6 procedimientos almacenados, 10 vistas, 10 índices y 10 triggers sobre las entidades más relevantes.
- Carga masiva de datos reales desde otra base de datos (SQL Server) usando CSV como formato intermedio entre motores.
- Seguridad basada en roles y permisos (RBAC).
