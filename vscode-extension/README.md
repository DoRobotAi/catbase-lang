# CatBase Language Support

CatBase is a modern, statically-typed programming language designed for clarity and ease of use. It combines Python-like syntax simplicity with C-like performance by compiling to native executables.

## Features

- **Clean, Python-like syntax** with explicit type declarations
- **Static typing** for better code reliability and readability
- **Compiles to native executables** - no interpreter needed
- **Rich standard library** - networking, threading, file I/O, audio
- **C library integration** - import `.so` and `.a` files directly
- **Cross-platform** - Linux, macOS, Windows support

## Installation

### From VS Code/Trae Marketplace

1. Open VS Code or Trae
2. Go to Extensions (`Ctrl+Shift+X`)
3. Search for "CatBase Language"
4. Click Install

### Manual Installation (VSIX)

1. Download the `.vsix` file from [open-vsx.org](https://open-vsx.org/extension/catbase/catbase-language)
2. In VS Code/Trae, press `Ctrl+Shift+P`
3. Type "Install from VSIX" and select the file

## Language Overview

### Hello World

```catbase
def main(args:list[str]) {
    print("Hello, World!")
}
```

### Variables (Explicit Type Declaration)

```catbase
name:str = "CatBase"
age:int = 1
pi:float = 3.14159
items:list[int] = [1, 2, 3]
```

### Functions

```catbase
def greet(name:str) -> str {
    return "Hello, " + name + "!"
}

def main(args:list[str]) {
    result:str = greet("World")
    print(result)
}
```

### Control Flow

```catbase
# If-else
if age >= 18 {
    print("Adult")
} else {
    print("Minor")
}

# For loop
for i:int in range(10) {
    print(i)
}

# While loop
count:int = 0
while count < 5 {
    count = count + 1
}
```

### Data Types

| Type | Description | Example |
|------|-------------|---------|
| `int` | 64-bit integer | `42` |
| `float` | 64-bit float | `3.14` |
| `str` | String | `"hello"` |
| `bool` | Boolean | `true` / `false` |
| `list[T]` | Generic list | `[1, 2, 3]` |
| `dict[K,V]` | Dictionary | `{"a": 1}` |
| `bytes` | Byte array | `""` |
| `None` | Null value | `None` |

### Operators

**Arithmetic:** `+`, `-`, `*`, `/`, `%`, `//`

**Comparison:** `==`, `!=`, `<`, `>`, `<=`, `>=`

**Logical:** `and`, `or`, `not`

**Assignment:** `=`, `+=`, `-=`, `*=`, `/=`

### Built-in Functions

```catbase
print("Message")           # Print to console
len("hello")               # String/list length
input("Prompt: ")          # Read user input
type(value)                # Get type name
str(123)                   # Convert to string
int("42")                  # Convert to integer
float("3.14")              # Convert to float
range(10)                  # Generate range
json.parse("{}")           # Parse JSON string
find("hello", "ell")       # Find substring
```

### File Operations

```catbase
f:File = open("file.txt", "r")
content:str = f.read()
close(f)

// Write file
f:File = open("output.txt", "w")
f.write("Hello, File!")
close(f)
```

### Networking

```catbase
// TCP Client
sock:Socket = socket()
sock.connect("example.com", 80)
sock.send("GET / HTTP/1.1\r\n\r\n")
response:str = sock.recv(1024)
sock.close()

// TCP Server
server:ServerSocket = server_socket(8080)
conn:Socket = server.accept()
msg:str = conn.recv(1024)
conn.send("HTTP/1.1 200 OK\r\n\r\nHello")
conn.close()
server.close()

// WebSocket
ws:WebSocket = websocket("wss://example.com/ws")
ws.send("Hello")
msg:str = ws.recv()
ws.close()
```

### Multithreading

```catbase
// Create thread
thread my_function(arg1, arg2)

// Mutex
m:Mutex = mutex()
lock(m)
// critical section
unlock(m)

// Queue (Thread-safe queue)
q:Queue = queue(10)
q.put_nowait(item)
item:any = q.get(1000)  // timeout in ms
```

**Note:** For detailed API documentation on Channel and Queue, refer to the [full CatBase documentation](https://github.com/catbase/catbase).

### Audio Recording and Playback

```catbase
// Record audio
data:bytes = record(5, "16000", "1", "", "1024")
save_wav(data, "recording.wav", "16000")

// Play audio
play(data, "16000")

// Stream recording with callback
stream:AudioStream = audio_stream("16000", "1", "1024", def(data:bytes) {
    print("Received chunk")
})
stream.start_recording()
stream.stop_recording()
stream.close()
```

## Compilation

```bash
# Basic compilation
catbasecc source.cat

# Run
./source

# Specify output name
catbasecc -o myprogram source.cat

# Optimization levels
catbasecc -O ReleaseFast source.cat    # Fast (default)
catbasecc -O ReleaseSmall source.cat # Small size
catbasecc -O ReleaseSafe source.cat   # Safe with runtime checks

# Static linking (no external dependencies)
catbasecc -static source.cat
```

## File Extension

CatBase source files use the `.cat` extension.

## License

MIT License

## Resources

- [CatBase Documentation](https://github.com/dorobotai/catbase-lang)
- [Report Issues](https://github.com/dorobotai/catbase-lang/issues)
