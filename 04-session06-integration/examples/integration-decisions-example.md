# Worked example — integration decisions

> **A worked example, not a case.** This is an invented hotel — deliberately a domain that none of
> the programme's case studies use, and every name in it is made up — so you can see what finished
> records look like without it handing you an answer for your own case. Copy the discipline, not
> the content.

**The situation.** Lakeview Suites is a 180-room business hotel. Room attendants work from a paper
list the housekeeping supervisor prints at 8 am, so a guest who checks out at 9:10 leaves behind a
room nobody knows is free until someone walks past it. The group is building a housekeeping app that
shows attendants which vacated rooms to clean next. This file holds two of its seams.

---

# Integration decision — Room vacated, from the PMS

*Decided: 26 Sep 2026 · By: Aditi, Karan, Neha*

## The seam
**Between** our housekeeping app (the room-queue service) **and** the hotel's Property Management
System (PMS) — the vendor product the front desk uses to check guests in and out.

## What crosses it
The moment a room becomes vacant — a guest has checked out, as the front desk recorded it.

## Who owns the other side
Meera Kulkarni, Front Office Systems Manager. She owns the PMS configuration and the vendor
relationship; any integration change goes through her as a ticket to the vendor, who upgrades the
PMS every quarter.

## Options considered

| Option | Shape | What it costs us | What it costs them | What would make it wrong |
|---|---|---|---|---|
| A — ask the PMS room-status API every 2 minutes | request | A poller to build and run; up to 2 minutes of lag; we must respect their rate limits | One small read every 2 minutes against their PMS; possibly counted against their API licence | The vendor rate-limits or charges per call, or 2 minutes turns out to be too slow |
| B — the PMS sends us a "checked out" notification | event | A public endpoint; duplicate and out-of-order messages; nothing to replay if one is lost | The outbound-notification module is a separately licensed add-on that Meera would have to buy and configure | The module is never bought, or notifications drop silently with no way to resend them |
| C — the PMS drops a room-list CSV in a shared folder every 30 minutes | file | A parser, and little else | Almost nothing — the export already exists for the night audit | Attendants need to know within minutes; a 30-minute-old list is the paper list again |

## Chosen, and why
**We chose:** A
**Shape:** request
**Because:** the hotel does not license the PMS notification module (Meera confirmed it, and buying
it is a procurement cycle longer than this project), and a 2-minute lag comfortably meets the
supervisor's target of starting a room within 45 minutes of check-out. One call returns all 180
rooms, so the load on their side is a single small read every 2 minutes.

## Rejected, and why
- **B (event)** — the freshest option, but it depends on a module this hotel does not own. We would
  be designing around something nobody has agreed to buy. Revisit if the module is ever licensed.
- **C (file)** — the cheapest to build, but a list up to 30 minutes old recreates exactly the
  problem we were asked to fix.

## What it costs us on their bad day
If the PMS is slow or down, the room queue stops updating. After three missed polls (6 minutes) the
app shows "Room status last updated 6 min ago" in amber, and attendants fall back to the
supervisor's radio calls. The app never guesses that a room is vacant: a stale "occupied" costs a
few minutes, but a wrong "vacant" sends an attendant into a guest's room.

## How we find out it changed
Honestly: Meera will tell us — the vendor sends her release notes before each quarterly upgrade.
That is an assumption, not a plan. As a guard, the poller checks that every response still has the
fields we rely on, and alerts us the first time one is missing instead of quietly treating every
room as occupied.

## Open question
Does the vendor count API reads against the hotel's licence, and what rate limit actually applies?
We are relying on Meera's view that one call every 2 minutes is fine; we need that from the vendor
in writing.

---

# Integration decision — Linen counts, to the laundry

*Decided: 26 Sep 2026 · By: Aditi, Karan, Neha*

## The seam
**Between** our housekeeping app **and** CleanSpin, the outside laundry that collects soiled linen
every morning.

## What crosses it
How many sheets, towels and pillowcases each floor sent to the laundry that day, so CleanSpin can
plan the next morning's pickup and return.

## Who owns the other side
Joseph Fernandes, Executive Housekeeper, owns the laundry contract. CleanSpin's operations desk
receives the counts and plans the next morning's run at 6 pm.

## Options considered

| Option | Shape | What it costs us | What it costs them | What would make it wrong |
|---|---|---|---|---|
| A — call CleanSpin's order API as each floor finishes | request | Integrating with an API we have never seen; retries when they are down | CleanSpin would have to build and run an API | CleanSpin has no API — which, today, it does not |
| B — publish a "linen bagged" event per floor | event | A broker and a subscription to maintain; a message per floor | CleanSpin would have to subscribe to and consume our events | They cannot consume events, and they plan once a day anyway |
| C — one CSV at 5 pm to the SFTP folder CleanSpin already reads | file | A daily export job | Nothing new — they already take files from two other hotels this way | CleanSpin starts planning more than once a day, or needs the counts before 5 pm |

## Chosen, and why
**We chose:** C
**Shape:** file
**Because:** CleanSpin plans once a day, at 6 pm, from files it already receives this way. Anything
faster buys nothing they would use, and costs them work they have not agreed to do.

## Rejected, and why
- **A (request)** — CleanSpin has no API, so this option exists only on paper.
- **B (event)** — minute-by-minute events are wasted on a partner that plans once a day, and they
  have no way to consume them.

## What it costs us on their bad day
If the 5 pm file does not arrive, CleanSpin plans from yesterday's numbers and may short us on towels
the next morning. The export retries at 5:15 and 5:30; if all three attempts fail, Joseph gets an
email with the counts so he can phone them through before 6 pm.

## How we find out it changed
If CleanSpin changes the file layout or the folder, they will tell Joseph — an assumption, and the
contract does not require them to give notice. As a guard we check the file was collected (it
disappears from the folder) and alert if it is still sitting there at 6 pm.

## Open question
Does the contract oblige CleanSpin to give notice before changing the file format, and would they
accept an extra column for damaged linen?

---

## What to notice in this example

- **Neither seam chose an event.** Events are not the grown-up answer. Each seam chose the shape its
  owner could actually support: the first lost its best technical option to a licence, the second to
  a partner who plans once a day.
- **Owners are people.** Meera and Joseph, with what each of them controls — never "IT" or "the
  vendor".
- **Every rejected option has a reason you could argue with.** "B is too complex" would not count;
  "B depends on a module this hotel does not own" does.
- **The bad day protects against the dangerous mistake.** The app would rather show a room as
  occupied than wrongly send someone into it.
- **"They will tell us" is written down — and then guarded.** It is stated as an assumption, with a
  cheap check that notices when the assumption fails.
