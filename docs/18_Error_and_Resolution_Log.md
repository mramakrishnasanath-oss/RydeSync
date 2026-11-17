# RideSync — Technical Error and Resolution Log

**Document Reference:** `DOC-18-ERRORS`  
**Standard:** Continuous Issue Tracking & Resolution Documentation  

---

## Logged Issues & Remediation Records

### ERR-001: Git Repository Missing in Workspace
- **Date Encountered:** `2026-11-17`
- **Component:** Version Control System
- **Command / Context:** `git status`
- **Observed Error Message:**
  ```text
  fatal: not a git repository (or any of the parent directories): .git
  ```
- **Root Cause Analysis:** The workspace directory was initialized with raw course files and documents from previous sessions without running `git init`.
- **Impact:** Inability to create feature branches or generate verifiable git commit hashes for project evaluation.
- **Resolution Strategy:**
  1. Create a production-ready `.gitignore` excluding temporary files, bytecode, OS metadata, and environment credentials.
  2. Execute `git init` locally (subject to user confirmation).
  3. Commit the documentation baseline as `chore: initialize repository structure and documentation baseline`.
- **Status:** Resolved / Ready for initialization.

---

### ERR-002: SQL Server Local Connection Timeout / Service Stopped
- **Date Encountered:** `2026-11-17`
- **Component:** Microsoft SQL Server 2025 (`SQLEXPRESS`)
- **Command / Context:** `sqlcmd -E -S localhost -Q "SELECT @@VERSION;"` and `sqlcmd -E -S ".\SQLEXPRESS" ...`
- **Observed Error Message:**
  ```text
  Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : SQL Server Network Interfaces: Error Locating Server/Instance Specified [xFFFFFFFF].
  Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : Login timeout expired.
  ```
- **Root Cause Analysis:** 
  1. The SQL Server instance `MSSQL17.SQLEXPRESS` is installed on the host operating system, but the Windows service `MSSQL$SQLEXPRESS` is in a stopped state, or named pipes/TCP protocols are not running under the current sandbox process context.
  2. Direct Service Control Manager calls (`Get-Service`) require administrative elevation which is restricted in sandboxed PowerShell mode.
- **Impact:** Queries directly executed via CLI fail until the SQL Server service is active.
- **Resolution Strategy:**
  1. Provide automated idempotent SQL scripts (`.sql` files) in `database/sql/` that can be executed directly in SQL Server Management Studio (SSMS 22) or through `sqlcmd` once the user starts the service.
  2. Document exact SSMS execution steps and connection parameters (`Server: .\SQLEXPRESS`, `Authentication: Windows Authentication`).
- **Status:** Documented with workaround for manual verification.

---

### ERR-003: Driver–Vehicle Relationship Ambiguity (Section 3.1 vs Section 3.2)
- **Date Encountered:** `2026-11-17`
- **Component:** Data Architecture & Relational ER Modeling
- **Context:** Comparison of entity attributes table against relationship descriptions.
- **Observed Issue:** 
  Section 3.1 specified `VehicleID` in `Driver` (implying a Foreign Key), but Section 3.2 omitted Driver–Vehicle when enumerating the four primary narrative relationships.
- **Root Cause Analysis:** Academic specification oversight where entity attributes included a foreign key reference that was not explicitly detailed in the narrative relationship section.
- **Impact:** Ambiguity over whether Driver owns Vehicle, Vehicle owns Driver, or if a separate junction table is needed.
- **Resolution Strategy:**
  Reconciled the schema by placing `VehicleID` in `Driver` as a `FOREIGN KEY REFERENCES Vehicles(VehicleID)` with a `UNIQUE` constraint and `NULL` support ($1:0..1$). This satisfies both sections cleanly without introducing extraneous tables.
- **Status:** Architecturally Resolved & Documented in `docs/06_ER_Diagram.md`.


---

### ERR-004: T-SQL Subquery Inside PRINT Statement (Msg 1046)
- **Date Encountered:** `2026-11-17`
- **Component:** Sample Data Insertion (`03_seed_data.sql`)
- **Observed Error Message:**
  ```text
  Msg 1046, Level 15, State 1, Line 229
  Subqueries are not allowed in this context. Only scalar expressions are allowed.
  ```
- **Root Cause Analysis:** In Transact-SQL, the `PRINT` command accepts only a scalar string expression or string variable. Passing an inline subquery like `PRINT 'Text ' + CAST((SELECT COUNT(*) FROM ...) AS VARCHAR)` violates T-SQL parsing rules.
- **Impact:** While Riders, Vehicles, Drivers, Trips, and Ratings inserted successfully, the batch containing `LocationPings` generation aborted at syntax evaluation.
- **Resolution Strategy:** Assigned the count to a local variable `@TotalPings` via `SELECT @TotalPings = COUNT(*) FROM dbo.LocationPings;` before concatenating with `PRINT`.
- **Status:** Resolved in `03_seed_data.sql`.
