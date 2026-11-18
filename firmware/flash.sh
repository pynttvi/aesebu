#!/bin/sh
set -eu

usage() {
    printf '%s\n' 'Usage: firmware/flash.sh --list' \
        '       firmware/flash.sh [--write] ADAPTER_SERIAL BOARD_FIRMWARE.xe' \
        'Without --write, prints the selected adapter and image only.'
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    --list)
        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
        exec xflash --list-devices
        ;;
esac

write=false
if [ "${1:-}" = --write ]; then
    write=true
    shift
fi

[ "$#" -eq 2 ] || { usage >&2; exit 2; }
adapter=$1
image=$2

case "$adapter" in
    ''|-*|*[!a-zA-Z0-9_-]*) printf '%s\n' 'Provide a valid XTAG adapter serial.' >&2; exit 2 ;;
esac
case "$image" in
    *.xe) ;;
    *) printf '%s\n' 'Provide a board-specific .xe image.' >&2; exit 2 ;;
esac
case "$image" in
    /*) ;;
    *) image="./$image" ;;
esac
if [ ! -f "$image" ] || [ ! -r "$image" ] || [ ! -s "$image" ]; then
    printf 'Image is missing, unreadable, or empty: %s\n' "$image" >&2
    exit 2
fi

printf 'XTAG adapter: %s\nImage: %s\n' "$adapter" "$image"
if [ "$write" = false ]; then
    printf '%s\n' 'Dry run. Pass --write to program flash.'
    exit 0
fi

exec xflash --adapter-id "$adapter" "$image"
