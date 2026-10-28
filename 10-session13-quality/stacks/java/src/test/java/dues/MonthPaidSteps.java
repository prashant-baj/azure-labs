package dues;

import static org.junit.jupiter.api.Assertions.assertEquals;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;

/** Thin steps: words into calls, then compare. The rule lives in MonthStatus, never here. */
public class MonthPaidSteps {
    private BigDecimal dues;
    private List<BigDecimal> payments;
    private MonthStatus status;

    @Given("the dues for the month are {int}")
    public void theDuesAre(int amount) {
        dues = BigDecimal.valueOf(amount);
    }

    @Given("the flat has paid {}")
    public void theFlatHasPaid(String text) {
        payments = "nothing".equals(text) ? List.of()
                : Arrays.stream(text.split("\\+")).map(String::trim).map(BigDecimal::new).toList();
    }

    @When("the treasurer checks the month")
    public void theTreasurerChecks() {
        status = MonthStatus.of(dues, payments);
    }

    @Then("the flat is {} with a balance of {int}")
    public void theFlatIs(String expected, int balance) {
        assertEquals("paid".equals(expected), status.paid());
        assertEquals(0, BigDecimal.valueOf(balance).compareTo(status.balance()));
    }
}
