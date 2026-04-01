"""Tests for the CLI entry point."""

from pathlib import Path

import httpx
import respx
from click.testing import CliRunner

from tempo_pipelines.cli import list_pipelines, main, run


def test_list_pipelines() -> None:
    """list command shows available pipelines."""
    runner = CliRunner()
    result = runner.invoke(list_pipelines)
    assert result.exit_code == 0
    assert "augment" in result.output


def test_main_help() -> None:
    """main group shows help."""
    runner = CliRunner()
    result = runner.invoke(main, ["--help"])
    assert result.exit_code == 0


def test_run_help() -> None:
    """run command shows help."""
    runner = CliRunner()
    result = runner.invoke(run, ["--help"])
    assert result.exit_code == 0


@respx.mock
def test_run_augment_pipeline_success(tmp_path: Path) -> None:
    """run augment pipeline ends successfully."""
    respx.get("https://api.augmentcode.com/analytics/v0/dau-count").mock(
        return_value=httpx.Response(200, json={"data": [{"date": "2025-11-24", "count": 3}]})
    )

    runner = CliRunner()
    result = runner.invoke(run, ["-p", "augment", "-o", str(tmp_path)])
    assert result.exit_code == 0
    assert "completed" in result.output


@respx.mock
def test_run_augment_pipeline_failure(tmp_path: Path) -> None:
    """run augment pipeline reports failure on HTTP error."""
    respx.get("https://api.augmentcode.com/analytics/v0/dau-count").mock(
        return_value=httpx.Response(500, json={"error": "server error"})
    )

    runner = CliRunner()
    result = runner.invoke(run, ["-p", "augment", "-o", str(tmp_path)])
    assert result.exit_code == 1
    assert "failed" in result.output


def test_run_main_list_via_main() -> None:
    """list command accessible through main group."""
    runner = CliRunner()
    result = runner.invoke(main, ["list"])
    assert result.exit_code == 0
    assert "augment" in result.output


def test_run_main_run_help() -> None:
    """run subcommand is accessible through main group."""
    runner = CliRunner()
    result = runner.invoke(main, ["run", "--help"])
    assert result.exit_code == 0


def test_run_unknown_pipeline_else_branch(tmp_path: Path) -> None:
    """The else branch for unknown pipeline is reachable via callback invocation."""
    from tempo_pipelines.cli import run

    runner = CliRunner()
    # Call the underlying callback directly to bypass click.Choice validation
    with runner.isolated_filesystem():
        try:
            run.callback(pipeline="unknown_source", output=str(tmp_path))  # type: ignore[attr-defined]
            raise AssertionError("Should have raised SystemExit")
        except SystemExit as exc:
            assert exc.code == 1


def test_main_module_entrypoint() -> None:
    """Verify __main__.py can be imported without crashing at module level."""
    import subprocess
    import sys

    # Run as a subprocess with --help to exercise the __main__ entry
    proc = subprocess.run(
        [sys.executable, "-m", "tempo_pipelines", "--help"],
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0
    assert "Tempo Pipelines" in proc.stdout
