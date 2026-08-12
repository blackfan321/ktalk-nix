{ appimageContents, pname, desktopFile ? "${pname}.desktop" }:
''
  install -m 444 -D ${appimageContents}/${desktopFile} $out/share/applications/${pname}.desktop
  substituteInPlace $out/share/applications/${pname}.desktop \
    --replace-fail 'Exec=AppRun' 'Exec=${pname}'
  cp -r ${appimageContents}/usr/share/icons $out/share
''
