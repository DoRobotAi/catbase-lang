# CatBase 编程语言参考手册

CatBase编程语言是为Ai应用研发而生，极小运行环境下可以替代C并支持python语法。

CatBase是一个全新的编程语言，它是一种现代的、简洁的编程语言，专为教学和快速开发而设计。CatBase 可以将类似python简洁的CatBase代码编译为本地可执行文件，具有优异的性能。

CatBase，这个语言的语法类似于python，但是比python更简单，更易学。

请记住如下不同就可以顺畅的使用CatBase编程了：
1、程序块不再受制于讨厌的缩进规则，而是引入了大括号。
2、CatBase并不依赖于解释器，而是直接可以编译为二进制代码。
3、不需要学习c语言，也不需要关心指针和内存问题，用python的语法即可编写原来c语言才可以编写并编译的二进制可执行代码。
4、CatBase要求强类型，变量必须声明变量类型，函数返回值必须声明返回的变量类型，且类型名称大小写敏感。
5、可以方便地调用.so库和.a库，并且自身也可以编译成.so库和.a库。

CatBase语言的语法看起来像python，比如用def定义函数，但是与完整的python又有所不同，更像是限制版和改进版的python的一个全新的编程语言。

## 目录

1. [简介](#1-简介)
2. [基础语法](#2-基础语法)
3. [数据类型](#3-数据类型)
4. [运算符](#4-运算符)
5. [控制流](#5-控制流)
6. [函数](#6-函数)
7. [内置函数](#7-内置函数)
7.1 [打印函数](#71-打印函数)
7.2 [数学函数](#72-数学函数)
7.3 [类型转换函数](#73-类型转换函数)
7.4 [进制转换函数](#74-进制转换函数)
7.5 [字符函数](#75-字符函数)
7.6 [字符串函数](#76-字符串函数)
7.7 [系统函数](#77-系统函数)
7.8 [指针类型](#78-指针类型pointer)
7.9 [串口通信函数](#79-串口通信函数)
8. [文件操作](#8-文件操作)
9. [网络编程](#9-网络编程)
9.1 [TCP 套接字](#91-tcp-套接字)
9.2 [TCP 服务器](#92-tcp-服务器)
9.3 [UDP 套接字](#93-udp-套接字)
9.4 [与 Python socket 对比](#94-与-python-socket-对比)
9.5 [HTTP 请求](#95-http-请求)
9.6 [TCP/UDP 二进制数据通信](#96-tcpudp-二进制数据通信)
9.7 [WebSocket](#97-websocket)
10. [多线程编程](#10-多线程编程)
10.1 [创建线程](#101-创建线程)
10.2 [线程同步](#102-线程同步)
10.3 [线程安全计数器（Mutex 实现）](#103-线程安全计数器mutex-实现)
10.4 [等待线程](#104-等待线程)
10.5 [消息队列](#105-消息队列)
10.6 [优雅关闭事件](#106-优雅关闭事件)
10.7 [线程安全队列（Queue）](#107-线程安全队列queue)
11. [信号处理](#11-信号处理)
12. [配置文件解析](#12-配置文件解析)
13. [协程编程](#13-协程编程)
14. [导入系统](#14-导入系统)
15. [音频录音和播放](#15-音频录音和播放)
15.1 [依赖安装](#151-依赖安装)
15.2 [一次性录音](#152-一次性录音)
15.3 [流式录音](#153-流式录音)
15.4 [播放音频](#154-播放音频)
15.5 [音频设备列表](#155-音频设备列表)
15.6 [保存为 WAV 文件](#156-保存为-wav-文件)
15.7 [完整示例](#157-完整示例)
15.8 [与 Python PyAudio 对比](#158-与-python-pyaudio-对比)
16. [语法汇总](#16-语法汇总)

***

## 1. 简介

### 1.1 概述

CatBase 是一种静态类型编程语言，设计目标是简洁、易学，同时具备强大的功能。它支持网络编程、多线程、文件操作等常用特性，并且可以导入 C 语言库。

CatBase 的主要特点包括：

- 简洁清晰的语法
- 静态类型系统，要求显式类型声明
- 丰富的内置函数库
- 支持网络编程（TCP/UDP/HTTP）
- 支持串口通信（RS-232/USB 转串口）
- 支持多线程编程
- 编译为本地可执行文件，性能优异
- 支持 C 语言库导入（.so/.a 文件）

### 1.2 CatBase 研发背景

#### 为什么要开发 CatBase？

在现有的编程语言生态中，我们发现存在一些痛点：

**C 语言的弊端：**

- 语法复杂，学习曲线陡峭
- 需要手动管理内存，容易出现内存泄漏
- 没有内置的字符串类型，需要使用字符数组
- 缺少现代语言的特性，如垃圾回收、闭包等
- 开发效率相对较低

**Python 语言的优势和弊端：**

- 优势：语法简洁优雅，开发效率高，生态丰富
- 弊端：运行速度慢，无法直接编译为本地可执行文件（需要 Python 解释器）
- 弊端：使用缩进来规范代码块，这种编程方法很容易出错（缩进不一致会导致语法错误）
- 弊端：声明变量时不强制指定变量类型，容易造成类型错误，增加程序员阅读代码时辨识变量类型的时间成本

**CatBase 的解决方案：**

CatBase 旨在结合 C 语言和 Python 语言的优点，同时解决 Python 的这两个问题：

| 特性     | C 语言 | Python | CatBase |
| ------ | ---- | ------ | ------- |
| 执行效率   | 高    | 低      | 高       |
| 开发效率   | 低    | 高      | 高       |
| 语法简洁   | 否    | 是      | 是       |
| 类型安全   | 是    | 否      | 是       |
| 静态类型   | 是    | 否      | 是       |
| 本地执行   | 是    | 否      | 是       |
| 大括号代码块 | 是    | 否      | 是       |
| 显式类型声明 | 是    | 否      | 是       |

#### CatBase 相比 Python 的两大核心优势

**优势一：使用大括号规范代码块**

Python 使用缩进来定义代码块，容易因为缩进不一致而导致语法错误：

```python
# Python - 缩进问题示例
def main():
    if True:
        print("Hello")  # 如果缩进少一个空格，可能导致语法错误
    else:
        print("World")
```

CatBase 使用大括号 `{}` 来定义代码块，避免缩进问题：

```catbase
# CatBase - 大括号代码块
def main(args:list[str]) {
    if True {
        print("Hello")  # 大括号明确定义代码块范围
    } else {
        print("World")
    }
}
```

**优势二：强制变量类型声明**

Python 变量可以不声明类型，虽然简洁但容易出错：

```python
# Python - 变量类型不明确
name = "Tom"          # 字符串
age = 25              # 整数
items = [1, 2, 3]    # 列表
# 程序员需要阅读代码才能推断变量类型
```

CatBase 要求显式声明变量类型，代码一目了然：

```catbase
# CatBase - 变量类型明确
name:str = "Tom"           # 字符串类型
age:int = 25               # 整数类型
items:list[int] = [1, 2, 3]  # 整数列表类型
# 变量类型一目了然，提高代码可读性
```

**为什么命名为 CatBase？**

- "Cat" 代表简洁、优雅（如同猫一般）
- "Base" 代表基础、根基，象征这是一门面向基础编程的语言
- 同时，"CatBase" 也暗示这门语言可以作为学习更复杂语言的根基
- 另外，"Cat" 正好也是"C" at Base的拆分理解一语双关，符合这门语言的目标

#### 代码量对比

让我们对比一下实现相同功能时，三种语言的代码量：

**Hello World：**

C 语言：

```c
#include <stdio.h>
int main() {
    printf("Hello, World!\n");
    return 0;
}
```

Python：

```python
print("Hello, World!")
```

CatBase：

```catbase
def main(args:list[str]) {
    print("Hello, World!")
}
```

**文件读取：**

C 语言：

```c
#include <stdio.h>
#include <stdlib.h>

int main() {
    FILE *fp = fopen("test.txt", "r");
    if (fp == NULL) {
        printf("Cannot open file\n");
        return 1;
    }
    
    char buffer[1024];
    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        printf("%s", buffer);
    }
    
    fclose(fp);
    return 0;
}
```

Python：

```python
with open("test.txt", "r") as f:
    print(f.read())
```

CatBase：

```catbase
def main(args:list[str]) {
    f:File = file("test.txt", "r")
    content:str = f.read()
    f.close()
    print(content)
}
```

从对比可以看出，CatBase 在保持接近 Python 简洁性的同时，还能编译为本地可执行文件，拥有接近 C 语言的执行效率。

### 1.3 Hello World

下面是 CatBase 的 Hello World 程序：

```catbase
def main(args:list[str]) {
    print("Hello, World!")
}
```

**运行结果：**

```
Hello, World!
```

### 1.4 编译器和命令行

CatBase 编译器（`catbasecc`）将 `.cat` 文件编译为可执行文件。

#### 基本用法

```bash
# 编译源文件
catbasecc source.cat

# 编译并运行
catbasecc source.cat && ./source
```

#### 命令行参数

| 参数             | 说明                                          |
| -------------- | ------------------------------------------- |
| `-no-emit-obj` | 编译后不生成 .o 目标文件                              |
| `-shared`      | 生成共享库（.so）而不是可执行文件                          |
| `-static`      | 静态链接（生成的可执行文件不依赖动态库，适合极小资源环境）               |
| `-O <level>`   | 编译优化级别：ReleaseFast、ReleaseSmall、ReleaseSafe |
| `-o <output>`  | 指定输出可执行文件的名称                                |

```bash
# 编译时不生成 .o 文件
catbasecc -no-emit-obj source.cat

# 生成共享库
catbasecc -shared mylib.cat

# 静态链接（适合极小资源环境，如嵌入式系统）
catbasecc -static source.cat

# 生成最小体积的可执行文件
catbasecc -O ReleaseSmall source.cat

# 安全优先（带运行时检查）
catbasecc -O ReleaseSafe source.cat

# 指定输出文件名
catbasecc -o myprogram source.cat
```

#### 优化级别说明

CatBase 编译器提供三种编译优化级别：

| 优化级别           | 说明                         | 适用场景                           |
| -------------- | -------------------------- | ------------------------------ |
| `ReleaseFast`  | 快速运行（默认）：执行速度最快，代码体积较大     | 生产环境，对性能要求高的应用                 |
| `ReleaseSmall` | 最小体积：代码体积最小，运行速度稍慢         | 极小资源环境（如嵌入式设备、容器镜像优化）、磁盘空间受限场景 |
| `ReleaseSafe`  | 安全优先：包含运行时检查，代码体积最大，执行速度最慢 | 开发调试阶段、需要额外安全保护的场景             |

**体积对比示例：**

假设一个简单的 Hello World 程序：

- `ReleaseFast`：约 960 KB（默认）
- `ReleaseSmall`：约 13 KB（体积减少约 98.6%）
- `ReleaseSafe`：约 1.5 MB

实际体积取决于程序复杂度和引入的库。

**极小体积示例：**

使用 `-static -O ReleaseSmall` 组合可以生成极小体积的可执行文件：

```bash
# 生成极小体积的静态链接可执行文件（约 13 KB）
catbasecc -static -O ReleaseSmall source.cat
```

这种组合特别适合：

- 嵌入式系统
- 容器镜像优化（如 Docker Alpine）
- 资源受限的 Linux 环境

#### 静态链接说明

`-static` 参数使生成的可执行文件不依赖任何动态链接库（.so），所有依赖都静态链接到可执行文件中。

**适用场景：**

- **极小资源 Linux 环境**：如嵌入式系统、容器镜像（Alpine 等精简发行版）
- **简化部署**：不需要在目标机器上安装额外的动态库
- **安全要求高的环境**：减少动态库攻击面

**注意事项：**

- **与** **`-shared`** **互斥**：不能同时使用 `-static` 和 `-shared`
- **与 .so/.a 导入冲突**：如果代码中使用了 `import` 导入 .so 或 .a 文件，静态链接会自动忽略并给出警告
  ```bash
  Warning: -static is incompatible with .so import, ignoring static linking
  ```
- **C 标准库**：静态链接时会将 libc 一起链接到可执行文件中

**静态链接与动态库导入（.so）的区别：**

| 文件类型                  | 说明          | 能否静态链接 |
| --------------------- | ----------- | ------ |
| `.so` (Shared Object) | 动态链接库，运行时加载 | ❌ 不能   |
| `.a` (Archive)        | 静态归档库，编译时链接 | ✅ 可以   |

**为什么 .so 不能静态链接？**

`.so` 文件是**运行时依赖**，存储在目标系统的动态库目录中（如 `/usr/lib`）。静态链接发生在**编译时**，只能将编译时可见的代码链接到可执行文件中。

**示例：MySQL 场景**

假设你的代码中导入了 MySQL 客户端库：

```catbase
import "./libmysqlclient.so"

def main(args:list[str]) {
    # 连接数据库...
}
```

编译时使用 `-static`：

```bash
catbasecc -static source.cat
```

编译器会给出警告并忽略静态链接：

```
Warning: -static is incompatible with .so import, ignoring static linking
```

这是因为 `.so` 是运行时依赖，无法在编译时打包进可执行文件。

**解决方案：**

1. **使用动态链接（默认）**：目标机器需要安装 MySQL 客户端库
   ```bash
   catbasecc source.cat
   ```
2. **使用静态归档库（.a）**：如果可以获得静态库版本
   ```bash
   catbasecc -static import "./libmysqlclient.a" source.cat
   ```
   注意：静态归档库必须存在且与你的目标架构兼容

**示例对比：**

```bash
# 动态链接（默认）
catbasecc source.cat
# 生成的 source 依赖: libc.so, libm.so 等

# 静态链接
catbasecc -static source.cat
# 生成的 source 不依赖任何动态库
```

```bash
# 查看可执行文件的动态库依赖
ldd ./source

# 静态链接后的可执行文件
ldd ./source
# 输出: "not a dynamic executable"
```

#### 编译输出

编译成功后，会生成以下文件：

- `source` - 可执行文件（无扩展名）
- `source.o` - 目标文件（可通过 `-no-emit-obj` 禁用）
- `out/source.zig` - 生成的中间代码
- `libsource.so` - 共享库（使用 `-shared` 参数时生成）

#### 应用场景

极小资源的linux环境和服务器Linux环境，所以在调用so的时候，需要兼顾服务器环境和极小紧凑环境。

### 1.5 IDE 配置

CatBase 支持在 VS Code / Trae 等基于 VS Code 的编辑器中进行开发，提供语法高亮和代码补全功能。

#### 安装步骤

**方式一：手动安装**

1. 在扩展目录创建 `catbase` 文件夹：
   - **Windows**: `%USERPROFILE%\.vscode\extensions\catbase`
   - **Mac/Linux**: `~/.vscode/extensions/catbase`
2. 在该文件夹下创建以下文件结构：

```
catbase/
├── package.json
├── language-configuration.json
└── syntaxes/
    └── catbase.tmLanguage
```

1. 各个文件的内容如下：

**package.json**（扩展配置）

```json
{
  "name": "catbase-language",
  "displayName": "CatBase Language",
  "description": "CatBase programming language support for VS Code",
  "version": "1.0.0",
  "publisher": "catbase",
  "engines": {
    "vscode": "^1.60.0"
  },
  "categories": [
    "Programming Languages"
  ],
  "contributes": {
    "languages": [
      {
        "id": "catbase",
        "aliases": ["CatBase", "catbase"],
        "extensions": [".cat"],
        "configuration": "./language-configuration.json"
      }
    ],
    "grammars": [
      {
        "language": "catbase",
        "scopeName": "source.catbase",
        "path": "./syntaxes/catbase.tmLanguage"
      }
    ]
  }
}
```

**language-configuration.json**（语言特性配置）

```json
{
  "comments": {
    "lineComment": "#",
    "blockComments": ["/*", "*/"]
  },
  "brackets": [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"]
  ],
  "autoClosingPairs": [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"],
    ["\"", "\""],
    ["'", "'"]
  ],
  "surroundingPairs": [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"],
    ["\"", "\""],
    ["'", "'"]
  ],
  "indentationRules": {
    "increaseIndentPattern": "\\{[^}]*$",
    "decreaseIndentPattern": "^\\s*\\}"
  }
}
```

**syntaxes/catbase.tmLanguage**（语法高亮定义）

```yaml
name: CatBase
scopeName: source.catbase
patterns:
  - include: '#comments'
  - include: '#strings'
  - include: '#keywords'
  - include: '#types'
  - include: '#numbers'
  - include: '#functions'

repository:
  comments:
    patterns:
      - name: comment.line.catbase
        begin: "#"
        end: "$"
      - name: comment.block.catbase
        begin: "/\\*"
        end: "\\*/"

  strings:
    patterns:
      - name: string.quoted.double.catbase
        begin: "\""
        end: "\""
        patterns:
          - name: string.escape.catbase
            match: \\.
      - name: string.quoted.single.catbase
        begin: "'"
        end: "'"
        patterns:
          - name: string.escape.catbase
            match: \\.

  keywords:
    patterns:
      - name: keyword.control.catbase
        match: \b(def|if|else|for|while|return|break|try|catch|except|finally|thread|async|await|import|from|as|not|and|or|in|is)\b
      - name: keyword.other.catbase
        match: \b(True|False|None)\b

  types:
    patterns:
      - name: storage.type.catbase
        match: \b(i64|i32|i16|i8|u64|u32|u16|u8|f64|f32|bool|str|list|dict|bytes|any)\b

  numbers:
    patterns:
      - name: constant.numeric.catbase
        match: \b\d+(\.\d+)?\b
      - name: constant.numeric.hex.catbase
        match: \b0x[0-9a-fA-F]+\b

  functions:
    patterns:
      - name: entity.name.function.catbase
        match: '[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\()'
```

1. 重启 VS Code / Trae

**方式二：使用VSIX文件安装（推荐）**

项目根目录已包含 `vscode-extension` 文件夹，可以生成VSIX安装包进行安装。

1. **生成VSIX安装包**（在Linux服务器上执行）：
   ```bash
   # 进入项目目录
   cd /path/to/CatBase_Worksp
   
   # 使用Python生成VSIX文件
   python3 -c "
   import zipfile
   import os
   import shutil
   import tempfile
   
   tmpdir = tempfile.mkdtemp()
   ext_dir = os.path.join(tmpdir, 'extension')
   os.makedirs(ext_dir)
   
   # 复制所有文件到正确位置
   src_dir = 'vscode-extension'
   for item in os.listdir(src_dir):
       src = os.path.join(src_dir, item)
       dst = os.path.join(ext_dir, item)
       if os.path.isfile(src):
           shutil.copy2(src, dst)
       elif os.path.isdir(src):
           shutil.copytree(src, dst)
   
   # 创建vsix
   vsix_path = 'catbase-language-1.0.0.vsix'
   with zipfile.ZipFile(vsix_path, 'w') as vsix:
       for root, dirs, files in os.walk(ext_dir):
           for f in files:
               full_path = os.path.join(root, f)
               arc_path = 'extension/' + os.path.relpath(full_path, ext_dir)
               vsix.write(full_path, arc_path)
   
   shutil.rmtree(tmpdir)
   print('VSIX created: ' + vsix_path)
   "
   ```
   执行完成后会在项目根目录生成 `catbase-language-1.0.0.vsix` 文件。
2. **下载VSIX文件到本地**：
   ```powershell
   # 从远程服务器下载到本地Windows
   scp 用户名@服务器IP:/path/to/CatBase_Worksp/catbase-language-1.0.0.vsix C:\Users\你的用户名\Downloads\
   ```
3. **安装VSIX**：
   - 打开VS Code / Trae
   - 按 `Ctrl+Shift+X` 打开扩展视图
   - 点击右上角 `...` 菜单
   - 选择 "Install from VSIX..."
   - 选择下载的 `catbase-language-1.0.0.vsix` 文件
   - 安装完成后按 `Ctrl+Shift+P`，输入 `Developer: Reload Window` 重新加载

**方式三：手动复制文件**

项目根目录已包含 `vscode-extension` 文件夹，可直接复制该文件夹到扩展目录：

```bash
# 复制整个文件夹到扩展目录
cp -r vscode-extension ~/.vscode/extensions/catbase

# Windows 可使用:
# xcopy /E /I vscode-extension "%USERPROFILE%\.vscode\extensions\catbase"
```

**方式四：开发模式安装**

```bash
cd vscode-extension
code --install-extension .
```

#### 功能特性

安装完成后，`.cat` 文件将获得以下支持：

- 语法高亮（关键字、字符串、数字、类型等）
- 注释高亮（`#`、`//` 行注释和 `/* */` 块注释）
- 括号匹配
- 自动缩进
- 文件图标显示

## 2. 基础语法

> **本章导读：** 在上一章中，我们了解了 CatBase 的基本概念和研发背景。本章将深入学习 CatBase 的基础语法，包括变量声明、数据类型、注释等。通过本章的学习，你将掌握 CatBase 的基本编程要素，为后续学习更复杂的特性打下坚实基础。

### 2.1 变量声明

**CatBase 设计优势：** 与 Python 的动态类型系统不同，CatBase 采用静态类型系统，要求所有变量必须显式声明类型。这一设计带来了以下优势：

- **类型安全**：编译时就能发现类型错误，减少运行时错误
- **代码可读性**：变量类型一目了然，便于团队协作
- **性能优化**：编译器可以进行更多优化，提高执行效率

CatBase 要求所有变量必须显式声明类型。变量声明使用冒号 `:` 分隔变量名和类型。

#### 语法

```
变量名:类型 = 初始值
```

#### 基本类型示例

```catbase
def main(args:list[str]) {
    # 整数类型
    age:int = 25
    
    # 浮点数类型
    price:float = 19.99
    
    # 字符串类型
    name:str = "CatBase"
    
    # 布尔类型
    is_active:bool = True
    
    print("Name: ", name, "\n")
    print("Age: ", age, "\n")
    print("Price: ", price, "\n")
    print("Active: ", is_active, "\n")
}
```

**运行结果：**

```
Name: CatBase
Age: 25
Price: 19.99
Active: true
```

### 2.2 内置名称保护

CatBase 保护内置函数名和类型名，防止用户意外覆盖导致运行时错误。

#### 内置函数名保护

以下函数名是内置函数，不能用作用户定义函数的名称：

`print`, `len`, `range`, `open`, `file`, `close`, `sleep`, `input`, `str`, `int`, `float`, `bool`, `list`, `dict`, `hex`, `bin`, `oct`, `chr`, `ord`, `exec`, `pow`, `round`, `abs`, `max`, `min`, `sum`, `type`, `json_loads`, `json_dumps`, `sorted`, `reversed`, `enumerate`, `zip`, `map`, `filter` 等。

#### 内置类型名保护

以下类型名是内置类型，不能用作变量名：

`int`, `str`, `float`, `bool`, `list`, `dict`, `File`, `Thread`, `Mutex`, `Queue`, `Response`, `WebSocket`, `TCPSocket`, `TCPClient`, `UDPSocket`, `Serial`, `RecordStream`, `PlayStream`, `Config`, `None` 等。

#### 示例

```catbase
# 错误示例 - 不能使用内置函数名
def file() -> int {  # 编译错误！
    return 1
}

# 错误示例 - 不能使用内置类型名
def main(args:list[str]) {
    Thread:Thread = 1  # 编译错误！
}
```

编译时会报错：

```
CatBase compilation errors:
  line 3: cannot use 'file' as function name: 'file' is a built-in function
  line 5: cannot use 'Thread' as variable name: 'Thread' is a built-in type
```

#### 列表类型

```catbase
def main(args:list[str]) {
    # 列表类型
    numbers:list[int] = [1, 2, 3, 4, 5]
    
    print("Numbers: ", numbers, "\n")
    print("First: ", numbers[0], "\n")
}
```

**运行结果：**

```
Numbers: [1, 2, 3, 4, 5]
First: 1
```

#### 字典类型

```catbase
def main(args:list[str]) {
    # 字典类型
    person:dict[str, str] = {"name": "Tom", "age": "20"}
    
    print("Person: ", person, "\n")
    print("Name: ", person["name"], "\n")
}
```

**运行结果：**

```
Person: {"name": "Tom", "age": 20}
Name: Tom
```

#### 自定义类型（对象类型）

CatBase 除了支持基本数据类型外，还提供了一系列自定义类型（也称为对象类型）。这些类型是CatBase运行时库提供的内置对象，用于实现各种功能。

**常见的自定义类型：**

| 类型 | 说明 | 创建方式 |
|------|------|----------|
| `File` | 文件对象 | `file(filename, mode)` |
| `Response` | HTTP 响应对象 | `http_post()`, `http_get()` |
| `WebSocket` | WebSocket 客户端 | `websocket(url, headers[可选])` |
| `Serial` | 串口对象 | `serial(port, baud_rate)` |
| `TCPSocket` | TCP套接字（客户端/服务器） | `tcpsocket()` |
| `TCPClient` | TCP客户端连接（来自TCPSocket.accept） | - |
| `UDPSocket` | UDP套接字 | `udpsocket()` |
| `RecordStream` | 录音流 | `recordStream(rate, channels, chunk, format, device_name, callback)` |
| `PlayStream` | 播放流 | `playStream(rate, channels, format, device_name, callback)` |
| `list[dict[str,str]]` | 设备列表 | `getInputDeviceList()`, `getOutputDeviceList()` |
| `Mutex` | 互斥锁 | `mutex()` |
| `Thread` | 线程句柄 | `thread worker(args)` |
| `Queue` | 消息队列 | `queue(maxsize)` |
| `Config` | 配置文件对象 | `config(filename)` |

**使用示例：**

```catbase
def main(args:list[str]) {
    # TCP客户端
    sock:TCPSocket = tcpsocket()
    sock.connect("example.com", 80)

    # TCP服务器
    server:TCPSocket = tcpsocket()
    server.bind("0.0.0.0", 8080)
    server.listen(128)
    client:TCPClient = server.accept()

    # UDP
    udp:UDPSocket = udpsocket()
    udp.sendto("Hello", "127.0.0.1", 9999)

    # WebSocket客户端
    ws:WebSocket = websocket("ws://example.com/ws", None)

    # 串口
    ser:Serial = serial("/dev/ttyUSB0", 115200)

    # 配置文件
    cfg:Config = config("app.conf")

    # 文件对象
    f:File = file("test.txt", "r")

    # 音频流
    stream:RecordStream = recordStream(rate=16000, channels=1)

    # 使用完成后需要关闭资源
    client.close()
    ws.close()
    ser.close()
    f.close()
    stream.close()
}
```

**自定义类型的特点：**

1. 需要使用内置函数或构造函数创建
2. 通常需要手动释放资源（调用 `close()` 方法）
3. 支持特定的方法调用，如 `stream.read()`、`ws.send()`、`client.recv()` 等
4. 类型名称首字母大写，与基本数据类型区分

#### Queue（线程安全消息队列）

Queue 是线程安全的消息队列，与 Python 的 `queue.Queue` API 对齐。

**创建方式：**
```catbase
q:Queue = queue(maxsize)  # maxsize 为 0 表示无限制队列
```

**支持的类型：**
Queue 支持 int、float、str、bytes 四种类型。**第一次放入的元素类型决定后续所有元素的类型**，类型不匹配的元素会被静默丢弃。

**常用方法：**

| 方法 | 说明 | 示例 |
|------|------|------|
| `put(item, timeout_ms)` | 阻塞式放入，timeout_ms=-1 表示无限等待 | `q.put(msg, -1)` |
| `put_nowait(item)` | 非阻塞放入，满时静默丢弃 | `q.put_nowait(msg)` |
| `get(timeout_ms)` | 带超时取出，超时返回对应类型的零值，0 表示非阻塞，-1 表示无限等待 | `q.get(1000)` |
| `get_nowait()` | 非阻塞取出，空时返回对应类型的零值 | `q.get_nowait()` |
| `task_done()` | 标记一个任务完成 | `q.task_done()` |
| `join()` | 等待所有任务完成，并等待所有子线程结束 | `q.join()` |
| `empty()` | 检查队列是否为空 | `q.empty()` |
| `full()` | 检查队列是否已满 | `q.full()` |
| `qsize()` | 获取队列中的元素数量 | `q.qsize()` |
| `get_maxsize()` | 获取队列的最大容量 | `q.get_maxsize()` |

**使用示例（生产者-消费者模式）：**

```catbase
def producer(q:Queue) {
    i:int = 0
    while i < 5 {
        msg:str = str(i * 100)
        q.put(msg, -1)  # 阻塞等待放入
        print("Producer: put ", msg, "\n")
        i = i + 1
    }
}

def consumer(q:Queue) {
    i:int = 0
    while i < 5 {
        if !q.empty() {
            msg:str = q.get_nowait()
            print("Consumer: get_nowait ", msg, "\n")
            q.task_done()
        } else {
            print("Consumer: queue is empty, waiting...\n")
        }
        sleep(1)
        i = i + 1
    }
}

def main(args:list[str]) {
    q:Queue = queue(10)
    thread producer(q)
    thread consumer(q)
    q.join()  # 等待所有任务和线程完成
    print("Test completed!\n")
}
```

**注意：**
- `put(item, timeout_ms)` 的 `timeout_ms` 参数：`-1` 表示无限等待，`0` 表示非阻塞，正数表示等待毫秒数
- `join()` 会等待队列中所有消息被处理（`unfinished_tasks == 0`），并等待所有通过 `thread` 启动的子线程结束
- 使用 `put_nowait()` 时，如果队列满消息会被静默丢弃
- Queue 会在放入元素时克隆 str/bytes 类型的数据，确保数据归队列所有，避免线程退出时数据被释放

#### 显式类型声明要求

CatBase 要求所有变量必须显式声明类型。以下代码会导致错误：

```catbase
def main(args:list[str]) {
    x = 10  # 错误：必须显式声明类型
}
```

**编译错误：**

```
line 3: [Type Error] Variable 'x' must be explicitly declared with a type
```

正确的写法：

```catbase
def main(args:list[str]) {
    x:int = 10  # 正确
}
```

#### 全局变量

CatBase 支持在函数外部声明顶层全局变量。全局变量在整个程序运行期间保持其值，可用于定义常量、配置参数等。

**语法：**

```
变量名:类型 = 初始值
```

**示例：**

```catbase
# 全局变量声明（位于函数外部）
MY_NAME: str = "CatBase"
MY_VERSION: int = 1
MY_PI: float = 3.14
IS_ACTIVE: bool = true

def main(args:list[str]) {
    print("Name: ")
    print(MY_NAME)
    print("\n")
    print("Version: ")
    print(MY_VERSION)
    print("\n")
    print("PI: ")
    print(MY_PI)
    print("\n")
}
```

**运行结果：**

```
Name: CatBase
Version: 1
PI: 3.14
```

**全局变量的特点：**

1. 全局变量必须在函数外部声明
2. 全局变量必须在声明时初始化
3. 全局变量可以在任何函数中访问和修改
4. 全局变量在整个程序运行期间保持其值
5. 全局变量不支持使用 `var` 关键字，必须使用类型注解

### 2.2 函数定义

函数使用 `def` 关键字定义。

#### 语法

```
def 函数名(参数:类型, ...) -> 返回类型 {
    # 函数体
    return 值
}
```

注意：返回类型是可选的，如果不指定返回类型，函数默认返回 `None`。

#### 无参函数

```catbase
def greet() {
    print("Hello, World!")
}

def main(args:list[str]) {
    greet()
}
```

**运行结果：**

```
Hello, World!
```

#### 有参函数

```catbase
def greet(name:str) {
    print("Hello, ", name, "!")
}

def main(args:list[str]) {
    greet("CatBase")
    greet("World")
}
```

**运行结果：**

```
Hello, CatBase!
Hello, World!
```

#### 有返回值的函数

```catbase
def add(a:int, b:int) -> int {
    return a + b
}

def main(args:list[str]) {
    result:int = add(5, 3)
    print("5 + 3 = ", result, "\n")
}
```

**运行结果：**

```
5 + 3 = 8
```

#### 主函数

每个 CatBase 程序必须包含一个 `main` 函数作为入口点。`main` 函数接收一个列表类型的参数，用于获取命令行传入的参数。

```catbase
def main(args:list[str]) {
    print("Program started!\n")
    print("Number of arguments: ", len(args), "\n")
}
```

**运行结果：**

```
Program started!
Number of arguments: 1
```

##### 获取命令行参数

命令行参数通过 `args` 列表传入，其中：

- `args[0]` 是程序名称（可执行文件路径）
- `args[1]` 开始是用户传入的实际参数

```catbase
def main(args:list[str]) {
    print("Program name: ", args[0], "\n")
    print("Number of arguments: ", len(args), "\n")
    
    # 遍历所有参数
    i:int = 0
    while i < len(args) {
        print("args[", i, "] = ", args[i], "\n")
        i = i + 1
    }
}
```

**运行结果：**

```
Program name: ./hello
Number of arguments: 4
args[0] = ./hello
args[1] = hello
args[2] = world
args[3] = 123
```

##### 编译运行示例

```bash
# 编译
catbasecc hello.cat

# 运行并传入参数
./hello hello world 123
```

### 2.3 注释

CatBase 支持三种注释方式：

#### 1. 井号注释（#）

使用 `#` 进行单行注释，从 `#` 到行尾都是注释内容。

```catbase
def main(args:list[str]) {
    # 这是一个注释
    print("Hello")  # 这也是注释
}
```

**运行结果：**

```
Hello
```

#### 2. 块注释（/\* ... \*/）

使用 `/*` 和 `*/` 包裹多行注释内容。

```catbase
def main(args:list[str]) {
    /*
     * 这是一个
     * 多行注释
     */
    print("Hello")
}
```

**运行结果：**

```
Hello
```

#### 3. 三引号注释（""" ... """）

使用三个双引号或单引号包裹多行注释内容。

```catbase
def main(args:list[str]) {
    """
    这是一个
    三引号注释
    """
    print("Hello")
}
```

**运行结果：**

```
Hello
```

#### 4. 双斜杠注释（//）

使用 `//` 进行单行注释，从 `//` 到行尾都是注释内容。这种注释风格与许多主流编程语言（如 C++、Java、JavaScript）一致。

```catbase
def main(args:list[str]) {
    // 这是一个注释
    print("Hello")  // 这也是注释
}
```

**运行结果：**

```
Hello
```

### 2.4 代码块

CatBase 使用花括号 `{}` 定义代码块。

```catbase
def main(args:list[str]) {
    # 简单的代码块
    {
        x:int = 10
        print("x = ", x, "\n")
    }
    
    # 条件语句中的代码块
    if True {
        print("True block\n")
    } else {
        print("False block\n")
    }
}
```

**运行结果：**

```
x = 10
True block

```

***

## 3. 数据类型

> **本章导读：** 上一章我们学习了变量声明的基本语法，本章将深入了解 CatBase 支持的数据类型。掌握这些数据类型是编写正确程序的基础。CatBase 提供了丰富的数据类型，包括整数、浮点数、字符串、布尔值、列表和字典等，满足各种编程需求。

### 3.1 基本数据类型

CatBase 支持以下基本数据类型：

| 类型      | 说明   | 示例                 |
| ------- | ---- | ------------------ |
| `int`   | 整数   | `42`, `-10`        |
| `float` | 浮点数  | `3.14`, `-0.5`     |
| `str`   | 字符串  | `"Hello"`          |
| `bool`  | 布尔值  | `True`, `False`    |
| `list`  | 列表   | `[1, 2, 3]`        |
| `dict`  | 字典   | `{"key": "value"}` |
| `bytes` | 字节序列 | `b"Hello"`         |
| `function` | 函数引用 | `my_callback`     |

#### 整数类型

```catbase
def main(args:list[str]) {
    a:int = 10
    b:int = -20
    c:int = 0
    
    print("a = ", a, "\n")
    print("b = ", b, "\n")
    print("c = ", c, "\n")
}
```

**运行结果：**

```
a = 10
b = -20
c = 0

```

#### 浮点数类型

```catbase
def main(args:list[str]) {
    pi:float = 3.14159
    neg:float = -2.5
    zero:float = 0.0
    
    print("pi = ", pi, "\n")
    print("neg = ", neg, "\n")
    print("zero = ", zero, "\n")
}
```

**运行结果：**

```
pi = 3.14159
neg = -2.5
zero = 0.0

```

#### 整数和浮点数子类型

CatBase 除了提供基本的 `int` 和 `float` 类型外，还支持更细粒度的数值子类型，用于精确控制内存占用和数值范围。这些子类型在调用外部 C 库函数（通过 `from...import` 声明）时特别有用，可以与 C 语言的类型精确对应。

| 子类型    | 说明                | 对应 C/Zig 类型 | 取值范围                          |
| --------- | ------------------- | -------------- | --------------------------------- |
| `i8`      | 8 位有符号整数        | `i8`           | -128 ~ 127                        |
| `i16`     | 16 位有符号整数       | `i16`          | -32768 ~ 32767                    |
| `i32`     | 32 位有符号整数       | `i32`          | -2^31 ~ 2^31-1                   |
| `i64`     | 64 位有符号整数       | `i64`          | -2^63 ~ 2^63-1                   |
| `u8`      | 8 位无符号整数        | `u8`           | 0 ~ 255                           |
| `u16`     | 16 位无符号整数       | `u16`          | 0 ~ 65535                         |
| `u32`     | 32 位无符号整数       | `u32`          | 0 ~ 2^32-1                       |
| `u64`     | 64 位无符号整数       | `u64`          | 0 ~ 2^64-1                       |
| `f32`     | 32 位单精度浮点数     | `f32`          | IEEE 754 单精度                     |
| `f64`     | 64 位双精度浮点数     | `f64`          | IEEE 754 双精度                     |

**使用说明：**

- 在一般 CatBase 代码中，使用 `int`（默认对应 `i64`）和 `float`（默认对应 `f64`）即可
- 子类型主要用于 `from...import` 声明外部函数时的参数和返回值类型，确保与 C 函数的类型精确匹配
- `int` 等价于 `i64`，`float` 等价于 `f64`

**外部函数声明示例：**

```catbase
import "./libmylib.so" as mylib

# 使用子类型声明外部函数，精确匹配 C 函数签名
from mylib import process_byte(data: u8) -> i32
from mylib import get_coordinate() -> f32
from mylib import write_buffer(buf: bytes, len: u32) -> i64

def main(args:list[str]) {
    result:i32 = mylib.process_byte(65)
    print("Result: ", result, "\n")
}
```

#### 字符串类型

CatBase 支持使用双引号 `"..."` 或单引号 `'...'` 定义字符串，也支持使用 f-string 格式化字符串：

```catbase
def main(args:list[str]) {
    s1:str = "Hello"
    s2:str = 'World'
    s3:str = ""
    s4:str = ''
    
    print("s1 = ", s1, "\n")
    print("s2 = ", s2, "\n")
    print("s3 = '", s3, "'\n")
    print("s4 = '", s4, "'\n")
    print("s1 + s2 = ", s1 + " " + s2, "\n")
}
```

**运行结果：**

```
s1 = Hello
s2 = World
s3 = ''
s4 = ''
s1 + s2 = Hello World

```

#### f-string 格式化字符串

CatBase 支持使用 f-string（格式化字符串）在字符串中嵌入变量和表达式。f-string 以 `f"` 或 `f'` 开头，使用 `{变量名}` 在字符串中插入变量值。

```catbase
def main(args:list[str]) {
    name:str = "CatBase"
    version:int = 1
    
    # 基本 f-string 用法
    msg:str = f"Hello, {name}!"
    print(msg, "\n")
    
    # 嵌入多个变量
    info:str = f"{name} version {version}"
    print(info, "\n")
    
    # 嵌入表达式
    a:int = 10
    b:int = 20
    result:str = f"Sum = {a + b}"
    print(result, "\n")
}
```

**运行结果：**

```
Hello, CatBase!
CatBase version 1
Sum = 30
```

**语法说明：**

- `f"...{var}..."` - 在双引号字符串中嵌入变量
- `f'...{var}...'` - 在单引号字符串中嵌入变量
- `{expr}` - 花括号内可以是任意表达式

#### 布尔类型

```catbase
def main(args:list[str]) {
    t:bool = True
    f:bool = False
    
    print("t = ", t, "\n")
    print("f = ", f, "\n")
}
```

**运行结果：**

```
t = True
f = False

```

### 3.2 复合数据类型

#### 列表

列表是一种有序的可变集合。

```catbase
def main(args:list[str]) {
    # 创建列表
    nums:list[int] = [1, 2, 3, 4, 5]
    
    # 访问元素
    print("First: ", nums[0], "\n")
    print("Last: ", nums[4], "\n")
    
    # 修改元素
    nums[0] = 10
    print("Modified: ", nums, "\n")
    
    # 列表长度
    print("Length: ", len(nums), "\n")
}
```

**运行结果：**

```
First: 1
Last: 5
Modified: [10, 2, 3, 4, 5]
Length: 5

```

#### 字典

字典是一种键值对集合。

```catbase
def main(args:list[str]) {
    # 创建字典
    person:dict[str, str] = {"name": "Tom", "age": "20", "city": "Beijing"}
    
    # 访问值
    print("Name: ", person["name"], "\n")
    print("Age: ", person["age"], "\n")
    
    # 修改值
    person["age"] = 21
    print("Updated: ", person, "\n")
    
    # 添加新键值对
    person["country"] = "China"
    print("After add: ", person, "\n")
}
```

**运行结果：**

```
Name: Tom
Age: 20
Updated: {"name": "Tom", "age": 21}
After add: {"name": "Tom", "age": 21, "city": "Beijing", "country": "China"}

```

#### bytes

bytes 类型表示字节序列，用于处理二进制数据。bytes 本质上是字符串的另一种形式，可以直接用于需要字节数据的场景，如串口通信、网络协议等。

**bytes 字面量语法：** 使用 `b"..."` 前缀创建字节序列。

```catbase
def main(args:list[str]) {
    # 创建 ASCII bytes
    data:bytes = b"Hello"
    print(data)
    print("\n")

    # 创建包含十六进制数据的 bytes
    # \xHH 表示十六进制字节值
    hex_data:bytes = b"\x01\x02\x03\x04"
    print("Hex data length: ")
    print(len(hex_data))
    print("\n")
}
```

**运行结果：**

```
Hello
Hex data length: 4

```

#### bytes 转义序列

bytes 类型支持以下转义序列：

| 转义序列   | 说明                   |
| ------ | -------------------- |
| `\n`   | 换行符（0x0A）            |
| `\t`   | 制表符（0x09）            |
| `\r`   | 回车符（0x0D）            |
| `\"`   | 双引号字符                |
| `\\`   | 反斜杠字符                |
| `\xHH` | 十六进制字节值（HH 为两位十六进制数） |

#### bytes 应用示例：串口通信

bytes 类型非常适合用于串口通信，可以发送二进制协议数据：

```catbase
def main(args:list[str]) {
    # 打开串口
    ser:Serial = serial("/dev/ttyUSB0", 115200)
    print("Serial port opened successfully\n")

    # 发送文本数据
    ser.write(b"Hello, Serial!\n")

    # 发送二进制协议数据（Modbus 示例）
    # 帧格式：设备地址(1) + 功能码(1) + 数据(N) + CRC(2)
    modbus_frame:bytes = b"\x01\x03\x00\x00\x00\x0A"
    ser.write(modbus_frame)

    # 读取响应
    data:str = ser.read(1024)
    print("Received: ")
    print(data)
    print("\n")

    # 关闭串口
    ser.close()
    print("Serial port closed\n")
}
```

**运行结果：**

```
Serial port opened successfully
Serial port closed

```

#### bytes 应用示例：二进制协议构造

```catbase
def main(args:list[str]) {
    # 构造 IP 头的前 20 字节
    version_ihl:bytes = b"\x45"      # 版本(4) + 首部长度(5)
    tos:bytes = b"\x00"              # 服务类型
    total_length:bytes = b"\x00\x14"  # 总长度 (20)
    identification:bytes = b"\x00\x00" # 标识
    flags_offset:bytes = b"\x40\x00"  # 标志 + 片偏移
    ttl:bytes = b"\x40"              # 生存时间 (64)
    protocol:bytes = b"\x06"         # 协议 (TCP)
    checksum:bytes = b"\x00\x00"      # 校验和
    src_ip:bytes = b"\xC0\xA8\x01\x01" # 源 IP (192.168.1.1)
    dst_ip:bytes = b"\xC0\xA8\x01\x02" # 目标 IP (192.168.1.2)

    # 组合完整的 IP 头
    ip_header:bytes = version_ihl + tos + total_length + identification + flags_offset + ttl + protocol + checksum + src_ip + dst_ip

    print("IP header length: ")
    print(len(ip_header))
    print("\n")
    print("IP header hex: ")
    print(ip_header)
    print("\n")
}
```

**运行结果：**

```
IP header length: 20
IP header hex: E5 00 14 00 00 40 00 40 06 00 00 C0 A8 01 01 C0 A8 01 02

```

### 3.3 类型转换

CatBase 提供以下类型转换函数：

| 函数         | 说明         |
| ---------- | ---------- |
| `int(x)`   | 将 x 转换为整数  |
| `float(x)` | 将 x 转换为浮点数 |
| `str(x)`   | 将 x 转换为字符串 |

#### 类型转换示例

```catbase
def main(args:list[str]) {
    # 字符串转整数
    n:int = int("42")
    print("int('42') = ", n, "\n")
    
    # 整数转字符串
    s:str = str(123)
    print("str(123) = '", s, "'\n")
    
    # 整数转浮点数
    f:float = float(10)
    print("float(10) = ", f, "\n")
    
    # 字符串转浮点数
    f2:float = float("3.14")
    print("float('3.14') = ", f2, "\n")
}
```

**运行结果：**

```
int('42') = 42
str(123) = '123'
float(10) = 10.0
float('3.14') = 3.14

```

***

## 4. 运算符

> **本章导读：** 掌握数据类型后，本章将介绍 CatBase 中的运算符。运算符是编程中不可或缺的工具，用于对数据进行各种计算和操作。通过本章学习，你将能够灵活运用算术、比较、逻辑等运算符构建复杂的表达式。

### 4.1 算术运算符

| 运算符 | 说明 | 示例           |
| --- | -- | ------------ |
| `+` | 加法 | `5 + 3 → 8`  |
| `-` | 减法 | `5 - 3 → 2`  |
| `*` | 乘法 | `5 * 3 → 15` |
| `/` | 除法 | `5 / 2 → 2`  |
| `%` | 取余 | `5 % 2 → 1`  |

#### 算术运算示例

```catbase
def main(args:list[str]) {
    a:int = 10
    b:int = 3
    
    print("a + b = ", a + b, "\n")
    print("a - b = ", a - b, "\n")
    print("a * b = ", a * b, "\n")
    print("a / b = ", a / b, "\n")
    print("a % b = ", a % b, "\n")
}
```

**运行结果：**

```
a + b = 13
a - b = 7
a \* b = 30
a / b = 3
a % b = 1

```

### 4.2 复合赋值运算符

CatBase 支持复合赋值运算符，将算术运算与赋值合并为一条语句，使代码更简洁。

| 运算符  | 说明     | 等价写法        | 示例           |
| ---- | ------ | ----------- | ------------ |
| `+=` | 加后赋值  | `a = a + b` | `a += 3`     |
| `-=` | 减后赋值  | `a = a - b` | `a -= 3`     |
| `*=` | 乘后赋值  | `a = a * b` | `a *= 3`     |
| `/=` | 除后赋值  | `a = a / b` | `a /= 3`     |

#### 复合赋值运算示例

```catbase
def main(args:list[str]) {
    a:int = 10
    
    a += 5    # 等价于 a = a + 5
    print("a += 5: ", a, "\n")
    
    a -= 3    # 等价于 a = a - 3
    print("a -= 3: ", a, "\n")
    
    a *= 2    # 等价于 a = a * 2
    print("a *= 2: ", a, "\n")
    
    a /= 4    # 等价于 a = a / 4
    print("a /= 4: ", a, "\n")
}
```

**运行结果：**

```
a += 5: 15
a -= 3: 12
a *= 2: 24
a /= 4: 6
```

### 4.3 关系运算符

| 运算符  | 说明   | 示例              |
| ---- | ---- | --------------- |
| `==` | 等于   | `5 == 5 → True` |
| `!=` | 不等于  | `5 != 3 → True` |
| `<`  | 小于   | `3 < 5 → True`  |
| `>`  | 大于   | `5 > 3 → True`  |
| `<=` | 小于等于 | `3 <= 5 → True` |
| `>=` | 大于等于 | `5 >= 5 → True` |

#### 关系运算示例

```catbase
def main(args:list[str]) {
    a:int = 5
    b:int = 3
    
    print("a == b: ", a == b, "\n")
    print("a != b: ", a != b, "\n")
    print("a < b: ", a < b, "\n")
    print("a > b: ", a > b, "\n")
    print("a <= b: ", a <= b, "\n")
    print("a >= b: ", a >= b, "\n")
}
```

**运行结果：**

```
a == b: false
a != b: true
a < b: false
a > b: true
a <= b: false
a >= b: true

```

### 4.4 逻辑运算符

| 运算符   | 说明  | 示例                       |
| ----- | --- | ------------------------ |
| `and` | 逻辑与 | `True and False → False` |
| `or`  | 逻辑或 | `True or False → True`   |
| `not` | 逻辑非 | `not True → False`       |

#### 逻辑运算示例

```catbase
def main(args:list[str]) {
    a:bool = True
    b:bool = False
    
    print("a and b: ", a and b, "\n")
    print("a or b: ", a or b, "\n")
    print("not a: ", not a, "\n")
    print("not b: ", not b, "\n")
}
```

**运行结果：**

```
a and b: false
a or b: true
not a: false
not b: true

```

### 4.5 成员运算符

| 运算符  | 说明          | 示例                                   |
| ---- | ----------- | ------------------------------------ |
| `in` | 检查键是否存在于字典中 | `"name" in {"name": "Alice"} → True` |

#### in 运算符示例

`in` 运算符用于检查字典中是否存在指定的键：

```catbase
def main(args:list[str]) {
    data:dict[str,any] = {"name": "Alice", "age": 30}
    
    print("name in data: ", "name" in data, "\n")
    print("city in data: ", "city" in data, "\n")
    
    # 在条件语句中使用
    if "age" in data {
        print("Age exists!\n")
    }
    
    # 结合 and 使用
    if "name" in data and data["name"] {
        print("Name is not empty!\n")
    }
}
```

**运行结果：**

```
name in data: true
city in data: false
Age exists!
Name is not empty!

```

### 4.6 运算符优先级

CatBase 运算符优先级（从高到低）：

1. `()` - 括号
2. `not` - 逻辑非
3. `* / %` - 乘除取余
4. `+ -` - 加减
5. `< > <= >=` - 比较
6. `== !=` - 等于/不等于
7. `in` - 成员运算符
8. `and` - 逻辑与
9. `or` - 逻辑或

#### 优先级示例

```catbase
def main(args:list[str]) {
    # 乘除优先于加减
    print("2 + 3 * 4 = ", 2 + 3 * 4, "\n")
    
    # 括号可以改变优先级
    print("(2 + 3) * 4 = ", (2 + 3) * 4, "\n")
    
    # 逻辑运算
    print("not 1 > 2: ", not 1 > 2, "\n")
}
```

**运行结果：**

```
2 + 3 \* 4 = 14
(2 + 3) \* 4 = 20
not 1 > 2: true

```

***

## 5. 控制流

> **本章导读：** 运算符学完后，本章将介绍控制流语句。控制流决定了程序的执行顺序，包括条件语句和循环语句。掌握控制流后，你将能够编写具有分支和循环逻辑的程序，实现更复杂的功能。

### 5.1 条件语句

#### if 语句

```catbase
def main(args:list[str]) {
    age:int = 18
    
    if age >= 18 {
        print("成年人\n")
    } else {
        print("未成年人\n")
    }
}
```

**运行结果：**

```
成年人

```

#### if 变量（简化的空值检查）

CatBase 支持使用简化的 `if 变量` 语法来判断字符串是否为空：

```catbase
def main(args:list[str]) {
    test_str:str = "hello"
    
    if test_str {
        print("字符串不为空\n")
    }
    
    empty_str:str = ""
    if empty_str {
        print("字符串不为空\n")
    } else {
        print("字符串为空\n")
    }
}
```

**运行结果：**

```
字符串不为空
字符串为空

```

**语法说明：**

- `if variable` - 如果变量不为空（字符串长度 > 0），则条件为真
- 等同于 `if variable != ""` 的检查

#### if-else if-else 语句

```catbase
def main(args:list[str]) {
    score:int = 85
    
    if score >= 90 {
        print("优秀\n")
    } else if score >= 80 {
        print("良好\n")
    } else if score >= 60 {
        print("及格\n")
    } else {
        print("不及格\n")
    }
}
```

**运行结果：**

```
良好

```

#### 嵌套 if 语句

```catbase
def main(args:list[str]) {
    x:int = 10
    y:int = 20
    
    if x > 0 {
        if y > 0 {
            print("x 和 y 都为正数\n")
        } else {
            print("x 为正数，y 为负数\n")
        }
    } else {
        print("x 为负数\n")
    }
}
```

**运行结果：**

```
x 和 y 都为正数

```

### 5.2 循环语句

#### for 循环

```catbase
def main(args:list[str]) {
    # 遍历列表
    nums:list[int] = [1, 2, 3, 4, 5]
    
    for i in nums {
        print("Value: ", i, "\n")
    }
}
```

**运行结果：**

```
Value: 1
Value: 2
Value: 3
Value: 4
Value: 5

```

#### 带有索引的 for 循环

```catbase
def main(args:list[str]) {
    fruits:list[str] = ["apple", "banana", "orange"]
    
    for i, v in fruits {
        print(i, ": ", v, "\n")
    }
}
```

**运行结果：**

```
0: apple
1: banana
2: orange

```

#### 范围 for 循环

```catbase
def main(args:list[str]) {
    # 遍历范围
    for i in range(5) {
        print("i = ", i, "\n")
    }
}
```

**运行结果：**

```
i = 0
i = 1
i = 2
i = 3
i = 4

```

#### for 循环（迭代器）

CatBase 支持使用 `for ... in` 语法迭代实现了迭代器方法的对象，如 HTTP 流式响应。

要使用迭代器循环，需要满足以下条件：

1. 对象实现了 `iter_lines()` 方法
2. 该方法返回一个迭代器，每次迭代返回一行内容
3. 当迭代器返回 `None` 时循环自动结束

```catbase
def main(args:list[str]) {
    # 发送 HTTP 请求（流式模式）
    url:str = "http://localhost:19090/v1/chat/completions"
    data:dict[str,any] = {
        "model": "qwen",
        "messages": [{"role": "user", "content": "你好"}],
        "stream": true
    }
    
    # 使用 stream=True 启用流式模式
    response:Response = http_post(url, json=data, stream=True)
    
    # 检查响应状态
    response.raise_for_status()
    
    # 迭代读取流式响应
    for line in response.iter_lines() {
        print(line)
    }
}
```

**运行结果：**

```
data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"你好"},"logprobs":null,"finish_reason":null}]}
data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"！"},"logprobs":null,"finish_reason":null}]}
data: [DONE]
```

**说明**：

- `stream=True` 参数启用流式模式，返回 Response 对象而非字符串
- `response.raise_for_status()` 检查 HTTP 状态码，非 200-299 范围会触发异常
- `response.iter_lines()` 返回一个迭代器，每次迭代返回一行响应内容
- 当迭代器返回 None 时循环自动结束

##### 解析流式响应

在处理流式 API 响应时，通常需要解析每一行的 JSON 数据：

```catbase
def main(args:list[str]) {
    url:str = "http://localhost:19090/v1/chat/completions"
    data:dict[str,any] = {
        "model": "qwen",
        "messages": [{"role": "user", "content": "你好"}],
        "stream": true
    }
    
    response:Response = http_post(url, json=data, stream=True)
    response.raise_for_status()
    
    # 解析流式响应
    for line in response.iter_lines() {
        line_str:str = line
        if line_str.startswith("data: ") {
            # 提取 JSON 部分
            data_json:str = line_str[6:]
            
            # 解析 JSON
            data_dict:dict = json_loads(data_json)
            
            # 检查 choices 字段
            if "choices" in data_dict and data_dict["choices"] {
                # 获取 delta 中的 content
                delta:dict = data_dict["choices"][0].get("delta", {})
                content:any = delta.get("content", "")
                
                # 转换为字符串打印
                content_str:str = str(content)
                print(content_str, end="", flush=True)
            }
        }
    }
}
```

**运行结果：**

```
你好！有什么可以帮你的吗？
```

**解析步骤说明**：

1. 使用 `startswith("data: ")` 检查是否是数据行
2. 使用切片 `[6:]` 提取 JSON 字符串
3. 使用 `json_loads()` 解析 JSON 为字典
4. 使用 `in` 运算符检查键是否存在
5. 使用 `.get()` 方法安全获取嵌套值
6. 使用 `str()` 将 JsonValue 转换为字符串
7. 使用 `end=""` 参数实现不换行打印

#### while 循环

```catbase
def main(args:list[str]) {
    i:int = 0
    
    while i < 5 {
        print("i = ", i, "\n")
        i = i + 1
    }
}
```

**运行结果：**

```
i = 0
i = 1
i = 2
i = 3
i = 4

```

#### break

```catbase
def main(args:list[str]) {
    # break 示例
    print("Break example:\n")
    for i in range(10) {
        if i == 5 {
            break
        }
        print(i, " ")
    }
    print("\n")
}
```

**运行结果：**

```
Break example:
0 1 2 3 4
```

> **注意**：CatBase 目前不支持 `continue` 关键字。如需跳过某些迭代，请使用 `if` 条件语句代替。

### 5.3 异常处理

CatBase 使用 `try...except` 语句来处理异常。异常处理机制允许你在代码中捕获和处理运行时错误，使程序更加健壮。

#### 基本语法

CatBase 支持以下 except 语法：

1. **无变量语法**（推荐）：`except { ... }` - 不需要指定异常变量
2. **带变量语法**：`except errname` - 捕获异常到变量
3. **带类型语法**：`except Exception as errname` - 捕获异常到变量

> **注意**：也兼容旧的 `catch` 关键字，用法与 `except` 相同。

#### 无变量的 except（推荐语法）

```catbase
def main(args:list[str]) {
    try {
        print("hello\n")
    }
    except {
        print("something went wrong\n")
    }
}
```

**运行结果：**

```
hello

```

#### 带异常变量的 except

```catbase
def main(args:list[str]) {
    try {
        print("hello\n")
    }
    except e {
        print("Caught error: ")
        print(e)
    }
}
```

**运行结果：**

```
hello

```

#### 带类型和变量的 except

```catbase
def main(args:list[str]) {
    try {
        print("hello\n")
    }
    except Exception as e {
        print("Caught exception: ")
        print(e)
    }
}
```

**运行结果：**

```
hello

```

#### 嵌套 try-except

```catbase
def main(args:list[str]) {
    try {
        try {
            print("inner try\n")
        }
        except Exception as e {
            print("inner except: ")
            print(e)
        }
    }
    except Exception as e {
        print("outer except: ")
        print(e)
    }
}
```

**运行结果：**

```
inner try

```

#### 异常处理规则

1. **统一异常类型**：所有异常都是 `Exception` 类型，不区分 error 和 Exception
2. **异常变量作用域**：异常变量（如 `e` 或 `err`）只在 except 块内部可见
3. **任意位置捕获**：try-except 可以在函数的任意位置使用
4. **关键字选择**：推荐使用 `except`，也兼容 `catch`

#### 打印异常信息

在 except 块中，可以使用 `print(errname)` 直接打印异常的详细信息：

```catbase
def main(args:list[str]) {
    try {
        x:int = 10
        y:int = 0
        if y == 0 {
            print("Error: Division by zero\n")
        }
    }
    except Exception as e {
        print("Caught: ")
        print(e)
    }
}
```

**运行结果：**

```
Error: Division by zero
Caught: error.RuntimeError

```

#### 兼容旧的 catch 语法

CatBase 也兼容旧的 `catch` 关键字：

```catbase
def main(args:list[str]) {
    try {
        print("hello\n")
    }
    catch {
        print("caught\n")
    }
}
```

**运行结果：**

```
hello

```

#### finally 块

`finally` 块用于定义无论是否发生异常都会执行的代码。通常用于资源清理，如关闭文件、释放锁等。

```catbase
def main(args:list[str]) {
    try {
        print("try block\n")
    }
    except {
        print("catch block\n")
    }
    finally {
        print("finally block - always executes\n")
    }
}
```

**运行结果：**

```
try block
finally block - always executes

```

**即使发生异常，finally 也会执行：**

```catbase
def main(args:list[str]) {
    try {
        print("try block - about to error\n")
        # 这里模拟一个错误
    }
    except {
        print("catch block\n")
    }
    finally {
        print("finally block - cleanup here\n")
    }
}
```

**运行结果：**

```
try block - about to error
catch block
finally block - cleanup here

```

**使用 finally 进行资源清理的典型场景：**

```catbase
def main(args:list[str]) {
    stream: RecordStream = recordStream(rate=16000, channels=1)

    try {
        data:bytes = record(5, "16000", "1", "", "1024")
        save_wav(data, "/tmp/recording.wav", "16000")
    }
    except {
        print("Error during recording\n")
    }
    finally {
        # 确保录音流被关闭，释放资源
        stream.close()
        print("Resources cleaned up\n")
    }
}
```

***

## 6. 函数

> **本章导读：** 顺序执行和条件判断都掌握后，本章将介绍函数。函数是组织代码的基本单元，可以提高代码的复用性和可读性。CatBase 的函数设计简洁易用，同时支持返回值，让你的程序更加模块化。

### 6.1 函数定义与调用

#### 基本函数定义

```catbase
def greet(name:str) {
    print("Hello, ", name, "!\n")
}

def main(args:list[str]) {
    greet("CatBase")
}
```

**运行结果：**

```
Hello, CatBase!

```

#### 带返回值的函数

```catbase
def add(a:int, b:int) -> int {
    return a + b
}

def main(args:list[str]) {
    result:int = add(5, 3)
    print("5 + 3 = ", result, "\n")
}
```

**运行结果：**

```
5 + 3 = 8

```

#### 多返回值函数

CatBase 支持两种方式声明返回列表的函数：

**方式一：显式指定元素类型**

```catbase
def divide() -> list[int] {
    quotient:int = 1
    remainder:int = 2
    r:list[int]=[quotient, remainder]
    return r
}

def main(args:list[str]) {
    result:list[int] = divide()
    print(result[0],result[1])
}
```

**方式二：隐式推断元素类型**

```catbase
def divide() -> list {
    quotient:int = 1
    remainder:int = 2
    r:list=[quotient, remainder]
    return r
}

def main(args:list[str]) {
    result:list = divide()
    print(result[0],result[1])
}
```

**运行结果：**

```
1 2

```

> **设计原理**：CatBase 编译器会自动进行类型推断。当函数返回类型声明为 `list`（未指定元素类型）时，编译器会根据 return 语句中实际返回的列表字面量或变量类型，自动推断并填充具体的元素类型（如 `list[int]`）。同样，当变量声明为 `list` 但赋值了具体类型的列表时，变量类型也会被自动更新为具体类型。

> **使用注意**：
>
> - 显式声明（如 `list[int]`）代码可读性更好，类型检查更严格
> - 隐式推断（如 `list`）更灵活，但建议确保函数内所有返回路径返回相同类型的列表

**完整示例：两种方式同时使用**

```catbase
# 方式一：显式指定元素类型
def get_list1() -> list[int] {
    return [1, 2, 3, 4, 5]
}

# 方式二：隐式推断元素类型
def get_list2() -> list {
    return [1, 2, 3, 4, 5]
}

def main(args:list[str]) {
    result1:list[int] = get_list1()
    result2:list = get_list2()
    print("方式一: ", result1, "\n")
    print("方式二: ", result2, "\n")
}
```

**运行结果：**

```
方式一:  [1, 2, 3, 4, 5] 
方式二:  [1, 2, 3, 4, 5] 

```

**字典作为返回值示例**

```catbase
# 方式一：显式指定键值类型
def get_dict1() -> dict[str, int] {
    d:dict[str, int] = {"a": 1, "b": 2, "c": 3}
    return d
}

# 方式二：隐式推断键值类型
def get_dict2() -> dict {
    d:dict[str, int] = {"x": 10, "y": 20, "z": 30}
    return d
}

def main(args:list[str]) {
    result1:dict[str, int] = get_dict1()
    result2:dict = get_dict2()
    print("方式一: ", result1, "\n")
    print("方式二: ", result2, "\n")
    print("result1[\"a\"] = ", result1["a"], "\n")
    print("result2[\"y\"] = ", result2["y"], "\n")
}
```

**运行结果：**

```
方式一:  {'a': 1, 'b': 2, 'c': 3} 
方式二:  {'x': 10, 'y': 20, 'z': 30} 
result1["a"] =  1 
result2["y"] =  20 

```

> **注意**：字典和列表一样，也支持隐式类型推断。当函数返回类型声明为 `dict`（未指定键值类型）时，编译器会自动根据 return 语句中的字典变量类型推断具体的键值类型。

### 6.2 递归函数

```catbase
def factorial(n:int) -> int {
    if n <= 1 {
        return 1
    }
    return n * factorial(n - 1)
}

def main(args:list[str]) {
    print("5! = ", factorial(5), "\n")
    print("10! = ", factorial(10), "\n")
}
```

**运行结果：**

```
5! = 120
10! = 3628800

```

### 6.3 函数参数

#### 默认参数

```catbase
def greet(name:str, greeting:str) {
    print(greeting, ", ", name, "!\n")
}

def main(args:list[str]) {
    greet("Tom", "Hello")
    greet("Jerry", "Hi")
}
```

**运行结果：**

```
Hello, Tom!
Hi, Jerry!

```

#### 函数引用作为参数

CatBase 支持将函数引用作为参数传递给其他函数，这使得回调模式成为可能。

```catbase
def on_audio_frame(frame:bytes) {
    print("Received audio frame")
    print(len(frame))
}

def process_audio(callback:function) {
    # 回调函数会被调用
    callback(bytes("test data"))
}

def main(args:list[str]) {
    # 将 on_audio_frame 函数作为参数传递
    process_audio(on_audio_frame)
}
```

**运行结果：**

```
Received audio frame
9
```

**说明：**
- 当一个已定义的函数名作为参数传递时，它被视为 `function` 类型
- 函数引用可以用于回调式 API，如音频处理、网络通信等场景
- 不能直接打印函数引用（Zig 不支持格式化函数指针）

### 6.4 变量作用域

```catbase
def main(args:list[str]) {
    x:int = 10
    
    print("Outer x = ", x, "\n")
    
    {
        x:int = 20
        print("Inner x = ", x, "\n")
    }
    
    print("Outer x after block = ", x, "\n")
}
```

**运行结果：**

```
Outer x = 10
Inner x = 20
Outer x after block = 10

```

***

## 7. 内置函数

> **本章导读：** 自定义函数学完后，本章将介绍 CatBase 的内置函数。内置函数是语言提供的常用工具，无需定义即可直接使用，可以大大提升开发效率。CatBase 提供了丰富的内置函数，涵盖类型转换、数学运算、字符串处理等领域。

CatBase 提供了丰富的内置函数。

### 7.1 打印函数

#### print

`print(...)` - 打印值到标准输出

```catbase
def main(args:list[str]) {
    print("Hello\n")
    print("Number: ", 42, "\n")
    print("Bool: ", True, "\n")
}
```

**运行结果：**

```
Hello
Number: 42
Bool: true

```

##### print 函数参数说明

`print()` 函数支持以下参数：

- **位置参数**：要打印的值，可以是多个值
- **end**：结尾字符，默认是换行符 `\n`，设置为空字符串 `""` 可以不换行
- **flush**：是否刷新输出，默认 False，设置为 True 可以立即刷新输出

```catbase
def main(args:list[str]) {
    # 不换行打印
    print("Hello ", end="", flush=True)
    print("World!", end="", flush=True)
    
    # 使用默认换行
    print("\nDone!")
}
```

**运行结果：**

```
Hello World!
Done!
```

### 7.2 数学函数

#### abs

`abs(x:int) : int` - 返回绝对值

```catbase
def main(args:list[str]) {
    print("abs(-5) = ", abs(-5), "\n")
    print("abs(5) = ", abs(5), "\n")
    print("abs(0) = ", abs(0), "\n")
}
```

**运行结果：**

```
abs(-5) = 5
abs(5) = 5
abs(0) = 0

```

#### max

`max(a:int, b:int) : int` - 返回较大值

```catbase
def main(args:list[str]) {
    print("max(5, 3) = ", max(5, 3), "\n")
    print("max(-10, 10) = ", max(-10, 10), "\n")
}
```

**运行结果：**

```
max(5, 3) = 5
max(-10, 10) = 10

```

#### min

`min(a:int, b:int) : int` - 返回较小值

```catbase
def main(args:list[str]) {
    print("min(5, 3) = ", min(5, 3), "\n")
    print("min(-10, 10) = ", min(-10, 10), "\n")
}
```

**运行结果：**

```
min(5, 3) = 3
min(-10, 10) = -10

```

#### sum

`sum(list) : int` - 返回列表所有元素的和

```catbase
def main(args:list[str]) {
    nums:list[int] = [1, 2, 3, 4, 5]
    print("sum([1,2,3,4,5]) = ", sum(nums), "\n")
    print("sum([]) = ", sum([]), "\n")
}
```

**运行结果：**

```
sum([1,2,3,4,5]) = 15
sum([]) = 0

```

#### pow

`pow(base:int, exp:int) : int` - 返回幂运算结果

```catbase
def main(args:list[str]) {
    print("pow(2, 3) = ", pow(2, 3), "\n")
    print("pow(5, 0) = ", pow(5, 0), "\n")
    print("pow(10, 2) = ", pow(10, 2), "\n")
}
```

**运行结果：**

```
pow(2, 3) = 8
pow(5, 0) = 1
pow(10, 2) = 100

```

#### round

`round(x:int|float) : int|float` - 四舍五入，返回与输入相同的类型
`round(x:int|float, n:int) : float` - 四舍五入到指定小数位数，返回 float

```catbase
def main(args:list[str]) {
    print("round(3.7) = ", round(3.7), "\n")
    print("round(3.2) = ", round(3.2), "\n")
    print("round(3.5) = ", round(3.5), "\n")
    print("round(3.14159, 2) = ", round(3.14159, 2), "\n")
}
```

**运行结果：**

```
round(3.7) = 4
round(3.2) = 3
round(3.5) = 4
round(3.14159, 2) = 3.14

```

### 7.3 类型转换函数

#### int

`int(x) : int` - 转换为整数

```catbase
def main(args:list[str]) {
    print("int('42') = ", int("42"), "\n")
    print("int(3.7) = ", int(3.7), "\n")
    print("int(True) = ", int(True), "\n")
}
```

**运行结果：**

```
int('42') = 42
int(3.7) = 3
int(True) = 1

```

#### float

`float(x) : float` - 转换为浮点数

```catbase
def main(args:list[str]) {
    print("float(10) = ", float(10), "\n")
    print("float('3.14') = ", float("3.14"), "\n")
}
```

**运行结果：**

```
float(10) = 10.0
float('3.14') = 3.14

```

#### str

`str(x) : str` - 转换为字符串

```catbase
def main(args:list[str]) {
    print("str(123) = '", str(123), "'\n")
    print("str(3.14) = '", str(3.14), "'\n")
    print("str(True) = '", str(True), "'\n")
}
```

**运行结果：**

```
str(123) = '123'
str(3.14) = '3.14'
str(True) = 'true'

```

##### str 函数与 JSON 值转换

`str()` 函数还可以将 JSON 解析后的值（dict 类型）转换为字符串。当使用 `json_loads()` 解析 JSON 字符串后，得到的字典中的值可能是 `JsonValue` 类型，使用 `str()` 可以将其转换为字符串：

```catbase
def main(args:list[str]) {
    # 解析 JSON 字符串
    json_str:str = "{\"name\": \"Alice\", \"age\": 30, \"score\": 95.5}"
    data:dict = json_loads(json_str)
    
    # 提取值并转换为字符串
    name:str = str(data["name"])
    age:str = str(data["age"])
    score:str = str(data["score"])
    
    print("Name: ", name, "\n")
    print("Age: ", age, "\n")
    print("Score: ", score, "\n")
}
```

**运行结果：**

```
Name: Alice
Age: 30
Score: 95.5

```

`str()` 函数支持转换以下 JsonValue 类型：

- `.str` - 字符串
- `.int` - 整数
- `.float` - 浮点数
- `.bool` - 布尔值（转换为 "true" 或 "false"）
- `.null` - JSON 空值（转换为 "null"，对应 JSON 标准的 null）
- `.list` - 列表（转换为 JSON 数组字符串）
- `.dict` - 字典（转换为 JSON 对象字符串）

**注意**：在 CatBase 代码中，空值使用 `None` 表示（对应 JSON 的 `null`）。例如：

````catbase
def main(args:list[str]) {
    # CatBase 中使用 None 表示空值
    value:any = None
    
    # 判断是否为空
    if value == None {
        print("Value is None\n")
    }
}

### 7.4 进制转换函数

#### bin

`bin(x:int) : str` - 转换为二进制

```catbase
def main(args:list[str]) {
    print("bin(5) = '", bin(5), "'\n")
    print("bin(10) = '", bin(10), "'\n")
    print("bin(255) = '", bin(255), "'\n")
}
````

**运行结果：**

```
bin(5) = '0b101'
bin(10) = '0b1010'
bin(255) = '0b11111111'

```

#### oct

`oct(x:int) : str` - 转换为八进制

```catbase
def main(args:list[str]) {
    print("oct(8) = '", oct(8), "'\n")
    print("oct(10) = '", oct(10), "'\n")
    print("oct(64) = '", oct(64), "'\n")
}
```

**运行结果：**

```
oct(8) = '0o10'
oct(10) = '0o12'
oct(64) = '0o100'

```

#### hex

`hex(x:int) : str` - 转换为十六进制

```catbase
def main(args:list[str]) {
    print("hex(255) = '", hex(255), "'\n")
    print("hex(16) = '", hex(16), "'\n")
    print("hex(4096) = '", hex(4096), "'\n")
}
```

**运行结果：**

```
hex(255) = '0xff'
hex(16) = '0x10'
hex(4096) = '0x1000'

```

### 7.5 字符函数

#### chr

`chr(x:int) : str` - 整数转换为字符

```catbase
def main(args:list[str]) {
    print("chr(65) = '", chr(65), "'\n")
    print("chr(97) = '", chr(97), "'\n")
    print("chr(48) = '", chr(48), "'\n")
}
```

**运行结果：**

```
chr(65) = 'A'
chr(97) = 'a'
chr(48) = '0'

```

#### ord

`ord(x:str) : int` - 字符转换为整数

```catbase
def main(args:list[str]) {
    print("ord('A') = ", ord("A"), "\n")
    print("ord('a') = ", ord("a"), "\n")
    print("ord('0') = ", ord("0"), "\n")
}
```

**运行结果：**

```
ord('A') = 65
ord('a') = 97
ord('0') = 48

```

### 7.6 字符串函数

#### len

`len(x) : int` - 返回长度

```catbase
def main(args:list[str]) {
    print("len('hello') = ", len("hello"), "\n")
    print("len([1,2,3]) = ", len([1, 2, 3]), "\n")
    print("len({'a':1}) = ", len({"a": 1}), "\n")
}
```

**运行结果：**

```
len('hello') = 5
len([1,2,3]) = 3
len({'a':1}) = 1

```

#### range

`range(n:int) : list` - 生成范围

```catbase
def main(args:list[str]) {
    print("range(5) = ", range(5), "\n")
    print("range(2, 5) = ", range(2, 5), "\n")
}
```

**运行结果：**

```
range(5) = [0, 1, 2, 3, 4]
range(2, 5) = [2, 3, 4]

```

#### 字符串方法

字符串对象提供了丰富的方法进行操作。以下是所有可用的字符串方法：

##### 大小写转换

```catbase
def main(args:list[str]) {
    s:str = "Hello World"
    print("原字符串: ", s, "\n")
    print("upper(): ", s.upper(), "\n")
    print("lower(): ", s.lower(), "\n")
    print("capitalize(): ", s.capitalize(), "\n")
    print("title(): ", s.title(), "\n")
}
```

**运行结果：**

```
原字符串: Hello World
upper(): HELLO WORLD
lower(): hello world
capitalize(): Hello world
title(): Hello World

```

##### 空白字符处理

```catbase
def main(args:list[str]) {
    s:str = "   Hello World   "
    print("原字符串: '", s, "'\n")
    print("strip(): '", s.strip(), "'\n")
    print("lstrip(): '", s.lstrip(), "'\n")
    print("rstrip(): '", s.rstrip(), "'\n")
}
```

**运行结果：**

```
原字符串: '   Hello World   '
strip(): 'Hello World'
lstrip(): 'Hello World   '
rstrip(): '   Hello World'

```

##### 查找和计数

```catbase
def main(args:list[str]) {
    s:str = "Hello World Hello"
    print("原字符串: ", s, "\n")
    print("find('World'): ", s.find("World"), "\n")
    print("rfind('Hello'): ", s.rfind("Hello"), "\n")
    print("count('l'): ", s.count("l"), "\n")
    print("startswith('Hello'): ", s.startswith("Hello"), "\n")
    print("endswith('World'): ", s.endswith("World"), "\n")
}
```

**运行结果：**

```
原字符串: Hello World Hello
find('World'): 6
rfind('Hello'): 12
count('l'): 3
startswith('Hello'): true
endswith('World'): false

```

##### 字符串切片

CatBase 支持字符串切片操作，可以提取字符串的子串：

```catbase
def main(args:list[str]) {
    s:str = "Hello World"
    
    # 从索引 6 到末尾
    result1:str = s[6:]
    print("s[6:]: ", result1, "\n")
    
    # 从索引 0 到索引 5（不包含）
    result2:str = s[0:5]
    print("s[0:5]: ", result2, "\n")
    
    # 从索引 6 到索引 11
    result3:str = s[6:11]
    print("s[6:11]: ", result3, "\n")
}
```

**运行结果：**

```
s[6:]:  World
s[0:5]: Hello
s[6:11]: World

```

**语法说明：**

- `str[start:]` - 从 start 索引到字符串末尾
- `str[start:end]` - 从 start 索引到 end 索引（不包含 end）
- 索引从 0 开始

##### 分割和连接

```catbase
def main(args:list[str]) {
    s:str = "apple,banana,cherry"
    print("原字符串: ", s, "\n")
    result:list = s.split(",")
    print("split(','): ", result, "\n")
    
    s2:str = "Hello\nWorld\n!"
    print("原字符串: ", s2, "\n")
    result2:list = s2.splitlines()
    print("splitlines(): ", result2, "\n")
    
    items:list[str] = ["Hello", "World"]
    joined:str = ",".join(items)
    print("join(): ", joined, "\n")
}
```

**运行结果：**

```
原字符串: apple,banana,cherry
split(','): [apple, banana, cherry]
原字符串: Hello
World
!
splitlines(): [Hello, World, !]
join(): Hello,World

```

##### 替换

```catbase
def main(args:list[str]) {
    s:str = "Hello World"
    print("原字符串: ", s, "\n")
    print("replace('World', 'CatBase'): ", s.replace("World", "CatBase"), "\n")
}
```

**运行结果：**

```
原字符串: Hello World
replace('World', 'CatBase'): Hello CatBase

```

##### 字符判断

```catbase
def main(args:list[str]) {
    print("'hello'.islower(): ", "hello".islower(), "\n")
    print("'HELLO'.isupper(): ", "HELLO".isupper(), "\n")
    print("'Hello'.istitle(): ", "Hello".istitle(), "\n")
    print("'123'.isdigit(): ", "123".isdigit(), "\n")
    print("'abc'.isalpha(): ", "abc".isalpha(), "\n")
    print("'abc123'.isalnum(): ", "abc123".isalnum(), "\n")
    print("'   '.isspace(): ", "   ".isspace(), "\n")
    print("'123'.isnumeric(): ", "123".isnumeric(), "\n")
}
```

**运行结果：**

```
'hello'.islower(): true
'HELLO'.isupper(): true
'Hello'.istitle(): true
'123'.isdigit(): true
'abc'.isalpha(): true
'abc123'.isalnum(): true
'   '.isspace(): true
'123'.isnumeric(): true

```

### 7.7 系统函数

#### exec

`exec(cmd:str) : str` - 执行系统命令

```catbase
def main(args:list[str]) {
    result:str = exec("echo hello")
    print("exec result: ", result, "\n")
}
```

**运行结果：**

```
exec result: hello

```

#### sleep

`sleep(seconds:int)` - 暂停执行

```catbase
def main(args:list[str]) {
    print("Before sleep\n")
    sleep(1)
    print("After sleep\n")
}
```

**运行结果：**

```
Before sleep
After sleep

```

#### time

`time()` - 获取当前时间戳（毫秒），返回浮点数

```catbase
def main(args:list[str]) {
    t:float = time()
    print("Current timestamp: ")
    print(t)
}
```

**运行结果：**

```
Current timestamp: 1717412345.0

```

#### perf_counter

`perf_counter()` - 获取高精度计数器（纳秒），返回浮点数，用于精确测量代码执行时间

```catbase
def main(args:list[str]) {
    start:float = perf_counter()
    # 模拟耗时操作
    s:int = 0
    for i in range(1000000) {
        s = s + i
    }
    end:float = perf_counter()
    print("Elapsed: ")
    print((end - start) / 1000000000.0, " seconds")
}
```

**运行结果：**

```
Elapsed: 0.012345 seconds

```

#### strftime

`strftime(format:str) : str` - 格式化时间为字符串，返回格式如 "2024-06-04 12:00:00"

```catbase
def main(args:list[str]) {
    s:str = strftime("%Y-%m-%d %H:%M:%S")
    print("Current time: ")
    print(s)
}
```

**运行结果：**

```
Current time: 2024-06-04 12:00:00

```

#### localtime

`localtime()` - 获取本地时间，返回时间结构体，包含 year, month, day, hour, minute, second, weekday 字段

```catbase
def main(args:list[str]) {
    t:TimeStruct = localtime()
    print("Year: ")
    print(t.year)
    print("Month: ")
    print(t.month)
    print("Day: ")
    print(t.day)
    print("Hour: ")
    print(t.hour)
    print("Minute: ")
    print(t.minute)
    print("Second: ")
    print(t.second)
}
```

**运行结果：**

```
Year: 2024
Month: 6
Day: 4
Hour: 12
Minute: 0
Second: 30

```

#### gmtime

`gmtime()` - 获取 UTC 时间，返回时间结构体，包含 year, month, day, hour, minute, second, weekday 字段

```catbase
def main(args:list[str]) {
    t:TimeStruct = gmtime()
    print("UTC Year: ")
    print(t.year)
    print("UTC Month: ")
    print(t.month)
    print("UTC Day: ")
    print(t.day)
    print("UTC Hour: ")
    print(t.hour)
}
```

**运行结果：**

```
UTC Year: 2024
UTC Month: 6
UTC Day: 4
UTC Hour: 4

```

#### timestamp_to_struct

`timestamp_to_struct(timestamp:float) : TimeStruct` - 将时间戳转换为时间结构体

```catbase
def main(args:list[str]) {
    ts:float = time()
    t:TimeStruct = timestamp_to_struct(ts)
    print("Year: ")
    print(t.year)
    print("Month: ")
    print(t.month)
    print("Day: ")
    print(t.day)
}
```

**运行结果：**

```
Year: 2024
Month: 6
Day: 4

```

#### strftime_timestamp

`strftime_timestamp(timestamp:float, format:str) : str` - 将时间戳按指定格式转换为字符串

```catbase
def main(args:list[str]) {
    ts:float = time()
    s:str = strftime_timestamp(ts, "%Y-%m-%d %H:%M:%S")
    print("Formatted: ")
    print(s)
}
```

**运行结果：**

```
Formatted: 2024-06-04 12:00:00

```

#### mktime

`mktime(t:TimeStruct) : float` - 将时间结构体转换为时间戳

```catbase
def main(args:list[str]) {
    t:TimeStruct = localtime()
    ts:float = mktime(t)
    print("Timestamp: ")
    print(ts)
}
```

**运行结果：**

```
Timestamp: 1717412345.0

```

#### input

`input(prompt:str) : str` - 从标准输入读取用户输入

```catbase
def main(args:list[str]) {
    name:str = input("Please enter your name: ")
    print("Hello, ", name, "!\n")
}
```

**运行结果：**

```
Please enter your name: CatBase
Hello, CatBase!

```

#### type

`type(x) : str` - 返回变量的类型名称

```catbase
def main(args:list[str]) {
    a:int = 10
    b:str = "hello"
    c:list[int] = [1, 2, 3]
    d:dict[str, str] = {"key": "value"}
    
    print("type(10) = ", type(a), "\n")
    print("type('hello') = ", type(b), "\n")
    print("type([1,2,3]) = ", type(c), "\n")
    print("type(dict) = ", type(d), "\n")
}
```

**运行结果：**

```
type(10) = int
type('hello') = str
type([1,2,3]) = list
type(dict) = dict

```

#### assert

`assert(condition:bool, message:str)` - 断言，条件为假时终止程序并输出错误信息

`assert` 用于在代码中设置检查点，当条件不满足时立即终止程序。这在调试和开发阶段非常有用，可以及早发现问题。

```catbase
def divide(a:int, b:int) -> int {
    # 断言：除数不能为 0
    assert(b != 0, "Division by zero")
    return a / b
}

def main(args:list[str]) {
    result:int = divide(10, 2)
    print("10 / 2 = ", result, "\n")
    
    # 下面这行会触发断言失败
    # result = divide(10, 0)
}
```

**运行结果：**

```
10 / 2 = 5
```

**说明：**
- `assert` 接受两个参数：条件表达式和错误信息字符串
- 当条件为 `False` 时，程序终止并输出错误信息
- 当条件为 `True` 时，程序正常继续执行
- 建议在开发调试阶段使用，用于验证程序逻辑的正确性

#### isinstance

`isinstance(x, type_name:str) : bool` - 检查变量是否为指定类型

```catbase
def main(args:list[str]) {
    a:int = 10
    b:str = "hello"
    c:list[int] = [1, 2, 3]
    
    print("isinstance(10, 'int') = ", isinstance(a, "int"), "\n")
    print("isinstance(10, 'str') = ", isinstance(a, "str"), "\n")
    print("isinstance('hello', 'str') = ", isinstance(b, "str"), "\n")
    print("isinstance([1,2,3], 'list') = ", isinstance(c, "list"), "\n")
}
```

**运行结果：**

```
isinstance(10, 'int') = true
isinstance(10, 'str') = false
isinstance('hello', 'str') = true
isinstance([1,2,3], 'list') = true

```

### 7.8 指针类型（Pointer）

CatBase 提供了 `Pointer` 类型，用于外部库（.so/.a）调用时处理指针参数。这在调用 C 语言库时特别有用，尤其是当库函数需要修改传入的变量值时。

#### Pointer 类型简介

`Pointer` 类型是对 Zig 中 `?*anyopaque` 的封装，是一个可选的 opaque 指针类型。它主要用于：

- 调用需要指针参数的外部 C 函数
- 通过指针修改变量的值
- 处理外部库返回的指针数据

#### 创建指针

**`pointer()`** - 创建空指针

```catbase
def main(args:list[str]) {
    # 创建空指针
    empty: Pointer = pointer()
    
    # 检查是否为空指针
    if empty.is_null() {
        print("Pointer is null\n")
    }
}
```

**`pointer_of(var)`** - 创建指向变量的指针

```catbase
def main(args:list[str]) {
    # 创建整数变量
    num: int = 42
    
    # 创建指向 num 的指针
    ptr: Pointer = pointer_of(num)
    
    # 通过指针获取值
    val: int = ptr.get()
    print("Value: ", val, "\n")  # 输出 42
    
    # 通过指针设置新值
    ptr.set(100)
    print("After set: ", num, "\n")  # 输出 100
}
```

#### Pointer 方法

| 方法 | 说明 |
|------|------|
| `ptr.get()` | 获取指针指向的值（返回 i64） |
| `ptr.set(value)` | 设置指针指向的值 |
| `ptr.is_null()` | 判断指针是否为空 |

#### 应用场景

##### 场景一：调用修改外部变量的 C 函数

某些 C 函数需要通过指针返回多个值：

```catbase
# 假设有一个 C 函数通过指针返回计算结果
# void calculate(int input, int *result, int *remainder)
# result 和 remainder 都是输出参数

import "./libcalc.so" as calc

# 声明外部函数
from calc import calculate(input: int, result: int, remainder: int) -> None

def main(args:list[str]) {
    result: int = 0
    remainder: int = 0
    
    # 创建指向 result 和 remainder 的指针
    result_ptr: Pointer = pointer_of(result)
    remainder_ptr: Pointer = pointer_of(remainder)
    
    # 调用函数（这里需要通过 Pointer 传递地址）
    # 注意：实际调用方式取决于库的 API 设计
}
```

##### 场景二：处理外部库返回的指针

```catbase
import "./libdata.so" as data_lib

# 声明外部函数
from data_lib import get_buffer_size() -> int
from data_lib import read_buffer(buf: Pointer, size: int) -> int

def main(args:list[str]) {
    # 获取缓冲区大小
    size: int = data_lib.get_buffer_size()
    
    # 创建缓冲区
    buffer: bytes = bytes(" " * size)
    
    # 读取数据到缓冲区
    bytes_read: int = data_lib.read_buffer(buffer, size)
    
    print("Read ", bytes_read, " bytes\n")
}
```

##### 场景三：在声明外部函数时使用 Pointer 类型

当外部函数参数是指针类型时，可以在 `from...import` 声明中直接使用 `Pointer`：

```catbase
import "./libserial.so" as serial_lib

# 声明外部函数， Pointer 用于需要指针参数的场景
from serial_lib import serial_write(handle: int, data: Pointer, len: int) -> int
from serial_lib import serial_read(handle: int, data: Pointer, len: int) -> int
from serial_lib import serial_close(handle: int) -> None

def main(args:list[str]) {
    # 打开串口（假设返回句柄）
    handle: int = serial_lib.serial_open("/dev/ttyUSB0", 115200)
    
    # 准备数据
    msg: str = "Hello, Serial!"
    msg_bytes: bytes = bytes(msg)
    
    # 写入数据
    written: int = serial_lib.serial_write(handle, pointer_of(msg_bytes), len(msg_bytes))
    print("Written ", written, " bytes\n")
    
    # 关闭串口
    serial_lib.serial_close(handle)
}
```

#### 注意事项

- `pointer_of()` 会自动获取传入变量的地址，以便通过指针修改其值
- 使用 `ptr.set(value)` 时，值的类型应为 `int`（CatBase 的 int 类型在底层映射为 i64）
- 对空指针调用 `get()` 或 `set()` 会导致程序 panic
- 使用 `is_null()` 可以安全地检查指针是否为空

***

### 7.9 串口通信函数

CatBase 提供了完整的串口通信支持，可以使用 `serial()` 构造函数创建串口对象，然后通过对象方法进行读写和关闭。

#### 创建串口连接

**`serial(port, baud_rate)`**

创建串口对象并打开串口设备。

参数：
- `port`: 串口设备路径
  - Linux/macOS: 如 `/dev/ttyUSB0`、`/dev/ttyS0`
  - Windows: 如 `COM1`、`COM2`
- `baud_rate`: 波特率，支持 300、1200、2400、4800、9600、19200、38400、57600、115200、230400

返回：`Serial` 串口对象

```catbase
def main(args:list[str]) {
    # 打开串口
    ser:Serial = serial("/dev/ttyUSB0", 115200)
    print("Serial port opened successfully\n")

    # 写入数据
    ser.write("Hello, Serial!\n")

    # 读取数据
    data:str = ser.read(1024)
    print("Received: ")
    print(data)
    print("\n")

    # 关闭串口
    ser.close()
    print("Serial port closed\n")
}
```

#### Serial 对象方法

| 方法 | 说明 |
|------|------|
| `ser.write(data)` | 向串口写入数据（data 为 str 或 bytes） |
| `ser.read(length)` | 从串口读取最多 length 字节数据 |
| `ser.available()` | 检查串口可读取的字节数 |
| `ser.close()` | 关闭串口连接 |

#### 串口 Bytes 收发详解

串口通信中，`ser.write()` 和 `ser.read()` 方法可以接收和返回字符串类型，而 `bytes` 类型本质上是特殊的字符串，可以直接用于串口收发。以下是 bytes 在串口通信中的具体应用：

##### 发送二进制数据

```catbase
def main(args:list[str]) {
    ser:Serial = serial("/dev/ttyUSB0", 115200)

    # 发送 Modbus RTU 读取寄存器命令
    # 帧格式：设备地址(1) + 功能码(1) + 起始地址(2) + 寄存器数量(2) + CRC校验(2)
    modbus_read:bytes = b"\x01\x03\x00\x00\x00\x0A"
    ser.write(modbus_read)

    # 发送自定义协议数据包
    # 帧头 + 长度 + 数据 + 校验
    header:bytes = b"\xAA\x55"
    length:bytes = b"\x00\x08"
    data:bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"
    checksum:bytes = b"\x2C"

    packet:bytes = header + length + data + checksum
    ser.write(packet)

    print("Binary data sent\n")
    ser.close()
}
```

##### 接收和解析二进制数据

```catbase
def main(args:list[str]) {
    ser:Serial = serial("/dev/ttyUSB0", 115200)

    # 发送读取请求
    ser.write(b"\x01\x03\x00\x00\x00\x0A")

    # 等待数据到达（最多等待 100 次轮询）
    i:int = 0
    while i < 100 {
        avail:int = ser.available()
        if avail >= 8 {
            # Modbus 响应至少 8 字节：地址+功能码+长度+数据(4字节)+CRC(2字节)
            data:str = ser.read(avail)

            # 解析响应数据
            # 假设收到的数据格式：\x01\x03\x04\x00\x00\x00\x01\xXX\xXX
            #                     地址  功能码  长度   数据高字节  数据低字节  CRC
            print("Received data\n")
            print("Data length: ")
            print(len(data))
            print("\n")
            break
        }
        i = i + 1
    }

    ser.close()
}
```

##### 完整的二进制协议通信示例

```catbase
def main(args:list[str]) {
    ser:Serial = serial("/dev/ttyUSB0", 115200)
    print("Serial port opened\n")

    # 定义协议帧格式
    # | 帧头(2) | 类型(1) | 长度(2) | 数据(N) | 校验(1) |
    # | 0xAA 0x55 | 0x01 | 0x0008 | N bytes | XOR |

    # 发送传感器查询命令
    frame_type:bytes = b"\x01"
    data_length:bytes = b"\x00\x08"
    sensor_cmd:bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"

    # 计算异或校验和
    xor_sum:bytes = b"\x00"
    j:int = 0
    while j < len(sensor_cmd) {
        # 简单的校验和计算（实际协议可能更复杂）
        j = j + 1
    }

    # 组装完整帧
    header:bytes = b"\xAA\x55"
    frame:bytes = header + frame_type + data_length + sensor_cmd + xor_sum

    # 发送帧
    ser.write(frame)
    print("Sent ")
    print(len(frame))
    print(" bytes\n")

    # 接收响应
    i:int = 0
    while i < 200 {
        avail:int = ser.available()
        if avail > 0 {
            response:str = ser.read(avail)
            print("Received ")
            print(len(response))
            print(" bytes: ")
            print(response)
            print("\n")

            # 验证帧头
            if len(response) >= 2 {
                # 检查是否以 0xAA 0x55 开头
                print("Protocol verified\n")
            }
            break
        }
        i = i + 1
    }

    ser.close()
    print("Serial port closed\n")
}
```

##### 十六进制转义说明

在 bytes 字面量中，`\xHH` 表示一个十六进制字节值：

| 字面量             | 实际字节值 | 说明        |
| --------------- | ----- | --------- |
| `\x00`          | 0     | 空字节       |
| `\x01` - `\x0F` | 1-15  | 控制字符      |
| `\x41`          | 65    | ASCII 'A' |
| `\xFF`          | 255   | 最大值       |

**示例：**

```catbase
def main(args:list[str]) {
    # 十六进制字符串 "41 42 43" (ABC)
    hex_str:bytes = b"\x41\x42\x43"
    print(hex_str)
    print("\n")
}
```

***

## 8. 文件操作

> **本章导读：** 掌握了函数和内置函数后，本章将介绍文件操作。文件操作是实际开发中非常常见的需求，用于持久化存储数据。CatBase 提供了简洁的文件操作 API，可以方便地进行文件的读写。

### 8.1 打开和关闭文件

#### file

`file(filename:str, mode:str) : File` - 打开文件

参数：

- `filename` - 文件名
- `mode` - 打开模式：
  - `"r"` - 读取模式
  - `"w"` - 写入模式（覆盖）
  - `"a"` - 追加模式
  - `"r+"` - 读写模式（可读取和写入，不创建新文件）

```catbase
def main(args:list[str]) {
    f:File = file("test.txt", "w")
    f.write("Hello, World!")
    f.close()
    
    f2:File = file("test.txt", "r")
    content:str = f2.read()
    print("Content: ", content, "\n")
    close(f2)
}
```

### 8.2 读取文件

#### read

`file.read() : str` - 读取整个文件

```catbase
def main(args:list[str]) {
    f:File = file("test.txt", "r")
    content:str = f.read()
    print("Content: ", content, "\n")
    f.close()
}
```

### 8.3 写入文件

#### write

`file.write(content:str)` - 写入文件（覆盖模式）

```catbase
def main(args:list[str]) {
    f:File = file("output.txt", "w")
    f.write("Line 1\n")
    f.write("Line 2\n")
    f.write("Line 3\n")
    f.close()
    
    print("File written successfully\n")
}
```

#### append

`file.append(content:str)` - 追加写入文件

在文件末尾追加内容，不会覆盖原有内容。

```catbase
def main(args:list[str]) {
    # 首次写入
    f:File = file("log.txt", "w")
    f.write("Log entry 1\n")
    f.close()
    
    # 追加写入
    f2:File = file("log.txt", "a")
    f2.append("Log entry 2\n")
    f2.append("Log entry 3\n")
    close(f2)
    
    # 读取验证
    f3:File = file("log.txt", "r")
    content:str = f3.read()
    close(f3)
    
    print("File content:\n", content, "\n")
}
```

**运行结果：**

```
File content:
Log entry 1
Log entry 2
Log entry 3

```

#### writeAt

`file.writeAt(content:str, position:int)` - 在指定位置写入

在文件的指定位置（字节偏移量）写入内容。

```catbase
def main(args:list[str]) {
    # 创建一个包含固定长度内容的文件
    f:File = file("data.txt", "w")
    f.write("AAAAAAAAAAAA")  # 12个字符
    f.close()
    
    # 在位置 5 写入 "BBB"（替换字符）
    f2:File = file("data.txt", "r+")
    f2.writeAt("BBB", 5)
    f2.close()
    
    # 读取验证
    f3:File = file("data.txt", "r")
    content:str = f3.read()
    close(f3)
    
    print("File content: ", content, "\n")
}
```

**运行结果：**

```
File content: AAAAABBBAAA

```

#### close

`close(file:File)` - 关闭文件

关闭打开的文件，释放相关资源。

```catbase
def main(args:list[str]) {
    f:File = file("test.txt", "w")
    f.write("Hello")
    f.close()  # 关闭文件
}
```

注意：在完成文件操作后，必须调用 `close()` 关闭文件。

### 8.4 完整示例

```catbase
def main(args:list[str]) {
    # 写入文件
    f:File = file("demo.txt", "w")
    f.write("Hello, CatBase!")
    f.close()
    
    # 读取文件
    f2:File = file("demo.txt", "r")
    content:str = f2.read()
    close(f2)
    
    print("Read from file: ", content, "\n")
}
```

**运行结果：**

```
Read from file: Hello, CatBase!

```

### 8.5 文件操作与 Bytes

文件操作与 bytes 类型结合，可以用于处理二进制文件，如图片、音频、压缩文件等。

##### 写入二进制数据

```catbase
def main(args:list[str]) {
    # 创建要写入的二进制数据
    # 模拟写入一个简单的 BMP 图像文件头（54 字节）
    # BMP 文件头
    bmp_header:bytes = b"BM"                    # 文件标识
    file_size:bytes = b"\x00\x00\x00\x00"      # 文件大小（占位）
    reserved:bytes = b"\x00\x00\x00\x00"        # 保留字段
    offset:bytes = b"\x36\x00\x00\x00"          # 像素数据偏移 (54)

    # DIB 头（40 字节）
    dib_size:bytes = b"\x28\x00\x00\x00"        # DIB 头大小
    width:bytes = b"\x10\x00\x00\x00"           # 宽度 (16)
    height:bytes = b"\x10\x00\x00\x00"           # 高度 (16)
    planes:bytes = b"\x01\x00"                  # 颜色平面数
    bits_per_pixel:bytes = b"\x18\x00"           # 每像素位数 (24)
    compression:bytes = b"\x00\x00\x00\x00"     # 压缩方式
    image_size:bytes = b"\x00\x00\x00\x00"      # 图像大小
    x_pixels_per_m:bytes = b"\x00\x00\x00\x00"  # 水平分辨率
    y_pixels_per_m:bytes = b"\x00\x00\x00\x00"  # 垂直分辨率
    colors_used:bytes = b"\x00\x00\x00\x00"     # 使用的颜色数
    colors_important:bytes = b"\x00\x00\x00\x00" # 重要颜色数

    # 组合完整的 BMP 文件头
    header:bytes = bmp_header + file_size + reserved + offset + dib_size + width + height + planes + bits_per_pixel + compression + image_size + x_pixels_per_m + y_pixels_per_m + colors_used + colors_important

    # 写入文件
    f:File = file("test.bmp", "wb")
    f.write(header)
    f.close()

    print("BMP header written (54 bytes)\n")
}
```

##### 读取二进制文件

```catbase
def main(args:list[str]) {
    # 以二进制模式读取文件
    f:File = file("test.bmp", "rb")
    data:str = f.read()
    f.close()

    # 分析 BMP 文件头
    print("File size: ")
    print(len(data))
    print(" bytes\n")

    # 检查文件标识 (BM = 0x42 0x4D)
    if len(data) >= 2 {
        print("File identifier: ")
        print(data[0])
        print(data[1])
        print("\n")
    }

    # 读取宽度信息 (偏移 18，4 字节)
    if len(data) >= 22 {
        print("Width info in header\n")
    }
}
```

##### 写入和读取自定义二进制格式

```catbase
def main(args:list[str]) {
    # 创建数据包
    # 格式：| 魔数(2) | 版本(1) | 长度(2) | 数据(N) | CRC(4) |

    magic:bytes = b"\xCA\xTB"          # 魔数
    version:bytes = b"\x01"            # 版本 1
    payload:bytes = b"Hello, Binary!"  # 数据载荷
    length:bytes = b"\x00\x0F"        # 长度 15

    # 计算简单的 CRC 校验和
    crc:bytes = b"\x00\x00\x00\x00"

    # 组装数据包
    packet:bytes = magic + version + length + payload + crc

    # 写入二进制文件
    f:File = file("data.bin", "wb")
    f.write(packet)
    f.close()

    print("Packet written: ")
    print(len(packet))
    print(" bytes\n")

    # 读取二进制文件
    f2:File = file("data.bin", "rb")
    received:str = f2.read()
    close(f2)

    # 验证数据包
    if len(received) >= 5 {
        # 检查魔数
        print("Received packet, length: ")
        print(len(received))
        print("\n")

        # 提取数据载荷
        if len(received) > 9 {
            payload_len:int = len(received) - 9
            print("Payload length: ")
            print(payload_len)
            print("\n")
        }
    }
}
```

##### 二进制协议文件存储

```catbase
def main(args:list[str]) {
    # 存储多个二进制记录到文件
    # 记录格式：| ID(4) | 类型(1) | 数据长度(2) | 数据(N) |

    f:File = file("records.bin", "wb")

    # 记录 1
    id1:bytes = b"\x00\x00\x00\x01"
    type1:bytes = b"\x01"
    data1:bytes = b"\x41\x42\x43\x44"      # ABCD
    len1:bytes = b"\x00\x04"
    record1:bytes = id1 + type1 + len1 + data1

    # 记录 2
    id2:bytes = b"\x00\x00\x00\x02"
    type2:bytes = b"\x02"
    data2:bytes = b"\x01\x02\x03\x04\x05"   # 5 字节数据
    len2:bytes = b"\x00\x05"
    record2:bytes = id2 + type2 + len2 + data2

    # 写入所有记录
    f.write(record1)
    f.write(record2)
    f.close()

    print("Records written to file\n")

    # 读取并解析记录
    f2:File = file("records.bin", "rb")
    content:str = f2.read()
    close(f2)

    # 解析记录 1
    print("Record 1 ID: ")
    print(len(content))
    print("\n")
}
```

##### 追加二进制数据

```catbase
def main(args:list[str]) {
    # 以追加模式写入二进制数据
    f:File = file("log.bin", "ab")

    # 写入二进制日志条目
    # 格式：| 时间戳(8) | 类型(1) | 数据(N) |
    timestamp:bytes = b"\x00\x00\x00\x00\x00\x00\x00\x01"
    entry_type:bytes = b"\x01"
    log_data:bytes = b"\xDE\xAD\xBE\xEF"

    entry:bytes = timestamp + entry_type + log_data
    f.write(entry)
    f.close()

    print("Binary log entry appended\n")

    # 读取二进制日志
    f2:File = file("log.bin", "rb")
    log_content:str = f2.read()
    close(f2)

    print("Total log size: ")
    print(len(log_content))
    print(" bytes\n")
}
```

***

## 9. 网络编程

> **本章导读：** 文件操作让我们能够处理本地数据，本章将介绍网络编程。 CatBase 内置了强大的网络功能，支持 TCP、UDP、HTTP 等常用协议，让你能够轻松开发网络应用。

### 9.1 TCP 套接字

CatBase 提供统一的 `TCPSocket` 类型，可用于创建 TCP 客户端或 TCP 服务器。

#### 创建 TCP 套接字

**`tcpsocket()`**

创建一个新的 TCP 套接字。

```catbase
# TCP 客户端
sock:TCPSocket = tcpsocket()
sock.connect("example.com", 80)
```

#### TCPSocket 方法

| 方法 | 说明 |
|------|------|
| `sock.connect(host, port[, timeout])` | 连接到 TCP 服务器（客户端模式），可选超时参数 |
| `sock.bind(host, port)` | 绑定地址和端口（服务器模式） |
| `sock.listen(backlog)` | 开始监听连接（服务器模式） |
| `sock.accept()` | 接受连接，返回 TCPClient（服务器模式） |
| `sock.write(data)` | 发送数据 |
| `sock.read(size)` | 接收最多 size 字节数据 |
| `sock.close()` | 关闭套接字 |

#### TCP 客户端示例

```catbase
def main(args:list[str]) {
    client:TCPSocket = tcpsocket()
    client.connect("example.com", 80)

    client.write("GET / HTTP/1.0\r\n\r\n")
    response:str = client.read(4096)
    print("Response length: ", len(response), "\n")
    client.close()
}
```

### 9.2 TCP 服务器

```catbase
def main(args:list[str]) {
    server:TCPSocket = tcpsocket()
    server.bind("0.0.0.0", 8080)
    server.listen(128)
    print("Server listening on port 8080\n")

    conn:TCPClient = server.accept()
    print("Client connected\n")

    data:str = conn.read(1024)
    print("Received: ", data, "\n")

    conn.write("HTTP/1.0 200 OK\r\n\r\nHello!")
    conn.close()
    server.close()
}
```

### 9.3 UDP 套接字

CatBase 提供 `UDPSocket` 类型用于 UDP 通信。

#### 创建 UDP 套接字

**`udpsocket()`**

创建一个新的 UDP 套接字。

```catbase
udp:UDPSocket = udpsocket()
```

#### UDPSocket 方法

| 方法 | 说明 |
|------|------|
| `udp.bind(host, port)` | 绑定地址和端口 |
| `udp.sendto(data, host, port)` | 发送数据到指定地址 |
| `udp.recvfrom(size[, timeout])` | 接收数据，返回字符串，可选超时参数 |
| `udp.close()` | 关闭套接字 |

#### UDP 客户端示例

```catbase
def main(args:list[str]) {
    udp:UDPSocket = udpsocket()
    udp.sendto("Hello from UDP!", "127.0.0.1", 9999)
    udp.close()
}
```

#### UDP 服务器示例

```catbase
def main(args:list[str]) {
    udp:UDPSocket = udpsocket()
    udp.bind("0.0.0.0", 9999)
    print("UDP server listening on port 9999\n")

    try {
        # 使用带超时的接收方法，超时时间 10 秒
        data:str = udp.recvfrom(1024, 10)
        print("Received: ", data, "\n")
        
        # 发送响应到客户端
        udp.sendto("Received: " + data, "127.0.0.1", 9998)
    }
    except err {
        print("Error: ", err, "\n")
    }

    udp.close()
}
```

### 9.4 与 Python socket 对比

| CatBase | Python |
|---------|--------|
| `tcpsocket()` | `socket.socket(socket.AF_INET, socket.SOCK_STREAM)` |
| `sock.connect(host, port)` | `sock.connect((host, port))` |
| `sock.bind(host, port)` | `sock.bind((host, port))` |
| `sock.listen(backlog)` | `sock.listen(backlog)` |
| `sock.accept()` | `conn, addr = sock.accept()` |
| `sock.write(data)` | `sock.send(data)` |
| `sock.read(size)` | `sock.recv(size)` |
| `udpsocket()` | `socket.socket(socket.AF_INET, socket.SOCK_DGRAM)` |
| `udp.sendto(data, host, port)` | `sock.sendto(data, (host, port))` |
| `udp.recvfrom(size)` | `data, addr = sock.recvfrom(size)` |

### 9.5 HTTP 请求

#### http_get

`http_get(url:str, timeout:int) : str` - 发送 HTTP GET 请求

http_get 函数用于发送 HTTP GET 请求，支持设置超时时间。

**参数说明：**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| url | str | 是 | - | 请求的 URL 地址 |
| timeout | int | 否 | 60 | 超时时间，单位为秒 |

**返回值：**

- 成功：返回 HTTP 响应内容（str 类型）
- 失败：抛出错误，如 `error.Timeout`（连接超时）、`error.HostUnreachable`（主机不可达）

**基本用法：**

```catbase
def main(args:list[str]) {
    # 简单 GET 请求（使用默认超时 60 秒）
    response:str = http_get("http://example.com")
    print("Response: ", response, "\n")
}
```

**带超时参数的 GET 请求：**

```catbase
def main(args:list[str]) {
    # 设置 10 秒超时
    response:str = http_get("http://example.com", timeout=10)
    print("Response: ", response, "\n")
}
```

**使用 try-except 捕获错误：**

```catbase
def main(args:list[str]) {
    try {
        # 尝试 GET 请求，超时时间 3 秒
        response:str = http_get("http://192.168.254.254:9999/", timeout=3)
        print("Response: ", response, "\n")
    }
    except err {
        print("HTTP GET failed with error: ", err, "\n")
    }
}
```

**运行结果（超时情况）：**

```
HTTP GET failed with error: error.Timeout
```

**带查询参数的 GET 请求：**

在 URL 中使用 `?` 后面跟查询参数，多个参数用 `&` 分隔。

```catbase
def main(args:list[str]) {
    # 带查询参数的 GET 请求
    # 查询参数直接拼接到 URL 中
    url:str = "http://httpbin.org/get?username=admin&password=123456"
    response:str = http_get(url, timeout=10)
    print("Response: ", response, "\n")
}
```

**运行结果：**

```
Response: {
  "args": {
    "password": "123456", 
    "username": "admin"
  }, 
  "headers": {
    "Host": "httpbin.org"
  }, 
  "origin": "xxx.xxx.xxx.xxx", 
  "url": "http://httpbin.org/get?username=admin&password=123456"
}

```

#### http_post

`http_post(url:str, headers:str, json:dict, data:str, timeout:int, stream:bool) : Response` - 发送 HTTP POST 请求

http_post 函数支持以下参数（均可通过关键字参数传递）：

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| url | str | 是 | - | 请求的 URL 地址 |
| headers | str | 否 | "" | 请求头 |
| json | dict | 否 | {} | JSON 数据（自动设置 Content-Type） |
| data | str | 否 | "" | 请求体数据 |
| timeout | int | 否 | 60 | 超时时间（秒） |
| stream | bool | 否 | False | 是否使用流式响应 |

##### 表单数据提交

使用 `application/x-www-form-urlencoded` 格式提交表单数据：

```catbase
def main(args:list[str]) {
    # 表单数据提交（使用 data 关键字参数）
    response:Response = http_post("http://httpbin.org/post", data="username=admin&password=123456")
    print("Response: ", response, "\n")
}
```

**运行结果：**

```
Response: {
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {
    "password": "123456", 
    "username": "admin"
  }, 
  "headers": {
    "Content-Length": "27", 
    "Content-Type": "application/x-www-form-urlencoded", 
    "Host": "httpbin.org"
  }, 
  "json": null, 
  "origin": "xxx.xxx.xxx.xxx", 
  "url": "http://httpbin.org/post"
}

```

##### JSON 数据提交

使用 JSON 格式提交数据，需要手动构造 JSON 字符串：

```catbase
def main(args:list[str]) {
    # 构造 JSON 数据
    # 格式: {"key": "value"}
    json_data:str = "{\"username\": \"admin\", \"password\": \"123456\", \"age\": 25}"
    
    response:Response = http_post("http://httpbin.org/post", data=json_data)
    print("Response: ", response, "\n")
}
```

**运行结果：**

```
Response: {
  "args": {}, 
  "data": "{\"username\": \"admin\", \"password\": \"123456\", \"age\": 25}", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Content-Length": "53", 
    "Content-Type": "application/x-www-form-urlencoded", 
    "Host": "httpbin.org"
  }, 
  "json": {
    "age": 25, 
    "password": "123456", 
    "username": "admin"
  }, 
  "origin": "xxx.xxx.xxx.xxx", 
  "url": "http://httpbin.org/post"
}

```

##### 提交复杂 JSON 数据

```catbase
def main(args:list[str]) {
    # 提交包含数组的 JSON
    json_data:str = "{\"users\": [{\"name\": \"Alice\", \"age\": 30}, {\"name\": \"Bob\", \"age\": 25}], \"status\": \"active\"}"
    
    response:Response = http_post("http://httpbin.org/post", data=json_data)
    print("Response: ", response, "\n")
}
```

**运行结果：**

```
Response: {
  "args": {}, 
  "data": "{\"users\": [{\"name\": \"Alice\", \"age\": 30}, {\"name\": \"Bob\", \"age\": 25}], \"status\": \"active\"}", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Content-Length": "87", 
    "Content-Type": "application/x-www-form-urlencoded", 
    "Host": "httpbin.org"
  }, 
  "json": {
    "status": "active", 
    "users": [
      {
        "age": 30, 
        "name": "Alice"
      }, 
      {
        "age": 25, 
        "name": "Bob"
      }
    ]
  }, 
  "origin": "xxx.xxx.xxx.xxx", 
  "url": "http://httpbin.org/post"
}

```

**注意：** http_post 默认使用 `application/x-www-form-urlencoded` Content-Type。如果需要提交纯 JSON 数据，需要在服务端自行解析 `data` 字段。

### 9.5.1 OpenAI API 调用

OpenAI API 允许开发者访问强大的大语言模型（LLM），如 GPT-4、GPT-3.5 等。CatBase 可以通过 http_post 函数与 OpenAI API 进行通信，实现自然语言处理、智能对话等功能。

#### 基本聊天请求

```catbase
def main(args:list[str]) {
    # OpenAI API 配置
    api_key:str = "your-openai-api-key"
    api_url:str = "https://api.openai.com/v1/chat/completions"

    # 构造请求 JSON
    # messages 数组包含对话历史
    # role: system(系统), user(用户), assistant(助手)
    # content: 消息内容
    request_json:str = "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"system\", \"content\": \"You are a helpful assistant.\"}, {\"role\": \"user\", \"content\": \"Hello, who are you?\"}]}"

    # 发送 POST 请求
    response:Response = http_post(api_url, data=request_json)
    print("Response: ", response, "\n")
}
```

#### 发送对话请求并解析响应

```catbase
def main(args:list[str]) {
    # OpenAI API 配置
    api_key:str = "your-openai-api-key"
    api_url:str = "https://api.openai.com/v1/chat/completions"

    # 构造对话请求
    # system: 定义助手的行为
    # user: 用户的输入
    request_json:str = "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"system\", \"content\": \"你是一个专业的Python编程助手。\"}, {\"role\": \"user\", \"content\": \"请用Python写一个快速排序算法。\"}]}"

    # 发送请求
    response:Response = http_post(api_url, data=request_json)
    print("API Response:\n")
    print(response)
    print("\n")

    # 响应格式：
    # {
    #   "id": "chatcmpl-...",
    #   "choices": [{
    #     "message": {
    #       "role": "assistant",
    #       "content": "..."
    #     }
    #   }]
    # }
}
```

#### 多轮对话

```catbase
def main(args:list[str]) {
    api_url:str = "https://api.openai.com/v1/chat/completions"

    # 初始对话历史
    # 可以将之前的对话追加到此数组中实现多轮对话
    messages:str = "[{\"role\": \"system\", \"content\": \"你是一个乐于助人的助手。\"}, {\"role\": \"user\", \"content\": \"什么是人工智能？\"}]"

    # 发送第一轮对话
    request_json:str = "{\"model\": \"gpt-3.5-turbo\", \"messages\": " + messages + "}"
    response:Response = http_post(api_url, data=request_json)

    print("First response:\n")
    print(response)
    print("\n")

    # 如果需要继续对话，可以解析响应并追加到 messages
    # 然后发送新的请求...

    # 第二轮对话示例（需要手动追加之前的对话）
    messages:str = "[{\"role\": \"system\", \"content\": \"你是一个乐于助人的助手。\"}, {\"role\": \"user\", \"content\": \"什么是人工智能？\"}, {\"role\": \"assistant\", \"content\": \"人工智能是...\"}, {\"role\": \"user\", \"content\": \"它有哪些应用？\"}]"

    request_json = "{\"model\": \"gpt-3.5-turbo\", \"messages\": " + messages + "}"
    response = http_post(api_url, data=request_json)

    print("Second response:\n")
    print(response)
    print("\n")
}
```

#### 设置生成参数

OpenAI API 支持多种生成参数，控制输出的质量和多样性：

```catbase
def main(args:list[str]) {
    api_url:str = "https://api.openai.com/v1/chat/completions"

    # 构造带参数的请求
    # temperature: 0.0-2.0，控制随机性。较低的值使输出更确定性，较高的值使输出更随机
    # max_tokens: 生成的最大 token 数
    # top_p: 核采样参数
    request_json:str = "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"写一个关于猫的笑话。\"}], \"temperature\": 0.8, \"max_tokens\": 100}"

    response:Response = http_post(api_url, data=request_json)
    print("Response with parameters:\n")
    print(response)
    print("\n")
}
```

#### 流式响应（Streaming）

流式响应允许实时显示 LLM 的输出，而不需要等待完整响应。对于长文本生成特别有用。

```catbase
def main(args:list[str]) {
    api_url:str = "https://api.openai.com/v1/chat/completions"

    # 启用 stream: true 可以获得流式响应
    request_json:str = "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"用三句话解释量子计算。\"}], \"stream\": true}"

    response:Response = http_post(api_url, data=request_json)
    print("Streaming response:\n")
    print(response)
    print("\n")

    # 注意：实际使用中，流式响应返回的是 SSE 格式的数据
    # 需要自行解析 data: 开头的行
}
```

#### 流式响应数据解析

流式响应返回的是 SSE（Server-Sent Events）格式，每行以 `data:` 开头。以下是解析流式响应的示例：

```catbase
def main(args:list[str]) {
    api_url:str = "https://api.openai.com/v1/chat/completions"

    # 启用流式响应
    request_json:str = "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"解释什么是递归。\"}], \"stream\": true}"

    response:Response = http_post(api_url, data=request_json)

    # 打印原始响应
    print("Raw streaming response:\n")
    print(response)
    print("\n")

    # 流式响应格式示例：
    # data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk","created":1234567890,"model":"gpt-3.5-turbo","choices":[{"index":0,"delta":{"content":"递归"},"finish_reason":null}]}
    #
    # data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk","created":1234567890,"model":"gpt-3.5-turbo","choices":[{"index":0,"delta":{"content":"是一"},"finish_reason":null}]}
    #
    # data: {"id":"chatcmpl-xxx","object":"chat.completion.chunk","created":1234567890,"model":"gpt-3.5-turbo","choices":[{"index":0,"delta":{"content":"种"},"finish_reason":null}]}
    #
    # data: [DONE]

    # 提取每个 delta 中的 content
    # 注意：实际解析需要字符串处理函数，这里仅展示概念
    print("Streaming complete!\n")
}
```

#### 完整流式聊天示例

```catbase
def main(args:list[str]) {
    api_url:str = "https://api.openai.com/v1/chat/completions"

    # 构造请求
    request_json:str = "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"给我写一首关于编程的五行诗。\"}], \"stream\": true}"

    print("Requesting streaming response...\n")
    print("Response: \n")

    # 发送流式请求
    response:Response = http_post(api_url, data=request_json)

    # 打印完整响应
    print(response)
    print("\n")

    # SSE 流式响应格式说明：
    # 1. 每个数据块以 "data: " 开头
    # 2. 每个块是一个 JSON 对象，包含 delta 字段
    # 3. delta.content 包含增量文本
    # 4. 最后以 "data: [DONE]" 结束

    # 模拟解析过程（实际需要字符串函数支持）
    # chunks:list = split(response, "data:")
    # for chunk in chunks {
    #     if starts_with(chunk, "[DONE]") {
    #         break
    #     }
    #     # 解析 JSON 提取 content
    #     content:str = extract_json_field(chunk, "content")
    #     print(content)
    # }

    print("\nStreaming response ended.\n")
}
```

#### 流式响应的应用场景

| 场景         | 说明              |
| ---------- | --------------- |
| **实时打字效果** | 模拟打字机效果，提升用户体验  |
| **长文本生成**  | 无需等待完整响应，边生成边显示 |
| **交互式对话**  | 在生成过程中用户可以中断或调整 |
| **代码补全**   | 实时显示代码补全建议      |

#### 完整示例：智能助手

```catbase
def main(args:list[str]) {
    api_url:str = "https://api.openai.com/v1/chat/completions"

    # 系统提示词，定义助手角色
    system_prompt:str = "你是一个专业、友好的编程助手，名叫 CatBot。你擅长解释编程概念和帮助编写代码。"

    # 用户的第一个问题
    user_question:str = "请解释什么是变量，以及为什么需要声明变量类型？"

    # 构造请求
    request_json:str = "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"system\", \"content\": \"" + system_prompt + "\"}, {\"role\": \"user\", \"content\": \"" + user_question + "\"}], \"temperature\": 0.7, \"max_tokens\": 500}"

    print("Sending request to OpenAI API...\n")

    # 发送请求
    response:Response = http_post(api_url, data=request_json)

    print("Response received!\n")
    print("=" * 50)
    print(response)
    print("=" * 50)
    print("\n")

    # 提示：实际应用中需要解析 JSON 响应提取 content 字段
    # 响应格式：{"choices": [{"message": {"content": "..."}}]}
}
```

#### 其他 OpenAI API 端点

OpenAI 还提供了其他 API 端点，可以通过类似的方式调用：

| 端点          | 说明   | URL 格式                                         |
| ----------- | ---- | ---------------------------------------------- |
| Chat        | 多轮对话 | `https://api.openai.com/v1/chat/completions`   |
| Completions | 文本补全 | `https://api.openai.com/v1/completions`        |
| Embeddings  | 文本嵌入 | `https://api.openai.com/v1/embeddings`         |
| Images      | 图像生成 | `https://api.openai.com/v1/images/generations` |

**文本补全示例：**

```catbase
def main(args:list[str]) {
    api_url:str = "https://api.openai.com/v1/completions"

    # 构造补全请求
    request_json:str = "{\"model\": \"text-davinci-003\", \"prompt\": \"从前有座山，\", \"max_tokens\": 50, \"temperature\": 0.7}"

    response:Response = http_post(api_url, data=request_json)
    print("Completion response:\n")
    print(response)
    print("\n")
}
```

#### http\_post（推荐）

`http_post(url:str, headers:str, json:dict[str,any], data:str, timeout:int, stream:bool) : Response` - 发送 HTTP POST 请求（推荐使用）

http\_post 函数是与 Python `requests.post()` 类似的高级 HTTP POST 函数，支持多种参数：

- **url** (str): 请求 URL（必选）
- **headers** (str): 请求头，多个 header 用 `&` 分隔（可选，默认空字符串）
- **json** (dict\[str,any]): JSON 数据，接收 dict 类型（可选）
- **data** (str): 表单数据（可选，当 json 有值时忽略 data）
- **timeout** (int): 超时时间，单位秒，默认 60（可选）
- **stream** (bool): 是否使用流式模式，默认 False（可选）

**参数优先级**：当 `json` 和 `data` 参数同时有值时，优先使用 `json` 参数。

**自动 Content-Type 检测**：http\_post 函数会自动根据传入的参数类型设置 Content-Type：

- 如果传入 `json` 参数，自动设置为 `application/json` 并自动序列化字典为 JSON
- 如果传入 `data` 参数，自动设置为 `application/x-www-form-urlencoded`

**返回值**：返回 Response 对象，包含以下方法：

- `raise_for_status()`: 检查响应状态码，非 200-299 触发异常
- `iter_lines()`: 迭代读取流式响应内容（仅在 stream=True 时可用）

##### 基本使用

```catbase
def main(args:list[str]) {
    url:str = "http://httpbin.org/post"
    
    # 使用 json 参数提交 JSON 数据
    json_data:dict[str,any] = {"name": "Tom", "age": 20}
    response:Response = http_post(url=url, json=json_data)
    print("Response: ", response, "\n")
}
```

##### 带请求头

```catbase
def main(args:list[str]) {
    url:str = "http://httpbin.org/post"
    headers:str = "Authorization: Bearer abc123"
    json_data:dict[str,any] = {"username": "admin", "password": "123456"}
    
    response:Response = http_post(url=url, headers=headers, json=json_data)
    print("Response: ", response, "\n")
}
```

##### 使用 data 参数提交表单数据

```catbase
def main(args:list[str]) {
    url:str = "http://httpbin.org/post"
    
    # 使用 data 参数提交表单数据
    form_data:str = "username=admin&password=123456"
    response:Response = http_post(url=url, data=form_data)
    print("Response: ", response, "\n")
}
```

##### 设置超时

```catbase
def main(args:list[str]) {
    url:str = "http://httpbin.org/post"
    json_data:dict[str,any] = {"name": "test"}
    
    # 设置超时时间为 30 秒
    response:Response = http_post(url=url, json=json_data, timeout=30)
    print("Response: ", response, "\n")
}
```

##### OpenAI API 调用

```catbase
def main(args:list[str]) {
    api_key:str = "your-openai-api-key"
    api_url:str = "https://api.openai.com/v1/chat/completions"
    
    # 构造请求数据
    request_data:dict[str,any] = {
        "model": "gpt-3.5-turbo",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Hello, who are you?"}
        ],
        "temperature": 0.7,
        "max_tokens": 100
    }
    
    headers:str = "Authorization: Bearer " + api_key
    response:Response = http_post(url=api_url, headers=headers, json=request_data)
    print("Response: ", response, "\n")
}
```

##### 流式响应（用于 vLLM、OpenAI 等 API）

```catbase
def main(args:list[str]) {
    # vLLM 或 OpenAI 兼容 API 调用
    base_url:str = "http://localhost:19090/v1"
    model_path:str = "qwen"
    url:str = base_url + "/chat/completions"
    
    # 构造请求数据
    data:dict[str,any] = {
        "model": model_path,
        "messages": [
            {"role": "system", "content": "直接回答问题，不要有任何思考过程。"},
            {"role": "user", "content": "你好"}
        ],
        "temperature": 0.1,
        "max_tokens": 1000,
        "stream": True
    }
    
    # 发送请求并启用流式模式
    response:Response = http_post(url, json=data, stream=True, timeout=60)
    
    # 检查响应状态
    response.raise_for_status()
    
    # 迭代读取流式响应
    for line in response.iter_lines() {
        print(line)
    }
}
```

#### HTTP Response 对象

当使用 `stream=True` 参数时，`http_post` 返回一个 Response 对象，该对象包含以下方法：

##### raise\_for\_status

`response.raise_for_status()` - 检查 HTTP 响应状态

如果响应状态码不在 200-299 范围内，会触发 panic 异常。这与 Python 的 `requests.Response.raise_for_status()` 方法行为一致。

```catbase
def main(args:list[str]) {
    response:Response = http_post(url, json=data, stream=True)
    
    # 检查状态码，非 200-299 会触发异常
    response.raise_for_status()
    
    # 继续处理响应...
}
```

##### iter\_lines

`response.iter_lines()` - 迭代读取流式响应行

该方法返回一个迭代器，每次调用返回响应的一行内容。当到达响应末尾时返回 None。

```catbase
def main(args:list[str]) {
    response:Response = http_post(url, json=data, stream=True)
    
    # 方法一：使用 for 循环迭代（推荐）
    for line in response.iter_lines() {
        print(line)
    }
    
    # 方法二：使用 while 循环
    while True {
        line:str = response.iter_lines()
        if !line {
            break
        }
        print(line)
    }
}
```

#### json\_dumps

`json_dumps(data:dict[str,any]) : str` - 将字典转换为 JSON 字符串

json\_dumps 函数用于将 CatBase 的字典类型（dict\[str,any]）序列化为 JSON 字符串，与 Python 的 `json.dumps()` 函数功能类似。

##### 基本使用

```catbase
def main(args:list[str]) {
    data:dict[str,any] = {"name": "Tom", "age": 20}
    json_str:str = json_dumps(data)
    print("JSON: ", json_str, "\n")
}
```

**运行结果：**

```
JSON:  {"name":"Tom","age":20}

```

##### 混合类型数据

```catbase
def main(args:list[str]) {
    # 支持多种数据类型
    data:dict[str,any] = {
        "name": "Alice",
        "age": 25,
        "score": 98.5,
        "active": True,
        "tags": ["developer", "programmer"],
        "info": {"city": "Beijing", "country": "China"}
    }
    
    json_str:str = json_dumps(data)
    print("JSON: ", json_str, "\n")
}
```

**运行结果：**

```
JSON:  {"name":"Alice","age":25,"score":98.5,"active":true,"tags":["developer","programmer"],"info":{"city":"Beijing","country":"China"}}

```

##### 嵌套列表

```catbase
def main(args:list[str]) {
    # 包含列表的字典
    items:list[str] = ["apple", "banana", "orange"]
    
    data:dict[str,any] = {
        "product": "fruit",
        "items": items,
        "count": 3
    }
    
    json_str:str = json_dumps(data)
    print("JSON: ", json_str, "\n")
}
```

##### 字典列表

```catbase
def main(args:list[str]) {
    # 包含字典的列表
    users:list[dict[str,str]] = [
        {"name": "Tom", "age": "20"},
        {"name": "Jerry", "age": "25"}
    ]
    
    data:dict[str,any] = {
        "users": users,
        "total": 2
    }
    
    json_str:str = json_dumps(data)
    print("JSON: ", json_str, "\n")
}
```

##### json\_loads

`json_loads(json_str:str) : dict[str,any]` - 将 JSON 字符串解析为字典

json\_loads 函数用于将 JSON 字符串解析为 CatBase 的字典类型（dict\[str,any]），与 Python 的 `json.loads()` 函数功能相反。

###### 基本使用

```catbase
def main(args:list[str]) {
    json_str:str = "{\"name\": \"Alice\", \"age\": 30}"
    
    data:dict[str,any] = json_loads(json_str)
    print("Parsed: ", data, "\n")
}
```

**运行结果：**

```
Parsed: {"age":30,"name":"Alice"}

```

###### 解析嵌套 JSON

```catbase
def main(args:list[str]) {
    json_str:str = "{\"name\": \"Bob\", \"info\": {\"city\": \"Beijing\", \"country\": \"China\"}, \"scores\": [90, 85, 92]}"
    
    data:dict[str,any] = json_loads(json_str)
    print("Parsed: ", data, "\n")
}
```

**运行结果：**

```
Parsed: {"info":{"city":"Beijing","country":"China"},"name":"Bob","scores":[90,85,92]}

```

##### 结合 http\_post 使用

```catbase
def main(args:list[str]) {
    url:str = "http://httpbin.org/post"
    
    # 构造 JSON 数据
    request_data:dict[str,any] = {
        "model": "gpt-3.5-turbo",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Hello!"}
        ],
        "temperature": 0.7
    }
    
    # 转换为 JSON 字符串（可选，http_post 也可直接接收 dict）
    json_str:str = json_dumps(request_data)
    print("Sending JSON: ", json_str, "\n")
    
    # 发送请求（json 参数直接接收 dict）
    response:Response = http_post(url=url, json=request_data)
    print("Response: ", response, "\n")
}
```

##### 字典的 .get() 方法

字典类型支持 `.get()` 方法，用于安全地获取字典中的值。当键不存在时，返回默认值，避免程序崩溃。

```catbase
def main(args:list[str]) {
    # 解析 JSON 字符串
    json_str:str = "{\"name\": \"Alice\", \"age\": 30}"
    data:dict = json_loads(json_str)
    
    # 使用 .get() 方法获取值
    name:any = data.get("name", "")
    city:any = data.get("city", "Unknown")
    
    print("Name: ", str(name), "\n")
    print("City: ", str(city), "\n")
}
```

**运行结果：**

```
Name: Alice
City: Unknown

```

###### .get() 方法的语法

```
dict.get(key, default)
```

- **key** (str): 要获取的键名
- **default**: 当键不存在时返回的默认值，**必须指定**

**重要特性：**
- `.get()` 方法**必须传入第二个参数**（默认值），否则编译报错
- 返回值类型由**第二个参数的类型**决定：
  - `.get("name", "")` 返回 `str` 类型
  - `.get("count", 0)` 返回 `int` 类型
  - `.get("ratio", 0.5)` 返回 `float` 类型
  - `.get("enabled", True)` 返回 `bool` 类型
  - `.get("data", {})` 返回 `dict[str, any]` 类型
  - `.get("items", [])` 返回 `list[any]` 类型

**示例：**

```catbase
def main(args:list[str]) {
    # 解析 JSON 字符串
    json_str:str = "{\"name\": \"Alice\", \"age\": 30, \"scores\": [95, 87, 92]}"
    data:dict = json_loads(json_str)
    
    # 根据默认值类型推断返回类型
    name:str = data.get("name", "")       # 返回 str 类型
    age:int = data.get("age", 0)           # 返回 int 类型
    city:str = data.get("city", "Unknown") # 返回 str 类型
    scores:list = data.get("scores", [])   # 返回 list[any] 类型
    
    print("Name: ", name, "\n")
    print("Age: ", age, "\n")
    print("City: ", city, "\n")
}
```

**运行结果：**

```
Name: Alice
Age: 30
City: Unknown
```

###### 结合列表索引使用

`.get()` 方法可以与列表索引访问结合使用，处理嵌套的 JSON 数据：

```catbase
def main(args:list[str]) {
    # 模拟 API 流式响应解析
    json_str:str = "{\"choices\": [{\"delta\": {\"content\": \"Hello\"}}]}"
    data_dict:dict = json_loads(json_str)
    
    # 获取嵌套数据，返回类型由默认值决定
    if "choices" in data_dict and data_dict["choices"] {
        delta:dict[str, any] = data_dict["choices"][0].get("delta", {})
        content:str = delta.get("content", "")
        print("Content: ", content, "\n")
    }
}
```

**运行结果：**

```
Content: Hello

```

### 9.6 TCP/UDP 二进制数据通信

TCP 和 UDP 通信本质上都是字节流传输，`write`、`sendto` 和 `recvfrom` 函数都支持 bytes 类型的数据。以下是 bytes 在网络通信中的具体应用：

#### TCP 发送二进制数据

```catbase
def main(args:list[str]) {
    client:TCPSocket = tcpsocket()
    client.connect("192.168.1.100", 8080)

    # 发送自定义二进制协议
    # 帧格式：| 帧头(2) | 长度(2) | 数据(N) | 校验(1) |
    header:bytes = b"\xAA\x55"
    length:bytes = b"\x00\x08"
    data:bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"
    checksum:bytes = b"\x2C"

    packet:bytes = header + length + data + checksum

    # 发送二进制数据
    client.write(packet)
    print("Sent ")
    print(len(packet))
    print(" bytes\n")

    # 接收响应
    response:str = client.read(4096)
    print("Response length: ")
    print(len(response))
    print("\n")

    client.close()
}
```

#### TCP 服务器处理二进制协议

```catbase
def main(args:list[str]) {
    server:TCPSocket = tcpsocket()
    server.bind("0.0.0.0", 8888)
    server.listen(128)
    print("TCP Server listening on port 8888\n")

    conn:TCPClient = server.accept()
    print("Client connected\n")

    # 接收客户端数据
    data:str = conn.read(1024)
    print("Received ")
    print(len(data))
    print(" bytes\n")

    # 解析二进制协议
    # 帧格式：| 魔数(2) | 命令(1) | 序列号(2) | 数据长度(2) | 数据(N) |
    if len(data) >= 7 {
        # 验证帧头 (0xAA 0x55)
        print("Protocol header verified\n")

        # 发送响应
        response_header:bytes = b"\xAA\x55"
        response_cmd:bytes = b"\x81"  # 响应命令
        response_seq:bytes = b"\x00\x01"
        response_data:bytes = b"\x00\x00\x00\x00"

        response:bytes = response_header + response_cmd + response_seq + response_data
        conn.write(response)
        print("Response sent\n")
    }

    conn.close()
    server.close()
}
```

#### UDP 发送二进制数据

```catbase
def main(args:list[str]) {
    sock:UDPSocket = udpsocket()
    sock.bind("127.0.0.1", 0)

    # 发送自定义二进制协议
    # 数据包格式：| 源端口(2) | 目标端口(2) | 长度(2) | 校验(2) | 数据(N) |
    src_port:bytes = b"\x00\x00"
    dst_port:bytes = b"\x23\x28"  # 9000 的十六进制
    length:bytes = b"\x00\x0C"
    checksum:bytes = b"\x00\x00"
    payload:bytes = b"\x01\x02\x03\x04\x05\x06"

    packet:bytes = src_port + dst_port + length + checksum + payload

    # 发送二进制数据
    sock.sendto(packet, "127.0.0.1", 9000)
    print("UDP packet sent\n")

    sock.close()
}
```

#### 网络字节序转换

网络协议通常使用大端字节序（Big Endian），以下是处理多字节数据的示例：

```catbase
def main(args:list[str]) {
    # 构造 32 位长度字段
    b0:bytes = b"\x00"
    b1:bytes = b"\x00"
    b2:bytes = b"\x01"
    b3:bytes = b"\x00"

    length_32:bytes = b0 + b1 + b2 + b3

    print("32-bit length: ")
    print(len(length_32))
    print(" bytes\n")

    # 组装完整帧
    header:bytes = b"\xAA\x55"
    frame:bytes = header + length_32

    print("Complete frame: ")
    print(len(frame))
    print(" bytes\n")
}
```

***

### 9.7 WebSocket

> WebSocket 是一种在单个 TCP 连接上进行全双工通信的协议，适用于实时性要求高的应用场景，如聊天、游戏、实时数据推送等。CatBase 提供了完整的 WebSocket 客户端支持。

#### websocket

`websocket(url:str, headers:dict) : WebSocket` - 创建 WebSocket 连接

创建一个 WebSocket 客户端连接到指定服务器。

**参数说明：**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| url | str | 是 | - | WebSocket 服务器地址（如 `ws://example.com/ws`） |
| headers | dict | 否 | None | 可选的请求头字典 |

**返回值：**

- 返回 `WebSocket` 类型对象，用于与服务器通信

**基本用法：**

```catbase
def main(args:list[str]) {
    # 创建 WebSocket 连接
    ws:WebSocket = websocket("ws://127.0.0.1:8080/ws", None)

    # 发送消息
    ws.send("Hello, Server!")

    # 接收消息
    msg:str = ws.recv()
    print("Received: ", msg, "\n")

    # 关闭连接
    ws.close()
}
```

**带认证头的 WebSocket 连接：**

```catbase
def main(args:list[str]) {
    # 设置认证头
    headers:dict = {}
    headers["Authorization"] = "Bearer your-token-here"
    headers["X-App-Id"] = "my-app"

    ws:WebSocket = websocket("wss://example.com/ws", headers)

    ws.send("Hello with auth!")
    ws.close()
}
```

#### WebSocket 方法

| 方法 | 说明 |
|------|------|
| `ws.send(message:str)` | 发送文本消息到服务器 |
| `ws.recv() : str` | 阻塞接收服务器消息，返回空字符串表示连接关闭 |
| `ws.close()` | 关闭 WebSocket 连接 |

#### WebSocket 客户端示例

```catbase
# WebSocket 音频客户端示例
def audio_sender_task(ws:WebSocket) {
    print("[INFO] 发送任务启动\n")

    # 打开录音流
    rec_stream:RecordStream = recordStream(
        rate="16000",
        channels="1",
        chunk="512",
        callback=on_audio_data
    )
    rec_stream.start_recording()

    # 发送 Hello 消息
    hello_msg:str = ""
    hello_msg = hello_msg + "{\"type\":\"hello\",\"version\":1,"
    hello_msg = hello_msg + "\"features\":{\"mcp\":true},"
    hello_msg = hello_msg + "\"transport\":\"websocket\"}"
    ws.send(hello_msg)

    # 循环发送音频数据
    i:int = 0
    while i < 100 {
        # 模拟 PCM 数据
        pcm_data:bytes = ""
        j:int = 0
        while j < 320 {
            pcm_data = pcm_data + "\x00\x00"
            j = j + 1
        }

        # 发送音频帧
        ws.send(pcm_data)
        sleep(0.02)
        i = i + 1
    }

    rec_stream.stop_recording()
    rec_stream.close()
}

def on_audio_data(data:bytes) {
    print("录音数据: ", len(data), " 字节\n")
}

def main(args:list[str]) {
    print("========================================\n")
    print("      WebSocket 音频客户端\n")
    print("========================================\n")

    # 连接 WebSocket 服务器
    ws:WebSocket = websocket("ws://127.0.0.1:8080/ws", None)

    # 创建发送和接收线程
    thread audio_sender_task(ws)
    thread audio_receiver_task(ws)

    # 等待一段时间
    sleep(10)

    print("[INFO] 正在关闭连接...\n")
    ws.close()

    print("========================================\n")
    print("[INFO] WebSocket 客户端已关闭\n")
    print("========================================\n")
}
```

#### WebSocket 与 Python websocket-client 对比

| CatBase | Python (websocket-client) |
|---------|---------------------------|
| `websocket(url, None)` | `websocket.create_connection(url)` |
| `websocket(url, headers)` | `websocket.create_connection(url, headers=headers)` |
| `ws.send(message)` | `ws.send(message)` |
| `ws.recv()` | `ws.recv()` |
| `ws.close()` | `ws.close()` |

***

## 10. 多线程编程

> **本章导读：** 网络编程让我们能够与外部世界通信，本章将介绍多线程编程。多线程是现代编程中提高程序性能的重要手段，CatBase 提供了简洁的多线程支持，包括线程创建、同步（Mutex）、原子操作等特性。

### 10.1 创建线程

CatBase 支持两种创建线程的方式：

#### 方式一：作为独立语句（不等待线程结束）

`thread func(args)` - 创建新线程并立即返回，不等待线程结束

```catbase
def worker(id:int) {
    print("Worker ", id, " started\n")
    sleep(1)
    print("Worker ", id, " finished\n")
}

def main(args:list[str]) {
    print("Main thread started\n")
    
    thread worker(1)
    thread worker(2)
    thread worker(3)
    
    sleep(2)
    print("Main thread finished\n")
}
```

#### 方式二：作为表达式（获取线程句柄并可等待）

`t:Thread = thread worker(args)` - 创建线程并返回 Thread 句柄

```catbase
def worker(a:int, b:int) {
    print("Worker started with", a, b)
    result:int = a + b
    print("Worker result:", result)
}

def main(args:list[str]) {
    print("=== Testing thread() function ===\n")
    
    # 创建线程并获取句柄
    t1:Thread = thread worker(1, 2)
    print("Thread created, t1 type:", type(t1), "\n")
    
    # 使用 join() 等待线程结束
    t1.join()
    print("Thread t1 joined\n")
    
    # 创建多个线程
    t2:Thread = thread worker(10, 20)
    t2.join()
    print("Thread t2 joined\n")
    
    print("=== All thread tests passed ===\n")
}
```

**运行结果：**

```
=== Testing thread() function ===
Thread created, t1 type: Thread
Worker started with 1 2
Worker result: 3
Thread t1 joined
Worker started with 10 20
Worker result: 30
Thread t2 joined
=== All thread tests passed ===
```

**注意：**
- `thread worker(args)` 作为语句使用时，线程立即启动并后台运行
- `thread worker(args)` 作为表达式使用时，返回 Thread 句柄，可通过 `.join()` 方法等待线程结束
- 被线程调用的函数返回类型必须是 `void`（无返回值）

### 10.2 线程同步

#### mutex

`mutex() : Mutex` - 创建互斥锁

```catbase
def main(args:list[str]) {
    m:Mutex = mutex()
    print("Mutex created\n")
}
```

#### lock

`m.lock()` - 获取互斥锁（方法形式）

```catbase
def worker(id:int, m:Mutex) {
    m.lock()
    print("Worker ", id, " locked\n")
    sleep(1)
    m.unlock()
}
```

#### unlock

`m.unlock()` - 释放互斥锁（方法形式）

```catbase
def worker(id:int, m:Mutex) {
    m.lock()
    print("Worker ", id, " working\n")
    m.unlock()
    print("Worker ", id, " unlocked\n")
}
```

#### Mutex 完整示例

```catbase
def worker(id:int, m:Mutex) {
    m.lock()
    print("Worker ", id, " locked\n")
    sleep(1)
    print("Worker ", id, " unlocking\n")
    m.unlock()
}

def main(args:list[str]) {
    m:Mutex = mutex()
    
    # 使用 thread() 作为表达式获取线程句柄
    t1:Thread = thread worker(1, m)
    t2:Thread = thread worker(2, m)
    t3:Thread = thread worker(3, m)
    
    # 等待所有线程结束
    t1.join()
    t2.join()
    t3.join()
    
    print("All workers finished\n")
}
```

#### Mutex 的用途说明

**Mutex**（互斥锁）是一种用于多线程编程的同步机制。在多线程程序中，当多个线程同时访问共享资源（如变量、文件、数据库连接等）时，可能会产生**竞态条件（Race Condition）和**数据不一致的问题。

Mutex 的作用是：

1. **确保同一时刻只有一个线程**能够访问共享资源
2. **防止数据竞争**：当一个线程正在修改某个数据时，其他线程必须等待
3. **保护临界区**：代码中访问共享资源的区域称为临界区，mutex 用于保护临界区

**示例场景 - 计数器问题：**

假设有多个线程同时对同一个计数器进行加法操作：

*没有 mutex 的情况：*

```
线程A读取counter=0
线程B读取counter=0  (A还没写回)
线程A写回counter=1
线程B写回counter=1  (覆盖了A的结果，丢失了一次加法)
结果：counter=1（应该是2）
```

*有 mutex 的情况：*

```
线程A获取mutex锁
线程A读取counter=0
线程A计算counter=1
线程A写回counter=1
线程A释放mutex锁

线程B获取mutex锁
线程B读取counter=1
线程B计算counter=2
线程B写回counter=2
线程B释放mutex锁

结果：counter=2（正确）
```

| 特性       | 说明                    |
| -------- | --------------------- |
| **作用**   | 保护共享资源，防止数据竞争         |
| **特性**   | 独占性、不可重入（同一线程不能重复加锁）  |
| **适用场景** | 多线程访问同一变量、文件、数据库等共享资源 |

### 10.3 线程安全计数器（Mutex 实现）

CatBase 不提供原子操作函数（如 `atomic_add` 等），但可以通过 Mutex 互斥锁实现线程安全的计数器操作。

#### 使用 Mutex 保护共享变量

```catbase
# 全局计数器和互斥锁
counter: int = 0
m: Mutex = mutex()

def increment(id: int) {
    i: int = 0
    while i < 1000 {
        m.lock()
        counter = counter + 1
        m.unlock()
        i = i + 1
    }
    print("Worker ", id, " finished\n")
}

def main(args:list[str]) {
    # 启动3个线程同时递增计数器
    t1: Thread = thread increment(1)
    t2: Thread = thread increment(2)
    t3: Thread = thread increment(3)

    t1.join()
    t2.join()
    t3.join()

    print("Final counter: ", counter, "\n")
}
```

**运行结果：**

```
Worker 1 finished
Worker 2 finished
Worker 3 finished
Final counter: 3000
```

#### Mutex 与原子操作的对比

| 特性 | 原子操作（CatBase 不支持） | Mutex（CatBase 支持） |
| ---- | ---------------------- | ------------------- |
| 性能  | 更快，开销更小           | 较慢，有锁开销        |
| 适用场景 | 简单数值操作            | 复杂临界区           |
| 用途  | 计数器、标志位等         | 保护代码块           |

**使用注意事项：**

1. 在多线程环境下访问共享变量时，必须使用 Mutex 保护
2. 锁的范围应尽可能小，只保护必要的临界区代码
3. 避免死锁：不要在持有锁的情况下尝试获取同一个锁

### 10.4 等待线程

#### join

`t.join()` - 等待线程结束（Thread 对象的方法）

```catbase
def worker(id:int) {
    print("Worker ", id, " started\n")
    sleep(1)
    print("Worker ", id, " finished\n")
}

def main(args:list[str]) {
    t1:Thread = thread worker(1)
    t2:Thread = thread worker(2)
    
    t1.join()
    t2.join()
    
    print("All workers finished\n")
}
```

**运行结果：**

```
Worker 1 started
Worker 2 started
Worker 1 finished
Worker 2 finished
All workers finished

```

**注意：**
- `t.join()` 是 Thread 对象的方法，用于等待线程执行完毕
- 如果线程已经结束，调用 `join()` 会立即返回

### 10.5 消息队列

消息队列是一种线程间通信机制，用于在多线程之间安全地传递数据。CatBase 的消息队列 API 与 Python 的 `queue.Queue` 对齐。

#### queue

`queue(maxsize:int) : Queue` - 创建消息队列

```catbase
def main(args:list[str]) {
    # 创建队列，最大容量 10
    q:Queue = queue(10)
    print("Queue created, maxsize: 10\n")
}
```

#### put_nowait

`q.put_nowait(item:int)` - 非阻塞将数据放入队列（与 Python `queue.put_nowait()` 对齐）

```catbase
def producer(q:Queue) {
    i:int = 0
    while i < 5 {
        msg:int = i * 100
        q.put_nowait(msg)
        print("Producer: put_nowait ", msg, "\n")
        i = i + 1
    }
}
```

#### get

`q.get(timeout_ms:int) : int` - 从队列取出数据，支持超时（与 Python `queue.get()` 对齐）

- `timeout_ms = 0`: 非阻塞，超时返回 0
- `timeout_ms = -1`: 无限等待
- `timeout_ms > 0`: 超时时间（毫秒）

```catbase
def consumer(q:Queue) {
    i:int = 0
    while i < 5 {
        if !q.empty() {
            msg:int = q.get(100)  # 等待 100ms
            print("Consumer: get ", msg, "\n")
        } else {
            print("Consumer: queue is empty, waiting...\n")
        }
        i = i + 1
    }
}
```

#### empty

`q.empty() : bool` - 检查队列是否为空

```catbase
if q.empty() {
    print("Queue is empty\n")
}
```

#### full

`q.full() : bool` - 检查队列是否已满

```catbase
if q.full() {
    print("Queue is full\n")
}
```

#### qsize

`q.qsize() : int` - 获取队列中的元素数量（与 Python `queue.qsize()` 对齐）

```catbase
size:int = q.qsize()
print("Queue size: ", size, "\n")
```

#### get_nowait

`q.get_nowait() : int` - 非阻塞从队列取出数据，空时返回 0（与 Python `queue.get_nowait()` 对齐）

```catbase
if !q.empty() {
    msg:int = q.get_nowait()
    print("Got: ", msg, "\n")
}
```

#### get_maxsize

`q.get_maxsize() : int` - 获取队列的最大容量（与 Python `queue.maxsize` 属性对齐）

```catbase
max:int = q.get_maxsize()
print("Queue maxsize: ", max, "\n")
```

#### task_done

`q.task_done()` - 标记一个任务完成（与 Python `queue.task_done()` 对齐）

```catbase
def consumer(q:Queue) {
    i:int = 0
    while i < 5 {
        if !q.empty() {
            msg:int = q.get_nowait()
            print("Consumer: got ", msg, "\n")
            q.task_done()  # 标记任务完成
        }
        i = i + 1
    }
}
```

#### join

`q.join()` - 等待所有任务完成（与 Python `queue.join()` 对齐）

```catbase
# 启动生产者和消费者
thread producer(q)
thread consumer(q)

# 等待所有任务完成
q.join()
print("All tasks completed!\n")
```

#### 兼容的旧版函数

以下函数是旧版 API，仍可使用：

| 函数 | 说明 | 等价方法 |
|------|------|---------|
| `queue_push(q, item)` | 放入队列 | `q.put_nowait(item)` |
| `queue_pop(q)` | 取出数据 | `q.get(0)` |
| `queue_empty(q)` | 检查空 | `q.empty()` |
| `queue_full(q)` | 检查满 | `q.full()` |
| `queue_size(q)` | 获取大小 | `q.qsize()` |

#### Python queue API 与 CatBase API 对照表

| Python | CatBase | 说明 |
|--------|---------|------|
| `queue.Queue(maxsize)` | `queue(maxsize)` | 创建队列 |
| `q.put_nowait(item)` | `q.put_nowait(item)` | 非阻塞放入 ✅ |
| `q.get(timeout)` | `q.get(timeout_ms)` | 带超时取出 ✅ |
| `q.get_nowait()` | `q.get_nowait()` | 非阻塞取出 ✅ |
| `q.empty()` | `q.empty()` | 检查空 ✅ |
| `q.full()` | `q.full()` | 检查满 ✅ |
| `q.qsize()` | `q.qsize()` | 获取大小 ✅ |
| `q.maxsize` | `q.get_maxsize()` | 获取最大容量 ✅ |
| `q.task_done()` | `q.task_done()` | 标记任务完成 ✅ |
| `q.join()` | `q.join()` | 等待完成 ✅ |

#### 消息队列完整示例

```catbase
def producer(q:Queue) {
    i:int = 0
    while i < 5 {
        msg:int = i * 100
        q.put_nowait(msg)
        print("Producer: put_nowait ", msg, "\n")
        sleep(1)
        i = i + 1
    }
}

def consumer(q:Queue) {
    i:int = 0
    while i < 5 {
        if !q.empty() {
            msg:int = q.get(100)
            print("Consumer: get ", msg, "\n")
        } else {
            print("Consumer: queue is empty, waiting...\n")
        }
        sleep(1)
        i = i + 1
    }
}

def main(args:list[str]) {
    print("Testing Queue (Python-like API)...\n")

    # 创建队列，最大容量 10
    q:Queue = queue(10)

    print("Queue created, maxsize: 10\n")
    print("q.empty(): ", q.empty(), "\n")
    print("q.full(): ", q.full(), "\n")
    print("q.qsize(): ", q.qsize(), "\n")

    # 启动生产者和消费者
    thread producer(q)
    thread consumer(q)

    # 等待一段时间让线程完成
    sleep(6)

    print("\nFinal q.qsize(): ", q.qsize(), "\n")
    print("Test completed!\n")
}
```

**运行结果：**

```
Testing Queue (Python-like API)...

Queue created, maxsize: 10

q.empty():  true 

q.full():  false 

q.qsize():  0 

Producer: put_nowait  0 

Consumer: get  0 

Producer: put_nowait  100 

Consumer: get  100 

Producer: put_nowait  0 

Consumer: get  0 

Producer: put_nowait  100 

Consumer: get  100 

Producer: put_nowait  200 

Consumer: get  200 

Producer: put_nowait  300 

Consumer: get  300 

Producer: put_nowait  400 

Final q.qsize():  1 

Test completed!

```

#### 消息队列与 Mutex 的对比

| 特性       | 消息队列              | Mutex + 共享变量 |
| -------- | ------------------ | --------------- |
| **数据传递**  | 通过队列自动传递         | 通过共享变量手动传递    |
| **同步方式**  | 自动同步（队列操作是原子操作） | 需要手动加锁解锁      |
| **安全性**   | 更高，不会死锁           | 可能死锁           |
| **性能**    | 稍有开销（队列操作）       | 更好（仅锁操作）      |
| **适用场景**  | 生产者-消费者模式        | 临界区保护          |

**消息队列的用途：**

1. **生产者-消费者模式**：一个线程生产数据，另一个线程消费数据
2. **任务分发**：主线程分发任务给工作线程
3. **事件通知**：线程间传递事件或消息
4. **解耦**：让生产者和消费者不需要知道彼此的存在

***

### 10.6 优雅关闭事件

优雅关闭事件（ShutdownEvent）是一种线程间通信机制，类似于 Python 的 `asyncio.Event`，用于实现优雅的程序关闭。

#### 基本概念

当程序收到关闭信号（如 Ctrl+C）时，我们需要一种机制来：
1. 通知所有工作线程关闭请求
2. 工作线程检查关闭状态并有序停止
3. 主线程等待所有工作线程完成

#### init_shutdown_event

`init_shutdown_event()` - 初始化关闭事件（在 main 开始前自动调用）

```catbase
# 无需手动调用，程序启动时自动初始化
```

#### set_shutdown_event

`set_shutdown_event()` - 设置关闭事件（相当于 Python 的 `event.set()`）

```catbase
# 设置关闭事件，通知所有线程程序即将关闭
set_shutdown_event()
```

#### is_shutdown_event_set

`is_shutdown_event_set()` - 检查关闭事件是否被设置，返回布尔值

```catbase
if is_shutdown_event_set() {
    print("Shutdown requested\n")
}
```

#### shutdown_requested

`shutdown_requested()` - 检查是否请求关闭，返回布尔值（与 `is_shutdown_event_set()` 等效）

```catbase
# 在工作线程中定期检查
for {
    if shutdown_requested() {
        print("Stopping task...\n")
        return
    }
    # 继续工作
}
```

#### wait_shutdown_event

`wait_shutdown_event(timeout_seconds:float)` - 等待关闭事件或超时

- 无参数或参数为 0：无限等待
- 参数 > 0：等待指定秒数后超时

```catbase
# 等待关闭事件（最多等待 10 秒）
result:bool = wait_shutdown_event(10)
if result {
    print("Shutdown event received!\n")
} else {
    print("Timeout reached\n")
}
```

#### 完整示例

```catbase
async def long_running_task(id:int) {
    print("Task ", id, " started\n")
    for {
        # 定期检查关闭请求
        if shutdown_requested() {
            print("Task ", id, " stopping...\n")
            return
        }
        sleep(0.1)  # 模拟工作
    }
}

def main(args:list[str]) {
    print("Starting tasks...\n")

    # 启动多个工作线程
    for i in range(5) {
        thread long_running_task(i)
    }

    # 等待关闭事件（最多等待 30 秒）
    print("Waiting for shutdown (Ctrl+C to trigger)...\n")
    result:bool = wait_shutdown_event(30)

    if result {
        print("Shutdown event received!\n")
    } else {
        print("Timeout, continuing...\n")
    }

    print("Main program finished\n")
}
```

**运行结果（按下 Ctrl+C）：**

```
Starting tasks...
Task 0 started
Task 1 started
Task 2 started
...
Waiting for shutdown (Ctrl+C to trigger)...
^C
Task 0 stopping...
Task 1 stopping...
Task 2 stopping...
Shutdown event received!
Main program finished
```

**与 Python asyncio.Event 的对比：**

| CatBase | Python asyncio |
|---------|---------------|
| `init_shutdown_event()` | `asyncio.Event()` |
| `set_shutdown_event()` | `event.set()` |
| `is_shutdown_event_set()` | `event.is_set()` |
| `shutdown_requested()` | `event.is_set()` |
| `wait_shutdown_event(timeout)` | `await event.wait(timeout)` |

### 10.7 线程安全队列（Queue）

> 在多线程编程中，线程间经常需要传递数据。CatBase 提供了线程安全的队列（Queue），与 Python 的 `queue.Queue` API 对齐。

#### queue

`queue(maxsize:int) : Queue` - 创建线程安全队列

创建一个线程安全的队列，用于在线程间传递数据。

**参数说明：**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| maxsize | int | 否 | 0 | 队列最大容量，0 表示无限制 |

**返回值：**

- 返回 `Queue` 类型对象

**基本用法：**

```catbase
def producer(q:Queue) {
    i:int = 0
    while i < 5 {
        q.put_nowait(i)
        print("Produced: ", i, "\n")
        i = i + 1
    }
}

def consumer(q:Queue) {
    i:int = 0
    while i < 5 {
        value:int = q.get(-1)  # 无限等待
        print("Consumed: ", value, "\n")
        i = i + 1
    }
}

def main(args:list[str]) {
    q:Queue = queue(0)  # 无限制队列

    thread producer(q)
    thread consumer(q)

    sleep(2)
}
```

#### Queue 方法

| 方法 | 说明 |
|------|------|
| `q.put_nowait(item:int)` | 非阻塞放入item，满时静默丢弃 |
| `q.get(timeout_ms:int) : int` | 带超时取出，超时返回0；timeout_ms=-1表示无限等待 |
| `q.get_nowait() : int` | 非阻塞取出，空时返回0 |
| `q.empty() : bool` | 检查队列是否为空 |
| `q.full() : bool` | 检查队列是否已满 |
| `q.qsize() : int` | 获取队列中的元素数量 |
| `q.maxsize() : int` | 获取队列的最大容量 |
| `q.task_done()` | 标记一个任务完成 |
| `q.join()` | 等待所有任务完成 |

**参数详解：**

- `timeout_ms` 取值：
  - `0`：非阻塞，如果队列为空立即返回0
  - `-1`：无限等待，直到队列有数据
  - `> 0`：等待指定毫秒数，超时返回0

#### Queue 使用示例

```catbase
def worker(id:int, q:Queue) {
    # 无限等待获取数据
    value:int = q.get(-1)
    print("Worker ", id, " got: ", value, "\n")

    # 标记任务完成
    q.task_done()
}

def main(args:list[str]) {
    q:Queue = queue(10)  # 最多10个元素

    # 启动消费者线程
    thread worker(1, q)
    thread worker(2, q)

    # 生产者放入数据
    i:int = 0
    while i < 5 {
        q.put_nowait(i)
        print("Produced: ", i, "\n")
        sleep(0.1)
        i = i + 1
    }

    # 等待所有任务完成
    q.join()

    print("All tasks completed\n")
}
```

#### Queue 与 Python queue.Queue 对比

| CatBase | Python |
|---------|--------|
| `queue(maxsize)` | `queue.Queue(maxsize)` |
| `q.put_nowait(item)` | `q.put_nowait(item)` |
| `q.get(timeout_ms)` | `q.get(timeout=timeout_ms/1000)` |
| `q.get_nowait()` | `q.get_nowait()` |
| `q.empty()` | `q.empty()` |
| `q.full()` | `q.full()` |
| `q.qsize()` | `q.qsize()` |
| `q.task_done()` | `q.task_done()` |
| `q.join()` | `q.join()` |

***

## 11. 信号处理

> **本章导读：** 本章介绍信号处理机制。信号是操作系统发送给进程的简短异步通知，用于报告事件（如 Ctrl+C 中断）。CatBase 通过 `ShutdownEvent` 机制实现优雅关闭，与 Python 的信号处理方式对齐。

### 11.1 基本概念

**信号（Signal）** 是进程间通信的简单形式，由操作系统内核发送给进程。常见的信号包括：

| 信号 | 值 | 说明 |
|------|-----|------|
| SIGINT | 2 | 中断信号（Ctrl+C） |
| SIGTERM | 15 | 终止信号（默认的 `kill` 信号） |
| SIGKILL | 9 | 强制终止信号（不可捕获） |
| SIGHUP | 1 | 挂起信号（终端关闭） |

### 11.2 CatBase 的信号处理机制

CatBase 不直接暴露底层信号 API（如 `signal()`、`sigaction()`），而是通过高层次的 `ShutdownEvent` 机制处理常见的优雅关闭场景。

#### 工作原理

```
┌─────────────────────────────────────────────────────────────┐
│                     CatBase 程序                             │
│                                                             │
│  ┌──────────────┐     SIGINT/SIGTERM      ┌──────────────┐ │
│  │   操作系统     │ ───────────────────────►│   信号处理    │ │
│  │   内核        │       Ctrl+C            │   钩子       │ │
│  └──────────────┘                          └──────┬───────┘ │
│                                                    │         │
│                                                    ▼         │
│                                          ┌─────────────────┐ │
│                                          │ ShutdownEvent   │ │
│                                          │ .is_set = true  │ │
│                                          └────────┬────────┘ │
│                                                   │          │
│         ┌────────────────┬────────────────┬──────┘          │
│         ▼                ▼                ▼                │
│    ┌─────────┐     ┌─────────┐     ┌─────────┐              │
│    │ Thread1 │     │ Thread2 │     │ Thread3 │              │
│    │检查标志位│     │检查标志位│     │检查标志位│              │
│    └─────────┘     └─────────┘     └─────────┘              │
└─────────────────────────────────────────────────────────────┘
```

### 11.3 与 Python 的对比

#### Python 信号处理示例

```python
import signal
import sys

def handle_signal(signum, frame):
    print("Received signal, shutting down...")
    sys.exit(0)

# 注册信号处理器
signal.signal(signal.SIGINT, handle_signal)
signal.signal(signal.SIGTERM, handle_signal)

# 主循环
while True:
    # 处理任务
    pass
```

#### CatBase 优雅关闭示例

```catbase
async def worker(id:int) {
    print("Worker ", id, " started\n")
    while true {
        # 定期检查关闭请求
        if shutdown_requested() {
            print("Worker ", id, " stopping...\n")
            return
        }
        sleep(0.1)
    }
}

def main(args:list[str]) {
    print("Starting workers...\n")

    # 启动多个工作线程
    for i in range(5) {
        thread worker(i)
    }

    # 等待关闭事件
    # 当收到 Ctrl+C 或 kill 命令时，ShutdownEvent 会被设置
    wait_shutdown_event(0)  # 0 表示无限等待

    print("All workers stopped gracefully\n")
}
```

### 11.4 信号处理与 ShutdownEvent 的关系

| 方面 | Python | CatBase |
|------|--------|---------|
| 底层机制 | `signal.signal()` | Zig 线程同步原语 |
| 协调机制 | 回调函数 | `ShutdownEvent` 标志 |
| 工作线程检查 | 回调中设置标志 | `shutdown_requested()` |
| 等待机制 | `time.sleep()` 循环 | `wait_shutdown_event()` |

### 11.5 实际使用场景

#### 场景一：服务器优雅关闭

```catbase
async def handle_request(client_id:int) {
    print("Handling request from client ", client_id, "\n")
    # 处理请求...
}

def main(args:list[str]) {
    print("Web server starting on port 8080...\n")

    # 启动服务器线程
    for i in range(100) {  # 模拟100个连接
        thread handle_request(i)
    }

    # 等待关闭信号
    print("Press Ctrl+C to stop the server...\n")
    wait_shutdown_event(0)

    print("Shutting down server...\n")
    # 清理资源...
}
```

#### 场景二：定时任务优雅退出

```catbase
async def scheduled_task(id:int) {
    print("Task ", id, " running\n")
    for {
        if shutdown_requested() {
            print("Task ", id, " cancelled\n")
            return
        }
        # 执行任务...
        sleep(1)
    }
}

def main(args:list[str]) {
    # 启动定时任务
    for i in range(3) {
        thread scheduled_task(i)
    }

    # 运行 60 秒后自动退出
    result:bool = wait_shutdown_event(60)
    if result {
        print("Shutdown was triggered\n")
    } else {
        print("Timeout reached\n")
    }
}
```

### 11.6 注意事项

1. **SIGKILL 无法捕获**：当进程收到 `SIGKILL` 信号时，操作系统会立即终止进程，无法执行任何清理代码

2. **主线程等待**：建议在主线程中使用 `wait_shutdown_event()` 等待关闭信号，让工作线程有时间检查 `shutdown_requested()` 并有序退出

3. **检查频率**：工作线程应该定期检查 `shutdown_requested()`，建议在循环中每次迭代都检查或每隔固定时间检查

4. **阻塞操作**：如果工作线程中有阻塞操作（如网络等待），应该设置超时，让线程能够及时响应关闭请求

***

## 12. 配置文件解析

> **本章导读：** 本章介绍如何使用 `Config` 类型读取和解析 INI 格式的配置文件，类似于 Python 的 `configparser`。这对于管理应用程序配置非常有用。

### 12.1 Config 类型

`Config` 是 CatBase 内置的对象类型，用于解析 INI 格式的配置文件。

```catbase
config:Config = config("config.conf")
```

**INI 配置文件格式：**

```ini
# 注释
[section_name]
key1 = value1
key2 = value2

[another_section]
key = value
```

### 12.2 加载配置文件

使用 `config(filename)` 加载配置文件：

```catbase
config:Config = config("config.conf")
```

如果文件不存在或无法解析，会返回空的 Config 对象。

### 12.3 获取配置值

CatBase 提供多个函数获取配置值：

| 函数 | 说明 | 返回类型 |
|------|------|---------|
| `config_get(config, section, key)` | 获取字符串值 | `str` |
| `config_get_int(config, section, key, default)` | 获取整数值 | `int` |
| `config_get_float(config, section, key, default)` | 获取浮点数值 | `float` |
| `config_has_key(config, section, key)` | 检查键是否存在 | `bool` |

**示例：**

```catbase
def main(args:list[str]) {
    # 加载配置文件
    config:Config = config("app.conf")

    # 获取字符串值
    websocket_url:str = config_get(config, "websocket", "url")
    print("URL: ", websocket_url, "\n")

    # 获取整数值（提供默认值）
    port:int = config_get_int(config, "websocket", "port", 8080)
    print("Port: ", port, "\n")

    # 检查键是否存在
    if config_has_key(config, "websocket", "ssl") {
        print("SSL is configured\n")
    }
}
```

### 12.4 完整示例

假设 `app.conf` 文件内容如下：

```ini
[websocket]
url = ws://localhost:8080
device_id = device001
port = 8080

[recording]
sample_rate = 16000
channels = 1
```

对应的 CatBase 代码：

```catbase
def main(args:list[str]) {
    print("=== Config Demo ===\n")

    config:Config = config("app.conf")

    # 读取 websocket 配置
    url:str = config_get(config, "websocket", "url")
    device_id:str = config_get(config, "websocket", "device_id")
    port:int = config_get_int(config, "websocket", "port", 8080)

    print("WebSocket URL: ", url, "\n")
    print("Device ID: ", device_id, "\n")
    print("Port: ", port, "\n")

    # 读取 recording 配置
    sample_rate:int = config_get_int(config, "recording", "sample_rate", 16000)
    channels:int = config_get_int(config, "recording", "channels", 1)

    print("Sample rate: ", sample_rate, "\n")
    print("Channels: ", channels, "\n")
}
```

**运行结果：**

```
=== Config Demo ===

WebSocket URL:  ws://localhost:8080
Device ID:  device001
Port:  8080
Sample rate:  16000
Channels:  1
```

### 12.5 与 Python configparser 的对比

| CatBase | Python |
|---------|--------|
| `config("file.conf")` | `configparser.ConfigParser()` + `read()` |
| `config_get(c, "sec", "key")` | `c.get("sec", "key")` |
| `config_get_int(c, "sec", "key", 0)` | `c.getint("sec", "key", fallback=0)` |
| `config_get_float(c, "sec", "key", 0.0)` | `c.getfloat("sec", "key", fallback=0.0)` |
| `config_has_key(c, "sec", "key")` | `c.has_option("sec", "key")` |

***

## 13. 协程编程

> **本章导读：** 本章介绍协程编程。协程是一种轻量级的并发模型，比线程更轻量，适合高并发服务器应用场景。CatBase 提供 `async def` 和 `await` 语法，支持协程编程。

### 13.1 定义协程函数

#### async def

使用 `async def` 关键字定义协程函数：

```catbase
async def fetch_data(url:str) -> str {
    print("Fetching data from ", url, "\n")
    response:str = "Data from " + url
    return response
}

async def process_request(req_id:int) {
    result:str = await fetch_data("http://example.com/api/" + str(req_id))
    print("Request ", req_id, " completed: ", result, "\n")
}
```

**说明：**
- `async def` 定义协程函数
- 协程函数内部可以使用 `await` 关键字等待其他协程完成

### 13.2 等待协程

#### await

使用 `await` 关键字等待协程执行结果：

```catbase
async def get_data() -> str {
    await sleep(1)
    return "Data loaded"
}

def main(args:list[str]) {
    result:str = await get_data()
    print("Result: ", result, "\n")
}
```

**说明：**
- `await` 只能在 `async def` 函数内部使用
- `await` 会暂停当前协程，等待目标协程完成并返回结果

### 13.3 协程与线程的关系

CatBase 的 `async/await` 语法在：
- `async def` 定义的函数在独立线程中执行
- `await` 调用会创建一个新线程并 join 等待其完成
- `async/await` 保留了类似 Python 的简洁语法，但获得真正的多线程并行能力

#### 核心特性对比

| 特性 | thread（线程） | async（协程） |
|------|--------------|--------------|
| 创建开销 | 较大（需要操作系统分配资源） | 较小（底层使用线程池） |
| 内存占用 | 约 1MB/线程 | 约 1KB/协程（实际使用线程） |
| 切换成本 | 操作系统上下文切换 | 线程 join 同步 |
| 数量限制 | 受限于内存，通常数千个 | 受限于线程数 |
| 同步方式 | Mutex 锁、原子操作 | await 同步等待 |
| 真正并行 | 是 | 是（底层是线程） |

#### 应用场景对比

**1. I/O 密集型 vs CPU 密集型**

| 场景 | 推荐方案 | 原因 |
|------|---------|------|
| 网络请求、文件读写、数据库查询 | 协程 (async) | I/O 等待期间不占用 CPU，可并发大量协程 |
| 视频编码、图像处理、科学计算 | 线程 (thread) | 需要 CPU 持续计算，可利用多核 |

**2. 并发数量**

| 场景 | 推荐方案 | 原因 |
|------|---------|------|
| 需要同时处理数百到数千任务 | 两者均可 | async/await 底层使用线程，性能良好 |
| 需要同时处理大量 I/O 密集型任务 | 协程 (async) | 代码简洁，语法清晰 |
| 需要 CPU 密集型并行计算 | 线程 (thread) | 直接控制线程，更灵活 |

**3. 编程复杂度**

| 场景 | 推荐方案 | 原因 |
|------|---------|------|
| 简单并发任务 | 协程 (async) | 代码简洁，无需考虑锁的问题 |
| 需要共享状态 | 线程 (thread) | 成熟的同步机制 |
| 复杂依赖关系 | 协程 (async) | await 语法更直观 |

### 13.4 协程使用示例

#### 示例一：高并发 Web 服务器

```catbase
async def handle_client(client_id:int) {
    # 模拟处理客户端请求
    print("Client ", client_id, " connected\n")
    
    # 模拟网络延迟
    await sleep(1)
    
    print("Client ", client_id, " request processed\n")
}

def main(args:list[str]) {
    # 模拟服务器同时处理 10000 个客户端连接
    for i in range(10000) {
        handle_client(i)
    }
    
    print("Server started, handling 10000 clients\n")
}
```

**运行结果：**

```
Server started, handling 10000 clients
Client 0 connected
Client 1 connected
Client 2 connected
...
Client 9999 connected
Client 0 request processed
Client 1 request processed
...
```

#### 示例二：并发网络请求

```catbase
async def fetch_url(url:str) -> str {
    # 模拟网络请求
    await sleep(1)
    return "Response from " + url
}

async def crawl_urls() {
    urls:list[str] = ["http://a.com", "http://b.com", "http://c.com"]
    
    results:list[str] = []
    for url in urls {
        result:str = await fetch_url(url)
        results.append(result)
    }
    
    print("All fetched: ", results, "\n")
}

def main(args:list[str]) {
    crawl_urls()
}
```

#### 示例三：并发数据库查询

```catbase
async def query_user(user_id:int) -> str {
    # 模拟数据库查询延迟
    await sleep(0.5)
    return "User-" + str(user_id)
}

async def get_all_users() {
    # 并发查询 100 个用户
    results:list[str] = []
    for i in range(100) {
        result:str = await query_user(i)
        results.append(result)
    }
    
    print("Total users: ", len(results), "\n")
}

def main(args:list[str]) {
    get_all_users()
}
```

### 13.5 线程使用示例

#### 示例一：CPU 密集型计算

```catbase
def calculate(start:int, end:int) -> int {
    sum:int = 0
    for i in range(start, end) {
        sum = sum + i * i
    }
    return sum
}

def main(args:list[str]) {
    # 使用 4 个线程并行计算
    thread calculate(0, 250000)
    thread calculate(250000, 500000)
    thread calculate(500000, 750000)
    thread calculate(750000, 1000000)
    
    sleep(1)
    print("Calculation completed\n")
}
```

#### 示例二：后台任务处理

```catbase
def background_task(task_id:int) {
    print("Task ", task_id, " started\n")
    sleep(2)
    print("Task ", task_id, " completed\n")
}

def main(args:list[str]) {
    # 启动多个后台任务
    for i in range(10) {
        thread background_task(i)
    }
    
    print("All tasks dispatched\n")
    sleep(3)
}
```

### 13.6 选择指南

根据以下因素选择合适的并发模型：

**选择协程 (async/await) 的场景：**
- 高并发网络服务（Web 服务器、API 服务）
- 需要同时处理大量 I/O 操作
- 需要处理数万至数十万并发连接
- 追求更高的资源利用效率

**选择线程 (thread) 的场景：**
- CPU 密集型任务（计算、加密、压缩）
- 需要利用多核 CPU
- 与现有线程代码集成
- 任务数量较少但计算量大

**混合使用：**
- 主服务器使用协程处理高并发连接
- 将 CPU 密集型任务交给线程池处理

***

## 14. 导入系统

> **本章导读：** 多线程编程让我们能够充分利用系统资源，本章将介绍导入系统。CatBase 支持导入外部 C 语言库（.so/.a 文件），让你能够使用丰富的 C 语言生态。同时，CatBase 也支持将代码编译为共享库，供其他程序调用。

### 14.0 Import 路径解析规则

CatBase 支持三种类型的导入：

1. **导入 .cat 文件**：导入其他 CatBase 源文件，可以调用其中定义的函数
2. **导入 .so 文件**：导入共享库，调用 C 函数
3. **导入 .a 文件**：导入静态库，调用 C 函数

#### 路径解析规则

当使用 `import` 语句导入文件时，编译器会按照以下规则查找文件：

- **绝对路径**：如果 import 路径是绝对路径（如 `/usr/lib/libmylib.so`），直接在该绝对路径查找文件
- **相对路径**：如果 import 路径是相对路径（如 `./libmylib.so` 或 `libmylib.so`），**无论命令行当前工作目录是什么**，编译器都会从**被编译的源文件所在目录**开始查找

> **注意**：
> - 所有类型的 import（.cat、.so、.a）都遵循同样的路径解析规则

#### 使用示例

```catbase
# 导入同目录下的 CatBase 文件（相对路径）
import "./helper.cat" as helper

# 导入同目录下的共享库（相对路径）
import "./libmylib.so" as mylib

# 导入系统库（绝对路径）
import "/usr/lib/x86_64-linux-gnu/libm.so" as math

# 导入静态库（相对路径）
import "./libtest.a" as test
```

### 14.1 生成共享库

CatBase 支持将代码编译为共享库（.so 文件），供其他程序或 CatBase 代码导入使用。

#### 编译共享库

使用 `-shared` 参数将 CatBase 代码编译为共享库：

```bash
# 编译生成共享库 libmylib.so
catbasecc -shared mylib.cat
```

生成的共享库文件名为 `libmylib.so`（自动添加 `lib` 前缀）。

#### 共享库示例

首先创建一个包含公共函数的 CatBase 源文件：

```catbase
# mylib.cat - 定义公共函数
def add(a:int, b:int) {
    result:int = a + b
    print("add: ", a, " + ", b, " = ", result, "\n")
}

def multiply(a:int, b:int) {
    result:int = a * b
    print("multiply: ", a, " * ", b, " = ", result, "\n")
}
```

编译为共享库：

```bash
catbasecc -shared mylib.cat
```

这将生成 `libmylib.so` 文件。

### 14.2 导入共享库

编译生成共享库后，可以在其他 CatBase 代码中导入使用：

```catbase
# main.cat - 使用共享库
import "./libmylib.so" as mylib

def main(args:list[str]) {
    mylib.add(5, 3)
    mylib.multiply(4, 7)
}
```

编译并运行：

```bash
catbasecc main.cat && ./main
```

**运行结果：**

```
add: 5 + 3 = 8
multiply: 4 * 7 = 28
```

### 14.3 导入 C 库

CatBase 支持导入 C 语言编写的共享库（.so）和静态库（.a）。

#### 导入 .so 文件

```catbase
import "./libtest.so" as test

# 声明外部函数签名
from test import add(a: int, b: int) -> int

def main(args:list[str]) {
    result:int = test.add(5, 7)
    print("5 + 7 = ", result, "\n")
}
```

#### 导入 .a 文件

```catbase
import "./libtest.a" as test

# 声明外部函数签名（与 .so 文件语法一致）
from test import add(a: int, b: int) -> int

def main(args:list[str]) {
    result:int = test.add(5, 7)
    print("5 + 7 = ", result, "\n")
}
```

### 14.4 导入系统库

```catbase
import "libm.so" as math

# 声明外部函数
from math import sqrt(x: float) -> float

def main(args:list[str]) {
    result:float = math.sqrt(16.0)
    print("sqrt(16) = ", result, "\n")
}
```

### 14.5 声明外部函数（from...import 语法）

当导入 .so 或 .a 文件时，如果编译器无法自动识别库中的函数，可以使用 `from...import` 语法手动声明外部函数的签名。这与 Python 的 `from module import func` 语法类似。

#### 语法格式

```catbase
from <lib_alias> import <func_name>(<param_name>: <param_type>, ...) -> <return_type>
```

#### 使用示例

```catbase
# 首先导入共享库
import "./libmylib.so" as mylib

# 声明外部函数签名
from mylib import my_function(a: int, b: int) -> int
from mylib import another_function(s: str) -> int
from mylib import get_value() -> float

def main(args:list[str]) {
    # 调用外部函数
    result = mylib.my_function(5, 3)
    print("Result: ", result, "\n")
    
    msg = mylib.another_function("hello")
    print("Message: ", msg, "\n")
    
    value = mylib.get_value()
    print("Value: ", value, "\n")
}
```

#### 支持的类型映射

| CatBase 类型 | C/Zig 类型 | 说明 |
|------------|-------|------|
| `int` | `c_int` | 整数 |
| `float` | `f64` | 浮点数（C 的 double） |
| `bool` | `c_int` | 布尔值（C 中通常用 int 表示） |
| `str` | `[*c]const u8` | 字符串指针 |
| `bytes` | `[*c]u8` | 字节指针 |
| `None` | `void` | 无返回值 |

#### 实际应用场景

当你只有 .so 文件但没有对应的头文件时，可以使用此语法声明需要使用的函数：

```catbase
import "/usr/local/lib/libcustom.so" as custom

# 声明需要的函数
from custom import process_data(input: bytes, size: int) -> int
from custom import init(config: str) -> int
from custom import cleanup() -> None

def main(args:list[str]) {
    custom.init("debug=true")
    data = bytes("test data")
    result = custom.process_data(data, len(data))
    custom.cleanup()
}
```

**注意事项：**
- `from...import` 语句必须在对应的 `import` 语句之后
- 函数名必须与 .so 文件中的实际函数名完全一致
- 参数类型和返回类型需要与 C 函数声明匹配，否则可能导致运行时错误 

***

## 15. 音频录音和播放

> **本章导读：** 本章介绍 CatBase 的音频功能，支持录音和播放功能。CatBase 使用 Linux ALSA (Advanced Linux Sound Architecture) 实现音频处理，提供与 Python PyAudio 相似的 API。

### 15.1 依赖安装 {#151-依赖安装}

在 Linux 上使用音频功能需要安装 ALSA 开发库：

```bash
# Ubuntu/Debian
sudo apt-get install libasound2-dev

# CentOS/RHEL
sudo yum install alsa-lib-devel
```

### 15.2 一次性录音 {#152-一次性录音}

#### record

`record(duration:int, sample_rate:int, channels:int, device_name:str, chunk:int) : bytes` - 录制音频，返回 PCM 数据

参数：

- `duration` - 录音时长（秒）
- `sample_rate` - 采样率（如 16000）
- `channels` - 声道数（如 1）
- `device_name` - 设备名称，格式为 `plughw:CARD=X,DEV=Y`，可使用 `getInputDeviceList()` 获取
- `chunk` - 缓冲大小（如 1024）

返回值：

- 返回 bytes 类型的 PCM 音频数据

```catbase
def main(args:list[str]) {
    print("开始录音...\n")

    # 录音5秒，返回PCM数据
    # 参数: duration, sample_rate, channels, device_name, chunk
    data:bytes = record(5, 16000, 1, "plughw:CARD=0,DEV=0", 1024)

    # 保存为WAV文件
    save_wav(data, "/tmp/recording.wav", 16000)

    print("录音完成，已保存到 /tmp/recording.wav\n")

    # 播放录音（指定输出设备）
    play(data, 16000, "plughw:CARD=1,DEV=0")

    print("播放完成\n")
}
```

### 15.3 流式录音 {#153-流式录音}

#### recordStream

`recordStream(rate:int, channels:int, chunk:int, format:int, device_name:str, callback:function) : RecordStream` - 创建流式录音对象

**参数：**

| 参数 | 关键字参数 | 默认值 | 说明 |
|------|-----------|--------|------|
| rate | rate | 16000 | 采样率（如 16000） |
| channels | channels | 1 | 声道数（如 1） |
| chunk | chunk | 1024 | 缓冲大小 |
| format | format | 3 | 音频格式代码 |
| device_name | device_name | "default" | 设备名称，格式为 `plughw:CARD=X,DEV=Y` |
| callback | callback | None | 回调函数（可选） |

**参数说明：**

- `rate` - 采样率，单位 Hz（如 16000、44100）
- `channels` - 声道数，1 表示单声道，2 表示立体声
- `chunk` - 每次读取的音频帧数，影响延迟和内存使用
- `format` - 音频格式代码，见下表
- `device_name` - ALSA 设备名称，使用 `getInputDeviceList()` 获取
- `callback` - 可选的回调函数，用于异步录音

**format 格式代码：**

| 代码 | 格式           |
| -- | ------------ |
| 1  | S8           |
| 2  | U8           |
| 3  | S16\_LE (默认) |
| 4  | S16\_BE      |
| 5  | U16\_LE      |
| 7  | S24\_LE      |
| 11 | S32\_LE      |
| 15 | FLOAT        |
| 16 | FLOAT64      |
| 17 | MU\_LAW      |
| 18 | A\_LAW       |

#### RecordStream 方法

| 方法            | 返回类型 | 说明               |
| ------------- | ---- | ---------------- |
| `read()`      | str  | 读取一个 chunk 的音频数据 |
| `is_active()` | bool | 检查录音流是否处于活跃状态    |
| `close()`     | None | 关闭录音流            |
| `setCallback(callback)` | None | 设置回调函数 |
| `startRecording()` | None | 启动带回调的异步录音 |
| `stopRecording()` | None | 停止录音 |

**回调机制说明：**

CatBase 支持音频回调机制，参考 Python sounddevice 的回调模式。当指定 `callback` 参数时：
- 录音会在独立线程中异步进行
- 每当有新的音频数据可用时，自动调用回调函数
- 回调函数接收一个 `bytes` 参数，包含音频数据

**回调函数签名：**
```catbase
def on_audio_data(data: bytes) {
    # data 是一个 chunk 的音频数据
    print("Received", len(data), "bytes")
}
```

**使用回调的录音示例：**

```catbase
# 录音回调函数 - 当有新的音频数据时被调用
def on_audio_data(data: bytes) {
    print("Received audio frame: ", len(data), " bytes")
    # 可以在这里处理音频数据，如保存、分析等
}

def main(args: list[str]) {
    # 创建带回调的录音流
    # 参数: rate, channels, chunk, format, device_name, callback
    stream: RecordStream = recordStream(16000, 1, 512, 3, "plughw:CARD=0,DEV=0", on_audio_data)

    print("Recording started with callback...")
    sleep(5)  # 录音5秒

    stream.stopRecording()
    stream.close()
    print("Recording stopped")
}
```

**使用关键字参数的录音示例：**

```catbase
def on_audio_data(data: bytes) {
    print("Received: ", len(data), " bytes")
}

def main(args: list[str]) {
    # 使用关键字参数
    stream: RecordStream = recordStream(rate=16000, channels=1, chunk=512, format=3, device_name="plughw:CARD=0,DEV=0", callback=on_audio_data)

    print("Recording started...")
    sleep(5)

    stream.stopRecording()
    stream.close()
    print("Recording stopped")
}
```

**流式录音（无回调）示例：**

```catbase
def main(args:list[str]) {
    # 创建录音流
    stream: RecordStream = recordStream(44100, 1, 1024, 3, "plughw:CARD=0,DEV=0")

    frames: list[bytes] = []
    data: bytes

    print("开始录音，按Ctrl+C停止...\n")

    # 持续录音，检测活跃状态
    while stream.is_active() {
        data = stream.read()
        if len(data) > 0 {
            frames.append(data)
        }
    }

    # 关闭流
    stream.close()

    # 合并所有录音数据
    all_data: bytes = bytes("")
    i: int = 0
    while i < frames.len() {
        all_data = all_data + frames[i]
        i = i + 1
    }

    # 保存为WAV
    save_wav(all_data, "/tmp/stream_recording.wav", 44100)

    print("录音完成，已保存到 /tmp/stream_recording.wav\n")
}
```

### 15.4 播放音频 {#154-播放音频}

CatBase 提供两种播放音频的方式：`play` 和 `playStream`，分别适用于不同场景。

#### play - 一次性播放

`play(data:bytes, sample_rate:int, device_name:str) : None` - 播放 PCM 音频数据

**适用场景：**
- 播放已完整的音频数据（如整段录音）
- 简单的播放需求，不需要流式控制
- 播放文件（需先读取为PCM数据）

参数：

- `data` - bytes 类型的 PCM 音频数据
- `sample_rate` - 采样率（如 16000）
- `device_name` - 设备名称，格式为 `plughw:CARD=X,DEV=Y`，可使用 `getOutputDeviceList()` 获取

```catbase
def main(args:list[str]) {
    # 录音
    data:bytes = record(3, 16000, 1, "plughw:CARD=0,DEV=0", 1024)

    # 播放（一次性播放整个数据，指定输出设备）
    play(data, 16000, "plughw:CARD=1,DEV=0")
}
```

#### playStream - 流式播放

`playStream(rate:int, channels:int, format:int, device_name:str, callback:function) : PlayStream` - 创建流式播放对象

**适用场景：**
- 需要实时流式播放（如网络音频流、实时合成音频）
- 需要控制播放状态（is_active、wait）
- 需要分段写入音频数据
- 需要长时间播放大量音频数据
- 需要精确控制播放流程

**参数：**

| 参数 | 关键字参数 | 默认值 | 说明 |
|------|-----------|--------|------|
| rate | rate | 16000 | 采样率（如 16000） |
| channels | channels | 1 | 声道数（如 1） |
| format | format | 3 | 音频格式代码 |
| device_name | device_name | "default" | 设备名称，格式为 `plughw:CARD=X,DEV=Y` |
| callback | callback | None | 回调函数（可选） |

**参数说明：**

- `rate` - 采样率，单位 Hz
- `channels` - 声道数
- `format` - 音频格式代码，见下表
- `device_name` - ALSA 设备名称，使用 `getOutputDeviceList()` 获取
- `callback` - 可选的回调函数，用于异步播放

**format 格式代码：**

| 代码 | 格式 |
|------|------|
| 1 | S8 |
| 2 | U8 |
| 3 | S16_LE (默认) |
| 4 | S16_BE |
| 7 | S24_LE |
| 11 | S32_LE |
| 15 | FLOAT |
| 16 | FLOAT64 |
| 17 | MU_LAW |
| 18 | A_LAW |

**play 与 playStream 对比：**

| 特性 | play | playStream |
|------|------|-------------|
| 用法 | 一次性播放整个数据 | 创建流对象，分段写入播放 |
| 复杂度 | 简单 | 稍复杂 |
| 控制能力 | 无 | 可控制播放状态、等待完成 |
| 适用场景 | 播放短音频、简单需求 | 实时流播放、大数据量播放 |
| 资源管理 | 自动释放 | 需手动调用 close() |
| 回调支持 | 无 | 支持回调机制 |

#### PlayStream 方法

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `write(data)` | bool | 写入音频数据 |
| `is_active()` | bool | 检查播放流是否处于活跃状态 |
| `wait()` | None | 等待播放完成 |
| `close()` | None | 关闭播放流 |
| `setCallback(callback)` | None | 设置回调函数 |
| `startPlaying()` | None | 启动带回调的异步播放 |
| `stopPlaying()` | None | 停止播放 |

**播放回调机制说明：**

当指定 `callback` 参数时，播放会在独立线程中异步进行：
- 每当音频设备需要数据时，自动调用回调函数获取音频数据
- 回调函数返回 `bytes` 类型的音频数据
- 返回空数据时，播放会暂停等待

**回调函数签名：**
```catbase
def get_audio_data() -> bytes {
    # 返回音频数据供播放
    return bytes("audio_data_for_playback")
}
```

**使用回调的播放示例：**

```catbase
# 播放回调函数 - 当音频设备需要数据时被调用
def get_audio_data() -> bytes {
    # 可以在这里生成或获取音频数据
    # 例如：从文件读取、实时合成、从网络接收等
    return bytes("audio_chunk_data")
}

def main(args: list[str]) {
    # 创建带回调的播放流
    # 参数: rate, channels, format, device_name, callback
    pstream: PlayStream = playStream(16000, 1, 3, "plughw:CARD=1,DEV=0", get_audio_data)

    print("Playback started with callback...")
    sleep(5)  # 播放5秒

    pstream.stopPlaying()
    pstream.close()
    print("Playback stopped")
}
```

**使用关键字参数的播放示例：**

```catbase
def get_audio_data() -> bytes {
    return bytes("audio_data")
}

def main(args: list[str]) {
    # 使用关键字参数
    pstream: PlayStream = playStream(rate=16000, channels=1, format=3, device_name="plughw:CARD=1,DEV=0", callback=get_audio_data)

    print("Playback started...")
    sleep(5)

    pstream.stopPlaying()
    pstream.close()
    print("Playback stopped")
}
```

**流式播放（无回调）示例：**

```catbase
def main(args:list[str]) {
    # 创建播放流
    pstream: PlayStream = playStream(44100, 1, 3, "plughw:CARD=1,DEV=0")

    # 录音
    data:bytes = record(5, 44100, 1, "plughw:CARD=0,DEV=0", 1024)

    # 流式播放
    pstream.write(data)

    # 等待播放完成
    pstream.wait()

    # 关闭播放流
    pstream.close()

    print("播放完成\n")
}
```

### 15.5 音频设备列表 {#155-音频设备列表}

CatBase 提供 `getInputDeviceList()` 和 `getOutputDeviceList()` 函数获取系统音频设备信息。

#### 设备名称格式说明

CatBase 统一使用 `plughw:CARD=X,DEV=Y` 格式的设备名称：

- `plughw:` - 使用 ALSA 插件层，自动处理采样率转换和格式转换，推荐使用
- `hw:` - 直接访问硬件，要求硬件支持指定格式（低延迟但可能不支持某些采样率）

**为什么使用 `plughw:`？**

| 特性 | `hw:CARD=X,DEV=Y` | `plughw:CARD=X,DEV=Y` |
|------|-------------------|----------------------|
| 采样率转换 | ❌ 不支持 | ✅ 自动转换 |
| 格式转换 | ❌ 不支持 | ✅ 自动处理 |
| 延迟 | 更低 | 略高 |
| 适用场景 | 专业音频 | 通用场景（推荐） |

#### getInputDeviceList

`getInputDeviceList() : list[dict[str, str]]` - 获取可用的输入设备（录音设备）列表

返回可用录音设备的列表，每个设备是一个 dict，包含以下字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | str | 设备名称，格式为 `plughw:CARD=X,DEV=Y` |
| `description` | str | 设备描述名称 |

```catbase
def main(args:list[str]) {
    # 获取输入设备列表
    input_devices:list[dict[str, str]] = getInputDeviceList()
    
    print("可用录音设备：\n")
    i:int = 0
    while i < len(input_devices) {
        dev:dict[str, str] = input_devices[i]
        print("  ", i, ": name=", dev["name"], ", desc=", dev["description"], "\n")
        i = i + 1
    }
    
    # 使用第一个设备录音（跳过第0个默认设备）
    if len(input_devices) > 1 {
        dev_name:str = input_devices[1]["name"]
        data:bytes = record(3, "16000", "1", dev_name, "1024")
    }
}
```

#### getOutputDeviceList

`getOutputDeviceList() : list[dict[str, str]]` - 获取可用的输出设备（播放设备）列表

返回可用播放设备的列表，每个设备是一个 dict，包含以下字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | str | 设备名称，格式为 `plughw:CARD=X,DEV=Y` |
| `description` | str | 设备描述名称 |

```catbase
def main(args:list[str]) {
    # 获取输出设备列表
    output_devices:list[dict[str, str]] = getOutputDeviceList()
    
    print("可用播放设备：\n")
    i:int = 0
    while i < len(output_devices) {
        dev:dict[str, str] = output_devices[i]
        print("  ", i, ": name=", dev["name"], ", desc=", dev["description"], "\n")
        i = i + 1
    }
    
    # 使用第一个设备播放（跳过第0个默认设备）
    if len(output_devices) > 1 {
        dev_name:str = output_devices[1]["name"]
        data:bytes = record(3, 16000, 1, "default", 1024)
        play(data, 16000, dev_name)
    }
}
```

### 15.6 保存为 WAV 文件 {#156-保存为-wav-文件}

#### save_wav

`save_wav(data:str, filename:str, sample_rate:str) : None` - 将 PCM 数据保存为 WAV 文件

参数：

- `data` - bytes 类型的 PCM 音频数据
- `filename` - 保存的文件路径
- `sample_rate` - 采样率字符串（如 "16000"）

**WAV 文件格式：**

- 采样率：可配置（默认 16000 Hz）
- 声道：1（单声道）
- 位深：16位
- 格式：PCM

```catbase
def main(args:list[str]) {
    data:bytes = record(5, 16000, 1, "plughw:CARD=0,DEV=0", 1024)
    save_wav(data, "/tmp/my_recording.wav", 16000)
    print("已保存为 WAV 文件\n")
}
```

### 15.7 完整示例 {#157-完整示例}

**示例1：简单录音和播放（使用设备列表）**

```catbase
def main(args:list[str]) {
    # 获取设备列表
    input_devices:list[dict[str, str]] = getInputDeviceList()
    output_devices:list[dict[str, str]] = getOutputDeviceList()
    
    # 跳过第0个默认设备，使用第一个实际设备
    if len(input_devices) < 2 or len(output_devices) < 2 {
        print("未找到音频设备\n")
        return
    }
    
    in_dev:str = input_devices[1]["name"]
    out_dev:str = output_devices[1]["name"]
    
    print("开始录音...\n")

    # 录音5秒，返回PCM数据
    data:bytes = record(5, 16000, 1, in_dev, 1024)

    # 保存为WAV文件
    save_wav(data, "/tmp/recording.wav", 16000)

    print("录音完成，已保存到 /tmp/recording.wav\n")

    # 播放录音
    play(data, 16000, out_dev)

    print("播放完成\n")
}
```

**示例2：使用流式录音和播放**

```catbase
def main(args:list[str]) {
    # 获取设备列表
    input_devices:list[dict[str, str]] = getInputDeviceList()
    
    if len(input_devices) < 2 {
        print("未找到录音设备\n")
        return
    }
    
    in_dev:str = input_devices[1]["name"]
    
    # 使用一次性录音
    frames: list[bytes] = []
    
    print("开始录音...\n")
    
    # 录音5次，每次1秒
    i: int = 0
    while i < 5 {
        data:bytes = record(1, 16000, 1, in_dev, 1024)
        frames.append(data)
        i = i + 1
    }
    
    # 合并数据
    all_data: str = ""
    i = 0
    while i < frames.len() {
        all_data = all_data + frames[i]
        i = i + 1
    }
    
    save_wav(all_data, "/tmp/recording.wav", 16000)
    print("完成！\n")
}
```

**示例3：多段录音**

```catbase
def main(args:list[str]) {
    # 获取设备列表
    input_devices:list[dict[str, str]] = getInputDeviceList()
    
    if len(input_devices) < 2 {
        print("未找到录音设备\n")
        return
    }
    
    in_dev:str = input_devices[1]["name"]
    
    # 录制10段录音，每段1秒
    frames: list[bytes] = []
    segment_count: int = 10
    
    i: int = 0
    while i < segment_count {
        print("录制第")
        print(i + 1)
        print("段...\n")

        data:bytes = record(1, 16000, 1, in_dev, 1024)
        frames.append(data)

        i = i + 1
    }
    
    # 合并并保存
    all_data: str = ""
    j: int = 0
    while j < frames.len() {
        all_data = all_data + frames[j]
        j = j + 1
    }
    
    save_wav(all_data, "/tmp/segments.wav", 16000)
    print("完成！\n")
}
```

### 15.8 与 Python PyAudio 对比 {#158-与-python-pyaudio-对比}

**录音流：**

| PyAudio | CatBase | 说明 |
|---------|---------|------|
| `pyaudio.PyAudio()` | 内置 | 无需创建 |
| `stream = p.open(format=FORMAT, channels=CHANNELS, rate=RATE, input=True, frames_per_buffer=CHUNK)` | `stream: RecordStream = recordStream(rate=RATE, channels=CHANNELS, chunk=CHUNK, format=FORMAT)` | 创建录音流 |
| `stream.read(CHUNK)` | `stream.read()` | 读取音频数据 |
| `stream.is_active()` | `stream.is_active()` | 检查活跃状态 |
| `stream.stop_stream()` | `stream.close()` | 停止/关闭流 |

**播放流：**

| PyAudio | CatBase | 说明 |
|---------|---------|------|
| `stream = p.open(format=FORMAT, channels=CHANNELS, rate=RATE, output=True, frames_per_buffer=CHUNK)` | `pstream: PlayStream = playStream(rate=RATE, channels=CHANNELS, format=FORMAT)` | 创建播放流 |
| `stream.write(data)` | `pstream.write(data)` | 写入音频数据 |
| `stream.is_active()` | `pstream.is_active()` | 检查播放状态 |
| `stream.stop_stream()` | `pstream.close()` | 停止/关闭流 |

***

## 16. 语法汇总

> **本章导读：** 经过前面章节的学习，你已经掌握了 CatBase 的所有核心特性。本章将对所有语法进行汇总，方便查阅和复习。通过本章的语法汇总，你可以快速回顾 CatBase 的关键字、数据类型、内置函数等知识点。

### 16.1 关键字

| 关键字      | 说明                           |
| ----------- | ------------------------------ |
| `def`       | 定义函数                       |
| `if`        | 条件语句                       |
| `else`      | 否则                           |
| `for`       | 循环（支持列表、范围、迭代器） |
| `while`     | 循环                           |
| `return`    | 返回值                         |
| `break`     | 跳出循环                       |
| `try`       | 尝试块                         |
| `except`    | 捕获异常                       |
| `catch`     | 捕获异常（兼容）               |
| `finally`   | 最终块（总是执行）             |
| `Exception` | 异常类型                       |
| `thread`    | 创建线程                       |
| `async`     | 定义协程函数                   |
| `await`     | 等待协程                       |
| `import`    | 导入模块                       |
| `from`      | 从模块导入（用于声明外部函数） |
| `as`        | 别名                           |
| `None`      | 空值                           |
| `True`      | 布尔真值                       |
| `False`     | 布尔假值                       |
| `in`        | 成员判断 / for-in 迭代         |
| `is`        | 身份判断                       |
| `not`       | 逻辑非                         |
| `and`       | 逻辑与                         |
| `or`        | 逻辑或                         |

### 16.2 数据类型

| 类型       | 说明                         |
| ---------- | ---------------------------- |
| `int`      | 整数                         |
| `float`    | 浮点数                       |
| `str`      | 字符串                       |
| `bool`     | 布尔值                       |
| `list`     | 列表                         |
| `dict`     | 字典                         |
| `bytes`    | 字节序列                     |
| `function` | 函数引用                     |
| `None`     | 空值类型                     |
| `any`      | 任意类型（用于外部函数声明） |

### 16.3 内置函数汇总

| 函数                            | 说明                                |
| ------------------------------- | ----------------------------------- |
| **打印/输入**                   |                                     |
| `print(...)`                    | 打印                                |
| `input(prompt)`                 | 读取输入                            |
| **类型转换**                    |                                     |
| `int(x)`                        | 转换为整数                          |
| `float(x)`                      | 转换为浮点数                        |
| `str(x)`                        | 转换为字符串                        |
| `bool(x)`                       | 转换为布尔值                        |
| `list(x)`                       | 转换为列表                          |
| `dict(x)`                       | 转换为字典                          |
| `bytes(x)`                      | 转换为字节序列                      |
| **类型检查**                    |                                     |
| `type(x)`                       | 获取类型                            |
| `isinstance(x, type)`           | 类型判断                            |
| `assert(cond, msg)`             | 断言                                |
| **数学运算**                    |                                     |
| `abs(x)`                        | 绝对值                              |
| `max(a, b)`                     | 最大值                              |
| `min(a, b)`                     | 最小值                              |
| `pow(a, b)`                     | 幂运算                              |
| `round(x)`                      | 四舍五入（返回与输入相同类型）      |
| `round(x, n)`                   | 四舍五入保留 n 位小数（返回 float） |
| `sum(list)`                     | 求和                                |
| **进制转换**                    |                                     |
| `bin(x)`                        | 转二进制                            |
| `oct(x)`                        | 转八进制                            |
| `hex(x)`                        | 转十六进制                          |
| **字符转换**                    |                                     |
| `chr(x)`                        | 整数转字符                          |
| `ord(x)`                        | 字符转整数                          |
| **字符串/容器操作**             |                                     |
| `len(x)`                        | 获取长度                            |
| `range(start, end, [step])`     | 生成范围                            |
| `append(list, item)`            | 追加元素到列表                      |
| `pop(list, [index])`            | 弹出元素                            |
| `insert(list, index, item)`     | 插入元素                            |
| `remove(list, item)`            | 移除元素                            |
| **文件操作**                    |                                     |
| `file(filename, mode)`          | 打开文件                            |
| `close(f)`                      | 关闭文件                            |
| **网络编程**                    |                                     |
| `tcpsocket()`                   | 创建 TCP 套接字                     |
| `udpsocket()`                   | 创建 UDP 套接字                     |
| `http_get(url, timeout)`        | HTTP GET                            |
| `http_post(...)`                | HTTP POST                           |
| `websocket(url, headers[可选])` | WebSocket 连接                      |
| **JSON 处理**                   |                                     |
| `json_dumps(dict)`              | 字典转 JSON                         |
| `json_loads(str)`               | JSON 转字典                         |
| **串口通信**                    |                                     |
| `serial(port, baud_rate)`       | 打开串口                            |
| **线程/同步**                   |                                     |
| `thread func(args)`             | 创建线程（语句）                    |
| `thread_join(t)`                | 等待线程结束                        |
| `mutex()`                       | 创建互斥锁                          |
| `lock(m)`                       | 加锁                                |
| `unlock(m)`                     | 解锁                                |
| `queue()`                       | 创建消息队列                        |
| **时间函数**                    |                                     |
| `time()`                        | 获取当前时间戳                      |
| `perf_counter()`                | 高精度计时器                        |
| `strftime(format, timestamp)`   | 时间格式化                          |
| **音频**                        |                                     |
| `record(seconds, rate, ...)`    | 录音                                |
| `play(data, rate, device)`      | 播放音频                            |
| `save_wav(data, filename, ...)` | 保存为 WAV 文件                     |
| `recordStream(...)`             | 创建录音流                          |
| `playStream(...)`               | 创建播放流                          |
| `getInputDeviceList()`          | 获取输入设备列表                    |
| `getOutputDeviceList()`         | 获取输出设备列表                    |
| **指针**                        |                                     |
| `pointer(addr)`                 | 创建指针                            |
| `pointer_of(var)`               | 获取变量指针                        |
| **其他**                        |                                     |
| `sleep(seconds)`                | 休眠                                |
| `exec(code)`                    | 执行 CatBase 代码                   |

## 后记

### 关于作者

CatBase 编程语言由来自中国的**钟声**设计并研发。钟声同时也是中国珠海的**豆子机器人科技** (http://dorobot.net) 公司的创始人。

豆子机器人科技 (http://dorobot.net) 是一家专注于人工智能和机器人技术的创新公司，致力于开发智能化解决方案。CatBase 作为公司内部使用的编程语言，最初是为了解决项目开发中遇到的效率和性能问题而创建的。
CatBase编程语言是为Ai应用研发而生，极小运行环境下可以替代c，支持python语法。

### 致谢

感谢以下人员对 CatBase 的支持与贡献：

- **所有 CatBase 语言的爱好者** - 感谢你们的选择和信任
- **开源社区** - 
感谢 Zig 语言团队创造了如此优秀的编译工具链
感谢 Python 社区为 CatBase 提供了语法的灵感与参考
感谢 C 语言生态为 CatBase 提供了性能优化的参考
感谢 CatBase 社区为 CatBase 提供了反馈和建议
感谢 中国广东珠海的豆子机器人科技公司 (http://dorobot.net) 为 CatBase 提供了资金支持

### 展望

CatBase 将持续迭代优化，未来计划支持：

- 更多的内置数据类型
- 更丰富的标准库
- 跨平台支持（Windows、macOS 等）
- 更好的 IDE 支持

我们相信，CatBase 将成为一门实用、高效、易学的编程语言，帮助更多开发者实现他们的创意。

### 联系我们

- 官方网站：<http://catbase-lang.com>

***

*CatBase 编程语言参考手册 - 版本 1.0*
