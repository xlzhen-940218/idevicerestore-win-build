#!/usr/bin/env bash
set -euo pipefail  # 启用严格错误检查

# 颜色定义
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'
BLUE='\033[34m'; MAGENTA='\033[35m'; CYAN='\033[36m'
BOLD='\033[1m'; RESET='\033[0m'

# 路径定义
INSTALL_PREFIX="/usr/local"
BUILD_DIR="$HOME"

# 检测并安装依赖
install_dependencies() {
    local arch_suffix=""
    [[ "$1" == "x86" ]] && arch_suffix="i686" || arch_suffix="x86_64"

    declare -a packages=(
        base-devel git make libtool autoconf automake pkg-config libcurl-devel libzstd-devel
        "mingw-w64-${arch_suffix}-gcc"
        "mingw-w64-${arch_suffix}-curl"
        "mingw-w64-${arch_suffix}-zstd"
        "mingw-w64-${arch_suffix}-libzip"
    )

    echo -e "${BOLD}${CYAN}Checking dependencies...${RESET}"
    for pkg in "${packages[@]}"; do
        if pacman -Q "$pkg" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ $pkg 已安装${RESET}"
        else
            echo -e "${YELLOW}➤ 正在安装 $pkg...${RESET}"
            pacman -S --noconfirm --needed "$pkg" || {
                echo -e "${RED}✗ $pkg 安装失败${RESET}"
                return 1
            }
        fi
    done
}

# 选择构建架构
select_architecture() {
    PS3="请选择架构 (1-2): "
    options=("x86_64" "i686")
    
    echo -e "${BOLD}${CYAN}选择目标架构:${RESET}"
    select opt in "${options[@]}"; do
        case $opt in
            "x86_64")
                build_platform="x64"
                break
                ;;
            "i686")
                build_platform="x86"
                break
                ;;
            *) echo -e "${RED}无效选项 $REPLY${RESET}";;
        esac
    done

    export PKG_CONFIG_PATH="${INSTALL_PREFIX}/${build_platform}/idevicerestore/lib/pkgconfig"
    echo -e "${GREEN}▶ 已选择 ${build_platform} 架构${RESET}"
}

# 克隆仓库
clone_repo() {
    local repo=$1

    echo "cd ${BUILD_DIR}"
    cd "${BUILD_DIR}"

    if [[ ! -d "${BUILD_DIR}/${repo}" ]]; then
        echo -e "${BLUE}➤ 正在克隆 ${repo}...${RESET}"


        git clone --depth 1 "https://github.com/libimobiledevice/${repo}.git" \
            || { echo -e "${RED}✗ 克隆 ${repo} 失败${RESET}"; return 1; }
    else
        echo -e "${GREEN}✓ ${repo} 已存在${RESET}"
        git -C "${BUILD_DIR}/${repo}" pull
    fi
}

# 构建模块
build_module() {
    local module=$1
    local build_dir="${BUILD_DIR}/${module}/build/${build_platform}"

    echo -e "${BOLD}${MAGENTA}🚀 开始构建 ${module}${RESET}"
    
    # 创建构建目录
    mkdir -p "$build_dir" || return 1
    cd "$build_dir" || return 1

    # 生成配置
    ../../autogen.sh \
        --prefix="${INSTALL_PREFIX}/${build_platform}/idevicerestore" \
        --without-cython \
        --enable-shared \
        || { echo -e "${RED}✗ ${module} 配置失败${RESET}"; return 1; }

    # 编译安装
    make -j$(nproc) && make install || {
        echo -e "${RED}✗ ${module} 构建失败${RESET}"
        return 1
    }

    echo -e "${GREEN}✅ ${module} 构建成功${RESET}"
}

main() {
    # 选择架构
    select_architecture
    
    # 安装依赖
    install_dependencies "$build_platform" || exit 1

    # 构建模块列表
    modules=(
        libplist libimobiledevice-glue libusbmuxd 
        libtatsu libimobiledevice libirecovery idevicerestore
    )

    # 主构建流程
    for module in "${modules[@]}"; do
        clone_repo "$module" || continue
        build_module "$module" || { 
            echo -e "${RED}⚠ 关键模块构建失败，终止执行${RESET}"
            exit 1
        }
    done

    echo -e "${BOLD}${GREEN}🎉 所有组件构建完成！${RESET}"
}

main "$@"
