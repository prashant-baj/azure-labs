# BEFORE - it works. Every test passes. Read it as a reviewer would.
# (Invented example: a housing society's late fee on monthly maintenance.)

def calc(d, a, t):
    # calculate fee
    try:
        if t == 1:
            if d > 15:
                return a + a * 0.02 * ((d - 15) // 30 + 1)
            return a
        elif t == 2:
            if d > 15:
                return a + 500
            return a
        else:
            return a
    except Exception:
        return 0
