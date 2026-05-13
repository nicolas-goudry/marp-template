{
  pkgs ? import <nixpkgs> { },
}:

let
  serve = pkgs.writeShellApplication {
    name = "serve";

    runtimeInputs = [
      pkgs.marp-cli
    ];

    text = ''
      find_root() {
        local curdir="''${1:-$PWD}"
        local flake="$curdir/flake.nix"

        if [[ "$curdir" == "/" ]]; then
          >&2 echo "ERROR: failed to find marp-deck-directory project root."
          exit 1
        fi

        if [[ -f "$flake" ]] && grep -q 'description = "Marp Deck Directory"' "$flake" 2>/dev/null; then
          echo "$curdir"
        else
          find_root "$(dirname "$curdir")"
        fi
      }

      marp --server "$(find_root)" --watch
    '';
  };
in
pkgs.mkShellNoCC {
  nativeBuildInputs =
    (with pkgs; [
      marp-cli
    ])
    ++ [
      serve
    ];

  shellHook = ''
    echo
    echo "#########################################################"
    echo "#                                                       #"
    echo "#   Welcome to Marp Deck Directory development shell!   #"
    echo "#                                                       #"
    echo "#########################################################"
    echo
    echo "If not done already, look up this project documentation on GitHub: https://github.com/nicolas-goudry/marp-deck-directory"
    echo
    echo "To serve all decks, use the 'serve' command, only available in this development shell:"
    echo
    echo -e "\t$ serve"
    echo
  '';
}
