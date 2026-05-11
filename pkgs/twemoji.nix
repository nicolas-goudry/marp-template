{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  name = "twemoji";
  version = "14.0.3";

  src = fetchFromGitHub {
    owner = "twitter";
    repo = "twemoji";
    rev = "v${finalAttrs.version}";
    hash = "sha256-wIjdsl/bnmlF8i/qHmJI+YBurXieLFVa5CBzG++OIlw=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontFixup = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R assets/* $out

    runHook postInstall
  '';

  meta = {
    description = "Twitter emoji assets";
    homepage = "https://github.com/twitter/twemoji";
    license = lib.licenses.mit;
    sourceProvenance = lib.sourceTypes.fromSource;
    maintainers = [ lib.maintainers.nicolas-goudry ];
    platforms = lib.platforms.all;
  };
})
