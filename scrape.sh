#!/usr/bin/env bash

ROMSDIR="${SKYSCRAPER_ROMS_DIR:-/roms}"
if [ "${SKYSCRAPER_ROMS_TO_SUBDIR}" = "true" ]; then
    ROMSTOSUBDIR=true
else
    ROMSTOSUBDIR=false
fi

[ -n "${SKYSCRAPER_FRONTEND}" ] && FRONTEND="-f ${SKYSCRAPER_FRONTEND}"

DFLFLAGS=unattend,unattendskip
if [ "${SKYSCRAPER_NO_RELATIVE_PATHS}" != "true" ]; then
    DFLFLAGS="${DFLFLAGS},relative"
fi
FLAGS="--flags ${SKYSCRAPER_FLAGS:-"${DFLFLAGS}"}"

DEFAULT_MODULES="${SKYSCRAPER_MODULES:-thegamesdb}"
declare -A MODS_MAP
for line in $(echo "${SKYSCRAPER_PLATFORM_MODULES}" | tr ';' '\n'); do 
    sys=$(echo $line | cut -d ':' -f1)
    scrap=$(echo $line | cut -d ':' -f2)
    MODS_MAP[$sys]=$scrap
done

# $1 platform
get_scrapers() {
    echo "${MODS_MAP[$1]:-${DEFAULT_MODULES}}" | tr ',' ' '
}

# $1 platform
get_output_dir() {
    if ${ROMSTOSUBDIR}; then
        echo "$ROMSDIR/$1"
    elif [ -n "${SKYSCRAPER_GAMELIST_DIR}" ]; then
        if echo ${SKYSCRAPER_GAMELIST_DIR} | grep -q '^/'; then
            echo "$ROMSDIR/$1/$SKYSCRAPER_GAMELIST_DIR"
        else
            echo "$SKYSCRAPER_GAMELIST_DIR/$1"
        fi
    fi
}

# $1 platform
get_media_dir() {
    if [ -n "${SKYSCRAPER_MEDIA_DIR}" ]; then
        if echo ${SKYSCRAPER_MEDIA_DIR} | grep -q '^/'; then
            echo "$ROMSDIR/$1/$SKYSCRAPER_MEDIA_DIR"
        else
            echo "$SKYSCRAPER_MEDIA_DIR/$1"
        fi
    fi
}

# $1 platform
scrape() {
    platform="$1"
    if [ -z "$platform" ]; then
        echo "missing platform argument!" 2>&1
        return 1
    fi
    romsdir="$ROMSDIR/$platform"
    outputdir="$(get_output_dir "$platform")"
    mediadir="$(get_media_dir "$platform")"

    [ -n "$outputdir" ] && output="-g $outputdir" || output=""
    [ -n "$mediadir" ] && media="-o $mediadir" || media=""

    echo "scraping system: $platform"

    for scraper in $(get_scrapers $platform); do
        Skyscraper -p "$platform" -s "$scraper" -i "$romsdir" $FRONTEND $FLAGS
    done
    Skyscraper -p "$platform" -i "$romsdir" $output $media $FRONTEND $FLAGS
}

scrape_all() {
    for system in $(ls -p "$ROMSDIR" | grep '/$' | sed -e 's_/$__'); do
        scrape "$system"
    done
}


## main code

echo "perform global update"
scrape_all

echo "starting main loop..."

inotifywait -e create -e close_write -e moved_to --format "%w%f" -m -r -q "$ROMSDIR" | while read file; do
    if echo "$file" | grep -q "gamelist.xml\|${SKYSCRAPER_MEDIA_DIR:-/media/}"; then
        continue
    fi
    system="$(echo "${file#"$ROMSDIR"/}" | sed -e 's_/.*__')"
    echo "new file: $file"
    scrape "$system"
done
