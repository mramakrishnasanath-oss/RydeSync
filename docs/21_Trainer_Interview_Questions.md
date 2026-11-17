# RideSync — Trainer Viva & Technical Interview Defense Guide

**Audience:** B.Tech Trainee Evaluation  
**Subject:** MS SQL Server 2025, SSMS 22, MongoDB 8.0, Python 3.13 Architecture  
**Document Reference:** `DOC-21-VIVA-QNA`  

---

## 1. Core Database Architecture & Design Questions

### Q1: What normal form is your RideSync database in? Prove it.
**Answer:**  
*"Sir, our RideSync database is in **Third Normal Form (3NF)** and conforms to **Boyce-Codd Normal Form (BCNF)**.*  
- *It satisfies **1NF** because every attribute contains only atomic, indivisible values (e.g. Latitude and Longitude are separated, names are split into FirstName/LastName, and there are no repeating groups).*  
- *It satisfies **2NF** because all tables have single-column primary keys (`RiderID`, `DriverID`, `VehicleID`, etc.), so no partial functional dependency on a composite key can exist.*  
- *It satisfies **3NF** because there are zero transitive dependencies—non-key attributes depend solely on the primary key, not on other non-key attributes (e.g., Vehicle model depends on `VehicleID`, not `DriverID`)."*

---

### Q2: Why is `VehicleID` placed in `Driver` instead of `DriverID` in `Vehicle`?
**Answer:**  
*"In Section 3.1 of the case study specification, `VehicleID` is explicitly designated as an attribute of the `Driver` entity.*  
*Architecturally, placing `VehicleID` in `Driver` allows a driver to exist in the system during background verification before being assigned a vehicle (`VehicleID IS NULL`). By placing a **`UNIQUE` constraint** on `Driver(VehicleID)`, we strictly enforce a **$1 : 0..1$ relationship**, guaranteeing that a physical vehicle can never be assigned to two active drivers simultaneously."*

---

### Q3: Why did you use `BIGINT` for `LocationPings.PingID` while using `INT` for `Trips.TripID`?
**Answer:**  
*"Because of the **data volume velocity**.*  
*A standard 32-bit signed integer (`INT`) has an upper boundary of approximately $2.14 \times 10^9$ (2.14 billion rows). While UrbanGo might complete millions of trips over several years (well within `INT`), active drivers stream GPS location pings every **2 to 3 seconds**.*  
*With 10,000 active drivers emitting a ping every 3 seconds, that generates $288 \times 10^6$ pings every single day. A standard `INT` would overflow in just over a week. `BIGINT` (64-bit integer) provides capacity up to $9.22 \times 10^{18}$ rows, ensuring centuries of safe telemetry storage."*

---

## 2. Advanced Day 9 T-SQL Questions (Views, Procedures, Functions, Cursors)

### Q4: What is the difference between a Stored Procedure and a Stored Function in SQL Server?
**Answer:**  
| Feature | Stored Procedure (`CREATE PROCEDURE`) | Stored Function (`CREATE FUNCTION`) |
| :--- | :--- | :--- |
| **Purpose** | Executes transactional business workflows & actions. | Computes and returns values or table result sets. |
| **Transactions** | Can initiate transactions (`BEGIN TRAN`, `COMMIT`, `ROLLBACK`). | Cannot initiate transactions or modify database state. |
| **Usage in SQL** | Invoked standalone via `EXEC` or `{CALL ...}`. | Can be embedded directly inside `SELECT`, `WHERE`, `JOIN`. |
| **Return Value** | Returns zero, one, or multiple result sets plus status code. | Must return exactly one scalar value or one table variable. |
| **Parameters** | Supports `IN` and `OUTPUT` parameters. | Supports only `IN` parameters. |

*"In RideSync, we use Stored Procedures for stateful actions like `sp_assign_driver` and `sp_complete_trip`, and Functions for deterministic calculations like `fn_calculate_distance` and `fn_estimate_fare`."*

---

### Q5: What does `WITH CHECK OPTION` do in an updatable view?
**Answer:**  
*"Sir, `WITH CHECK OPTION` ensures that any `INSERT` or `UPDATE` executed through a view must conform to the view's filtering criteria defined in its `WHERE` clause.*  
*In our view `dbo.vw_online_drivers_updatable`, the filter is `WHERE Status = 'ONLINE'`. If an operator attempts to execute:*
```sql
UPDATE dbo.vw_online_drivers_updatable SET Status = 'OFFLINE' WHERE DriverID = 1;
```
*SQL Server intercepts the command and rejects it with **Error 550**, because setting the status to 'OFFLINE' would cause that row to disappear from the view. This protects operational security and data integrity."*

