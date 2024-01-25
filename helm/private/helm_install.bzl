"""Helm rules"""

load("//helm:providers.bzl", "HelmPackageInfo")

def _stamp_opts(ctx, name, opts):
    opts_file = ctx.actions.declare_file("{}.{}.opts".format(ctx.label.name, name))
    ctx.actions.write(
        opts_file,
        "\n".join(opts),
    )

    opts_stamped_file = ctx.actions.declare_file("{}.{}.opts.stamped".format(ctx.label.name, name))

    args = ctx.actions.args()
    args.add("-volatile_status_file", ctx.version_file)
    args.add("-stable_status_file", ctx.info_file)
    args.add("-input_file", opts_file)
    args.add("-output_file", opts_stamped_file)

    ctx.actions.run(
        executable = ctx.file._stamper,
        inputs = [opts_file, ctx.version_file, ctx.info_file],
        outputs = [opts_stamped_file],
        arguments = [args],
    )

    return opts_stamped_file

def _helm_install_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    helm_opts_file = _stamp_opts(ctx, "helm_opts", ctx.attr.helm_opts)
    opts_file = _stamp_opts(ctx, "opts", ctx.attr.opts)

    if toolchain.helm.basename.endswith(".exe"):
        installer = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        installer = ctx.actions.declare_file(ctx.label.name + ".sh")

    install_name = ctx.attr.install_name or ctx.label.name

    pkg_info = ctx.attr.package[HelmPackageInfo]

    image_pushers = []
    image_runfiles = []
    for image in pkg_info.images:
        image_pushers.append(image[DefaultInfo].files_to_run.executable)
        image_runfiles.append(image[DefaultInfo].default_runfiles)

    ctx.actions.expand_template(
        template = ctx.file._installer,
        output = installer,
        substitutions = {
            "{chart}": pkg_info.chart.short_path,
            "{helm}": toolchain.helm.short_path,
            "{image_pushers}": "\n".join([pusher.short_path for pusher in image_pushers]),
            "{install_name}": install_name,
            "{helm_opts}": helm_opts_file.short_path,
            "{install_opts}": opts_file.short_path,
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles([installer, toolchain.helm, pkg_info.chart, helm_opts_file, opts_file] + image_pushers)
    for ir in image_runfiles:
        runfiles = runfiles.merge(ir)

    return [
        DefaultInfo(
            files = depset([installer]),
            runfiles = runfiles,
            executable = installer,
        ),
    ]

helm_install = rule(
    doc = "Produce a script for performing a helm install action",
    implementation = _helm_install_impl,
    executable = True,
    attrs = {
        "opts": attr.string_list(
            doc = "Additional arguments to pass to `helm install`.",
        ),
        "helm_opts": attr.string_list(
            doc = "Additional arguments to pass to `helm` during install.",
        ),
        "install_name": attr.string(
            doc = "The name to use for the `helm install` command. The target name will be used if unset.",
        ),
        "package": attr.label(
            doc = "The helm package to install.",
            providers = [HelmPackageInfo],
            mandatory = True,
        ),
        "_installer": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            allow_single_file = True,
            default = Label("//helm/private/installer:template"),
        ),
        "_stamper": attr.label(
            doc = "A process wrapper to use for stamping the install.",
            allow_single_file = True,
            default = Label("//helm/private/stamper"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)

def _helm_uninstall_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    helm_opts_file = _stamp_opts(ctx, "helm_opts", ctx.attr.helm_opts)
    opts_file = _stamp_opts(ctx, "opts", ctx.attr.opts)

    if toolchain.helm.basename.endswith(".exe"):
        uninstaller = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        uninstaller = ctx.actions.declare_file(ctx.label.name + ".sh")

    install_name = ctx.attr.install_name or ctx.label.name

    ctx.actions.expand_template(
        template = ctx.file._uninstaller,
        output = uninstaller,
        substitutions = {
            "{helm}": toolchain.helm.short_path,
            "{install_name}": install_name,
            "{helm_opts}": helm_opts_file.short_path,
            "{install_opts}": opts_file.short_path,
        },
        is_executable = True,
    )

    return [
        DefaultInfo(
            files = depset([uninstaller]),
            runfiles = ctx.runfiles([uninstaller, toolchain.helm, helm_opts_file, opts_file]),
            executable = uninstaller,
        ),
    ]

helm_uninstall = rule(
    doc = "Produce a script for performing a helm uninstall action",
    implementation = _helm_uninstall_impl,
    executable = True,
    attrs = {
        "opts": attr.string_list(
            doc = "Additional arguments to pass to `helm install`.",
        ),
        "helm_opts": attr.string_list(
            doc = "Additional arguments to pass to `helm` during install.",
        ),
        "install_name": attr.string(
            doc = "The name to use for the `helm install` command. The target name will be used if unset.",
        ),
        "_uninstaller": attr.label(
            doc = "A process wrapper to use for performing `helm uninstall`.",
            allow_single_file = True,
            default = Label("//helm/private/uninstaller:template"),
        ),
        "_stamper": attr.label(
            doc = "A process wrapper to use for stamping the install.",
            allow_single_file = True,
            default = Label("//helm/private/stamper"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)

def _helm_reinstall_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    helm_opts_file = _stamp_opts(ctx, "helm_opts", ctx.attr.helm_opts)
    opts_file = _stamp_opts(ctx, "opts", ctx.attr.opts)

    if toolchain.helm.basename.endswith(".exe"):
        reinstaller = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        reinstaller = ctx.actions.declare_file(ctx.label.name + ".sh")

    install_name = ctx.attr.install_name or ctx.label.name

    pkg_info = ctx.attr.package[HelmPackageInfo]

    image_pushers = []
    image_runfiles = []
    for image in pkg_info.images:
        image_pushers.append(image[DefaultInfo].files_to_run.executable)
        image_runfiles.append(image[DefaultInfo].default_runfiles)

    ctx.actions.expand_template(
        template = ctx.file._reinstaller,
        output = reinstaller,
        substitutions = {
            "{chart}": pkg_info.chart.short_path,
            "{helm}": toolchain.helm.short_path,
            "{image_pushers}": "\n".join([pusher.short_path for pusher in image_pushers]),
            "{install_name}": install_name,
            "{helm_opts}": helm_opts_file.short_path,
            "{install_opts}": opts_file.short_path,
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles([reinstaller, toolchain.helm, pkg_info.chart, helm_opts_file, opts_file] + image_pushers)
    for ir in image_runfiles:
        runfiles = runfiles.merge(ir)

    return [
        DefaultInfo(
            files = depset([reinstaller]),
            runfiles = runfiles,
            executable = reinstaller,
        ),
    ]

helm_reinstall = rule(
    doc = "Produce a script for performing a helm uninstall and install actions",
    implementation = _helm_reinstall_impl,
    executable = True,
    attrs = {
        "opts": attr.string_list(
            doc = "Additional arguments to pass to `helm install`.",
        ),
        "helm_opts": attr.string_list(
            doc = "Additional arguments to pass to `helm` during install.",
        ),
        "install_name": attr.string(
            doc = "The name to use for the `helm install` command. The target name will be used if unset.",
        ),
        "package": attr.label(
            doc = "The helm package to reinstall.",
            providers = [HelmPackageInfo],
            mandatory = True,
        ),
        "_reinstaller": attr.label(
            doc = "A process wrapper to use for performing `helm uninstall`.",
            allow_single_file = True,
            default = Label("//helm/private/reinstaller:template"),
        ),
        "_stamper": attr.label(
            doc = "A process wrapper to use for stamping the install.",
            allow_single_file = True,
            default = Label("//helm/private/stamper"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)

def _helm_push_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    helm_opts_file = _stamp_opts(ctx, "helm_opts", ctx.attr.helm_opts)
    opts_file = _stamp_opts(ctx, "opts", ctx.attr.opts)

    if toolchain.helm.basename.endswith(".exe"):
        pusher = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        pusher = ctx.actions.declare_file(ctx.label.name + ".sh")

    pkg_info = ctx.attr.package[HelmPackageInfo]

    image_pushers = []
    image_runfiles = []
    for image in pkg_info.images:
        image_pushers.append(image[DefaultInfo].files_to_run.executable)
        image_runfiles.append(image[DefaultInfo].default_runfiles)

    if image_pushers:
        image_commands = "\n".join([pusher.short_path for pusher in image_pushers])
    else:
        image_commands = "echo 'No OCI images to push for Helm chart'"

    ctx.actions.expand_template(
        template = ctx.file._pusher,
        output = pusher,
        substitutions = {
            "{image_pushers}": image_commands,
            "{helm_opts}": helm_opts_file.short_path,
            "{install_opts}": opts_file.short_path,
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles([pusher] + image_pushers)
    for ir in image_runfiles:
        runfiles = runfiles.merge(ir)

    return [
        DefaultInfo(
            files = depset([pusher]),
            runfiles = runfiles,
            executable = pusher,
        ),
    ]

helm_push = rule(
    doc = "Produce a script for pushing all oci images used by a helm chart",
    implementation = _helm_push_impl,
    executable = True,
    attrs = {
        "package": attr.label(
            doc = "The helm package to upload images from.",
            providers = [HelmPackageInfo],
            mandatory = True,
        ),
        "_pusher": attr.label(
            doc = "A template used to produce the pusher executable.",
            allow_single_file = True,
            default = Label("//helm/private/pusher:template"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)
