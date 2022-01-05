"""rules_helm toolchain implementation"""

def _helm_toolchain_impl(ctx):
    return platform_common.ToolchainInfo(
        helm = ctx.file.helm,
    )

helm_toolchain = rule(
    implementation = _helm_toolchain_impl,
    doc = "A helm toolchain",
    attrs = {
        "helm": attr.label(
            doc = "A helm binary",
            allow_single_file = True,
            mandatory = True,
        ),
    },
)
