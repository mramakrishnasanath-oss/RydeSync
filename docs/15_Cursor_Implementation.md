# RideSync — Day 9 Cursor Implementation & Set-Based Analysis

**Document Reference:** `DOC-15-CURSORS`  
**Database:** `RideSyncDB`  
**Day 9 Topic:** Cursors, Iterative Row Processing, Lifecycle, and Set-Based Alternatives  

---

## 1. Day 9 Cursor Requirement Overview

In the Day 9 curriculum, cursors are introduced to teach row-by-row data traversal in SQL Server. In RideSync, this is modeled via **`sp_process_stale_drivers`**, which identifies active drivers who have not emitted a telemetry ping for $>60$ seconds, sets them to `'OFFLINE'`, and writes an audit record to `dbo.StaleDriverAudit`.

---

## 2. Cursor Lifecycle Architecture

```
1. DECLARE CURSOR   ──> Defines cursor attributes (FAST_FORWARD) and query.
2. OPEN             ──> Populates the active result set in server memory.
3. FETCH NEXT       ──> Retrieves the first row into local scalar variables.
4. WHILE @@FETCH_STATUS = 0
   ├── Process Row  ──> Executes procedural logic (Update + Audit Insert).
   └── FETCH NEXT   ──> Retrieves subsequent row to advance cursor pointer.
5. CLOSE            ──> Releases row locks and active cursor data sets.
6. DEALLOCATE       ──> Destroys cursor memory structures and variable bindings.
```

### The Role of `@@FETCH_STATUS`:
- `0`: Fetch succeeded; row returned.
- `-1`: Fetch failed or cursor pointer reached beyond the end of the result set.
- `-2`: The row fetched is missing (deleted by another concurrent session).

---

## 3. Side-by-Side Comparison: Cursor vs Set-Based SQL

```
┌─────────────────────────────────┬────────────────────────────────────────────────────────┐
│ Dimension                       │ Cursor Implementation (sp_process_stale_drivers)       │
├─────────────────────────────────┼────────────────────────────────────────────────────────┤
│ Processing Style                │ Procedural (Row-by-Agonizing-Row)                      │
│ Engine Overhead                 │ High: Frequent context switches between engine layers  │
│ Lock Duration                   │ Incremental row locks held across iteration cycle      │
│ Memory Impact                   │ Cursor state persisted in tempdb / memory structures   │
│ Code Verbosity                  │ 45 lines of T-SQL (DECLARE, OPEN, FETCH, CLOSE, etc.)   │
│ Production Suitability          │ Low for batch updates; High for calling external APIs  │
└─────────────────────────────────┴────────────────────────────────────────────────────────┘

┌─────────────────────────────────┬────────────────────────────────────────────────────────┐
│ Dimension                       │ Set-Based SQL Alternative                              │
├─────────────────────────────────┼────────────────────────────────────────────────────────┤
│ Processing Style                │ Relational Set-Based (Single Atomic Pass)              │
│ Engine Overhead                 │ Minimal: Query optimizer compiles single pipeline plan │
│ Lock Duration                   │ Atomic transaction lock held for milliseconds          │
│ Memory Impact                   │ Standard buffer pool usage; zero cursor overhead       │
│ Code Verbosity                  │ 12 lines of concise declarative SQL                    │
│ Production Suitability          │ Industry-standard best practice for high throughput    │
└─────────────────────────────────┴────────────────────────────────────────────────────────┘
```

### The Set-Based SQL Alternative (Industry Standard):
```sql
BEGIN TRANSACTION;

WITH LatestPings AS (
    SELECT DriverID, MAX(RecordedAt) AS MaxRecordedAt
    FROM dbo.LocationPings
    GROUP BY DriverID
)
UPDATE d
SET d.Status = 'OFFLINE'
OUTPUT 
    inserted.DriverID, 
    'ONLINE', 
    DATEDIFF(SECOND, lp.MaxRecordedAt, SYSUTCDATETIME()), 
    SYSUTCDATETIME(), 
    'Set-based batch timeout'
INTO dbo.StaleDriverAudit (DriverID, PreviousStatus, SecondsStale, MarkedOfflineAt, Reason)
FROM dbo.Drivers d
LEFT JOIN LatestPings lp ON d.DriverID = lp.DriverID
WHERE d.Status = 'ONLINE'
  AND (lp.MaxRecordedAt IS NULL OR DATEDIFF(SECOND, lp.MaxRecordedAt, SYSUTCDATETIME()) > 60);

COMMIT TRANSACTION;
```

---

## 4. Viva Defense Takeaway
When asked by the trainer why you wrote a cursor:
> *"Sir, I implemented `sp_process_stale_drivers` using the full cursor lifecycle (`DECLARE`, `OPEN`, `FETCH`, `CLOSE`, `DEALLOCATE`) to satisfy our Day 9 training requirement for procedural row traversal. However, as a software architect, I also authored the set-based alternative using a single `UPDATE ... OUTPUT` statement, demonstrating that set-based execution runs in $O(1)$ batch time compared to the $O(N)$ context switches of a cursor."*
