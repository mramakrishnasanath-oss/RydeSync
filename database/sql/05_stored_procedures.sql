-- ============================================================================
-- SCRIPT 05: DAY 9 STORED PROCEDURES (TRANSACTIONAL & ATOMIC DISPATCH)
-- System: RideSync (UrbanGo Mobility)
-- Database: RideSyncDB
-- Technology: Microsoft SQL Server 2025 (v17)
-- Author: Senior Database Architect
-- Date: 2026-11-17
-- Description: Implements Day 9 Stored Procedures with:
--              - Input (IN) & Output (OUT) parameters
--              - Strict input validation
--              - Atomic Driver Assignment with concurrency locks (UPDLOCK, HOLDLOCK)
--              - ACID Transaction Control (BEGIN TRAN, COMMIT, ROLLBACK)
--              - Structured Error Handling (TRY...CATCH, THROW)
-- ============================================================================

USE RideSyncDB;
GO

-- ============================================================================
-- PROCEDURE 1: sp_register_rider
-- Description: Onboards a new passenger account with unique phone verification.
-- Demonstrates: IN parameters, OUTPUT parameter, error handling.
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_register_rider
    @FirstName      NVARCHAR(50),
    @LastName       NVARCHAR(50),
    @Phone          VARCHAR(15),
    @NewRiderID     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Parameter validation
        IF @FirstName IS NULL OR LTRIM(RTRIM(@FirstName)) = ''
            THROW 50001, 'FirstName cannot be null or empty.', 1;

        IF @LastName IS NULL OR LTRIM(RTRIM(@LastName)) = ''
            THROW 50002, 'LastName cannot be null or empty.', 1;

        IF @Phone IS NULL OR LEN(@Phone) < 10
            THROW 50003, 'Phone number must be at least 10 digits.', 1;

        -- Check duplicate phone
        IF EXISTS (SELECT 1 FROM dbo.Riders WHERE Phone = @Phone)
            THROW 50004, 'A rider with this phone number already exists.', 1;

        -- Insert record
        INSERT INTO dbo.Riders (FirstName, LastName, Phone, CreatedAt)
        VALUES (LTRIM(RTRIM(@FirstName)), LTRIM(RTRIM(@LastName)), @Phone, SYSUTCDATETIME());

        SET @NewRiderID = SCOPE_IDENTITY();
        PRINT 'Rider registered successfully with RiderID: ' + CAST(@NewRiderID AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
    END CATCH
END;
GO

PRINT 'Created procedure: dbo.sp_register_rider';
GO

-- ============================================================================
-- PROCEDURE 2: sp_register_driver
-- Description: Onboards a driver and optionally associates a verified vehicle.
-- Demonstrates: Foreign key integrity check, UNIQUE vehicle check, OUTPUT param.
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_register_driver
    @FirstName      NVARCHAR(50),
    @LastName       NVARCHAR(50),
    @VehicleID      INT = NULL,
    @NewDriverID    INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Validation
        IF @FirstName IS NULL OR LTRIM(RTRIM(@FirstName)) = ''
            THROW 50010, 'FirstName cannot be empty.', 1;

        IF @LastName IS NULL OR LTRIM(RTRIM(@LastName)) = ''
            THROW 50011, 'LastName cannot be empty.', 1;

        -- If vehicle is provided, verify it exists and is unassigned
        IF @VehicleID IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.Vehicles WHERE VehicleID = @VehicleID)
                THROW 50012, 'Specified VehicleID does not exist.', 1;

            IF EXISTS (SELECT 1 FROM dbo.Drivers WHERE VehicleID = @VehicleID)
                THROW 50013, 'Vehicle is already assigned to another driver (1:1 allocation rule).', 1;
        END

        INSERT INTO dbo.Drivers (FirstName, LastName, VehicleID, Status, RegisteredAt)
        VALUES (LTRIM(RTRIM(@FirstName)), LTRIM(RTRIM(@LastName)), @VehicleID, 'OFFLINE', SYSUTCDATETIME());

        SET @NewDriverID = SCOPE_IDENTITY();
        PRINT 'Driver registered successfully with DriverID: ' + CAST(@NewDriverID AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

PRINT 'Created procedure: dbo.sp_register_driver';
GO

-- ============================================================================
-- PROCEDURE 3: sp_update_driver_status
-- Description: Toggles driver operational state between OFFLINE, ONLINE, SUSPENDED.
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_update_driver_status
    @DriverID       INT,
    @NewStatus      VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Drivers WHERE DriverID = @DriverID)
            THROW 50020, 'Driver not found.', 1;

        IF @NewStatus NOT IN ('OFFLINE', 'ONLINE', 'ON_TRIP', 'SUSPENDED')
            THROW 50021, 'Invalid status value. Allowed: OFFLINE, ONLINE, ON_TRIP, SUSPENDED.', 1;

        -- Cannot go ONLINE without an assigned vehicle
        IF @NewStatus = 'ONLINE'
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.Drivers WHERE DriverID = @DriverID AND VehicleID IS NULL)
                THROW 50022, 'Cannot go ONLINE without an assigned vehicle.', 1;
        END

        UPDATE dbo.Drivers
        SET Status = @NewStatus
        WHERE DriverID = @DriverID;

        PRINT 'Driver ' + CAST(@DriverID AS VARCHAR(10)) + ' status updated to ' + @NewStatus;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

PRINT 'Created procedure: dbo.sp_update_driver_status';
GO

