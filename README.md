# Automatización de pruebas backend con Karate Framework

[![Karate Tests](https://github.com/criskian/karate-caja-negra/actions/workflows/ci.yml/badge.svg)](https://github.com/criskian/karate-caja-negra/actions/workflows/ci.yml)

Suite de pruebas automatizadas de API REST con **Karate Framework 1.4.1** (Gradle + JUnit 5)
construida a partir de los ejercicios de **técnicas de caja negra**:

| Bloque | Técnica | Ejercicio | Escenarios |
|---|---|---|---|
| 1 | Transición de estados | 1.5 Sistema de Lavandería Industrial Automatizada | `@GH-1` … `@GH-10` |
| 2 | Tabla de decisión | 2.3 Sistema de Navegación de un Dron Agrícola Autónomo | `@GH-11` … `@GH-17` |

**17 escenarios (45 ejecuciones con los `Scenario Outline`)**, cada uno vinculado a un issue de
GitHub que actúa como caso de prueba (*TestCase*).

> API bajo prueba: `https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api`
> (alojada en el plan gratuito de Render: la primera petición puede tardar ~1 minuto).

## Estructura

```
.
├── .github/workflows/ci.yml            # Pipeline: ejecución por tags + actualización de issues
├── build.gradle / settings.gradle      # Karate 1.4.1, logback, JUnit 5
├── docs/
│   ├── 01-diseno-casos-de-prueba.md    # Tablas de transición/decisión y justificación
│   └── 02-trazabilidad.md              # Requisito -> issue -> tag -> ejecución
└── src/test
    ├── java/runner/KarateRunner.java   # Runner (parallel=1, reporte Cucumber JSON)
    └── resources
        ├── karate-config.js            # baseUrl, timeouts, headers globales
        ├── data/rutas-lavanderia.json  # Ruta mínima de eventos hacia cada estado
        ├── helpers/                    # Features reutilizables (@ignore)
        └── features
            ├── lavanderia/
            │   ├── lavanderia-transiciones-validas.feature     # @GH-1..6, @GH-9
            │   └── lavanderia-transiciones-invalidas.feature   # @GH-7, @GH-8, @GH-10
            └── dron-agricola/
                └── dron-agricola-tabla-decision.feature        # @GH-11..17
```

## Requisitos

- Java 17 o superior (`java -version`)
- Conexión a internet. No hace falta instalar Gradle: se usa el wrapper (`gradlew`).

## Ejecución local

```bash
# Toda la suite
./gradlew test

# Un escenario por su issue
./gradlew test -Dkarate.options="--tags @GH-4"

# Varios issues, un requisito, una técnica o todos los negativos
./gradlew test -Dkarate.options="--tags @GH-1,@GH-2"
./gradlew test -Dkarate.options="--tags @RF-LAV-05"
./gradlew test -Dkarate.options="--tags @tabla-decision"
./gradlew test -Dkarate.options="--tags @negativo"

# Contra otro ambiente
./gradlew test -DbaseUrl=http://localhost:3000/api
```

En Windows con PowerShell/CMD usar `gradlew.bat` (o `.\gradlew`).

**Reporte:** abrir `target/karate-reports/karate-summary.html` en el navegador. Al entrar a un
escenario se ve cada request, headers, payload y response.

## Cómo se diseñó cada escenario

- **Estado compartido.** La API guarda el estado de la máquina en memoria y es global. Por eso
  el runner usa `parallel(1)` y cada escenario parte de un estado conocido: el helper
  `lavanderia-mover-a-estado.feature` reinicia la máquina y reproduce la ruta mínima de
  eventos válidos hasta el estado requerido (el equivalente a "consultar el estado y moverlo
  hasta Sx" del diseño de casos), y verifica la precondición con `GET /estado`.
- **Una regla de negocio por escenario.** Cuando varias filas de la tabla comparten el mismo
  resultado esperado se usa `Scenario Outline` + `Examples` (p. ej. la apertura forzosa desde
  S2/S3/S4, o las 17 transiciones inválidas).
- **Tres niveles de verificación** en las transiciones: el cuerpo completo de la respuesta
  (`match response == {...}`), el estado persistido (`GET /estado`) y, en el ciclo completo,
  el historial.
- **Casos negativos.** Una transición no definida no es un error HTTP: la API responde `200`
  con `valida: false` y `noDefinida: true`, y el estado no cambia. Un evento fuera del
  catálogo o una evaluación con datos incorrectos sí responde `400`.

## Trazabilidad con GitHub Issues y Projects

```
Requisito (RF-LAV-04) → Issue #4 (TestCase) → @GH-4 en el .feature → Ejecución en Actions
```

Cada `Scenario` lleva `@GH-<n>` (el número real del issue) y `@RF-<…>` (el requisito).
Los 17 issues están en el tablero **[TestCases - Karate Caja Negra](https://github.com/users/criskian/projects/7)**
con los campos *Requisito*, *Tag Karate*, *Técnica* y *Última ejecución*. Ver
[`docs/02-trazabilidad.md`](docs/02-trazabilidad.md) para la matriz completa.

## Pipeline (GitHub Actions)

`.github/workflows/ci.yml` — workflow **Karate Tests**:

| Disparador | Qué hace |
|---|---|
| `push` / `pull_request` a `main` | Ejecuta toda la suite y publica el reporte como artefacto |
| `workflow_dispatch` (manual) | Ejecuta toda la suite o los tags indicados (`@GH-4`, `@GH-1,@GH-2`) y además **comenta PASSED/FAILED en cada issue**, con el enlace a la corrida, y alterna los labels `automated-passed` / `automated-failed` |

Para ejecutar un TestCase desde GitHub: *Actions → Karate Tests → Run workflow → tag `@GH-4`*.

## Hallazgo sobre la API

`POST /decision/dron-agricola/evaluar` con valores no booleanos (`["a","b","c"]`) responde
`200` con `noDefinida: true` en lugar de `400`, aunque con un número incorrecto de valores sí
rechaza con `400`. El escenario `@GH-17` documenta el comportamiento actual para detectar
si cambia; es un candidato a defecto de validación de entrada.
