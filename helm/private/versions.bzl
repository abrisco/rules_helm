"""Constants for accessing helm binaries"""

DEFAULT_HELM_VERSION = "3.13.0"

DEFAULT_HELM_URL_TEMPLATES = [
    "https://get.helm.sh/helm-v{version}-{platform}.{compression}",
]

_CONSTRAINTS = {
    "darwin-amd64": ["@platforms//os:macos", "@platforms//cpu:x86_64"],
    "darwin-arm64": ["@platforms//os:macos", "@platforms//cpu:aarch64"],
    "linux-amd64": ["@platforms//os:linux", "@platforms//cpu:x86_64"],
    "linux-arm": ["@platforms//os:linux", "@platforms//cpu:arm"],
    "linux-arm64": ["@platforms//os:linux", "@platforms//cpu:aarch64"],
    "linux-i386": ["@platforms//os:linux", "@platforms//cpu:i386"],
    "linux-ppc64le": ["@platforms//os:linux", "@platforms//cpu:ppc"],
    "windows-amd64": ["@platforms//os:windows"],
}

def _artifact(platform, sha256):
    return struct(
        sha256 = sha256,
        constraints = _CONSTRAINTS[platform],
    )

HELM_VERSIONS = {
    "2.17.0": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "104dcda352985306d04d5d23aaf5252d00a85c083f3667fd013991d82f57ae83",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "f3bec3c7c55f6a9eb9e6586b8c503f370af92fe987fcbf741f37707606d70296",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "c3ebe8fa04b4e235eb7a9ab030a98d3002f93ecb842f0a8741f98383a9493d7f",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "048147ef523f88753ba34170f2f6acd01ac6ec688c6f5973b0e5ffb0b113a232",
        ),
    },
    "3.10.0": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "1e7fd528482ac2ef2d79fe300724b3e07ff6f846a2a9b0b0fe6f5fa05691786b",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "f7f6558ebc8211824032a7fdcf0d55ad064cb33ec1eeec3d18057b9fe2e04dbe",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "bf56beb418bb529b5e0d6d43d56654c5a03f89c98400b409d1013a33d9586474",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "3b72f5f8a60772fb156d0a4ab93272e8da7ef4d18e6421a7020d7c019f521fc1",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "9d841d55eb7cd6e07be0364bbfa85bceca7e184d50b43b13d20f044403937309",
        ),
    },
    "3.10.1": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "e7f2db0df45a5011c1df8c82efde1e306a93a31eba4696d27cd751917e549ac6",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "28a079a61c393d125c5d5e1a8e20a04b72c709ccfa8e7822f3f17bb1ad2bbc22",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "c12d2cd638f2d066fec123d0bd7f010f32c643afdf288d39a4610b1f9cb32af3",
        ),
        "linux-arm": _artifact(
            platform = "linux-arm",
            sha256 = "309f56a35185023262b4f20f7315d4e60854b517243444b34f5a458c81b33009",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "d04b38d439ab8655abb4cb9ccc1efa8a3fe95f3f68af46d9137c6b7985491833",
        ),
        "linux-i386": _artifact(
            platform = "linux-i386",
            sha256 = "fb75a02d8a6e9ba6dd458f47dc0771a0f15c1842b6f6e2928c9136e676657993",
        ),
        "linux-ppc64le": _artifact(
            platform = "linux-ppc64le",
            sha256 = "855ab37613b393c68d50b4355273df2322f27db08b1deca8807bac80343a8a64",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "4c6f89f005a86665e3e90c28d36446434945594aac960a8d5a2d1c4fb1e53522",
        ),
    },
    "3.10.2": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "e889960e4c1d7e2dfdb91b102becfaf22700cb86dc3e3553d9bebd7bab5a3803",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "460441eea1764ca438e29fa0e38aa0d2607402f753cb656a4ab0da9223eda494",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "2315941a13291c277dac9f65e75ead56386440d3907e0540bf157ae70f188347",
        ),
        "linux-arm": _artifact(
            platform = "linux-arm",
            sha256 = "25af344f46348958baa1c758cdf3b204ede3ddc483be1171ed3738d47efd0aae",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "57fa17b6bb040a3788116557a72579f2180ea9620b4ee8a9b7244e5901df02e4",
        ),
        "linux-i386": _artifact(
            platform = "linux-i386",
            sha256 = "ac9cbef2ec1237e2723ee8d3a92d1c4525a2da7cecc11336ba67de9bb6b473f0",
        ),
        "linux-ppc64le": _artifact(
            platform = "linux-ppc64le",
            sha256 = "53a578b84155d31c3e62dd93a88586b75e876dae82c7912c895ee5a574fa6209",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "f1a3190adecc26270bbef4f3ab2d1a56509f9d8df95413cdd6e3151f6f367862",
        ),
    },
    "3.10.3": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "77a94ebd37eab4d14aceaf30a372348917830358430fcd7e09761eed69f08be5",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "4f3490654349d6fee8d4055862efdaaf9422eca1ffd2a15393394fd948ae3377",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "950439759ece902157cf915b209b8d694e6f675eaab5099fb7894f30eeaee9a2",
        ),
        "linux-arm": _artifact(
            platform = "linux-arm",
            sha256 = "dca718eb68c72c51fc7157c4c2ebc8ce7ac79b95fc9355c5427ded99e913ec4c",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "260cda5ff2ed5d01dd0fd6e7e09bc80126e00d8bdc55f3269d05129e32f6f99d",
        ),
        "linux-i386": _artifact(
            platform = "linux-i386",
            sha256 = "592e98a492cb782aa7cd67e9afad76e51cd68f5160367600fe542c2d96aa0ad4",
        ),
        "linux-ppc64le": _artifact(
            platform = "linux-ppc64le",
            sha256 = "93cdf398abc68e388d1b46d49d8e1197544930ecd3e81cc58d0a87a4579d60ed",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "5d97aa26830c1cd6c520815255882f148040587fd7cdddb61ef66e4c081566e0",
        ),
    },
    "3.11.0": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "5a3d13545a302eb2623236353ccd3eaa01150c869f4d7f7a635073847fd7d932",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "f4717f8d1dab79bace3ff5d9d48bebef62310421fd479205ef54a56204f97415",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "6c3440d829a56071a4386dd3ce6254eab113bc9b1fe924a6ee99f7ff869b9e0b",
        ),
        "linux-arm": _artifact(
            platform = "linux-arm",
            sha256 = "cddbef72886c82a123038883f32b04e739cc4bd7b9e5f869740d51e50a38be01",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "57d36ff801ce8c0201ce9917c5a2d3b4da33e5d4ea154320962c7d6fb13e1f2c",
        ),
        "linux-i386": _artifact(
            platform = "linux-i386",
            sha256 = "fad897763f3b965bc4d75c8f95748ebc0330a5859d9ea170a4885571facacdb1",
        ),
        "linux-ppc64le": _artifact(
            platform = "linux-ppc64le",
            sha256 = "6481a51095f408773212ab53edc2ead8a70e39eba67c2491e11c4229a251f9b5",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "55477fa4295fb3043835397a19e99a138bb4859fbe7cd2d099de28df9d8786f1",
        ),
    },
    "3.11.1": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "2548a90e5cc957ccc5016b47060665a9d2cd4d5b4d61dcc32f5de3144d103826",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "43d0198a7a2ea2639caafa81bb0596c97bee2d4e40df50b36202343eb4d5c46b",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "0b1be96b66fab4770526f136f5f1a385a47c41923d33aab0dcb500e0f6c1bf7c",
        ),
        "linux-arm": _artifact(
            platform = "linux-arm",
            sha256 = "77b797134ea9a121f2ede9d159a43a8b3895a9ff92cc24b71b77fb726d9eba6d",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "919173e8fb7a3b54d76af9feb92e49e86d5a80c5185020bae8c393fa0f0de1e8",
        ),
        "linux-i386": _artifact(
            platform = "linux-i386",
            sha256 = "1581a4ce9d0014c49a3b2c6421f048d5c600e8cceced636eb4559073c335af0b",
        ),
        "linux-ppc64le": _artifact(
            platform = "linux-ppc64le",
            sha256 = "6ab8f2e253c115b17eda1e10e96d1637047efd315e9807bcb1d0d0bcad278ab7",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "bc37d5d283e57c5dfa94f92ff704c8e273599ff8df3f8132cef5ca73f6a23d0a",
        ),
    },
    "3.11.2": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "404938fd2c6eff9e0dab830b0db943fca9e1572cd3d7ee40904705760faa390f",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "f61a3aa55827de2d8c64a2063fd744b618b443ed063871b79f52069e90813151",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "781d826daec584f9d50a01f0f7dadfd25a3312217a14aa2fbb85107b014ac8ca",
        ),
        "linux-arm": _artifact(
            platform = "linux-arm",
            sha256 = "444b65100e224beee0a3a3a54cb19dad37388fa9217ab2782ba63551c4a2e128",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "0a60baac83c3106017666864e664f52a4e16fbd578ac009f9a85456a9241c5db",
        ),
        "linux-i386": _artifact(
            platform = "linux-i386",
            sha256 = "dee028554da99415eb19b4b1fd423db390f8f4d49e4c4cbc3df5d6f658ec7f38",
        ),
        "linux-ppc64le": _artifact(
            platform = "linux-ppc64le",
            sha256 = "04cbb8d053f2d8023e5cc6b771e9fa384fdd341eb7193a0fb592b7e2a036bf3d",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "bca0c5b99a0e6621032f1767e61a1723b86c5f4ef565fa58be8be6d619a4276a",
        ),
    },
    "3.11.3": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "9d029df37664b50e427442a600e4e065fa75fd74dac996c831ac68359654b2c4",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "267e4d50b68e8854b9cc44517da9ab2f47dec39787fed9f7eba42080d61ac7f8",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "ca2d5d40d4cdfb9a3a6205dd803b5bc8def00bd2f13e5526c127e9b667974a89",
        ),
        "linux-arm": _artifact(
            platform = "linux-arm",
            sha256 = "0816db0efd033c78c3cc1c37506967947b01965b9c0739fe13ec2b1eea08f601",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "9f58e707dcbe9a3b7885c4e24ef57edfb9794490d72705b33a93fa1f3572cce4",
        ),
        "linux-i386": _artifact(
            platform = "linux-i386",
            sha256 = "09c111400d953eda371aaa6e5f0f65acc7af6c6b31a9f327414bb6f0756ea215",
        ),
        "linux-ppc64le": _artifact(
            platform = "linux-ppc64le",
            sha256 = "9f0a8299152ec714cee7bdf61066ba83d34d614c63e97843d30815b55c942612",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "ae146d2a90600c6958bc801213daef467237cf475e26ab3f476dfb8e0d9549b7",
        ),
    },
    "3.12.0": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "8223beb796ff19b59e615387d29be8c2025c5d3aea08485a262583de7ba7d708",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "879f61d2ad245cb3f5018ab8b66a87619f195904a4df3b077c98ec0780e36c37",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "da36e117d6dbc57c8ec5bab2283222fbd108db86c83389eebe045ad1ef3e2c3b",
        ),
        "linux-arm": _artifact(
            platform = "linux-arm",
            sha256 = "1d1d3b0b6397825c3f91ec5f5e66eb415a4199ccfaf063ca399d64854897f3f0",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "658839fed8f9be2169f5df68e55cb2f0aa731a50df454caf183186766800bbd0",
        ),
        "linux-i386": _artifact(
            platform = "linux-i386",
            sha256 = "3815f4caa054be027ae1d6c17a302ee1fd7ff805d631f7ff75c9d093c41ab389",
        ),
        "linux-ppc64le": _artifact(
            platform = "linux-ppc64le",
            sha256 = "252d952b0e1b4ed2013710ddedf687ed5545d9f95a4fd72de0ff9617ff69155c",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "52138ba8caec50c358c7aee41aac28d6a8a037878ada3cf5ce6c1049fc772547",
        ),
    },
    "3.12.1": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "f487b5d8132bd2091378258a3029e33ee10f71575b2167cdfeaf6d0144d20938",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "e82e0433589b1b5170807d6fec75baedba40620458510bbd30cdb9d2246415fe",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "1a7074f58ef7190f74ce6db5db0b70e355a655e2013c4d5db2317e63fa9e3dea",
        ),
        "linux-arm": _artifact(
            platform = "linux-arm",
            sha256 = "6ae6d1cb3b9f7faf68d5cd327eaa53c432f01e8fd67edba4e4c744dcbd8a0883",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "50548d4fedef9d8d01d1ed5a2dd5c849271d1017127417dc4c7ef6777ae68f7e",
        ),
        "linux-i386": _artifact(
            platform = "linux-i386",
            sha256 = "983addced237a8eb921c2c8c953310d92031a6ce4599632edbe7cdb2c95a701e",
        ),
        "linux-ppc64le": _artifact(
            platform = "linux-ppc64le",
            sha256 = "32b25dba14549a4097bf3dd62221cf6df06279ded391f7479144e3a215982aaf",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "9040f8f37c90600a51db4934c04bc9c2adc058cb2161e20b5193b3ba46de10fa",
        ),
    },
    "3.12.2": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "6e8bfc84a640e0dc47cc49cfc2d0a482f011f4249e2dff2a7e23c7ef2df1b64e",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "b60ee16847e28879ae298a20ba4672fc84f741410f438e645277205824ddbf55",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "2b6efaa009891d3703869f4be80ab86faa33fa83d9d5ff2f6492a8aebe97b219",
        ),
        "linux-arm": _artifact(
            platform = "linux-arm",
            sha256 = "39cc63757901eaea5f0c30b464d3253a5d034ffefcb9b9d3c9e284887b9bb381",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "cfafbae85c31afde88c69f0e5053610c8c455826081c1b2d665d9b44c31b3759",
        ),
        "linux-i386": _artifact(
            platform = "linux-i386",
            sha256 = "ecd4d0f3feb0f8448ed11e182e493e74c36572e1b52d47ecbed3e99919c8390d",
        ),
        "linux-ppc64le": _artifact(
            platform = "linux-ppc64le",
            sha256 = "fb0313bfd6ec5a08d8755efb7e603f76633726160040434fd885e74b6c10e387",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "35dc439baad85728dafd2be0edd4721ae5b770c5cf72c3adf9558b1415a9cae6",
        ),
    },
    "3.12.3": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "1bdbbeec5a12dd0c1cd4efd8948a156d33e1e2f51140e2a51e1e5e7b11b81d47",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "240b0a7da9cae208000eff3d3fb95e0fa1f4903d95be62c3f276f7630b12dae1",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "1b2313cd198d45eab00cc37c38f6b1ca0a948ba279c29e322bdf426d406129b5",
        ),
        "linux-arm": _artifact(
            platform = "linux-arm",
            sha256 = "6b67cf5fc441c1fcb4a860629b2ec613d0e6c8ac536600445f52a033671e985e",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "79ef06935fb47e432c0c91bdefd140e5b543ec46376007ca14a52e5ed3023088",
        ),
        "linux-i386": _artifact(
            platform = "linux-i386",
            sha256 = "cb789c4753bf66c8426f6be4091349c0780aaf996af0a1de48318f9f8d6b7bc8",
        ),
        "linux-ppc64le": _artifact(
            platform = "linux-ppc64le",
            sha256 = "8f2182ae53dd129a176ee15a09754fa942e9e7e9adab41fd60a39833686fe5e6",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "f3e2e9d69bb0549876aef6e956976f332e482592494874d254ef49c4862c5712",
        ),
    },
    "3.13.0": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "d44aa324ba6b2034e1f9eec34b80ec386a5e2c88a3db47f7276b3b5981ebd2a1",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "fda10c694f2e926d8b4195c12001e83413b598fb7a828c8b6751ae4a355e0ca6",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "138676351483e61d12dfade70da6c03d471bbdcac84eaadeb5e1d06fa114a24f",
        ),
        "linux-arm": _artifact(
            platform = "linux-arm",
            sha256 = "bb2cdde0d12c55f65e88e7c398e67463e74bc236f68b7f307a73174b35628c2e",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "d12a0e73a7dbff7d89d13e0c6eb73f5095f72d70faea30531941d320678904d2",
        ),
        "linux-i386": _artifact(
            platform = "linux-i386",
            sha256 = "f644910b9eb5f0a8427397c06dc0ddd9412925a0631decf2740363d38a8c9190",
        ),
        "linux-ppc64le": _artifact(
            platform = "linux-ppc64le",
            sha256 = "d9be0057c21ce5994885630340b4f2725a68510deca6e3c455030d83336e4797",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "8989f94407d31da2697a7354fba5f5c436b27ea193f76de6f1d37a51898a97a1",
        ),
    },
    "3.4.2": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "c33b7ee72b0006f23b33f5032b531dd609fff7b08a4324f9ba07722a4f3fec9a",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "cacde7768420dd41111a4630e047c231afa01f67e49cc0c6429563e024da4b98",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "486cad35b9ac1da88781847f2fcaaaed729e44705eb42593322e4b52d0f2c1a1",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "76ff3f8c21c9af5b80abdd87ec07629ad88dbfe6206decc4d3024f26398554b9",
        ),
    },
    "3.5.3": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "451ad70dfe286e3979c78ecf7074f4749d93644da8aa2cc778e2f969771f1794",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "2170a1a644a9e0b863f00c17b761ce33d4323da64fc74562a3a6df2abbf6cd70",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "e1348d94ce4caace43689ee2dfa5f8bcd8687c12053d9c13d79875b65d6b72aa",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "33fef4740b255b58a52e5504622068fd8a7d9aea19f1a84438f5cc1c5aade0d6",
        ),
    },
    "3.6.3": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "84a1ff17dd03340652d96e8be5172a921c97825fd278a2113c8233a4e8db5236",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "a50b499dbd0bbec90761d50974bf1e67cc6d503ea20d03b4a1275884065b7e9e",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "07c100849925623dc1913209cd1a30f0a9b80a5b4d6ff2153c609d11b043e262",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "6fe647628bc27e7ae77d015da4d5e1c63024f673062ac7bc11453ccc55657713",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "797d2abd603a2646f2fb9c3fabba46f2fabae5cbd1eb87c20956ec5b4a2fc634",
        ),
    },
    "3.7.2": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "5a0738afb1e194853aab00258453be8624e0a1d34fcc3c779989ac8dbcd59436",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "260d4b8bffcebc6562ea344dfe88efe252cf9511dd6da3cccebf783773d42aec",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "4ae30e48966aba5f807a4e140dad6736ee1a392940101e4d79ffb4ee86200a9e",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "b0214eabbb64791f563bd222d17150ce39bf4e2f5de49f49fdb456ce9ae8162f",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "299165f0af46bece9a61b41305cca8e8d5ec5319a4b694589cd71e6b75aca77e",
        ),
    },
    "3.8.1": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "3b6d87d360a51bf0f2344edd54e3580a8e8de2c4a4fd92eccef3e811f7e81bb3",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "5f0fea586781fb867b92c10133786949ab6a447f297d5c12e1e8f5dd3a9ed712",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "d643f48fe28eeb47ff68a1a7a26fc5142f348d02c8bc38d699674016716f61cd",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "dbf5118259717d86c57d379317402ed66016c642cc0d684f3505da6f194b760d",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "a75003fc692131652d3bd218dd4007692390a1dd156f11fd7668e389bdd8f765",
        ),
    },
    "3.8.2": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "25bb4a70b0d9538a97abb3aaa57133c0779982a8091742a22026e60d8614f8a0",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "dfddc0696597c010ed903e486fe112a18535ab0c92e35335aa54af2360077900",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "6cb9a48f72ab9ddfecab88d264c2f6508ab3cd42d9c09666be16a7bf006bed7b",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "238db7f55e887f9c1038b7e43585b84389a05fff5424e70557886cad1635b3ce",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "051959311ed5a3d49596b298b9e9618e2a0ad6a9270c134802f205698348ba5e",
        ),
    },
    "3.9.0": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "7e5a2f2a6696acf278ea17401ade5c35430e2caa57f67d4aa99c607edcc08f5e",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "22cf080ded5dd71ec15d33c13586ace9b6002e97518a76df628e67ecedd5aa70",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "1484ffb0c7a608d8069470f48b88d729e88c41a1b6602f145231e8ea7b43b50a",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "5c0aa709c5aaeedd190907d70f9012052c1eea7dff94bffe941b879a33873947",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "631d333bce5f2274c00af753d54bb62886cdb17a958d2aff698c196612c9e8cb",
        ),
    },
    "3.9.1": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "3cd0ad43154506ef65003bb871e71ab88d080b855ecbaa183e41f774bc7fb46e",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "df47fb682a3ddc9904ee5fe21e60a788cced3556df0496b46278644074b2618a",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "73df7ddd5ab05e96230304bf0e6e31484b1ba136d0fc22679345c0b4bd43f7ac",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "655dbceb4ab4b246af2214e669b9d44e3a35f170f39df8eebdb8d87619c585d1",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "9d6c1f4a2b328be15c548665e49e1628ebb4246258ab2cba6e0ee893b9881314",
        ),
    },
    "3.9.2": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "35d7ff8bea561831d78dce8f7bf614a7ffbcad3ff88d4c2f06a51bfa51c017e2",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "6250a6b92603a9c14194932e9dc22380ac423779519521452163493db33b68c8",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "3f5be38068a1829670440ccf00b3b6656fd90d0d9cfd4367539f3b13e4c20531",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "e4e2f9aad786042d903534e3131bc5300d245c24bbadf64fc46cca1728051dbc",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "d0d98a2a1f4794fcfc437000f89d337dc9278b6b7672f30e164f96c9413a7a74",
        ),
    },
    "3.9.3": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "ca3d57bb68135fa45a7acc2612d472e8ad01b78f49eaca57490aefef74a61c95",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "db20ee8758616e1d69e90aedc5eb940751888bdd2b031badf2080a05df4c9eb7",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "2d07360a9d93b18488f1ddb9de818b92ba738acbec6e1c66885a88703fa7b21c",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "59168c08c32293759005d0c509ce4be9038d7663827e05564c779e59658d8299",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "cdd24727d233e620ce6e8ec21646a6218bde94cf3d5f24e9c4ae6a114939975d",
        ),
    },
    "3.9.4": {
        "darwin-amd64": _artifact(
            platform = "darwin-amd64",
            sha256 = "fe5930feca6fd1bd2c57df01c1f381c6444d1c3d2b857526bf6cbfbd6bf906b4",
        ),
        "darwin-arm64": _artifact(
            platform = "darwin-arm64",
            sha256 = "a73d91751153169781b3ab5b4702ba1a2631fc8242eba33828b5905870059312",
        ),
        "linux-amd64": _artifact(
            platform = "linux-amd64",
            sha256 = "31960ff2f76a7379d9bac526ddf889fb79241191f1dbe2a24f7864ddcb3f6560",
        ),
        "linux-arm64": _artifact(
            platform = "linux-arm64",
            sha256 = "d24163e466f7884c55079d1050968e80a05b633830047116cdfd8ae28d35b0c0",
        ),
        "windows-amd64": _artifact(
            platform = "windows-amd64",
            sha256 = "7cdc1342bc1863b6d5ce695fbef4d3b0d65c7c5bcef6ec6adf8fc9aa53821262",
        ),
    },
}
