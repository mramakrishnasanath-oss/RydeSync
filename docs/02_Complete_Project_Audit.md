# RideSync — Complete Project Audit

**Document Reference:** `DOC-02-AUDIT`  
**Audit Conducted Date:** November 17, 2026 (Training Schedule Day 9)  
**Auditor:** Senior Software Architect & Database Lead  
**Workspace Inspected:** `C:\Users\sanat\OneDrive\Desktop\RideSync Project`  

---

## 1. Executive Summary of Audit Findings

A comprehensive baseline inspection of the repository was conducted prior to executing any code or database scripts. The current repository contains initial requirement and vision documents produced during Agile Days 3 & 4 (Sprint 0 Planning), along with training schedule records. However, **no implementation code (Python, SQL DDL, MongoDB, or automated tests) had been initialized or executed in the workspace**. 

The project is currently at **Day 9** of the Hexaware Mavericks Segue Foundation Training Schedule (November 17, 2026). The immediate milestone is the **Wednesday Trainer Demonstration**, focusing on presenting the relational schema, ER diagram, keys, constraints, Day 9 advanced database objects (views, stored procedures, functions, cursors), and MongoDB event architecture.

---

## 2. Component-by-Component Classification Matrix

| Dimension # | Component / Layer | Status | Primary Observation |
| :---: | :--- | :---: | :--- |
| **1** | **Folder Structure** | **NOT STARTED** | Workspace contained only root docx, xlsx, and mp4 files. Standard layered structure (`entity/`, `dao/`, `service/`, `database/`, `docs/`, `tests/`) was missing. |
| **2** | **Python Files** | **NOT STARTED** | Zero Python files (`.py`) existed. No domain entities, DAO classes, or service classes existed. |
| **3** | **SQL Server Files** | **NOT STARTED** | Zero `.sql` scripts existed. Database `RideSyncDB` had not been created. |
| **4** | **MongoDB Scripts** | **NOT STARTED** | Zero `.js` or `.py` MongoDB scripts existed. Operational collections had not been initialized. |
| **5** | **Configuration Files** | **NOT STARTED** | No `requirements.txt`, `.env`, `db_config.json`, or `.gitignore` existed. |
| **6** | **Database Connection** | **NOT STARTED** | No connection helper or pool (via `pyodbc` or `pymongo`) existed. |
| **7** | **Classes and Functions** | **NOT STARTED** | No domain entity models, validation functions, or business routines existed. |
| **8** | **Packages & Dependencies** | **NEEDS VERIFICATION** | Host environment has Python 3.12.4 with `openpyxl`, `pandas`, `requests`. However, project baseline mandates `pyodbc`, `pymongo`, and Python 3.13 standard. |
| **9** | **Git Repository & Branch** | **NOT STARTED** | Workspace was not initialized as a git repository (`fatal: not a git repository`). No commit history existed. |
| **10** | **Existing Documentation** | **PARTIALLY COMPLETED** | `Complete Project Requirements.docx` and `RideSync_Product_Vision.docx` exist. Formal technical docs (ERD, data dictionary, schema specs) were missing. |
| **11** | **Unit Tests** | **NOT STARTED** | Zero test files (`test_*.py`) or test matrices existed. |
| **12** | **Execution Workflow** | **NOT STARTED** | No console CLI runner, script workflow, or test runners existed. |

---

## 3. Deep-Dive Audit Analysis by Dimension

### Dimension 1: Complete Folder Structure
- **Current State:** The root directory contained only 4 unorganized project files:
  - `Complete Project Requirements.docx`
  - `Mavericks_Segue_Training_Plan_Foundation_Python_1.0 - Oct 2026.xlsx`
  - `Project intial Video.mp4`
  - `RideSync_Product_Vision.docx`
- **What is Missing:** Layered enterprise directory architecture:
  - `entity/` (domain value objects and data classes)
  - `dao/` (Data Access Objects for SQL Server and MongoDB)
  - `service/` (Business logic: dispatching, location processing, fare calculation)
  - `exception/` (Custom domain exceptions)
  - `util/` (Database connection factories, configuration loaders)
  - `main/` (Console interface CLI)
  - `tests/` (Automated unit and integration test suites)
  - `database/sql/` (DDL, constraints, seed data, views, procedures)
  - `database/mongodb/` (Collection validation schemas, aggregation views)
  - `docs/` (23 technical documentation artifacts)
- **Why It Matters:** Without standard directory segregation, business logic mixes with database queries and CLI operations, violating Single Responsibility Principle (SRP) and enterprise development guidelines.
- **Remediation Action:** Create the modular layered structure while preserving all existing reference files in place.

---

### Dimension 2: Python Files & Source Code
- **Current State:** No `.py` files in the repository.
- **What is Missing:**
  - Entities: `Rider`, `Driver`, `Vehicle`, `LocationPing`, `Trip`, `Rating`.
  - Interfaces/DAOs: `RiderDAO`, `DriverDAO`, `TripDAO`, `LocationPingDAO`.
  - Services: `DispatchService`, `LocationService`, `BillingService`.
- **Why It Matters:** The backend system cannot process CLI commands or enforce business workflows without source code.
- **Remediation Action:** Implement pure entity models using Python 3 dataclasses/properties, decoupled completely from database SQL strings.

---

### Dimension 3: SQL Server DDL & Schema Scripts
- **Current State:** No SQL scripts exist.
- **What is Missing:**
  - `01_create_database.sql`
  - `02_create_tables.sql` (6 core tables with Primary Keys, Foreign Keys, CHECK constraints, UNIQUE constraints, DEFAULTs)
  - `03_seed_data.sql` ($\ge 10$ records per master table, $\ge 200$ in `LocationPing`)
  - `04_views.sql` (Simple, complex, and updatable views with `WITH CHECK OPTION`)
  - `05_stored_procedures.sql` (Atomic transaction dispatch, rider/driver registration)
  - `06_stored_functions.sql` (Distance computation, fare formula)
  - `07_cursor_job.sql` (Stale driver batch inspection)
  - `99_cleanup.sql` (Reverse dependency teardown)
