package dues;

import static io.cucumber.junit.platform.engine.Constants.GLUE_PROPERTY_NAME;
import static io.cucumber.junit.platform.engine.Constants.PLUGIN_PROPERTY_NAME;

import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.IncludeEngines;
import org.junit.platform.suite.api.SelectDirectories;
import org.junit.platform.suite.api.Suite;

/** Runs every scenario under features/. In your repo: @SelectDirectories("specs") - next to the spec. */
@Suite
@IncludeEngines("cucumber")
@SelectDirectories("features")
@ConfigurationParameter(key = GLUE_PROPERTY_NAME, value = "dues")
@ConfigurationParameter(key = PLUGIN_PROPERTY_NAME, value = "pretty, junit:target/scenarios.xml")
public class RunScenariosTest {
}
