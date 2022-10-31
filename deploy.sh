#!/bin/bash

idms () {

export WINEDLLOVERRIDES="mscoree,mshtml="
export WINEARCH="win32"
export WINEPREFIX="/home/runner/.wine"
export WINEDEBUG="-all"

wget -q "https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.0.3/appimage-builder-1.0.3-x86_64.AppImage" -O builder ; chmod +x builder

wget -q https://github.com/mmtrt/WINE_AppImage/releases/download/continuous-stable-4-i386/wine-stable-i386_4.0.4-x86_64.AppImage
chmod +x *.AppImage ; mv wine-stable-i386_4.0.4-x86_64.AppImage wine-stable.AppImage

# idm stable
stable_ver=$(wget "https://www.internetdownloadmanager.com/download.html" -qO- 2>&1 | grep -Po '=id.*[0-9]' | sed -r 's|=||')
stable_vers=$(wget "https://www.internetdownloadmanager.com/download.html" -qO- 2>&1 | grep -Po '=id.*[0-9]' | sed -r 's|=idman||;s|build||;s/./&./1;s/./&./4;s/./&./10')

wget -q "https://mirror2.internetdownloadmanager.com/$stable_ver.exe"

mkdir -p "AppDir/usr/share/icons" "AppDir/winedata" ;

cp idm.desktop AppDir ; cp wrapper AppDir ; sed -i -e 's|progVer=|progVer='"$stable_vers"'|g' AppDir/wrapper

cp idm.png AppDir/usr/share/icons ; cp idm.png AppDir

# Install app in WINEPREFIX
./wine-stable.AppImage "$stable_ver.exe" /skipdlgs ; sleep 5 ; killall wineserver || true

(cd "$WINEPREFIX/drive_c/Program Files/Internet Download Manager/" ; mv IDMIntegrator64.exe IDMIntegrator64.exe.bak ; mv IEMonitor.exe IEMonitor.exe.bak)
mv "$WINEPREFIX/drive_c/Program Files/Internet Download Manager" AppDir/usr/share/idm
find "AppDir/usr/share/idm" -type d -execdir chmod 755 {} +
rm -rf "$WINEPREFIX" "*.exe"

./builder --recipe idm.yml

}

idmswp () {

export WINEDLLOVERRIDES="mscoree,mshtml="
export WINEARCH="win32"
export WINEPREFIX="/home/runner/work/idm_AppImage/idm_AppImage/AppDir/winedata/.wine"
export WINEDEBUG="-all"

wget -q "https://gist.github.com/mmtrt/895168bd77a0a68be19788734fb31870/raw/f119ce7f5469e9f0fd0bbfa908c4c39d721187ff/idm.reg"

wget -q "https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.0.3/appimage-builder-1.0.3-x86_64.AppImage" -O builder ; chmod +x builder

wget -q https://github.com/mmtrt/WINE_AppImage/releases/download/continuous-stable-4-i386/wine-stable-i386_4.0.4-x86_64.AppImage
chmod +x *.AppImage ; mv wine-stable-i386_4.0.4-x86_64.AppImage wine-stable.AppImage

# idm stable
stable_ver=$(wget "https://www.internetdownloadmanager.com/download.html" -qO- 2>&1 | grep -Po '=id.*[0-9]' | sed -r 's|=||')
stable_vers=$(wget "https://www.internetdownloadmanager.com/download.html" -qO- 2>&1 | grep -Po '=id.*[0-9]' | sed -r 's|=idman||;s|build||;s/./&./1;s/./&./4;s/./&./10')

wget -q "https://mirror2.internetdownloadmanager.com/$stable_ver.exe"

mkdir -p "AppDir/usr/share/icons" "AppDir/winedata" test

cp idm.desktop AppDir ; mv wrapper AppDir ; sed -i -e 's|progVer=|progVer='"$stable_vers"'|g' AppDir/wrapper

cp idm.png AppDir/usr/share/icons ; cp idm.png AppDir

# Create WINEPREFIX
./wine-stable.AppImage wineboot ; sleep 5
# Install app in WINEPREFIX
./wine-stable.AppImage "$stable_ver.exe" /skipdlgs ; sleep 5 ; killall wineserver || true

(cd "$WINEPREFIX/drive_c/Program Files/Internet Download Manager/" ; mv IDMIntegrator64.exe IDMIntegrator64.exe.bak ; mv IEMonitor.exe IEMonitor.exe.bak)
mv "AppDir/winedata/.wine/drive_c/Program Files/Internet Download Manager" "AppDir/usr/share/idm"
find "AppDir/usr/share/idm" -type d -execdir chmod 755 {} +

# Apply registry
./wine-stable.AppImage regedit idm.reg ; sleep 1 ; rm *.reg

(cp -Rp AppDir/usr/share/idm test ; ./wine-stable.AppImage test/idm/IDMan.exe & sleep 5 ; killall IDMan.exe ; rm -rf ./test)

# Removing any existing user data
( cd "$WINEPREFIX" ; rm -rf users ) || true

mv AppDir/winedata/resources AppDir/winedata/.wine/drive_c/windows

echo "disabled" > $WINEPREFIX/.update-timestamp

sed -i 's/stable|/stable-wp|/' idm.yml

./builder --recipe idm.yml

}

if [ "$1" == "stable" ]; then
    idms
    ( mkdir -p dist ; mv idm*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
elif [ "$1" == "stablewp" ]; then
    idmswp
    ( mkdir -p dist ; mv idm*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
fi
