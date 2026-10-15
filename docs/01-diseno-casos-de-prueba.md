# Diseño de casos de prueba de caja negra

Este documento justifica **por qué** se eligieron estos dos ejercicios y **cómo** se
derivaron los escenarios Karate a partir de las técnicas de caja negra. Cada escenario
automatizado sale de una celda o regla de las tablas de abajo.

## 1. Ejercicios seleccionados

| Bloque | Técnica | Ejercicio elegido | Por qué |
|---|---|---|---|
| 1 | Transición de estados | **1.5 Sistema de Lavandería Industrial Automatizada** | Tiene 5 estados y 5 eventos (25 celdas), con **8 transiciones válidas y 17 no definidas**. Incluye un evento reutilizado (`Fin Lavado`) cuyo destino cambia según el estado, y un estado de emergencia con un único evento de salida. Es el que más reglas distintas permite demostrar. |
| 2 | Tabla de decisión | **2.3 Sistema de Navegación de un Dron Agrícola Autónomo** | Tres condiciones binarias (8 combinaciones) con **prioridad entre condiciones** (el obstáculo anula al viento y a la batería). Permite explicar la simplificación de la tabla de 8 reglas a 3 acciones y cubrir todas las combinaciones con Scenario Outline. |

API bajo prueba: `https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api`
(endpoints `/lavanderia/*` y `/decision/dron-agricola/*`).

## 2. Ejercicio 1.5 - Lavandería industrial (transición de estados)

**Estados:** S1 Tapa Abierta (inicial), S2 Llenando Agua, S3 Lavando, S4 Centrifugando,
S5 Parada de Emergencia.
**Eventos:** Cerrar Tapa, Nivel OK, Fin Lavado, Apertura Forzosa, Reset Operador.

### 2.1 Tabla de transición (estado destino; `—` = evento no definido)

| Estado \ Evento | Cerrar Tapa | Nivel OK | Fin Lavado | Apertura Forzosa | Reset Operador |
|---|---|---|---|---|---|
| **S1** Tapa Abierta | S2 *(bloquear pestillo)* | — | — | — | — |
| **S2** Llenando Agua | — | S3 *(activar motor)* | — | S5 *(abrir válvula)* | — |
| **S3** Lavando | — | — | S4 | S5 *(abrir válvula)* | — |
| **S4** Centrifugando | — | — | **S1** | S5 *(abrir válvula)* | — |
| **S5** Parada de Emergencia | — | — | — | — | S1 |

### 2.2 Cobertura: 25 celdas = 8 válidas + 17 inválidas

| Celdas | Escenario | Issue | Requisito |
|---|---|---|---|
| S1 + Cerrar Tapa | Cerrar tapa bloquea pestillo (S1→S2) | #1 | RF-LAV-01 |
| S2 + Nivel OK | Nivel OK activa motor (S2→S3) | #2 | RF-LAV-02 |
| S3 + Fin Lavado | Pasa a centrifugar (S3→S4) | #3 | RF-LAV-03 |
| S4 + Fin Lavado | Regresa a tapa abierta (S4→S1) | #4 | RF-LAV-04 |
| S2/S3/S4 + Apertura Forzosa (3 celdas) | Emergencia desde estados activos | #5 | RF-LAV-05 |
| S5 + Reset Operador | Reset de emergencia (S5→S1) | #6 | RF-LAV-06 |
| *(recorrido S1→S2→S3→S4→S1)* | Ciclo completo + historial | #9 | RF-LAV-09 |
| 13 celdas vacías de S1-S4 | Evento no definido se ignora | #7 | RF-LAV-07 |
| 4 celdas vacías de S5 | S5 solo acepta Reset | #8 | RF-LAV-08 |
| *(fuera de la tabla)* | Evento fuera del catálogo → 400 | #10 | RF-LAV-10 |

**Punto crítico (RF-LAV-04):** `Fin Lavado` desde S3 va a S4, pero desde S4 va a S1. Un
solo escenario no detecta un error de implementación en el que ambos lleven al mismo
destino; por eso están en escenarios separados (#3 y #4).

**Cómo se llega a cada estado:** el helper `lavanderia-mover-a-estado.feature` reinicia la
máquina y reproduce la ruta mínima de eventos válidos definida en
`data/rutas-lavanderia.json`, y verifica con `GET /estado` que la precondición se cumple.

## 3. Ejercicio 2.3 - Dron agrícola (tabla de decisión)

**Condiciones (orden del arreglo `valores` de la API):**
C1 viento > 40 km/h · C2 batería < 15 % · C3 obstáculo a menos de 2 m.

### 3.1 Tabla de decisión completa (2³ = 8 reglas)

| Regla | C1 Viento | C2 Batería | C3 Obstáculo | Acción |
|---|---|---|---|---|
| R1 | V | V | V | Ejecutar maniobra de esquive de emergencia |
| R2 | V | F | V | Ejecutar maniobra de esquive de emergencia |
| R3 | F | V | V | Ejecutar maniobra de esquive de emergencia |
| R4 | F | F | V | Ejecutar maniobra de esquive de emergencia |
| R5 | V | V | F | Abortar misión y activar retorno automático (RTL) |
| R6 | V | F | F | Abortar misión y activar retorno automático (RTL) |
| R7 | F | V | F | Abortar misión y activar retorno automático (RTL) |
| R8 | F | F | F | Continuar ruta de vuelo planificada |

**Simplificación:** con `C3 = V` la acción es siempre el esquive (R1-R4 colapsan en una
regla); con `C3 = F` basta que C1 **o** C2 sea verdadera para el RTL; con las tres falsas
se continúa. Aun así se prueban las 8 combinaciones, porque una implementación podría
ordenar mal las prioridades solo en alguna de ellas.

### 3.2 Cobertura

| Reglas | Escenario | Issue | Requisito |
|---|---|---|---|
| R1-R4 | Obstáculo → esquive (Outline, 4 filas) | #11 | RF-DRO-01 |
| R5-R7 | Sin obstáculo, viento o batería → RTL (Outline, 3 filas) | #12 | RF-DRO-02 |
| R8 | Sin riesgo → continuar | #13 | RF-DRO-03 |
| *(entrada inválida)* | Número incorrecto de condiciones → 400 | #14 | RF-DRO-04 |
| *(estado del servicio)* | Historial de evaluaciones y reinicio | #15 | RF-DRO-05 |
| *(contrato)* | Definición con 3 condiciones y 4 reglas | #16 | RF-DRO-06 |
| *(entrada inválida)* | Valores no booleanos → noDefinida | #17 | RF-DRO-07 |

## 4. Resumen

- **17 escenarios**, cada uno con su issue y su tag `@GH-n` (el taller pide al menos 10).
- Los 7 Scenario Outline se expanden en 35 ejecuciones: 3 (#5) + 13 (#7) + 4 (#8) +
  4 (#10) + 4 (#11) + 3 (#12) + 4 (#14). Sumadas a los 10 escenarios simples, la suite
  tiene **45 ejecuciones**.
- Positivos: 12 (#1-6, #9, #11-13, #15, #16) · Negativos: 5 (#7, #8, #10, #14, #17).
