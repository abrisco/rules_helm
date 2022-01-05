#!/usr/bin/env python3

import argparse
import json
import re
import shutil
import subprocess
import tempfile
from glob import glob
from pathlib import Path
from shutil import move
from typing import Dict, List, Optional


def parse_args() -> argparse.Namespace:
    """[summary]

    Returns:
        argparse.Namespace: [description]
    """
    parser = argparse.ArgumentParser("helm packager")

    parser.add_argument(
        "--template",
        dest="templates",
        required=True,
        type=Path,
        action="append",
        help="A helm template file",
    )
    parser.add_argument(
        "--chart", required=True, type=Path, help="The helm `chart.yaml` file."
    )
    parser.add_argument(
        "--values", required=True, type=Path, help="The helm `values.yaml` file."
    )
    parser.add_argument(
        "--dep",
        dest="deps",
        type=Path,
        action="append",
        help="A helm dependency (`charts/*.tgz` files).",
    )
    parser.add_argument(
        "--helm", required=True, type=Path, help="The path to a helm executable"
    )
    parser.add_argument(
        "--output",
        required=True,
        type=Path,
        help="The path to the Bazel `HelmPackage` action output",
    )
    parser.add_argument(
        "--metadata_output",
        required=True,
        type=Path,
        help="The path to the Bazel `HelmPackage` action metadata output",
    )
    parser.add_argument(
        "--image_manifest",
        dest="image_manifests",
        type=Path,
        action="append",
        help="Information about Bazel produced container images used by the helm chart",
    )
    parser.add_argument(
        "--stable_status_file",
        type=Path,
        help="The stable status file (`ctx.info_file`)",
    )
    parser.add_argument(
        "--volatile_status_file",
        type=Path,
        help="The stable status file (`ctx.version_file`)",
    )
    parser.add_argument(
        "--workspace_name",
        type=str,
        required=True,
        help="The name of the current Bazel workspace",
    )

    return parser.parse_args()


def load_image_stamps(
    image_manifests: Optional[List[Path]], workspace_name: str
) -> Dict[str, str]:
    """[summary]

    Args:
        image_manifests (Optional[List[Path]]): [description]
        workspace_name (str): [description]

    Returns:
        Dict[str, str]: [description]
    """
    images = {}

    if not image_manifests:
        return images

    for manifest_path in image_manifests:
        manifest = json.loads(manifest_path.read_text())
        registry_url = "{}/{}@{}".format(
            manifest["registry"],
            manifest["repository"],
            Path(manifest["digest"]).read_text().strip(),
        )
        images.update({manifest["label"].strip(): registry_url})
        if not manifest["label"].startswith("@"):
            images.update(
                {
                    "@{}{}".format(
                        workspace_name, manifest["label"].strip()
                    ): registry_url
                }
            )

    return images


def apply_stamping(
    content: str,
    volatile_status_file: Optional[Path],
    stable_status_file: Optional[Path],
    image_stamps: Dict[str, str],
) -> str:
    """[summary]

    Args:
        content (str): [description]
        volatile_status_file (Optional[Path]): [description]
        stable_status_file (Optional[Path]): [description]
        image_stamps (Dict[str, str]): [description]

    Returns:
        str: [description]
    """
    stamps = {}
    for file in (volatile_status_file, stable_status_file):
        if not file or not file.exists():
            continue
        with file.open() as fhd:
            for line in fhd.readlines():
                key, value = line.split(" ", maxsplit=1)
                stamps.update({key: value})

    for image_label, url in image_stamps.items():
        content = content.replace("{" + image_label + "}", url)

    for stamp, value in stamps.items():
        content = content.replace("{" + stamp + "}", value.rstrip())

    return content


def main() -> None:
    """[summary]

    Raises:
        ValueError: [description]
        ValueError: [description]
    """
    opt = parse_args()

    with tempfile.TemporaryDirectory() as tmp_dir:
        # Load image stamps
        image_stamps = load_image_stamps(opt.image_manifests, opt.workspace_name)

        # Copy the chart and values
        chart_content = apply_stamping(
            content=opt.chart.read_text(),
            stable_status_file=opt.stable_status_file,
            volatile_status_file=opt.volatile_status_file,
            image_stamps=image_stamps,
        )

        # Chart.yaml may contain some base stamp values in builds that aren't stamping
        # these are sanitized here to produce consistent outputs.
        chart_name = None
        replacements = []
        for line in chart_content.splitlines():
            if line.startswith(("version", "appVersion")):
                replacements.append(line)
            if line.startswith("name:"):
                chart_name = line[len("name:") :].strip(" \"'")
        for replacement in replacements:
            chart_content = chart_content.replace(
                replacement,
                replacement.replace("{", "").replace("}", "").replace("_", "-"),
            )

        if not chart_name:
            raise ValueError("The Chart.yaml file has no `name` definition")

        # Create a directory that matches the chart name to satisfy `apiVersion = v1`
        tmp_path = Path(tmp_dir) / chart_name
        tmp_path.mkdir(parents=True, exist_ok=True)

        # Write the new Chart.yaml file
        (tmp_path / "Chart.yaml").write_text(chart_content)

        # The `values.yaml` file may have stamp variables which need to be resolved.
        (tmp_path / "values.yaml").write_text(
            apply_stamping(
                content=opt.values.read_text(),
                stable_status_file=opt.stable_status_file,
                volatile_status_file=opt.volatile_status_file,
                image_stamps=image_stamps,
            )
        )

        # Copy all templates
        templates_dir = tmp_path / "templates"
        for template in opt.templates:
            # Locate the root templates directory
            template_root = template
            while template_root and template_root.name != "templates":
                template_root = template_root.parent

            # Determine the copy destination with sub directories
            template_rel_path = template.relative_to(template_root)
            dest = templates_dir / template_rel_path

            # Copy the template file
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(template, dest)

        if opt.deps:
            # Copy over any dependency chart files
            chart_dir = tmp_path / "charts"
            chart_dir.mkdir(parents=True)
            for dep in opt.deps:
                shutil.copyfile(dep, chart_dir / dep.name)

        # Build the helm package
        helm_bin = Path.cwd() / opt.helm
        proc = subprocess.run(
            [helm_bin, "package", "."], cwd=str(tmp_path), capture_output=True
        )
        if proc.returncode:
            print(proc.stdout.decode("utf-8"))
            print(proc.stderr.decode("utf-8"))
            exit(proc.returncode)

        # Locate the package file
        files = glob("{}/*.tgz".format(tmp_path))
        if len(files) != 1:
            raise ValueError(
                "Unexpected number of helm packages found: {}".format(files)
            )
        package = Path(files[0])

        # Read metadata
        match = re.match(r"(.*)-([\d][\d\w\-\.]+)\.tgz", package.name)
        if not match:
            raise ValueError("Unable to parse file name: '{}'".format(package.name))
        name = match.group(1)
        version = match.group(2)

        # Write metadata
        opt.metadata_output.write_text(
            json.dumps(
                {
                    "name": name,
                    "version": version,
                },
                indent=4,
            )
        )

        # Move the package to satisfy the Bazel action
        move(str(package), str(opt.output.resolve()))


if __name__ == "__main__":
    main()
