{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
  ...
}:

let
  pname = "ktalk";
  version = "3.7.1";

  sources = {
    x86_64-linux = {
      suffix = "x86_64";
      hash = "sha256-DSIQuo60Rhdf7IRdoExSpJh7KqtnkKe/Qi0QsbfraVM=";
    };
    aarch64-linux = {
      suffix = "arm64";
      hash = "sha256-V5fsPFEGMrCU9/RWN+7Xpo3jRrtQt5XuzVi57BuCAVE=";
    };
  };

  system = stdenv.hostPlatform.system;
  source = sources.${system} or (throw "Unsupported system: ${system}");

  src = fetchurl {
    url = "https://st.ktalk.host/ktalk-app/linux/ktalk${version}${source.suffix}.AppImage";
    inherit (source) hash;
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
  mkDesktop = import ./desktop-helper.nix;
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = mkDesktop {
    inherit pname;
    inherit appimageContents;
  };

  meta = with lib; {
    description = "Kontur.Talk Desktop Client";
    mainProgram = pname;
    homepage = "https://kontur.ru/talk";
    downloadPage = "https://app.ktalk.ru/download/app";
    license = licenses.unfree;
    maintainers = with maintainers; [ blackfan321 ];
    platforms = builtins.attrNames sources;
  };
}
