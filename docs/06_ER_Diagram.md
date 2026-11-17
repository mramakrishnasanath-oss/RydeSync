# RideSync — Entity Relationship (ER) Diagrams & Data Models

**Document Reference:** `DOC-06-ERD`  
**System:** RideSync (UrbanGo Mobility)  
**Database Name:** `RideSyncDB`  
**Target RDBMS:** Microsoft SQL Server 2025 (v17)  

---

## 1. Executive Summary & Resolution of Ambiguity

The RideSync database architecture is built around **exactly six core entities**, strictly conforming to the original project requirements.

### Reconciliation of Section 3.1 vs Section 3.2
- **Section 3.1 (Entities):** Includes `VehicleID` inside the `Driver` entity.
- **Section 3.2 (Relationships):** Expressly details 4 narrative relationships:
  1. Rider to Trip ($1 : M$)
  2. Driver to Trip ($1 : M$)
  3. Driver to LocationPing ($1 : M$)
  4. Trip to Rating ($1 : 1 \text{ or } 1 : 0..1$)
- **Reconciliation Decision:** 
  The presence of `VehicleID` in `Driver` mandates an explicit 5th relational link: `Driver.VehicleID` references `Vehicle.VehicleID`. By enforcing a `UNIQUE` constraint on `Driver.VehicleID` while allowing `NULL` during driver registration before vehicle verification, we establish a clean **$1:1$ Optional** relationship. This prevents two active drivers from being assigned to the same vehicle concurrently.

---

## 2. Conceptual ER Diagram

The Conceptual ERD shows high-level business entities and their semantic relationships without technical keys or implementation data types.

```mermaid
erDiagram
    RIDER ||--o{ TRIP : "requests"
    DRIVER ||--o{ TRIP : "fulfills"
    DRIVER ||--o{ LOCATION_PING : "broadcasts"
    DRIVER ||--o| VEHICLE : "operates (1:1)"
    TRIP ||--o| RATING : "receives (0..1)"

    RIDER {
        string RiderID
        string FullName
        string ContactPhone
    }
    DRIVER {
        string DriverID
        string FullName
        string ActiveStatus
    }
    VEHICLE {
        string VehicleID
        string RegistrationPlate
        string CarModel
    }
    LOCATION_PING {
        string PingID
        float Latitude
        float Longitude
        timestamp RecordedAt
    }
    TRIP {
        string TripID
        timestamp RequestedAt
        timestamp MatchedAt
        string TripStatus
        decimal TotalFare
    }
    RATING {
        string RatingID
        int StarScore
        string RiderFeedback
    }
```

---

## 3. Logical ER Diagram

The Logical ERD introduces relational primary keys, foreign keys, logical domain rules, cardinalities, and optionality.

```mermaid
erDiagram
    RIDER ||--o{ TRIP : "places (1 to 0..N)"
    DRIVER ||--o{ TRIP : "accepts (1 to 0..N)"
    DRIVER ||--o{ LOCATION_PING : "emits (1 to 0..N)"
    DRIVER ||--o| VEHICLE : "assigned to (0..1 to 1)"
    TRIP ||--o| RATING : "evaluated by (1 to 0..1)"

    RIDER {
        int RiderID PK
        string FirstName
        string LastName
        string Phone UK
    }

    DRIVER {
        int DriverID PK
        string FirstName
        string LastName
        int VehicleID FK,UK "Nullable, 1:1 with Vehicle"
        string Status "ONLINE, OFFLINE, ON_TRIP, SUSPENDED"
    }

    VEHICLE {
        int VehicleID PK
        string PlateNumber UK
        string Model
    }

    LOCATION_PING {
        bigint PingID PK
        int DriverID FK
        decimal Latitude "Between -90 and 90"
        decimal Longitude "Between -180 and 180"
        datetime2 RecordedAt
    }

    TRIP {
        int TripID PK
        int RiderID FK
        int DriverID FK "Nullable until matched"
        datetime2 RequestedAt
        datetime2 MatchedAt "Nullable until matched"
        string Status "REQUESTED, MATCHED, IN_PROGRESS, COMPLETED, CANCELLED"
        decimal Fare "Nullable until completed"
    }

    RATING {
        int RatingID PK
        int TripID FK,UK "1:1 with completed Trip"
        int Stars "CHECK: 1 to 5"
        string Comment "Optional rider feedback"
    }
```