---

### Q6: How does your `sp_assign_driver` procedure prevent race conditions (double driver booking)?
**Answer:**  
*"Sir, `sp_assign_driver` enforces ACID isolation using pessimistic row locking with **`UPDLOCK` and `HOLDLOCK`** hints inside a transaction:*
```sql
BEGIN TRANSACTION;
SELECT Status FROM dbo.Trips WITH (UPDLOCK, HOLDLOCK) WHERE TripID = @TripID;
SELECT Status FROM dbo.Drivers WITH (UPDLOCK, HOLDLOCK) WHERE DriverID = @DriverID;
```
- *`UPDLOCK` tells SQL Server to acquire an update lock immediately instead of a shared lock, preventing two concurrent transactions from simultaneously reading the driver as available.*  
- *`HOLDLOCK` maintains the lock until the transaction finishes (`SERIALIZABLE` level).*  
- *If Trip is `REQUESTED` and Driver is `ONLINE`, we update Driver to `ON_TRIP` and Trip to `MATCHED` and `COMMIT`.*  
- *If another rider's transaction attempts to claim the same driver in that millisecond, it is queued until the lock releases, sees Driver status is now `ON_TRIP`, and automatically **ROLLS BACK**.*  
*This guarantees 100% elimination of double-booking."*

---

### Q7: Why are Cursors discouraged in production, and how did you implement it for Day 9?
**Answer:**  
*"Cursors operate on a **row-by-row procedural model** (RBAR: Row By Agonizing Row) rather than the relational engine's native **set-based model**.*  
*Each fetch in a cursor incurs network buffer and engine context-switch overhead, holds row locks iteratively, and consumes cursor memory structures on the server.*  
*For our Day 9 exercise, I implemented `sp_process_stale_drivers` using the complete cursor lifecycle:*
1. `DECLARE cur_stale_drivers CURSOR FAST_FORWARD FOR ...`
2. `OPEN cur_stale_drivers;`
3. `FETCH NEXT FROM cur_stale_drivers INTO ...;`
4. `WHILE @@FETCH_STATUS = 0 BEGIN ... FETCH NEXT ... END;`
5. `CLOSE cur_stale_drivers;`
6. `DEALLOCATE cur_stale_drivers;`
*I also documented the set-based alternative using a single `UPDATE ... FROM ... WHERE` statement, showing that set-based execution runs in a single optimized pass in $O(1)$ batch time compared to $O(N)$ cursor iterations."*

---

## 3. Polyglot Persistence & Architecture Questions

### Q8: Why use both SQL Server 2025 and MongoDB 8.0? Why not just one?
**Answer:**  
*"Because RideSync has two distinctly different data access patterns:*
1. **Transactional Master Data (SQL Server):** Riders, Drivers, Vehicles, Trips, and Fares require strict **ACID compliance**, referential foreign keys, unique constraints, and structured reporting. A financial transaction or trip contract cannot afford eventual consistency.
2. **High-Velocity Telemetry Streams (MongoDB):** Drivers streaming GPS pings every 2–3 seconds produce millions of ephemeral breadcrumbs daily. MongoDB excels at horizontal write scalability, has native **GeoJSON 2dsphere indexes** for spatial radius searching, flexible payload schemas for varied device sensors, and automatic data expiration via **TTL (Time-To-Live) indexes**."*

---

### Q9: How will Python 3.13 connect to your SQL Server stored procedures?
**Answer:**  
*"Using the Microsoft ODBC Driver 18 for SQL Server via `pyodbc`.*  
*In our `util.db_connection.DBConnection` manager, we open a pooled connection and execute stored procedures using the standard ODBC call syntax:*
```python
with DBConnection.get_sql_cursor() as cursor:
    cursor.execute("{CALL dbo.sp_assign_driver (?, ?, ?, ?)}", (trip_id, driver_id, success, message))
```
*This separates application logic from the database engine, prevents SQL injection, and executes pre-compiled query plans on the SQL Server instance."*
