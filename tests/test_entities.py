"""
RideSync - Unit Tests for Domain Entities
Tests Layer: tests/test_entities.py
Verifies domain validation rules, properties, and constraints independently of DB.
Uses standard library unittest for zero-dependency execution.
"""
import unittest
from entity.rider import Rider
from entity.driver import Driver
from entity.vehicle import Vehicle
from entity.location_ping import LocationPing
from entity.trip import Trip
from entity.rating import Rating


class TestDomainEntities(unittest.TestCase):

    def test_rider_valid(self):
        rider = Rider(rider_id=1, first_name="Aarav", last_name="Sharma", phone="+919876543210")
        self.assertEqual(rider.full_name, "Aarav Sharma")
        self.assertEqual(rider.phone, "+919876543210")

    def test_rider_invalid_phone(self):
        with self.assertRaises(ValueError):
            Rider(rider_id=1, first_name="Aarav", last_name="Sharma", phone="12345")

    def test_vehicle_valid(self):
        v = Vehicle(vehicle_id=1, plate_number="ts09ub1001", model="Dzire")
        self.assertEqual(v.plate_number, "TS09UB1001")  # Automatically uppercase

    def test_driver_availability(self):
        d = Driver(driver_id=1, first_name="Rajesh", last_name="Kumar", vehicle_id=1, status="ONLINE")
        self.assertTrue(d.is_available())

        d.status = "ON_TRIP"
        self.assertFalse(d.is_available())

        d.status = "OFFLINE"
        self.assertFalse(d.is_available())

    def test_driver_invalid_status(self):
        with self.assertRaises(ValueError):
            Driver(driver_id=1, first_name="Rajesh", last_name="Kumar", status="FLYING")

    def test_location_ping_bounds(self):
        # Valid ping
        p = LocationPing(ping_id=1, driver_id=1, latitude=17.4482, longitude=78.3741)
        self.assertEqual(p.driver_id, 1)

        # Invalid latitude
        with self.assertRaises(ValueError):
            LocationPing(ping_id=2, driver_id=1, latitude=95.0, longitude=78.3741)

        # Invalid longitude
        with self.assertRaises(ValueError):
            LocationPing(ping_id=3, driver_id=1, latitude=17.4482, longitude=190.0)

    def test_rating_bounds(self):
        # Valid rating
        r = Rating(rating_id=1, trip_id=1, stars=5, comment="Great ride")
        self.assertEqual(r.stars, 5)

        # Invalid rating (> 5)
        with self.assertRaises(ValueError):
            Rating(rating_id=2, trip_id=1, stars=6)

        # Invalid rating (< 1)
        with self.assertRaises(ValueError):
            Rating(rating_id=3, trip_id=1, stars=0)


if __name__ == "__main__":
    unittest.main()
