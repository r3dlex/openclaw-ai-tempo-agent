"""Tests for the Augment Code pipeline."""

import json
from pathlib import Path

import httpx
import respx

from tempo_pipelines.config import AugmentConfig
from tempo_pipelines.sources.augment import AugmentClient, run_augment_pipeline


@respx.mock
def test_dau_count() -> None:
    config = AugmentConfig(api_url="http://test", api_token="tok")
    client = AugmentClient(config)

    respx.get("http://test/analytics/v0/dau-count").mock(
        return_value=httpx.Response(200, json={"data": [{"date": "2025-11-24", "count": 10}]})
    )

    result = client.dau_count("2025-11-24", "2025-11-25")
    assert result["data"][0]["count"] == 10
    client.close()


@respx.mock
def test_pipeline_writes_output(tmp_path: Path) -> None:
    config = AugmentConfig(api_url="http://test", api_token="tok")

    respx.get("http://test/analytics/v0/dau-count").mock(
        return_value=httpx.Response(
            200,
            json={"data": [{"date": "2025-11-24", "count": 5}]},
        )
    )

    result = run_augment_pipeline(config, str(tmp_path))
    assert result.success
    assert (tmp_path / "augment_data.json").exists()

    data = json.loads((tmp_path / "augment_data.json").read_text())
    assert "data" in data


@respx.mock
def test_pipeline_handles_error(tmp_path: Path) -> None:
    config = AugmentConfig(api_url="http://test", api_token="tok")

    respx.get("http://test/analytics/v0/dau-count").mock(
        return_value=httpx.Response(500, json={"error": "server error"})
    )

    result = run_augment_pipeline(config, str(tmp_path))
    assert not result.success
    assert result.error is not None