-- ============================================================================
-- PROCEDURE 4: sp_request_ride
-- Description: Rider initiates a point-to-point booking request.
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_request_ride
    @RiderID        INT,
    @PickupLat      DECIMAL(9,6),
    @PickupLon      DECIMAL(9,6),
    @DropLat        DECIMAL(9,6),
    @DropLon        DECIMAL(9,6),
    @NewTripID      INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verify rider exists
        IF NOT EXISTS (SELECT 1 FROM dbo.Riders WHERE RiderID = @RiderID)
            THROW 50030, 'Rider does not exist.', 1;

        -- Verify rider does not have an unresolved active trip
        IF EXISTS (SELECT 1 FROM dbo.Trips WHERE RiderID = @RiderID AND Status IN ('REQUESTED', 'MATCHED', 'IN_PROGRESS'))
            THROW 50031, 'Rider already has an active or pending trip.', 1;

        INSERT INTO dbo.Trips (RiderID, DriverID, RequestedAt, Status, PickupLat, PickupLon, DropLat, DropLon)
        VALUES (@RiderID, NULL, SYSUTCDATETIME(), 'REQUESTED', @PickupLat, @PickupLon, @DropLat, @DropLon);

        SET @NewTripID = SCOPE_IDENTITY();
        PRINT 'Ride requested successfully. TripID: ' + CAST(@NewTripID AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

PRINT 'Created procedure: dbo.sp_request_ride';
GO

-- ============================================================================
-- PROCEDURE 5: sp_assign_driver (HIGHEST PRIORITY: ATOMIC DRIVER DISPATCH)
-- Description: Atomically assigns a selected online driver to a pending ride.
-- ACID Enforced: Uses UPDLOCK and HOLDLOCK to eliminate race conditions,
--                ensuring that two concurrent riders NEVER claim the same driver.
-- Outputs: @Success (1/0), @Message (Human-readable diagnostic string).
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_assign_driver
    @TripID         INT,
    @DriverID       INT,
    @Success        BIT OUTPUT,
    @Message        NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- Automatically rollback on serious runtime errors

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Acquire exclusive update lock on the Trip and verify it is still in REQUESTED status
        DECLARE @CurrentTripStatus VARCHAR(20);
        SELECT @CurrentTripStatus = Status 
        FROM dbo.Trips WITH (UPDLOCK, HOLDLOCK)
        WHERE TripID = @TripID;

        IF @CurrentTripStatus IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Success = 0;
            SET @Message = 'TripID ' + CAST(@TripID AS NVARCHAR(10)) + ' does not exist.';
            RETURN;
        END

        IF @CurrentTripStatus <> 'REQUESTED'
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Success = 0;
            SET @Message = 'Trip is no longer in REQUESTED status (Current: ' + @CurrentTripStatus + ').';
            RETURN;
        END

        -- 2. Acquire exclusive update lock on Driver and verify driver is still ONLINE
        DECLARE @CurrentDriverStatus VARCHAR(20);
        SELECT @CurrentDriverStatus = Status
        FROM dbo.Drivers WITH (UPDLOCK, HOLDLOCK)
        WHERE DriverID = @DriverID;

        IF @CurrentDriverStatus IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Success = 0;
            SET @Message = 'DriverID ' + CAST(@DriverID AS NVARCHAR(10)) + ' does not exist.';
            RETURN;
        END

        IF @CurrentDriverStatus <> 'ONLINE'
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Success = 0;
            SET @Message = 'Driver is no longer ONLINE (Current: ' + @CurrentDriverStatus + '). Already claimed.';
            RETURN;
        END

        -- 3. Atomic Assignment: Update Driver to 'ON_TRIP' and Trip to 'MATCHED'
        UPDATE dbo.Drivers
        SET Status = 'ON_TRIP'
        WHERE DriverID = @DriverID;

        UPDATE dbo.Trips
        SET DriverID = @DriverID,
            MatchedAt = SYSUTCDATETIME(),
            Status = 'MATCHED'
        WHERE TripID = @TripID;

        -- 4. Commit atomic operation
        COMMIT TRANSACTION;
        SET @Success = 1;
        SET @Message = 'Driver ' + CAST(@DriverID AS NVARCHAR(10)) + ' atomically claimed and assigned to Trip ' + CAST(@TripID AS NVARCHAR(10)) + '.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Success = 0;
        SET @Message = 'Atomic dispatch failed: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

PRINT 'Created procedure: dbo.sp_assign_driver (Atomic Transactional Dispatch)';
GO

-- ============================================================================
-- PROCEDURE 6: sp_complete_trip
-- Description: Concludes a ride, records calculated fare, and returns driver to ONLINE.
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_complete_trip
    @TripID         INT,
    @Fare           DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @DriverID INT;
        DECLARE @TripStatus VARCHAR(20);

        SELECT @DriverID = DriverID, @TripStatus = Status
        FROM dbo.Trips WITH (UPDLOCK, HOLDLOCK)
        WHERE TripID = @TripID;

        IF @TripStatus IS NULL
            THROW 50040, 'Trip not found.', 1;

        IF @TripStatus NOT IN ('MATCHED', 'IN_PROGRESS')
            THROW 50041, 'Trip is not in an active state to complete.', 1;

        IF @Fare < 0.00
            THROW 50042, 'Fare cannot be negative.', 1;

        -- Update trip to COMPLETED with final fare
        UPDATE dbo.Trips
        SET Status = 'COMPLETED',
            Fare = @Fare
        WHERE TripID = @TripID;

        -- Return driver to ONLINE state
        IF @DriverID IS NOT NULL
        BEGIN
            UPDATE dbo.Drivers
            SET Status = 'ONLINE'
            WHERE DriverID = @DriverID;
        END

        COMMIT TRANSACTION;
        PRINT 'Trip ' + CAST(@TripID AS VARCHAR(10)) + ' completed. Driver ' + CAST(@DriverID AS VARCHAR(10)) + ' released to ONLINE.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

PRINT 'Created procedure: dbo.sp_complete_trip';
GO

PRINT 'All Day 9 Stored Procedures created successfully.';
GO
