{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  bc,
  nukeReferences,
}:

stdenv.mkDerivation {
  pname = "rtl8821au";
  version = "${kernel.version}-unstable-2024-03-16";

  src = fetchFromGitHub {
    owner = "morrownr";
    repo = "8821au-20210708";
    rev = "168ac48174067e17ffb9f8b15ab802f37447dacc";
    hash = "sha256-eB9RCoU5jg5fgZkfcef9fsQ6tyD8gTPD+wYcR6PbWNw=";
  };

  nativeBuildInputs = [
    bc
    nukeReferences
  ] ++ kernel.moduleBuildDependencies;

  hardeningDisable = [
    "pic"
    "format"
  ];

  env.NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-pointer-types";

  makeFlags =
    [
      "ARCH=${stdenv.hostPlatform.linuxArch}"
      ("CONFIG_PLATFORM_I386_PC=" + (if stdenv.hostPlatform.isx86 then "y" else "n"))
      (
        "CONFIG_PLATFORM_ARM_RPI="
        + (if (stdenv.hostPlatform.isAarch32 || stdenv.hostPlatform.isAarch64) then "y" else "n")
      )
    ]
    ++ lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
      "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    ];

  prePatch = ''
    substituteInPlace ./Makefile \
      --replace /lib/modules/ "${kernel.dev}/lib/modules/" \
      --replace /sbin/depmod \# \
      --replace '$(MODDESTDIR)' "$out/lib/modules/${kernel.modDirVersion}/kernel/net/wireless/"
  '';

  preInstall = ''
    mkdir -p "$out/lib/modules/${kernel.modDirVersion}/kernel/net/wireless/"
  '';

  postInstall = ''
    nuke-refs $out/lib/modules/*/kernel/net/wireless/*.ko
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "rtl8821AU and rtl8812AU chipset driver with firmware";
    homepage = "https://github.com/morrownr/8821au";
    license = licenses.gpl2Only;
    platforms = lib.platforms.linux;
    maintainers = with maintainers; [ plchldr ];
  };
}
