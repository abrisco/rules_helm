"""Helm rules"""

load("//helm:providers.bzl", "HelmPackageInfo")

def _sanitize_runfile_path(file):
    """Ensure paths are usable from a runfiles directory

    Args:
        file (File): The file who's path to sanitize

    Returns:
        str: A valid runfiles path for a test
    """
    if file.short_path.startswith("../"):
        return file.short_path.replace("../", "external/", 1)
    return file.short_path

def _helm_lint_aspect_impl(target, ctx):
    if HelmPackageInfo not in target:
        return []

    helm_pkg_info = target[HelmPackageInfo]
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    output = ctx.actions.declare_file(ctx.label.name + ".helm_lint.ok")

    args = ctx.actions.args()
    args.add("-helm", toolchain.helm)
    args.add("-package", helm_pkg_info.chart)
    args.add("-output", output)

    ctx.actions.run(
        outputs = [output],
        executable = ctx.executable._linter,
        mnemonic = "HelmLintCheck",
        inputs = [helm_pkg_info.chart],
        tools = [toolchain.helm],
        arguments = [args],
    )

    return [
        OutputGroupInfo(
            helm_lint_checks = depset([output]),
        ),
    ]

helm_lint_aspect = aspect(
    doc = "An aspect for running `helm lint` on helm package targets",
    implementation = _helm_lint_aspect_impl,
    attrs = {
        "_linter": attr.label(
            doc = "A process wrapper for performing the linting.",
            cfg = "exec",
            executable = True,
            default = Label("//helm/private/linter:linter"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)

def _helm_lint_test_impl(ctx):
    args_file = ctx.actions.declare_file(ctx.label.name + ".args.txt")

    helm_pkg_info = ctx.attr.chart[HelmPackageInfo]
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    ctx.actions.write(
        output = args_file,
        content = "\n".join([
            "-helm",
            _sanitize_runfile_path(toolchain.helm),
            "-package",
            _sanitize_runfile_path(helm_pkg_info.chart),
        ]),
    )

    if toolchain.helm.basename.endswith(".exe"):
        test_runner = ctx.actions.declare_file(ctx.label.name + ".exe")
    else:
        test_runner = ctx.actions.declare_file(ctx.label.name)

    ctx.actions.symlink(
        output = test_runner,
        target_file = ctx.executable._linter,
        is_executable = True,
    )

    return [
        DefaultInfo(
            files = depset([test_runner]),
            runfiles = ctx.runfiles(
                files = [toolchain.helm, helm_pkg_info.chart, args_file],
            ).merge(ctx.attr._linter[DefaultInfo].default_runfiles),
            executable = test_runner,
        ),
        testing.TestEnvironment({
            "RULES_HELM_HELM_LINT_TEST_ARGS_PATH": args_file.short_path,
        }),
    ]

helm_lint_test = rule(
    implementation = _helm_lint_test_impl,
    doc = "A rule for performing `helm lint` on a helm package",
    attrs = {
        "chart": attr.label(
            doc = "The helm package to run linting on.",
            mandatory = True,
            providers = [HelmPackageInfo],
        ),
        "_linter": attr.label(
            doc = "A process wrapper for performing the linting.",
            cfg = "exec",
            executable = True,
            default = Label("//helm/private/linter:linter"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
    test = True,
)
