"""
RideSync - Rider Entity Model
Domain Layer: entity/rider.py
Represents a registered passenger account in UrbanGo Mobility.
"""
from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class Rider:
    """
    Rider Domain Entity
    Corresponds to SQL Server table dbo.Riders
    """
    rider_id: Optional[int]
    first_name: str
    last_name: str
    phone: str
    created_at: Optional[datetime] = None

    def __post_init__(self):
        if not self.first_name or not self.first_name.strip():
            raise ValueError("Rider first_name cannot be empty.")
        if not self.last_name or not self.last_name.strip():
            raise ValueError("Rider last_name cannot be empty.")
        if not self.phone or len(self.phone.strip()) < 10:
            raise ValueError("Rider phone must be at least 10 digits.")

    @property
    def full_name(self) -> str:
        """Returns the full name of the rider."""
        return f"{self.first_name.strip()} {self.last_name.strip()}"

    def __repr__(self) -> str:
        return f"<Rider ID={self.rider_id} Name='{self.full_name}' Phone='{self.phone}'>"
