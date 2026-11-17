# RideSync — SQL Schema Detailed Technical Explanation

**Document Reference:** `DOC-09-SCHEMA`  
**Database:** `RideSyncDB`  
**RDBMS:** Microsoft SQL Server 2025 (v17)  

---

## 1. Schema Architecture & Collation

`RideSyncDB` is provisioned under the modern `Latin1_General_100_CI_AS_SC_UTF8` collation.  
- **UTF-8 Support:** Allows efficient native UTF-8 character storage in `NVARCHAR` columns while supporting international rider and driver names without multi-byte collation translation penalties.
- **Read Committed Snapshot Isolation (RCSI):** Configured via `ALTER DATABASE RideSyncDB SET READ_COMMITTED_SNAPSHOT ON`. This guarantees that read operations (such as spatial dispatch searches and reporting queries) never block write operations, and writes never block reads.

---

## 2. Table-by-Table Architectural Specification

### Table 1: `dbo.Riders`
- **Role:** Master passenger registry.
- **Key Columns:**
  - `RiderID INT IDENTITY(1,1) PRIMARY KEY`: Surrogate integer key.
  - `Phone VARCHAR(15) NOT NULL UNIQUE`: Enforces single account per phone number; indexed automatically via non-clustered unique index.
  - `CreatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()`: Microsecond-precision UTC creation timestamp.

### Table 2: `dbo.Vehicles`
- **Role:** Fleet vehicle registry.
- **Key Columns:**
  - `VehicleID INT IDENTITY(1,1) PRIMARY KEY`: Surrogate key.
  - `PlateNumber VARCHAR(20) NOT NULL UNIQUE`: Government motor vehicle registration plate; prevents duplicate vehicle registrations across fleet.
  - `Model NVARCHAR(50) NOT NULL`: Make, model, and trim (e.g. 'Maruti Suzuki Dzire VXi').

### Table 3: `dbo.Drivers`
- **Role:** Service partner registry and availability tracker.
- **Key Columns:**
  - `DriverID INT IDENTITY(1,1) PRIMARY KEY`: Surrogate key.
  - `VehicleID INT NULL UNIQUE`: References `dbo.Vehicles(VehicleID)`. `NULL` permits onboarding before car assignment; `UNIQUE` ensures strict 1:1 vehicle allocation.
  - `Status VARCHAR(20) NOT NULL DEFAULT 'OFFLINE'`: Domain validated via `CHECK (Status IN ('OFFLINE', 'ONLINE', 'ON_TRIP', 'SUSPENDED'))`.

### Table 4: `dbo.LocationPings`
- **Role:** High-velocity time-series telemetry breadcrumbs.
- **Key Columns:**
  - `PingID BIGINT IDENTITY(1,1) PRIMARY KEY`: 64-bit integer supporting billions of continuous records without overflow.
  - `DriverID INT NOT NULL`: Foreign key referencing `dbo.Drivers(DriverID)`.
  - `Latitude DECIMAL(9,6) NOT NULL`: Precise to ~11 cm.
  - `Longitude DECIMAL(9,6) NOT NULL`: Precise to ~11 cm.
  - `RecordedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()`: Timestamp indexed in composite index `(DriverID, RecordedAt DESC)` for sub-millisecond recency queries.

### Table 5: `dbo.Trips`
- **Role:** Core transportation contract and lifecycle state machine.
- **Key Columns:**
  - `TripID INT IDENTITY(1,1) PRIMARY KEY`: Surrogate key.
  - `RiderID INT NOT NULL`: References `dbo.Riders(RiderID)`.
  - `DriverID INT NULL`: Nullable while trip is in `REQUESTED` status; populated upon atomic dispatch.
  - `RequestedAt DATETIME2(3) NOT NULL`: Booking request timestamp.
  - `MatchedAt DATETIME2(3) NULL`: Dispatch assignment timestamp.
  - `Status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED'`: `CHECK (Status IN ('REQUESTED', 'MATCHED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))`.
  - `Fare DECIMAL(10,2) NULL`: Final billing amount in INR; computed upon trip completion.

### Table 6: `dbo.Ratings`
- **Role:** Post-trip customer satisfaction review.
- **Key Columns:**
  - `RatingID INT IDENTITY(1,1) PRIMARY KEY`: Surrogate key.
  - `TripID INT NOT NULL UNIQUE`: Foreign key to `dbo.Trips(TripID)`. `UNIQUE` enforces strict 1:1 relationship between completed trip and review.
  - `Stars TINYINT NOT NULL CHECK (Stars BETWEEN 1 AND 5)`: 1 to 5 star rating.
  - `Comment NVARCHAR(500) NULL`: Rider feedback comment.
