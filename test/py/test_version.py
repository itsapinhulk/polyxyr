import tomllib
from pathlib import Path

import polyxyr

PYPROJECT = Path(__file__).resolve().parents[2] / "src" / "python" / "pyproject.toml"


def test_version_matches_pyproject():
    expected = tomllib.loads(PYPROJECT.read_text())["project"]["version"]
    assert polyxyr.__version__ == expected
