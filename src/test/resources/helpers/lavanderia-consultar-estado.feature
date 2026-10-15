@ignore
Feature: Helper - consultar el estado actual de la lavadora

  # Devuelve en 'estadoActual' el estado y en 'historial' las transiciones
  # registradas por la API.

  Scenario: Consultar estado
    Given url baseUrl
    And path 'lavanderia', 'estado'
    When method get
    Then status 200
    * def estadoActual = response.estadoActual
    * def historial = response.historial
