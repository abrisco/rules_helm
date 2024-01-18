"""Helm rules"""

load("//helm:providers.bzl", "HelmPackageInfo")

def _helm_push_registry_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    if toolchain.helm.basename.endswith(".exe"):
        registrar = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        registrar = ctx.actions.declare_file(ctx.label.name + ".sh")

    registry_url = ctx.attr.registry_url

    pkg_info = ctx.attr.package[HelmPackageInfo]
    ctx.actions.expand_template(
        template = ctx.file._registrar,
        output = registrar,
        substitutions = {
            "{chart}": pkg_info.chart.short_path,
            "{helm}": toolchain.helm.short_path,
            "{registry_url}": registry_url,
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles([registrar, toolchain.helm, pkg_info.chart])

    return [
        DefaultInfo(
            files = depset([registrar]),
            runfiles = runfiles,
            executable = registrar,
        ),
    ]

helm_push_registry = rule(
    doc = "Produce a script for performing a helm push to a registry",
    implementation = _helm_push_registry_impl,
    executable = True,
    attrs = {
        "package": attr.label(
            doc = "The helm package to push to the registry.",
            providers = [HelmPackageInfo],
            mandatory = True,
        ),
        "registry_url": attr.string(
            doc = "The URL of the registry.",
            mandatory = True,
        ),
        "_registrar": attr.label(
            doc = "A process wrapper to use for performing `helm registry and helm push`.",
            allow_single_file = True,
            default = Label("//helm/private/registrar:template"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)
