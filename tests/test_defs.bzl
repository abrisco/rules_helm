"""Test rules and utiltiies"""

load("//helm:providers.bzl", "HelmPackageInfo")

def _rlocationpath(file, workspace_name):
    if file.short_path.startswith("../"):
        return file.short_path[len("../"):]

    return "{}/{}".format(workspace_name, file.short_path)

def _helm_package_regex_test_impl(ctx):
    package = ctx.attr.package[HelmPackageInfo].chart

    chart_patterns = ctx.actions.declare_file("{}.chart_patterns.json".format(ctx.label.name))
    values_patterns = ctx.actions.declare_file("{}.values_patterns.json".format(ctx.label.name))
    templates_patterns = ctx.actions.declare_file("{}.templates_patterns.json".format(ctx.label.name))

    ctx.actions.write(
        output = chart_patterns,
        content = json.encode_indent(ctx.attr.chart_patterns, indent = " " * 4),
    )

    ctx.actions.write(
        output = values_patterns,
        content = json.encode_indent(ctx.attr.values_patterns, indent = " " * 4),
    )

    ctx.actions.write(
        output = templates_patterns,
        content = json.encode_indent(ctx.attr.templates_patterns, indent = " " * 4),
    )

    test_runner = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = test_runner,
        target_file = ctx.executable._test_runner,
        is_executable = True,
    )

    return [
        DefaultInfo(
            runfiles = ctx.runfiles(files = [package, chart_patterns, values_patterns, templates_patterns]).merge(ctx.attr._test_runner[DefaultInfo].default_runfiles),
            executable = test_runner,
        ),
        testing.TestEnvironment(
            environment = {
                "CHART_PATTERNS": _rlocationpath(chart_patterns, ctx.workspace_name),
                "HELM_PACKAGE": _rlocationpath(package, ctx.workspace_name),
                "TEMPLATES_PATTERNS": _rlocationpath(templates_patterns, ctx.workspace_name),
                "VALUES_PATTERNS": _rlocationpath(values_patterns, ctx.workspace_name),
            },
        ),
    ]

helm_package_regex_test = rule(
    doc = "A rule for testing that a Helm package's `Chart.yaml` and `values.yaml` files contain expected regex patterns.",
    implementation = _helm_package_regex_test_impl,
    attrs = {
        "chart_patterns": attr.string_list(
            doc = "A list of regex patterns that are required to match the contents of `Chart.yaml` from `package`.",
        ),
        "package": attr.label(
            doc = "A `helm_package` target.",
            providers = [HelmPackageInfo],
            mandatory = True,
        ),
        "templates_patterns": attr.string_list_dict(
            doc = "A mapping of template paths to regex patterns required to match.",
        ),
        "values_patterns": attr.string_list(
            doc = "A list of regex patterns that are required to match the contents of `values.yaml` from `package`.",
        ),
        "_test_runner": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//tests/private/package_regex_tester"),
        ),
    },
    test = True,
)
