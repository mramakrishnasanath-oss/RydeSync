# RideSync — Entity & Attribute Data Dictionary

**Document Reference:** `DOC-07-DICTIONARY`  
**Database:** `RideSyncDB` (Microsoft SQL Server 2025)  

---

## 1. Relational Entities Data Dictionary

### Entity 1: Rider (`Riders`)
- **Primary Business Role:** Represents the customer who books transportation through UrbanGo Mobility.
- **Primary Key:** `RiderID` (Auto-incrementing integer)

| Column Name | SQL Data Type | Nullability | Constraints | Business Purpose & Description |
| :--- | :--- | :---: | :--- | :--- |
| `RiderID` | `INT` | `NOT NULL` | `PRIMARY KEY`, `IDENTITY(1,1)` | Unique internal system identifier for each rider. |
| `FirstName` | `NVARCHAR(50)` | `NOT NULL` | None | Rider's given name; Unicode support for international characters. |
| `LastName` | `NVARCHAR(50)` | `NOT NULL` | None | Rider's family name / surname. |
| `Phone` | `VARCHAR(15)` | `NOT NULL` | `UNIQUE`, `CHECK(Phone LIKE '+%[0-9]%')` | Contact telephone number; must be unique to prevent duplicate accounts. |

---

### Entity 2: Driver (`Drivers`)
- **Primary Business Role:** Represents the licensed service partner available to fulfill dispatch requests.
- **Primary Key:** `DriverID` (Auto-incrementing integer)

| Column Name | SQL Data Type | Nullability | Constraints | Business Purpose & Description |
| :--- | :--- | :---: | :--- | :--- |
| `DriverID` | `INT` | `NOT NULL` | `PRIMARY KEY`, `IDENTITY(1,1)` | Unique internal system identifier for each driver. |
| `FirstName` | `NVARCHAR(50)` | `NOT NULL` | None | Driver's given name. |
| `LastName` | `NVARCHAR(50)` | `NOT NULL` | None | Driver's family name. |
| `VehicleID` | `INT` | `NULL` | `FOREIGN KEY REFERENCES Vehicles(VehicleID)`, `UNIQUE` | Assigned vehicle. Nullable during initial onboarding; `UNIQUE` ensures 1:1 allocation. |
| `Status` | `VARCHAR(20)` | `NOT NULL` | `DEFAULT 'OFFLINE'`, `CHECK(Status IN ('OFFLINE', 'ONLINE', 'ON_TRIP', 'SUSPENDED'))` | Current operational availability of the driver. |

---

### Entity 3: Vehicle (`Vehicles`)
- **Primary Business Role:** Represents the physical automobile registered to transport riders.
- **Primary Key:** `VehicleID` (Auto-incrementing integer)

| Column Name | SQL Data Type | Nullability | Constraints | Business Purpose & Description |
| :--- | :--- | :---: | :--- | :--- |
| `VehicleID` | `INT` | `NOT NULL` | `PRIMARY KEY`, `IDENTITY(1,1)` | Unique internal system identifier for the vehicle. |
| `PlateNumber` | `VARCHAR(20)` | `NOT NULL` | `UNIQUE` | Official government motor vehicle registration license plate. |
| `Model` | `NVARCHAR(50)` | `NOT NULL` | None | Commercial make, model, and year (e.g., 'Toyota Camry Hybrid'). |

---

### Entity 4: LocationPing (`LocationPings`)
- **Primary Business Role:** High-volume time-series telemetry representing continuous GPS breadcrumbs streamed by active drivers.
- **Primary Key:** `PingID` (Auto-incrementing 64-bit integer)

| Column Name | SQL Data Type | Nullability | Constraints | Business Purpose & Description |
| :--- | :--- | :---: | :--- | :--- |
| `PingID` | `BIGINT` | `NOT NULL` | `PRIMARY KEY`, `IDENTITY(1,1)` | Unique high-cardinality telemetry breadcrumb identifier. |
| `DriverID` | `INT` | `NOT NULL` | `FOREIGN KEY REFERENCES Drivers(DriverID)` | Driver who broadcast the GPS ping. |
| `Latitude` | `DECIMAL(9,6)` | `NOT NULL` | `CHECK(Latitude BETWEEN -90.000000 AND 90.000000)` | GPS latitude coordinate (precise to ~11 cm). |
| `Longitude` | `DECIMAL(9,6)` | `NOT NULL` | `CHECK(Longitude BETWEEN -180.000000 AND 180.000000)` | GPS longitude coordinate (precise to ~11 cm). |
| `RecordedAt` | `DATETIME2(3)` | `NOT NULL` | `DEFAULT SYSUTCDATETIME()` | UTC timestamp when the ping was logged. |

---

### Entity 5: Trip (`Trips`)
- **Primary Business Role:** Represents the core ride contract between a rider and an assigned driver.
- **Primary Key:** `TripID` (Auto-incrementing integer)

| Column Name | SQL Data Type | Nullability | Constraints | Business Purpose & Description |
| :--- | :--- | :---: | :--- | :--- |
| `TripID` | `INT` | `NOT NULL` | `PRIMARY KEY`, `IDENTITY(1,1)` | Unique identifier for the ride engagement. |
| `RiderID` | `INT` | `NOT NULL` | `FOREIGN KEY REFERENCES Riders(RiderID)` | Customer requesting the ride. |
| `DriverID` | `INT` | `NULL` | `FOREIGN KEY REFERENCES Drivers(DriverID)` | Driver allocated to the trip; `NULL` while in `REQUESTED` status. |
| `RequestedAt` | `DATETIME2(3)` | `NOT NULL` | `DEFAULT SYSUTCDATETIME()` | UTC timestamp when the booking was initiated. |
| `MatchedAt` | `DATETIME2(3)` | `NULL` | `CHECK(MatchedAt >= RequestedAt)` | UTC timestamp when dispatch successfully assigned an available driver. |
| `Status` | `VARCHAR(20)` | `NOT NULL` | `DEFAULT 'REQUESTED'`, `CHECK(Status IN ('REQUESTED', 'MATCHED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))` | Current lifecycle state of the trip. |
| `Fare` | `DECIMAL(10,2)`| `NULL` | `CHECK(Fare >= 0.00)` | Final computed billing amount (INR); calculated upon completion. |

---

### Entity 6: Rating (`Ratings`)
- **Primary Business Role:** Rider feedback and performance rating submitted upon trip completion.
- **Primary Key:** `RatingID` (Auto-incrementing integer)

| Column Name | SQL Data Type | Nullability | Constraints | Business Purpose & Description |
| :--- | :--- | :---: | :--- | :--- |
| `RatingID` | `INT` | `NOT NULL` | `PRIMARY KEY`, `IDENTITY(1,1)` | Unique identifier for the review record. |
| `TripID` | `INT` | `NOT NULL` | `FOREIGN KEY REFERENCES Trips(TripID)`, `UNIQUE` | Completed trip being evaluated; `UNIQUE` enforces strict 1:1 rating rule. |
| `Stars` | `TINYINT` | `NOT NULL` | `CHECK(Stars BETWEEN 1 AND 5)` | Numerical satisfaction score (1 to 5 stars). |
| `Comment` | `NVARCHAR(500)`| `NULL` | None | Qualitative rider comments or feedback notes. |
