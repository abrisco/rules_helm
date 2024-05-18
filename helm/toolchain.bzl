"""rules_helm toolchain implementation"""

def _helm_toolchain_impl(ctx):
    binary = ctx.file.helm
    template_variables = platform_common.TemplateVariableInfo({
        "HELM_BIN": binary.path,
    })

    default_info = DefaultInfo(
        files = depset([binary]),
        runfiles = ctx.runfiles(files = [binary]),
    )

    toolchain_info = platform_common.ToolchainInfo(
        helm = binary,
        default = default_info,
        template_variables = template_variables,
    )

    return [default_info, toolchain_info, template_variables]

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
