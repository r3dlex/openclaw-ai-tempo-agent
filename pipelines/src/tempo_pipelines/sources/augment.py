"""Augment Code Analytics API client.

Endpoints:
- GET /analytics/v0/dau-count     Daily active user counts (max 90 days)
- GET /analytics/v0/dau           Active users for a date (paginated)
- GET /analytics/v0/daily-usage   Org usage by day
- GET /analytics/v0/user-activity Per-user metrics (paginated)
- GET /analytics/v0/daily-user-activity-by-editor-language

Rate limit: 10 req/min, 20-request burst.
"""

import json
from datetime import datetime
from pathlib import Path

import httpx
import structlog

from tempo_pipelines.config import AugmentConfig
from tempo_pipelines.models import PipelineResult

logger = structlog.get_logger()

RATE_LIMIT_DELAY = 6.0  # seconds between requests to stay under 10/min


class AugmentClient:
    """Client for the Augment Code Analytics API."""

    def __init__(self, config: AugmentConfig) -> None:
        self.config = config
        self.client = httpx.Client(
            base_url=config.api_url,
            headers={
                "Authorization": f"Bearer {config.api_token}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            timeout=30.0,
        )

    def dau_count(
        self, start_date: str | None = None, end_date: str | None = None
    ) -> dict[str, object]:
        """Fetch daily active user counts."""
        params: dict[str, str] = {}
        if start_date:
            params["start_date"] = start_date
        if end_date:
            params["end_date"] = end_date
        return self._get("/analytics/v0/dau-count", params)

    def dau(self, date: str | None = None, page_size: int = 100) -> dict[str, object]:
        """Fetch active users for a date."""
        params: dict[str, str | int] = {"page_size": page_size}
        if date:
            params["date"] = date
        return self._get("/analytics/v0/dau", params)

    def daily_usage(
        self, start_date: str | None = None, end_date: str | None = None
    ) -> dict[str, object]:
        """Fetch daily organization usage metrics."""
        params: dict[str, str] = {}
        if start_date:
            params["start_date"] = start_date
        if end_date:
            params["end_date"] = end_date
        return self._get("/analytics/v0/daily-usage", params)

    def user_activity(
        self, start_date: str | None = None, end_date: str | None = None, page_size: int = 50
    ) -> dict[str, object]:
        """Fetch per-user activity metrics."""
        params: dict[str, str | int] = {"page_size": page_size}
        if start_date:
            params["start_date"] = start_date
        if end_date:
            params["end_date"] = end_date
        return self._get("/analytics/v0/user-activity", params)

    def _get(self, path: str, params: dict[str, str | int]) -> dict[str, object]:
        """Make a GET request with rate limit retry."""
        response = self.client.get(path, params=params)
        if response.status_code == 429:
            import time

            logger.warning("rate_limited", path=path)
            time.sleep(RATE_LIMIT_DELAY)
            response = self.client.get(path, params=params)
        response.raise_for_status()
        return response.json()  # type: ignore[no-any-return]

    def close(self) -> None:
        self.client.close()


def run_augment_pipeline(config: AugmentConfig, output_dir: str) -> PipelineResult:
    """Execute the Augment data ingestion pipeline."""
    client = AugmentClient(config)
    output_path = Path(output_dir) / "augment_data.json"

    try:
        logger.info("augment_pipeline_start")
        data = client.dau_count()
        records = data.get("data", [])
        record_count = len(records) if isinstance(records, list) else 0

        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, "w") as f:
            json.dump(data, f, indent=2)

        logger.info("augment_pipeline_complete", records=record_count)
        return PipelineResult(
            source="augment",
            records_processed=record_count,
            output_file=str(output_path),
            timestamp=datetime.utcnow(),
            success=True,
        )
    except Exception as e:
        logger.error("augment_pipeline_failed", error=str(e))
        return PipelineResult(
            source="augment",
            records_processed=0,
            output_file=str(output_path),
            timestamp=datetime.utcnow(),
            success=False,
            error=str(e),
        )
    finally:
        client.close()
