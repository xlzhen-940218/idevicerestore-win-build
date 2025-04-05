#!/bin/bash
set -euo pipefail

# 配置工作目录
WORKDIR="$HOME/libimobiledevice"
echo "创建工作目录：$WORKDIR"
mkdir -p "$WORKDIR" && cd "$WORKDIR"

# 安装编译依赖
echo "安装系统依赖..."
brew install libtool autoconf automake

# 配置Python虚拟环境
echo "配置Python虚拟环境..."
python3 -m venv .venv
source .venv/bin/activate
pip3 install --upgrade pip
pip3 install cython

# 定义编译函数
compile_library() {
    local lib_name="$1"
    local repo_url="https://github.com/libimobiledevice/${lib_name}.git"

    echo "▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄"
    echo "█ 开始编译 $lib_name"
    echo "▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀"

    # 克隆仓库（带重试机制）
    if [ ! -d "$lib_name" ]; then
        echo "克隆代码库..."
        git clone "$repo_url" || {
            echo "克隆失败，尝试使用ssh协议..."
            git clone "git@github.com:libimobiledevice/${lib_name}.git"
        }
    else
        echo "检测到已有代码库，跳过克隆"
    fi

    # 构建流程
    (
        echo "进入构建目录..."
        cd "$lib_name" || exit 1
        mkdir -p build && cd build

        echo "生成构建配置..."
        ../autogen.sh --enable-shared

        echo "编译安装..."
        sudo make -j 8       # 并行编译加速
        sudo make install
    )
}

# 执行编译任务
compile_library "libplist"
compile_library "libimobiledevice-glue"
compile_library "libusbmuxd"
compile_library "libtatsu"
compile_library "libimobiledevice"
compile_library "libirecovery"
compile_library "idevicerestore"

echo "✅ 所有任务完成！建议执行以下操作："
echo "1. 保持虚拟环境：source $WORKDIR/.venv/bin/activate"
echo "2. 后续可继续编译其他依赖库"
echo "3. 退出虚拟环境：deactivate"
