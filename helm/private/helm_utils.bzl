"""rules_helm utility helpers"""

def symlink(*, ctx, output, target_file, is_executable = True):
    """A utility function for avoiding https://github.com/bazelbuild/bazel/issues/21747

    Args:
        ctx (ctx): The rule's context object.
        output (File): The output file.
        target_file (File): The file to target.
        is_executable (bool): Whether or not the symlink should be executable.
    """
    if target_file.basename.endswith(".exe"):
        args = ctx.actions.args()
        args.add(target_file)
        args.add(output)
        ctx.actions.run(
            executable = ctx.executable._copier,
            mnemonic = "HelmCopier",
            arguments = [args],
            inputs = [target_file],
            outputs = [output],
        )
    else:
        ctx.actions.symlink(
            output = output,
            target_file = target_file,
            is_executable = is_executable,
        )

def rlocationpath(file, workspace_name):
    """Generate the Runfiles location path for a given file.

    Args:
        file (File): The file in question
        workspace_name (str): The name of the current workspace.

    Returns:
        str: The rlocationpath value of `file`.
    """
    if file.short_path.startswith("../"):
        return file.short_path[len("../"):]

    return "{}/{}".format(workspace_name, file.short_path)

StampSettingInfo = provider(
    doc = "Information about the `--stamp` command line flag",
    fields = {
        "value": "bool: Whether or not the `--stamp` flag was enabled",
    },
)

def _stamp_build_setting_impl(ctx):
    return StampSettingInfo(value = ctx.attr.value)

_stamp_build_setting = rule(
    doc = """\
        Whether to encode build information into the binary. Possible values:

        - stamp = 1: Always stamp the build information into the binary, even in [--nostamp][stamp] builds. \
        This setting should be avoided, since it potentially kills remote caching for the binary and \
        any downstream actions that depend on it.
        - stamp = 0: Always replace build information by constant values. This gives good build result caching.
        - stamp = -1: Embedding of build information is controlled by the [--[no]stamp][stamp] flag.

        Stamped binaries are not rebuilt unless their dependencies change.
        [stamp]: https://docs.bazel.build/versions/main/user-manual.html#flag--stamp

        This module can be removed likely after the following PRs ar addressed:
        - https://github.com/bazelbuild/bazel/issues/11164
    """,
    implementation = _stamp_build_setting_impl,
    attrs = {
        "value": attr.bool(
            doc = "The default value of the stamp build flag",
            mandatory = True,
        ),
    },
)

def stamp_build_setting(name, visibility = ["//visibility:public"]):
    native.config_setting(
        name = "stamp_detect",
        values = {"stamp": "1"},
        visibility = visibility,
    )

    _stamp_build_setting(
        name = name,
        value = select({
            ":stamp_detect": True,
            "//conditions:default": False,
        }),
        visibility = visibility,
    )

def is_stamping_enabled(attr):
    """Determine whether or not build stamping is enabled

    Args:
        attr (struct): A rule's struct of attributes (`ctx.attr`)

    Returns:
        bool: The stamp value
    """
    stamp_num = getattr(attr, "stamp", -1)
    if stamp_num == 1:
        return True
    elif stamp_num == 0:
        return False
    elif stamp_num == -1:
        stamp_flag = getattr(attr, "_stamp_flag", None)
        return stamp_flag[StampSettingInfo].value if stamp_flag else False
    else:
        fail("Unexpected `stamp` value: {}".format(stamp_num))
