@api @dron-agricola @tabla-decision
Feature: Dron agrícola - tabla de decisión de la misión de fumigación
  Como piloto de un dron agrícola autónomo
  Quiero que el software decida si continúa, esquiva o regresa a la base
  Para proteger el equipo ante viento fuerte, batería baja u obstáculos imprevistos

  # Condiciones (el orden del arreglo "valores" de la API):
  #   C1 viento > 40 km/h | C2 batería < 15 % | C3 obstáculo a menos de 2 m
  #
  # Tabla de decisión completa (8 reglas, prioridad: obstáculo > viento/batería):
  #   C1 C2 C3 | Acción
  #   V  V  V  | Ejecutar maniobra de esquive de emergencia
  #   V  F  V  | Ejecutar maniobra de esquive de emergencia
  #   F  V  V  | Ejecutar maniobra de esquive de emergencia
  #   F  F  V  | Ejecutar maniobra de esquive de emergencia
  #   V  V  F  | Abortar misión y activar retorno automático (RTL)
  #   V  F  F  | Abortar misión y activar retorno automático (RTL)
  #   F  V  F  | Abortar misión y activar retorno automático (RTL)
  #   F  F  F  | Continuar ruta de vuelo planificada

  Background:
    * url baseUrl
    * call read('classpath:helpers/reiniciar.feature') { recurso: 'decision/dron-agricola' }

  @GH-11 @RF-DRO-01 @positivo @prioridad
  Scenario Outline: El obstáculo cercano siempre dispara el esquive de emergencia (viento=<viento>, batería baja=<bateria>)
    # Given que se detecta un obstáculo a menos de 2 m, con viento fuerte=<viento> y batería baja=<bateria>
    # When el sistema evalúa las condiciones de vuelo
    Given path 'decision', 'dron-agricola', 'evaluar'
    And request { valores: [<viento>, <bateria>, <obstaculo>] }
    When method post
    # Then ejecuta la maniobra de esquive sin importar el viento ni la batería
    Then status 200
    And match response.valores == [<viento>, <bateria>, <obstaculo>]
    And match response.accion == 'Ejecutar maniobra de esquive de emergencia'
    And match response.noDefinida == false

    Examples:
      | viento | bateria | obstaculo |
      | true   | true    | true      |
      | true   | false   | true      |
      | false  | true    | true      |
      | false  | false   | true      |

  @GH-12 @RF-DRO-02 @positivo
  Scenario Outline: Sin obstáculo, el viento fuerte o la batería baja abortan la misión y activan el RTL (viento=<viento>, batería baja=<bateria>)
    # Given que NO hay obstáculo cercano, con viento fuerte=<viento> y batería baja=<bateria>
    # When el sistema evalúa las condiciones de vuelo
    Given path 'decision', 'dron-agricola', 'evaluar'
    And request { valores: [<viento>, <bateria>, <obstaculo>] }
    When method post
    # Then aborta la misión y activa el retorno automático (RTL)
    Then status 200
    And match response.valores == [<viento>, <bateria>, <obstaculo>]
    And match response.accion == 'Abortar misión y activar retorno automático (RTL)'
    And match response.noDefinida == false

    Examples:
      | viento | bateria | obstaculo |
      | true   | true    | false     |
      | true   | false   | false     |
      | false  | true    | false     |

  @GH-13 @RF-DRO-03 @positivo
  Scenario: Sin ninguna condición de riesgo el dron continúa la ruta planificada
    # Given que no hay viento fuerte, ni batería baja, ni obstáculo cercano
    # When el sistema evalúa las condiciones de vuelo
    Given path 'decision', 'dron-agricola', 'evaluar'
    And request { valores: [false, false, false] }
    When method post
    # Then continúa la ruta de vuelo planificada
    Then status 200
    And match response ==
    """
    {
      valores: [false, false, false],
      accion: 'Continuar ruta de vuelo planificada',
      reglaIndex: '#number',
      noDefinida: false
    }
    """

  @GH-14 @RF-DRO-04 @negativo
  Scenario Outline: Una evaluación con un número incorrecto de condiciones se rechaza con 400 (<descripcion>)
    # Given que la entrada no trae exactamente las 3 condiciones booleanas
    # When se envía la evaluación
    Given path 'decision', 'dron-agricola', 'evaluar'
    And request <cuerpo>
    When method post
    # Then la API responde 400 indicando que se esperaban 3 valores
    Then status 400
    And match response == { error: 'Se esperaban 3 valores booleanos' }
    # And la evaluación rechazada no queda registrada en el historial
    Given path 'decision', 'dron-agricola', 'definicion'
    When method get
    Then status 200
    And match response.historial == []

    Examples:
      | descripcion          | cuerpo                                  |
      | una sola condición   | { valores: [true] }                     |
      | arreglo vacío        | { valores: [] }                         |
      | cuatro condiciones   | { valores: [true, false, true, false] } |
      | sin el campo valores | {}                                      |

  @GH-15 @RF-DRO-05 @positivo
  Scenario: Cada evaluación queda en el historial y reiniciar lo limpia
    # Given que el historial del dron está vacío
    Given path 'decision', 'dron-agricola', 'definicion'
    When method get
    Then status 200
    And match response.historial == []
    # When se evalúan dos combinaciones distintas
    Given path 'decision', 'dron-agricola', 'evaluar'
    And request { valores: [false, false, false] }
    When method post
    Then status 200
    Given path 'decision', 'dron-agricola', 'evaluar'
    And request { valores: [true, false, false] }
    When method post
    Then status 200
    # Then el historial conserva las dos evaluaciones en el orden en que se hicieron
    Given path 'decision', 'dron-agricola', 'definicion'
    When method get
    Then status 200
    And match response.historial == '#[2]'
    And match response.historial[0].valores == [false, false, false]
    And match response.historial[0].accion == 'Continuar ruta de vuelo planificada'
    And match response.historial[1].valores == [true, false, false]
    And match response.historial[1].accion == 'Abortar misión y activar retorno automático (RTL)'
    # And al reiniciar el historial queda vacío
    * call read('classpath:helpers/reiniciar.feature') { recurso: 'decision/dron-agricola' }
    Given path 'decision', 'dron-agricola', 'definicion'
    When method get
    Then status 200
    And match response.historial == []

  @GH-16 @RF-DRO-06 @positivo @contrato
  Scenario: La definición del ejercicio expone las tres condiciones y las cuatro reglas
    # Given el servicio del dron agrícola
    # When se consulta su definición
    Given path 'decision', 'dron-agricola', 'definicion'
    When method get
    # Then devuelve el nombre, las condiciones en el orden esperado y el total de reglas
    Then status 200
    And match response ==
    """
    {
      nombre: 'Sistema de Navegación de un Dron Agrícola Autónomo',
      condiciones: ['Viento > 40 km/h', 'Batería < 15%', 'Obstáculo a menos de 2m'],
      historial: [],
      totalReglas: 4
    }
    """

  @GH-17 @RF-DRO-07 @negativo
  Scenario: Valores que no son booleanos no coinciden con ninguna regla de la tabla
    # Observación del comportamiento real: la API NO responde 400 sino 200 con
    # noDefinida=true y sin acción. Se documenta tal cual para detectar cambios.
    # Given condiciones con valores de tipo texto en lugar de booleanos
    # When el sistema evalúa las condiciones
    Given path 'decision', 'dron-agricola', 'evaluar'
    And request { valores: ['a', 'b', 'c'] }
    When method post
    # Then no se selecciona ninguna acción de vuelo
    Then status 200
    And match response.accion == null
    And match response.noDefinida == true
