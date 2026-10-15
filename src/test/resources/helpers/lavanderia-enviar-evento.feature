@ignore
Feature: Helper - enviar un evento válido a la lavadora

  # Se usa SOLO para preparar precondiciones (llevar la máquina a un estado).
  # Si el evento no es una transición válida, la preparación falla y el
  # escenario se detiene con un error claro en vez de dar un falso resultado.
  #
  # Parámetro: evento -> nombre del evento, p. ej. 'Cerrar Tapa'

  Scenario: Enviar evento de preparación
    Given url baseUrl
    And path 'lavanderia', 'evento'
    And request { evento: '#(evento)' }
    When method post
    Then status 200
    And match response.valida == true
