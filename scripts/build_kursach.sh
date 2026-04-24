#!/usr/bin/env bash
set -e

OUTPUT_DIR=""
TMP_DIR=""
BIN_DIR=""
CLEAN=0
SKIP_DEPS=0
SKIP_AUTOGEN=0

usage() {
    echo "Usage: $0 -o <output_dir> [-t <temp_dir>] [-b <bin_dir>] [--cleanup] [--skip-deps] [--skip-autogen]"
    echo ""
    echo "  -o, --output    Output directory (required)"
    echo "  -t, --tmpdir    Directory for temp files (default: ./tmp)"
    echo "  -b, --bin       Directory with/for kursach-autogen binary (default: ./bin)"
    echo "  --cleanup       Remove temp build dirs after build"
    echo "  --skip-deps     Skip dependency verification"
    echo "  --skip-autogen  Skip kursach-autogen check and build"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            [[ -z "${2-}" ]] && { echo "Error: --output requires a value"; usage; }
            OUTPUT_DIR="$2"; shift 2 ;;
        -t|--tmpdir)
            [[ -z "${2-}" ]] && { echo "Error: --tmpdir requires a value"; usage; }
            TMP_DIR="$2"; shift 2 ;;
        -b|--bin)
            [[ -z "${2-}" ]] && { echo "Error: --bin requires a value"; usage; }
            BIN_DIR="$2"; shift 2 ;;
        --cleanup)
            CLEAN=1; shift ;;
        --skip-deps)
            SKIP_DEPS=1; shift ;;
        --skip-autogen)
            SKIP_AUTOGEN=1; shift ;;
        -h|--help)
            usage ;;
        *)
            echo "Error: unknown argument '$1'"; usage ;;
    esac
done

[[ -z "$OUTPUT_DIR" ]] && { echo "Error: --output is required"; usage; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(pwd)"
TMP_DIR="${TMP_DIR:-$ROOT_DIR/tmp}"
BIN_DIR="${BIN_DIR:-$ROOT_DIR/bin}"

if [ "$SKIP_DEPS" != "1" ]; then
    echo "==> Verify dependencies"
    "$SCRIPT_DIR/verify_dependencies.sh" || {
        echo "Error: dependencies missing. Use --skip-deps to bypass."
        exit 1
    }
fi

if [ "$SKIP_AUTOGEN" != "1" ]; then
    AUTOGEN_BIN="$BIN_DIR/kursach-autogen"
    if [ -x "$AUTOGEN_BIN" ]; then
        echo "==> kursach-autogen found: $AUTOGEN_BIN"
    else
        echo "==> kursach-autogen not found, building..."
        mkdir -p "$BIN_DIR"
        "$SCRIPT_DIR/build_kursach_autogen.sh" -o "$BIN_DIR" -t "$TMP_DIR/autogen_build"
        if [ "$CLEAN" = "1" ]; then
            rm -rf "$TMP_DIR/autogen_build"
        fi
    fi
fi

echo "==> Build tasks"
mkdir -p "$OUTPUT_DIR"
CLEAN_FLAG=""
[ "$CLEAN" = "1" ] && CLEAN_FLAG="--cleanup"
"$SCRIPT_DIR/build_tasks.sh" -i "$ROOT_DIR/tasks" -o "$OUTPUT_DIR/tasks" $CLEAN_FLAG

echo "==> Build course paper PDF"
KURSACH_SRC="$ROOT_DIR/kursach"
KURSACH_TMP="$TMP_DIR/kursach_out"
mkdir -p "$TMP_DIR"
rm -rf "$KURSACH_TMP"

( cd "$KURSACH_SRC" && "$AUTOGEN_BIN" kursach.yaml --output "$KURSACH_TMP" )

PDF_SRC="$KURSACH_TMP/main.pdf"
if [ -f "$PDF_SRC" ]; then
    cp "$PDF_SRC" "$OUTPUT_DIR/kursach.pdf"
    echo "==> PDF copied to $OUTPUT_DIR/kursach.pdf"
else
    echo "Error: kursach.pdf not found in $KURSACH_TMP"
    exit 1
fi

if [ "$CLEAN" = "1" ]; then
    rm -rf "$KURSACH_TMP"
    rm -rf "$TMP_DIR"
fi

echo "==> All done. Output: $OUTPUT_DIR"
