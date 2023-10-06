"""Helm rules for managing external dependencies"""

load("//helm:providers.bzl", "HelmPackageInfo")

def _helm_import_impl(ctx):
    metadata_output = ctx.actions.declare_file(ctx.label.name + ".metadata.json")
    ctx.actions.write(
        output = metadata_output,
        content = json.encode_indent(struct(
            name = ctx.label.name,
            version = ctx.attr.version,
        ), indent = " " * 4),
    )

    return [
        DefaultInfo(
            files = depset([ctx.file.chart]),
            runfiles = ctx.runfiles([ctx.file.chart]),
        ),
        HelmPackageInfo(
            chart = ctx.file.chart,
            images = [],
            metadata = metadata_output,
        ),
    ]

helm_import = rule(
    implementation = _helm_import_impl,
    doc = "A rule that allows pre-packaged Helm charts to be used within Bazel.",
    attrs = {
        "chart": attr.label(
            doc = "A Helm chart's `.tgz` file.",
            allow_single_file = [".tgz"],
        ),
        "version": attr.string(
            doc = "The version fo the helm chart",
        ),
    },
)

def _find_chart_url(repository_ctx, repo_file, chart_file):
    repo_def = repository_ctx.read(repo_file)
    lines = repo_def.splitlines()
    for line in lines:
        line = line.lstrip(" ")
        if line.startswith("-") and line.endswith(chart_file):
            url = line.lstrip("-").lstrip(" ")
            if url == chart_file:
                return "{}/{}".format(repository_ctx.attr.repository, url)
            if url.startswith("http") and url.endswith("/{}".format(chart_file)):
                return url
    fail("cannot find {} in {}".format(chart_file, repo_file))

_HELM_DEP_BUILD_FILE = """\
load("@rules_helm//helm:defs.bzl", "helm_import")

helm_import(
    name = "{chart_name}",
    chart = "{chart_file}",
    visibility = ["//visibility:public"],
)

alias(
    name = "{repository_name}",
    actual = ":{chart_name}",
    visibility = ["//visibility:public"],
)
"""

def _helm_import_repository_impl(repository_ctx):
    chart_name = repository_ctx.attr.chart_name or repository_ctx.name

    if repository_ctx.attr.url:
        chart_url = repository_ctx.attr.url
    else:
        if not repository_ctx.attr.version:
            fail("`version` is needed to locate charts")

        repo_yaml = "index.yaml"
        repository_ctx.download(
            output = repo_yaml,
            url = "{}/{}".format(
                repository_ctx.attr.repository,
                repo_yaml,
            ),
        )
        file_name = "{}-{}.tgz".format(
            chart_name,
            repository_ctx.attr.version,
        )

        chart_url = _find_chart_url(repository_ctx, repo_yaml, file_name)

    # Parse the chart file name from the URL
    _, _, chart_file = chart_url.rpartition("/")

    repository_ctx.file("BUILD.bazel", content = _HELM_DEP_BUILD_FILE.format(
        chart_name = chart_name,
        chart_file = chart_file,
        repository_name = repository_ctx.name,
    ))

    result = repository_ctx.download(
        output = repository_ctx.path(chart_file),
        url = chart_url,
        sha256 = repository_ctx.attr.sha256,
    )

    return {
        "chart_name": repository_ctx.attr.chart_name,
        "name": repository_ctx.name,
        "repository": repository_ctx.attr.repository,
        "sha256": result.sha256,
        "url": chart_url,
        "version": repository_ctx.attr.version,
    }

helm_import_repository = repository_rule(
    implementation = _helm_import_repository_impl,
    doc = "A rule for fetching external Helm charts from an arbitrary repository.",
    attrs = {
        "chart_name": attr.string(
            doc = "Chart name to import.",
        ),
        "repository": attr.string(
            doc = "Chart repository url where to locate the requested chart.",
            mandatory = True,
        ),
        "sha256": attr.string(
            doc = "The expected SHA-256 hash of the chart imported.",
        ),
        "url": attr.string(
            doc = "The url where the chart can be directly downloaded.",
        ),
        "version": attr.string(
            doc = "Specify a version constraint for the chart version to use.",
        ),
    },
)
