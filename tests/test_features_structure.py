#!/usr/bin/env python3
"""Structure checks for my.features wiring (no Nix required)."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text()


def main() -> int:
    features = read("modules/features.nix")
    assert "mkEnableOption" in features
    assert "awscli" in features
    assert "zellij" in features

    darwin = read("darwin/default.nix")
    assert "../modules/features.nix" in darwin
    assert "sharedModules" in darwin
    assert "my.features" in darwin

    packages = read("home/packages.nix")
    assert "config.my.features.awscli.enable" in packages
    assert "# awscli2" not in packages  # must not rely on comment toggles
    assert "awscli2" in packages

    brew = read("darwin/homebrew.nix")
    assert "config.my.features" in brew
    assert "lib.optionals" in brew

    print("test_features_structure: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
