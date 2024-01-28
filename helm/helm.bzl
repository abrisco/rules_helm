"""Helm rules"""

load("//helm/private:helm_install.bzl", "helm_install", "helm_push", "helm_uninstall", "helm_upgrade")
load("//helm/private:helm_package.bzl", "helm_package")
load("//helm/private:helm_registry.bzl", "helm_push_registry")

def helm_chart(
        name,
        chart = None,
        chart_json = None,
        values = None,
        values_json = None,
        substitutions = {},
        templates = None,
        images = [],
        deps = None,
        tags = [],
        install_name = None,
        registry_url = None,
        helm_opts = [],
        install_opts = [],
        upgrade_opts = [],
        uninstall_opts = [],
        stamp = None,
        **kwargs):
    """Rules for producing a helm package and some convenience targets.

    | target | rule |
    | --- | --- |
    | `{name}` | [helm_package](#helm_package) |
    | `{name}.push` | [helm_push](#helm_push) |
    | `{name}.push_registry` | [helm_push_registry](#helm_push_registry) |
    | `{name}.install` | [helm_install](#helm_install) |
    | `{name}.uninstall` | [helm_uninstall](#helm_uninstall) |
    | `{name}.upgrade` | [helm_upgrade](#helm_upgrade) |

    Args:
        name (str): The name of the [helm_package](#helm_package) target.
        chart (str, optional): The path to the chart directory. Defaults to `Chart.yaml`.
        chart_json (str, optional): The json encoded contents of `Chart.yaml`.
        values (str, optional): The path to the values file. Defaults to `values.yaml`.
        values_json (str, optional): The json encoded contents of `values.yaml`.
        substitutions (dict, optional): A dictionary of substitutions to apply to `values.yaml`.
        templates (list, optional): A list of template files to include in the package.
        images (list, optional): A list of [oci_push](https://github.com/bazel-contrib/rules_oci/blob/main/docs/push.md#oci_push_rule-remote_tags) targets
        deps (list, optional): A list of helm package dependencies.
        tags (list, optional): Tags to apply to all targets.
        install_name (str, optional): The `helm install` name to use. `name` will be used if unset.
        registry_url (str, Optional): The registry url for the helm chart. `{name}.push_registry`
            is only defined when a value is passed here.
        helm_opts (list, optional): Additional options to pass to helm.
        install_opts (list, optional): Additional options to pass to `helm install`.
        uninstall_opts (list, optional): Additional options to pass to `helm uninstall`.
        upgrade_opts (list, optional): Additional options to pass to `helm upgrade`.
        stamp (int):  Whether to encode build information into the helm chart.
        **kwargs (dict): Additional keyword arguments for `helm_package`.
    """
    if templates == None:
        templates = native.glob(["templates/**"])

    tags = kwargs.pop("tags", [])
    tags_with_manual = depset(tags + ["manual"]).to_list()

    helm_package(
        name = name,
        chart = chart,
        chart_json = chart_json,
        deps = deps,
        images = images,
        templates = templates,
        values = values,
        values_json = values_json,
        substitutions = substitutions,
        stamp = stamp,
        tags = tags,
        **kwargs
    )

    helm_push(
        name = name + ".push",
        package = name,
        tags = tags_with_manual,
        **kwargs
    )

    if registry_url:
        helm_push_registry(
            name = name + ".push_registry",
            package = name,
            registry_url = registry_url,
            tags = tags_with_manual,
            **kwargs
        )

    if not install_name:
        install_name = name.replace("_", "-")

    helm_install(
        name = name + ".install",
        install_name = install_name,
        package = name,
        tags = tags_with_manual,
        helm_opts = helm_opts,
        opts = install_opts,
        **kwargs
    )

    helm_upgrade(
        name = name + ".upgrade",
        install_name = install_name,
        package = name,
        tags = tags_with_manual,
        helm_opts = helm_opts,
        opts = upgrade_opts,
        **kwargs
    )

    helm_uninstall(
        name = name + ".uninstall",
        install_name = install_name,
        tags = tags_with_manual,
        helm_opts = helm_opts,
        opts = uninstall_opts,
        **kwargs
    )
