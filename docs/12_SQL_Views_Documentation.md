# RideSync — Day 9 SQL Views Documentation

**Document Reference:** `DOC-12-VIEWS`  
**Database:** `RideSyncDB`  
**Day 9 Topic:** Views (Simple, Complex, Updatable with `WITH CHECK OPTION`)  

---

## 1. Summary of Implemented Views

| View Name | Classification | Underlying Tables | Key SQL Concepts | Purpose |
| :--- | :---: | :--- | :--- | :--- |
| `vw_driver_availability` | Simple View | `Drivers`, `Vehicles` | `INNER JOIN`, Column projection | Active driver dispatch dashboard |
| `vw_trip_summary` | Complex View | `Trips`, `Riders`, `Drivers`, `Vehicles`, `Ratings` | Multi-table `LEFT JOIN`, `DATEDIFF` | Consolidated ride lifecycle analytics |
| `vw_driver_location_history`| Complex Analytical | `LocationPings`, `Drivers` | CTE, `ROW_NUMBER() OVER()` | Latest known location per driver |
| `vw_zone_supply_summary` | Aggregate View | `Drivers`, `LocationPings` | `GROUP BY`, `CASE`, Aggregates | Urban supply-demand heat analysis |
| `vw_online_drivers_updatable`| Updatable View | `Drivers` | `WITH CHECK OPTION` | Secured operational status maintenance |

---

## 2. In-Depth View Breakdown

### View 1: `dbo.vw_driver_availability` (Simple View)
- **Business Purpose:** Exposes currently active (`ONLINE`) drivers and their vehicle specifications for dispatch routing.
- **Security Implications:** Hides driver registration dates, internal database IDs, and sensitive phone numbers from dispatch operators.
- **SQL Definition:**
  ```sql
  CREATE OR ALTER VIEW dbo.vw_driver_availability AS
  SELECT 
      d.DriverID,
      d.FirstName + ' ' + d.LastName AS DriverFullName,
      d.Status AS DriverStatus,
      v.VehicleID,
      v.PlateNumber,
      v.Model AS VehicleModel
  FROM dbo.Drivers d
  INNER JOIN dbo.Vehicles v ON d.VehicleID = v.VehicleID
  WHERE d.Status = 'ONLINE';
  ```
- **JOIN Explanation:** `INNER JOIN dbo.Vehicles` ensures that only drivers with an assigned, verified vehicle appear in the available pool.

---

### View 2: `dbo.vw_trip_summary` (Complex Reporting View)
- **Business Purpose:** Central reporting dashboard showing every trip, rider details, assigned driver, vehicle, duration latency, fare, and feedback.
- **SQL Definition:**
  ```sql
  CREATE OR ALTER VIEW dbo.vw_trip_summary AS
  SELECT 
      t.TripID,
      t.Status AS TripStatus,
      t.RequestedAt,
      t.MatchedAt,
      DATEDIFF(SECOND, t.RequestedAt, t.MatchedAt) AS DispatchLatencySeconds,
      t.Fare AS TotalFareINR,
      r.RiderID,
      r.FirstName + ' ' + r.LastName AS RiderName,
      r.Phone AS RiderPhone,
      d.DriverID,
      ISNULL(d.FirstName + ' ' + d.LastName, 'Unassigned') AS DriverName,
      d.Status AS DriverCurrentStatus,
      v.PlateNumber,
      v.Model AS VehicleModel,
      rt.Stars AS RatingStars,
      rt.Comment AS RiderComment
  FROM dbo.Trips t
  INNER JOIN dbo.Riders r ON t.RiderID = r.RiderID
  LEFT JOIN dbo.Drivers d ON t.DriverID = d.DriverID
  LEFT JOIN dbo.Vehicles v ON d.VehicleID = v.VehicleID
  LEFT JOIN dbo.Ratings rt ON t.TripID = rt.TripID;
  ```
- **JOIN Explanation:**
  - `INNER JOIN Riders`: Every trip must have an associated rider.
  - `LEFT JOIN Drivers`: Preserves pending trips where no driver has been matched yet (`Status = 'REQUESTED'`).
  - `LEFT JOIN Vehicles`: Accommodates unassigned drivers.
  - `LEFT JOIN Ratings`: Preserves trips that have not yet been rated by the passenger.

---

### View 3: `dbo.vw_driver_location_history` (Complex Analytical View)
- **Business Purpose:** Resolves the single latest known GPS ping for every driver in high-volume time-series data without slow correlated subqueries.
- **Key Technique:** Uses a Common Table Expression (CTE) and `ROW_NUMBER() OVER (PARTITION BY DriverID ORDER BY RecordedAt DESC)`.
- **Telemetry Freshness:** Categorizes drivers as `'FRESH'` if pinged within 60s, or `'STALE'` if older.

---

### View 4: `dbo.vw_online_drivers_updatable` (Updatable with `WITH CHECK OPTION`)
- **Business Purpose:** Permits operations staff to modify online driver profiles directly through the view.
- **The Role of `WITH CHECK OPTION`:**
  Under SQL Server rules, if an updatable view has a `WHERE` filter and `WITH CHECK OPTION`, any modification that would cause the affected row to no longer qualify for the view's `WHERE` clause is aborted with **Error 550**.
- **Demonstration:**
  ```sql
  -- This statement FAILS with Error 550:
  UPDATE dbo.vw_online_drivers_updatable SET Status = 'OFFLINE' WHERE DriverID = 1;
  ```
  This proves to your trainer that the view protects data consistency.
