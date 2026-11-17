# RideSync — Changelog

All notable changes to the RideSync project will be documented in this file.  
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.9.0] - 2026-11-17 (Training Day 9 Milestone)

### Added
- **Documentation Architecture (`docs/`):**
  - `01_Project_Overview.md`: Business domain, KPIs, and architectural goals for UrbanGo Mobility.
  - `02_Complete_Project_Audit.md`: Comprehensive 12-dimension repository baseline audit.
  - `03_Requirements_Traceability.md`: Complete RTM mapping 12 user stories to code & tests.
  - `04_System_Architecture.md`: Layered N-Tier and Polyglot architecture diagrams.
  - `05_Database_Design.md`: 1NF through BCNF normalization proofs and indexing strategy.
  - `06_ER_Diagram.md`: Conceptual, Logical, and Physical Mermaid ER diagrams.
  - `07_Entity_Attribute_Dictionary.md`: Full schema dictionary for all 6 relational entities.
  - `08_Relationship_Explanation.md`: Detailed explanation of all 5 relational associations.
  - `10_Constraints_Documentation.md`: Catalog of all PK, FK, UNIQUE, CHECK, and DEFAULT rules.
  - `12_SQL_Views_Documentation.md`: Documentation for simple, complex, and updatable views.
  - `13_Stored_Procedures_Documentation.md`: Detailed breakdown of `sp_assign_driver` and others.
  - `14_Stored_Functions_Documentation.md`: Haversine distance, fare formula, and inline TVF docs.
  - `15_Cursor_Implementation.md`: Cursor lifecycle guide and set-based comparison.
  - `16_MongoDB_Design.md`: Collections, schema validators, 2dsphere indexes, and aggregation views.
  - `17_Day_Wise_Development_Log.md`: 24-point chronological engineering task records.
  - `18_Error_and_Resolution_Log.md`: Technical issues, root causes, and resolutions.
  - `19_Testing_and_Validation_Report.md`: 18-case QA test matrix.
  - `20_Trainer_Demo_Guide.md`: Verbatim 5-minute and 15-minute trainer demonstration scripts.
  - `21_Trainer_Interview_Questions.md`: Top viva defense questions with technically correct answers.
  - `22_Next_Steps_and_Pending_Work.md`: Development roadmap for Days 10–22.
- **Relational SQL Server 2025 Layer (`database/sql/`):**
  - `01_create_database.sql`: Safe idempotent `RideSyncDB` creation script.
  - `02_create_tables.sql`: DDL for all 6 tables with complete constraints.
  - `03_seed_data.sql`: 15 Riders, 12 Vehicles, 12 Drivers, 15 Trips, 10 Ratings, 260 LocationPings.
  - `04_views.sql`: 5 views including `vw_online_drivers_updatable` with `WITH CHECK OPTION`.
  - `05_stored_procedures.sql`: 6 stored procedures with atomic dispatch lock `sp_assign_driver`.
  - `06_stored_functions.sql`: Haversine formula `fn_calculate_distance` and pricing functions.
  - `07_cursor_job.sql`: `sp_process_stale_drivers` cursor job and set-based alternative.
  - `08_test_and_validation.sql`: 10 executable integrity and constraint tests.
  - `99_cleanup.sql`: Reverse dependency order teardown script.
- **MongoDB 8.0 Event Layer (`database/mongodb/`):**
  - `01_setup_collections.js`: Operational collections (`driver_location_events`, `dispatch_events`, `ride_activity_logs`), GeoJSON 2dsphere index, TTL index, sample documents, and `view_zone_dispatch_metrics`.
- **Python 3 Layered Architecture:**
  - `entity/`: 6 pure dataclass domain models (`Rider`, `Driver`, `Vehicle`, `LocationPing`, `Trip`, `Rating`).
  - `exception/`: Strongly typed domain exceptions in `custom_exceptions.py`.
  - `util/`: Context-managed database connection provider `DBConnection` in `db_connection.py`.
  - `tests/`: 7 automated domain entity unit tests in `test_entities.py` (100% passing).
  - `requirements.txt`, `README.md`, `.gitignore`.

### Changed
- Reconciled Section 3.1 vs Section 3.2 specification discrepancy regarding Driver–Vehicle relationship by enforcing a `UNIQUE` constraint and `NULL` support on `Driver.VehicleID` ($1:0..1$).
