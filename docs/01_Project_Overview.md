# RideSync — Project Overview & Vision

**System Name:** RideSync  
**Full Title:** Real-Time Ride-Hailing Dispatch and Live Tracking System  
**Client / Business Domain:** UrbanGo Mobility  
**Application Type:** Console-Based Backend Architecture  
**Training Program:** Hexaware Mavericks Segue Foundation Training (Python Digital Foundation)  
**Document Reference:** `DOC-01-OVERVIEW`  
**Current Date:** November 17, 2026 (Training Schedule Day 9)  

---

## 1. Executive Summary

**UrbanGo Mobility** operates an urban ride-hailing network connecting riders needing point-to-point transportation with nearby registered drivers. In the existing legacy operations, driver location updates rely on a 60-second polling cycle, and dispatch ride matching executes by scanning the entire relational driver table. This architectural bottleneck results in:
1. High latency during ride dispatch.
2. Inaccurate location calculations due to stale GPS coordinates.
3. Increased probability of race conditions leading to duplicate driver assignments.
4. Heavy database load during peak operational hours.

**RideSync** is engineered as a modern, resilient, polyglot backend system designed to eliminate these inefficiencies. By combining high-frequency GPS location streaming (every 2–3 seconds), zone-partitioned spatial filtering, atomic transactional driver claims, and hybrid relational-document persistence (Microsoft SQL Server 2025 + MongoDB 8.0), RideSync delivers an enterprise-grade ride-hailing dispatch engine.

---

## 2. Business Problem Statement

| Operational Challenge | Legacy UrbanGo Approach | Impact on Business / Performance | RideSync Solution |
| :--- | :--- | :--- | :--- |
| **Driver Location Frequency** | 60-second client polling | Drivers move 300–800 meters between updates; pickup estimates are highly inaccurate. | High-frequency continuous GPS streaming (every 2–3 seconds) into operational log storage. |
| **Dispatch Matching Algorithm** | Full-table scan across all drivers | Query latency scales linearly with registered drivers $O(N)$, causing severe dispatch bottlenecks. | Zone-partitioned indexing and spatial distance ranking against active, available drivers. |
| **Concurrent Ride Claims** | Unsynchronized database updates | Two riders can simultaneously match and claim the same available driver (race condition). | Atomic transaction control using ACID isolation (`BEGIN TRANSACTION` with conditional lock/status update). |
| **Data Ingestion Overhead** | Relational inserts for every location ping | High write I/O pressure on the operational relational database from thousands of active vehicles. | Polyglot persistence: Relational SQL Server 2025 for ACID master data; MongoDB 8.0 for event streams and operational telemetry. |

---

## 3. Core Objectives & Key Performance Indicators (KPIs)

- **Continuous Ingestion:** Support high-volume location ping streaming at 2–3 second intervals.
- **Sub-Second Dispatch:** Match riders to the nearest verified active driver within a configurable geographic radius ($R \le 5\text{ km}$).
- **Zero Double-Booking:** Guarantee 100% prevention of duplicate driver assignment via atomic transaction claims (`sp_assign_driver`).
- **Lifecycle Integrity:** Enforce strict state transitions across ride lifecycles: `REQUESTED` $\rightarrow$ `MATCHED` $\rightarrow$ `IN_PROGRESS` $\rightarrow$ `COMPLETED` (or `CANCELLED`).
- **Transparent Pricing:** Accurately compute base, distance, and duration fares with surge-multiplier capabilities.
- **Operational Intelligence:** Monitor real-time supply vs. demand per zone using SQL views and MongoDB aggregation pipelines.

---

## 4. Architectural Stack & Baseline Technologies

- **Relational Storage:** Microsoft SQL Server 2025 (v17)
  - Purpose: Master transactional records (Rider, Driver, Vehicle, Trip, Rating, Master Location Pings).
  - Administration Tool: SQL Server Management Studio (SSMS 22).
  - Key Engine Features: Referential Integrity, CHECK constraints, CTEs, Window Functions, Views, Stored Procedures, ACID Transactions.
- **Document / Event Storage:** MongoDB 8.0
  - Purpose: High-throughput ingestion of telemetry pings (`driver_location_events`), dispatch events (`dispatch_events`), and operational audit logs (`ride_activity_logs`).
  - Tools: MongoDB Compass & `mongosh`.
- **Application Backend:** Python 3.13
  - Core Modules: Layered architecture (`entity/`, `dao/`, `service/`, `exception/`, `util/`, `main/`).
  - Database Driver: `pyodbc` for SQL Server; `pymongo` for MongoDB.
- **Development Lifecycle:** Agile Scrum framework tracked via JIRA board conventions, MoSCoW prioritization, and Git version control.

---

## 5. Scope & Boundary Conditions

### In Scope
- Six relational master entities (`Rider`, `Driver`, `Vehicle`, `LocationPing`, `Trip`, `Rating`).
- Robust referential integrity, domain constraints, and audit logging.
- Advanced SQL Server Day 9 deliverables: Views, Stored Procedures, Functions, and Cursors.
- MongoDB operational collections with JSON Schema validation and aggregation views.
- Clean 3-tier Python architecture separating domain models, data access objects, and business services.

### Out of Scope (Sprint 1 Baseline)
- External third-party payment gateway integration.
- Hardware-level GPS device firmware.
- Native mobile client applications (Android/iOS) — the system interface is an enterprise console backend.
- Complex machine learning demand forecasting (deferred to post-foundation sprints).
