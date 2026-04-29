pull_appimage version:
  wget -O "ktalk-{{version}}.AppImage" "https://st.ktalk.host/ktalk-app/linux/ktalk{{version}}x86_64.AppImage"
  nix hash file "ktalk-{{version}}.AppImage"

cleanup:
  rm *.AppImage
