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

## Contenido

1. [Estructura](#estructura)
2. [Requisitos y ejecución local](#requisitos)
3. [Cómo se diseñó cada escenario](#cómo-se-diseñó-cada-escenario)
4. [Trazabilidad con GitHub Issues y Projects](#trazabilidad-con-github-issues-y-projects)
5. [Pipeline (GitHub Actions)](#pipeline-github-actions)
6. [Hallazgo sobre la API](#hallazgo-sobre-la-api)
7. **Guía para la sustentación**
   - [A. Qué se evalúa](#a-qué-se-evalúa)
   - [B. Qué ocurre al ejecutar una prueba](#b-qué-ocurre-al-ejecutar-una-prueba)
   - [C. Recorrido por los archivos](#c-recorrido-por-los-archivos)
   - [D. Anatomía de un escenario](#d-anatomía-de-un-escenario)
   - [E. Los 17 casos de prueba](#e-los-17-casos-de-prueba)
   - [F. Cambios en vivo](#f-cambios-en-vivo)
   - [G. Preparación antes de sustentar](#g-preparación-antes-de-sustentar)
   - [H. Preguntas probables](#h-preguntas-probables)
   - [I. Si algo falla](#i-si-algo-falla)
   - [J. Uso de la IA](#j-uso-de-la-ia)

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

En Windows con PowerShell usar `.\gradlew.bat` y poner **entre comillas** el argumento completo:
`.\gradlew.bat test "-Dkarate.options=--tags @GH-4"`.

**Reporte:** abrir `target/karate-reports/karate-summary.html` en el navegador. Al entrar a un
escenario se ve cada request, headers, payload y response.

Desde el IDE: abrir `src/test/java/runner/KarateRunner.java` y ejecutar el método
`ejecutarSuite` (clic derecho → *Run*). Para un solo caso, ejecutar directamente el archivo
`.feature` o el escenario, o filtrar por tag con `-Dkarate.options`.

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

Pasos del job, en orden: checkout → Java 17 → Gradle con caché → validar el input de tags →
**despertar la API** (hasta 12 intentos, por el cold start de Render) → ejecutar Karate
(`continue-on-error`, para poder publicar el reporte y comentar los issues aunque algo falle) →
subir `karate-reports` como artefacto → leer el JSON de Cucumber, escribir el resumen y, solo
en ejecución manual, comentar y etiquetar cada issue → fallar el job si las pruebas fallaron.
Un `concurrency group` evita que dos corridas usen a la vez la API (su estado es global).

## Hallazgo sobre la API

`POST /decision/dron-agricola/evaluar` con valores no booleanos (`["a","b","c"]`) responde
`200` con `noDefinida: true` en lugar de `400`, aunque con un número incorrecto de valores sí
rechaza con `400`. El escenario `@GH-17` documenta el comportamiento actual para detectar
si cambia; es un candidato a defecto de validación de entrada.

---

# Guía para la sustentación

## A. Qué se evalúa

La rúbrica del taller pide cinco cosas. Dónde está cada una:

| # | Se pide | Dónde está |
|---|---|---|
| 5.1 | Al menos 10 escenarios en Karate, cada uno con su issue | 17 escenarios en `src/test/resources/features/**`; 17 issues (#1–#17) |
| 5.2 | Código en su repositorio | Este repositorio público |
| 5.3 | Despliegue de las pruebas en GitHub Actions | `.github/workflows/ci.yml` → pestaña *Actions* |
| 5.4 | TestCases con sus issues vinculados a los escenarios | Tablero [Projects #7](https://github.com/users/criskian/projects/7) + tag `@GH-n` en cada escenario |
| 5.5 | Sustentación oral | Explicar un elemento (feature, scenario, trazabilidad, issue), ejecutar escenarios desde el TestCase o **cambiar algo en vivo** |

El objetivo de la sustentación es comprobar que, aunque se haya usado IA como asistente, se
domina cada elemento de la automatización. Basta con entender bien **tres ideas**:

1. **Qué es un caso de prueba aquí:** un `Scenario` en un `.feature` (Given/When/Then) que llama
   a la API y compara la respuesta con lo esperado.
2. **Cómo se conecta con el resto:** el tag `@GH-n` del escenario es el número del issue que lo
   documenta; `@RF-…` es el requisito que cubre.
3. **Cómo se ejecuta y se reporta:** `./gradlew test` en local, o *Run workflow* en Actions, que
   además escribe el resultado en el issue.

## B. Qué ocurre al ejecutar una prueba

```
./gradlew test
   └─ Gradle compila y lanza JUnit 5
        └─ KarateRunner.ejecutarSuite()          lee classpath:features (parallel = 1)
             └─ por cada Scenario:
                  1. karate-config.js            calcula baseUrl, timeouts y header Accept
                  2. Background                  fija * url baseUrl
                  3. helper mover-a-estado       reinicia la API y lleva la máquina al estado inicial
                  4. Given/When/Then             POST /lavanderia/evento y compara la respuesta
                  5. helper consultar-estado     GET /lavanderia/estado y verifica el estado guardado
        └─ escribe target/karate-reports/ (HTML + JSON de Cucumber)
```

Orden de prioridad de `baseUrl`: `-DbaseUrl=…` → variable de entorno `BASE_URL` → la API del
taller por defecto.

Puntos de la API que hay que saber:

| Endpoint | Para qué |
|---|---|
| `POST /lavanderia/evento` con `{ "evento": "Cerrar Tapa" }` | Envía un evento a la máquina de estados |
| `GET /lavanderia/estado` | Devuelve `estadoActual` y el `historial` de transiciones |
| `POST /lavanderia/reiniciar` | Vuelve a `S1 (Tapa Abierta)` |
| `POST /decision/dron-agricola/evaluar` con `{ "valores": [viento, bateria, obstaculo] }` | Evalúa la tabla de decisión |
| `GET /decision/dron-agricola/definicion` | Nombre, condiciones, total de reglas e historial |
| `POST /decision/dron-agricola/reiniciar` | Limpia el historial del dron |

Respuestas por tipo de resultado:

| Situación | HTTP | Cuerpo |
|---|---|---|
| Transición válida | `200` | `valida: true`, `estadoNuevo`, `accion` (o `null`) |
| Transición no definida | `200` | `valida: false`, `noDefinida: true`, mismo estado |
| Evento fuera del catálogo / cuerpo vacío | `400` | `error` con "Evento desconocido…" |
| Dron con cantidad de valores incorrecta | `400` | `{ error: 'Se esperaban 3 valores booleanos' }` |
| Dron con valores no booleanos | `200` | `noDefinida: true`, `accion: null` (ver `@GH-17`) |

## C. Recorrido por los archivos

| Archivo | Qué hace | Qué decir |
|---|---|---|
| `build.gradle` | Declara Karate 1.4.1 + logback + JUnit 5; propaga `karate.options` y `baseUrl` solo si vienen por consola; `outputs.upToDateWhen { false }` fuerza a ejecutar siempre | "Gradle no cachea el resultado, así cada `test` llama de verdad a la API" |
| `gradlew` / `gradlew.bat` | Wrapper de Gradle | "No hay que instalar Gradle; el wrapper baja la versión exacta (8.7)" |
| `KarateRunner.java` | Punto de entrada JUnit: `Runner.path("classpath:features").parallel(1)`, genera JSON de Cucumber y falla si hay escenarios fallidos | "`parallel(1)` es a propósito: la API tiene un único estado global" |
| `karate-config.js` | Se ejecuta antes de cada escenario: `baseUrl`, timeouts de 90 s, header `Accept: application/json` | "Los 90 s cubren el cold start de Render" |
| `data/rutas-lavanderia.json` | Para cada estado, la lista mínima de eventos válidos desde S1 que lo alcanza | "Es el 'mover la máquina hasta Sx' del diseño de casos" |
| `helpers/reiniciar.feature` | Hace `POST …/reiniciar` del recurso indicado | Evita que un escenario herede el estado del anterior |
| `helpers/lavanderia-enviar-evento.feature` | Envía un evento (se usa con listas para encadenar varios) | Lo reutiliza el helper de rutas y el ciclo completo |
| `helpers/lavanderia-consultar-estado.feature` | Hace `GET …/estado` y devuelve `estadoActual` | Verifica la precondición y el estado persistido |
| `helpers/lavanderia-mover-a-estado.feature` | Reinicia → lee la ruta del JSON → envía los eventos → verifica que quedó en el estado pedido | Es el "Given" de casi todos los escenarios |
| `lavanderia-transiciones-validas.feature` | Las 8 transiciones válidas + ciclo completo (`@GH-1..6`, `@GH-9`) | Técnica: transición de estados |
| `lavanderia-transiciones-invalidas.feature` | Las 17 celdas no definidas + eventos fuera de catálogo (`@GH-7`, `@GH-8`, `@GH-10`) | Casos negativos |
| `dron-agricola-tabla-decision.feature` | Las 8 reglas de la tabla, validaciones, historial y contrato (`@GH-11..17`) | Técnica: tabla de decisión |
| `.github/workflows/ci.yml` | Pipeline descrito arriba | "Se puede correr por tag y deja el resultado en el issue" |
| `docs/01-diseno-casos-de-prueba.md` | Tablas de transición y de decisión, y por qué cada caso | Es el diseño previo a automatizar |
| `docs/02-trazabilidad.md` | Matriz requisito → issue → tag → ejecución | Para la pregunta de trazabilidad |

Los helpers llevan el tag `@ignore` para que el runner no los ejecute como pruebas: solo se
usan con `call read('classpath:helpers/…')`.

## D. Anatomía de un escenario

Ejemplo real, `@GH-1` (en `lavanderia-transiciones-validas.feature`):

```gherkin
@GH-1 @RF-LAV-01 @positivo                                  # ① tags: issue, requisito, tipo
Scenario: Cerrar la tapa bloquea el pestillo y pasa a llenar agua (S1 -> S2)
  * call read('classpath:helpers/lavanderia-mover-a-estado.feature') { estadoObjetivo: 'S1 (Tapa Abierta)' }   # ② Given
  Given path 'lavanderia', 'evento'                         # ③ arma la URL: baseUrl + /lavanderia/evento
  And request { evento: 'Cerrar Tapa' }                     #    cuerpo JSON de la petición
  When method post                                          #    envía el POST
  Then status 200                                           # ④ verifica el código HTTP
  And match response == { estadoAnterior: 'S1 (Tapa Abierta)', evento: 'Cerrar Tapa',
        guardia: null, estadoNuevo: 'S2 (Llenando Agua)', valida: true, accion: 'Bloquear pestillo' }   # ⑤ cuerpo completo
  * def consulta = call read('classpath:helpers/lavanderia-consultar-estado.feature')   # ⑥ GET /estado
  * match consulta.estadoActual == 'S2 (Llenando Agua)'     #    el estado quedó guardado
```

① Los tags enlazan el escenario con el issue (`@GH-1`) y el requisito (`@RF-LAV-01`).
② Precondición: deja la máquina en S1. ③ Se arma la petición. ④⑤ Se valida la respuesta.
⑥ Se confirma que el cambio persistió y no solo se devolvió en la respuesta.

Vocabulario de Karate usado en el proyecto:

| Palabra | Significado |
|---|---|
| `*` | Paso genérico (equivale a Given/When/Then/And) |
| `url`, `path`, `request`, `method` | Arman y envían la petición |
| `status` | Código HTTP esperado |
| `response` | Cuerpo JSON de la respuesta |
| `match a == b` | Comparación exacta (`match each …`, `contains` para parciales) |
| `'#string'`, `'#number'`, `'#[4]'` | Validadores: tipo o largo de arreglo |
| `def` | Define una variable |
| `call read('…')` | Ejecuta otro `.feature` (helper) y devuelve sus variables |
| `Scenario Outline` + `Examples` | Un mismo escenario con varias filas de datos (`<columna>`) |
| `Background` | Pasos que se repiten antes de cada escenario |
| `karate.map`, `karate.fail` | Funciones del motor (transformar listas, fallar a propósito) |

## E. Los 17 casos de prueba

| Issue / tag | Requisito | Qué verifica | Tipo | Ejecuciones |
|---|---|---|---|---|
| #1 `@GH-1` | `RF-LAV-01` | S1 + Cerrar Tapa → S2, acción "Bloquear pestillo" | positivo | 1 |
| #2 `@GH-2` | `RF-LAV-02` | S2 + Nivel OK → S3, acción "Activar motor" | positivo | 1 |
| #3 `@GH-3` | `RF-LAV-03` | S3 + Fin Lavado → S4 | positivo | 1 |
| #4 `@GH-4` | `RF-LAV-04` | S4 + Fin Lavado → S1 (mismo evento, distinto destino) | positivo | 1 |
| #5 `@GH-5` | `RF-LAV-05` | Apertura Forzosa desde S2/S3/S4 → S5, acción "Abrir válvula de descarga" | positivo | 3 |
| #6 `@GH-6` | `RF-LAV-06` | S5 + Reset Operador → S1 | positivo | 1 |
| #7 `@GH-7` | `RF-LAV-07` | 13 combinaciones estado/evento no definidas se ignoran (200, `noDefinida`) | negativo | 13 |
| #8 `@GH-8` | `RF-LAV-08` | En S5 solo Reset Operador es válido; los otros 4 eventos se ignoran | negativo | 4 |
| #9 `@GH-9` | `RF-LAV-09` | Ciclo completo S1→S2→S3→S4→S1 con 4 transiciones en el historial | positivo | 1 |
| #10 `@GH-10` | `RF-LAV-10` | Evento inexistente, vacío, ausente o con minúsculas → 400 y el estado no cambia | negativo | 4 |
| #11 `@GH-11` | `RF-DRO-01` | Con obstáculo siempre esquiva (4 combinaciones de viento y batería) | positivo | 4 |
| #12 `@GH-12` | `RF-DRO-02` | Sin obstáculo, viento o batería → abortar y RTL | positivo | 3 |
| #13 `@GH-13` | `RF-DRO-03` | Sin riesgo → continuar la ruta | positivo | 1 |
| #14 `@GH-14` | `RF-DRO-04` | Cantidad incorrecta de valores → 400 y sin rastro en el historial | negativo | 4 |
| #15 `@GH-15` | `RF-DRO-05` | El historial guarda las evaluaciones y reiniciar lo limpia | positivo | 1 |
| #16 `@GH-16` | `RF-DRO-06` | La definición expone 3 condiciones y 4 reglas | positivo | 1 |
| #17 `@GH-17` | `RF-DRO-07` | Valores no booleanos → 200 y `noDefinida` (posible defecto de validación) | negativo | 1 |

Totales: **17 escenarios, 45 ejecuciones, 12 positivos y 5 negativos** (`@GH-7`, `8`, `10`, `14`, `17`).
Resultado actual: todo en verde, en local y en Actions.

**Las dos técnicas, en una frase cada una**

- **Transición de estados (lavandería).** Hay 5 estados y 5 eventos = 25 celdas. 8 son transiciones
  válidas (`@GH-1…6`, y `@GH-5` cubre 3) y 17 no están definidas (`@GH-7` cubre 13 y `@GH-8` cubre 4).
  Lo crítico es que `Fin Lavado` lleva a S4 desde S3 pero a S1 desde S4.
- **Tabla de decisión (dron).** 3 condiciones booleanas = 8 combinaciones, reducidas a 4 reglas
  por prioridad: obstáculo → esquivar; si no, viento o batería → regresar a la base (RTL); si
  no, continuar. Las 8 combinaciones están cubiertas entre `@GH-11`, `@GH-12` y `@GH-13`.

## F. Cambios en vivo

Pruebas que se pueden hacer frente al profesor. Todas se probaron contra la API real.

**1. Hacer fallar una prueba a propósito (y verla fallar).**
En `dron-agricola-tabla-decision.feature`, `@GH-13`, cambiar
`accion: 'Continuar ruta de vuelo planificada'` por otro texto. Ejecutar
`./gradlew test "-Dkarate.options=--tags @GH-13"`: la prueba falla y el reporte muestra el valor
esperado frente al recibido. Revertir con `git checkout -- src` .

**2. Agregar un caso a un `Examples`.**
En `@GH-10` (`lavanderia-transiciones-invalidas.feature`), añadir una fila:
`| solo espacio | { evento: ' ' } |`. Se ejecuta como una prueba más, sin tocar los pasos.

**3. Crear un escenario nuevo con su issue.**
Ejemplo: S3 → Apertura Forzosa → S5 → Reset Operador → S1.
1. Crear el issue (número 18) en GitHub, con las mismas labels que los demás.
2. Agregar el escenario con los tags `@GH-18 @RF-LAV-11 @positivo`.
3. Ejecutar `./gradlew test "-Dkarate.options=--tags @GH-18"`.

**4. Ejecutar un caso desde el TestCase (GitHub).**
*Actions → Karate Tests → Run workflow* → `tag` = `@GH-4`. Al terminar, abrir el issue #4: tiene un
comentario con **PASSED ✅**, el enlace a la corrida y el label `automated-passed`.

**5. Cambiar un dato de entrada.**
En `@GH-12`, quitar una fila de `Examples` y ver que el total pasa de 45 a 44 ejecuciones; o
cambiar `[true, false, false]` en `@GH-15` y ajustar la aserción para que siga coincidiendo.

**6. Filtrar por un conjunto de pruebas.**
`@negativo` (los 5 negativos), `@RF-LAV-05` (un requisito), `@tabla-decision` (todo el dron),
`@GH-1,@GH-2` (dos casos).

## G. Preparación antes de sustentar

- [ ] **Despertar la API** unos minutos antes: abrir
      `https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api/ejercicios` y esperar a que cargue.
- [ ] IDE con el proyecto abierto, y a mano: `KarateRunner.java`, un `.feature`, `karate-config.js`.
- [ ] Repositorio abierto en el navegador (pestañas *Code*, *Issues*, *Actions*).
- [ ] Tablero [Projects #7](https://github.com/users/criskian/projects/7) abierto (es el *TestCases*).
- [ ] Una ejecución local reciente: `./gradlew test` y `target/karate-reports/karate-summary.html`.
- [ ] Sesión de GitHub iniciada, para poder usar *Run workflow*.
- [ ] Probado que `./gradlew test "-Dkarate.options=--tags @GH-1"` funciona en la máquina.
- [ ] Revisado que `git status` esté limpio antes de empezar cambios en vivo.

## H. Preguntas probables

**¿Qué es Karate?** Un framework para probar APIs que usa sintaxis Gherkin (Given/When/Then)
y trae HTTP, JSON y aserciones incluidos, sin escribir Java para cada prueba.

**¿Qué es un `Feature` y qué es un `Scenario`?** El feature es el archivo `.feature` que agrupa
casos de una misma funcionalidad. Cada `Scenario` es un caso de prueba.

**¿Qué diferencia hay entre `Scenario` y `Scenario Outline`?** El Outline repite el mismo
escenario con las filas de `Examples`, reemplazando `<columna>` por el valor. Por eso hay 17
escenarios pero 45 ejecuciones.

**¿Para qué sirve el `Background`?** Para los pasos que van antes de cada escenario. Aquí fija la
URL base y, en el dron, reinicia el historial.

**¿Cómo se relaciona un issue con un escenario?** Por el tag: el issue #4 corresponde a `@GH-4`.
El pipeline lee los tags del reporte y comenta en el issue con ese número.

**¿Qué es la trazabilidad?** Poder seguir un requisito hasta su prueba y su resultado:
`RF-LAV-04` → issue #4 → `@GH-4` → ejecución en Actions.

**¿Por qué `parallel(1)`?** La API guarda un estado global en memoria; dos escenarios a la vez
se pisarían y darían fallos falsos.

**¿Por qué cada escenario reinicia la máquina?** Para que no dependa del anterior y arranque
siempre en un estado conocido (S1).

**¿Cómo se verifica el estado, además de la respuesta?** Con `GET /lavanderia/estado`. Confirma
que el cambio quedó guardado, no solo que la respuesta lo dijera.

**¿Por qué una transición inválida da `200` y no `4xx`?** Así lo define la API: responde 200 con
`valida: false` y `noDefinida: true`. Las pruebas verifican ese comportamiento y que el estado no cambie.

**¿Por qué hay un caso `@GH-17` que "pasa" con un comportamiento raro?** Documenta el
comportamiento actual (200 en lugar de 400) como hallazgo. Si la API se corrige, ese caso
fallará y avisará del cambio.

**¿Cómo se ejecuta un solo caso?** `./gradlew test "-Dkarate.options=--tags @GH-n"`, o desde
Actions con *Run workflow* y el tag.

**¿Qué pasa si el pipeline falla?** El job sube el reporte igual (`continue-on-error` en el paso
de pruebas), comenta **FAILED** en el issue, pone `automated-failed` y termina en rojo.

**¿Dónde está el reporte?** Local: `target/karate-reports/karate-summary.html`. En Actions: el
artefacto `karate-reports` de la corrida.

**¿Por qué los timeouts de 90 segundos?** La API está en el plan gratuito de Render y se duerme;
la primera petición puede tardar cerca de un minuto.

**¿Qué técnicas de caja negra se usaron y por qué?** Transición de estados para la lavadora
(depende del estado en que se encuentra) y tabla de decisión para el dron (depende de la
combinación de condiciones).

**¿Cómo se agrega un caso nuevo?** Crear el issue, escribir el escenario con `@GH-n` y su
`@RF-…`, ejecutarlo por tag, y añadirlo al tablero con su tag y requisito.

## I. Si algo falla

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| Timeout o conexión rechazada en todo | La API estaba dormida | Abrir `/api/ejercicios` en el navegador, esperar y repetir |
| Falla un escenario suelto que antes pasaba | Otra persona usa la misma API a la vez (estado global) | Reintentar; en el pipeline el `concurrency` evita el cruce propio |
| `gradlew` no se reconoce | Terminal fuera de la carpeta del proyecto, o `gradlew` en vez de `gradlew.bat` | `cd` a la carpeta; en PowerShell usar `.\gradlew.bat` |
| `--tags` no filtra en PowerShell | Faltan comillas alrededor de `-Dkarate.options=…` | `"-Dkarate.options=--tags @GH-1"` |
| `0 scenarios` ejecutados | Tag mal escrito o inexistente | Revisar el tag en el `.feature` |
| No hay reporte | La ejecución no llegó a correr | Revisar la salida de Gradle y repetir con la API despierta |
| *Run workflow* no aparece | Sin sesión o sin permisos | Iniciar sesión con la cuenta dueña del repo |

## J. Uso de la IA

El taller exige validar que quien entrega sigue dominando su automatización aunque haya usado IA
como asistente. Conviene decirlo con claridad: la IA ayudó a estructurar el proyecto y a
escribir parte del código, y lo importante es poder explicar cada pieza, ejecutarla y modificarla.
Por eso esta guía existe: cada archivo, cada tag y cada decisión (el `parallel(1)`, el reinicio
por escenario, los helpers, el pipeline) tiene un motivo que se puede defender.
