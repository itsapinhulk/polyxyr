"""polyxyr — a collection of useful utilities."""

from importlib.metadata import PackageNotFoundError, version as _version

try:
    __version__ = _version("polyxyr")
except PackageNotFoundError:  # pragma: no cover - not installed
    __version__ = "0.0.1"

__all__ = ["__version__"]
