package dues;

import java.math.BigDecimal;
import java.util.List;

/** RULE-002: has a flat paid this month? Money is BigDecimal - never double. */
public record MonthStatus(BigDecimal dues, BigDecimal paidSoFar) {

    public static MonthStatus of(BigDecimal dues, List<BigDecimal> payments) {
        return new MonthStatus(dues, payments.stream().reduce(BigDecimal.ZERO, BigDecimal::add));
    }

    public BigDecimal balance() {
        return dues.subtract(paidSoFar);
    }

    public boolean paid() {
        return balance().signum() <= 0;
    }
}
