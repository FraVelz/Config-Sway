#!/usr/bin/env bash
##
## Script de previsualización de ranger (scope.sh).
## Se usa cuando use_preview_script=true en rc.conf.
## Códigos de salida: 0=preview, 1=sin preview, 2=texto plano, 5=fijar, 6/7=imagen.
##
set -o noclobber -o noglob -o nounset -o pipefail
IFS=$'\n'

FILE_PATH="${1}"              # Ruta completa del archivo resaltado
PV_WIDTH="${2}"               # Ancho del panel de vista previa (caracteres)
# shellcheck disable=SC2034
PV_HEIGHT="${3}"              # Alto del panel (no usado aquí)
IMAGE_CACHE_PATH="${4}"       # Ruta para cachear previsualización de imágenes
PV_IMAGE_ENABLED="${5}"       # "True" si imágenes habilitadas, "False" si no

FILE_EXTENSION="${FILE_PATH##*.}"
FILE_EXTENSION_LOWER="$(printf "%s" "${FILE_EXTENSION}" | tr '[:upper:]' '[:lower:]')"

HIGHLIGHT_SIZE_MAX=262143     # 256 KiB; archivos más grandes = texto plano
HIGHLIGHT_TABWIDTH=${HIGHLIGHT_TABWIDTH:-8}
HIGHLIGHT_STYLE=${HIGHLIGHT_STYLE:-pablo}
HIGHLIGHT_OPTIONS="--replace-tabs=${HIGHLIGHT_TABWIDTH} --style=${HIGHLIGHT_STYLE} ${HIGHLIGHT_OPTIONS:-}"
PYGMENTIZE_STYLE=${PYGMENTIZE_STYLE:-autumn}

## Por extensión: archivos, PDF, torrent, ODT, HTML, JSON, audio DSD/wavpack...
handle_extension() {
    case "${FILE_EXTENSION_LOWER}" in
        a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
        rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)
            atool --list -- "${FILE_PATH}" 2>/dev/null && exit 5
            bsdtar --list --file "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
        rar)
            unrar lt -p- -- "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
        7z)
            7z l -p -- "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
        pdf)
            pdftotext -l 10 -nopgbrk -q -- "${FILE_PATH}" - 2>/dev/null | fmt -w "${PV_WIDTH}" && exit 5
            mutool draw -F txt -i -- "${FILE_PATH}" 1-10 2>/dev/null | fmt -w "${PV_WIDTH}" && exit 5
            exiftool "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
        torrent)
            transmission-show -- "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
        odt|ods|odp|sxw)
            odt2txt "${FILE_PATH}" 2>/dev/null && exit 5
            pandoc -s -t markdown -- "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
        xlsx)
            xlsx2csv -- "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
        htm|html|xhtml)
            w3m -dump "${FILE_PATH}" 2>/dev/null && exit 5
            lynx -dump -- "${FILE_PATH}" 2>/dev/null && exit 5
            elinks -dump "${FILE_PATH}" 2>/dev/null && exit 5
            pandoc -s -t markdown -- "${FILE_PATH}" 2>/dev/null && exit 5
            ;;
        json)
            jq --color-output . "${FILE_PATH}" 2>/dev/null && exit 5
            python -m json.tool -- "${FILE_PATH}" 2>/dev/null && exit 5
            ;;
        dff|dsf|wv|wvc)
            mediainfo "${FILE_PATH}" 2>/dev/null && exit 5
            exiftool "${FILE_PATH}" 2>/dev/null && exit 5
            ;;
    esac
}

## Imágenes: rotación EXIF, fuentes (fontimage).
handle_image() {
    local mimetype="${1}"
    case "${mimetype}" in
        image/*)
            local orientation
            orientation="$(identify -format '%[EXIF:Orientation]\n' -- "${FILE_PATH}" 2>/dev/null)"
            if [[ -n "${orientation}" && "${orientation}" != 1 ]]; then
                convert -- "${FILE_PATH}" -auto-orient "${IMAGE_CACHE_PATH}" 2>/dev/null && exit 6
            fi
            exit 7;;
        application/font*|application/*opentype)
            local preview_png="/tmp/scope-$(basename "${IMAGE_CACHE_PATH%.*}").png"
            if fontimage -o "${preview_png}" --pixelsize 120 --fontname --pixelsize 80 \
               --text "  ABCDEFGHIJKLMNOPQRSTUVWXYZ  " --text "  abcdefghijklmnopqrstuvwxyz  " \
               --text "  0123456789  " "${FILE_PATH}" 2>/dev/null; then
                convert -- "${preview_png}" "${IMAGE_CACHE_PATH}" 2>/dev/null && rm -f "${preview_png}" && exit 6
            fi
            exit 1;;
    esac
}

## Por tipo MIME: RTF/DOC, DOCX/ePub, Excel, texto con highlight/bat/pygmentize, DjVu, vídeo/audio.
handle_mime() {
    local mimetype="${1}"
    case "${mimetype}" in
        text/rtf|*msword)
            catdoc -- "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
        *wordprocessingml.document|*/epub+zip|*/x-fictionbook+xml)
            pandoc -s -t markdown -- "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
        *ms-excel)
            xls2csv -- "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
        text/*|*/xml)
            if [[ "$(stat --printf='%s' -- "${FILE_PATH}" 2>/dev/null)" -gt "${HIGHLIGHT_SIZE_MAX}" ]]; then
                exit 2
            fi
            if [[ "$(tput colors 2>/dev/null)" -ge 256 ]]; then
                local pygmentize_format='terminal256' highlight_format='xterm256'
            else
                local pygmentize_format='terminal' highlight_format='ansi'
            fi
            env HIGHLIGHT_OPTIONS="${HIGHLIGHT_OPTIONS}" highlight --out-format="${highlight_format}" --force -- "${FILE_PATH}" 2>/dev/null && exit 5
            env COLORTERM=8bit bat --color=always --style=plain -- "${FILE_PATH}" 2>/dev/null && exit 5
            pygmentize -f "${pygmentize_format}" -O "style=${PYGMENTIZE_STYLE}" -- "${FILE_PATH}" 2>/dev/null && exit 5
            exit 2;;
        image/vnd.djvu)
            djvutxt "${FILE_PATH}" 2>/dev/null | fmt -w "${PV_WIDTH}" && exit 5
            exiftool "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
        image/*)
            exiftool "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
        video/*|audio/*)
            mediainfo "${FILE_PATH}" 2>/dev/null && exit 5
            exiftool "${FILE_PATH}" 2>/dev/null && exit 5
            exit 1;;
    esac
}

## Si no hay handler: mostrar salida de "file".
handle_fallback() {
    echo '----- Tipo de archivo -----' && file --dereference --brief -- "${FILE_PATH}" && exit 5
    exit 1
}

MIMETYPE="$(file --dereference --brief --mime-type -- "${FILE_PATH}")"
[[ "${PV_IMAGE_ENABLED}" == 'True' ]] && handle_image "${MIMETYPE}"
handle_extension
handle_mime "${MIMETYPE}"
handle_fallback

exit 1
