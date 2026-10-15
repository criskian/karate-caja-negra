@ignore
Feature: Helper - reiniciar el estado de un recurso de la API

  # Las APIs guardan su estado en memoria y es compartido por todos los
  # escenarios. Cada escenario reinicia su recurso para ser independiente.
  #
  # Parámetro: recurso -> 'lavanderia' | 'decision/dron-agricola'

  Scenario: Reiniciar recurso
    Given url baseUrl + '/' + recurso
    And path 'reiniciar'
    When method post
    Then status 200
