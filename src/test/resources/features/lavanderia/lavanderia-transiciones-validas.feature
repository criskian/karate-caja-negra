@api @lavanderia @transicion-estados
Feature: Lavandería industrial - transiciones válidas
  Como técnico de pruebas del firmware de la lavadora industrial
  Quiero verificar cada transición válida del diagrama de estados
  Para asegurar que la máquina avanza, ejecuta sus acciones y se detiene como lo exige la especificación

  # Diagrama (estado inicial S1):
  #   S1 --Cerrar Tapa--> S2 --Nivel OK--> S3 --Fin Lavado--> S4 --Fin Lavado--> S1
  #   S2|S3|S4 --Apertura Forzosa--> S5 --Reset Operador--> S1

  Background:
    * url baseUrl

  @GH-1 @RF-LAV-01 @positivo
  Scenario: Cerrar la tapa bloquea el pestillo y pasa a llenar agua (S1 -> S2)
    # Given que la lavadora está en el estado "S1 (Tapa Abierta)"
    * call read('classpath:helpers/lavanderia-mover-a-estado.feature') { estadoObjetivo: 'S1 (Tapa Abierta)' }
    # When el operador cierra la tapa
    Given path 'lavanderia', 'evento'
    And request { evento: 'Cerrar Tapa' }
    When method post
    # Then pasa a "S2 (Llenando Agua)" y ejecuta la acción "Bloquear pestillo"
    Then status 200
    And match response ==
    """
    {
      estadoAnterior: 'S1 (Tapa Abierta)',
      evento: 'Cerrar Tapa',
      guardia: null,
      estadoNuevo: 'S2 (Llenando Agua)',
      valida: true,
      accion: 'Bloquear pestillo'
    }
    """
    * def consulta = call read('classpath:helpers/lavanderia-consultar-estado.feature')
    * match consulta.estadoActual == 'S2 (Llenando Agua)'

  @GH-2 @RF-LAV-02 @positivo
  Scenario: El nivel correcto de agua activa el motor y pasa a lavar (S2 -> S3)
    # Given que la lavadora está en el estado "S2 (Llenando Agua)"
    * call read('classpath:helpers/lavanderia-mover-a-estado.feature') { estadoObjetivo: 'S2 (Llenando Agua)' }
    # When el sensor reporta que el nivel de agua es correcto
    Given path 'lavanderia', 'evento'
    And request { evento: 'Nivel OK' }
    When method post
    # Then pasa a "S3 (Lavando)" y ejecuta la acción "Activar motor"
    Then status 200
    And match response ==
    """
    {
      estadoAnterior: 'S2 (Llenando Agua)',
      evento: 'Nivel OK',
      guardia: null,
      estadoNuevo: 'S3 (Lavando)',
      valida: true,
      accion: 'Activar motor'
    }
    """
    * def consulta = call read('classpath:helpers/lavanderia-consultar-estado.feature')
    * match consulta.estadoActual == 'S3 (Lavando)'

  @GH-3 @RF-LAV-03 @positivo
  Scenario: Fin Lavado desde Lavando pasa a Centrifugando (S3 -> S4)
    # Given que la lavadora está en el estado "S3 (Lavando)"
    * call read('classpath:helpers/lavanderia-mover-a-estado.feature') { estadoObjetivo: 'S3 (Lavando)' }
    # When termina el ciclo de lavado
    Given path 'lavanderia', 'evento'
    And request { evento: 'Fin Lavado' }
    When method post
    # Then pasa a "S4 (Centrifugando)" sin ejecutar ninguna acción adicional
    Then status 200
    And match response ==
    """
    {
      estadoAnterior: 'S3 (Lavando)',
      evento: 'Fin Lavado',
      guardia: null,
      estadoNuevo: 'S4 (Centrifugando)',
      valida: true,
      accion: null
    }
    """
    * def consulta = call read('classpath:helpers/lavanderia-consultar-estado.feature')
    * match consulta.estadoActual == 'S4 (Centrifugando)'

  @GH-4 @RF-LAV-04 @positivo
  Scenario: Fin Lavado desde Centrifugando regresa a Tapa Abierta (S4 -> S1)
    # El mismo evento "Fin Lavado" produce un destino distinto según el estado
    # en que ocurre (S3 -> S4 vs S4 -> S1): es el punto crítico de este diseño.
    # Given que la lavadora está en el estado "S4 (Centrifugando)"
    * call read('classpath:helpers/lavanderia-mover-a-estado.feature') { estadoObjetivo: 'S4 (Centrifugando)' }
    # When termina el centrifugado
    Given path 'lavanderia', 'evento'
    And request { evento: 'Fin Lavado' }
    When method post
    # Then regresa a "S1 (Tapa Abierta)" y NO se queda en "S4 (Centrifugando)"
    Then status 200
    And match response ==
    """
    {
      estadoAnterior: 'S4 (Centrifugando)',
      evento: 'Fin Lavado',
      guardia: null,
      estadoNuevo: 'S1 (Tapa Abierta)',
      valida: true,
      accion: null
    }
    """
    * def consulta = call read('classpath:helpers/lavanderia-consultar-estado.feature')
    * match consulta.estadoActual == 'S1 (Tapa Abierta)'

  @GH-5 @RF-LAV-05 @positivo
  Scenario Outline: La apertura forzosa interrumpe el ciclo desde <estadoInicial> y abre la válvula
    # Given que la lavadora está en el estado activo "<estadoInicial>"
    * call read('classpath:helpers/lavanderia-mover-a-estado.feature') { estadoObjetivo: '<estadoInicial>' }
    # When se fuerza la apertura de la tapa
    Given path 'lavanderia', 'evento'
    And request { evento: 'Apertura Forzosa' }
    When method post
    # Then pasa a "S5 (Parada de Emergencia)" y ejecuta "Abrir válvula de descarga"
    Then status 200
    And match response ==
    """
    {
      estadoAnterior: '<estadoInicial>',
      evento: 'Apertura Forzosa',
      guardia: null,
      estadoNuevo: 'S5 (Parada de Emergencia)',
      valida: true,
      accion: 'Abrir válvula de descarga'
    }
    """
    * def consulta = call read('classpath:helpers/lavanderia-consultar-estado.feature')
    * match consulta.estadoActual == 'S5 (Parada de Emergencia)'

    Examples:
      | estadoInicial      |
      | S2 (Llenando Agua) |
      | S3 (Lavando)       |
      | S4 (Centrifugando) |

  @GH-6 @RF-LAV-06 @positivo
  Scenario: El reset del operador saca la máquina de la parada de emergencia (S5 -> S1)
    # Given que la lavadora está en el estado "S5 (Parada de Emergencia)"
    * call read('classpath:helpers/lavanderia-mover-a-estado.feature') { estadoObjetivo: 'S5 (Parada de Emergencia)' }
    # When el operador ejecuta el reset
    Given path 'lavanderia', 'evento'
    And request { evento: 'Reset Operador' }
    When method post
    # Then regresa a "S1 (Tapa Abierta)"
    Then status 200
    And match response ==
    """
    {
      estadoAnterior: 'S5 (Parada de Emergencia)',
      evento: 'Reset Operador',
      guardia: null,
      estadoNuevo: 'S1 (Tapa Abierta)',
      valida: true,
      accion: null
    }
    """
    * def consulta = call read('classpath:helpers/lavanderia-consultar-estado.feature')
    * match consulta.estadoActual == 'S1 (Tapa Abierta)'

  @GH-9 @RF-LAV-09 @positivo @e2e
  Scenario: Un ciclo completo de lavado recorre S1 -> S2 -> S3 -> S4 -> S1 y queda en el historial
    # Given que la lavadora está recién reiniciada en "S1 (Tapa Abierta)"
    * call read('classpath:helpers/lavanderia-mover-a-estado.feature') { estadoObjetivo: 'S1 (Tapa Abierta)' }
    # When se ejecuta el ciclo completo de eventos
    * def ciclo = [{ evento: 'Cerrar Tapa' }, { evento: 'Nivel OK' }, { evento: 'Fin Lavado' }, { evento: 'Fin Lavado' }]
    * call read('classpath:helpers/lavanderia-enviar-evento.feature') ciclo
    # Then la máquina termina en S1 y la API registró las 4 transiciones, en orden
    Given path 'lavanderia', 'estado'
    When method get
    Then status 200
    And match response.estadoActual == 'S1 (Tapa Abierta)'
    And match response.historial == '#[4]'
    And match each response.historial contains { valida: true }
    * def destinos = karate.map(response.historial, function(h) { return h.estadoNuevo })
    * match destinos == ['S2 (Llenando Agua)', 'S3 (Lavando)', 'S4 (Centrifugando)', 'S1 (Tapa Abierta)']
