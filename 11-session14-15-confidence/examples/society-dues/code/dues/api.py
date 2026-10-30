"""The slice as a web service - what the pipeline deploys and tests (ADR 0003: FastAPI).

Thin on purpose: every route calls the use case or the rule; no rule lives here (E-004).
"""

import os
import sqlite3
import threading
from decimal import Decimal

from fastapi import APIRouter, FastAPI, Header, HTTPException, Request
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field

from dues.model import Payment
from dues.record_payment import PaymentRecorder
from dues.reminders import reminder_list
from dues.sqlite_store import SqliteFlats, SqlitePayments, SqliteUnmatched, open_store

DUES_PER_FLAT = Decimal(os.getenv("DUES_PER_FLAT", "2500"))
DEMO_FLATS = [("A-101", "Meera"), ("B-304", "Asha"), ("C-101", "Ravi"), ("C-102", "Ravi")]
ALLOWED = {"treasurer", "secretary"}  # C-002: only these may see who paid what

router = APIRouter()


class UpiPayment(BaseModel):
    bank_reference: str = Field(min_length=1, max_length=64)
    remark: str = Field(default="", max_length=140)
    payer: str = Field(min_length=1, max_length=80)
    amount: Decimal = Field(gt=0, max_digits=10, decimal_places=2)  # money is never a float


class Store:
    """Everything a route needs - built once per app, never inside a route (E-008).

    One SQLite connection, many request threads: every use goes through the lock. Found by the performance
    smoke, not by a unit test - see defect-analysis.md (DEF-001).
    """

    def __init__(self, db: sqlite3.Connection):
        self._db = db
        self._lock = threading.Lock()
        self._payments = SqlitePayments(db)
        self._recorder = PaymentRecorder(SqliteFlats(db), self._payments, SqliteUnmatched(db))

    def record(self, payment: Payment):
        with self._lock:
            return self._recorder.record(payment)

    def reminders(self) -> list[dict]:
        with self._lock:
            flats = [flat for (flat,) in self._db.execute("select distinct flat from flats order by flat")]
            due = reminder_list({flat: DUES_PER_FLAT for flat in flats}, self._payments.amounts_by_flat())
        return [{"flat": r.flat, "balance": str(r.balance)} for r in due]

    def unmatched(self) -> list[dict]:
        with self._lock:
            rows = self._db.execute("select bank_reference, reason from unmatched order by bank_reference").fetchall()
        return [{"bank_reference": ref, "reason": reason} for ref, reason in rows]


def _store(request: Request) -> Store:
    return request.app.state.store


def _allowed(role: str | None) -> None:
    if role not in ALLOWED:
        raise HTTPException(status_code=403, detail="Only the treasurer or the secretary may see this (C-002)")


@router.get("/health")
def health(request: Request) -> dict:
    return {"status": "ok", "version": request.app.version}


@router.post("/payments/upi", status_code=201)
def receive_upi(body: UpiPayment, request: Request) -> dict:  # FR-001, FR-003, FR-004, FR-006
    payment = Payment(body.bank_reference, body.remark, body.payer, float(body.amount), "upi")
    result = _store(request).record(payment)
    if result is None:
        return {"bank_reference": body.bank_reference, "duplicate": True}
    reason = result.reason.value if result.reason else None
    return {"bank_reference": body.bank_reference, "duplicate": False, "flat": result.flat, "reason": reason}


@router.get("/reminders")
def reminders(request: Request, x_role: str | None = Header(default=None)) -> list[dict]:  # FR-008, C-002
    _allowed(x_role)
    return _store(request).reminders()


@router.get("/unmatched")
def unmatched(request: Request, x_role: str | None = Header(default=None)) -> list[dict]:  # FR-006
    _allowed(x_role)
    return _store(request).unmatched()


@router.get("/ui/reminders", response_class=HTMLResponse)
def reminders_page(request: Request) -> str:  # the treasurer's screen - what the UI test drives
    items = "".join(
        f'<li data-flat="{r["flat"]}">{r["flat"]} - balance {r["balance"]}</li>' for r in _store(request).reminders()
    )
    return (
        "<!doctype html><html lang='en'><head><meta charset='utf-8'><title>Reminders</title></head>"
        f"<body><h1>Reminders this month</h1><ul id='reminders'>{items}</ul></body></html>"
    )


def create_app(db: sqlite3.Connection | None = None) -> FastAPI:
    db = db or open_store(sqlite3.connect(":memory:", check_same_thread=False))
    if not db.execute("select 1 from flats").fetchone():
        db.executemany("insert into flats values (?, ?)", DEMO_FLATS)  # the test environment's known flats
    app = FastAPI(title="Society dues", version=os.getenv("APP_VERSION", "local"))
    app.state.store = Store(db)
    app.include_router(router)
    return app


app = create_app()
