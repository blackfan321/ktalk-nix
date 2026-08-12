{
  lib,
  appimageTools,
  fetchurl,
  ...
}:

let
  pname = "ktalk";
  version = "3.6.0";

  src = fetchurl {
    url = "https://st.ktalk.host/ktalk-app/linux/ktalk${version}x86_64.AppImage";
    hash = "sha256-naQaV5w/jKIyEUZOliKxJRZ7Q2guTdud+WTm2QTZEzo=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
  mkDesktop = import ./desktop-helper.nix;
in appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = mkDesktop {inherit pname; inherit appimageContents;};

  meta = with lib; {
    description = "KTalk client";
    longDescription = ''
      Desktop client for KTalk
    '';

    mainProgram = pname;
    homepage = "https://kontur.ru/talk";
    downloadPage = "https://app.ktalk.ru/download/app";
    license = licenses.unfree;
    maintainers = with maintainers; [ blackfan321 ];
    platforms = [ "x86_64-linux" ];
  };
}
