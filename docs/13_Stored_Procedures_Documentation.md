# RideSync — Day 9 Stored Procedures Documentation

**Document Reference:** `DOC-13-PROCEDURES`  
**Database:** `RideSyncDB`  
**Day 9 Topic:** Stored Procedures, IN/OUT Parameters, Concurrency Control, Transactions  

---

## 1. Catalog of Stored Procedures

| Procedure Name | Key Feature | Transactional? | Concurrency Control | Business Value |
| :--- | :--- | :---: | :---: | :--- |
| `sp_register_rider` | Input validation, `OUTPUT` param | No | Standard Insert | Onboards new rider with duplicate check. |
| `sp_register_driver`| 1:1 Vehicle check, `OUTPUT` param| No | Standard Insert | Onboards driver partner safely. |
| `sp_update_driver_status` | Status domain validation | No | Single Update | Toggles driver availability state. |
| `sp_request_ride` | Active booking verification | No | Single Insert | Creates new ride contract (`REQUESTED`). |
| **`sp_assign_driver`** | **Atomic Claim, Concurrency Locks** | **YES** | **`UPDLOCK, HOLDLOCK`** | **Eliminates double driver assignments.** |
| `sp_complete_trip` | Multi-table state transition | **YES** | **`UPDLOCK`** | Records fare, marks trip completed, releases driver. |

---

## 2. Deep Dive: `sp_assign_driver` (Atomic Concurrency Protection)

### The Business Vulnerability
In a high-concurrency ride-hailing system, two passengers requesting a ride at the same split-second might have their requests routed to the same nearest driver. Without atomic locking, both requests read the driver as `ONLINE`, assign their trip to that driver, and set the driver to `ON_TRIP`. This causes an operational catastrophe: two riders waiting for the same physical vehicle.

### The RideSync Technical Solution
```sql
CREATE OR ALTER PROCEDURE dbo.sp_assign_driver
    @TripID INT,
    @DriverID INT,
    @Success BIT OUTPUT,
    @Message NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Exclusive lock on Trip
        DECLARE @CurrentTripStatus VARCHAR(20);
        SELECT @CurrentTripStatus = Status 
        FROM dbo.Trips WITH (UPDLOCK, HOLDLOCK)
        WHERE TripID = @TripID;

        IF @CurrentTripStatus <> 'REQUESTED'
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Success = 0;
            SET @Message = 'Trip is no longer in REQUESTED status.';
            RETURN;
        END

        -- 2. Exclusive lock on Driver
        DECLARE @CurrentDriverStatus VARCHAR(20);
        SELECT @CurrentDriverStatus = Status
        FROM dbo.Drivers WITH (UPDLOCK, HOLDLOCK)
        WHERE DriverID = @DriverID;

        IF @CurrentDriverStatus <> 'ONLINE'
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Success = 0;
            SET @Message = 'Driver is no longer ONLINE (Already claimed).';
            RETURN;
        END

        -- 3. Atomic Assignment
        UPDATE dbo.Drivers SET Status = 'ON_TRIP' WHERE DriverID = @DriverID;
        UPDATE dbo.Trips SET DriverID = @DriverID, MatchedAt = SYSUTCDATETIME(), Status = 'MATCHED' WHERE TripID = @TripID;

        COMMIT TRANSACTION;
        SET @Success = 1;
        SET @Message = 'Driver assigned successfully.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Success = 0;
        SET @Message = 'Dispatch failed: ' + ERROR_MESSAGE();
    END CATCH
END;
```

### Concurrency Mechanism Explained:
1. `UPDLOCK`: Forces SQL Server to place an update lock during the initial `SELECT`, preventing any competing transaction from obtaining an update lock on the same row.
2. `HOLDLOCK`: Holds the lock for the entire duration of the transaction until `COMMIT` or `ROLLBACK` executes (serializable isolation).
3. `XACT_ABORT ON`: Guarantees that if a severe client disconnect occurs, the engine rolls back the transaction immediately without leaving orphan locks.
