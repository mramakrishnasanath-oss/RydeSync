# RideSync — Next Steps & Pending Development Roadmap

**Document Reference:** `DOC-22-NEXT-STEPS`  
**Current Milestone:** Day 9 (Views, Procedures, Functions, Cursors & MongoDB)  
**Upcoming Milestones:** Days 10 through 22 (Hexaware Python Digital Foundation)  

---

## 1. Immediate Next Step: Wednesday Trainer Demonstration
1. Rehearse the 5-minute and 15-minute scripts from [20_Trainer_Demo_Guide.md](file:///c:/Users/sanat/OneDrive/Desktop/RideSync%20Project/docs/20_Trainer_Demo_Guide.md).
2. Open SQL Server Management Studio (SSMS 22) and run `database/sql/01_create_database.sql` through `08_test_and_validation.sql`.
3. Review the top viva defense questions in [21_Trainer_Interview_Questions.md](file:///c:/Users/sanat/OneDrive/Desktop/RideSync%20Project/docs/21_Trainer_Interview_Questions.md).

---

## 2. Roadmap for Days 10 to 22 (Sprint 1 Close & Sprint 2 Backend)

| Day # | Calendar Date | Syllabus Topic | RideSync Technical Deliverable |
| :---: | :---: | :--- | :--- |
| **Day 10** | Nov 18, 2026 | **Triggers** (`AFTER`, `INSTEAD OF`, inserted/deleted tables) | Implement `trg_trip_audit` (captures trip state transitions into audit table) and `trg_prevent_unassigned_online` (blocks driver going online without vehicle). |
| **Day 11** | Nov 20, 2026 | **Coding Challenge Platform** (SQL Server & MongoDB Assessment) | Timed challenge drill covering queries, joins, and transactional procedures. |
| **Day 12** | Nov 23, 2026 | **Python 3.13 Introduction & Business Rules** | Connect Python to `RideSyncDB` using `pyodbc`; implement fare and surge calculation rules. |
| **Day 13** | Nov 25, 2026 | **OOP & Domain Hierarchy** | Extend domain models; implement Polymorphism for Ride tiers (RideStandard, RidePremium, RideEV). |
| **Day 14** | Nov 26, 2026 | **Protocols, Special Methods & String API** | Implement `__eq__`, `__hash__`, `__repr__` for entities and formatted receipt generators. |
| **Day 15** | Nov 27, 2026 | **Decorators, Generators & Functional Tools** | Stream simulation generator `simulate_driver_telemetry()` yielding GPS pings every 2–3s. |
| **Day 16** | Nov 30, 2026 | **Multithreading & Async IO** | Concurrency simulator testing simultaneous ride requests against `sp_assign_driver`. |
| **Days 17-22** | Dec 1–8, 2026 | **DAO Layer, Service Layer, CLI Runner & Capstone Close** | Complete Console CLI application with interactive dispatch menu. |
