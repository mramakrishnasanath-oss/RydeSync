# RideSync — Relational Relationships & Referential Integrity

**Document Reference:** `DOC-08-RELATIONSHIPS`  
**System:** RideSync (UrbanGo Mobility)  
**Database:** `RideSyncDB`  

---

## 1. Overview of Relationships

RideSync defines **exactly five relational associations** across its six core entities:

```
[Vehicles] 1 ──── 0..1 [Drivers] 1 ──── 0..N [LocationPings]
                         │
                         │ 1
                         │
                         ▼ 0..N
[Riders]   1 ──── 0..N  [Trips]  1 ──── 0..1 [Ratings]
```

---

## 2. In-Depth Relationship Specifications

### Relationship 1: Driver to Vehicle (`FK_Drivers_Vehicles`)
- **Parent:** `dbo.Vehicles (VehicleID)`
- **Child:** `dbo.Drivers (VehicleID)`
- **Cardinality:** $1 : 0..1$ (One-to-One Optional)
- **Referential Action:** `ON DELETE SET NULL`, `ON UPDATE CASCADE`
- **Integrity Enforcement:** `UQ_Drivers_VehicleID`
- **Business Rationale:** A driver may register and undergo identity checks before their vehicle is inspected and assigned (`VehicleID` is nullable). However, once a vehicle is assigned, the `UNIQUE` constraint guarantees that no other driver can be assigned to the same vehicle. If a vehicle record is decommissioned (`DELETE`), the driver's vehicle reference is safely set to `NULL` rather than deleting the driver profile.

---

### Relationship 2: Rider to Trip (`FK_Trips_Riders`)
- **Parent:** `dbo.Riders (RiderID)`
- **Child:** `dbo.Trips (RiderID)`
- **Cardinality:** $1 : 0..N$ (One-to-Many)
- **Referential Action:** `ON DELETE NO ACTION`, `ON UPDATE CASCADE`
- **Business Rationale:** A customer account can book many trips over time. Deleting a rider account while active trip records exist is blocked (`NO ACTION`) to preserve historical accounting and audit compliance.

---

### Relationship 3: Driver to Trip (`FK_Trips_Drivers`)
- **Parent:** `dbo.Drivers (DriverID)`
- **Child:** `dbo.Trips (DriverID)`
- **Cardinality:** $1 : 0..N$ (One-to-Many)
- **Referential Action:** `ON DELETE NO ACTION`, `ON UPDATE CASCADE`
- **Business Rationale:** A driver fulfills many trips throughout their service tenure. When a trip is initially requested (`Status = 'REQUESTED'`), `DriverID` is `NULL`. Upon atomic dispatch matching, `DriverID` is populated. `ON DELETE NO ACTION` protects trip financial records if a driver leaves the platform.

---

### Relationship 4: Driver to LocationPing (`FK_LocationPings_Drivers`)
- **Parent:** `dbo.Drivers (DriverID)`
- **Child:** `dbo.LocationPings (DriverID)`
- **Cardinality:** $1 : 0..N$ (One-to-Many)
- **Referential Action:** `ON DELETE CASCADE`, `ON UPDATE CASCADE`
- **Business Rationale:** A driver emits continuous telemetry pings every 2–3 seconds while active. Because location pings are ephemeral operational breadcrumbs belonging strictly to the driver, if a driver test account is deleted in development, all associated pings cascade-delete cleanly (`CASCADE`).

---

### Relationship 5: Trip to Rating (`FK_Ratings_Trips`)
- **Parent:** `dbo.Trips (TripID)`
- **Child:** `dbo.Ratings (TripID)`
- **Cardinality:** $1 : 0..1$ (One-to-One Optional)
- **Referential Action:** `ON DELETE CASCADE`, `ON UPDATE CASCADE`
- **Integrity Enforcement:** `UQ_Ratings_TripID`
- **Business Rationale:** A trip receives at most one rating from the rider upon completion (or zero if the rider skips the review). The `UNIQUE` constraint on `TripID` in `dbo.Ratings` guarantees that duplicate reviews cannot be submitted for the same ride.
