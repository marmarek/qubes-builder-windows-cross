#!/bin/sh
# default installer build
# called from Makefile.Windows at the end of dist-package

shopt -s nullglob

WIXPATH=/opt/wix
WINEMU=wine

export DISPLAY=:0
#export WINEARCH=win32 WINEPREFIX=$HOME/wine
#export WINEDEBUG=-all WINEARCH=win32

DIFXLIB="Z:/opt/wix/difxapp_$DDK_ARCH.wixlib"
#DIFXLIB="../../../../../../../opt/wix/difxapp_$DDK_ARCH.wixlib"
MSIARCH=$DDK_ARCH
MSIOS=$DDK_DIST

if [ -r version ]; then
    export VERSION=$(<version)
elif [ -r "$DIST_SRC/version" ]; then
    export VERSION=$(<../version)
fi

# msm or msi extension is the script's parameter
if [ "$1" = "msm" ]; then
    MSISUFFIX=-$MSIOS$MSIARCH$MSIBUILD
    MSIEXT=.msm
else
    MSISUFFIX=-$MSIOS$MSIARCH-$VERSION$MSIBUILD
    MSIEXT=.msi
fi

export MSIOS MSIARCH
export WIN_BUILD_TYPE=fre

set -x

build() {
    FILENAME="$1"
    MSINAME=$FILENAME$MSISUFFIX
    MSIOUT=$MSINAME$MSIEXT

    $WINEMU "$WIXPATH/candle.exe" "$FILENAME.wxs" -arch "$MSIARCH" -ext WixUIExtension -ext WixDifxAppExtension -ext WixIIsExtension
    $WINEMU "$WIXPATH/light.exe" -sval -o "$MSIOUT" "$FILENAME.wixobj" -ext WixUIExtension -ext WixDifxAppExtension -ext WixIIsExtension -ext WixUtilExtension "$DIFXLIB"

    # FIXME: This is not an ideal way to check for errors because the output file may be created
    # even if wix fails to merge something in. We can't rely on wix warnings (errorlevel) because
    # some of them are unavoidable (eg. when merging MSVCRT redistributables).
    if ! [ -f "$MSIOUT" ]; then
       exit 1
    fi
}

bundle() {
    FILENAME="$1"
    MSINAME=$FILENAME$MSISUFFIX
    MSIOUT=$MSINAME.exe

    $WINEMU "$WIXPATH/candle.exe" "$FILENAME.wxb" -arch "$MSIARCH" -ext WixUIExtension.dll -ext WixBalExtension.dll
    $WINEMU "$WIXPATH/light.exe" -o "$MSIOUT" "$FILENAME.wixobj" -ext WixUIExtension.dll -ext WixBalExtension.dll

    # FIXME: This is not an ideal way to check for errors because the output file may be created
    # even if wix fails to merge something in. We can't rely on wix warnings (errorlevel) because
    # some of them are unavoidable (eg. when merging MSVCRT redistributables).
    if ! [ -f "$MSIOUT" ]; then
       exit 1
    fi
}

if [ -n "$WIN_CROSS_WIX_SOURCES" ]; then
    for f in $WIN_CROSS_WIX_SOURCES; do
        build ${f%.wxs}
    done

    for f in $WIN_CROSS_WIX_BUNDLES; do
        bundle ${f%.wxb}
    done
else
    # Iterate over all installer source files.
    for f in *.wxs; do
        build ${f%.wxs}
    done

    # Build bundles if present.
    for f in *.wxb; do
        bundle ${f%.wxb}
    done
fi

# Return 0 without checking errorlevel because wix warnings can cause it to return nonzero values.
# If there's an error we catch it below.
exit 0

