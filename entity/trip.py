"""
RideSync - Trip Entity Model
Domain Layer: entity/trip.py
Represents a ride contract between a rider and an allocated driver partner.
"""
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

ALLOWED_TRIP_STATUSES = {"REQUESTED", "MATCHED", "IN_PROGRESS", "COMPLETED", "CANCELLED"}


@dataclass
class Trip:
    """
    Trip Domain Entity
    Corresponds to SQL Server table dbo.Trips
    """
    trip_id: Optional[int]
    rider_id: int
    driver_id: Optional[int] = None
    requested_at: Optional[datetime] = None
    matched_at: Optional[datetime] = None
    status: str = "REQUESTED"
    fare: Optional[float] = None
    pickup_lat: Optional[float] = None
    pickup_lon: Optional[float] = None
    drop_lat: Optional[float] = None
    drop_lon: Optional[float] = None

    def __post_init__(self):
        self.status = self.status.strip().upper()
        if self.status not in ALLOWED_TRIP_STATUSES:
            raise ValueError(f"Invalid Trip status: {self.status}. Must be one of {ALLOWED_TRIP_STATUSES}")
        if self.fare is not None and self.fare < 0.0:
            raise ValueError("Fare cannot be negative.")

    def is_active(self) -> bool:
        """Determines if the trip is currently undergoing dispatch or transit."""
        return self.status in {"REQUESTED", "MATCHED", "IN_PROGRESS"}

    def __repr__(self) -> str:
        return f"<Trip ID={self.trip_id} RiderID={self.rider_id} DriverID={self.driver_id} Status='{self.status}' Fare={self.fare}>"
