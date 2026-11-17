# RideSync — Relational Database Design & Normalization Proof

**Document Reference:** `DOC-05-DB-DESIGN`  
**Database Name:** `RideSyncDB`  
**RDBMS:** Microsoft SQL Server 2025 (v17)  

---

## 1. Normalization Proof (1NF through BCNF)

### First Normal Form (1NF) Compliance
A relational table is in 1NF if and only if all domain values are atomic and there are no repeating groups.
- **Riders & Drivers:** Names are decomposed into discrete atomic attributes (`FirstName` and `LastName`), rather than a composite `FullName` string. Contact phones are stored as single atomic strings.
- **LocationPings:** GPS coordinates are stored as separate atomic decimal columns (`Latitude` and `Longitude`), rather than composite coordinate strings or serialized arrays.
- **Trips:** Timestamps are discrete UTC values (`RequestedAt`, `MatchedAt`).
- **Conclusion:** 1NF is 100% satisfied across all tables.

### Second Normal Form (2NF) Compliance
A relation is in 2NF if it is in 1NF and every non-prime attribute is fully functionally dependent on the primary key (no partial dependencies).
- In `RideSyncDB`, every table utilizes a **single-column surrogate primary key** (`RiderID`, `DriverID`, `VehicleID`, `PingID`, `TripID`, `RatingID`).
- Because no primary key is composite, a partial key dependency is mathematically impossible.
- **Conclusion:** 2NF is 100% satisfied across all tables.

### Third Normal Form (3NF) Compliance
A relation is in 3NF if it is in 2NF and no non-prime attribute is transitively dependent on the primary key ($X \rightarrow Y$ and $Y \rightarrow Z$).
- In `dbo.Drivers`, `VehicleID` is stored as a foreign key. Attribute values describing the car (`PlateNumber`, `Model`) are **not stored in Drivers**; they reside solely in `dbo.Vehicles`.
- In `dbo.Trips`, rider phone numbers and driver names are not duplicated; they reside in `dbo.Riders` and `dbo.Drivers`.
- **Conclusion:** 3NF is 100% satisfied across all tables.

### Boyce-Codd Normal Form (BCNF) Compliance
A relation is in BCNF if for every functional dependency $X \rightarrow Y$, $X$ is a superkey.
- In `dbo.Riders`, $Phone \rightarrow RiderID$ exists, but `Phone` has a `UNIQUE` constraint, making it a candidate key (superkey).
- In `dbo.Vehicles`, $PlateNumber \rightarrow VehicleID$ exists, but `PlateNumber` is also a candidate key (`UNIQUE`).
- In `dbo.Drivers`, $VehicleID \rightarrow DriverID$ exists, but `VehicleID` has a `UNIQUE` constraint, making it a candidate key.
- **Conclusion:** BCNF is 100% satisfied across all tables.

---

## 2. Table Indexing Architecture

| Table | Index Name | Type | Key Columns | Included Columns | Optimization Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Riders` | `PK_Riders` | Clustered | `RiderID` | All | Primary key search |
| `Riders` | `UQ_Riders_Phone` | Non-Clustered | `Phone` | None | Unique enforcement & rider login |
| `Vehicles`| `PK_Vehicles` | Clustered | `VehicleID` | All | Primary key search |
| `Vehicles`| `UQ_Vehicles_PlateNumber` | Non-Clustered | `PlateNumber`| None | Fleet deduplication |
| `Drivers` | `PK_Drivers` | Clustered | `DriverID` | All | Primary key search |
| `Drivers` | `IX_Drivers_Status` | Non-Clustered | `Status` | `VehicleID, FirstName, LastName` | Fast dispatch lookup for `ONLINE` drivers |
| `LocationPings` | `PK_LocationPings` | Clustered | `PingID` | All | Primary key search |
| `LocationPings` | `IX_LocationPings_Driver_Time` | Non-Clustered | `DriverID, RecordedAt DESC` | `Latitude, Longitude` | Sub-millisecond latest driver location retrieval |
| `Trips` | `PK_Trips` | Clustered | `TripID` | All | Primary key search |
| `Trips` | `IX_Trips_Status_Rider` | Non-Clustered | `Status, RiderID` | `DriverID, RequestedAt` | Active rider booking status checks |
| `Ratings`| `PK_Ratings` | Clustered | `RatingID` | All | Primary key search |
| `Ratings`| `UQ_Ratings_TripID` | Non-Clustered | `TripID` | None | Enforces strict 1:1 Trip rating rule |
