"""
RideSync - LocationPing Entity Model
Domain Layer: entity/location_ping.py
Represents high-frequency GPS telemetry emitted by an active driver.
"""
from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class LocationPing:
    """
    LocationPing Domain Entity
    Corresponds to SQL Server table dbo.LocationPings
    """
    ping_id: Optional[int]
    driver_id: int
    latitude: float
    longitude: float
    recorded_at: Optional[datetime] = None

    def __post_init__(self):
        if not (-90.0 <= self.latitude <= 90.0):
            raise ValueError(f"Latitude {self.latitude} is out of bounds (-90.0 to 90.0).")
        if not (-180.0 <= self.longitude <= 180.0):
            raise ValueError(f"Longitude {self.longitude} is out of bounds (-180.0 to 180.0).")

    def __repr__(self) -> str:
        return f"<LocationPing PingID={self.ping_id} DriverID={self.driver_id} Lat={self.latitude:.6f} Lon={self.longitude:.6f}>"
