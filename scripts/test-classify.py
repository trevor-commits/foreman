#!/usr/bin/env python3
"""Regression tests for classifier fallback behavior."""

from __future__ import annotations

import importlib.util
import json
import os
import sys
import types
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("foreman-classify.py")
SPEC = importlib.util.spec_from_file_location("foreman_classify", MODULE_PATH)
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


def test_provider_error_falls_back_to_standard() -> None:
    class FailingMessages:
        def create(self, **_kwargs: object) -> object:
            raise RuntimeError("provider unavailable")

    class FailingClient:
        messages = FailingMessages()

    original_module = sys.modules.get("anthropic")
    original_key = os.environ.get("ANTHROPIC_API_KEY")
    sys.modules["anthropic"] = types.SimpleNamespace(Anthropic=FailingClient)
    os.environ["ANTHROPIC_API_KEY"] = "fixture"
    try:
        raw, model, used_fallback = module.call_anthropic("fixture prompt")
    finally:
        if original_module is None:
            sys.modules.pop("anthropic", None)
        else:
            sys.modules["anthropic"] = original_module
        if original_key is None:
            os.environ.pop("ANTHROPIC_API_KEY", None)
        else:
            os.environ["ANTHROPIC_API_KEY"] = original_key

    result = json.loads(raw)
    assert used_fallback is True, used_fallback
    assert model == "claude-opus-5", model
    assert result["route"] == "standard", result
    assert result["confidence"] == 0.0, result


if __name__ == "__main__":
    test_provider_error_falls_back_to_standard()
    print("PASS: classifier provider errors fall back to standard")
