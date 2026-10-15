/**
 * Configuración global de Karate. Se ejecuta antes de cada escenario.
 *
 * baseUrl se resuelve en este orden de prioridad:
 *   1. -DbaseUrl=...  (propiedad del sistema, p. ej. ./gradlew test -DbaseUrl=...)
 *   2. variable de entorno BASE_URL (útil en pipelines)
 *   3. API pública del taller de caja negra
 */
function fn() {
  var defaultBaseUrl = 'https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api';

  var baseUrl = karate.properties['baseUrl']
    || java.lang.System.getenv('BASE_URL')
    || defaultBaseUrl;

  var config = {
    env: karate.env || 'dev',
    baseUrl: baseUrl
  };

  // La API está desplegada en el plan gratuito de Render: tras un periodo
  // de inactividad la primera petición puede tardar ~1 minuto (cold start).
  karate.configure('connectTimeout', 90000);
  karate.configure('readTimeout', 90000);
  karate.configure('headers', { Accept: 'application/json' });

  return config;
}
