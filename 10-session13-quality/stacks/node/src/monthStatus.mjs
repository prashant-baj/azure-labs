// RULE-002: has a flat paid this month? Amounts in paise - integers, never floats.
export function monthStatus(duesPaise, paymentsPaise) {
  const paidSoFar = paymentsPaise.reduce((total, p) => total + p, 0);
  const balance = duesPaise - paidSoFar;
  return { paid: balance <= 0, balance };
}
