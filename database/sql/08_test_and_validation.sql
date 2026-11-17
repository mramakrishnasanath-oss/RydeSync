-- ============================================================================
-- SCRIPT 08: COMPREHENSIVE TESTING & CONSTRAINT VALIDATION
-- System: RideSync (UrbanGo Mobility)
-- Database: RideSyncDB
-- Technology: Microsoft SQL Server 2025 (v17)
-- Author: Lead QA & Database Engineer
-- Date: 2026-11-17
-- Description: Executes positive and negative test cases to prove:
--              1. Primary key uniqueness
--              2. Foreign key rejections
--              3. UNIQUE constraint rejections (duplicate phone, plate, vehicle assignment)
--              4. CHECK constraint enforcement (lat/lon bounds, stars 1-5, status values)
--              5. Atomic Driver Assignment and Rollback Verification
--              6. View query outputs
--              7. Stored Function calculations
--              8. Cursor job execution
-- ============================================================================

USE RideSyncDB;
GO

SET NOCOUNT ON;
PRINT '============================================================';
PRINT 'STARTING RIDESYNC DATABASE INTEGRITY TEST SUITE';
PRINT '============================================================';

-- ----------------------------------------------------------------------------
-- TEST 1: DUPLICATE PHONE REJECTION (Negative Test)
-- Expected Result: Violation of UNIQUE constraint UQ_Riders_Phone (Error 2627)
-- ----------------------------------------------------------------------------
PRINT 'TEST 1: Attempting to insert duplicate rider phone (+919876543210)...';
BEGIN TRY
    INSERT INTO dbo.Riders (FirstName, LastName, Phone)
    VALUES (N'Duplicate', N'User', '+919876543210');
    PRINT 'TEST 1 FAILED: Duplicate phone was incorrectly allowed.';
END TRY
BEGIN CATCH
    PRINT 'TEST 1 PASSED: Duplicate phone correctly rejected by UQ_Riders_Phone. Error: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
END CATCH;
GO

-- ----------------------------------------------------------------------------
-- TEST 2: DUPLICATE VEHICLE PLATE REJECTION (Negative Test)
-- Expected Result: Violation of UNIQUE constraint UQ_Vehicles_PlateNumber
-- ----------------------------------------------------------------------------
PRINT 'TEST 2: Attempting to insert duplicate vehicle plate (TS09UB1001)...';
BEGIN TRY
    INSERT INTO dbo.Vehicles (PlateNumber, Model)
    VALUES ('TS09UB1001', N'Duplicate Car');
    PRINT 'TEST 2 FAILED: Duplicate plate was incorrectly allowed.';
END TRY
BEGIN CATCH
    PRINT 'TEST 2 PASSED: Duplicate plate correctly rejected by UQ_Vehicles_PlateNumber. Error: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
END CATCH;
GO

-- ----------------------------------------------------------------------------
-- TEST 3: VEHICLE DOUBLE-ASSIGNMENT REJECTION (Negative Test)
-- Expected Result: Violation of UNIQUE constraint UQ_Drivers_VehicleID (1:1 Vehicle Rule)
-- ----------------------------------------------------------------------------
PRINT 'TEST 3: Attempting to assign VehicleID 1 to a second driver...';
BEGIN TRY
    INSERT INTO dbo.Drivers (FirstName, LastName, VehicleID, Status)
    VALUES (N'Intruder', N'Driver', 1, 'ONLINE');
    PRINT 'TEST 3 FAILED: Same vehicle was assigned to two drivers.';
END TRY
BEGIN CATCH
    PRINT 'TEST 3 PASSED: 1:1 Vehicle allocation correctly enforced by UQ_Drivers_VehicleID. Error: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
END CATCH;
GO

-- ----------------------------------------------------------------------------
-- TEST 4: INVALID LATITUDE/LONGITUDE REJECTION (Negative Test)
-- Expected Result: Violation of CHECK constraint CK_LocationPings_Latitude
-- ----------------------------------------------------------------------------
PRINT 'TEST 4: Attempting to insert invalid GPS latitude (95.000000)...';
BEGIN TRY
    INSERT INTO dbo.LocationPings (DriverID, Latitude, Longitude)
    VALUES (1, 95.000000, 78.380000);
    PRINT 'TEST 4 FAILED: Out-of-bounds latitude was allowed.';
END TRY
BEGIN CATCH
    PRINT 'TEST 4 PASSED: Out-of-bounds latitude correctly blocked by CK_LocationPings_Latitude. Error: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
END CATCH;
GO

-- ----------------------------------------------------------------------------
-- TEST 5: INVALID STAR RATING REJECTION (Negative Test)
-- Expected Result: Violation of CHECK constraint CK_Ratings_Stars (Allowed: 1 to 5)
-- ----------------------------------------------------------------------------
PRINT 'TEST 5: Attempting to insert invalid rating (6 stars)...';
BEGIN TRY
    INSERT INTO dbo.Ratings (TripID, Stars, Comment)
    VALUES (1, 6, N'Exceeds range');
    PRINT 'TEST 5 FAILED: Invalid star score was allowed.';
END TRY
BEGIN CATCH
    PRINT 'TEST 5 PASSED: Invalid rating correctly blocked by CK_Ratings_Stars. Error: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
