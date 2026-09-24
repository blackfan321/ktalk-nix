{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
  ...
}:

let
  pname = "ktalk";

  linuxSources = {
    version = "3.7.1";
    x86_64-linux = {
      suffix = "x86_64";
      hash = "sha256-DSIQuo60Rhdf7IRdoExSpJh7KqtnkKe/Qi0QsbfraVM=";
    };
    aarch64-linux = {
      suffix = "arm64";
      hash = "sha256-V5fsPFEGMrCU9/RWN+7Xpo3jRrtQt5XuzVi57BuCAVE=";
    };
  };

  darwinSources = {
    version = "3.7.0";
    aarch64-darwin = {
      hash = "sha256-q/nb/vqb6mryAfCoLxVlN88F3NZdP/14SZF3IOz2V2g=";
    };
  };

  system = stdenv.hostPlatform.system;

  platformNames =
    sources: lib.filter (name: lib.isAttrs sources.${name}) (builtins.attrNames sources);

  meta = with lib; {
    description = "Kontur.Talk Desktop Client";
    mainProgram = pname;
    homepage = "https://kontur.ru/talk";
    downloadPage = "https://app.ktalk.ru/download/app";
    license = licenses.unfree;
    maintainers = with maintainers; [ blackfan321 ];
    platforms = platformNames linuxSources ++ platformNames darwinSources;
  };
in
if stdenv.isLinux then
  let
    source = linuxSources.${system} or (throw "Unsupported system: ${system}");
    inherit (linuxSources) version;
    src = fetchurl {
      url = "https://st.ktalk.host/ktalk-app/linux/ktalk${version}${source.suffix}.AppImage";
      inherit (source) hash;
    };
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
else if stdenv.isDarwin then
  let
    source = darwinSources.${system} or (throw "Unsupported system: ${system}");
    inherit (darwinSources) version;
  in
  stdenv.mkDerivation {
    inherit pname meta version;

    src = fetchurl {
      url = "https://st.ktalk.host/ktalk-app/mac/ktalk.${version}-mac.dmg";
      inherit (source) hash;
    };

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
else
  throw "Unsupported system: ${system}"
