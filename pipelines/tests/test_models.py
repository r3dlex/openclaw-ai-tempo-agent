"""Tests for data models."""

from datetime import datetime, timezone

from tempo_pipelines.models import (
    DailyUsage,
    DateRange,
    DauCount,
    PipelineResult,
    UsageRecord,
    UserActivity,
)


def test_date_range_model() -> None:
    dr = DateRange(
        start_date=datetime(2025, 11, 24, tzinfo=timezone.utc),
        end_date=datetime(2025, 11, 25, tzinfo=timezone.utc),
    )
    assert dr.start_date.year == 2025


def test_usage_record_model() -> None:
    record = UsageRecord(
        date_range=DateRange(
            start_date=datetime(2025, 11, 24, tzinfo=timezone.utc),
            end_date=datetime(2025, 11, 25, tzinfo=timezone.utc),
        ),
        credits_consumed=500,
        group_key="alice@example.com",
    )
    assert record.credits_consumed == 500
    assert record.group_key == "alice@example.com"


def test_dau_count_model() -> None:
    dau = DauCount(date="2025-11-24", count=42)
    assert dau.count == 42
    assert dau.date == "2025-11-24"


def test_user_activity_model_defaults() -> None:
    ua = UserActivity(user="bob@example.com", active_days=3)
    assert ua.modified_lines == 0
    assert ua.messages == 0
    assert ua.tool_calls == 0
    assert ua.completions == 0


def test_user_activity_model_full() -> None:
    ua = UserActivity(
        user="charlie@example.com",
        active_days=5,
        modified_lines=100,
        messages=50,
        tool_calls=20,
        completions=10,
    )
    assert ua.active_days == 5
    assert ua.modified_lines == 100


def test_daily_usage_model_defaults() -> None:
    du = DailyUsage(date="2025-11-24")
    assert du.modified_lines == 0
    assert du.messages == 0
    assert du.tool_calls == 0
    assert du.completions == 0


def test_daily_usage_model_full() -> None:
    du = DailyUsage(date="2025-11-24", modified_lines=200, messages=75)
    assert du.modified_lines == 200
    assert du.messages == 75


def test_pipeline_result_success() -> None:
    result = PipelineResult(
        source="augment",
        records_processed=10,
        output_file="/tmp/augment_data.json",
        timestamp=datetime.now(tz=timezone.utc),
        success=True,
    )
    assert result.success is True
    assert result.error is None
    assert result.records_processed == 10


def test_pipeline_result_failure() -> None:
    result = PipelineResult(
        source="augment",
        records_processed=0,
        output_file="/tmp/augment_data.json",
        timestamp=datetime.now(tz=timezone.utc),
        success=False,
        error="Connection refused",
    )
    assert result.success is False
    assert result.error == "Connection refused"
