{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    # nativeBuildInputs is usually what you want -- tools you need to run
    nativeBuildInputs = [ 
	pkgs.gnumake
	pkgs.ocaml
	pkgs.dune_3
	pkgs.ocamlPackages.menhir
    ];
}
