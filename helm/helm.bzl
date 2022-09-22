"""Helm rules"""

load("//helm/private:helm_install.bzl", "helm_install", "helm_push", "helm_reinstall", "helm_uninstall")
load("//helm/private:helm_package.bzl", "helm_package")

def helm_chart(name, images = [], deps = None, tags = [], install_name = None):
    """Rules for producing a helm package and some convenience targets.

    | target | rule |
    | --- | --- |
    | `{name}` | [helm_package](#helm_package) |
    | `{name}.push` | [helm_push](#helm_push) |
    | `{name}.install` | [helm_install](#helm_install) |
    | `{name}.uninstall` | [helm_uninstall](#helm_uninstall) |
    | `{name}.reinstall` | [helm_reinstall](#helm_reinstall) |

    Args:
        name (str): The name of the [helm_package](#helm_package) target.
        images (list, optional): A list of [container_push](https://github.com/bazelbuild/rules_docker/blob/v0.22.0/docs/container.md#container_push) targets
        deps (list, optional): A list of helm package dependencies.
        tags (list, optional): Tags to apply to all targets.
        install_name (str, optional): The `helm install` name to use. `name` will be used if unset.
    """
    helm_package(
        name = name,
        chart = "Chart.yaml",
        deps = deps,
        images = images,
        tags = tags,
        templates = native.glob(["templates/**"]),
        values = "values.yaml",
    )

    helm_push(
        name = name + ".push",
        package = name,
        tags = tags,
    )

    if not install_name:
        install_name = name.replace("_", "-")

    helm_install(
        name = name + ".install",
        install_name = install_name,
        package = name,
        tags = tags,
    )

    helm_uninstall(
        name = name + ".uninstall",
        install_name = install_name,
        tags = tags,
    )

    helm_reinstall(
        name = name + ".reinstall",
        install_name = install_name,
        package = name,
        tags = tags,
    )

def chart_content(
        name,
        api_version = "v2",
        description = "A Helm chart for Kubernetes by Bazel.",
        type = "application",
        version = "0.1.0",
        app_version = "0.16.0"):
    """A convenience wrapper for defining Chart.yaml files with [helm_package.chart_json](#helm_package-chart_json).

    Args:
        name (str): The name of the chart
        api_version (str, optional): The Helm API version
        description (str, optional): A descritpion of the chart.
        type (str, optional): The chart type.
        version (str, optional): The chart version.
        app_version (str, optional): The version number of the application being deployed.

    Returns:
        str: A json encoded string which represents `Chart.yaml` contents.
    """
    return json.encode({
        "apiVersion": api_version,
        "appVersion": app_version,
        "description": description,
        "name": name,
        "type": type,
        "version": version,
    })
