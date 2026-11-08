{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
  fetchgit,
  fetchFromGitHub,
  dockerTools,
  ...
}:

let
  inherit (import ./flake/systems.nix) systems;

  system = stdenv.hostPlatform.system;

  sources = import ./_sources/generated.nix {
    inherit
      fetchgit
      fetchurl
      fetchFromGitHub
      dockerTools
      ;
  };

  pname = "ktalk";

  meta = with lib; {
    description = "Kontur.Talk Desktop Client";
    mainProgram = pname;
    homepage = "https://kontur.ru/talk";
    downloadPage = "https://app.ktalk.ru/download/app";
    license = licenses.unfree;
    maintainers = with maintainers; [ blackfan321 ];
    platforms = systems;
  };
in
if !(lib.elem system systems) then
  throw "Unsupported system: ${system}"
else if stdenv.hostPlatform.isLinux then
  let
    source =
      if stdenv.hostPlatform.isx86_64 then sources.ktalk-linux-x86_64 else sources.ktalk-linux-aarch64;
    inherit (source) version src;
    appimageContents = appimageTools.extract {
      inherit pname src version;
    };
    mkDesktop = import ./desktop-helper.nix;
  in
  appimageTools.wrapType2 {
    inherit
      pname
      src
      meta
      version
      ;

    extraInstallCommands = mkDesktop {
      inherit pname appimageContents;
    };
  }
else
  let
    inherit (sources.ktalk-darwin) version src;
  in
  stdenv.mkDerivation {
    inherit
      pname
      meta
      version
      src
      ;

    # hdiutil lives outside the Nix sandbox.
    __noChroot = true;

    dontBuild = true;
    dontFixup = true;

    sourceRoot = "Толк.app";

    unpackPhase = ''
      runHook preUnpack

      tmp=$(mktemp -d)
      /usr/bin/hdiutil attach "$src" -mountpoint "$tmp" -nobrowse -quiet
      cp -R "$tmp"/* ./
      /usr/bin/hdiutil detach "$tmp" -quiet
      rm -rf "$tmp"

      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/Applications/Толк.app"
      cp -R Contents "$out/Applications/Толк.app/"

      runHook postInstall
    '';
  }
