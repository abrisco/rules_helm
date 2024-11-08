"""Helm rules"""

load("//helm:providers.bzl", "HelmPackageInfo")
load(":helm_utils.bzl", "rlocationpath", "symlink")

def _helm_lint_aspect_impl(target, ctx):
    if HelmPackageInfo not in target:
        return []

    helm_pkg_info = target[HelmPackageInfo]
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    output = ctx.actions.declare_file(ctx.label.name + ".helm_lint.ok")

    args = ctx.actions.args()
    args.add("-helm", toolchain.helm)
    args.add("-helm_plugins", toolchain.helm_plugins.path)
    args.add("-package", helm_pkg_info.chart)
    args.add("-output", output)

    ctx.actions.run(
        outputs = [output],
        executable = ctx.executable._linter,
        mnemonic = "HelmLintCheck",
        inputs = [helm_pkg_info.chart],
        tools = [toolchain.helm, toolchain.helm_plugins],
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

    args = ctx.actions.args()
    args.set_param_file_format("multiline")
    args.add("-helm", rlocationpath(toolchain.helm, ctx.workspace_name))
    args.add("-helm_plugins", rlocationpath(toolchain.helm_plugins, ctx.workspace_name))
    args.add("-package", rlocationpath(helm_pkg_info.chart, ctx.workspace_name))

    ctx.actions.write(
        output = args_file,
        content = args,
    )

    if toolchain.helm.basename.endswith(".exe"):
        test_runner = ctx.actions.declare_file(ctx.label.name + ".exe")
    else:
        test_runner = ctx.actions.declare_file(ctx.label.name)

    symlink(
        ctx = ctx,
        output = test_runner,
        target_file = ctx.executable._linter,
        is_executable = True,
    )

    return [
        DefaultInfo(
            files = depset([test_runner]),
            runfiles = ctx.runfiles(
                files = [toolchain.helm, toolchain.helm_plugins, helm_pkg_info.chart, args_file],
            ).merge(ctx.attr._linter[DefaultInfo].default_runfiles),
            executable = test_runner,
        ),
        testing.TestEnvironment({
            "RULES_HELM_HELM_LINT_TEST_ARGS_PATH": rlocationpath(args_file, ctx.workspace_name),
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
        "_copier": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//helm/private/copier"),
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
