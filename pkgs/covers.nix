{
  lib,
  stdenv,
  brave-unsandboxed,
  marp-cli,
  poppler-utils,
  twemoji,
  yq-go,
}:

let
  version = "1.0.0";

  # Get all covers from ".md" files under root "covers" directory
  covers = map (name: lib.removeSuffix ".md" name) (
    lib.attrNames (
      lib.filterAttrs (name: value: value == "regular" && lib.hasSuffix ".md" name) (
        builtins.readDir ../covers
      )
    )
  );

  # Helper function for building cover derivations
  mkCover = cover: stdenv.mkDerivation (finalAttrs: {
    inherit version;

    name = cover;

    # Build a custom-scoped source directory from relevant project directories
    src = lib.fileset.toSource {
      root = ../.;

      fileset = lib.fileset.unions [
        ../assets
        ../covers/${cover}.md
        ../.marprc
      ];
    };

    # Disable fixup of twemoji assets (2K+ SVG files)
    stripExclude = [
      "assets/twemoji"
    ];

    # Build dependencies
    nativeBuildInputs = [
      brave-unsandboxed
      marp-cli
      poppler-utils
      twemoji
      yq-go
    ];

    # Patch to make Marp look for twemoji locally
    patchPhase = ''
      yq -i '. + {"options":{"emoji":{"twemoji":{"base":"../assets/twemoji/"}}}}' .marprc
    '';

    # Before building, we copy Twemoji assets before building so that they can be included in the output PDF.
    preBuild = ''
      cp -R ${twemoji} assets/twemoji
    '';

    buildPhase = ''
      runHook preBuild

      marp covers/${cover}.md \
        --output=${cover}.pdf \
        --debug=true \
        --pdf \
        --browser=chrome \
        --browser-path=${lib.getExe brave-unsandboxed} \
        --allow-local-files
      ls -la
      pdftoppm -png -f 1 -l 1 ${cover}.pdf ${cover}
      ls -la

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      mv ${cover}-1.png $out/${cover}.png

      runHook postInstall
    '';
  });

  # Create list of derivations for all covers
  coversDrvs = lib.map (cover: mkCover cover) covers;
in

# Meta-derivation that builds all covers in a single output and exposes single covers as passthru attributes.
stdenv.mkDerivation (finalAttrs: {
  inherit version;

  name = "covers";
  # This is a "meta-derivation", there's no source
  src = null;
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  buildInputs = coversDrvs;

  installPhase = lib.concatLines (
    [ "mkdir -p $out" ]
    ++ (lib.map (coverDrv: ''
      cp ${coverDrv}/${coverDrv.name}.png $out
    '') coversDrvs)
  );

  # All covers are exposed as passthru attributes to allow building them one-by-one.
  # This allows building a single cover: nix build '.#covers.<cover>'
  passthru = lib.listToAttrs (lib.map (coverDrv: lib.nameValuePair coverDrv.name coverDrv) coversDrvs);
})
