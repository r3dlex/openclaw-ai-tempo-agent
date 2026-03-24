"""CLI entry point for running pipelines."""

import click
import structlog

from tempo_pipelines.config import PipelineConfig
from tempo_pipelines.sources.augment import run_augment_pipeline

structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.dev.ConsoleRenderer(),
    ],
)

logger = structlog.get_logger()

PIPELINES = {
    "augment": "Augment Code Analytics",
}


@click.group()
def main() -> None:
    """Tempo Pipelines - AI tool data ingestion."""


@main.command()
@click.option("--pipeline", "-p", required=True, type=click.Choice(list(PIPELINES.keys())))
@click.option("--output", "-o", default="data", help="Output directory")
def run(pipeline: str, output: str) -> None:
    """Run a data pipeline."""
    config = PipelineConfig()
    logger.info("pipeline_start", pipeline=pipeline, output=output)

    if pipeline == "augment":
        result = run_augment_pipeline(config.augment, output)
    else:
        click.echo(f"Unknown pipeline: {pipeline}")
        raise SystemExit(1)

    if result.success:
        click.echo(f"Pipeline '{pipeline}' completed: {result.records_processed} records")
    else:
        click.echo(f"Pipeline '{pipeline}' failed: {result.error}")
        raise SystemExit(1)


@main.command(name="list")
def list_pipelines() -> None:
    """List available pipelines."""
    for key, desc in PIPELINES.items():
        click.echo(f"  {key:15s} {desc}")


if __name__ == "__main__":
    main()
