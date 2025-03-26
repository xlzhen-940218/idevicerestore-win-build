# idevicerestore刷机工具自动化mingw编译脚本

### 主要功能特性

1. **依赖环境自动部署**  
   - 自动检测并安装编译所需的依赖库和工具链
   - 集成 MSYS2 基础运行环境配置

2. **架构灵活选择**  
   - 支持 x86/x64 双平台编译（注：x86 架构需使用特定版本的 MSYS2 环境）

3. **智能编译系统**  
   - 自动化编译 `idevicerestore` 核心程序
   - 同步编译其依赖项包括：
     * libimobiledevice
     * libirecovery
     * openssl 等关键组件

4. **跨平台兼容输出**  
   - 生成标准动态链接库 (DLL) 
   - 支持作为 `shared library` 被 Visual Studio 工程直接引用
   - 提供完整的头文件包含目录及 `.lib` 导入库
