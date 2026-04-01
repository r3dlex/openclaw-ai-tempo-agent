"""Tests for pipeline configuration."""

import os

from tempo_pipelines.config import AugmentConfig, PipelineConfig


def test_augment_config_defaults() -> None:
    config = AugmentConfig(api_token="test_token")
    assert config.api_url == "https://api.augmentcode.com"
    assert config.api_token == "test_token"


def test_augment_config_custom_url() -> None:
    config = AugmentConfig(api_url="http://localhost:8081", api_token="tok")
    assert config.api_url == "http://localhost:8081"


def test_augment_config_from_env(monkeypatch: object) -> None:
    assert isinstance(monkeypatch, object)
    import pytest

    with pytest.MonkeyPatch.context() as mp:
        mp.setenv("AUGMENT_API_URL", "http://env-test")
        mp.setenv("AUGMENT_API_TOKEN", "env-token")
        config = AugmentConfig()
        assert config.api_url == "http://env-test"
        assert config.api_token == "env-token"


def test_pipeline_config_defaults() -> None:
    config = PipelineConfig(augment=AugmentConfig(api_token="tok"))
    assert config.data_dir == "data"
    assert config.log_level == "INFO"


def test_pipeline_config_has_augment() -> None:
    config = PipelineConfig(augment=AugmentConfig(api_token="tok"))
    assert isinstance(config.augment, AugmentConfig)
