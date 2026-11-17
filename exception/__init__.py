"""
RideSync - Exceptions Package
"""
from exception.custom_exceptions import (
    RideSyncException,
    DatabaseConnectionError,
    EntityNotFoundError,
    DuplicateEntityError,
    DriverUnavailableError,
    InvalidTripStateTransitionError,
    AtomicDispatchConflictError,
)

__all__ = [
    "RideSyncException",
    "DatabaseConnectionError",
    "EntityNotFoundError",
    "DuplicateEntityError",
    "DriverUnavailableError",
    "InvalidTripStateTransitionError",
    "AtomicDispatchConflictError",
]