- **Why It Matters:** The relational database forms the foundational layer for Wednesday's trainer demonstration and is evaluated under Day 9 criteria.
- **Remediation Action:** Author clean, idempotent Transact-SQL scripts with explicit constraint naming and execution safety blocks.

---

### Dimension 4: MongoDB Operational Event Scripts
- **Current State:** No MongoDB setup or scripts exist.
- **What is Missing:**
  - `01_create_collections.js` (`driver_location_events`, `dispatch_events`, `ride_activity_logs`)
  - `$jsonSchema` validation rules enforcing coordinate boundaries and mandatory fields.
  - 2dsphere / compound geospatial indexes.
  - Aggregation pipeline view (`db.createView()`).
- **Why It Matters:** Polyglot persistence is required by the training curriculum to contrast ACID relational storage with high-volume operational event logs.
- **Remediation Action:** Implement complete JavaScript scripts executable via `mongosh` or MongoDB Compass.

---

### Dimension 5: Configuration Files & Environment
- **Current State:** Missing `.env`, `requirements.txt`, `.gitignore`.
- **Why It Matters:** Running the application on multiple machines or pushing to Git risks credential exposure and dependency mismatches.
- **Remediation Action:** Provide a secured configuration template and `requirements.txt`.

---

### Dimension 6: Database Connection Implementation
- **Current State:** No database connectivity logic exists.
- **What is Missing:** Connection manager supporting both Windows Integrated Authentication (`Trusted_Connection=yes`) and SQL Authentication, with robust connection string parameters and error handling.
- **Why It Matters:** The application layer must gracefully handle server timeouts, invalid instances, or dropped connections.
- **Remediation Action:** Implement `DBConnection` utility using `pyodbc` with connection pooling and context managers (`with` statements).

---

### Dimension 7: Existing Classes and Functions
- **Current State:** None implemented.
- **Why It Matters:** Prevents execution of business rules.
- **Remediation Action:** Build strictly structured OOP classes conforming to Python 3.13 best practices.

---

### Dimension 8: Packages & Dependencies
- **Current State:** Local environment runs Python 3.12.4. `openpyxl`, `pandas`, `requests` are installed. `pyodbc` and `pymongo` need verification.
- **Why It Matters:** Database interaction requires `pyodbc` (ODBC Driver 18 for SQL Server) and `pymongo`.
- **Remediation Action:** Include exact pip specifications in `requirements.txt`.

---

### Dimension 9: Git Repository & Branching
- **Current State:** Not initialized (`fatal: not a git repository`).
- **Why It Matters:** Version control is mandatory for agile tracking, milestone isolation, and code review.
- **Remediation Action:** Initialize git repository, configure `.gitignore` (ignoring `.env`, `.pyc`, logs, binaries), create initial commit on `main`, and branch to `feature/day9-database-layer` upon user approval.

---

### Dimension 10: Existing Documentation
- **Current State:** Informal Word documents exist (`Complete Project Requirements.docx`, `RideSync_Product_Vision.docx`).
- **What is Missing:** Structured engineering markdown documents covering architecture, ER diagrams, data dictionary, constraint explanations, and trainer interview readiness.
- **Remediation Action:** Build the complete 23-document technical library in `docs/`.

---

### Dimension 11: Unit Tests
- **Current State:** Zero tests.
- **What is Missing:** Test cases verifying domain constraints, foreign key rejections, atomic dispatch locks, and coordinate boundaries.
- **Remediation Action:** Build comprehensive test matrix and test query scripts.

---

### Dimension 12: Execution Workflow
- **Current State:** No execution entrypoint.
- **Remediation Action:** Provide step-by-step SQL/MongoDB execution instructions and a console menu runner.

---

## 4. Key Architectural Ambiguity Discovered: Driver–Vehicle Relationship

In the reference materials, a critical discrepancy between Section 3.1 (Entities) and Section 3.2 (Relationships) was identified:

1. **Entity Definition (Section 3.1):**
   - `Driver` entity specifies attributes: `DriverID`, `FirstName`, `LastName`, `VehicleID`, `Status`.
   - `Vehicle` entity specifies attributes: `VehicleID`, `PlateNumber`, `Model`.
2. **Relationship Definition (Section 3.2):**
   - Lists only 4 narrative relationships:
     - Rider requests Trip ($1:M$)
     - Driver accepts/completes Trip ($1:M$)
     - Driver sends LocationPing ($1:M$)
     - Trip receives Rating ($1:1$)
   - Omits explicit narrative description of Driver–Vehicle relationship, yet places `VehicleID` inside `Driver`.

### Architectural Resolution & Decision
- **Foreign Key Placement:** `Driver.VehicleID` is formally defined as a `FOREIGN KEY` referencing `Vehicle(VehicleID)`.
- **Cardinality Decision:** 
  - To ensure that one physical car cannot be registered and operated by multiple drivers simultaneously (vital for ride-hailing insurance and law enforcement compliance), a `UNIQUE` constraint is enforced on `Driver(VehicleID)`.
  - To support driver onboarding before a vehicle is inspected/assigned, `VehicleID` in `Driver` is made **nullable**.
  - **Result:** Strict **$1:1$ Optional** relationship: Each driver has at most 1 assigned vehicle; each vehicle is assigned to at most 1 driver.
- This resolution preserves the original 6 core entities, satisfies both sections, and introduces no extraneous tables.
