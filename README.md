<div align="center">
<img src="catbase-fang.jpg" alt="CatBase Logo" style="zoom:25%;" />

# CatBase Programming Language

**为 AI 应用研发而生的现代编程语言** — 极小运行环境下可替代 C，支持 Python 风格语法，编译为高性能本地二进制。

[![Official Website](http://img.shields.io/badge/-catbase--lang.com-2ea44f?style=for-the-badge)](http://catbase-lang.com)
[![Company](https://img.shields.io/badge/-dorobot.net-ff69b4?style=for-the-badge)](http://dorobot.net)
[![Language](https://img.shields.io/badge/language-CatBase-blue.svg?style=for-the-badge)]()
[![Backend](https://img.shields.io/badge/backend-Zig-orange.svg?style=for-the-badge)](https://ziglang.org/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg?style=for-the-badge)]()

[English](#) · [简体中文](#) · [官方文档](doc/catbase.md) · [官网](http://catbase-lang.com) · [公司官网](http://dorobot.net)

</div>

---

## ✨ 简介

**CatBase** 是一种全新的静态类型编程语言，专为 AI 应用研发与快速开发而设计，由来自中国的**钟声**设计并研发。它的语法类似 Python，但比 Python 更简单、更易学；同时能够编译为本地可执行文件，具有优异的运行性能，特别适合在**极小运行环境**下替代 C 语言。

> **记住 5 个不同，就能顺畅使用 CatBase：**
> 1. 程序块不再受制于缩进规则，而是使用 `{}` 大括号。
> 2. 不依赖解释器，直接编译为本地二进制代码。
> 3. 无需学习 C 指针和内存管理，用 Python 语法即可编写 C 才能编写的程序。
> 4. **强类型**：变量必须声明类型，函数返回值必须声明类型，类型名称**大小写敏感**。
> 5. 可方便调用 `.so`/`.a` 库，自身也可编译为 `.so`/`.a` 库。

CatBase 编程语言是为 Ai 应用研发而生，极小运行环境下可以替代 c，支持 python 语法。

---

## 🚀 主要特性

- 🪶 **极简语法** — Python 风格，零缩进烦恼
- ⚡ **本地性能** — 编译为原生二进制，无运行时解释器
- 🧠 **AI 友好** — 专为 AI 应用研发设计
- 🌐 **网络编程** — TCP / UDP / HTTP / WebSocket 全套支持
- 🧵 **多线程** — 线程、互斥锁、消息队列、协程
- 📁 **文件操作** — 简洁的文件读写 API
- 🎵 **音频处理** — 录音、播放、WAV 文件保存
- 🔌 **串口通信** — RS-232 / USB 转串口
- 📦 **导入系统** — 模块化代码组织
- 🛠️ **C 互操作** — 轻松调用 `.so` / `.a` 库
- 📊 **JSON 处理** — 内置 JSON 解析与序列化
- ⏱️ **时间函数** — 毫秒级和高精度计时

---

## 📦 详细安装指南

### 环境要求

| 项目 | 要求 | 说明 |
|------|------|------|
| 操作系统 | Linux（推荐 Ubuntu 20.04+ / Debian 11+） | Windows 需通过 WSL 或原生 Windows 版本 |
| Zig 编译器 | 0.14.1+ | 由 `setup-deps.sh` 自动安装 |
| C 编译器 | gcc / clang | 编译 Zig 运行时需要 |
| 依赖库 | alsa-lib（可选） | 音频录制/播放功能 |
| 工具 | curl 或 wget | 下载 Zig 安装包 |

### 快速安装（Linux）

```bash
# 1. 解压源码包
$ tar -zxvf ./catbase_v0.0.6.tar.gz

# 2. 进入项目目录
$ cd catbase_v0.0.6

# 3. 运行依赖安装脚本
$ ./setup-deps.sh

# 4. 编译你的第一个 CatBase 程序
$ ./bin/catbasecc ./examples/test_aa_HelloWorld.cat
 Compiling ./examples/test_aa_HelloWorld.cat...
 Invoking CatBase bin compiler...
 Compilation successful.

# 5. 运行生成的二进制文件
$ ./test_aa_HelloWorld
Hello world!
```

### 第一个程序

创建 `hello.cat`：

```cat
def main(args: list[str]) {
    print("Hello world!")
}
```

编译并运行：

```bash
$ ./bin/catbasecc hello.cat
$ ./hello
Hello world!
```

### 卸载

```bash
# 删除 Zig 安装
$ sudo rm -rf /usr/local/zig

# 删除 CatBase 编译产物
$ rm -f test_aa_HelloWorld *.o runtime/*.zig runtime/*.o
```

---

## 📖 代码示例

### 基础语法

```cat
# 变量声明（强类型）
name: str = "CatBase"
version: float = 0.6
count: int = 100
items: list[int] = [1, 2, 3, 4, 5]

# 函数定义
def add(a: int, b: int) -> int {
    return a + b
}

def main(args: list[str]) {
    # 打印
    print("Hello, " + name + "!")
    print("Version: " + str(version))

    # 条件分支
    if count > 50 {
        print("many")
    } else {
        print("few")
    }

    # 循环
    for i in range(0, 5) {
        print(str(i))
    }
}
```

### 文件操作

```cat
def main(args: list[str]) {
    f: any = file("data.txt", "w")
    write(f, "Hello, CatBase!")
    close(f)

    f2: any = file("data.txt", "r")
    content: str = read(f2)
    print(content)
    close(f2)
}
```

### 网络编程（HTTP）

```cat
def main(args: list[str]) {
    resp: str = http_get("http://api.example.com/data", 5000)
    print(resp)
}
```

### 多线程

```cat
def worker(id: int) {
    print("Worker " + str(id) + " started")
    sleep(1)
    print("Worker " + str(id) + " done")
}

def main(args: list[str]) {
    thread worker(1)
    thread worker(2)
    thread worker(3)
}
```

### JSON 处理

```cat
def main(args: list[str]) {
    data: dict[str, any] = {
        "name": "CatBase",
        "version": 0.6,
        "tags": ["compiler", "language", "ai"]
    }

    json_str: str = json_dumps(data)
    print(json_str)

    parsed: dict[str, any] = json_loads(json_str)
    print(parsed["name"])
}
```

> 📚 完整语法参考请查看 [**CatBase 编程语言参考手册**](doc/catbase.md)

---

## 🔧 配置（conf/config.conf）

通过 `conf/config.conf` 可以调整编译器行为，包括 Zig 路径、优化级别、错误显示方式等。

### 完整配置示例

```ini
// CatBase Configuration File

[zig]
// Zig compiler installation path (for Linux)
path = /usr/local/zig

// Zig compiler installation path (for Windows)
win_path = D:\CatBase_worksp\tools\zig

// Download URL (optional, will use default if empty)
download_url = https://ziglang.org/download/0.14.1/zig-aarch64-linux-0.14.1.tar.xz

[compiler]
// Target operating system: Linux or Windows
os = Linux

// Directory for generated runtime files
runtime_dir = runtime

// Optimization level: ReleaseFast, ReleaseSmall, ReleaseSafe
optimization = ReleaseSmall

// Whether to skip generating .o files during compilation
no_emit_obj = true

// Whether to keep Zig intermediate files (.zig) after compilation
keep_zig_files = true

// Whether to show raw Zig compiler errors
show_zig_errors = true
```

### 配置项详细说明

| 配置项 | 取值范围 | 默认值 | 说明 |
|--------|----------|--------|------|
| `[zig] path` | 任意目录路径 | `/usr/local/zig` | Linux 下 Zig 安装路径，`setup-deps.sh` 会安装到这里 |
| `[zig] win_path` | 任意目录路径 | `D:\CatBase_worksp\tools\zig` | Windows 下 Zig 安装路径 |
| `[zig] download_url` | HTTP(S) URL | aarch64 Linux 包 | `setup-deps.sh` 下载 Zig 的 URL  x86 平台可改为 `zig-x86_64-linux-0.14.1.tar.xz` |
| `[compiler] os` | `Linux` / `Windows` | `Linux` | 目标操作系统 |
| `[compiler] runtime_dir` | 相对路径 | `runtime` | 生成的 Zig 运行时文件输出目录 |
| `[compiler] optimization` | `ReleaseFast` / `ReleaseSmall` / `ReleaseSafe` | `ReleaseSmall` | Zig 优化模式：<br>• `ReleaseFast` - 最快执行速度<br>• `ReleaseSmall` - 最小可执行文件体积<br>• `ReleaseSafe` - 完整运行时安全检查 |
| `[compiler] no_emit_obj` | `true` / `false` | `true` | 是否跳过生成 `.o` 目标文件 |
| `[compiler] keep_zig_files` | `true` / `false` | `true` | 是否在 `runtime/` 目录保留 `.zig` 源文件 |
| `[compiler] show_zig_errors` | `true` / `false` | `true` | 是否显示原始 Zig 编译器错误 |

### 源码映射功能（show_zig_errors）

`show_zig_errors` 控制编译错误显示策略：

**当 `show_zig_errors = true` 时**（推荐开发时使用）：

- ✅ 显示 .cat 源码映射（带行号和上下文）
- ✅ 同时显示原始 Zig 编译器错误

**当 `show_zig_errors = false` 时**（推荐生产环境）：
- ✅ 只显示 .cat 源码映射
- ❌ 隐藏原始 Zig 错误（更清洁的输出）

启用后，Zig 编译错误会自动反向映射到对应的 `.cat` 源文件行号和上下文：

```
============================================================
CatBase compilation error:
============================================================

Error #1:
  --> examples/test.cat:3
  |
  | 2 |     x: int = 0
 >| 3 |     x.nonexistent_method()
  | 4 |     print(x)
  |
------------------------------------------------------------
Analysis: Type mismatch - check that method exists on this type.

============================================================

============================================================
Original Zig compiler output:
============================================================
runtime/test.zig:61:6: error: no field or member function named
    'nonexistent_method' in 'i64'
    x.nonexistent_method();
    ~^~~~~~~~~~~~~~~~~~~
============================================================
```

### 性能调优建议

| 场景 | 推荐配置 |
|------|----------|
| 开发调试 | `optimization = ReleaseSafe`<br>`keep_zig_files = true`<br>`show_zig_errors = true` |
| 生产部署 | `optimization = ReleaseSmall`<br>`no_emit_obj = true`<br>`keep_zig_files = false` |
| 性能基准测试 | `optimization = ReleaseFast`<br>`no_emit_obj = true` |

---

## 🧪 运行测试套件

```bash
# 编译并运行 examples 下所有测试
$ for f in examples/test_*.cat; do
    ./bin/catbasecc "$f" && echo "PASS: $f" || echo "FAIL: $f"
done
```

也可以使用仓库提供的测试脚本：

```bash
$ ./checkCatbasecc.sh
```

---

## 🛣️ 路线图

CatBase 将持续迭代优化，未来计划支持：

- [ ] 更多的内置数据类型
- [ ] 更丰富的标准库
- [ ] 跨平台支持（Windows、macOS 等）
- [ ] 更好的 IDE 支持
- [ ] 包管理与在线仓库
- [ ] 性能优化与体积缩减

我们相信，CatBase 将成为一门实用、高效、易学的编程语言，帮助更多开发者实现他们的创意。

---

## 👤 关于作者

**CatBase** 编程语言由来自中国的**钟声**设计并研发。钟声同时也是中国珠海的**豆子机器人科技** (<http://dorobot.net>) 公司的创始人。

**豆子机器人科技** (<http://dorobot.net>) 是一家专注于人工智能和机器人技术的创新公司，致力于开发智能化解决方案。CatBase 作为公司内部使用的编程语言，最初是为了解决项目开发中遇到的效率和性能问题而创建的。

> CatBase 编程语言是为 AI 应用研发而生，极小运行环境下可以替代 C，支持 Python 语法。

---

## 🙏 致谢

感谢以下人员对 CatBase 的支持与贡献：

- 🎓 **所有 CatBase 语言的爱好者** — 感谢你们的选择和信任
- 🌐 **开源社区** — CatBase 是站在巨人肩膀上的作品
  - 🦎 **Zig 语言团队** — 创造了如此优秀的编译工具链
  - 🐍 **Python 社区** — 为 CatBase 提供了语法的灵感与参考
  - ⚙️ **C 语言生态** — 为 CatBase 提供了性能优化的参考
  - 💬 **CatBase 社区** — 为 CatBase 提供了反馈和建议
- 🏢 **中国广东珠海的豆子机器人科技公司** (<http://dorobot.net>) — 为 CatBase 提供了资金支持

---

## 📞 联系我们

| 渠道 | 链接 |
|------|------|
| 🌐 CatBase 官方网站 | <http://catbase-lang.com> |
| 🏢 豆子机器人科技 | <http://dorobot.net> |
| 📖 完整文档 | [doc/catbase.md](doc/catbase.md) |
| 🐛 问题反馈 | [GitHub Issues](../../issues) |
| 💡 功能建议 | [GitHub Discussions](../../discussions) |

---

## 📄 许可证

本项目采用 **MIT 许可证** — 详见 [LICENSE](LICENSE) 文件。

---

<div align="center">

**如果 CatBase 对你有帮助，请给一个 ⭐ Star！**

Made with ❤️ in 珠海 · [catbase-lang.com](http://catbase-lang.com) · [dorobot.net](http://dorobot.net)
