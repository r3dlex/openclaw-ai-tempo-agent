"""Data models for pipeline outputs."""

from datetime import datetime

from pydantic import BaseModel


class DateRange(BaseModel):
    start_date: datetime
    end_date: datetime


class UsageRecord(BaseModel):
    """A single usage record from an AI tool."""

    date_range: DateRange
    credits_consumed: int
    group_key: str


class DauCount(BaseModel):
    """Daily active user count."""

    date: str
    count: int


class UserActivity(BaseModel):
    """Per-user activity metrics."""

    user: str
    active_days: int
    modified_lines: int = 0
    messages: int = 0
    tool_calls: int = 0
    completions: int = 0


class DailyUsage(BaseModel):
    """Daily organization usage metrics."""

    date: str
    modified_lines: int = 0
    messages: int = 0
    tool_calls: int = 0
    completions: int = 0


class PipelineResult(BaseModel):
    """Result of a pipeline execution."""

    source: str
    records_processed: int
    output_file: str
    timestamp: datetime
    success: bool
    error: str | None = None