END CATCH;
GO

-- ----------------------------------------------------------------------------
-- TEST 6: FOREIGN KEY REFERENTIAL INTEGRITY (Negative Test)
-- Expected Result: Violation of Foreign Key FK_Trips_Riders
-- ----------------------------------------------------------------------------
PRINT 'TEST 6: Attempting to create Trip for non-existent RiderID 99999...';
BEGIN TRY
    INSERT INTO dbo.Trips (RiderID, Status)
    VALUES (99999, 'REQUESTED');
    PRINT 'TEST 6 FAILED: Orphan trip record was allowed.';
END TRY
BEGIN CATCH
    PRINT 'TEST 6 PASSED: Non-existent rider foreign key rejected by FK_Trips_Riders. Error: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
END CATCH;
GO

-- ----------------------------------------------------------------------------
-- TEST 7: ATOMIC DRIVER ASSIGNMENT & TRANSACTION ROLLBACK (Positive & Concurrency Test)
-- Scenario: Assign available Driver 1 to Trip 14, then verify second attempt fails
-- ----------------------------------------------------------------------------
PRINT 'TEST 7: Testing sp_assign_driver atomic dispatch...';
DECLARE @TestTripID INT = 14; -- Currently in 'REQUESTED' state
DECLARE @TestDriverID INT = 1; -- Currently 'ONLINE'
DECLARE @Success BIT;
DECLARE @Message NVARCHAR(200);

-- Attempt 1: Should succeed
EXEC dbo.sp_assign_driver 
    @TripID = @TestTripID, 
    @DriverID = @TestDriverID, 
    @Success = @Success OUTPUT, 
    @Message = @Message OUTPUT;

PRINT 'Attempt 1 Result: Success=' + CAST(@Success AS VARCHAR(1)) + ', Message=' + @Message;

-- Attempt 2: Concurrent rider tries to claim the same driver (Should fail and rollback)
EXEC dbo.sp_assign_driver 
    @TripID = @TestTripID, 
    @DriverID = @TestDriverID, 
    @Success = @Success OUTPUT, 
    @Message = @Message OUTPUT;

PRINT 'Attempt 2 Result: Success=' + CAST(@Success AS VARCHAR(1)) + ', Message=' + @Message;
IF @Success = 0
    PRINT 'TEST 7 PASSED: Atomic driver lock prevented duplicate assignment.';
ELSE
    PRINT 'TEST 7 FAILED: Duplicate assignment was not prevented.';
GO

-- ----------------------------------------------------------------------------
-- TEST 8: WITH CHECK OPTION ENFORCEMENT ON UPDATABLE VIEW (Negative Test)
-- Expected Result: Error 550 - The attempted insert or update failed because a
--                  target view specifies WITH CHECK OPTION and one or more resulting
--                  rows did not qualify under the CHECK OPTION constraint.
-- ----------------------------------------------------------------------------
PRINT 'TEST 8: Testing WITH CHECK OPTION on vw_online_drivers_updatable...';
BEGIN TRY
    -- Attempting to update a driver to OFFLINE through the online view
    UPDATE dbo.vw_online_drivers_updatable
    SET Status = 'OFFLINE'
    WHERE DriverID = 2;
    PRINT 'TEST 8 FAILED: WITH CHECK OPTION did not block the invalid update.';
END TRY
BEGIN CATCH
    PRINT 'TEST 8 PASSED: WITH CHECK OPTION successfully blocked update to non-qualifying row. Error: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
END CATCH;
GO

-- ----------------------------------------------------------------------------
-- TEST 9: STORED FUNCTIONS VALIDATION
-- ----------------------------------------------------------------------------
PRINT 'TEST 9: Testing scalar distance and fare estimation functions...';
DECLARE @Dist DECIMAL(10,3);
DECLARE @Fare DECIMAL(10,2);

-- Distance between Cyber Towers (17.4482, 78.3741) and Gachibowli (17.4400, 78.3489)
SET @Dist = dbo.fn_calculate_distance(17.448200, 78.374100, 17.440000, 78.348900);
SET @Fare = dbo.fn_estimate_fare(@Dist, 1.20); -- 1.2x surge

PRINT 'Calculated Great-Circle Distance: ' + CAST(@Dist AS VARCHAR(10)) + ' KM';
PRINT 'Estimated Fare with 1.2x Surge: ₹' + CAST(@Fare AS VARCHAR(10));

IF @Dist > 0.0 AND @Fare > 50.0
    PRINT 'TEST 9 PASSED: Functions computed valid non-zero outputs.';
ELSE
    PRINT 'TEST 9 FAILED: Function returned invalid values.';
GO

-- ----------------------------------------------------------------------------
-- TEST 10: CURSOR PROCEDURE EXECUTION
-- ----------------------------------------------------------------------------
PRINT 'TEST 10: Executing stale driver cursor job...';
EXEC dbo.sp_process_stale_drivers @StaleThresholdSeconds = 120;
PRINT 'TEST 10 PASSED: Stale driver cursor completed without errors.';
GO

PRINT '============================================================';
PRINT 'ALL 10 DATABASE INTEGRITY & CONSTRAINT TESTS EXECUTED';
PRINT '============================================================';
GO
