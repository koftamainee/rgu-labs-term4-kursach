#!/usr/bin/env bash
set -e

missing=()

check_cmd() {
    local name="$1"
    local cmd="$2"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "OK: $name ($cmd)"
    else
        echo "MISSING: $name ($cmd)"
        missing+=("$name (command $cmd)")
    fi
}

check_pkgconfig() {
    local name="$1"
    local pkg="$2"
    if pkg-config --exists "$pkg" 2>/dev/null; then
        echo "OK: $name (pkg-config $pkg)"
    else
        echo "MISSING: $name (pkg-config $pkg)"
        missing+=("$name (pkg-config $pkg)")
    fi
}

check_latex_pkg() {
    local name="$1"
    local pkg="$2"
    if kpsewhich "$pkg.sty" >/dev/null 2>&1; then
        echo "OK: LaTeX $name ($pkg.sty)"
    else
        echo "MISSING: LaTeX $name ($pkg.sty)"
        missing+=("LaTeX $name ($pkg.sty)")
    fi
}

echo "=== C++ dependencies ==="
CXX=""
if command -v c++ >/dev/null 2>&1; then
    CXX="c++"
elif command -v g++ >/dev/null 2>&1; then
    CXX="g++"
elif command -v clang++ >/dev/null 2>&1; then
    CXX="clang++"
fi

if [ -n "$CXX" ]; then
    echo "OK: C++ compiler ($CXX)"
else
    echo "MISSING: C++ compiler"
    missing+=("C++ compiler")
fi

check_header() {
    local name="$1"
    local header="$2"
    if [ -n "$CXX" ] && echo "#include <$header>" | "$CXX" -E -x c++ - &>/dev/null; then
        echo "OK: $name ($header)"
    else
        echo "MISSING: $name ($header)"
        missing+=("$name (header $header)")
    fi
}

check_header "imgui" "imgui.h"
check_header "implot" "implot.h"

check_pkgconfig "Qt6" "Qt6Core"
check_pkgconfig "GLFW" "glfw3"
check_cmd "CMake" "cmake"

echo ""
echo "=== Rust dependencies ==="
check_cmd "cargo" "cargo"
check_cmd "rustc" "rustc"

echo ""
echo "=== LaTeX dependencies ==="
if command -v kpsewhich >/dev/null 2>&1; then
    check_latex_pkg "polyglossia" "polyglossia"
    check_latex_pkg "graphicx" "graphicx"
    check_latex_pkg "subcaption" "subcaption"
    check_latex_pkg "amsmath" "amsmath"
    check_latex_pkg "amssymb" "amssymb"
    check_latex_pkg "hyperref" "hyperref"
    check_latex_pkg "listings" "listings"
    check_latex_pkg "xcolor" "xcolor"
    check_latex_pkg "caption" "caption"
    check_latex_pkg "setspace" "setspace"
    check_latex_pkg "indentfirst" "indentfirst"
    check_latex_pkg "titlesec" "titlesec"
    check_latex_pkg "tocloft" "tocloft"
    check_latex_pkg "longtable" "longtable"
    check_latex_pkg "booktabs" "booktabs"
    check_latex_pkg "fancyhdr" "fancyhdr"
    check_latex_pkg "tcolorbox" "tcolorbox"
    check_latex_pkg "algorithm" "algorithm"
    check_latex_pkg "algpseudocode" "algpseudocode"
else
    echo "MISSING: kpsewhich not found, cannot check LaTeX packages"
    missing+=("kpsewhich")
fi

echo ""
if [ ${#missing[@]} -ne 0 ]; then
    echo "=== MISSING DEPENDENCIES ==="
    for m in "${missing[@]}"; do
        echo "  - $m"
    done
    exit 1
else
    echo "All dependencies satisfied."
    exit 0
fi
