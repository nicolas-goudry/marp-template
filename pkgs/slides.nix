{
  lib,
  stdenv,
  brave-unsandboxed,
  marp-cli,
  twemoji,
  yq-go,
}:

let
  getDeckCoverName = name: "${lib.removeSuffix ".md" name}.cover.md";

  # Get all decks from ".md" files under root "slides/" directory, excluding covers.
  # NOTE: covers are either named "cover.md" or "<deck-name>.cover.md".
  decks =
    lib.filter (name: lib.hasSuffix ".md" name && name != "cover.md" && name != getDeckCoverName name)
      (
        map (
          name:
          # listFilesRecursive returns absolute paths, so we strip away the path to decks' root directory (i.e. "slides/")
          # from the result to get relative path to decks.
          lib.removePrefix "/" (lib.removePrefix (toString ../slides) (toString name))
        ) (lib.filesystem.listFilesRecursive ../slides)
      );

  mkDeck =
    deck: format:
    let
      isPDF = format == "pdf";
      isHTML = format == "html";
      isCover = format == "cover";

      dirname = lib.dirOf deck;
      # Decks named "slides.md" are considered "self-contained": they should live in their own directory and can have
      # a companion "cover.md" file as well as deck-specific assets in an "assets/" subdirectory.
      # NOTE: deck-specific assets are not limited to self-contained decks, multiple decks can share deck-specific
      #       assets if they happen to have an "assets/" directory at the same level.
      isSelfContained = lib.hasSuffix "slides.md" deck;
      # Compute the relative path to repository's root from deck location.
      pathToRoot = lib.join "" (lib.map (_: "../") (lib.splitString "/" deck));

      # Find deck cover:
      # - if self-contained deck, look for "cover.md"
      # - else look for "<deck>.cover.md"
      # - else use deck
      coverName = getDeckCoverName deck;
      cover =
        let
          selfContainedCover = "${dirname}/cover.md";
          deckCover = "${dirname}/${coverName}";
        in
        if isSelfContained && lib.pathExists ../slides/${selfContainedCover} then
          selfContainedCover
        else if lib.pathExists ../slides/${deckCover} then
          deckCover
        else
          deck;

      # Compute deck name from path (used to set derivation and output file name):
      # - replace all path separators by dashes
      # - remove file extension (.md)
      # - if file is deeply nested and named "slides.md", use directory as name
      mkDeckName = name: lib.removeSuffix ".md" (lib.replaceString "/" "-" name);
      name = if isSelfContained then mkDeckName dirname else mkDeckName deck;

      infile = if isCover then cover else deck;
      outfile = "${name}.${if isCover then "png" else format}";
    in

    assert lib.assertMsg (
      isPDF || isHTML || isCover
    ) "Format must be 'html', 'pdf' or 'cover'. Requested format (${format}) is invalid.";

    stdenv.mkDerivation (finalAttrs: {
      name = "${name}-${format}";

      # Build a custom-scoped source directory from relevant project files/directories and deck path.
      src = lib.fileset.toSource {
        root = ../.;

        fileset = lib.fileset.unions [
          ../assets
          ../slides/${infile}
          # Load local marp config if it exists.
          (lib.fileset.maybeMissing ../.marprc)
          # Account for maybe missing deck-specific assets directory.
          (lib.fileset.maybeMissing ../slides/${dirname}/assets)
        ];
      };

      # Disable fixup of twemoji assets (2K+ SVG files).
      stripExclude = [
        "assets/twemoji"
      ];

      nativeBuildInputs = [
        marp-cli
        twemoji
        yq-go
      ]
      # Only pull in unsandboxed Brave browser if rendering PDF format.
      ++ lib.optional isPDF brave-unsandboxed;

      patchPhase =
        # PDF/Cover rendering needs assets paths to be relative to the source Markdown file:
        # - we configure twemoji's base to be in global assets (copy is done pre-build)
        # - we patch absolute assets references to point to global assets
        # NOTE: all other assets references should already be relative to the source Markdown file.
        (lib.optionalString (isPDF || isCover) ''
          touch .marprc
          yq -i '. + {"options":{"emoji":{"twemoji":{"base":"${pathToRoot}assets/twemoji/"}}}}' .marprc
          shopt -s globstar
          for css in **/*.css; do
            sed -i 's|\([^.]\)/assets|\1${pathToRoot}assets|g; s|^/assets|${pathToRoot}assets|g' $css
          done
        '')
        # HTML is rendered at root, so twemoji assets are at the same level.
        # NOTE: we don't patch source files here to avoid having to find what to patch, instead we patch assets paths
        #       in the install phase so that we only have to deal with the rendered HTML file.
        + (lib.optionalString isHTML ''
          touch .marprc
          yq -i '. + {"options":{"emoji":{"twemoji":{"base":"assets/twemoji/"}}}}' .marprc
        '');

      # Build deck to requested output format
      buildPhase = lib.concatLines [
        ''
          runHook preBuild

          # Twemoji assets are required BEFORE building so that PDF rendering can include them in the rendered PDF file
          cp -R ${twemoji} assets/twemoji

          # Common marp CLI flags
          flags=("--output=${outfile}" "--debug=true")
        ''
        # When building PDFs or covers, we explicitly set the Brave unsandboxed wrapper script as the browser path and
        # we allow local files so that rendering can access assets.
        (lib.optionalString (isPDF || isCover) ''
          flags+=(
            "--browser=chrome"
            "--browser-path=${lib.getExe brave-unsandboxed}"
            "--allow-local-files"
          )
        '')
        (lib.optionalString isPDF ''flags+=("--pdf")'')
        (lib.optionalString isCover ''flags+=("--image=png")'')
        ''
          HOME=$TMPDIR
          marp ''${flags[*]} slides/${infile}

          runHook postBuild
        ''
      ];

      # Install built file(s) in output directory.
      installPhase = lib.concatLines [
        ''
          runHook preInstall

          mkdir -p $out
          mv ${outfile} $out
        ''
        # HTML rendering requires assets to be bundled in output and paths must be adapted consequently:
        # - global assets are copied to root "assets/" directory
        # - global assets paths are replaced with the new relative location to root "assets/" directory, handling both
        #     directory-traversing paths (i.e. "../../../assets") and absolute paths (i.e. "/assets")
        # - deck-specific assets are copied to "assets/deck" directory to avoid collisions
        # - deck-specific assets paths (i.e. "./assets") are replaced with deck-specific assets path
        (lib.optionalString isHTML ''
          # Copy global assets
          cp -R assets $out

          # Handle deck-specific assets
          if [[ -d "slides/${dirname}/assets" ]]; then
            cp -R slides/${dirname}/assets $out/assets/deck
            # Replace exact "./assets" with deck-specific assets path (i.e. "assets/deck")
            sed -i 's|\([^.]\)\./assets|\1./assets/deck|g; s|^\./assets|./assets/deck|g' $out/${outfile}
          fi

          #######################################
          # Handle global assets path rewriting #
          #######################################

          # Replace any number of double-dot-slash prefixes to assets by relative
          # path to assets (i.e. "../assets" -> "./assets" / "../../../../../assets" -> "./assets")
          sed -Ei 's|(\.\./)+assets|./assets|g' $out/${outfile}

          # Replace absolute assets root path by relative path (i.e. "/assets" -> "./assets")
          sed -i 's|\([^.]\)/assets|\1./assets|g; s|^/assets|./assets|g' $out/${outfile}
        '')
        ''
          runHook postInstall
        ''
      ];
    });
in

assert lib.assertMsg (lib.length decks > 0) "No decks found in slides/.";

# Meta-derivation that builds all decks in a single output and exposes decks/formats combinations as passthru attributes.
stdenv.mkDerivation (finalAttrs: {
  name = "slides";

  # We only care about the global assets directory here.
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [ ../assets ];
  };
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  # Flat list of derivations produced in the passthru attribute (i.e. all deck derivations).
  buildInputs = lib.mapAttrsToListRecursiveCond (
    _: value: lib.isAttrs value && (!lib.isDerivation value)
  ) (_: value: value) finalAttrs.passthru;

  # The final output will contain all decks generated files and a common assets directory.
  #
  # The installation process is as follows:
  # - copy global assets to root "assets/" directory
  # - copy twemoji assets to "assets/twemoji"
  # - iterate over all decks generated formats to:
  #   - copy its main file
  #   - copy deck-specific assets to "assets/deck-<deck-name>"
  #   - patch paths to deck-specific assets to point to the new location
  installPhase = lib.concatLines (
    [
      ''
        mkdir -p $out
        cp -R assets $out
        cp -R ${twemoji} $out/assets/twemoji
      ''
    ]
    ++ (lib.map (
      deckDrv:
      let
        deckAssets = "deck-${lib.removeSuffix "-html" deckDrv.name}";
      in
      ''
        for deckFile in ${deckDrv}/*.{html,pdf,png}; do
          cp $deckFile $out

          if [[ "$deckFile" == *.html ]] && [[ -d "${deckDrv}/assets/deck" ]]; then
            cp -R ${deckDrv}/assets/deck $out/assets/${deckAssets}
            substituteInPlace "$out/$(basename "$deckFile")" --replace-warn assets/deck assets/${deckAssets}
          fi
        done
      ''
    ) finalAttrs.buildInputs)
  );

  # All decks are exposed as passthru attributes to allow building them one-by-one. All decks get a dedicated nested
  # attribute, following the directory tree, which is itself an attribute set matching output formats. Examples:
  # - given a deck located in foo/bar/baz.md, the deck is exposed as 'slides.foo.bar.baz.{html,pdf}'
  # - given a deck located in foo/bar/baz/slides.md, the deck is exposed as 'slides.foo.bar.baz.{html,pdf}'
  #
  # NOTE: deeply nested decks override upper ones, so if both previous examples were to exist at the same time, only
  #       foo/bar/baz/slides.md would be available. Similarly, if foo/bar.md or foo/bar/slides.md would exist in
  #       filesystem at the same time, they would not be available for build.
  passthru = lib.foldl' (
    acc: deck:
    lib.recursiveUpdate acc (
      lib.foldl'
        (
          acc': format:
          lib.recursiveUpdate acc' (
            lib.setAttrByPath (
              (lib.splitString "/" (
                if lib.hasSuffix "slides.md" deck then
                  lib.removeSuffix "/slides.md" deck
                else
                  (lib.removeSuffix ".md" deck)
              ))
              ++ [ format ]
            ) (mkDeck deck format)
          )
        )
        { }
        [
          "html"
          "pdf"
          "cover"
        ]
    )
  ) { } decks;
})
