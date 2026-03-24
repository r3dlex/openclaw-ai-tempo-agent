"""Pipeline configuration via environment variables."""

from pydantic_settings import BaseSettings


class AugmentConfig(BaseSettings):
    """Augment Code API configuration."""

    api_url: str = "https://api.augmentcode.com"
    api_token: str = ""

    model_config = {"env_prefix": "AUGMENT_"}


class PipelineConfig(BaseSettings):
    """Global pipeline configuration."""

    data_dir: str = "data"
    log_level: str = "INFO"

    augment: AugmentConfig = AugmentConfig()

    model_config = {"env_prefix": "TEMPO_"}
