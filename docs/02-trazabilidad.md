# Trazabilidad: requisito → TestCase (issue) → escenario → ejecución

La cadena completa para cada prueba es:

```
Requisito (RF-xxx-nn)  →  Issue / TestCase (#n)  →  Escenario Karate (@GH-n)  →  Ejecución en GitHub Actions
```

- El **requisito** sale del enunciado del ejercicio (ver `01-diseno-casos-de-prueba.md`).
- El **issue** `#n` es el caso de prueba. Su cuerpo contiene el escenario Gherkin y está
  en el tablero de proyecto *TestCases - Karate Caja Negra*.
- El **escenario** lleva dos tags: `@RF-xxx-nn` (a qué requisito pertenece) y `@GH-n`
  (a qué issue está vinculado). El número de `@GH-n` es el número real del issue.
- La **ejecución** del pipeline lee el reporte, comenta el resultado en el issue `#n` y
  alterna sus labels `automated-passed` / `automated-failed`.

## Matriz de trazabilidad

| Issue | Tag | Requisito | Técnica | Tipo | Feature |
|---|---|---|---|---|---|
| #1 | `@GH-1` | RF-LAV-01 | Transición de estados | Positivo | `lavanderia-transiciones-validas` |
| #2 | `@GH-2` | RF-LAV-02 | Transición de estados | Positivo | `lavanderia-transiciones-validas` |
| #3 | `@GH-3` | RF-LAV-03 | Transición de estados | Positivo | `lavanderia-transiciones-validas` |
| #4 | `@GH-4` | RF-LAV-04 | Transición de estados | Positivo | `lavanderia-transiciones-validas` |
| #5 | `@GH-5` | RF-LAV-05 | Transición de estados | Positivo | `lavanderia-transiciones-validas` |
| #6 | `@GH-6` | RF-LAV-06 | Transición de estados | Positivo | `lavanderia-transiciones-validas` |
| #7 | `@GH-7` | RF-LAV-07 | Transición de estados | Negativo | `lavanderia-transiciones-invalidas` |
| #8 | `@GH-8` | RF-LAV-08 | Transición de estados | Negativo | `lavanderia-transiciones-invalidas` |
| #9 | `@GH-9` | RF-LAV-09 | Transición de estados | Positivo | `lavanderia-transiciones-validas` |
| #10 | `@GH-10` | RF-LAV-10 | Transición de estados | Negativo | `lavanderia-transiciones-invalidas` |
| #11 | `@GH-11` | RF-DRO-01 | Tabla de decisión | Positivo | `dron-agricola-tabla-decision` |
| #12 | `@GH-12` | RF-DRO-02 | Tabla de decisión | Positivo | `dron-agricola-tabla-decision` |
| #13 | `@GH-13` | RF-DRO-03 | Tabla de decisión | Positivo | `dron-agricola-tabla-decision` |
| #14 | `@GH-14` | RF-DRO-04 | Tabla de decisión | Negativo | `dron-agricola-tabla-decision` |
| #15 | `@GH-15` | RF-DRO-05 | Tabla de decisión | Positivo | `dron-agricola-tabla-decision` |
| #16 | `@GH-16` | RF-DRO-06 | Tabla de decisión | Positivo | `dron-agricola-tabla-decision` |
| #17 | `@GH-17` | RF-DRO-07 | Tabla de decisión | Negativo | `dron-agricola-tabla-decision` |

## Catálogo de requisitos

| Requisito | Enunciado |
|---|---|
| RF-LAV-01 | Desde S1 (Tapa Abierta), el evento Cerrar Tapa bloquea el pestillo y pasa a S2 (Llenando Agua). |
| RF-LAV-02 | Desde S2, el evento Nivel OK activa el motor y pasa a S3 (Lavando). |
| RF-LAV-03 | Desde S3, el evento Fin Lavado pasa a S4 (Centrifugando). |
| RF-LAV-04 | Desde S4, el mismo evento Fin Lavado regresa a S1 (mismo evento, destino distinto). |
| RF-LAV-05 | En S2, S3 o S4, Apertura Forzosa abre la válvula de descarga y pasa a S5 (Parada de Emergencia). |
| RF-LAV-06 | Desde S5, el único evento válido es Reset Operador, que regresa a S1. |
| RF-LAV-07 | Los eventos no definidos para S1-S4 se ignoran: el estado no cambia. |
| RF-LAV-08 | En S5 solo Reset Operador es válido; cualquier otro evento se ignora. |
| RF-LAV-09 | El ciclo completo S1→S2→S3→S4→S1 se ejecuta y queda registrado en el historial. |
| RF-LAV-10 | Un evento fuera del catálogo se rechaza con error 400 sin alterar el estado. |
| RF-DRO-01 | Con obstáculo a menos de 2 m, esquive de emergencia sin importar viento ni batería. |
| RF-DRO-02 | Sin obstáculo, viento > 40 km/h o batería < 15 % → abortar misión y activar RTL. |
| RF-DRO-03 | Sin ninguna condición de riesgo → continuar ruta de vuelo planificada. |
| RF-DRO-04 | Una evaluación con un número de condiciones distinto de 3 se rechaza con error 400. |
| RF-DRO-05 | Cada evaluación queda en el historial y el reinicio lo limpia. |
| RF-DRO-06 | La definición del ejercicio expone sus 3 condiciones y 4 reglas. |
| RF-DRO-07 | Valores no booleanos no coinciden con ninguna regla (comportamiento observado). |

> Los requisitos RF-LAV-09, RF-LAV-10 y RF-DRO-04 a RF-DRO-07 no están escritos
> literalmente en los enunciados: se derivan de la API real y de buenas prácticas de
> prueba de servicios (ciclo extremo a extremo, validación de entradas, contrato).

## Cómo ejecutar un TestCase

**Localmente** (por issue, por requisito, por técnica o por ejercicio):

```bash
./gradlew test -Dkarate.options="--tags @GH-4"            # un issue
./gradlew test -Dkarate.options="--tags @GH-1,@GH-2"      # varios (OR)
./gradlew test -Dkarate.options="--tags @RF-LAV-05"       # por requisito
./gradlew test -Dkarate.options="--tags @tabla-decision"  # por técnica
./gradlew test -Dkarate.options="--tags @negativo"        # todos los negativos
./gradlew test -Dkarate.options="--tags ~@negativo"       # todos menos los negativos
```

**Desde GitHub Actions**: *Actions → Karate Tests → Run workflow* e ingresar el tag
(`@GH-4`). Al terminar, el pipeline deja un comentario en el issue #4 con el resultado
y el enlace a la corrida, y actualiza el label `automated-passed` / `automated-failed`.