---

## 4. Physical Database Schema Diagram

The Physical Schema illustrates the exact SQL Server 2025 implementation types, IDENTITY specifications, nullability, and index constraints.

```mermaid
erDiagram
    Riders ||--o{ Trips : "FK_Trips_Riders"
    Drivers ||--o{ Trips : "FK_Trips_Drivers"
    Drivers ||--o{ LocationPings : "FK_LocationPings_Drivers"
    Vehicles ||--o| Drivers : "FK_Drivers_Vehicles"
    Trips ||--o| Ratings : "FK_Ratings_Trips"

    Riders {
        INT RiderID PK "IDENTITY(1,1)"
        NVARCHAR_50 FirstName "NOT NULL"
        NVARCHAR_50 LastName "NOT NULL"
        VARCHAR_15 Phone "NOT NULL, UNIQUE"
    }

    Vehicles {
        INT VehicleID PK "IDENTITY(1,1)"
        VARCHAR_20 PlateNumber "NOT NULL, UNIQUE"
        NVARCHAR_50 Model "NOT NULL"
    }

    Drivers {
        INT DriverID PK "IDENTITY(1,1)"
        NVARCHAR_50 FirstName "NOT NULL"
        NVARCHAR_50 LastName "NOT NULL"
        INT VehicleID FK "NULL, UNIQUE (1:1 Vehicle)"
        VARCHAR_20 Status "NOT NULL, DEFAULT 'OFFLINE'"
    }

    LocationPings {
        BIGINT PingID PK "IDENTITY(1,1)"
        INT DriverID FK "NOT NULL"
        DECIMAL_9_6 Latitude "NOT NULL"
        DECIMAL_9_6 Longitude "NOT NULL"
        DATETIME2_3 RecordedAt "NOT NULL, DEFAULT SYSUTCDATETIME()"
    }

    Trips {
        INT TripID PK "IDENTITY(1,1)"
        INT RiderID FK "NOT NULL"
        INT DriverID FK "NULL (Before Match)"
        DATETIME2_3 RequestedAt "NOT NULL, DEFAULT SYSUTCDATETIME()"
        DATETIME2_3 MatchedAt "NULL"
        VARCHAR_20 Status "NOT NULL, DEFAULT 'REQUESTED'"
        DECIMAL_10_2 Fare "NULL"
    }

    Ratings {
        INT RatingID PK "IDENTITY(1,1)"
        INT TripID FK "NOT NULL, UNIQUE (1:1 with Trip)"
        TINYINT Stars "NOT NULL, CHECK (1..5)"
        NVARCHAR_500 Comment "NULL"
    }
```

---

## 5. Relationship Cardinality & Business Rules Summary

| Relationship | Parent Entity | Child Entity | Cardinality | Enforced By | Business Integrity Rule |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **Driver–Vehicle** | `Vehicles` | `Drivers` | $1 : 0..1$ | `FK_Drivers_Vehicles` + `UQ_Drivers_VehicleID` | A driver may be registered before vehicle assignment. One vehicle cannot be operated by two drivers concurrently. |
| **Rider–Trip** | `Riders` | `Trips` | $1 : 0..N$ | `FK_Trips_Riders` | A rider can place multiple trip requests over time. Trip cannot exist without a valid registered rider. |
| **Driver–Trip** | `Drivers` | `Trips` | $1 : 0..N$ | `FK_Trips_Drivers` | A driver fulfills zero or many trips over their lifetime. `DriverID` is nullable during the initial `REQUESTED` stage. |
| **Driver–LocationPing** | `Drivers` | `LocationPings` | $1 : 0..N$ | `FK_LocationPings_Drivers` | Active drivers continuously stream location pings every 2–3s. Historical telemetry links to the driver. |
| **Trip–Rating** | `Trips` | `Ratings` | $1 : 0..1$ | `FK_Ratings_Trips` + `UQ_Ratings_TripID` | Each trip can receive at most one rating after completion. Duplicate ratings for the same trip are blocked. |
