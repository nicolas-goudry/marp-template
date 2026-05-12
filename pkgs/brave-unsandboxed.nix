{
  lib,
  stdenv,
  makeWrapper,
  brave,
}:

stdenv.mkDerivation (finalAttrs: {
  name = "brave-unsandboxed";
  version = brave.version;
  src = null;
  dontUnpack = true;
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    brave
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    makeWrapper ${lib.getExe brave} $out/bin/${finalAttrs.name} \
      --add-flag "--no-sandbox" \
      --add-flag "--disable-setuid-sandbox" \
      --add-flag "--disable-gpu" \
      --add-flag "--disable-dev-shm-usage"

    runHook postInstall
  '';

  meta = brave.meta // {
    mainProgram = finalAttrs.name;
    description = "Unsandboxed Brave browser";
    maintainers = [ lib.maintainers.nicolas-goudry ];
  };
})
