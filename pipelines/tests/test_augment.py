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
def test_dau_count_no_params() -> None:
    """dau_count with no params still makes the request."""
    config = AugmentConfig(api_url="http://test", api_token="tok")
    client = AugmentClient(config)

    respx.get("http://test/analytics/v0/dau-count").mock(
        return_value=httpx.Response(200, json={"data": []})
    )

    result = client.dau_count()
    assert result["data"] == []
    client.close()


@respx.mock
def test_dau() -> None:
    config = AugmentConfig(api_url="http://test", api_token="tok")
    client = AugmentClient(config)

    respx.get("http://test/analytics/v0/dau").mock(
        return_value=httpx.Response(200, json={"data": [{"user": "alice@example.com"}]})
    )

    result = client.dau(date="2025-11-24")
    assert result["data"][0]["user"] == "alice@example.com"
    client.close()


@respx.mock
def test_dau_no_params() -> None:
    config = AugmentConfig(api_url="http://test", api_token="tok")
    client = AugmentClient(config)

    respx.get("http://test/analytics/v0/dau").mock(
        return_value=httpx.Response(200, json={"data": []})
    )

    result = client.dau()
    assert result["data"] == []
    client.close()


@respx.mock
def test_daily_usage() -> None:
    config = AugmentConfig(api_url="http://test", api_token="tok")
    client = AugmentClient(config)

    respx.get("http://test/analytics/v0/daily-usage").mock(
        return_value=httpx.Response(200, json={"data": [{"date": "2025-11-24", "messages": 100}]})
    )

    result = client.daily_usage("2025-11-24", "2025-11-25")
    assert result["data"][0]["messages"] == 100
    client.close()


@respx.mock
def test_daily_usage_no_params() -> None:
    config = AugmentConfig(api_url="http://test", api_token="tok")
    client = AugmentClient(config)

    respx.get("http://test/analytics/v0/daily-usage").mock(
        return_value=httpx.Response(200, json={"data": []})
    )

    result = client.daily_usage()
    assert result == {"data": []}
    client.close()


@respx.mock
def test_user_activity() -> None:
    config = AugmentConfig(api_url="http://test", api_token="tok")
    client = AugmentClient(config)

    respx.get("http://test/analytics/v0/user-activity").mock(
        return_value=httpx.Response(
            200,
            json={"data": [{"user": "bob@example.com", "active_days": 3}]},
        )
    )

    result = client.user_activity("2025-11-24", "2025-11-25")
    assert result["data"][0]["active_days"] == 3
    client.close()


@respx.mock
def test_user_activity_no_params() -> None:
    config = AugmentConfig(api_url="http://test", api_token="tok")
    client = AugmentClient(config)

    respx.get("http://test/analytics/v0/user-activity").mock(
        return_value=httpx.Response(200, json={"data": []})
    )

    result = client.user_activity()
    assert result == {"data": []}
    client.close()


@respx.mock
def test_rate_limit_retry() -> None:
    """Client retries once after a 429 rate limit response."""
    config = AugmentConfig(api_url="http://test", api_token="tok")
    client = AugmentClient(config)

    # First call returns 429, second returns 200
    respx.get("http://test/analytics/v0/dau-count").mock(
        side_effect=[
            httpx.Response(429, json={}),
            httpx.Response(200, json={"data": [{"date": "2025-11-24", "count": 5}]}),
        ]
    )

    # Patch RATE_LIMIT_DELAY to speed up test
    import tempo_pipelines.sources.augment as augment_mod

    original_delay = augment_mod.RATE_LIMIT_DELAY
    augment_mod.RATE_LIMIT_DELAY = 0
    try:
        result = client.dau_count()
        assert result["data"][0]["count"] == 5
    finally:
        augment_mod.RATE_LIMIT_DELAY = original_delay
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
def test_pipeline_writes_empty_data(tmp_path: Path) -> None:
    """Pipeline handles empty data list gracefully."""
    config = AugmentConfig(api_url="http://test", api_token="tok")

    respx.get("http://test/analytics/v0/dau-count").mock(
        return_value=httpx.Response(200, json={"data": []})
    )

    result = run_augment_pipeline(config, str(tmp_path))
    assert result.success
    assert result.records_processed == 0
    assert result.source == "augment"


@respx.mock
def test_pipeline_handles_non_list_data(tmp_path: Path) -> None:
    """Pipeline handles response where data field is not a list."""
    config = AugmentConfig(api_url="http://test", api_token="tok")

    respx.get("http://test/analytics/v0/dau-count").mock(
        return_value=httpx.Response(200, json={"data": "not-a-list"})
    )

    result = run_augment_pipeline(config, str(tmp_path))
    assert result.success
    assert result.records_processed == 0


@respx.mock
def test_pipeline_handles_error(tmp_path: Path) -> None:
    config = AugmentConfig(api_url="http://test", api_token="tok")

    respx.get("http://test/analytics/v0/dau-count").mock(
        return_value=httpx.Response(500, json={"error": "server error"})
    )

    result = run_augment_pipeline(config, str(tmp_path))
    assert not result.success
    assert result.error is not None


@respx.mock
def test_pipeline_creates_nested_output_dir(tmp_path: Path) -> None:
    """Pipeline creates nested output directories if they don't exist."""
    config = AugmentConfig(api_url="http://test", api_token="tok")
    nested = tmp_path / "a" / "b" / "c"

    respx.get("http://test/analytics/v0/dau-count").mock(
        return_value=httpx.Response(200, json={"data": [{"date": "2025-11-24", "count": 1}]})
    )

    result = run_augment_pipeline(config, str(nested))
    assert result.success
    assert (nested / "augment_data.json").exists()
