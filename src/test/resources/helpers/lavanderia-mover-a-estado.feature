@ignore
Feature: Helper - llevar la lavadora a un estado objetivo

  # Equivale al "consultar el estado y mover la máquina hasta Sx" del diseño
  # de casos: reinicia la máquina (siempre arranca en S1) y reproduce la ruta
  # mínima de eventos válidos que lleva hasta el estado pedido.
  #
  # Rutas definidas en classpath:data/rutas-lavanderia.json
  # Parámetro: estadoObjetivo -> p. ej. 'S3 (Lavando)'

  Scenario: Mover la lavadora al estado objetivo
    * call read('classpath:helpers/reiniciar.feature') { recurso: 'lavanderia' }

    * def rutas = read('classpath:data/rutas-lavanderia.json')
    * def ruta = rutas[estadoObjetivo]
    * if (ruta == null) karate.fail('Estado sin ruta definida: ' + estadoObjetivo)
    * def pasos = karate.map(ruta, function(evento) { return { evento: evento } })
    * if (pasos.length > 0) karate.call('classpath:helpers/lavanderia-enviar-evento.feature', pasos)

    # Precondición verificada: la máquina quedó realmente en el estado pedido
    * def consulta = call read('classpath:helpers/lavanderia-consultar-estado.feature')
    * match consulta.estadoActual == estadoObjetivo
