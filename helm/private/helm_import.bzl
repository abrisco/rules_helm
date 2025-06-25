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
    if repository_ctx.attr.url and repository_ctx.attr.repository:
        fail("`url` and `repository` are exclusive arguments.")

    if repository_ctx.attr.url:
        chart_url = repository_ctx.attr.url
        if repository_ctx.attr.chart_name:
            fail("`url` provided, do not set `chart_name`")
        if repository_ctx.attr.version:
            fail("`url` provided, do not set `version`")
    else:
        if not repository_ctx.attr.chart_name:
            fail("`chart_name` is required to locate chart")
        if not repository_ctx.attr.version:
            fail("`version` is required to locate chart")

        repo_yaml = "index.yaml"
        repository_ctx.download(
            output = repo_yaml,
            url = "{}/{}".format(
                repository_ctx.attr.repository,
                repo_yaml,
            ),
        )
        file_name = "{}-{}.tgz".format(
            repository_ctx.attr.chart_name,
            repository_ctx.attr.version,
        )

        chart_url = _find_chart_url(repository_ctx, repo_yaml, file_name)

    if not chart_url.startswith("http"):
        fail("Cannot download from {}, unsupported protocol".format(chart_url))

    # Parse the chart file name from the URL
    _, _, chart_file = chart_url.rpartition("/")
    chart_name, _, chart_version = chart_file.removesuffix(".tgz").rpartition("-")

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
        "chart_name": chart_name,
        "name": repository_ctx.name,
        "repository": repository_ctx.attr.repository,
        "sha256": result.sha256,
        "url": chart_url,
        "version": chart_version,
    }

helm_import_repository = repository_rule(
    implementation = _helm_import_repository_impl,
    doc = "A rule for fetching external Helm charts from an arbitrary URL or repository.",
    attrs = {
        "chart_name": attr.string(
            doc = "Chart name to import. Must be set if `repository` is specified",
        ),
        "repository": attr.string(
            doc = "Chart repository url where to locate the requested chart. Mutually exclusive with `url`.",
        ),
        "sha256": attr.string(
            doc = "The expected SHA-256 hash of the chart imported.",
        ),
        "url": attr.string(
            doc = "The url where a chart can be directly downloaded. Mutually exclusive with `chart_name`, `repository`, and `version`",
        ),
        "version": attr.string(
            doc = "Specify a version constraint for the chart version to use. Must be set if `repository` is specified.",
        ),
    },
)
