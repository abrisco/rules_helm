#!/usr/bin/env python3

import argparse
import subprocess
import sys
import tarfile
import tempfile
import os
from pathlib import Path
from typing import Optional


def parse_args() -> argparse.Namespace:
    """[summary]

    Returns:
        argparse.Namespace: [description]
    """
    parser = argparse.ArgumentParser("Helm Linter")

    parser.add_argument(
        "--helm",
        type=Path,
        required=True,
        help="The path to a helm binary",
    )
    parser.add_argument(
        "--package",
        type=Path,
        required=True,
        help="The path to a helm package",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="The path an output file that indicates linting was run successfully",
    )
    parser.add_argument(
        "--test",
        action="store_true",
        help="A flag to indicate whether or not the script is being run as test vs an action",
    )

    # Optionally parse arguments from a file provided from an environment variable
    if "RULES_HELM_HELM_LINT_TEST_ARGS_PATH" in os.environ:
        args_path = Path(os.environ["RULES_HELM_HELM_LINT_TEST_ARGS_PATH"])
        args = args_path.read_text().splitlines()
        opt = parser.parse_args(args)
    else:
        opt = parser.parse_args()

    if not opt.output and not opt.test:
        parser.error("`--output` is required when `--test` is not passed")

    return opt


def extract_package(helm_package: Path, output: Path) -> Path:
    """[summary]

    Args:
        helm_package (Path): [description]
        output (Path): [description]

    Returns:
        Path: [description]
    """
    with tarfile.open(helm_package) as tgz:
        tgz.extractall(str(output))

    # Ensure the chart extracts to just one directory
    dir_contents = list(tmp_path.iterdir())
    if len(dir_contents) != 1:
        raise RuntimeError(
            "Unexpected number of elements extracted from chart.tgz: {}".format(
                dir_contents
            )
        )

    return dir_contents[0]


def lint(directory: Path, helm_bin: Path, output: Optional[Path]) -> None:
    """[summary]

    Args:
        directory (Path): [description]
        helm_bin (Path): [description]
        output (Path): [description]
    """

    # Run the linter
    proc = subprocess.run(
        [helm_bin, "lint", "."],
        cwd=directory,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )

    stdout = proc.stdout.decode("utf-8")
    if proc.returncode:
        print(stdout, file=sys.stderr)
        sys.exit(proc.returncode)

    # Populate the output file
    if output:
        output.write_text(stdout)


if __name__ == "__main__":
    opt = parse_args()

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)

        chart_root = extract_package(opt.package, tmp_path)

        # In order to run the linter, the absolute path to the helm binary is needed
        helm_bin = Path.cwd() / opt.helm
        output = Path.cwd() / opt.output if opt.output else None
        lint(chart_root, helm_bin, output)
