"""Constants for accessing helm binaries"""

DEFAULT_HELM_VERSION = "3.10.0"

DEFAULT_HELM_URL_TEMPLATES = [
    "https://get.helm.sh/helm-v{version}-{platform}.{compression}",
]

HELM_VERSIONS = {
    "2.17.0": {
        "darwin-amd64": struct(
            sha256 = "104dcda352985306d04d5d23aaf5252d00a85c083f3667fd013991d82f57ae83",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "linux-amd64": struct(
            sha256 = "f3bec3c7c55f6a9eb9e6586b8c503f370af92fe987fcbf741f37707606d70296",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "c3ebe8fa04b4e235eb7a9ab030a98d3002f93ecb842f0a8741f98383a9493d7f",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "048147ef523f88753ba34170f2f6acd01ac6ec688c6f5973b0e5ffb0b113a232",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.10.0": {
        "darwin-amd64": struct(
            sha256 = "1e7fd528482ac2ef2d79fe300724b3e07ff6f846a2a9b0b0fe6f5fa05691786b",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "f7f6558ebc8211824032a7fdcf0d55ad064cb33ec1eeec3d18057b9fe2e04dbe",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "bf56beb418bb529b5e0d6d43d56654c5a03f89c98400b409d1013a33d9586474",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "3b72f5f8a60772fb156d0a4ab93272e8da7ef4d18e6421a7020d7c019f521fc1",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "9d841d55eb7cd6e07be0364bbfa85bceca7e184d50b43b13d20f044403937309",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.4.2": {
        "darwin-amd64": struct(
            sha256 = "c33b7ee72b0006f23b33f5032b531dd609fff7b08a4324f9ba07722a4f3fec9a",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "linux-amd64": struct(
            sha256 = "cacde7768420dd41111a4630e047c231afa01f67e49cc0c6429563e024da4b98",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "486cad35b9ac1da88781847f2fcaaaed729e44705eb42593322e4b52d0f2c1a1",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "76ff3f8c21c9af5b80abdd87ec07629ad88dbfe6206decc4d3024f26398554b9",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.5.3": {
        "darwin-amd64": struct(
            sha256 = "451ad70dfe286e3979c78ecf7074f4749d93644da8aa2cc778e2f969771f1794",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "linux-amd64": struct(
            sha256 = "2170a1a644a9e0b863f00c17b761ce33d4323da64fc74562a3a6df2abbf6cd70",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "e1348d94ce4caace43689ee2dfa5f8bcd8687c12053d9c13d79875b65d6b72aa",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "33fef4740b255b58a52e5504622068fd8a7d9aea19f1a84438f5cc1c5aade0d6",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.6.3": {
        "darwin-amd64": struct(
            sha256 = "84a1ff17dd03340652d96e8be5172a921c97825fd278a2113c8233a4e8db5236",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "a50b499dbd0bbec90761d50974bf1e67cc6d503ea20d03b4a1275884065b7e9e",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "07c100849925623dc1913209cd1a30f0a9b80a5b4d6ff2153c609d11b043e262",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "6fe647628bc27e7ae77d015da4d5e1c63024f673062ac7bc11453ccc55657713",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "797d2abd603a2646f2fb9c3fabba46f2fabae5cbd1eb87c20956ec5b4a2fc634",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.7.2": {
        "darwin-amd64": struct(
            sha256 = "5a0738afb1e194853aab00258453be8624e0a1d34fcc3c779989ac8dbcd59436",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "260d4b8bffcebc6562ea344dfe88efe252cf9511dd6da3cccebf783773d42aec",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "4ae30e48966aba5f807a4e140dad6736ee1a392940101e4d79ffb4ee86200a9e",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "b0214eabbb64791f563bd222d17150ce39bf4e2f5de49f49fdb456ce9ae8162f",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "299165f0af46bece9a61b41305cca8e8d5ec5319a4b694589cd71e6b75aca77e",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.8.1": {
        "darwin-amd64": struct(
            sha256 = "3b6d87d360a51bf0f2344edd54e3580a8e8de2c4a4fd92eccef3e811f7e81bb3",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "5f0fea586781fb867b92c10133786949ab6a447f297d5c12e1e8f5dd3a9ed712",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "d643f48fe28eeb47ff68a1a7a26fc5142f348d02c8bc38d699674016716f61cd",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "dbf5118259717d86c57d379317402ed66016c642cc0d684f3505da6f194b760d",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "a75003fc692131652d3bd218dd4007692390a1dd156f11fd7668e389bdd8f765",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.8.2": {
        "darwin-amd64": struct(
            sha256 = "25bb4a70b0d9538a97abb3aaa57133c0779982a8091742a22026e60d8614f8a0",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "dfddc0696597c010ed903e486fe112a18535ab0c92e35335aa54af2360077900",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "6cb9a48f72ab9ddfecab88d264c2f6508ab3cd42d9c09666be16a7bf006bed7b",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "238db7f55e887f9c1038b7e43585b84389a05fff5424e70557886cad1635b3ce",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "051959311ed5a3d49596b298b9e9618e2a0ad6a9270c134802f205698348ba5e",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.9.0": {
        "darwin-amd64": struct(
            sha256 = "7e5a2f2a6696acf278ea17401ade5c35430e2caa57f67d4aa99c607edcc08f5e",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "22cf080ded5dd71ec15d33c13586ace9b6002e97518a76df628e67ecedd5aa70",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "1484ffb0c7a608d8069470f48b88d729e88c41a1b6602f145231e8ea7b43b50a",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "5c0aa709c5aaeedd190907d70f9012052c1eea7dff94bffe941b879a33873947",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "631d333bce5f2274c00af753d54bb62886cdb17a958d2aff698c196612c9e8cb",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.9.1": {
        "darwin-amd64": struct(
            sha256 = "3cd0ad43154506ef65003bb871e71ab88d080b855ecbaa183e41f774bc7fb46e",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "df47fb682a3ddc9904ee5fe21e60a788cced3556df0496b46278644074b2618a",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "73df7ddd5ab05e96230304bf0e6e31484b1ba136d0fc22679345c0b4bd43f7ac",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "655dbceb4ab4b246af2214e669b9d44e3a35f170f39df8eebdb8d87619c585d1",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "9d6c1f4a2b328be15c548665e49e1628ebb4246258ab2cba6e0ee893b9881314",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.9.2": {
        "darwin-amd64": struct(
            sha256 = "35d7ff8bea561831d78dce8f7bf614a7ffbcad3ff88d4c2f06a51bfa51c017e2",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "6250a6b92603a9c14194932e9dc22380ac423779519521452163493db33b68c8",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "3f5be38068a1829670440ccf00b3b6656fd90d0d9cfd4367539f3b13e4c20531",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "e4e2f9aad786042d903534e3131bc5300d245c24bbadf64fc46cca1728051dbc",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "d0d98a2a1f4794fcfc437000f89d337dc9278b6b7672f30e164f96c9413a7a74",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.9.3": {
        "darwin-amd64": struct(
            sha256 = "ca3d57bb68135fa45a7acc2612d472e8ad01b78f49eaca57490aefef74a61c95",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "db20ee8758616e1d69e90aedc5eb940751888bdd2b031badf2080a05df4c9eb7",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "2d07360a9d93b18488f1ddb9de818b92ba738acbec6e1c66885a88703fa7b21c",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "59168c08c32293759005d0c509ce4be9038d7663827e05564c779e59658d8299",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "cdd24727d233e620ce6e8ec21646a6218bde94cf3d5f24e9c4ae6a114939975d",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.9.4": {
        "darwin-amd64": struct(
            sha256 = "fe5930feca6fd1bd2c57df01c1f381c6444d1c3d2b857526bf6cbfbd6bf906b4",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "a73d91751153169781b3ab5b4702ba1a2631fc8242eba33828b5905870059312",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "31960ff2f76a7379d9bac526ddf889fb79241191f1dbe2a24f7864ddcb3f6560",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "d24163e466f7884c55079d1050968e80a05b633830047116cdfd8ae28d35b0c0",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "7cdc1342bc1863b6d5ce695fbef4d3b0d65c7c5bcef6ec6adf8fc9aa53821262",
            constraints = ["@platforms//os:windows"],
        ),
    },
}
