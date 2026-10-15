@api @lavanderia @transicion-estados @negativo
Feature: Lavandería industrial - transiciones inválidas y entradas incorrectas
  Como técnico de pruebas del firmware de la lavadora industrial
  Quiero verificar que los eventos no definidos para un estado se ignoran
  Para asegurar que la máquina nunca cambia de estado ni ejecuta acciones por una orden que no corresponde

  # De las 25 celdas (5 estados x 5 eventos) de la tabla de transición, 8 son
  # válidas (ver lavanderia-transiciones-validas.feature) y 17 no están
  # definidas. Aquí se cubren las 17 más el caso de un evento inexistente.
  #
  # Una transición no definida NO es un error HTTP: la API responde 200 con
  # { valida: false, noDefinida: true } y el estado se mantiene.

  Background:
    * url baseUrl

  @GH-7 @RF-LAV-07 @negativo
  Scenario Outline: El evento "<evento>" no está definido en "<estadoInicial>" y la máquina permanece en el mismo estado
    # Given que la lavadora está en el estado "<estadoInicial>"
    * call read('classpath:helpers/lavanderia-mover-a-estado.feature') { estadoObjetivo: '<estadoInicial>' }
    # When llega el evento "<evento>", que no está definido para ese estado
    Given path 'lavanderia', 'evento'
    And request { evento: '<evento>' }
    When method post
    # Then la API lo marca como transición no definida y no cambia de estado
    Then status 200
    And match response ==
    """
    {
      estadoAnterior: '<estadoInicial>',
      evento: '<evento>',
      guardia: null,
      estadoNuevo: '<estadoInicial>',
      valida: false,
      noDefinida: true
    }
    """
    * def consulta = call read('classpath:helpers/lavanderia-consultar-estado.feature')
    * match consulta.estadoActual == '<estadoInicial>'

    Examples:
      | estadoInicial      | evento           |
      | S1 (Tapa Abierta)  | Nivel OK         |
      | S1 (Tapa Abierta)  | Fin Lavado       |
      | S1 (Tapa Abierta)  | Apertura Forzosa |
      | S1 (Tapa Abierta)  | Reset Operador   |
      | S2 (Llenando Agua) | Cerrar Tapa      |
      | S2 (Llenando Agua) | Fin Lavado       |
      | S2 (Llenando Agua) | Reset Operador   |
      | S3 (Lavando)       | Cerrar Tapa      |
      | S3 (Lavando)       | Nivel OK         |
      | S3 (Lavando)       | Reset Operador   |
      | S4 (Centrifugando) | Cerrar Tapa      |
      | S4 (Centrifugando) | Nivel OK         |
      | S4 (Centrifugando) | Reset Operador   |

  @GH-8 @RF-LAV-08 @negativo @critico
  Scenario Outline: En parada de emergencia el evento "<evento>" se ignora y solo Reset Operador es válido
    # Given que la lavadora está en el estado "S5 (Parada de Emergencia)"
    * call read('classpath:helpers/lavanderia-mover-a-estado.feature') { estadoObjetivo: 'S5 (Parada de Emergencia)' }
    # When llega el evento "<evento>"
    Given path 'lavanderia', 'evento'
    And request { evento: '<evento>' }
    When method post
    # Then se ignora: la máquina sigue detenida y no se reanuda el ciclo
    Then status 200
    And match response ==
    """
    {
      estadoAnterior: 'S5 (Parada de Emergencia)',
      evento: '<evento>',
      guardia: null,
      estadoNuevo: 'S5 (Parada de Emergencia)',
      valida: false,
      noDefinida: true
    }
    """
    * def consulta = call read('classpath:helpers/lavanderia-consultar-estado.feature')
    * match consulta.estadoActual == 'S5 (Parada de Emergencia)'

    Examples:
      | evento           |
      | Cerrar Tapa      |
      | Nivel OK         |
      | Fin Lavado       |
      | Apertura Forzosa |

  @GH-10 @RF-LAV-10 @negativo
  Scenario Outline: Un evento fuera del catálogo se rechaza con 400 y no altera el estado (<descripcion>)
    # Given que la lavadora está en el estado "S3 (Lavando)"
    * call read('classpath:helpers/lavanderia-mover-a-estado.feature') { estadoObjetivo: 'S3 (Lavando)' }
    # When se envía un cuerpo con un evento que no existe en la máquina
    Given path 'lavanderia', 'evento'
    And request <cuerpo>
    When method post
    # Then la API responde 400 con el motivo y el estado sigue siendo S3
    Then status 400
    And match response.error == '#string'
    And match response.error contains 'Evento desconocido'
    * def consulta = call read('classpath:helpers/lavanderia-consultar-estado.feature')
    * match consulta.estadoActual == 'S3 (Lavando)'

    Examples:
      | descripcion           | cuerpo                    |
      | evento inexistente    | { evento: 'Hacer Cafe' }  |
      | evento vacío          | { evento: '' }            |
      | sin campo evento      | {}                        |
      | minúsculas, no exacto | { evento: 'cerrar tapa' } |
