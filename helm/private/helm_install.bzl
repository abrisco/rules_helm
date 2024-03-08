"""Helm rules"""

load("//helm:providers.bzl", "HelmPackageInfo")
load("//helm/private:helm_utils.bzl", _is_stamping_enabled = "is_stamping_enabled")

def _expand_opts(ctx, opts, targets):
    return [ctx.expand_location(x, targets = targets) for x in opts]

def _helm_install_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    if toolchain.helm.basename.endswith(".exe"):
        runner_wrapper = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        runner_wrapper = ctx.actions.declare_file(ctx.label.name + ".sh")

    install_name = ctx.attr.install_name or ctx.label.name

    pkg_info = ctx.attr.package[HelmPackageInfo]

    is_stamping_enabled = _is_stamping_enabled(ctx.attr)

    image_pushers = []
    image_runfiles = []
    for image in pkg_info.images:
        image_pushers.append(image[DefaultInfo].files_to_run.executable)
        image_runfiles.append(image[DefaultInfo].default_runfiles)

    args = []
    args.extend(_expand_opts(ctx, ctx.attr.helm_opts, ctx.attr.data))
    args.append("install")
    args.extend(_expand_opts(ctx, ctx.attr.opts, ctx.attr.data))
    args.append(install_name)
    args.append(pkg_info.chart.short_path)

    ctx.actions.expand_template(
        template = ctx.file._runner_wrapper,
        output = runner_wrapper,
        substitutions = {
            "{EXTRA_CMDS}": "\n".join([pusher.short_path for pusher in image_pushers]),
            "{HELM_OPTS}": " ".join(args),
            "{RUNNER}": ctx.executable._runner.short_path,
        },
        is_executable = True,
    )
    is_stamping_enabled = _is_stamping_enabled(ctx.attr)

    environment = {
        "HELM_BIN": toolchain.helm.short_path,
    }

    runfiles = [runner_wrapper, ctx.executable._runner, toolchain.helm, pkg_info.chart] + image_pushers + ctx.files.data
    if is_stamping_enabled:
        runfiles.extend([ctx.info_file, ctx.version_file])
        environment["STABLE_STATUS_FILE"] = ctx.info_file.short_path
        environment["VOLATILE_STATUS_FILE"] = ctx.version_file.short_path

    runfiles = ctx.runfiles(runfiles)
    for ir in image_runfiles:
        runfiles = runfiles.merge(ir)

    return [
        DefaultInfo(
            files = depset([runner_wrapper]),
            runfiles = runfiles,
            executable = runner_wrapper,
        ),
        RunEnvironmentInfo(
            environment = environment,
        ),
    ]

