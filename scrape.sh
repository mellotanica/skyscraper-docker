#!/usr/bin/env bash

ROMSDIR="${SKYSCRAPER_ROMS_DIR:-/roms}"
if [ "${SKYSCRAPER_ROMS_TO_SUBDIR}" = "true" ]; then
    ROMSTOSUBDIR=true
else
    ROMSTOSUBDIR=false
fi
CACHEDIR="/cache"
TIMESTAMP_DIR="$CACHEDIR"/lastupdate

[ -n "${SKYSCRAPER_FRONTEND}" ] && FRONTEND="-f ${SKYSCRAPER_FRONTEND}"

DFLFLAGS=unattend,unattendskip
if [ "${SKYSCRAPER_NO_RELATIVE_PATHS}" != "true" ]; then
    DFLFLAGS="${DFLFLAGS},relative"
fi
FLAGS="--flags ${SKYSCRAPER_FLAGS:-"${DFLFLAGS}"}"

DEFAULT_MODULES="${SKYSCRAPER_MODULES:-thegamesdb}"

# $1 platform
get_scrapers() {
    SCRAPERS="$(for line in $(echo "${SKYSCRAPER_PLATFORM_MODULES}" | tr ';' '\n'); do 
        if [ "$(echo $line | cut -d ':' -f1)" = "$1" ]; then
            echo $line | cut -d ':' -f2
            break
        fi
    done)"
    if [ -z "$SCRAPERS" ]; then
        SCRAPERS="${DEFAULT_MODULES}"
    fi
    echo "${SCRAPERS}" | tr ',' ' '
}

# $1 platform
get_actual_roms_folder() {
    if ${ROMSTOSUBDIR}; then
        echo "$ROMSDIR/$1/roms"
    else
        echo "$ROMSDIR/$1"
    fi
}

# $1 platform
get_output_dir() {
    if ${ROMSTOSUBDIR}; then
        echo "$ROMSDIR/$1"
    elif [ -n "${SKYSCRAPER_GAMELIST_DIR}" ]; then
        if echo ${SKYSCRAPER_GAMELIST_DIR} | grep -q '^/'; then
            echo "$SKYSCRAPER_GAMELIST_DIR/$1"
        else
            echo "$ROMSDIR/$1/$SKYSCRAPER_GAMELIST_DIR"
        fi
    fi
}

# $1 platform
get_media_dir() {
    if [ -n "${SKYSCRAPER_MEDIA_DIR}" ]; then
        if echo ${SKYSCRAPER_MEDIA_DIR} | grep -q '^/'; then
            echo "$SKYSCRAPER_MEDIA_DIR/$1"
        else
            echo "$ROMSDIR/$1/$SKYSCRAPER_MEDIA_DIR"
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

    mkdir -p "$TIMESTAMP_DIR"
    touch "$TIMESTAMP_DIR/$system"
}

get_all_systems() {
    ls -p "$ROMSDIR" | grep '/$' | sed -e 's_/$__'
}

scrape_all() {
    for system in $(get_all_systems); do
        scrape "$system"
    done
}

system_from_rom_file() {
    echo "${file#"$ROMSDIR"/}" | sed -e 's_/.*__'
}

## main code

if [ "${SKYSCRAPER_RUN_GLOBAL_UPDATE}" == 'true' ]; then
    echo "perform global update"
    scrape_all
else
    for system in $(get_all_systems); do
        if [ -f "$TIMESTAMP_DIR/$system" ]; then 
            # if there are files newer than the last scrape process of this system, scrape again
            if [ -n "$(find "$ROMSDIR/$system" -newer "$TIMESTAMP_DIR/$system")" ]; then
                scrape "$system"
            fi
        else
            # if no scrape has happened before, run scraping process
            scrape "$system"
        fi
    done
fi

echo "starting main loop"
inotifywait -e create -e close_write -e moved_to --format "%w%f" -m -r -q "$ROMSDIR" | while read file; do
    if echo "$file" | grep -q "gamelist.xml\|${SKYSCRAPER_MEDIA_DIR:-/media/}"; then
        continue
    fi
    echo "new file: $file"
    scrape "$(system_from_rom_file "$file")"
done
