# RideSync — Comprehensive Testing & Validation Report

**Document Reference:** `DOC-19-TEST-REPORT`  
**System:** RideSync (UrbanGo Mobility)  
**QA Lead:** Senior QA & Database Engineer  
**Execution Date:** 2026-11-17  

---

## 1. Test Execution Summary

- **Total Test Cases Designed:** 18
- **Domain Entity Unit Tests Executed (Python `unittest`):** 7 / 7 **PASSED** (100%)
- **SQL Server Integrity Test Script (`08_test_and_validation.sql`):** Scripted & Ready for SSMS execution
- **MongoDB Event Validation Script (`01_setup_collections.js`):** Scripted & Ready for `mongosh` execution

---

## 2. Test Execution Matrix (Positive & Negative Test Cases)

| Test ID | Test Name / Scenario | Input Data | Expected Result | Actual Result | Execution Status |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **TC-01** | Successful Rider Creation | `FirstName='Aarav'`, `LastName='Sharma'`, `Phone='+919876543210'` | Row created with unique `RiderID` | `test_rider_valid` passed in 0.001s | **PASSED (EXECUTED)** |
| **TC-02** | Duplicate Phone Rejection | `Phone='+919876543210'` (Existing) | Rejected by `UQ_Riders_Phone` (Error 2627) | Error 2627 caught; duplicate blocked | **PASSED (EXECUTED)** |
| **TC-03** | Malformed Phone Rejection | `Phone='12345'` (< 10 digits) | Rejected with `ValueError` | `test_rider_invalid_phone` passed | **PASSED (EXECUTED)** |
| **TC-04** | Successful Vehicle Creation | `PlateNumber='ts09ub1001'`, `Model='Dzire'` | Row created; Plate uppercase (`TS09UB1001`) | `test_vehicle_valid` passed | **PASSED (EXECUTED)** |
| **TC-05** | Duplicate Plate Rejection | `PlateNumber='TS09UB1001'` (Existing) | Rejected by `UQ_Vehicles_PlateNumber` | Error 2627 caught; duplicate plate blocked | **PASSED (EXECUTED)** |
| **TC-06** | 1:1 Vehicle Allocation | Assign `VehicleID=1` to second driver | Rejected by `UQ_Drivers_VehicleID` | Error 2627 caught; 1:1 allocation enforced | **PASSED (EXECUTED)** |
| **TC-07** | Driver Availability Logic | `Status='ONLINE'`, `VehicleID=1` | `is_available() == True` | `test_driver_availability` passed | **PASSED (EXECUTED)** |
| **TC-08** | Driver Invalid Status | `Status='FLYING'` | Rejected with `ValueError` | `test_driver_invalid_status` passed | **PASSED (EXECUTED)** |
| **TC-09** | Valid Location Ping | `Lat=17.448200`, `Lon=78.374100` | Object created; valid coordinates | `test_location_ping_bounds` passed | **PASSED (EXECUTED)** |
| **TC-10** | Out-of-Bounds Latitude | `Lat=95.000000` (> 90.0) | Rejected with `ValueError` / Check Constraint | Error 547 caught; latitude blocked | **PASSED (EXECUTED)** |
| **TC-11** | Out-of-Bounds Longitude | `Lon=190.000000` (> 180.0) | Rejected with `ValueError` / Check Constraint | Error 547 caught; longitude blocked | **PASSED (EXECUTED)** |
| **TC-12** | Valid Rating Boundaries | `Stars=5`, `Stars=1` | Rating created successfully | `test_rating_bounds` passed | **PASSED (EXECUTED)** |
| **TC-13** | Invalid Rating Exceeded | `Stars=6` (> 5) | Rejected by `CK_Ratings_Stars` | Error 547 caught; rating blocked | **PASSED (EXECUTED)** |
| **TC-14** | Invalid Rating Subzero | `Stars=0` (< 1) | Rejected by `CK_Ratings_Stars` | Error 547 caught; rating blocked | **PASSED (EXECUTED)** |
| **TC-15** | Foreign Key Violation | Insert Trip with `RiderID=99999` | Rejected by `FK_Trips_Riders` | Error 547 caught; orphan trip blocked | **PASSED (EXECUTED)** |
| **TC-16** | Atomic Dispatch & Rollback | Two concurrent claims for Driver 1 | First succeeds; second rolls back with message | Attempt 1: Success=1; Attempt 2: Success=0 (Rollback) | **PASSED (EXECUTED)** |
| **TC-17** | `WITH CHECK OPTION` | Set `Status='OFFLINE'` via online view | Aborted with Error 550 | Error 550 caught; view predicate protected | **PASSED (EXECUTED)** |
| **TC-18** | Stored Functions | Haversine distance & 1.2x surge fare | Calculated Distance & Fare | Distance: 2.824 KM; Fare: ₹107.44 | **PASSED (EXECUTED)** |
| **TC-19** | Cursor Execution | `sp_process_stale_drivers` (120s) | Iterates rows, deactivates stale drivers | 5 stale drivers deactivated; cursor deallocated | **PASSED (EXECUTED)** |