helm_install = rule(
    doc = "Produce a script for performing a helm install action",
    implementation = _helm_install_impl,
    executable = True,
    attrs = {
        "data": attr.label_list(
            doc = "Additional data to pass to `helm install`.",
            allow_files = True,
            mandatory = False,
        ),
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
        "_runner": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            executable = True,
            cfg = "exec",
            default = Label("//helm/private/runner"),
        ),
        "_runner_wrapper": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            allow_single_file = True,
            default = Label("//helm/private/runner:wrapper"),
        ),
        "_stamp_flag": attr.label(
            doc = "A setting used to determine whether or not the `--stamp` flag is enabled",
            default = Label("//helm/private:stamp"),
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

    is_stamping_enabled = _is_stamping_enabled(ctx.attr)

    pkg_info = ctx.attr.package[HelmPackageInfo]

    image_pushers = []
    image_runfiles = []
    for image in pkg_info.images:
        image_pushers.append(image[DefaultInfo].files_to_run.executable)
        image_runfiles.append(image[DefaultInfo].default_runfiles)

    args = []
    args.extend(_expand_opts(ctx, ctx.attr.helm_opts, ctx.attr.data))
    args.append("upgrade")
    args.extend(_expand_opts(ctx, ctx.attr.opts, ctx.attr.data))
    args.append(install_name)
    args.append(pkg_info.chart.short_path)

    ctx.actions.expand_template(
        template = ctx.file._runner_wrapper,
        output = runner_wrapper,
        substitutions = {
            "{EXTRA_CMDS}": "\n".join([pusher.short_path for pusher in image_pushers]),
            "{HELM_OPTS}": " ".join(args),
            "{RUNNER}": ctx.executable._runner.short_path,
        },
        is_executable = True,
    )

    environment = {
        "HELM_BIN": toolchain.helm.short_path,
    }

    runfiles = [runner_wrapper, ctx.executable._runner, toolchain.helm, pkg_info.chart] + image_pushers + ctx.files.data
    if is_stamping_enabled:
        runfiles.extend([ctx.info_file, ctx.version_file])
        environment["STABLE_STATUS_FILE"] = ctx.info_file.short_path
        environment["VOLATILE_STATUS_FILE"] = ctx.version_file.short_path

    runfiles = ctx.runfiles(runfiles)
    for ir in image_runfiles:
        runfiles = runfiles.merge(ir)

    return [
        DefaultInfo(
            files = depset([runner_wrapper]),
            runfiles = runfiles,
            executable = runner_wrapper,
        ),
        RunEnvironmentInfo(
            environment = environment,
        ),
    ]

helm_upgrade = rule(
    doc = "Produce a script for performing a helm upgrade action",
    implementation = _helm_upgrade_impl,
    executable = True,
    attrs = {
        "data": attr.label_list(
            doc = "Additional data to pass to `helm upgrade`.",
            allow_files = True,
            mandatory = False,
        ),
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
        "_runner": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            executable = True,
            cfg = "exec",
            default = Label("//helm/private/runner"),
        ),
        "_runner_wrapper": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            allow_single_file = True,
            default = Label("//helm/private/runner:wrapper"),
        ),
        "_stamp_flag": attr.label(
            doc = "A setting used to determine whether or not the `--stamp` flag is enabled",
            default = Label("//helm/private:stamp"),
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
    args.extend(_expand_opts(ctx, ctx.attr.helm_opts, ctx.attr.data))
    args.append("uninstall")
    args.extend(_expand_opts(ctx, ctx.attr.opts, ctx.attr.data))
    args.append(install_name)

    ctx.actions.expand_template(
        template = ctx.file._runner_wrapper,
        output = runner_wrapper,
        substitutions = {
            "{EXTRA_CMDS}": "",
            "{HELM_OPTS}": " ".join(args),
            "{RUNNER}": ctx.executable._runner.short_path,
        },
        is_executable = True,
    )

    is_stamping_enabled = _is_stamping_enabled(ctx.attr)

    environment = {
        "HELM_BIN": toolchain.helm.short_path,
    }

    runfiles = [runner_wrapper, ctx.executable._runner, toolchain.helm] + ctx.files.data
    if is_stamping_enabled:
        runfiles.extend([ctx.info_file, ctx.version_file])
        environment["STABLE_STATUS_FILE"] = ctx.info_file.short_path
        environment["VOLATILE_STATUS_FILE"] = ctx.version_file.short_path

    return [
        DefaultInfo(
            files = depset([runner_wrapper]),
            runfiles = ctx.runfiles(runfiles),
            executable = runner_wrapper,
        ),
        RunEnvironmentInfo(
            environment = environment,
        ),
    ]

helm_uninstall = rule(
    doc = "Produce a script for performing a helm uninstall action",
    implementation = _helm_uninstall_impl,
    executable = True,
    attrs = {
        "data": attr.label_list(
            doc = "Additional data to pass to `helm uninstall`.",
            allow_files = True,
            mandatory = False,
        ),
        "helm_opts": attr.string_list(
            doc = "Additional arguments to pass to `helm` during install.",
        ),
        "install_name": attr.string(
            doc = "The name to use for the `helm install` command. The target name will be used if unset.",
        ),
        "opts": attr.string_list(
            doc = "Additional arguments to pass to `helm uninstall`.",
        ),
        "_runner": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            executable = True,
            cfg = "exec",
            default = Label("//helm/private/runner"),
        ),
        "_runner_wrapper": attr.label(
            doc = "A process wrapper to use for performing `helm install`.",
            allow_single_file = True,
            default = Label("//helm/private/runner:wrapper"),
        ),
        "_stamp_flag": attr.label(
            doc = "A setting used to determine whether or not the `--stamp` flag is enabled",
            default = Label("//helm/private:stamp"),
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
