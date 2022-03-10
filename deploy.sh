#!/bin/bash

idms () {

export WINEDLLOVERRIDES="mscoree,mshtml="
export WINEARCH="win32"
export WINEPREFIX="/home/runner/.wine"
export WINEDEBUG="-all"

# Convert and copy icon which is needed for desktop integration into place:
wget -q https://github.com/mmtrt/idm_AppImage/raw/main/idm.png
for width in 8 16 22 24 32 36 42 48 64 72 96 128; do
    dir=icons/hicolor/${width}x${width}/apps
    mkdir -p $dir
    convert idm.png -resize ${width}x${width} $dir/idm.png
done

wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x ./appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage --appimage-extract &>/dev/null

WINE_VER="$(wget -qO- https://dl.winehq.org/wine-builds/ubuntu/dists/focal/main/binary-i386/ | grep wine-stable | sed 's|_| |g;s|~| |g' | awk '{print $5}' | tail -n1)"
wget -q https://github.com/mmtrt/WINE_AppImage/releases/download/continuous-stable/wine-stable_${WINE_VER}-x86_64.AppImage
chmod +x *.AppImage ; mv wine-stable_${WINE_VER}-x86_64.AppImage wine-stable.AppImage

# idm stable
stable_ver=$(wget "https://www.internetdownloadmanager.com/download.html" -qO- 2>&1 | grep -Po '=id.*[0-9]' | sed -r 's|=||')
stable_vers=$(wget "https://www.internetdownloadmanager.com/download.html" -qO- 2>&1 | grep -Po '=id.*[0-9]' | sed -r 's|=idman||;s|b|B|;s/./&./1;s/./&_/4;s/./&_/10')

wget -q "https://mirror2.internetdownloadmanager.com/$stable_ver.exe"

# Install app in WINEPREFIX
./wine-stable.AppImage "$stable_ver.exe" /skipdlgs ; sleep 5 ; killall wineserver || true

# log files
ls -al ; ls -al "$WINEPREFIX/drive_c/Program Files/Internet Download Manager/"

(cd "$WINEPREFIX/drive_c/Program Files/Internet Download Manager/" ; mv IDMIntegrator64.exe IDMIntegrator64.exe.bak ; mv IEMonitor.exe IEMonitor.exe.bak)
mv "$WINEPREFIX/drive_c/Program Files/Internet Download Manager" idm-stable/usr/share/idm
find "idm-stable/usr" -type d -execdir chmod 755 {} +
rm -rf "$WINEPREFIX" "*.exe"

cp idm.desktop idm-stable ; cp AppRun idm-stable ; sed -i -e 's|progVer=|progVer='"$stable_vers"'|g' idm-stable/AppRun

cp -r icons idm-stable/usr/share ; cp idm.png idm-stable

export ARCH=x86_64; squashfs-root/AppRun -v ./idm-stable -n -u "gh-releases-zsync|mmtrt|idm_AppImage|stable|idm*.AppImage.zsync" idm_${stable_ver}-${ARCH}.AppImage &>/dev/null

}

idmswp () {

idms ; rm ./idm*AppImage*

# Create WINEPREFIX
./wine-stable.AppImage ; sleep 5 ; killall wineserver || true

# Removing any existing user data
( cd "$WINEPREFIX" ; rm -rf users ) || true

cp -Rp $WINEPREFIX idm-stable/ ; rm -rf $WINEPREFIX ; rm ./*.AppImage

#( cd idm-stable ; wget -qO- 'https://gist.github.com/mmtrt/0a0712cbae05b2e3dc2aac338fcf95eb/raw/b3cddb7fba032796b1d347cd032664b53ec9d74c/idmw.patch' | patch -p1 )

export ARCH=x86_64; squashfs-root/AppRun -v ./idm-stable -n -u "gh-releases-zsync|mmtrt|idm_AppImage|stable-wp|idm*WP*.AppImage.zsync" idm_${stable_ver}_WP-${ARCH}.AppImage &>/dev/null

}

if [ "$1" == "stable" ]; then
    idms
    ( mkdir -p dist ; mv idm*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
elif [ "$1" == "stablewp" ]; then
    idmswp
    ( mkdir -p dist ; mv idm*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
fi
