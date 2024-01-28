"""Helm rules"""

load("//helm:providers.bzl", "HelmPackageInfo")

def _stamp_opts(ctx, name, opts):
    opts_file = ctx.actions.declare_file("{}.{}.opts".format(ctx.label.name, name))
    ctx.actions.write(
        opts_file,
        " ".join(opts),
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

    if toolchain.helm.basename.endswith(".exe"):
        runner_wrapper = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        runner_wrapper = ctx.actions.declare_file(ctx.label.name + ".sh")

    install_name = ctx.attr.install_name or ctx.label.name

    pkg_info = ctx.attr.package[HelmPackageInfo]

    image_pushers = []
    image_runfiles = []
    for image in pkg_info.images:
        image_pushers.append(image[DefaultInfo].files_to_run.executable)
        image_runfiles.append(image[DefaultInfo].default_runfiles)

    args = []
    args.extend(ctx.attr.helm_opts)
    args.append("install")
    args.extend(ctx.attr.opts)
    args.append(install_name)
    args.append(pkg_info.chart.short_path)

    ctx.actions.expand_template(
        template = ctx.file._runner_wrapper,
        output = runner_wrapper,
        substitutions = {
            "{HELM_BIN}": toolchain.helm.short_path,
            "{STABLE_STATUS_FILE}": ctx.info_file.short_path,
            "{VOLATILE_STATUS_FILE}": ctx.version_file.short_path,
            "{HELM_OPTS}": " ".join(args),
            "{RUNNER}": ctx.executable._runner.short_path,
            "{EXTRA_CMDS}": "\n".join([pusher.short_path for pusher in image_pushers]),
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles([runner_wrapper, ctx.executable._runner, toolchain.helm, pkg_info.chart, ctx.info_file, ctx.version_file] + image_pushers)
    for ir in image_runfiles:
        runfiles = runfiles.merge(ir)

    return [
        DefaultInfo(
            files = depset([runner_wrapper]),
            runfiles = runfiles,
            executable = runner_wrapper,
        ),
    ]

helm_install = rule(
    doc = "Produce a script for performing a helm install action",
    implementation = _helm_install_impl,
    executable = True,
    attrs = {
        "helm_opts": attr.string_list(
            doc = "Additional arguments to pass to `helm` during install.",
        ),
        "install_name": attr.string(
            doc = "The name to use for the `helm install` command. The target name will be used if unset.",
        ),
        "opts": attr.string_list(
            doc = "Additional arguments to pass to `helm install`.",
        ),
        "package": attr.label(
            doc = "The helm package to install.",
            providers = [HelmPackageInfo],
            mandatory = True,
        ),
        "_runner_wrapper": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            allow_single_file = True,
            default = Label("//helm/private/runner:wrapper"),
        ),
        "_runner": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            executable = True,
            cfg = "exec",
            default = Label("//helm/private/runner"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)

def _helm_upgrade_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    if toolchain.helm.basename.endswith(".exe"):
        runner_wrapper = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        runner_wrapper = ctx.actions.declare_file(ctx.label.name + ".sh")

    install_name = ctx.attr.install_name or ctx.label.name

    pkg_info = ctx.attr.package[HelmPackageInfo]

    image_pushers = []
    image_runfiles = []
    for image in pkg_info.images:
        image_pushers.append(image[DefaultInfo].files_to_run.executable)
        image_runfiles.append(image[DefaultInfo].default_runfiles)

    args = []
    args.extend(ctx.attr.helm_opts)
    args.append("upgrade")
    args.extend(ctx.attr.opts)
    args.append(install_name)
    args.append(pkg_info.chart.short_path)

    ctx.actions.expand_template(
        template = ctx.file._runner_wrapper,
        output = runner_wrapper,
        substitutions = {
            "{HELM_BIN}": toolchain.helm.short_path,
            "{STABLE_STATUS_FILE}": ctx.info_file.short_path,
            "{VOLATILE_STATUS_FILE}": ctx.version_file.short_path,
            "{HELM_OPTS}": " ".join(args),
            "{RUNNER}": ctx.executable._runner.short_path,
            "{EXTRA_CMDS}": "\n".join([pusher.short_path for pusher in image_pushers]),
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles([runner_wrapper, ctx.executable._runner, toolchain.helm, pkg_info.chart, ctx.info_file, ctx.version_file] + image_pushers)
    for ir in image_runfiles:
        runfiles = runfiles.merge(ir)

    return [
        DefaultInfo(
            files = depset([runner_wrapper]),
            runfiles = runfiles,
            executable = runner_wrapper,
        ),
    ]

helm_upgrade = rule(
    doc = "Produce a script for performing a helm upgrade action",
    implementation = _helm_upgrade_impl,
    executable = True,
    attrs = {
        "helm_opts": attr.string_list(
            doc = "Additional arguments to pass to `helm` during upgrade.",
        ),
        "install_name": attr.string(
            doc = "The name to use for the `helm upgrade` command. The target name will be used if unset.",
        ),
        "opts": attr.string_list(
            doc = "Additional arguments to pass to `helm upgrade`.",
        ),
        "package": attr.label(
            doc = "The helm package to upgrade.",
            providers = [HelmPackageInfo],
            mandatory = True,
        ),
        "_runner_wrapper": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            allow_single_file = True,
            default = Label("//helm/private/runner:wrapper"),
        ),
        "_runner": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            executable = True,
            cfg = "exec",
            default = Label("//helm/private/runner"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)

def _helm_uninstall_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    if toolchain.helm.basename.endswith(".exe"):
        runner_wrapper = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        runner_wrapper = ctx.actions.declare_file(ctx.label.name + ".sh")

    install_name = ctx.attr.install_name or ctx.label.name


    args = []
    args.extend(ctx.attr.helm_opts)
    args.append("uninstall")
    args.extend(ctx.attr.opts)
    args.append(install_name)

    ctx.actions.expand_template(
        template = ctx.file._runner_wrapper,
        output = runner_wrapper,
        substitutions = {
            "{HELM_BIN}": toolchain.helm.short_path,
            "{STABLE_STATUS_FILE}": ctx.info_file.short_path,
            "{VOLATILE_STATUS_FILE}": ctx.version_file.short_path,
            "{HELM_OPTS}": " ".join(args),
            "{RUNNER}": ctx.executable._runner.short_path,
            "{EXTRA_CMDS}": "",
        },
        is_executable = True,
    )

    return [
        DefaultInfo(
            files = depset([runner_wrapper]),
            runfiles = ctx.runfiles([runner_wrapper, ctx.executable._runner, toolchain.helm, ctx.info_file, ctx.version_file]),
            executable = runner_wrapper,
        ),
    ]

helm_uninstall = rule(
    doc = "Produce a script for performing a helm uninstall action",
    implementation = _helm_uninstall_impl,
    executable = True,
    attrs = {
        "helm_opts": attr.string_list(
            doc = "Additional arguments to pass to `helm` during install.",
        ),
        "install_name": attr.string(
            doc = "The name to use for the `helm install` command. The target name will be used if unset.",
        ),
        "opts": attr.string_list(
            doc = "Additional arguments to pass to `helm uninstall`.",
        ),
        "_runner_wrapper": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            allow_single_file = True,
            default = Label("//helm/private/runner:wrapper"),
        ),
        "_runner": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            executable = True,
            cfg = "exec",
            default = Label("//helm/private/runner"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)

def _helm_push_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

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
