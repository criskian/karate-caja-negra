package runner;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class KarateRunner {

    /**
     * Ejecuta todos los features con parallel(1) a propósito: las APIs de
     * caja negra guardan el estado de la máquina en memoria y es global, así
     * que dos escenarios en paralelo se pisarían entre sí.
     *
     * El filtrado por tags (-Dkarate.options="--tags @GH-1") lo aplica Karate
     * automáticamente sobre este Runner.
     */
    @Test
    void ejecutarSuite() {
        Results results = Runner.path("classpath:features")
                .reportDir("target/karate-reports")
                .outputCucumberJson(true)
                .parallel(1);

        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}
