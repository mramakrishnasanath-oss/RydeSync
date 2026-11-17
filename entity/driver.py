"""
RideSync - Driver Entity Model
Domain Layer: entity/driver.py
Represents a licensed driver partner in UrbanGo Mobility.
"""
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

ALLOWED_DRIVER_STATUSES = {"OFFLINE", "ONLINE", "ON_TRIP", "SUSPENDED"}


@dataclass
class Driver:
    """
    Driver Domain Entity
    Corresponds to SQL Server table dbo.Drivers
    """
    driver_id: Optional[int]
    first_name: str
    last_name: str
    vehicle_id: Optional[int] = None
    status: str = "OFFLINE"
    registered_at: Optional[datetime] = None

    def __post_init__(self):
        if not self.first_name or not self.first_name.strip():
            raise ValueError("Driver first_name cannot be empty.")
        if not self.last_name or not self.last_name.strip():
            raise ValueError("Driver last_name cannot be empty.")
        self.status = self.status.strip().upper()
        if self.status not in ALLOWED_DRIVER_STATUSES:
            raise ValueError(f"Invalid Driver status: {self.status}. Must be one of {ALLOWED_DRIVER_STATUSES}")

    @property
    def full_name(self) -> str:
        """Returns the full name of the driver."""
        return f"{self.first_name.strip()} {self.last_name.strip()}"

    def is_available(self) -> bool:
        """Checks if driver is ready to be dispatched."""
        return self.status == "ONLINE" and self.vehicle_id is not None

    def __repr__(self) -> str:
        return f"<Driver ID={self.driver_id} Name='{self.full_name}' VehicleID={self.vehicle_id} Status='{self.status}'>"
