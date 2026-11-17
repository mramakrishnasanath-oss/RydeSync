# RideSync — Real-Time Ride-Hailing Dispatch and Live Tracking System

[![Technology: SQL Server 2025](https://img.shields.io/badge/RDBMS-SQL%20Server%202025-blue.svg)](https://www.microsoft.com/sql-server)
[![Technology: MongoDB 8.0](https://img.shields.io/badge/NoSQL-MongoDB%208.0-green.svg)](https://www.mongodb.com/)
[![Language: Python 3.13](https://img.shields.io/badge/Python-3.13-yellow.svg)](https://www.python.org/)
[![Architecture: Polyglot Persistence](https://img.shields.io/badge/Architecture-Polyglot%20Persistence-orange.svg)](#)

---

## 1. Project Overview & Business Vision

**RideSync** is an enterprise-grade backend ride-hailing dispatch and live tracking system engineered for **UrbanGo Mobility**. 

### The Problem in Legacy Ride-Hailing
UrbanGo Mobility previously tracked drivers via a 60-second polling interval and matched rides by executing full-table scans across all registered drivers. This legacy approach created severe dispatch delays, stale location calculations, and race conditions resulting in double-booked drivers.

### The RideSync Solution
RideSync re-architects dispatch operations by implementing:
1. **Continuous Telemetry Streaming:** High-frequency GPS updates every 2–3 seconds while active.
2. **Zone-Partitioned Spatial Dispatching:** Sub-second nearest-driver matching using spherical distance indexing.
3. **Atomic Driver Allocation:** ACID transactional locking (`sp_assign_driver`) guaranteeing zero concurrent double-booking.
4. **Polyglot Persistence Architecture:**
   - **Microsoft SQL Server 2025:** Transactional master data (Riders, Drivers, Vehicles, Trips, Ratings).
   - **MongoDB 8.0:** High-throughput time-series operational event streams (`driver_location_events`, `dispatch_events`, `ride_activity_logs`).

---

## 2. Layered Architecture

```
RideSync/
│
├── entity/             # Pure domain models (dataclasses without DB code)
│   ├── rider.py
│   ├── driver.py
│   ├── vehicle.py
│   ├── location_ping.py
│   ├── trip.py
│   └── rating.py
│
├── dao/                # Data Access Objects (SQL Server & MongoDB queries)
│
├── service/            # Core business logic (Dispatch, Telemetry, Pricing)
│
├── exception/          # Custom domain exceptions
│   └── custom_exceptions.py
│
├── util/               # Connection managers & configuration utilities
│   └── db_connection.py
│
├── main/               # Console CLI runner
│
├── tests/              # Unit & integration tests
│   └── test_entities.py
│
├── database/
│   ├── sql/            # DDL, Seed Data, Views, Stored Procedures, Functions
│   │   ├── 01_create_database.sql
│   │   ├── 02_create_tables.sql
│   │   ├── 03_seed_data.sql
│   │   ├── 04_views.sql
│   │   ├── 05_stored_procedures.sql
│   │   ├── 06_stored_functions.sql
│   │   ├── 07_cursor_job.sql
│   │   ├── 08_test_and_validation.sql
│   │   └── 99_cleanup.sql
│   └── mongodb/        # Collections, Schema validators & Aggregation views
│       └── 01_setup_collections.js
│
├── docs/               # 23 Comprehensive technical documents
├── requirements.txt
├── README.md
└── .gitignore
```

---

## 3. Database Execution Instructions

### Option A: Via SQL Server Management Studio (SSMS 22)
1. Open SSMS 22 and connect to your SQL Server instance (e.g. `.\SQLEXPRESS`).
2. Open and execute the SQL scripts in numerical order:
   - `database/sql/01_create_database.sql`
   - `database/sql/02_create_tables.sql`
   - `database/sql/03_seed_data.sql`
   - `database/sql/04_views.sql`
   - `database/sql/05_stored_procedures.sql`
   - `database/sql/06_stored_functions.sql`
   - `database/sql/07_cursor_job.sql`
   - `database/sql/08_test_and_validation.sql`

### Option B: Via MongoDB Compass / `mongosh`
1. Open MongoDB Compass or launch `mongosh`.
2. Connect to `mongodb://localhost:27017/`.
3. Load and run `database/mongodb/01_setup_collections.js`.

---

## 4. Running Unit Tests

Execute the unit tests directly from the root workspace:

```bash
python -m unittest discover tests/
```

Expected result:
```text
.......
Ran 7 tests in 0.001s
OK
```
