{
  pkgs ? import <nixpkgs> { },
}:

let
  projectRoot = ./.;

  serve = pkgs.writeShellApplication {
    name = "serve";

    runtimeInputs = [
      pkgs.marp-cli
    ];

    text = ''
      pushd ${projectRoot} >/dev/null
      marp --server . --watch
      popd >/dev/null
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
