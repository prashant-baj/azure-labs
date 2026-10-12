# BEFORE - every new kind of unit means editing this function (and re-testing all the others).

def late_fee(unit_type, dues, days_late):
    if days_late <= 15:
        return 0
    if unit_type == "residential":
        late_months = (days_late - 15) // 30 + 1
        return dues * 0.02 * late_months
    elif unit_type == "commercial":
        return 500
    elif unit_type == "parking":
        return 100
    raise ValueError(f"unknown unit type: {unit_type}")
