{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShellNoCC {
  nativeBuildInputs = with pkgs; [
    marp-cli
  ];
}
