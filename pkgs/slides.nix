{
  lib,
  stdenv,
  brave-unsandboxed,
  marp-cli,
  twemoji,
  yq-go,
}:

let
  version = "1.0.0";

  # Get all deck variants from ".md" files under root "slides" directory
  variants = map (name: lib.removeSuffix ".md" name) (
    lib.attrNames (
      lib.filterAttrs (name: value: value == "regular" && lib.hasSuffix ".md" name) (
        builtins.readDir ../slides
      )
    )
  );

  # Helper function for building the deck derivation in various variants and output format
  mkVariant =
    variant: format:
    let
      isPDF = format == "pdf";
      isHTML = format == "html";
      infile = "${variant}.md";
      outfile = "${variant}.${format}";
    in

    assert lib.assertMsg (
      isPDF || isHTML
    ) "Format must be 'html' or 'pdf'. Requested format (${format}) is invalid.";

    stdenv.mkDerivation (finalAttrs: {
      inherit version;

      name = "${variant}-${format}";

      # Build a custom-scoped source directory from relevant project directories
      src = lib.fileset.toSource {
        root = ../.;

        fileset = lib.fileset.unions [
          ../assets
          ../slides/${infile}
          ../.marprc
        ];
      };

      # Disable fixup of twemoji assets (2K+ SVG files)
      stripExclude = [
        "assets/twemoji"
      ];

      # Build dependencies
      nativeBuildInputs = [
        marp-cli
        twemoji
        yq-go
      ]
      # Only pull in unsandboxed Brave browser if rendering PDF format
      ++ lib.optional isPDF brave-unsandboxed;

      # Patch to make Marp look for twemoji locally
      # NOTE: paths handling differs between PDF and HTML, hence different patches based on format
      patchPhase = (lib.optionalString isPDF ''
        yq -i '. + {"options":{"emoji":{"twemoji":{"base":"../assets/twemoji/"}}}}' .marprc
      '') + (lib.optionalString isHTML ''
        yq -i '. + {"options":{"emoji":{"twemoji":{"base":"assets/twemoji/"}}}}' .marprc
      '');

      # Before building, we copy Twemoji assets so that both PDF output format and HTML can use them. PDF rendering need
      # them before building so that they can be included in the output PDF, while HTML need them in the install phase
      # where they are copied along with the project assets.
      preBuild = ''
        cp -R ${twemoji} assets/twemoji
      '';

      # Build deck to requested output format
      buildPhase = lib.concatLines [
        ''
          runHook preBuild

          flags=("--output=${outfile}" "--debug=true")
        ''
        # When building in PDF output format, we explicitly set the Brave unsandboxed wrapper script as the browser path
        # and we allow local files so that PDF rendering can access assets to include in the generated PDF.
        (lib.optionalString isPDF ''
          flags+=(
            "--pdf"
            "--browser=chrome"
            "--browser-path=${lib.getExe brave-unsandboxed}"
            "--allow-local-files"
          )
        '')
        ''
          marp ''${flags[*]} slides/${infile}

          runHook postBuild
        ''
      ];

      # Install built file(s) in output directory
      installPhase = lib.concatLines [
        ''
          runHook preInstall

          mkdir -p $out
          mv ${outfile} $out
        ''
        # HTML output format doesn't bundle assets like PDF does, so we copy them in the derivation output directory
        (lib.optionalString isHTML ''
          cp -R assets $out
        '')
        ''
          runHook postInstall
        ''
      ];

      preFixup = lib.optionalString isHTML ''
        substituteInPlace $out/${outfile} --replace-fail "../assets" "./assets"
      '';

      passthru = {
        inherit variant format;
      };
    });

  # Create list of derivations for all deck variants/format combinations
  variantsDrvs = lib.flatten (
    lib.map (
      variant:
      lib.map (format: mkVariant variant format) [
        "html"
        "pdf"
      ]
    ) variants
  );
in

# Meta-derivation that builds all deck variants/format combinations in a single output and exposes single variants as
# passthru attributes.
stdenv.mkDerivation (finalAttrs: {
  inherit version;

  name = "slides";
  # This is a "meta-derivation", there's no source
  src = null;
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  buildInputs = variantsDrvs;

  # The final output will contain all variants generated files and a common assets directory
  #
  # The installation process is as follows:
  # - copy assets from the first variant: all variants share the same assets so we don't care, we take the first one
  # - for each variant derivation, copy the output file identified by <variant>.<format>
  installPhase = lib.concatLines (
    [
      ''
        mkdir -p $out
        cp -R ${lib.elemAt variantsDrvs 0}/assets $out
      ''
    ]
    ++ (lib.map (variantDrv: ''
      cp ${variantDrv}/${variantDrv.passthru.variant}.${variantDrv.passthru.format} $out
    '') variantsDrvs)
  );

  # All variants are exposed as passthru attributes to allow building them one-by-one. All variants get a dedicated
  # attribute set with attributes for each output format, like below:
  # { <variant> = { <format1> = drv; <format2> = drv; }; }
  # This allows building a single variant in a given format with: nix build '.#slides.<variant>.<format>'
  passthru = lib.foldl' (
    acc: variant:
    acc
    // {
      ${variant} = lib.listToAttrs (
        lib.map (variantDrv: lib.nameValuePair variantDrv.passthru.format variantDrv) (
          lib.filter (variantDrv: variantDrv.passthru.variant == variant) variantsDrvs
        )
      );
    }
  ) { } variants;
})
