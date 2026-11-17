# RideSync — Comprehensive Constraints Documentation

**Document Reference:** `DOC-10-CONSTRAINTS`  
**Database:** `RideSyncDB` (Microsoft SQL Server 2025)  

---

## 1. Primary Key Constraints (Entity Integrity)

| Table | Constraint Name | Column(s) | Clustered? | Business Purpose |
| :--- | :--- | :--- | :---: | :--- |
| `Riders` | `PK_Riders` | `RiderID` | Yes | Uniquely identifies each registered passenger account. |
| `Vehicles` | `PK_Vehicles` | `VehicleID` | Yes | Uniquely identifies each physical fleet vehicle. |
| `Drivers` | `PK_Drivers` | `DriverID` | Yes | Uniquely identifies each licensed driver partner. |
| `LocationPings` | `PK_LocationPings` | `PingID` | Yes | High-cardinality 64-bit (`BIGINT`) telemetry identifier. |
| `Trips` | `PK_Trips` | `TripID` | Yes | Uniquely identifies each ride contract. |
| `Ratings` | `PK_Ratings` | `RatingID` | Yes | Uniquely identifies each customer feedback record. |

---

## 2. Foreign Key Constraints (Referential Integrity)

| Constraint Name | Child Table | Child Column | Parent Table | Parent Column | On Delete | On Update |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `FK_Drivers_Vehicles` | `Drivers` | `VehicleID` | `Vehicles` | `VehicleID` | `SET NULL` | `CASCADE` |
| `FK_Trips_Riders` | `Trips` | `RiderID` | `Riders` | `RiderID` | `NO ACTION` | `CASCADE` |
| `FK_Trips_Drivers` | `Trips` | `DriverID` | `Drivers` | `DriverID` | `NO ACTION` | `CASCADE` |
| `FK_LocationPings_Drivers` | `LocationPings` | `DriverID` | `Drivers` | `DriverID` | `CASCADE` | `CASCADE` |
| `FK_Ratings_Trips` | `Ratings` | `TripID` | `Trips` | `TripID` | `CASCADE` | `CASCADE` |

---

## 3. Unique Constraints (Domain Uniqueness)

| Constraint Name | Table | Column(s) | Business Rule Enforced |
| :--- | :--- | :--- | :--- |
| `UQ_Riders_Phone` | `Riders` | `Phone` | Prevents multiple accounts under the same phone number. |
| `UQ_Vehicles_PlateNumber` | `Vehicles` | `PlateNumber` | Prevents registering duplicate physical vehicles. |
| `UQ_Drivers_VehicleID` | `Drivers` | `VehicleID` | Strictly guarantees that one car cannot be driven by 2 drivers simultaneously (1:1). |
| `UQ_Ratings_TripID` | `Ratings` | `TripID` | Strictly guarantees that a trip can receive at most one rating (1:1). |

---

## 4. CHECK Constraints (Domain Validation)

| Constraint Name | Table | Condition / Predicate | Failure Consequence |
| :--- | :--- | :--- | :--- |
| `CK_Riders_Phone` | `Riders` | `LEN(Phone) >= 10 AND Phone NOT LIKE '%[^0-9+]%'` | Blocks malformed or non-numeric phone strings. |
| `CK_Drivers_Status` | `Drivers` | `Status IN ('OFFLINE', 'ONLINE', 'ON_TRIP', 'SUSPENDED')` | Blocks arbitrary unhandled status strings. |
| `CK_LocationPings_Latitude` | `LocationPings` | `Latitude BETWEEN -90.000000 AND 90.000000` | Rejects impossible GPS latitudes. |
| `CK_LocationPings_Longitude` | `LocationPings` | `Longitude BETWEEN -180.000000 AND 180.000000`| Rejects impossible GPS longitudes. |
| `CK_Trips_Status` | `Trips` | `Status IN ('REQUESTED', 'MATCHED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')` | Enforces valid trip lifecycle states. |
| `CK_Trips_Fare` | `Trips` | `Fare IS NULL OR Fare >= 0.00` | Prevents negative billing amounts. |
| `CK_Trips_MatchSequence` | `Trips` | `MatchedAt IS NULL OR MatchedAt >= RequestedAt` | Prevents temporal paradoxes (match before request). |
| `CK_Ratings_Stars` | `Ratings` | `Stars BETWEEN 1 AND 5` | Blocks ratings outside standard 1–5 scale. |

---

## 5. DEFAULT Constraints (Audit & State Baseline)

| Constraint Name | Table | Column | Default Expression | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `DF_Riders_CreatedAt` | `Riders` | `CreatedAt` | `SYSUTCDATETIME()` | Automatic registration UTC audit timestamp. |
| `DF_Vehicles_RegisteredAt`| `Vehicles`| `RegisteredAt`| `SYSUTCDATETIME()` | Automatic fleet registration UTC timestamp. |
| `DF_Drivers_Status` | `Drivers` | `Status` | `'OFFLINE'` | Safe offline default upon driver registration. |
| `DF_Drivers_RegisteredAt` | `Drivers` | `RegisteredAt`| `SYSUTCDATETIME()` | Driver onboarding UTC timestamp. |
| `DF_LocationPings_RecordedAt`| `LocationPings`| `RecordedAt`| `SYSUTCDATETIME()`| High-resolution telemetry ingestion timestamp. |
| `DF_Trips_RequestedAt` | `Trips` | `RequestedAt` | `SYSUTCDATETIME()` | Booking request timestamp. |
| `DF_Trips_Status` | `Trips` | `Status` | `'REQUESTED'` | Initial default booking state. |
| `DF_Ratings_CreatedAt` | `Ratings` | `CreatedAt` | `SYSUTCDATETIME()` | Review submission timestamp. |
