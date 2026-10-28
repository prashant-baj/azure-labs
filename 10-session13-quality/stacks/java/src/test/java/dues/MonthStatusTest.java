package dues;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;

/** TDD on the rule - one example per test, named after it, each seen red first. */
class MonthStatusTest {
    private static final BigDecimal DUES = new BigDecimal("2500");

    @Test
    void rule002d_noPaymentLeavesTheWholeDues() {
        MonthStatus status = MonthStatus.of(DUES, List.of());
        assertFalse(status.paid());
        assertEquals(0, DUES.compareTo(status.balance()));
    }

    @Test
    void rule002a_onePaymentOfTheFullDuesIsPaid() {
        assertTrue(MonthStatus.of(DUES, List.of(new BigDecimal("2500"))).paid());
    }

    @Test
    void rule002b_twoPaymentsThatCoverTheDuesArePaid() {
        assertTrue(MonthStatus.of(DUES, List.of(new BigDecimal("1500"), new BigDecimal("1000"))).paid());
    }

    @Test
    void rule002c_aPartPaymentShowsTheBalance() {
        MonthStatus status = MonthStatus.of(DUES, List.of(new BigDecimal("1000")));
        assertFalse(status.paid());
        assertEquals(0, new BigDecimal("1500").compareTo(status.balance()));
    }
}
