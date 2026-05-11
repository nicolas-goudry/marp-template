{
  pkgs ? import <nixpkgs> { },
}:

let
  lib = pkgs.lib;

  # Get all deck variants from ".md" files under "slides" directory
  variants = map (name: lib.removeSuffix ".md" name) (
    lib.attrNames (
      lib.filterAttrs (name: value: value == "regular" && lib.hasSuffix ".md" name) (
        builtins.readDir ./slides
      )
    )
  );

  # Wrapper script to disable Brave sandboxing
  # This is required so that Marp can actually run a browser from inside the Nix sandbox.
  # We disable:
  # - sandboxing (--no-sandbox and --disable-setuid-sandbox): sandboxing is not available in Nix build sandbox
  # - GPU (--disable-gpu)
  # - shared memory usage (--disable-dev-shm-usage): prefer temporary files
  brave-unsdbx =
    let
      name = "brave-unsandboxed";
    in
    pkgs.runCommandLocal name
      {
        nativeBuildInputs = with pkgs; [
          makeWrapper
          brave
        ];

        meta.mainProgram = name;
      }
      ''
        mkdir -p $out/bin

        cat > $out/bin/${name} <<'EOF'
        #!/bin/sh
        exec ${lib.getExe pkgs.brave} --no-sandbox --disable-setuid-sandbox --disable-gpu --disable-dev-shm-usage "$@"
        EOF

        chmod +x $out/bin/${name}
      '';

  # In-store twemoji assets to avoid referencing an online CDN
  # TODO: decide if this should be upstreamed into nixpkgs
  twemoji = pkgs.stdenv.mkDerivation (finalAttrs: {
    name = "twemoji";
    version = "14.0.3";

    src = pkgs.fetchFromGitHub {
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
  });

  # Helper function for building the deck derivation in various variants and output format
  mkDrv =
    variant: format:
    let
      isPDF = format == "pdf";
      infile = "${variant}.md";
      outfile = "${variant}.${format}";
    in

    assert lib.assertMsg (
      isPDF || format == "html"
    ) "Format must be 'html' or 'pdf'. Requested format (${format}) is invalid.";

    pkgs.stdenv.mkDerivation (finalAttrs: {
      name = "${variant}-${format}";

      # Build a custom-scoped source directory from relevant project directories
      src = lib.fileset.toSource {
        root = ./.;

        fileset = lib.fileset.unions [
          ./assets
          ./slides/${infile}
          ./.marprc
        ];
      };

      # Disable fixup of twemoji assets (2K+ SVG files)
      stripExclude = [
        "assets/twemoji"
      ];

      # Build dependencies
      nativeBuildInputs =
        with pkgs;
        [
          marp-cli
          twemoji
        ]
        # Only pull in unsandboxed Brave browser if rendering PDF format
        ++ lib.optional isPDF brave-unsdbx;

      # Patch to make Marp look for twemoji locally
      # NOTE: paths handling differs between PDF and HTML, hence different patches based on format
      patches =
        (lib.optional isPDF [
          ./.nix-patches/.marprc.twemoji-pdf.patch
        ])
        ++ (lib.optional (!isPDF) [
          ./.nix-patches/.marprc.twemoji-html.patch
        ]);

      # Before building, we fix assets paths when rendering PDF format and pull in twemoji assets:
      # - Assets paths must be relative to source Markdown file in PDF format, but we share them between variants so
      #   they are located at an upper level and referenced with "./assets" as if assets directory was at the same
      #   level. Hence we rewrite the paths to traverse up directory tree.
      # - Twemoji assets are needed BEFORE building to be included in the output PDF.
      preBuild = ''
        cp -R ${twemoji} assets/twemoji
      '';

      # Build deck to requested output format
      buildPhase = ''
        runHook preBuild

        flags=("--output=${outfile}" "--debug=true")
        [[ "${format}" == "pdf" ]] && flags+=(
          "--pdf"
          "--browser=chrome"
          "--browser-path=${lib.getExe brave-unsdbx}"
          "--allow-local-files" # This is required so that PDF rendering can access assets to include in output PDF
        )

        marp ''${flags[*]} slides/${infile}

        runHook postBuild
      '';

      # Install built file(s) in output directory
      # NOTE: PDF rendering is a single file bundling everything, while HTML requires "external" assets along it
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        mv ${outfile} $out
        [[ "${format}" == "html" ]] && cp -R assets $out

        runHook postInstall
      '';

      preFixup = ''
        [[ "${format}" == "html" ]] && substituteInPlace $out/${outfile} --replace-fail "../assets" "./assets"
      '';
    });
in
# Create HTML and PDF variants for all deck variants
lib.foldl' (
  acc: variant:
  acc
  // {
    "${variant}-html" = mkDrv variant "html";
    "${variant}-pdf" = mkDrv variant "pdf";
  }
) { } variants
