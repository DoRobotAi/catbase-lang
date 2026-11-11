// CatBase Runtime Library
// Provides Str (copy-on-write string), List, Dict with Python-like methods.

const std = @import("std");
const ctime = @cImport(@cInclude("time.h"));
const cstdio = @cImport(@cInclude("stdio.h"));
const ctermios = @cImport(@cInclude("termios.h"));
const cunistd = @cImport(@cInclude("unistd.h"));
const mem = std.mem;
const Allocator = mem.Allocator;

// 全局通用分配器，用于需要正常 free 的场景（如全局 Queue）
var globalAllocator = std.heap.GeneralPurposeAllocator(.{}){};

// 获取全局分配器
pub fn getGlobalAllocator() Allocator {
    return globalAllocator.allocator();
}

// 全局线程句柄列表，用于管理所有子线程
pub var threadHandles = std.ArrayList(std.Thread).init(std.heap.page_allocator);

// 等待所有子线程完成
pub fn joinAllThreads() void {
    for (threadHandles.items) |*handle| {
        handle.join();
    }
}

pub const Exception = error{
    RuntimeError,
};

pub fn tryCatchWrap(func: fn () void) anyerror!void {
    func();
}

pub fn throw(msg: []const u8) noreturn {
    @panic(msg);
}

// ============================ Input ============================
// input 函数：从标准输入读取一行文本
// input() - 无提示符
// input(prompt) - 显示提示符
// 使用 raw mode 手动处理输入，同时支持 ^H 和 ^? 作为删除字符

// 保存原始终端设置
var original_termios: ctermios.termios = undefined;
var termios_saved: bool = false;

// 设置终端为 raw mode，手动处理行编辑
fn setupRawMode() void {
    if (termios_saved) return;

    const fd = cunistd.STDIN_FILENO;
    if (ctermios.tcgetattr(fd, &original_termios) != 0) return;
    termios_saved = true;

    var new_termios = original_termios;
    // 关闭 ICANON (使用 raw mode) 和 ECHO (手动控制回显)
    const flags: ctermios.tcflag_t = ctermios.ICANON | ctermios.ECHO;
    new_termios.c_lflag &= ~flags;
    // 设置 VMIN=1, VTIME=0，等待至少一个字符
    new_termios.c_cc[ctermios.VMIN] = 1;
    new_termios.c_cc[ctermios.VTIME] = 0;

    _ = ctermios.tcsetattr(fd, ctermios.TCSANOW, &new_termios);
}

// 恢复原始终端设置
fn restoreTerminal() void {
    if (!termios_saved) return;
    const fd = cunistd.STDIN_FILENO;
    _ = ctermios.tcsetattr(fd, ctermios.TCSANOW, &original_termios);
}

// 手动读取一行输入，支持 backspace 删除
// 同时识别 ^H (ASCII 8) 和 ^? (ASCII 127) 作为删除字符
pub fn input(allocator: Allocator) Str {
    setupRawMode();

    var buf: [65536]u8 = undefined;
    var len: usize = 0;
    const stdout = std.io.getStdOut().writer();

    while (true) {
        var ch: u8 = 0;
        const n = cunistd.read(cunistd.STDIN_FILENO, &ch, 1);
        if (n != 1) break;

        if (ch == '\n' or ch == '\r') {
            // 回车结束输入
            stdout.print("\n", .{}) catch {};
            break;
        } else if (ch == 8 or ch == 127) {
            // ^H (ASCII 8) 或 ^? (ASCII 127) - 删除最后一个字符
            if (len > 0) {
                len -= 1;
                // 回显删除效果：退格 + 空格 + 退格
                stdout.print("\x08 \x08", .{}) catch {};
            }
        } else if (ch >= 32 and ch < 127) {
            // 可打印 ASCII 字符
            if (len < buf.len - 1) {
                buf[len] = ch;
                len += 1;
                stdout.print("{c}", .{ch}) catch {};
            }
        }
        // 忽略其他控制字符
    }

    restoreTerminal();

    return Str.init(allocator, buf[0..len]) catch Str{ .data = &[_]u8{}, .allocator = allocator, .borrowed = false };
}

// inputWithPrompt 函数
pub fn inputWithPrompt(allocator: Allocator, prompt: Str) Str {
    std.io.getStdOut().writer().print("{s}", .{prompt.data}) catch {};
    return input(allocator);
}

pub const ExceptionInfo = struct {
    message: []const u8,
};

// ============================ Range ============================
// range 函数：生成整数序列
// range(stop) - 0 到 stop-1
// range(start, stop) - start 到 stop-1
// range(start, stop, step) - start 到 stop-1，步长为 step
pub fn range(allocator: Allocator, args: [3]i64) List(i64) {
    var result = List(i64).init(allocator);
    var start: i64 = 0;
    var stop: i64 = args[0];
    var step: i64 = 1;

    if (args.len >= 2) {
        start = args[0];
        stop = args[1];
    }
    if (args.len >= 3) {
        step = args[2];
    }

    if (step > 0) {
        var i = start;
        while (i < stop) {
            _ = result.append(i) catch unreachable;
            i += step;
        }
    } else if (step < 0) {
        var i = start;
        while (i > stop) {
            _ = result.append(i) catch unreachable;
            i += step;
        }
    }

    return result;
}

// 打印文件操作错误的详细信息
// source_loc: CatBase 源文件位置，格式 "filename:line"，可以为空字符串
fn printFileError(path: []const u8, err: anyerror, source_loc: []const u8) void {
    std.debug.print("\nError: file operation failed\n", .{});

    // 关键修复：当 path 为空时，明确提示用户路径无效
    if (path.len == 0) {
        std.debug.print("  Reason: {s}\n", .{@errorName(err)});
        std.debug.print("  Path: <empty string> (file path was not specified or was truncated)\n", .{});
        std.debug.print("  Hint: The file path appears to be empty.\n", .{});
        std.debug.print("        - Check if the variable holding the path was correctly initialized\n", .{});
        std.debug.print("        - Check if string operations (e.g. string concatenation) caused data truncation\n", .{});
        std.debug.print("        - Use an absolute path like /tmp/data.json\n", .{});
        if (source_loc.len > 0) {
            std.debug.print("  Source: {s}\n", .{source_loc});
        }
        return;
    }

    std.debug.print("  Reason: {s}\n", .{@errorName(err)});

    // 使用 stack buffer 获取绝对工作目录
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    if (std.fs.cwd().realpath(".", &cwd_buf)) |dir| {
        if (std.fs.path.isAbsolute(path)) {
            // 绝对路径：直接打印，并显示它指向的文件
            std.debug.print("  File path: {s} (absolute path)\n", .{path});
            std.debug.print("  Searched at: {s}\n", .{path});
        } else {
            // 相对路径：拼接绝对路径
            std.debug.print("  File path: {s} (relative path)\n", .{path});
            std.debug.print("  Current working directory: {s}/\n", .{dir});
            std.debug.print("  Searched at: {s}/{s}\n", .{ dir, path });
        }
    } else |_| {
        std.debug.print("  File path: {s}\n", .{path});
        std.debug.print("  Searched at: <could not determine absolute path>\n", .{});
    }

    // 显示 CatBase 源文件位置（如果提供）
    if (source_loc.len > 0) {
        std.debug.print("  Source location: {s} (CatBase source file)\n", .{source_loc});
    }

    // 针对常见错误提供建议
    switch (err) {
        error.FileNotFound => {
            std.debug.print("  Hint: The file does not exist.\n", .{});
            std.debug.print("        - Check the spelling of the filename\n", .{});
            std.debug.print("        - Check that the file exists in the directory shown above\n", .{});
            std.debug.print("        - Or use an absolute path (e.g., /tmp/data.json)\n", .{});
        },
        error.AccessDenied => {
            std.debug.print("  Hint: Check file permissions (read/write access).\n", .{});
        },
        error.IsDir => {
            std.debug.print("  Hint: The path points to a directory, not a file.\n", .{});
        },
        error.NotDir => {
            std.debug.print("  Hint: A component of the path is not a directory.\n", .{});
        },
        else => {},
    }
}

// ============================ File ============================
pub const File = struct {
    const Self = @This();
    file: std.fs.File,
    allocator: Allocator,

    pub fn open(allocator: Allocator, path: Str, mode: Str, source_loc: Str) !Self {
        if (std.mem.eql(u8, mode.data, "w") or std.mem.eql(u8, mode.data, "a")) {
            const file = std.fs.cwd().createFile(path.data, .{ .truncate = false });
            if (file) |f| {
                return Self{
                    .file = f,
                    .allocator = allocator,
                };
            } else |err| {
                printFileError(path.data, err, source_loc.data);
                return err;
            }
        } else {
            const file = std.fs.cwd().openFile(path.data, .{});
            if (file) |f| {
                return Self{
                    .file = f,
                    .allocator = allocator,
                };
            } else |err| {
                printFileError(path.data, err, source_loc.data);
                return err;
            }
        }
    }

    // 安全打开文件，如果失败则退出
    // 注意：详细错误信息由 File.open 内部打印，此处只负责退出，避免重复输出
    pub fn openSafe(allocator: Allocator, path: Str, mode: Str, source_loc: Str) Self {
        return open(allocator, path, mode, source_loc) catch {
            std.process.exit(1);
        };
    }

    pub fn read(self: *const Self) Str {
        var file = @constCast(&self.file);
        const content = file.readToEndAlloc(std.heap.page_allocator, 1024 * 1024) catch unreachable;
        return Str{
            .data = content,
            .allocator = std.heap.page_allocator,
            .borrowed = false,
            .is_bytes = false,
        };
    }

    pub fn write(self: *const Self, content: Str) void {
        var file = @constCast(&self.file);
        file.seekTo(0) catch unreachable;
        file.writeAll(content.data) catch unreachable;
    }

    pub fn append(self: *const Self, content: Str) void {
        var file = @constCast(&self.file);
        file.seekTo(0) catch unreachable;
        const end_pos = file.getEndPos() catch unreachable;
        file.seekTo(end_pos) catch unreachable;
        file.writeAll(content.data) catch unreachable;
    }

    pub fn writeAt(self: *const Self, content: Str, pos: i64) void {
        var file = @constCast(&self.file);
        file.seekTo(@as(u64, @intCast(pos))) catch unreachable;
        file.writeAll(content.data) catch unreachable;
    }

    pub fn deinit(self: *Self) void {
        self.file.close();
    }

    pub fn close(self: *Self) void {
        self.deinit();
    }
};

// ============================ RecordStream 流式录音 ============================
pub const RecordStream = struct {
    const Self = @This();
    capture_handle: ?*alsa.snd_pcm_t,
    params: ?*alsa.snd_pcm_hw_params_t,
    sample_rate: c_uint,
    channels: c_uint,
    chunk: c_ulong,
    allocator: Allocator,
    running: bool,
    callback: ?*const fn (data: Str) void,
    callback_bytes: ?*const fn (data: []u8) void, // 新增：bytes 回调
    device_name_buf: ?[]u8, // 保存设备名称缓冲区的所有权

    // 创建录音流
    // format: ALSA格式代码
    // device_name: 设备名称字符串（如 "default", "plughw:0,0"）
    pub fn open(allocator: Allocator, sample_rate: i64, channels: i64, chunk: i64, format: i64, device_name_str: Str) !Self {
        var sample_rate_uint = @as(c_uint, @intCast(sample_rate));
        const channels_uint = @as(c_uint, @intCast(channels));
        const chunk_ulong = @as(c_ulong, @intCast(chunk));
        const format_code = @as(c_int, @intCast(format));

        var capture_handle: ?*alsa.snd_pcm_t = undefined;
        var device_name_buf: ?[]u8 = null;
        var device_name: [:0]const u8 = "default";

        // 将设备名称转换为 C 字符串
        // 注意：device_name_buf 必须保存到 RecordStream 中，在 close() 时释放
        // 因为 ALSA 内部会引用这个字符串
        if (device_name_str.data.len > 0) {
            device_name_buf = std.fmt.allocPrintZ(allocator, "{s}", .{device_name_str.data}) catch null;
            if (device_name_buf) |buf| {
                device_name = buf[0..buf.len :0];
            }
        }

        // 打开录音设备（使用指定的设备名称）
        if (alsa.snd_pcm_open(@as([*c]?*alsa.snd_pcm_t, @ptrCast(&capture_handle)), @ptrCast(device_name.ptr), alsa.SND_PCM_STREAM_CAPTURE, 0) < 0) {
            // 如果指定设备失败，尝试默认设备
            if (alsa.snd_pcm_open(@as([*c]?*alsa.snd_pcm_t, @ptrCast(&capture_handle)), "default", alsa.SND_PCM_STREAM_CAPTURE, 0) < 0) {
                return error.OpenFailed;
            }
        }

        var params: ?*alsa.snd_pcm_hw_params_t = undefined;
        _ = alsa.snd_pcm_hw_params_malloc(@as([*c]?*alsa.snd_pcm_hw_params_t, @ptrCast(&params)));

        // 设置参数
        if (alsa.snd_pcm_hw_params_any(capture_handle, params) < 0) {
            return error.InvalidParams;
        }

        if (alsa.snd_pcm_hw_params_set_access(capture_handle, params, alsa.SND_PCM_ACCESS_RW_INTERLEAVED) < 0) {
            return error.InvalidAccess;
        }

        // 将format代码转换为ALSA格式
        const alsa_format = switch (format_code) {
            1 => alsa.SND_PCM_FORMAT_S8,
            2 => alsa.SND_PCM_FORMAT_U8,
            3 => alsa.SND_PCM_FORMAT_S16_LE,
            4 => alsa.SND_PCM_FORMAT_S16_BE,
            5 => alsa.SND_PCM_FORMAT_U16_LE,
            6 => alsa.SND_PCM_FORMAT_U16_BE,
            7 => alsa.SND_PCM_FORMAT_S24_LE,
            8 => alsa.SND_PCM_FORMAT_S24_BE,
            9 => alsa.SND_PCM_FORMAT_U24_LE,
            10 => alsa.SND_PCM_FORMAT_U24_BE,
            11 => alsa.SND_PCM_FORMAT_S32_LE,
            12 => alsa.SND_PCM_FORMAT_S32_BE,
            13 => alsa.SND_PCM_FORMAT_U32_LE,
            14 => alsa.SND_PCM_FORMAT_U32_BE,
            15 => alsa.SND_PCM_FORMAT_FLOAT,
            16 => alsa.SND_PCM_FORMAT_FLOAT64,
            17 => alsa.SND_PCM_FORMAT_MU_LAW,
            18 => alsa.SND_PCM_FORMAT_A_LAW,
            else => alsa.SND_PCM_FORMAT_S16_LE, // 默认S16_LE
        };

        if (alsa.snd_pcm_hw_params_set_format(capture_handle, params, alsa_format) < 0) {
            return error.InvalidFormat;
        }

        var dir: c_int = 0;
        if (alsa.snd_pcm_hw_params_set_rate_near(capture_handle, params, @ptrCast(&sample_rate_uint), &dir) < 0) {
            return error.InvalidRate;
        }

        if (alsa.snd_pcm_hw_params_set_channels(capture_handle, params, channels_uint) < 0) {
            return error.InvalidChannels;
        }

        if (alsa.snd_pcm_hw_params(capture_handle, params) < 0) {
            return error.SetParamsFailed;
        }

        // 准备录音
        if (alsa.snd_pcm_prepare(capture_handle) < 0) {
            return error.PrepareFailed;
        }

        return Self{
            .capture_handle = capture_handle,
            .params = params,
            .sample_rate = sample_rate_uint,
            .channels = channels_uint,
            .chunk = chunk_ulong,
            .allocator = allocator,
            .running = false,
            .callback = null,
            .callback_bytes = null, // 初始化 bytes 回调为 null
            .device_name_buf = device_name_buf,
        };
    }

    // 设置回调函数
    pub fn setCallback(self: *Self, callback: *const fn (data: Str) void) void {
        self.callback = callback;
    }

    // 设置 bytes 回调函数（新增）
    pub fn setBytesCallback(self: *Self, callback: *const fn (data: []u8) void) void {
        self.callback_bytes = callback;
    }

    // 带回调的异步录音
    pub fn startRecording(self: *Self) !void {
        self.running = true;

        const bytes_per_sample: c_ulong = 2;
        const bytes_to_read = self.chunk * @as(c_ulong, self.channels) * bytes_per_sample;

        // 在新线程中运行录音循环
        const thread = try std.Thread.spawn(.{}, recordingThread, .{ self, bytes_to_read });
        thread.detach();
    }

    // 录音线程函数
    fn recordingThread(self: *Self, bytes_to_read: c_ulong) void {
        // 使用 global allocator，避免 arena 释放后线程仍在使用
        const safe_allocator = getGlobalAllocator();
        while (self.running) {
            const buffer = safe_allocator.alloc(u8, bytes_to_read) catch continue;

            const frames_read = alsa.snd_pcm_readi(self.capture_handle, buffer.ptr, self.chunk);
            if (frames_read < 0) {
                safe_allocator.free(buffer);
                if (!self.running) break; // 已停止，退出
                continue;
            }

            const actual_bytes = @as(usize, @intCast(frames_read)) * @as(c_ulong, self.channels) * 2;

            if (self.callback) |cb| {
                // 创建 Str，将 owned 设为 false，因为 buffer 会在下面被释放
                // fromStr() 会克隆数据，所以回调结束后 Queue 会拥有独立的数据副本
                const data = Str{
                    .data = buffer[0..actual_bytes],
                    .allocator = safe_allocator,
                    .borrowed = true,
                };
                cb(data);
            } else if (self.callback_bytes) |cb| {
                // bytes 回调：直接传 []u8，buffer 会在下面被释放
                // 注意：回调内必须完成数据处理或复制，buffer 释放后失效
                cb(buffer[0..actual_bytes]);
            }

            safe_allocator.free(buffer);
        }
    }

    // 停止录音
    pub fn stopRecording(self: *Self) void {
        self.running = false;
    }

    // 读取一个chunk的音频数据
    pub fn read(self: *Self) Str {
        const bytes_per_sample: c_ulong = 2;
        const bytes_to_read = self.chunk * @as(c_ulong, self.channels) * bytes_per_sample;

        var buffer = self.allocator.alloc(u8, bytes_to_read) catch unreachable;

        const frames_read = alsa.snd_pcm_readi(self.capture_handle, buffer.ptr, self.chunk);
        if (frames_read < 0) {
            // 出错时返回空数据
            self.allocator.free(buffer);
            return Str{
                .data = "",
                .allocator = self.allocator,
                .borrowed = true,
            };
        }

        const actual_bytes = @as(usize, @intCast(frames_read)) * @as(c_ulong, self.channels) * bytes_per_sample;

        return Str{
            .data = buffer[0..actual_bytes],
            .allocator = self.allocator,
            .borrowed = false,
        };
    }

    // 检查录音流是否处于活跃状态
    pub fn is_active(self: *Self) bool {
        const state = alsa.snd_pcm_state(self.capture_handle);
        return state == alsa.SND_PCM_STATE_RUNNING;
    }

    // 关闭录音流
    pub fn close(self: *Self) void {
        self.running = false;
        // drop PCM 设备，促使录音线程退出
        _ = alsa.snd_pcm_drop(self.capture_handle);
        // 等待录音线程退出（线程使用 global allocator，即使超时也安全）
        std.time.sleep(200 * std.time.ns_per_ms);
        _ = alsa.snd_pcm_close(self.capture_handle);
        alsa.snd_pcm_hw_params_free(self.params);
        // 释放设备名称缓冲区
        if (self.device_name_buf) |buf| {
            self.allocator.free(buf);
        }
    }
};

// ============================ PlayStream 流式播放 ============================
pub const PlayStream = struct {
    const Self = @This();
    playback_handle: ?*alsa.snd_pcm_t,
    params: ?*alsa.snd_pcm_hw_params_t,
    sample_rate: c_uint,
    channels: c_uint,
    chunk: c_ulong,
    allocator: Allocator,
    running: bool,
    callback: ?*const fn () Str,
    callback_bytes: ?*const fn () []u8, // 新增：bytes 回调（无参返回 []u8）
    device_name_buf: ?[]u8, // 保存设备名称缓冲区的所有权

    // 创建播放流
    // device_name: 设备名称字符串（如 "default", "plughw:0,0"）
    pub fn open(allocator: Allocator, sample_rate: i64, channels: i64, format: i64, device_name_str: Str) !Self {
        var sample_rate_uint = @as(c_uint, @intCast(sample_rate));
        const channels_uint = @as(c_uint, @intCast(channels));
        const format_code = @as(c_int, @intCast(format));

        var playback_handle: ?*alsa.snd_pcm_t = undefined;

        // 将设备名称转换为 C 字符串
        // 注意：device_name_buf 必须保存到 PlayStream 中，在 close() 时释放
        // 因为 ALSA 内部会引用这个字符串
        var device_name: [:0]const u8 = "default";
        var device_name_buf: ?[]u8 = null;
        if (device_name_str.data.len > 0) {
            device_name_buf = std.fmt.allocPrintZ(allocator, "{s}", .{device_name_str.data}) catch null;
            if (device_name_buf) |buf| {
                device_name = buf[0..buf.len :0];
            }
        }

        if (alsa.snd_pcm_open(@as([*c]?*alsa.snd_pcm_t, @ptrCast(&playback_handle)), @ptrCast(device_name.ptr), alsa.SND_PCM_STREAM_PLAYBACK, 0) < 0) {
            if (alsa.snd_pcm_open(@as([*c]?*alsa.snd_pcm_t, @ptrCast(&playback_handle)), "default", alsa.SND_PCM_STREAM_PLAYBACK, 0) < 0) {
                return error.OpenFailed;
            }
        }

        var params: ?*alsa.snd_pcm_hw_params_t = undefined;
        _ = alsa.snd_pcm_hw_params_malloc(@as([*c]?*alsa.snd_pcm_hw_params_t, @ptrCast(&params)));

        if (alsa.snd_pcm_hw_params_any(playback_handle, params) < 0) {
            return error.InvalidParams;
        }

        if (alsa.snd_pcm_hw_params_set_access(playback_handle, params, alsa.SND_PCM_ACCESS_RW_INTERLEAVED) < 0) {
            return error.InvalidAccess;
        }

        const alsa_format = switch (format_code) {
            1 => alsa.SND_PCM_FORMAT_S8,
            2 => alsa.SND_PCM_FORMAT_U8,
            3 => alsa.SND_PCM_FORMAT_S16_LE,
            else => alsa.SND_PCM_FORMAT_S16_LE,
        };

        if (alsa.snd_pcm_hw_params_set_format(playback_handle, params, alsa_format) < 0) {
            return error.InvalidFormat;
        }

        var dir: c_int = 0;
        if (alsa.snd_pcm_hw_params_set_rate_near(playback_handle, params, @ptrCast(&sample_rate_uint), &dir) < 0) {
            return error.InvalidRate;
        }

        if (alsa.snd_pcm_hw_params_set_channels(playback_handle, params, channels_uint) < 0) {
            return error.InvalidChannels;
        }

        if (alsa.snd_pcm_hw_params(playback_handle, params) < 0) {
            return error.SetParamsFailed;
        }

        if (alsa.snd_pcm_prepare(playback_handle) < 0) {
            return error.PrepareFailed;
        }

        return Self{
            .playback_handle = playback_handle,
            .params = params,
            .sample_rate = sample_rate_uint,
            .channels = channels_uint,
            .chunk = 1024,
            .allocator = allocator,
            .running = false,
            .callback = null,
            .callback_bytes = null, // 初始化 bytes 回调为 null
            .device_name_buf = device_name_buf,
        };
    }

    // 设置回调函数
    pub fn setCallback(self: *Self, callback: *const fn () Str) void {
        self.callback = callback;
    }

    // 设置 bytes 回调函数（新增，无参返回 []u8）
    pub fn setBytesCallback(self: *Self, callback: *const fn () []u8) void {
        self.callback_bytes = callback;
    }

    // 带回调的异步播放
    pub fn startPlaying(self: *Self) !void {
        self.running = true;

        // 在新线程中运行播放循环
        const thread = try std.Thread.spawn(.{}, playbackThread, .{self});
        thread.detach();
    }

    // 播放线程函数
    fn playbackThread(self: *Self) void {
        const bytes_per_sample: c_ulong = 2;

        while (self.running) {
            var data: Str = undefined;

            if (self.callback) |cb| {
                data = cb();
            } else if (self.callback_bytes) |cb| {
                // bytes 回调：直接调用获取 []u8
                const bytes_data = cb();
                if (bytes_data.len == 0) {
                    std.time.sleep(10_000_000);
                    continue;
                }
                // 写入音频数据
                const frames_to_write = @min(self.chunk, @as(c_ulong, @intCast(bytes_data.len)) / (@as(c_ulong, self.channels) * bytes_per_sample));
                const frames_written = alsa.snd_pcm_writei(self.playback_handle, bytes_data.ptr, frames_to_write);
                _ = frames_written;
                continue;
            } else {
                // 如果没有回调，等待一小段时间
                std.time.sleep(10_000_000);
                continue;
            }

            if (data.data.len == 0) {
                // 释放空数据（如果 owned）
                if (!data.borrowed and data.data.len > 0) {
                    data.deinit();
                }
                std.time.sleep(10_000_000);
                continue;
            }

            const frames_to_write = @min(self.chunk, @as(c_ulong, @intCast(data.data.len)) / (@as(c_ulong, self.channels) * bytes_per_sample));

            const frames_written = alsa.snd_pcm_writei(self.playback_handle, data.data.ptr, frames_to_write);
            _ = frames_written;

            // 释放回调返回的 Str 数据
            if (!data.borrowed) {
                data.deinit();
            }
        }
    }

    // 停止播放
    pub fn stopPlaying(self: *Self) void {
        self.running = false;
    }

    // 写入音频数据
    pub fn write(self: *Self, data: Str) bool {
        if (data.data.len == 0) {
            return false;
        }

        const bytes_per_sample: c_ulong = 2;
        const frames_to_write = @as(c_ulong, @intCast(data.data.len)) / (@as(c_ulong, self.channels) * bytes_per_sample);

        const frames_written = alsa.snd_pcm_writei(self.playback_handle, data.data.ptr, frames_to_write);
        return frames_written >= 0;
    }

    // 检查播放流是否活跃
    pub fn is_active(self: *Self) bool {
        const state = alsa.snd_pcm_state(self.playback_handle);
        return state == alsa.SND_PCM_STATE_RUNNING;
    }

    // 等待播放完成
    pub fn wait(self: *Self) void {
        while (self.is_active()) {
            std.time.sleep(10_000_000);
        }
    }

    // 关闭播放流
    pub fn close(self: *Self) void {
        self.running = false;
        // drop PCM 设备，促使播放线程退出
        _ = alsa.snd_pcm_drop(self.playback_handle);
        // 等待播放线程退出
        std.time.sleep(200 * std.time.ns_per_ms);
        _ = alsa.snd_pcm_close(self.playback_handle);
        alsa.snd_pcm_hw_params_free(self.params);
        // 释放设备名称缓冲区
        if (self.device_name_buf) |buf| {
            self.allocator.free(buf);
        }
    }
};

// ============================ 音频设备列表函数 ============================

// 使用 POSIX popen 执行命令并读取输出
fn execCommand(cmd: [*c]const u8) []const u8 {
    const fp = cstdio.popen(cmd, "r");
    if (fp == null) return "";

    var result = std.ArrayList(u8).init(std.heap.page_allocator);
    defer result.deinit();

    var buf: [4096]u8 = undefined;
    while (cstdio.fgets(&buf, buf.len, fp)) |line| {
        const len = std.mem.len(line);
        result.appendSlice(line[0..len]) catch break;
    }
    _ = cstdio.pclose(fp);

    return result.toOwnedSlice() catch "";
}

// 获取输入设备（录音）列表 - 返回 list[dict]，每个 dict 包含 "name" 和 "description"
pub fn getInputDeviceList(allocator: Allocator) List(Dict(Str, Str)) {
    var device_list = List(Dict(Str, Str)).init(allocator);

    // 使用 arecord -l 获取录音设备列表
    const output = execCommand("arecord -l");
    defer std.heap.page_allocator.free(output);

    // 如果没有输出或只有错误信息，返回空列表
    if (output.len == 0 or std.mem.indexOf(u8, output, "找不到音效卡") != null) {
        return device_list;
    }

    // 解析 arecord -l 输出
    // 格式: card X: card_name [card_desc], device Y: device_desc [device_desc_extended]
    var lines = std.mem.splitScalar(u8, output, '\n');
    while (lines.next()) |line| {
        // 跳过空行
        if (line.len == 0) continue;
        // 跳过没有 card 和 [ 的行
        if (std.mem.indexOf(u8, line, "card") == null) continue;
        if (std.mem.indexOf(u8, line, "[") == null) continue;

        // 解析 card 号
        const card_start = std.mem.indexOf(u8, line, "card").?;
        const card_str = line[card_start + 5 ..];
        const card_end = std.mem.indexOfAny(u8, card_str, ": ").?;
        const card_num = std.fmt.parseInt(u32, std.mem.trimRight(u8, card_str[0..card_end], " "), 10) catch continue;

        // 查找方括号中的设备名称 (第一个方括号)
        const name_start = std.mem.indexOf(u8, line, "[").?;
        const name_end = std.mem.indexOf(u8, line, "]").?;
        const device_name = line[name_start + 1 .. name_end];

        // 查找 device 号
        const dev_start = std.mem.indexOf(u8, line, "device").?;
        const dev_str = line[dev_start + 7 ..];
        // 只取第一个数字部分（冒号前面的）
        const dev_end = std.mem.indexOfAny(u8, dev_str, ": ") orelse dev_str.len;
        const dev_num = std.fmt.parseInt(u32, std.mem.trimRight(u8, dev_str[0..dev_end], " "), 10) catch continue;

        // 构建设备字符串: "hw:CARD=X,DEV=Y"
        const device_str = std.fmt.allocPrintZ(allocator, "plughw:CARD={d},DEV={d}", .{ card_num, dev_num }) catch continue;

        var dict = Dict(Str, Str).init(allocator);
        const key_name = allocator.dupe(u8, "name") catch continue;
        const key_desc = allocator.dupe(u8, "description") catch continue;

        dict.put(Str{ .data = key_name, .allocator = allocator, .borrowed = false }, Str{ .data = device_str, .allocator = allocator, .borrowed = false }) catch continue;
        dict.put(Str{ .data = key_desc, .allocator = allocator, .borrowed = false }, Str.init(allocator, device_name) catch continue) catch continue;
        device_list.append(dict) catch continue;
    }

    return device_list;
}

// 获取输出设备（播放）列表 - 返回 list[dict]，每个 dict 包含 "name" 和 "description"
pub fn getOutputDeviceList(allocator: Allocator) List(Dict(Str, Str)) {
    var device_list = List(Dict(Str, Str)).init(allocator);

    // 使用 aplay -l 获取播放设备列表
    const output = execCommand("aplay -l");
    defer std.heap.page_allocator.free(output);

    // 如果没有输出或只有错误信息，返回空列表
    if (output.len == 0 or std.mem.indexOf(u8, output, "找不到音效卡") != null) {
        return device_list;
    }

    // 解析 aplay -l 输出
    // 格式: card X: card_name [card_desc], device Y: device_desc [device_desc_extended]
    var lines = std.mem.splitScalar(u8, output, '\n');
    while (lines.next()) |line| {
        // 跳过空行
        if (line.len == 0) continue;
        // 跳过没有 card 和 [ 的行
        if (std.mem.indexOf(u8, line, "card") == null) continue;
        if (std.mem.indexOf(u8, line, "[") == null) continue;

        // 解析 card 号
        const card_start = std.mem.indexOf(u8, line, "card").?;
        const card_str = line[card_start + 5 ..];
        const card_end = std.mem.indexOfAny(u8, card_str, ": ").?;
        const card_num = std.fmt.parseInt(u32, std.mem.trimRight(u8, card_str[0..card_end], " "), 10) catch continue;

        // 查找方括号中的设备名称 (第一个方括号)
        const name_start = std.mem.indexOf(u8, line, "[").?;
        const name_end = std.mem.indexOf(u8, line, "]").?;
        const device_name = line[name_start + 1 .. name_end];

        // 查找 device 号
        const dev_start = std.mem.indexOf(u8, line, "device").?;
        const dev_str = line[dev_start + 7 ..];
        // 只取第一个数字部分（冒号前面的）
        const dev_end = std.mem.indexOfAny(u8, dev_str, ": ") orelse dev_str.len;
        const dev_num = std.fmt.parseInt(u32, std.mem.trimRight(u8, dev_str[0..dev_end], " "), 10) catch continue;

        // 构建设备字符串: "hw:CARD=X,DEV=Y"
        const device_str = std.fmt.allocPrintZ(allocator, "plughw:CARD={d},DEV={d}", .{ card_num, dev_num }) catch continue;

        var dict = Dict(Str, Str).init(allocator);
        const key_name = allocator.dupe(u8, "name") catch continue;
        const key_desc = allocator.dupe(u8, "description") catch continue;

        dict.put(Str{ .data = key_name, .allocator = allocator, .borrowed = false }, Str{ .data = device_str, .allocator = allocator, .borrowed = false }) catch continue;
        dict.put(Str{ .data = key_desc, .allocator = allocator, .borrowed = false }, Str.init(allocator, device_name) catch continue) catch continue;
        device_list.append(dict) catch continue;
    }

    return device_list;
}

// ============================ concat 函数（完全匹配编译器期望！）============================
pub fn concat_i64(allocator: Allocator, a: i64, b: i64) i64 {
    _ = allocator;
    return a + b;
}

pub fn concat_f64(allocator: Allocator, a: f64, b: f64) f64 {
    _ = allocator;
    return a + b;
}

pub fn concat_Str(allocator: Allocator, a: Str, b: Str) Str {
    return a.add(allocator, b) catch unreachable;
}

pub fn concat(allocator: Allocator, a: anytype, b: anytype) !@TypeOf(a, b) {
    const T = @TypeOf(a);
    const U = @TypeOf(b);
    if (T == i64 and U == i64) {
        return a + b;
    } else if (T == f64 and U == f64) {
        return a + b;
    } else {
        const str_a = toStrCompat(allocator, a);
        const str_b = toStrCompat(allocator, b);
        return str_a.add(allocator, str_b);
    }
}

inline fn toStrCompat(allocator: Allocator, value: anytype) Str {
    const T = @TypeOf(value);
    if (T == Str) {
        return value;
    } else if (T == i64) {
        return Str.from(allocator, value) catch unreachable;
    } else if (T == f64) {
        return Str.from(allocator, value) catch unreachable;
    } else if (T == bool) {
        return Str.init(allocator, if (value) "True" else "False") catch unreachable;
    } else if (T == []const u8) {
        return Str.init(allocator, value) catch unreachable;
    } else {
        return Str.init(allocator, "unknown") catch unreachable;
    }
}

// ============================ JsonValue ============================
pub const JsonValue = union(enum) {
    str: Str,
    int: i64,
    float: f64,
    bool: bool,
    list: List(JsonValue),
    dict: Dict(Str, JsonValue),
    null: void,

    pub fn get(self: JsonValue, key: []const u8, default: JsonValue) JsonValue {
        return switch (self) {
            .dict => |d| d.getOrElse(Str{ .data = @constCast(key), .allocator = undefined, .borrowed = true }, default),
            else => default,
        };
    }

    pub fn getFromStr(self: JsonValue, key: Str, default: JsonValue) JsonValue {
        return switch (self) {
            .dict => |d| d.getOrElse(key, default),
            else => default,
        };
    }

    pub fn getIndex(self: JsonValue, idx: usize) ?JsonValue {
        return switch (self) {
            .list => |l| if (idx < l.items.items.len) l.items.items[idx] else null,
            else => null,
        };
    }

    /// 将 JsonValue 转换为 Str（所有类型都可以转为字符串）
    pub fn getStr(self: JsonValue) Str {
        return switch (self) {
            .str => |s| s.clone() catch unreachable,
            .int => |i| blk: {
                const alloc = self.getAllocator();
                break :blk Str{ .data = std.fmt.allocPrint(alloc, "{d}", .{i}) catch unreachable, .allocator = alloc, .borrowed = false };
            },
            .float => |f| blk: {
                const alloc = self.getAllocator();
                break :blk Str{ .data = std.fmt.allocPrint(alloc, "{d}", .{f}) catch unreachable, .allocator = alloc, .borrowed = false };
            },
            .bool => |b| blk: {
                const alloc = self.getAllocator();
                break :blk Str{ .data = if (b) std.fmt.allocPrint(alloc, "true", .{}) catch unreachable else std.fmt.allocPrint(alloc, "false", .{}) catch unreachable, .allocator = alloc, .borrowed = false };
            },
            .null => Str{ .data = @constCast("null"), .allocator = undefined, .borrowed = true },
            .list => blk: {
                const alloc = self.getAllocator();
                break :blk Str{ .data = std.fmt.allocPrint(alloc, "[list]", .{}) catch unreachable, .allocator = alloc, .borrowed = false };
            },
            .dict => blk: {
                const alloc = self.getAllocator();
                break :blk Str{ .data = std.fmt.allocPrint(alloc, "[dict]", .{}) catch unreachable, .allocator = alloc, .borrowed = false };
            },
        };
    }

    /// 获取 JsonValue 内部字段的 allocator（如果有的话）
    fn getAllocator(self: JsonValue) Allocator {
        return switch (self) {
            .str => |s| s.allocator,
            .list => |l| blk: {
                _ = l;
                break :blk std.heap.page_allocator;
            },
            .dict => |d| blk: {
                _ = d;
                break :blk std.heap.page_allocator;
            },
            else => std.heap.page_allocator,
        };
    }

    /// 将 JsonValue 转换为 i64
    pub fn getInt(self: JsonValue) i64 {
        return switch (self) {
            .int => |i| i,
            .float => |f| @intFromFloat(f),
            .bool => |b| if (b) 1 else 0,
            .str => |s| std.fmt.parseInt(i64, s.data, 10) catch 0,
            .null => 0,
            .list => 0,
            .dict => 0,
        };
    }

    /// 将 JsonValue 转换为 f64
    pub fn getFloat(self: JsonValue) f64 {
        return switch (self) {
            .float => |f| f,
            .int => |i| @floatFromInt(i),
            .bool => |b| if (b) 1.0 else 0.0,
            .str => |s| std.fmt.parseFloat(f64, s.data) catch 0.0,
            .null => 0.0,
            .list => 0.0,
            .dict => 0.0,
        };
    }

    /// 将 JsonValue 转换为 bool
    pub fn getBool(self: JsonValue) bool {
        return switch (self) {
            .bool => |b| b,
            .int => |i| i != 0,
            .float => |f| f != 0.0,
            .str => |s| s.data.len > 0 and !(s.data.len == 5 and std.mem.eql(u8, s.data, "false")),
            .null => false,
            .list => true,
            .dict => true,
        };
    }
};

// =====================================================================
// Bytes 类型运行时支持
// =====================================================================
// 真正的 bytes 类型 = []u8 slice
// 智能分配：小数据用静态池（"栈式"），大数据用堆

const SmallBufferSize: usize = 4096;
const NumSmallBuffers: usize = 64;

const SmallBufferPool = struct {
    buffers: [NumSmallBuffers][SmallBufferSize]u8 = [_][SmallBufferSize]u8{[_]u8{0} ** SmallBufferSize} ** NumSmallBuffers,
    used: [NumSmallBuffers]bool = [_]bool{false} ** NumSmallBuffers,
    mutex: std.Thread.Mutex = .{},

    pub fn alloc(self: *@This(), n: usize) ?[]u8 {
        if (n > SmallBufferSize) return null;
        self.mutex.lock();
        defer self.mutex.unlock();
        for (&self.used, 0..) |*u, i| {
            if (!u.*) {
                u.* = true;
                return self.buffers[i][0..n];
            }
        }
        return null;
    }

    pub fn free(self: *@This(), b: []u8) bool {
        if (b.len > SmallBufferSize) return false;
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.buffers[0..], 0..) |*buf, i| {
            if (b.ptr == buf[0..].ptr) {
                self.used[i] = false;
                return true;
            }
        }
        return false;
    }
};

var small_pool: SmallBufferPool = .{};

/// 智能分配 bytes：小数据用静态池，大数据用堆
pub fn bytesAlloc(allocator: Allocator, n: usize) []u8 {
    if (n == 0) {
        return &[_]u8{};
    }
    if (small_pool.alloc(n)) |buf| {
        return buf;
    }
    return allocator.alloc(u8, n) catch unreachable;
}

/// 智能释放 bytes
pub fn bytesFree(allocator: Allocator, b: []u8) void {
    if (b.len == 0) return;
    if (small_pool.free(b)) return;
    allocator.free(b);
}

/// 智能分配（从 byte[N] 数组复制数据）
pub fn bytesFromArray(allocator: Allocator, src: []const u8) []u8 {
    const dst = bytesAlloc(allocator, src.len);
    @memcpy(dst, src);
    return dst;
}

/// 获取 bytes 的数据指针（用于 FFI）
/// 返回的指针需要外部包装为 Pointer（Pointer 在 main.go 中定义）
pub fn bytesPtr(b: []u8) [*]u8 {
    return b.ptr;
}

// ============================================================================
// 类型化指针构造函数（支持所有 C ABI 元素类型）
// 配合 main.go 生成的 Pointer.of / Pointer.typed 使用
// ============================================================================

/// 标量转类型化指针（int 8/16/32/64、u 8/16/32/64、float 32/64）
/// 这些函数在 CatBase 里通过 runtime 命名空间直接调用
/// 注意：函数参数是 const 的（值传递），所以 &v 是 *const T，需要 @constCast
/// 否则 @ptrCast 会在新版 Zig 上报 "discards const qualifier"
pub fn int8Ptr(v: i8) [*]u8 {
    return @ptrCast(@constCast(&v));
}
pub fn uint8Ptr(v: u8) [*]u8 {
    return @ptrCast(@constCast(&v));
}
pub fn int16Ptr(v: i16) [*]u8 {
    return @ptrCast(@constCast(&v));
}
pub fn uint16Ptr(v: u16) [*]u8 {
    return @ptrCast(@constCast(&v));
}
pub fn int32Ptr(v: i32) [*]u8 {
    return @ptrCast(@constCast(&v));
}
pub fn uint32Ptr(v: u32) [*]u8 {
    return @ptrCast(@constCast(&v));
}
pub fn int64Ptr(v: i64) [*]u8 {
    return @ptrCast(@constCast(&v));
}
pub fn uint64Ptr(v: u64) [*]u8 {
    return @ptrCast(@constCast(&v));
}
pub fn float32Ptr(v: f32) [*]u8 {
    return @ptrCast(@constCast(&v));
}
pub fn float64Ptr(v: f64) [*]u8 {
    return @ptrCast(@constCast(&v));
}

/// bytes 转类型化数组指针（reinterpret 转换，零拷贝）
/// 调用方必须保证 bytes.len 能被 elem_size 整除
/// 返回 (裸指针, 元素个数) — main.go 配合 Pointer.typed() 填 elem_count
pub fn bytesAsInt8Ptr(b: []u8) [*]u8 {
    return b.ptr;
}
pub fn bytesAsUint8Ptr(b: []u8) [*]u8 {
    return b.ptr;
}
pub fn bytesAsInt16Ptr(b: []u8) [*]u8 {
    std.debug.assert(b.len % 2 == 0); // i16 = 2 bytes
    return b.ptr;
}
pub fn bytesAsUint16Ptr(b: []u8) [*]u8 {
    std.debug.assert(b.len % 2 == 0);
    return b.ptr;
}
pub fn bytesAsInt32Ptr(b: []u8) [*]u8 {
    std.debug.assert(b.len % 4 == 0);
    return b.ptr;
}
pub fn bytesAsUint32Ptr(b: []u8) [*]u8 {
    std.debug.assert(b.len % 4 == 0);
    return b.ptr;
}
pub fn bytesAsInt64Ptr(b: []u8) [*]u8 {
    std.debug.assert(b.len % 8 == 0);
    return b.ptr;
}
pub fn bytesAsUint64Ptr(b: []u8) [*]u8 {
    std.debug.assert(b.len % 8 == 0);
    return b.ptr;
}
pub fn bytesAsFloat32Ptr(b: []u8) [*]u8 {
    std.debug.assert(b.len % 4 == 0);
    return b.ptr;
}
pub fn bytesAsFloat64Ptr(b: []u8) [*]u8 {
    std.debug.assert(b.len % 8 == 0);
    return b.ptr;
}

/// bytes 元素个数（按指定元素类型）
pub fn bytesCountAs(b: []u8, elem_size: usize) usize {
    std.debug.assert(elem_size > 0 and b.len % elem_size == 0);
    return b.len / elem_size;
}

/// str 转 C 字符串指针（const char*，末尾加 \0）
pub fn strAsCStr(allocator: Allocator, s: []const u8) ![:0]u8 {
    const buf = try allocator.allocSentinel(u8, s.len, 0);
    @memcpy(buf[0..s.len], s);
    return buf;
}

/// str 转 C 字符串指针（const char*，借用原 buffer，不复制，调用方保证生命周期）
/// 返回 [*]u8（与 Pointer.typed 签名匹配），通过 .elem_type = .c_char 表明元素类型
/// 注意：原 Str 的 data 不保证 \0 结尾（dupe 不带 sentinel），所以这里使用
/// Str.allocator 分配一个带 \0 结尾的副本，调用方用完需 free
pub fn strAsCStrBorrowed(s: Str) [*]u8 {
    // 通过 Str.allocator 分配一个带 \0 结尾的副本，避免原 Str 不带 sentinel
    const buf = s.allocator.allocSentinel(u8, s.data.len, 0) catch unreachable;
    @memcpy(buf[0..s.data.len], s.data);
    return buf.ptr;
}

/// 用 str 字面量做 C 字符串（const char*，编译期常量，零运行时分配）
pub fn cstr(comptime s: []const u8) [*c]const u8 {
    return s.ptr;
}

/// bytes 转 str（复制数据，str 独立管理内存）
pub fn bytesToStr(allocator: Allocator, b: []u8) !Str {
    return Str{
        .data = try allocator.dupe(u8, b),
        .allocator = allocator,
        .borrowed = false,
        .is_bytes = true,
    };
}

/// 从 bytes 字面量创建 []u8 切片（运行时复制，可变内存）
/// 用于 b"..." 字面量 - 因为字面量是 const，必须复制才能得到 []u8
pub fn bytesFromLiteral(allocator: Allocator, comptime arr: anytype) []u8 {
    return allocator.dupe(u8, arr) catch unreachable;
}

/// str 转 bytes（复制数据，bytes 独立内存）
pub fn strToBytes(allocator: Allocator, s: Str) []u8 {
    return bytesFromArray(allocator, s.data);
}

// 将 JsonValue 转换为 Str
pub fn strFromJsonValue(allocator: Allocator, jv: JsonValue) !Str {
    return switch (jv) {
        .str => |s| s.clone(),
        .int => |i| Str.init(allocator, std.fmt.allocPrint(allocator, "{d}", .{i}) catch unreachable),
        .float => |f| Str.init(allocator, std.fmt.allocPrint(allocator, "{d}", .{f}) catch unreachable),
        .bool => |b| if (b) Str.init(allocator, std.fmt.allocPrint(allocator, "true", .{}) catch unreachable) else Str.init(allocator, std.fmt.allocPrint(allocator, "false", .{}) catch unreachable),
        .null => Str.init(allocator, std.fmt.allocPrint(allocator, "None", .{}) catch unreachable),
        .list => |*l| jsonStringify(allocator, l),
        .dict => |*d| jsonStringify(allocator, d),
    };
}

// ============================ Str ============================
pub const Str = struct {
    data: []u8,
    allocator: Allocator,
    /// borrowed: true 表示此 Str 的内存由外部（Wrapper）拥有，CatBase 不会释放；
    /// borrowed: false 表示 CatBase 自己分配，在 deinit 时释放。
    /// 这是 owned: bool 的反义命名（borrowed = !owned），但语义更清晰。
    borrowed: bool,
    is_bytes: bool = false,

    pub fn init(allocator: Allocator, bytes: []const u8) !Str {
        const copy = try allocator.dupe(u8, bytes);
        return Str{
            .data = copy,
            .allocator = allocator,
            .borrowed = false,
            .is_bytes = false,
        };
    }

    pub fn initBytes(allocator: Allocator, bytes: []const u8) !Str {
        const copy = try allocator.dupe(u8, bytes);
        return Str{
            .data = copy,
            .allocator = allocator,
            .borrowed = false,
            .is_bytes = true,
        };
    }

    pub fn from(allocator: Allocator, value: anytype) !Str {
        if (@TypeOf(value) == JsonValue) {
            return switch (value) {
                .str => |s| s.clone(),
                .int => |i| Str{ .data = try std.fmt.allocPrint(allocator, "{}", .{i}), .allocator = allocator, .borrowed = false },
                .float => |f| Str{ .data = try std.fmt.allocPrint(allocator, "{}", .{f}), .allocator = allocator, .borrowed = false },
                .bool => |b| Str{ .data = if (b) try allocator.dupe(u8, "true") else try allocator.dupe(u8, "false"), .allocator = allocator, .borrowed = false },
                .null => Str{ .data = try allocator.dupe(u8, "null"), .allocator = allocator, .borrowed = false },
                .list => |l| {
                    var result = std.ArrayList(u8).init(allocator);
                    try result.append('[');
                    for (l.items.items, 0..) |item, idx| {
                        if (idx > 0) try result.append(',');
                        const itemStr = try from(allocator, item);
                        try result.appendSlice(itemStr.data);
                        allocator.free(itemStr.data);
                    }
                    try result.append(']');
                    return Str{ .data = result.items, .allocator = allocator, .borrowed = false };
                },
                .dict => |d| {
                    var result = std.ArrayList(u8).init(allocator);
                    try result.append('{');
                    var first = true;
                    var iter = d.map.iterator();
                    while (iter.next()) |entry| {
                        if (!first) try result.append(',');
                        first = false;
                        try result.appendSlice("\"");
                        try result.appendSlice(entry.key_ptr.data);
                        try result.appendSlice("\":");
                        const valStr = try from(allocator, entry.value_ptr.*);
                        try result.appendSlice(valStr.data);
                        allocator.free(valStr.data);
                    }
                    try result.append('}');
                    return Str{ .data = result.items, .allocator = allocator, .borrowed = false };
                },
            };
        }
        const str = try std.fmt.allocPrint(allocator, "{d}", .{value});
        return Str{
            .data = str,
            .allocator = allocator,
            .borrowed = false,
        };
    }

    pub fn fromOwned(allocator: Allocator, buffer: []u8) Str {
        return Str{
            .data = buffer,
            .allocator = allocator,
            .borrowed = false,
        };
    }

    pub fn repeat(allocator: Allocator, pattern: Str, times: i64) !Str {
        if (times <= 0 or pattern.data.len == 0) {
            return Str{ .data = &[_]u8{}, .allocator = allocator, .borrowed = true };
        }
        const total_len = pattern.data.len * @as(usize, @intCast(times));
        const buffer = try allocator.alloc(u8, total_len);
        for (0..total_len) |i| {
            buffer[i] = pattern.data[i % pattern.data.len];
        }
        return Str{ .data = buffer, .allocator = allocator, .borrowed = false };
    }

    pub fn fromSlice(allocator: Allocator, slice: []const u8) Str {
        return Str{
            .data = @constCast(slice),
            .allocator = allocator,
            .borrowed = true,
        };
    }

    pub fn clone(self: *const Str) !Str {
        var result = try init(self.allocator, self.data);
        result.is_bytes = self.is_bytes;
        return result;
    }

    pub fn cloneWithAllocator(self: *const Str, allocator: Allocator) !Str {
        var result = try init(allocator, self.data);
        result.is_bytes = self.is_bytes;
        return result;
    }

    pub fn deinit(self: *Str) void {
        if (!self.borrowed and self.data.len > 0) {
            self.allocator.free(self.data);
        }
        self.data = &[_]u8{};
        self.borrowed = true;
    }

    pub fn asSlice(self: *const Str) []const u8 {
        return self.data;
    }

    pub fn intoOwned(self: *Str) []u8 {
        const slice = self.data;
        self.data = &[_]u8{};
        self.borrowed = true;
        return slice;
    }

    pub fn add(self: *const Str, allocator: Allocator, other: Str) !Str {
        var buf = try allocator.alloc(u8, self.data.len + other.data.len);
        @memcpy(buf[0..self.data.len], self.data);
        @memcpy(buf[self.data.len..], other.data);
        return Str{ .data = buf, .allocator = allocator, .borrowed = false };
    }

    pub fn len(self: *const Str) usize {
        return self.data.len;
    }

    pub fn get(self: *const Str, idx: usize) u8 {
        return self.data[idx];
    }

    pub fn format(self: *const Str, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll(self.data);
    }

    pub fn upper(self: *const Str, allocator: Allocator) !Str {
        var buf = try allocator.alloc(u8, self.data.len);
        for (self.data, 0..) |c, i| {
            buf[i] = if (c >= 'a' and c <= 'z') c - 32 else c;
        }
        return Str{ .data = buf, .allocator = allocator, .borrowed = false };
    }

    pub fn lower(self: *const Str, allocator: Allocator) !Str {
        var buf = try allocator.alloc(u8, self.data.len);
        for (self.data, 0..) |c, i| {
            buf[i] = if (c >= 'A' and c <= 'Z') c + 32 else c;
        }
        return Str{ .data = buf, .allocator = allocator, .borrowed = false };
    }

    pub fn capitalize(self: *const Str, allocator: Allocator) !Str {
        if (self.data.len == 0) return self.clone();
        var buf = try allocator.alloc(u8, self.data.len);
        for (self.data, 0..) |c, i| {
            buf[i] = if (i == 0 and c >= 'a' and c <= 'z') c - 32 else if (i > 0 and c >= 'A' and c <= 'Z') c + 32 else c;
        }
        return Str{ .data = buf, .allocator = allocator, .borrowed = false };
    }

    pub fn title(self: *const Str, allocator: Allocator) !Str {
        var buf = try allocator.alloc(u8, self.data.len);
        var prev_is_space = true;
        for (self.data, 0..) |c, i| {
            if (prev_is_space and c >= 'a' and c <= 'z') {
                buf[i] = c - 32;
            } else if (!prev_is_space and c >= 'A' and c <= 'Z') {
                buf[i] = c + 32;
            } else {
                buf[i] = c;
            }
            prev_is_space = c == ' ' or c == '\t' or c == '\n';
        }
        return Str{ .data = buf, .allocator = allocator, .borrowed = false };
    }

    pub fn strip(self: *const Str, allocator: Allocator) !Str {
        return self.trim(allocator, Str.init(allocator, " \t\n\r") catch unreachable);
    }

    pub fn lstrip(self: *const Str, allocator: Allocator) !Str {
        var i: usize = 0;
        while (i < self.data.len and isWhitespace(self.data[i])) : (i += 1) {}
        return self.sliceFrom(allocator, i);
    }

    pub fn rstrip(self: *const Str, allocator: Allocator) !Str {
        var i: usize = self.data.len;
        while (i > 0 and isWhitespace(self.data[i - 1])) : (i -= 1) {}
        return self.sliceTo(allocator, i);
    }

    pub fn trim(self: *const Str, allocator: Allocator, chars: Str) !Str {
        var start: usize = 0;
        while (start < self.data.len and mem.indexOf(u8, chars.data, &[_]u8{self.data[start]}) != null) : (start += 1) {}
        var end = self.data.len;
        while (end > start and mem.indexOf(u8, chars.data, &[_]u8{self.data[end - 1]}) != null) : (end -= 1) {}
        return self.subSlice(allocator, start, end);
    }

    pub fn find(self: *const Str, sub: Str) ?usize {
        return mem.indexOf(u8, self.data, sub.data);
    }

    pub fn rfind(self: *const Str, sub: Str) ?usize {
        return mem.lastIndexOf(u8, self.data, sub.data);
    }

    pub fn index(self: *const Str, sub: Str) !usize {
        return self.find(sub) orelse error.NotFound;
    }

    pub fn rindex(self: *const Str, sub: Str) !usize {
        return self.rfind(sub) orelse error.NotFound;
    }

    pub fn count(self: *const Str, sub: Str) usize {
        return mem.count(u8, self.data, sub.data);
    }

    pub fn startswith(self: *const Str, prefix: Str) bool {
        return mem.startsWith(u8, self.data, prefix.data);
    }

    pub fn endswith(self: *const Str, suffix: Str) bool {
        return mem.endsWith(u8, self.data, suffix.data);
    }

    pub fn split(self: *const Str, allocator: Allocator, sep: Str) !List(Str) {
        var list = List(Str).init(allocator);
        errdefer list.deinit();
        var it = mem.splitSequence(u8, self.data, sep.data);
        while (it.next()) |part| {
            const item = try init(allocator, part);
            try list.append(item);
        }
        return list;
    }

    pub fn splitWhitespace(self: *const Str, allocator: Allocator) !List(Str) {
        var list = List(Str).init(allocator);
        errdefer list.deinit();
        var it = mem.splitAny(u8, self.data, " \t\n\r");
        while (it.next()) |part| {
            if (part.len == 0) continue;
            const item = try init(allocator, part);
            try list.append(item);
        }
        return list;
    }

    pub fn splitlines(self: *const Str, allocator: Allocator) !List(Str) {
        var list = List(Str).init(allocator);
        errdefer list.deinit();
        var it = mem.splitSequence(u8, self.data, "\n");
        while (it.next()) |part| {
            const item = try init(allocator, part);
            try list.append(item);
        }
        return list;
    }

    pub fn rsplit(self: *const Str, allocator: Allocator, sep: Str, maxsplit: i64) !List(Str) {
        var list = List(Str).init(allocator);
        errdefer list.deinit();

        if (maxsplit <= 0) {
            return self.split(allocator, sep);
        }

        var parts = std.ArrayList([]const u8).init(allocator);
        defer parts.deinit();

        var it = mem.splitSequence(u8, self.data, sep.data);
        while (it.next()) |part| {
            try parts.append(part);
        }

        const split_count = @min(@as(usize, @intCast(maxsplit)) + 1, parts.items.len);
        const last_part_start = parts.items.len - split_count + 1;

        for (parts.items[0..last_part_start]) |part| {
            const item = try init(allocator, part);
            try list.append(item);
        }

        if (last_part_start < parts.items.len) {
            var joined = std.ArrayList(u8).init(allocator);
            defer joined.deinit();
            for (parts.items[last_part_start..], 0..) |part, i| {
                if (i > 0) try joined.appendSlice(sep.data);
                try joined.appendSlice(part);
            }
            const item = try init(allocator, joined.items);
            try list.append(item);
        }

        return list;
    }

    pub fn join(self: *const Str, allocator: Allocator, items: List(Str)) !Str {
        if (items.items.len == 0) return init(allocator, "");
        var total_len: usize = 0;
        for (items.items) |item| {
            total_len += item.data.len;
        }
        total_len += self.data.len * (items.items.len - 1);
        var buf = try allocator.alloc(u8, total_len);
        var pos: usize = 0;
        for (items.items, 0..) |item, idx| {
            if (idx > 0) {
                @memcpy(buf[pos..][0..self.data.len], self.data);
                pos += self.data.len;
            }
            @memcpy(buf[pos..][0..item.data.len], item.data);
            pos += item.data.len;
        }
        return Str{ .data = buf, .allocator = allocator, .borrowed = false };
    }

    pub fn replace(self: *const Str, allocator: Allocator, old: Str, new: Str) !Str {
        if (old.data.len == 0) return self.clone();
        var buf = std.ArrayList(u8).init(allocator);
        defer buf.deinit();
        var i: usize = 0;
        while (i < self.data.len) {
            if (i + old.data.len <= self.data.len and mem.eql(u8, self.data[i..][0..old.data.len], old.data)) {
                try buf.appendSlice(new.data);
                i += old.data.len;
            } else {
                try buf.append(self.data[i]);
                i += 1;
            }
        }
        const slice = try buf.toOwnedSlice();
        return Str{ .data = slice, .allocator = allocator, .borrowed = false };
    }

    pub fn isdigit(self: *const Str) bool {
        if (self.data.len == 0) return false;
        for (self.data) |c| {
            if (c < '0' or c > '9') return false;
        }
        return true;
    }

    pub fn isalpha(self: *const Str) bool {
        if (self.data.len == 0) return false;
        for (self.data) |c| {
            if (!((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z'))) return false;
        }
        return true;
    }

    pub fn isalnum(self: *const Str) bool {
        if (self.data.len == 0) return false;
        for (self.data) |c| {
            const is_alpha = (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z');
            const is_digit = (c >= '0' and c <= '9');
            if (!is_alpha and !is_digit) return false;
        }
        return true;
    }

    pub fn isspace(self: *const Str) bool {
        if (self.data.len == 0) return false;
        for (self.data) |c| {
            if (!isWhitespace(c)) return false;
        }
        return true;
    }

    pub fn islower(self: *const Str) bool {
        var has_letter = false;
        for (self.data) |c| {
            if (c >= 'A' and c <= 'Z') return false;
            if (c >= 'a' and c <= 'z') has_letter = true;
        }
        return has_letter;
    }

    pub fn isupper(self: *const Str) bool {
        var has_letter = false;
        for (self.data) |c| {
            if (c >= 'a' and c <= 'z') return false;
            if (c >= 'A' and c <= 'Z') has_letter = true;
        }
        return has_letter;
    }

    pub fn istitle(self: *const Str) bool {
        if (self.data.len == 0) return false;
        var prev_is_space = true;
        for (self.data) |c| {
            const is_upper = (c >= 'A' and c <= 'Z');
            const is_lower = (c >= 'a' and c <= 'z');
            if (prev_is_space) {
                if (!is_upper and is_lower) return false;
            } else {
                if (is_upper) return false;
            }
            prev_is_space = c == ' ' or c == '\t' or c == '\n';
        }
        return true;
    }

    pub fn subSlice(self: *const Str, allocator: Allocator, start: usize, end: usize) !Str {
        if (start >= end) return init(allocator, "");
        const slice = try allocator.dupe(u8, self.data[start..end]);
        return Str{ .data = slice, .allocator = allocator, .borrowed = false };
    }

    pub fn sliceFrom(self: *const Str, allocator: Allocator, start: usize) !Str {
        return self.subSlice(allocator, start, self.data.len);
    }

    pub fn sliceTo(self: *const Str, allocator: Allocator, end: usize) !Str {
        return self.subSlice(allocator, 0, end);
    }

    pub fn formatStr(self: *const Str, allocator: Allocator, args: anytype) !Str {
        const result = try std.fmt.allocPrint(allocator, self.data, args);
        return Str{ .data = result, .allocator = allocator, .borrowed = false };
    }

    pub fn isnumeric(self: *const Str) bool {
        if (self.data.len == 0) return false;
        for (self.data) |c| {
            if (c < '0' or c > '9') return false;
        }
        return true;
    }
};

// ============================ HTTP Response ============================
pub const Response = struct {
    status_code: u16,
    body: Str,
    allocator: Allocator,
    stream: ?std.net.Stream = null,
    buffer: []u8 = &[_]u8{},
    buffer_pos: usize = 0,

    pub fn init(allocator: Allocator, status_code: u16, body: Str) Response {
        return Response{
            .status_code = status_code,
            .body = body,
            .allocator = allocator,
            .stream = null,
        };
    }

    pub fn initStream(allocator: Allocator, status_code: u16, stream: std.net.Stream) Response {
        return Response{
            .status_code = status_code,
            .body = Str{ .data = &[_]u8{}, .allocator = allocator, .borrowed = true },
            .allocator = allocator,
            .stream = stream,
        };
    }

    pub fn deinit(self: *Response) void {
        self.body.deinit();
        if (self.stream) |s| {
            s.close();
        }
        if (self.buffer.len > 0) {
            self.allocator.free(self.buffer);
        }
    }

    pub fn raiseForStatus(self: *Response) void {
        if (self.status_code < 200 or self.status_code >= 300) {
            const error_msg = std.fmt.allocPrint(self.allocator, "HTTP Error: {d} - {s}", .{
                self.status_code,
                self.body.data,
            }) catch unreachable;
            @panic(error_msg);
        }
    }

    pub fn iterLines(self: *Response) ?Str {
        if (self.stream == null) {
            return null;
        }
        const stream = self.stream.?;
        while (true) {
            if (self.buffer_pos >= self.buffer.len) {
                // 使用 poll 检测数据是否可读（超时 60 秒）
                var pollfd = [_]std.os.linux.pollfd{
                    std.os.linux.pollfd{
                        .fd = stream.handle,
                        .events = std.os.linux.POLL.IN | std.os.linux.POLL.ERR | std.os.linux.POLL.NVAL,
                        .revents = 0,
                    },
                };
                const poll_result = std.os.linux.poll(&pollfd, 1, 60000);
                if (poll_result == 0 or poll_result == std.math.maxInt(usize)) {
                    // 超时，返回 null 表示流结束
                    return null;
                }
                if (pollfd[0].revents & (std.os.linux.POLL.ERR | std.os.linux.POLL.NVAL) != 0) {
                    // 错误，返回 null
                    return null;
                }

                var new_buf = self.allocator.alloc(u8, 8192) catch unreachable;
                const bytes_read = stream.read(new_buf) catch blk: {
                    self.allocator.free(new_buf);
                    break :blk 0;
                };
                if (bytes_read == 0) {
                    self.allocator.free(new_buf);
                    if (self.buffer_pos < self.buffer.len) {
                        const remaining = self.buffer[self.buffer_pos..];
                        if (remaining.len > 0) {
                            const line = Str.init(self.allocator, remaining) catch unreachable;
                            self.buffer_pos = self.buffer.len;
                            return line;
                        }
                    }
                    return null;
                }
                if (self.buffer.len > 0) {
                    self.allocator.free(self.buffer);
                }
                self.buffer = new_buf[0..bytes_read];
                self.buffer_pos = 0;
            }
            var end_pos = self.buffer_pos;
            while (end_pos < self.buffer.len) {
                if (self.buffer[end_pos] == '\n') {
                    break;
                }
                end_pos += 1;
            }
            if (end_pos < self.buffer.len) {
                var line_data = self.buffer[self.buffer_pos..end_pos];
                if (line_data.len > 0 and line_data[line_data.len - 1] == '\r') {
                    line_data.len -= 1;
                }
                const line = Str.init(self.allocator, line_data) catch unreachable;
                self.buffer_pos = end_pos + 1;
                return line;
            }
        }
    }
};

fn isWhitespace(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\n' or c == '\r';
}

// ============================ List ============================
pub fn List(comptime T: type) type {
    return struct {
        const Self = @This();
        items: std.ArrayList(T),
        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return Self{
                .items = std.ArrayList(T).init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            if (comptime std.meta.hasFn(T, "deinit")) {
                for (self.items.items) |*item| {
                    item.deinit();
                }
            }
            self.items.deinit();
        }

        pub fn append(self: *Self, value: T) !void {
            try self.items.append(value);
        }

        pub fn len(self: *const Self) usize {
            return self.items.items.len;
        }

        pub fn get(self: *Self, idx: usize) T {
            return self.items.items[idx];
        }

        pub fn set(self: *Self, idx: usize, value: T) void {
            self.items.items[idx] = value;
        }

        /// 按索引删除元素（O(n) 操作，因为 std.ArrayList.orderedRemove 移动后续元素）
        /// 如果 idx 越界则不做任何操作
        pub fn remove(self: *Self, idx: usize) void {
            if (idx >= self.items.items.len) {
                return;
            }
            _ = self.items.orderedRemove(idx);
        }

        /// 清空所有元素（保留容量）
        pub fn clear(self: *Self) void {
            self.items.clearRetainingCapacity();
        }

        pub fn clone(self: *Self) !Self {
            var new = Self.init(self.allocator);
            errdefer new.deinit();
            for (self.items.items) |item| {
                try new.append(item);
            }
            return new;
        }

        pub fn format(self: *const Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            try writer.writeByte('[');
            for (self.items.items, 0..) |item, i| {
                if (i > 0) {
                    try writer.writeAll(", ");
                }
                if (comptime T == Str) {
                    try writer.writeByte('\'');
                    try writer.writeAll(item.data);
                    try writer.writeByte('\'');
                } else if (comptime T == bool) {
                    if (item) {
                        try writer.writeAll("True");
                    } else {
                        try writer.writeAll("False");
                    }
                } else {
                    try std.fmt.format(writer, "{any}", .{item});
                }
            }
            try writer.writeByte(']');
        }
    };
}

// 使用线程和超时机制建立TCP连接
fn connectWithTimeout(host: []const u8, port: u16, timeout_secs: u32, allocator: Allocator) !std.net.Stream {
    // 在堆上分配连接上下文，避免栈内存问题
    const ctx = try std.heap.page_allocator.create(ConnectionContext);

    // 复制 host 字符串到堆上
    const host_copy = try std.heap.page_allocator.alloc(u8, host.len);
    @memcpy(host_copy, host);

    ctx.* = ConnectionContext{
        .host = host_copy,
        .port = port,
        .allocator = allocator,
        .stream = null,
        .err = null,
        .completed = false,
    };

    const thread = try std.Thread.spawn(.{}, connectionThread, .{ctx});

    // 等待连接完成或超时
    const timeout_ns = timeout_secs * std.time.ns_per_s;
    const start_time = std.time.nanoTimestamp();

    var timed_out = false;
    while (!ctx.completed) {
        const elapsed = @as(u64, @intCast(std.time.nanoTimestamp() - start_time));
        if (elapsed >= timeout_ns) {
            // 超时，分离线程
            timed_out = true;
            thread.detach();
            break;
        }
        // 短暂休眠后继续检查
        std.Thread.yield() catch {};
    }

    if (timed_out) {
        // 超时情况：ctx 由 detached 线程在连接失败后清理
        // 我们不清理内存，因为线程可能仍在访问它们
        // 注意：这里不能使用errdefer，因为errdefer会在返回时执行
        // 而返回error.Timeout时，errdefer会尝试释放仍在被线程使用的内存
        return error.Timeout;
    }

    thread.join();

    // 清理堆分配
    std.heap.page_allocator.free(host_copy);
    std.heap.page_allocator.destroy(ctx);

    if (ctx.err) |err| {
        return err;
    }

    return ctx.stream.?;
}

const ConnectionContext = struct {
    host: []u8,
    port: u16,
    allocator: Allocator,
    stream: ?std.net.Stream,
    err: ?anyerror,
    completed: bool,
};

fn connectionThread(ctx: *ConnectionContext) void {
    const stream = std.net.tcpConnectToHost(ctx.allocator, ctx.host, ctx.port) catch |err| {
        ctx.err = err;
        ctx.completed = true;
        return;
    };
    ctx.stream = stream;
    ctx.completed = true;
}

pub fn httpPost(allocator: Allocator, url: Str, headers: Str, json_data: anytype, body: Str, timeout_secs: u32, stream_mode: bool) !Response {
    const parsed = parseUrl(url.data);

    // 建连：https 时由 httpConnect 完成 TLS 握手
    var conn = try httpConnect(allocator, url, timeout_secs);
    defer conn.close();

    var request_body = std.ArrayList(u8).init(allocator);
    defer request_body.deinit();

    var content_type: []const u8 = "application/json";

    const T = @TypeOf(json_data);
    const hasMap = @hasField(T, "map");
    const hasItems = @hasField(T, "items");
    var hasJsonData = false;

    if (hasMap) {
        if (json_data.map.count() > 0) {
            hasJsonData = true;
            const json_str = jsonStringify(allocator, &json_data);
            request_body.appendSlice(json_str.asSlice()) catch unreachable;
        }
    } else if (hasItems) {
        if (json_data.items.len > 0) {
            hasJsonData = true;
            const json_str = jsonStringify(allocator, &json_data);
            request_body.appendSlice(json_str.asSlice()) catch unreachable;
        }
    }

    if (!hasJsonData and body.data.len > 0) {
        request_body.appendSlice(body.data) catch unreachable;
        content_type = "application/x-www-form-urlencoded";
    }

    const content_length = std.fmt.allocPrint(allocator, "{d}", .{request_body.items.len}) catch unreachable;
    defer allocator.free(content_length);

    var request_headers = std.ArrayList(u8).init(allocator);
    defer request_headers.deinit();

    const ct = std.fmt.allocPrint(allocator, "Content-Type: {s}\r\n", .{content_type}) catch unreachable;
    defer allocator.free(ct);
    request_headers.appendSlice(ct) catch unreachable;

    if (headers.data.len > 0) {
        var header_parts = std.mem.splitAny(u8, headers.data, "&");
        while (header_parts.next()) |header| {
            request_headers.appendSlice(header) catch unreachable;
            request_headers.appendSlice("\r\n") catch unreachable;
        }
    }

    const conn_header = if (stream_mode) "Transfer-Encoding: chunked\r\n" else "Connection: close\r\n";

    var request: []u8 = undefined;
    if (stream_mode) {
        // 流式模式：使用 chunked 传输编码
        const chunk_size = std.fmt.allocPrint(allocator, "{x}\r\n", .{request_body.items.len}) catch unreachable;
        defer allocator.free(chunk_size);
        const host_port = std.fmt.allocPrint(allocator, "{s}:{d}", .{ parsed.host, parsed.port }) catch unreachable;
        defer allocator.free(host_port);
        request = std.fmt.allocPrint(allocator, "POST {s} HTTP/1.1\r\nHost: {s}\r\n{s}Transfer-Encoding: chunked\r\n\r\n{s}{s}\r\n0\r\n\r\n", .{
            parsed.path,
            host_port,
            request_headers.items,
            chunk_size,
            request_body.items,
        }) catch unreachable;
    } else {
        const host_port = std.fmt.allocPrint(allocator, "{s}:{d}", .{ parsed.host, parsed.port }) catch unreachable;
        defer allocator.free(host_port);
        request = std.fmt.allocPrint(allocator, "POST {s} HTTP/1.1\r\nHost: {s}\r\n{s}Content-Length: {s}\r\n{s}\r\n{s}", .{
            parsed.path,
            host_port,
            request_headers.items,
            content_length,
            conn_header,
            request_body.items,
        }) catch unreachable;
    }
    defer allocator.free(request);

    // 发送请求：明文走 posix.send，https 走 TLS writeAll
    try conn.sendAll(request);

    if (stream_mode) {
        // stream_mode 依赖裸 Stream 逐行读取并交给 Response 迭代；
        // TLS 连接不支持该模式，显式报错而不是退化成明文。
        if (conn.tls != null) return error.TlsStreamModeUnsupported;
        const fd = conn.sockfd;
        conn.sockfd = -1; // Stream 接管所有权，由 Response 迭代时关闭
        const stream = std.net.Stream{ .handle = fd };
        const response_line = readLine(stream, allocator);
        const status_code = parseStatusCode(response_line);
        return Response.initStream(allocator, status_code, stream);
    }

    var buffer: [65536]u8 = undefined;
    var total_read: usize = 0;
    var resp_content_length: ?usize = null;
    var headers_parsed = false;
    var resp_is_chunked = false;
    var body_start: usize = 0;

    while (total_read < buffer.len) {
        const n = conn.read(buffer[total_read..]) catch |err| {
            if (err == error.Timeout and total_read > 0) break;
            return err;
        };
        if (n == 0) break;
        total_read += n;

        if (!headers_parsed) {
            if (std.mem.indexOf(u8, buffer[0..total_read], "\r\n\r\n")) |hdr_end| {
                headers_parsed = true;
                body_start = hdr_end + 4;
                const headers_block = buffer[0..hdr_end];
                if (std.mem.indexOf(u8, headers_block, "Content-Length:")) |cl_idx| {
                    const rest = headers_block[cl_idx + 15 ..];
                    const cl_end = std.mem.indexOfAny(u8, rest, "\r\n") orelse rest.len;
                    resp_content_length = std.fmt.parseInt(usize, std.mem.trim(u8, rest[0..cl_end], " \t"), 10) catch null;
                }
                resp_is_chunked = headerHasChunked(headers_block);
                if (resp_content_length) |cl| {
                    if (total_read >= body_start + cl) break;
                }
            }
        } else if (resp_content_length) |cl| {
            if (total_read >= body_start + cl) break;
        }
        if (headers_parsed and resp_is_chunked and total_read > body_start) {
            if (std.mem.indexOf(u8, buffer[body_start - 2 .. total_read], "\r\n0\r\n\r\n") != null) break;
        }
    }

    if (total_read == 0) return error.ConnectionFailed;

    const owned = try allocator.dupe(u8, buffer[0..total_read]);
    const response_body = extractBodyOwned(allocator, owned);
    return Response.init(allocator, response_body.status_code, response_body.body);
}

fn readLine(stream: std.net.Stream, allocator: Allocator) []u8 {
    var line_buf = std.ArrayList(u8).init(allocator);
    var buf: [1]u8 = undefined;
    while (true) {
        // 使用 poll 检测数据是否可读（超时 60 秒）
        var pollfd = [_]std.os.linux.pollfd{
            std.os.linux.pollfd{
                .fd = stream.handle,
                .events = std.os.linux.POLL.IN | std.os.linux.POLL.ERR | std.os.linux.POLL.NVAL,
                .revents = 0,
            },
        };
        const poll_result = std.os.linux.poll(&pollfd, 1, 60000);
        if (poll_result == 0 or poll_result == std.math.maxInt(usize) or (pollfd[0].revents & (std.os.linux.POLL.ERR | std.os.linux.POLL.NVAL) != 0)) {
            // 超时或错误，返回已读取的内容
            return line_buf.toOwnedSlice() catch &[_]u8{};
        }

        if (stream.read(&buf)) |bytes_read| {
            if (bytes_read == 0) break;
        } else |_| {
            return line_buf.toOwnedSlice() catch &[_]u8{};
        }
        if (buf[0] == '\n') break;
        if (buf[0] != '\r') {
            line_buf.append(buf[0]) catch unreachable;
        }
    }
    return line_buf.toOwnedSlice() catch unreachable;
}

fn parseStatusCode(line: []u8) u16 {
    var i: usize = 0;
    while (i < line.len and line[i] != ' ') : (i += 1) {}
    i += 1;
    var j = i;
    while (j < line.len and line[j] >= '0' and line[j] <= '9') : (j += 1) {}
    const status_str = line[i..j];
    return std.fmt.parseInt(u16, status_str, 10) catch 500;
}

fn extractBody(response: []u8) struct { status_code: u16, body: Str } {
    const idx = std.mem.indexOf(u8, response, "\r\n\r\n") orelse response.len;
    const header_part = response[0..idx];
    const body_start = idx + 4;

    const status_line_end = std.mem.indexOf(u8, header_part, "\r\n") orelse header_part.len;
    const status_line = header_part[0..status_line_end];

    const status_code = parseStatusCode(status_line);

    const body_content = response[body_start..];

    return .{
        .status_code = status_code,
        .body = Str{ .data = body_content, .allocator = undefined, .borrowed = true },
    };
}

// extractBodyOwned —— 与 extractBody 相同，但 body 是响应 buffer 的副本，
// 由 Str 自己持有（调用方可以把原始 buffer 释放）。
fn extractBodyOwned(allocator: Allocator, response: []u8) struct { status_code: u16, body: Str } {
    const idx = std.mem.indexOf(u8, response, "\r\n\r\n") orelse response.len;
    const header_part = response[0..idx];
    const body_start = idx + 4;

    const status_line_end = std.mem.indexOf(u8, header_part, "\r\n") orelse header_part.len;
    const status_code = parseStatusCode(header_part[0..status_line_end]);

    const body_content = if (body_start <= response.len) response[body_start..] else &[_]u8{};
    const body_owned: []u8 = allocator.dupe(u8, body_content) catch unreachable;

    return .{
        .status_code = status_code,
        .body = Str{ .data = body_owned, .allocator = allocator, .borrowed = false },
    };
}

pub fn httpPostAdvanced(allocator: Allocator, url: Str, body: Str, headers: Str, timeout_secs: u32) Str {
    _ = timeout_secs;

    const parsed = parseUrl(url.data);

    const stream = std.net.tcpConnectToHost(allocator, parsed.host, parsed.port) catch unreachable;
    defer stream.close();

    const content_length = std.fmt.allocPrint(allocator, "{d}", .{body.data.len}) catch unreachable;
    defer allocator.free(content_length);

    var request_headers = std.ArrayList(u8).init(allocator);
    defer request_headers.deinit();

    request_headers.appendSlice("Content-Type: application/json\r\n") catch unreachable;

    if (headers.data.len > 0) {
        var header_parts = std.mem.splitAny(u8, headers.data, "&");
        while (header_parts.next()) |header| {
            request_headers.appendSlice(header) catch unreachable;
            request_headers.appendSlice("\r\n") catch unreachable;
        }
    }

    const request = std.fmt.allocPrint(allocator, "POST {s} HTTP/1.1\r\nHost: {s}\r\n{s}Content-Length: {s}\r\nConnection: close\r\n\r\n{s}", .{
        parsed.path,
        parsed.host,
        request_headers.items,
        content_length,
        body.data,
    }) catch unreachable;
    defer allocator.free(request);

    stream.writeAll(request) catch {
        stream.close();
        return error.Timeout;
    };

    var buffer: [65536]u8 = undefined;
    var total_read: usize = 0;
    var chunk_buf: [8192]u8 = undefined;

    while (true) {
        const bytes_read = stream.read(&chunk_buf) catch unreachable;
        if (bytes_read == 0) break;

        if (total_read + bytes_read > buffer.len) break;
        @memcpy(buffer[total_read .. total_read + bytes_read], chunk_buf[0..bytes_read]);
        total_read += bytes_read;

        if (total_read >= 4 and std.mem.eql(u8, buffer[total_read - 4 .. total_read], "\r\n\r\n")) {
            break;
        }
    }

    return Str{
        .data = buffer[0..total_read],
        .allocator = allocator,
        .borrowed = true,
    };
}

// Str 的 hash 函数
fn strHash(str: Str) u64 {
    return std.hash.XxHash64.hash(0, str.data);
}

// typeName 函数 - 获取值的类型名称
pub fn typeName(value: anytype) Str {
    const T = @TypeOf(value);
    if (T == Str) {
        if (value.is_bytes) {
            return Str.init(std.heap.page_allocator, "bytes") catch unreachable;
        }
        return Str.init(std.heap.page_allocator, "str") catch unreachable;
    } else if (T == i64) {
        return Str.init(std.heap.page_allocator, "int") catch unreachable;
    } else if (T == f64) {
        return Str.init(std.heap.page_allocator, "float") catch unreachable;
    } else if (T == bool) {
        return Str.init(std.heap.page_allocator, "bool") catch unreachable;
    } else if (T == u8) {
        // byte 类型：8 位无符号整数（0-255）
        return Str.init(std.heap.page_allocator, "byte") catch unreachable;
    } else if (T == []u8) {
        // bytes 类型：原始字节切片（[]u8）
        return Str.init(std.heap.page_allocator, "bytes") catch unreachable;
    } else if (T == std.Thread) {
        return Str.init(std.heap.page_allocator, "Thread") catch unreachable;
    } else if (T == JsonValue) {
        return switch (value) {
            .str => Str.init(std.heap.page_allocator, "any:str") catch unreachable,
            .int => Str.init(std.heap.page_allocator, "any:int") catch unreachable,
            .float => Str.init(std.heap.page_allocator, "any:float") catch unreachable,
            .bool => Str.init(std.heap.page_allocator, "any:bool") catch unreachable,
            .null => Str.init(std.heap.page_allocator, "any:None") catch unreachable,
            .list => Str.init(std.heap.page_allocator, "any:list") catch unreachable,
            .dict => Str.init(std.heap.page_allocator, "any:dict") catch unreachable,
        };
    } else {
        const type_name = @typeName(T);
        if (std.mem.startsWith(u8, type_name, "std.Thread")) {
            return Str.init(std.heap.page_allocator, "Thread") catch unreachable;
        }
        if (std.mem.startsWith(u8, type_name, "runtime.runtime.Dict")) {
            return Str.init(std.heap.page_allocator, "dict") catch unreachable;
        }
        if (std.mem.startsWith(u8, type_name, "runtime.runtime.List")) {
            return Str.init(std.heap.page_allocator, "list") catch unreachable;
        }
        return Str.init(std.heap.page_allocator, "unknown") catch unreachable;
    }
}

// toBool 函数 - 将任意类型转换为布尔值
pub fn toBool(value: anytype) bool {
    const T = @TypeOf(value);
    if (T == bool) {
        return value;
    } else if (T == i64 or T == comptime_int) {
        return value != 0;
    } else if (T == f64 or T == comptime_float) {
        return value != 0.0;
    } else if (T == Str) {
        return value.len() > 0;
    } else {
        return false;
    }
}

// sum 函数 - 计算列表元素的总和
pub fn sum(list: anytype) i64 {
    const T = @TypeOf(list);
    if (T == List(i64)) {
        var total: i64 = 0;
        for (list.items.items) |item| {
            total += item;
        }
        return total;
    } else {
        return 0;
    }
}

// exec 函数 - 执行系统命令
pub fn exec(allocator: Allocator, cmd: Str) Str {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "/bin/sh", "-c", cmd.data },
    }) catch |err| {
        return Str.init(allocator, @errorName(err)) catch unreachable;
    };
    defer result.deinit();
    return Str.init(allocator, result.stdout) catch unreachable;
}

// Str 的 eql 函数
pub fn strEql(a: Str, b: Str) bool {
    return std.mem.eql(u8, a.data, b.data);
}

// Str 的 hash context
const StrContext = struct {
    pub fn hash(_: @This(), key: Str) u64 {
        return strHash(key);
    }
    pub fn eql(_: @This(), a: Str, b: Str) bool {
        return strEql(a, b);
    }
};

// ============================ Dict ============================
pub fn Dict(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();
        const Map = if (K == []const u8 or K == []u8)
            std.StringHashMap(V)
        else if (K == Str)
            std.HashMap(Str, V, StrContext, 80)
        else
            std.HashMap(K, V, std.hash_map.AutoContext(K), 80);

        map: Map,
        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return Self{
                .map = Map.init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            if (comptime std.meta.hasFn(V, "deinit")) {
                var it = self.map.iterator();
                while (it.next()) |entry| {
                    entry.value_ptr.*.deinit();
                }
            }
            self.map.deinit();
        }

        pub fn put(self: *Self, key: K, value: V) !void {
            try self.map.put(key, value);
        }

        pub fn get(self: *const Self, key: K) ?V {
            return self.map.get(key);
        }

        pub fn getOrElse(self: *const Self, key: K, default: V) V {
            if (self.map.get(key)) |val| {
                return val;
            }
            return default;
        }

        pub fn contains(self: *const Self, key: K) bool {
            return self.map.contains(key);
        }

        pub fn remove(self: *Self, key: K) void {
            _ = self.map.remove(key);
        }

        pub fn len(self: *const Self) usize {
            return self.map.count();
        }

        pub fn keys(self: *Self) List(K) {
            var list = List(K).init(self.allocator);
            var it = self.map.iterator();
            while (it.next()) |entry| {
                list.append(entry.key_ptr.*) catch {};
            }
            return list;
        }

        pub fn values(self: *Self) List(V) {
            var list = List(V).init(self.allocator);
            var it = self.map.iterator();
            while (it.next()) |entry| {
                list.append(entry.value_ptr.*) catch {};
            }
            return list;
        }

        pub fn format(self: *const Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            try writer.writeByte('{');
            var it = self.map.iterator();
            var first = true;
            while (it.next()) |entry| {
                if (!first) {
                    try writer.writeAll(", ");
                }
                first = false;
                if (comptime K == Str) {
                    try writer.writeByte('\'');
                    try writer.writeAll(entry.key_ptr.*.data);
                    try writer.writeByte('\'');
                } else {
                    try std.fmt.format(writer, "{any}", .{entry.key_ptr.*});
                }
                try writer.writeAll(": ");
                if (comptime V == Str) {
                    try writer.writeByte('\'');
                    try writer.writeAll(entry.value_ptr.*.data);
                    try writer.writeByte('\'');
                } else if (comptime V == bool) {
                    if (entry.value_ptr.*) {
                        try writer.writeAll("True");
                    } else {
                        try writer.writeAll("False");
                    }
                } else {
                    try std.fmt.format(writer, "{any}", .{entry.value_ptr.*});
                }
            }
            try writer.writeByte('}');
        }
    };
}

// ============================ TCPSocket (统一 TCP 套接字) ============================
// TCPSocket 可以作为客户端或服务器使用
// 客户端模式: socket.connect(host, port) -> socket.write/read/close
// 服务器模式: socket.bind(port) -> socket.listen() -> socket.accept() -> client
pub const TCPSocket = struct {
    const Self = @This();
    socket: std.posix.socket_t,
    allocator: Allocator,
    is_server: bool = false,

    // 构造函数：tcpsocket()
    pub fn create(allocator: Allocator) !Self {
        const sock = try std.posix.socket(std.posix.AF.INET, std.posix.SOCK.STREAM, std.posix.IPPROTO.TCP);
        return Self{
            .socket = sock,
            .allocator = allocator,
            .is_server = false,
        };
    }

    // 绑定地址和端口 (服务器模式)
    pub fn bind(self: *Self, host: Str, port: i64) void {
        const addr = std.net.Address.parseIp(host.data, @as(u16, @intCast(port))) catch unreachable;
        std.posix.bind(self.socket, &addr.any, addr.getOsSockLen()) catch unreachable;
    }

    // 开始监听 (服务器模式)
    pub fn listen(self: *Self, backlog: i64) void {
        _ = backlog;
        std.posix.listen(self.socket, 128) catch unreachable;
        self.is_server = true;
    }

    // 接受连接 (服务器模式)，返回 TCPClient
    pub fn accept(self: *Self) !*TCPClient {
        var addr: std.posix.sockaddr = undefined;
        var addr_len: std.posix.socklen_t = @sizeOf(std.posix.sockaddr);
        const client_fd = try std.posix.accept(self.socket, &addr, &addr_len, 0);
        const stream = std.net.Stream{ .handle = client_fd };
        const client = try std.heap.page_allocator.create(TCPClient);
        client.* = TCPClient{
            .stream = stream,
            .allocator = self.allocator,
        };
        return client;
    }

    // 连接到服务器 (客户端模式) - 无超时
    pub fn connect(self: *Self, host: Str, port: i64) void {
        const addr = std.net.Address.parseIp(host.data, @as(u16, @intCast(port))) catch unreachable;
        std.posix.connect(self.socket, &addr.any, addr.getOsSockLen()) catch unreachable;
    }

    // 连接到服务器 (客户端模式) - 带超时
    pub fn connectWithTimeout(self: *Self, host: Str, port: i64, timeout_secs: u32) !void {
        const addr = std.net.Address.parseIp(host.data, @as(u16, @intCast(port))) catch {
            return error.HostUnreachable;
        };

        // 设置 O_NONBLOCK
        const flags = try std.posix.fcntl(self.socket, std.posix.F.GETFL, 0);
        const nonblock_val: u32 = 0o4000; // O_NONBLOCK value for x86_64
        _ = try std.posix.fcntl(self.socket, std.posix.F.SETFL, flags | nonblock_val);

        // 尝试连接 - 非阻塞模式
        _ = std.posix.connect(self.socket, &addr.any, addr.getOsSockLen()) catch {};

        // 连接进行中，等待完成或超时
        var pollfd = [_]std.os.linux.pollfd{
            std.os.linux.pollfd{
                .fd = self.socket,
                .events = std.os.linux.POLL.OUT,
                .revents = 0,
            },
        };

        const timeout_val = @as(i32, @intCast(timeout_secs)); // timeout_secs 已经是毫秒，直接传给 poll
        const poll_result = std.os.linux.poll(&pollfd, 1, timeout_val);

        if (poll_result == 0) {
            // 超时
            return error.Timeout;
        }

        // poll 失败
        if (poll_result == std.math.maxInt(usize)) {
            return error.Timeout;
        }

        // 检查 socket 是否可写（连接完成）
        if (pollfd[0].revents & std.os.linux.POLL.OUT == 0) {
            return error.Timeout;
        }

        // 检查连接错误
        std.posix.getsockoptError(self.socket) catch {
            return error.ConnectionRefused;
        };

        // 清除 O_NONBLOCK，恢复阻塞模式
        _ = try std.posix.fcntl(self.socket, std.posix.F.SETFL, flags);
    }

    // 发送数据
    pub fn write(self: *Self, data: Str) void {
        _ = std.posix.send(self.socket, data.data, 0) catch unreachable;
    }

    // 接收数据
    pub fn read(self: *Self, buffer_size: i64) Str {
        var buffer = self.allocator.alloc(u8, @as(usize, @intCast(buffer_size))) catch unreachable;
        const bytes_read = std.posix.recv(self.socket, buffer, 0) catch unreachable;
        return Str{
            .data = buffer[0..bytes_read],
            .allocator = self.allocator,
            .borrowed = false,
        };
    }

    // 关闭套接字
    pub fn close(self: *Self) void {
        std.posix.close(self.socket);
    }
};

// ============================ TCPClient (用于已接受的连接) ============================
pub const TCPClient = struct {
    const Self = @This();
    stream: std.net.Stream,
    allocator: Allocator,

    pub fn write(self: *Self, data: Str) void {
        self.stream.writeAll(data.data) catch unreachable;
    }

    pub fn read(self: *Self, buffer_size: i64) Str {
        var buffer = self.allocator.alloc(u8, @as(usize, @intCast(buffer_size))) catch unreachable;
        const bytes_read = self.stream.read(buffer) catch unreachable;
        return Str{
            .data = buffer[0..bytes_read],
            .allocator = self.allocator,
            .borrowed = false,
        };
    }

    pub fn close(self: *Self) void {
        self.stream.close();
    }
};

// ============================ UDPRecvResult (UDP 接收结果) ============================
pub const UDPRecvResult = struct {
    data: Str,
    host: Str,
    port: u16,
};

// ============================ UDPSocket (统一 UDP 套接字) ============================
// UDPSocket 可以绑定到本地地址用于接收，或用于发送到远程地址
// 服务器/接收模式: socket.bind(host, port) -> socket.recvfrom()
// 客户端/发送模式: socket.sendto(data, host, port)
pub const UDPSocket = struct {
    const Self = @This();
    socket: std.posix.socket_t,
    allocator: Allocator,

    // 构造函数：udpsocket()
    pub fn create(allocator: Allocator) !Self {
        const sock = try std.posix.socket(std.posix.AF.INET, std.posix.SOCK.DGRAM, std.posix.IPPROTO.UDP);
        return Self{
            .socket = sock,
            .allocator = allocator,
        };
    }

    // 绑定地址和端口
    pub fn bind(self: *Self, host: Str, port: i64) void {
        const addr = std.net.Address.parseIp(host.data, @as(u16, @intCast(port))) catch unreachable;
        std.posix.bind(self.socket, &addr.any, addr.getOsSockLen()) catch unreachable;
    }

    // 发送到指定地址
    pub fn sendto(self: *Self, data: Str, host: Str, port: i64) void {
        const addr = std.net.Address.parseIp(host.data, @as(u16, @intCast(port))) catch unreachable;
        _ = std.posix.sendto(self.socket, data.data, 0, &addr.any, addr.getOsSockLen()) catch unreachable;
    }

    // 接收数据（简化版本，只返回数据）
    pub fn recvfrom(self: *Self, buffer_size: i64) Str {
        var buffer = self.allocator.alloc(u8, @as(usize, @intCast(buffer_size))) catch unreachable;
        var addr: std.posix.sockaddr = undefined;
        var addr_len: std.posix.socklen_t = @sizeOf(@TypeOf(addr));
        const bytes_read = std.posix.recvfrom(self.socket, buffer, 0, &addr, &addr_len) catch unreachable;
        return Str{
            .data = buffer[0..bytes_read],
            .allocator = self.allocator,
            .borrowed = false,
        };
    }

    // 接收数据并返回发送者地址信息（返回 UDPRecvResult 结构体）
    pub fn recvfromFull(self: *Self, buffer_size: i64) UDPRecvResult {
        var buffer = self.allocator.alloc(u8, @as(usize, @intCast(buffer_size))) catch unreachable;
        var addr: std.posix.sockaddr = undefined;
        var addr_len: std.posix.socklen_t = @sizeOf(@TypeOf(addr));
        const bytes_read = std.posix.recvfrom(self.socket, buffer, 0, &addr, &addr_len) catch unreachable;
        const net_addr = std.net.Address.initPosix(&addr);
        return UDPRecvResult{
            .data = Str{
                .data = buffer[0..bytes_read],
                .allocator = self.allocator,
                .borrowed = false,
            },
            .host = Str{
                .data = net_addr.toString() catch unreachable,
                .allocator = self.allocator,
                .borrowed = true,
            },
            .port = net_addr.getPort(),
        };
    }

    // 接收数据（带超时）
    pub fn recvfromWithTimeout(self: *Self, buffer_size: i64, timeout_secs: u32) !Str {
        // 使用 poll 等待数据
        var pollfd = [_]std.os.linux.pollfd{
            std.os.linux.pollfd{
                .fd = self.socket,
                .events = std.os.linux.POLL.IN,
                .revents = 0,
            },
        };

        const timeout_val = @as(i32, @intCast(timeout_secs)); // timeout_secs 已经是毫秒，直接传给 poll
        const poll_result = std.os.linux.poll(&pollfd, 1, timeout_val);

        if (poll_result == 0) {
            // 超时
            return error.Timeout;
        }

        // poll 失败
        if (poll_result == std.math.maxInt(usize)) {
            return error.Timeout;
        }

        // 检查是否有数据可读
        if (pollfd[0].revents & std.os.linux.POLL.IN == 0) {
            return error.Timeout;
        }

        // 接收数据
        var buffer = self.allocator.alloc(u8, @as(usize, @intCast(buffer_size))) catch {
            return error.OutOfMemory;
        };
        var addr: std.posix.sockaddr = undefined;
        var addr_len: std.posix.socklen_t = @sizeOf(@TypeOf(addr));
        const bytes_read = std.posix.recvfrom(self.socket, buffer, 0, &addr, &addr_len) catch {
            return error.ReceiveFailed;
        };
        return Str{
            .data = buffer[0..bytes_read],
            .allocator = self.allocator,
            .borrowed = false,
        };
    }

    // 关闭套接字
    pub fn close(self: *Self) void {
        std.posix.close(self.socket);
    }
};

// ============================ JSON ============================
fn jsonEscape(allocator: Allocator, s: anytype) Str {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    const T = @TypeOf(s);
    // 处理不同类型的键
    if (T == Str) {
        // 字符串类型
        for (s.asSlice()) |c| {
            switch (c) {
                '"' => result.appendSlice("\\\"") catch {},
                '\\' => result.appendSlice("\\\\") catch {},
                '\n' => result.appendSlice("\\n") catch {},
                '\r' => result.appendSlice("\\r") catch {},
                '\t' => result.appendSlice("\\t") catch {},
                else => result.append(c) catch {},
            }
        }
    } else if (T == i64 or T == i32 or T == i16 or T == i8 or T == u64 or T == u32 or T == u16 or T == u8) {
        // 整数类型
        var buf: [32]u8 = undefined;
        const slice = std.fmt.bufPrint(&buf, "{}", .{s}) catch "";
        result.appendSlice(slice) catch {};
    } else if (T == f64 or T == f32) {
        // 浮点数类型
        var buf: [32]u8 = undefined;
        const slice = std.fmt.bufPrint(&buf, "{}", .{s}) catch "";
        result.appendSlice(slice) catch {};
    } else if (T == bool) {
        // 布尔类型
        if (s) {
            result.appendSlice("true") catch {};
        } else {
            result.appendSlice("false") catch {};
        }
    } else {
        // 默认当作字符串处理
        var buf: [32]u8 = undefined;
        const slice = std.fmt.bufPrint(&buf, "{}", .{s}) catch "";
        result.appendSlice(slice) catch {};
    }

    return Str.init(allocator, result.items) catch unreachable;
}

pub fn jsonStringify(allocator: Allocator, obj: anytype) Str {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    const T = @TypeOf(obj.*);

    // 如果传入的是 JsonValue 本身（不是 Dict/List），单独处理
    if (T == JsonValue) {
        jsonStringifyValue(allocator, &result, obj.*);
        // 先复制，再让 defer 释放 result.items
        const result_copy = allocator.dupe(u8, result.items) catch unreachable;
        return Str{ .data = result_copy, .allocator = allocator, .borrowed = false };
    }

    if (@hasField(T, "map")) {
        result.append('{') catch {};
        var it = obj.map.iterator();
        var first = true;
        while (it.next()) |entry| {
            if (!first) {
                result.append(',') catch {};
            }
            first = false;

            result.append('"') catch {};
            const key_escaped = jsonEscape(allocator, entry.key_ptr.*);
            result.appendSlice(key_escaped.asSlice()) catch {};
            result.append('"') catch {};
            result.append(':') catch {};

            const val = entry.value_ptr.*;
            // 检查是否是 JsonValue - 使用 @typeInfo 检查类型
            const ValType = @TypeOf(val);
            if (ValType == JsonValue) {
                // 这是一个 JsonValue
                jsonStringifyValue(allocator, &result, val);
            } else if (@typeInfo(ValType) == .@"struct" and @hasField(ValType, "map")) {
                const nested = jsonStringify(allocator, &val);
                result.appendSlice(nested.asSlice()) catch {};
            } else if (@typeInfo(ValType) == .@"struct" and @hasField(ValType, "items")) {
                const list_json = jsonStringify(allocator, &val);
                result.appendSlice(list_json.asSlice()) catch {};
            } else {
                result.append('"') catch {};
                const val_escaped = jsonEscape(allocator, val);
                result.appendSlice(val_escaped.asSlice()) catch {};
                result.append('"') catch {};
            }
        }
        result.append('}') catch {};
    } else if (@typeInfo(T) == .@"struct" and @hasField(T, "items")) {
        result.append('[') catch {};
        var i: usize = 0;
        for (obj.items.items) |item| {
            if (i > 0) {
                result.append(',') catch {};
            }
            i += 1;

            // 检查是否是 JsonValue - 使用 @TypeOf 直接比较
            const ItemType = @TypeOf(item);
            if (ItemType == JsonValue) {
                jsonStringifyValue(allocator, &result, item);
            } else if (@typeInfo(ItemType) == .@"struct" and @hasField(ItemType, "map")) {
                const nested = jsonStringify(allocator, &item);
                result.appendSlice(nested.asSlice()) catch {};
            } else if (@typeInfo(ItemType) == .@"struct" and @hasField(ItemType, "items")) {
                const list_json = jsonStringify(allocator, &item);
                result.appendSlice(list_json.asSlice()) catch {};
            } else {
                result.append('"') catch {};
                const item_escaped = jsonEscape(allocator, item);
                result.appendSlice(item_escaped.asSlice()) catch {};
                result.append('"') catch {};
            }
        }
        result.append(']') catch {};
    }

    return Str.init(allocator, result.items) catch unreachable;
}

pub fn convertToJsonValueList(allocator: Allocator, list: anytype) List(JsonValue) {
    var result = List(JsonValue).init(allocator);
    const T = @TypeOf(list);
    if (@typeInfo(T) == .@"struct" and @hasField(T, "items")) {
        for (list.items.items) |item| {
            const ItemType = @TypeOf(item);
            if (ItemType == JsonValue) {
                // 已经是 JsonValue，直接添加
                result.append(item) catch unreachable;
            } else {
                // 其他类型，使用 from 转换函数处理（包括 dict、str、int 等）
                const jv = fromAnyTypeToJsonValue(allocator, item) catch JsonValue{ .null = {} };
                result.append(jv) catch unreachable;
            }
        }
    }
    return result;
}

pub fn fromAnyTypeToJsonValue(allocator: Allocator, value: anytype) !JsonValue {
    const T = @TypeOf(value);
    if (T == JsonValue) {
        return value;
    }
    if (@typeInfo(T) == .@"struct" and @hasField(T, "map")) {
        // 这是一个 dict，转换为 JsonValue.dict
        var jsonDict = Dict(Str, JsonValue).init(allocator);
        var it = value.map.iterator();
        while (it.next()) |entry| {
            const key = entry.key_ptr.*;
            // 复制 key（始终是 Str）
            const keyStr = blk: {
                if (@typeInfo(@TypeOf(key)) == .@"struct" and @hasField(@TypeOf(key), "data")) {
                    break :blk try Str.init(allocator, key.data);
                }
                break :blk try Str.init(allocator, "unknown");
            };
            const val = entry.value_ptr.*;
            const jv = try fromAnyTypeToJsonValue(allocator, val);
            try jsonDict.put(keyStr, jv);
        }
        return JsonValue{ .dict = jsonDict };
    }
    if (@typeInfo(T) == .@"struct" and @hasField(T, "items")) {
        // 这是一个 list，转换为 JsonValue.list
        var jsonList = List(JsonValue).init(allocator);
        for (value.items.items) |item| {
            const jv = try fromAnyTypeToJsonValue(allocator, item);
            try jsonList.append(jv);
        }
        return JsonValue{ .list = jsonList };
    }
    if (@typeInfo(T) == .@"struct" and @hasField(T, "data")) {
        // 这是一个 Str，转换为 JsonValue.str
        return JsonValue{ .str = value };
    }
    // 默认情况：尝试转换为 int
    return JsonValue{ .int = value };
}

fn jsonStringifyValue(allocator: Allocator, result: *std.ArrayList(u8), val: JsonValue) void {
    switch (val) {
        .str => |s| {
            result.append('"') catch {};
            const escaped = jsonEscape(allocator, s);
            result.appendSlice(escaped.asSlice()) catch {};
            result.append('"') catch {};
        },
        .int => |i| {
            const str = std.fmt.allocPrint(allocator, "{d}", .{i}) catch "";
            result.appendSlice(str) catch {};
        },
        .float => |f| {
            const str = std.fmt.allocPrint(allocator, "{d:.10}", .{f}) catch "";
            result.appendSlice(str) catch {};
        },
        .bool => |b| {
            if (b) {
                result.appendSlice("true") catch {};
            } else {
                result.appendSlice("false") catch {};
            }
        },
        .list => |l| {
            result.append('[') catch {};
            var i: usize = 0;
            for (l.items.items) |item| {
                if (i > 0) {
                    result.append(',') catch {};
                }
                i += 1;
                jsonStringifyValue(allocator, result, item);
            }
            result.append(']') catch {};
        },
        .dict => |d| {
            result.append('{') catch {};
            var it = d.map.iterator();
            var first = true;
            while (it.next()) |entry| {
                if (!first) {
                    result.append(',') catch {};
                }
                first = false;
                result.append('"') catch {};
                const key_escaped = jsonEscape(allocator, entry.key_ptr.*);
                result.appendSlice(key_escaped.asSlice()) catch {};
                result.append('"') catch {};
                result.append(':') catch {};
                jsonStringifyValue(allocator, result, entry.value_ptr.*);
            }
            result.append('}') catch {};
        },
        .null => {
            result.appendSlice("null") catch {};
        },
    }
}

pub fn jsonParse(allocator: Allocator, json_str: Str) JsonValue {
    const json_data = json_str.asSlice();

    const parsed = std.json.parseFromSlice(std.json.Value, allocator, json_data, .{}) catch return JsonValue{ .null = {} };
    defer parsed.deinit();

    return jsonValueFromStdJson(parsed.value, allocator);
}

fn jsonValueFromStdJson(std_value: std.json.Value, allocator: Allocator) JsonValue {
    switch (std_value) {
        .string => |s| return JsonValue{ .str = Str.init(allocator, s) catch unreachable },
        .integer => |n| return JsonValue{ .int = n },
        .float => |n| return JsonValue{ .float = n },
        .number_string => |s| {
            // 尝试解析为整数
            if (std.fmt.parseInt(i64, s, 10)) |n| {
                return JsonValue{ .int = n };
            } else |_| {
                // 解析为浮点数
                const f = std.fmt.parseFloat(f64, s) catch unreachable;
                return JsonValue{ .float = f };
            }
        },
        .bool => |b| return JsonValue{ .bool = b },
        .null => return JsonValue{ .null = {} },
        .array => |arr| {
            var list = List(JsonValue).init(allocator);
            for (arr.items) |item| {
                list.append(jsonValueFromStdJson(item, allocator)) catch unreachable;
            }
            return JsonValue{ .list = list };
        },
        .object => |obj| {
            var dict = Dict(Str, JsonValue).init(allocator);
            var it = obj.iterator();
            while (it.next()) |entry| {
                const key = entry.key_ptr.*;
                const key_str = Str.init(allocator, key) catch unreachable;
                const val = jsonValueFromStdJson(entry.value_ptr.*, allocator);
                dict.put(key_str, val) catch unreachable;
            }
            return JsonValue{ .dict = dict };
        },
    }
}

pub fn jsonLoads(allocator: Allocator, json_str: Str) Dict(Str, JsonValue) {
    const json_data = json_str.asSlice();

    const parsed = std.json.parseFromSlice(std.json.Value, allocator, json_data, .{}) catch return Dict(Str, JsonValue).init(allocator);
    defer parsed.deinit();

    if (parsed.value != .object) {
        return Dict(Str, JsonValue).init(allocator);
    }

    var result = Dict(Str, JsonValue).init(allocator);
    var it = parsed.value.object.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;
        const key_str = Str.init(allocator, key) catch unreachable;
        const val = jsonValueFromStdJson(entry.value_ptr.*, allocator);
        result.put(key_str, val) catch unreachable;
    }

    return result;
}

// ============================ HTTP ============================
fn parseUrl(url: []const u8) struct { host: []const u8, port: u16, path: []const u8 } {
    var host: []const u8 = "127.0.0.1";
    var port: u16 = 80;
    var path: []const u8 = "/";

    var remaining = url;
    if (std.mem.startsWith(u8, remaining, "http://")) {
        remaining = remaining[7..];
    } else if (std.mem.startsWith(u8, remaining, "https://")) {
        remaining = remaining[8..];
        port = 443;
    } else if (std.mem.startsWith(u8, remaining, "ws://")) {
        remaining = remaining[5..];
    } else if (std.mem.startsWith(u8, remaining, "wss://")) {
        remaining = remaining[6..];
        port = 443;
    }

    // 查找路径起始位置
    const path_start = std.mem.indexOfAny(u8, remaining, "/?#");
    const host_port_part = if (path_start) |idx| remaining[0..idx] else remaining;

    // 查找端口
    const colon_pos = std.mem.indexOfScalar(u8, host_port_part, ':');
    if (colon_pos) |idx| {
        host = host_port_part[0..idx];
        port = std.fmt.parseInt(u16, host_port_part[idx + 1 ..], 10) catch 80;
    } else {
        host = host_port_part;
    }

    // 获取路径
    if (path_start) |idx| {
        path = remaining[idx..];
    }

    return .{ .host = host, .port = port, .path = path };
}

// urlUsesTls —— URL 是否要求 TLS（只看 scheme：https:// 为 true）。
// 注意不能用「端口 == 443」判断：用户可以写 https://host:8443。
fn urlUsesTls(url: []const u8) bool {
    return std.mem.startsWith(u8, url, "https://");
}

// 客户端连接抽象：https 走 TLS（std.crypto.tls.Client），http 走明文 socket。
//
// 为什么 https 不能再走裸 socket：parseUrl 只是把 https 的默认端口设成 443，
// 原来的 httpGet/httpPost 仍然用明文 socket 发请求。TLS 端口收到明文会直接
// 回 400/497（抓包首字节就是 16 进制 47 45 54 20，即 "GET "），对真实站点
// 也一样失败。
//
// 证书验证：主机名（SAN/CN）+ 系统默认 CA 包（由 Certificate.Bundle.rescan
// 自动发现 /etc/ssl/certs 等路径）。验证失败返回 error.CertificateVerifyFailed，
// 绝不静默降级成明文或忽略校验。
const HttpConn = struct {
    sockfd: std.posix.socket_t,
    tls: ?std.crypto.tls.Client = null,

    fn sendAll(self: *HttpConn, bytes: []const u8) !void {
        if (self.tls) |*t| {
            const stream = std.net.Stream{ .handle = self.sockfd };
            t.writeAll(stream, bytes) catch |err| switch (err) {
                error.WouldBlock => return error.Timeout,
                else => return error.ConnectionFailed,
            };
            return;
        }
        var sent: usize = 0;
        while (sent < bytes.len) {
            const n = std.posix.send(self.sockfd, bytes[sent..], 0) catch return error.ConnectionFailed;
            sent += n;
        }
    }

    fn read(self: *HttpConn, buf: []u8) !usize {
        if (self.tls) |*t| {
            const stream = std.net.Stream{ .handle = self.sockfd };
            return t.read(stream, buf) catch |err| switch (err) {
                error.WouldBlock => error.Timeout,
                // 对端未发 close_notify 直接断开：已有数据按正常结束处理
                error.TlsConnectionTruncated => 0,
                else => error.ConnectionFailed,
            };
        }
        return std.posix.recv(self.sockfd, buf, 0) catch |err| switch (err) {
            error.WouldBlock => error.Timeout,
            else => error.ConnectionFailed,
        };
    }

    fn close(self: *HttpConn) void {
        if (self.tls) |*t| {
            // 尽力发 close_notify，失败不影响响应结果
            const stream = std.net.Stream{ .handle = self.sockfd };
            _ = t.writeEnd(stream, &[_]u8{}, true) catch {};
        }
        std.posix.close(self.sockfd);
    }
};

// headerHasChunked —— 响应头里是否声明了 Transfer-Encoding: chunked（大小写不敏感）。
fn headerHasChunked(headers_block: []const u8) bool {
    var it = std.mem.splitScalar(u8, headers_block, '\n');
    while (it.next()) |line| {
        const trimmed = std.mem.trimRight(u8, line, "\r");
        if (std.ascii.startsWithIgnoreCase(trimmed, "transfer-encoding:")) {
            return std.ascii.indexOfIgnoreCase(trimmed, "chunked") != null;
        }
    }
    return false;
}

// setSocketTimeout —— 设置 SO_RCVTIMEO / SO_SNDTIMEO，让读写不会无限阻塞。
// 超过 timeout_secs 未就绪时 recv/send 返回 WouldBlock（上层映射为 Timeout）。
fn setSocketTimeout(sockfd: std.posix.socket_t, timeout_secs: u32) void {
    const timeout_ms: i32 = @intCast(timeout_secs * 1000);
    if (timeout_ms <= 0) return;
    const tv = std.os.linux.timeval{
        .sec = @as(isize, @intCast(@divFloor(timeout_ms, 1000))),
        .usec = @as(isize, @intCast(@mod(timeout_ms, 1000) * 1000)),
    };
    const tb = std.mem.asBytes(&tv);
    const tl: std.os.linux.socklen_t = @intCast(tb.len);
    _ = std.os.linux.setsockopt(sockfd, std.posix.SOL.SOCKET, std.posix.SO.SNDTIMEO, tb.ptr, tl);
    _ = std.os.linux.setsockopt(sockfd, std.posix.SOL.SOCKET, std.posix.SO.RCVTIMEO, tb.ptr, tl);
}

// httpConnect —— DNS + TCP 建连 +（https 时）TLS 握手。
// 返回的连接由调用方 HttpConn.close() 关闭。
fn httpConnect(allocator: Allocator, url: Str, timeout_secs: u32) !HttpConn {
    const parsed = parseUrl(url.data);
    const stream = std.net.tcpConnectToHost(allocator, parsed.host, parsed.port) catch return error.HostUnreachable;
    const sockfd = stream.handle;
    setSocketTimeout(sockfd, timeout_secs);

    if (!urlUsesTls(url.data)) {
        return HttpConn{ .sockfd = sockfd };
    }

    // 系统 CA 包：rescan 失败时 bundle 为空，握手会以
    // CertificateIssuerMismatch 失败（仍然不会退化成不校验）
    var bundle: std.crypto.Certificate.Bundle = .{};
    bundle.rescan(allocator) catch {};
    defer bundle.deinit(allocator);

    const client = std.crypto.tls.Client.init(stream, .{
        .host = .{ .explicit = parsed.host },
        .ca = .{ .bundle = bundle },
    }) catch |err| {
        std.posix.close(sockfd);
        return switch (err) {
            error.CertificateHostMismatch,
            error.CertificateExpired,
            error.CertificateNotYetValid,
            error.CertificateIssuerMismatch,
            error.CertificatePublicKeyInvalid,
            error.CertificateFieldHasInvalidLength,
            error.TlsCertificateNotVerified,
            => error.CertificateVerifyFailed,
            else => error.TlsHandshakeFailed,
        };
    };
    return HttpConn{ .sockfd = sockfd, .tls = client };
}

pub fn httpGet(allocator: Allocator, url: Str, timeout_secs: u32) !Str {
    const parsed = parseUrl(url.data);

    var conn = try httpConnect(allocator, url, timeout_secs);
    defer conn.close();

    const request = try std.fmt.allocPrint(allocator, "GET {s} HTTP/1.1\r\nHost: {s}\r\nConnection: close\r\n\r\n", .{
        parsed.path,
        parsed.host,
    });
    defer allocator.free(request);

    try conn.sendAll(request);

    // 边收边判断响应边界：Content-Length 收齐，或对端 close。
    // 旧实现只读一次 8192 字节，大响应会被截断。
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    var chunk: [8192]u8 = undefined;
    var content_length: ?usize = null;
    var headers_parsed = false;
    var is_chunked = false;
    var body_start: usize = 0;

    while (true) {
        const n = conn.read(&chunk) catch |err| {
            if (err == error.Timeout and buffer.items.len > 0) break;
            return err;
        };
        if (n == 0) break;
        try buffer.appendSlice(chunk[0..n]);

        if (!headers_parsed) {
            if (std.mem.indexOf(u8, buffer.items, "\r\n\r\n")) |hdr_end| {
                headers_parsed = true;
                body_start = hdr_end + 4;
                const headers_block = buffer.items[0..hdr_end];
                if (std.mem.indexOf(u8, headers_block, "Content-Length:")) |cl_idx| {
                    const rest = headers_block[cl_idx + 15 ..];
                    const cl_end = std.mem.indexOfAny(u8, rest, "\r\n") orelse rest.len;
                    content_length = std.fmt.parseInt(usize, std.mem.trim(u8, rest[0..cl_end], " \t"), 10) catch null;
                }
                is_chunked = headerHasChunked(headers_block);
                if (content_length) |cl| {
                    if (buffer.items.len >= body_start + cl) break;
                }
            }
        } else if (content_length) |cl| {
            if (buffer.items.len >= body_start + cl) break;
        }
        // chunked response: stop once the terminating zero chunk is seen.
        if (headers_parsed and is_chunked and buffer.items.len > body_start) {
            if (std.mem.indexOf(u8, buffer.items[body_start - 2 ..], "\r\n0\r\n\r\n") != null) break;
        }
    }

    if (buffer.items.len == 0) return error.ConnectionFailed;
    return Str{
        .data = try allocator.dupe(u8, buffer.items),
        .allocator = allocator,
        .borrowed = false,
    };
}

// ============================ WebSocket ============================
const Opcode = enum(u4) {
    continuation = 0x0,
    text = 0x1,
    binary = 0x2,
    close = 0x8,
    ping = 0x9,
    pong = 0xA,
};

pub const WebSocketClient = struct {
    stream: std.net.Stream,
    allocator: Allocator,

    pub fn connect(allocator: Allocator, url: Str, headers: ?Dict(Str, Str)) !WebSocketClient {
        const parsed = parseUrl(url.data);
        const stream = try std.net.tcpConnectToHost(allocator, parsed.host, parsed.port);
        var key_bytes: [16]u8 = undefined;
        std.crypto.random.bytes(&key_bytes);
        var key_buf: [32]u8 = undefined;
        const key_encoded = std.base64.standard.Encoder.encode(&key_buf, &key_bytes);

        // 构建 HTTP 请求头字符串
        var request_parts = std.ArrayList([]const u8).init(allocator);
        defer request_parts.deinit();

        // 基础请求行
        try request_parts.append("GET ");
        try request_parts.append(parsed.path);
        try request_parts.append(" HTTP/1.1\r\nHost: ");
        try request_parts.append(parsed.host);
        try request_parts.append("\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: ");
        try request_parts.append(key_encoded);
        try request_parts.append("\r\nSec-WebSocket-Version: 13\r\n");

        // 添加自定义 headers
        if (headers) |h| {
            var it = h.map.iterator();
            while (it.next()) |entry| {
                try request_parts.append(entry.key_ptr.*.data);
                try request_parts.append(": ");
                try request_parts.append(entry.value_ptr.data);
                try request_parts.append("\r\n");
            }
        }

        // 结束请求头
        try request_parts.append("\r\n");

        // 计算总长度
        var total_len: usize = 0;
        for (request_parts.items) |part| {
            total_len += part.len;
        }

        // 构建最终请求字符串
        var request = try allocator.alloc(u8, total_len);
        defer allocator.free(request);
        var offset: usize = 0;
        for (request_parts.items) |part| {
            @memcpy(request[offset..][0..part.len], part);
            offset += part.len;
        }

        try stream.writeAll(request);
        var response_buf: [1024]u8 = undefined;
        const n = try stream.read(&response_buf);
        if (std.mem.indexOf(u8, response_buf[0..n], "101 Switching Protocols") == null) {
            stream.close();
            return error.HandshakeFailed;
        }
        return WebSocketClient{ .stream = stream, .allocator = allocator };
    }

    pub fn send(self: *WebSocketClient, message: anytype) !void {
        // 编译期类型分派
        const T = @TypeOf(message);
        const data: []const u8 = blk: {
            if (T == Str) {
                break :blk message.asSlice();
            } else if (T == []u8) {
                break :blk message;
            } else if (T == []const u8) {
                break :blk message;
            } else {
                @compileError("WebSocket.send() expects Str, []u8, or []const u8, got " ++ @typeName(T));
            }
        };

        // 自动判断 frame 类型：
        //   - Str 始终是 text frame
        //   - []u8 中如果所有字节都是可打印 ASCII（含 \t\n\r）→ text frame（自动转换）
        //   - []u8 中含有控制字符或非 ASCII → binary frame
        const is_text: bool = if (T == Str) true else isPrintableAscii(data);
        const opcode: u8 = if (is_text) 0x81 else 0x82;

        var frame = std.ArrayList(u8).init(self.allocator);
        defer frame.deinit();
        try frame.append(opcode);

        var mask_key: [4]u8 = undefined;
        std.crypto.random.bytes(&mask_key);

        if (data.len < 126) {
            try frame.append(@as(u8, @intCast(data.len)) | 0x80);
        } else if (data.len < 65536) {
            try frame.append(126 | 0x80);
            try frame.append(@as(u8, @intCast((data.len >> 8) & 0xFF)));
            try frame.append(@as(u8, @intCast(data.len & 0xFF)));
        } else {
            try frame.append(127 | 0x80);
            const len_bytes = std.mem.toBytes(data.len);
            for (len_bytes) |b| {
                try frame.append(b);
            }
        }

        try frame.appendSlice(&mask_key);

        var masked_data = try self.allocator.alloc(u8, data.len);
        defer self.allocator.free(masked_data);
        for (data, 0..) |b, i| {
            masked_data[i] = b ^ mask_key[i % 4];
        }
        try frame.appendSlice(masked_data);
        try self.stream.writeAll(frame.items);
    }

    pub fn recv(self: *WebSocketClient) !Str {
        var header: [2]u8 = undefined;
        _ = try self.stream.read(&header);

        const opcode = header[0] & 0x0F;
        if (opcode == 0x8) {
            return Str{
                .data = "",
                .allocator = self.allocator,
                .borrowed = false,
            };
        }

        var payload_len = @as(u64, header[1] & 0x7F);
        if (payload_len == 126) {
            var len_buf: [2]u8 = undefined;
            _ = try self.stream.read(&len_buf);
            payload_len = @as(u16, len_buf[0]) << 8 | @as(u16, len_buf[1]);
        } else if (payload_len == 127) {
            var len_buf: [8]u8 = undefined;
            _ = try self.stream.read(&len_buf);
            payload_len = 0;
            for (len_buf) |b| {
                payload_len = (payload_len << 8) | @as(u64, b);
            }
        }

        const masked = (header[1] & 0x80) != 0;
        var mask_key: [4]u8 = undefined;
        if (masked) {
            _ = try self.stream.read(&mask_key);
        }

        var payload: [8192]u8 = undefined;
        const to_read = @min(payload_len, 8192);
        _ = try self.stream.read(payload[0..to_read]);

        if (masked) {
            for (0..to_read) |i| {
                payload[i] ^= mask_key[i % 4];
            }
        }

        return Str{
            .data = try self.allocator.dupe(u8, payload[0..to_read]),
            .allocator = self.allocator,
            .borrowed = false,
        };
    }

    pub fn close(self: *WebSocketClient) void {
        var close_frame: [2]u8 = .{ 0x88, 0x00 };
        _ = self.stream.write(&close_frame) catch {};
        self.stream.close();
    }
};

// 判断字节切片是否全部为"可打印 ASCII"（含 \t \n \r 三个常用控制字符）
// 用于 WebSocket.send() 自动判断 text/binary frame 类型
fn isPrintableAscii(data: []const u8) bool {
    for (data) |b| {
        // 0x00-0x08, 0x0B, 0x0C, 0x0E-0x1F: 非可打印控制字符
        if (b < 0x20) {
            if (b != 0x09 and b != 0x0A and b != 0x0D) {
                return false;
            }
        }
        // 0x7F: DEL
        if (b == 0x7F) {
            return false;
        }
        // 0x80-0xFF: 非 ASCII（可能是 UTF-8 编码的 Unicode，但简化处理为非可打印）
        if (b >= 0x80) {
            return false;
        }
    }
    return true;
}

// ============================ WebSocketClient 构造函数 ============================
// 全局构造函数：websocket(url, headers)
pub fn websocket(url: Str, headers: ?Dict(Str, Str)) *WebSocketClient {
    const ws = std.heap.page_allocator.create(WebSocketClient) catch unreachable;
    ws.* = WebSocketClient.connect(std.heap.page_allocator, url, headers) catch unreachable;
    return ws;
}

pub fn wsConnect(url: Str, headers: ?Dict(Str, Str)) WebSocketClient {
    return WebSocketClient.connect(std.heap.page_allocator, url, headers) catch unreachable;
}

pub fn wsSend(client: WebSocketClient, message: anytype) void {
    var c = client;
    c.send(message) catch unreachable;
}

pub fn wsRecv(client: WebSocketClient) Str {
    var c = client;
    return c.recv() catch unreachable;
}

pub fn wsClose(client: WebSocketClient) void {
    var c = client;
    c.close();
}

// ============================ Serial Port ============================
// Cross-platform serial port implementation

const builtin = @import("builtin");

pub const SerialPort = struct {
    const Self = @This();

    handle: SerialHandle,
    is_open: bool,

    pub fn open(port: []const u8, baud_rate: u32) !Self {
        const handle = try serialOpen(port, baud_rate);
        return Self{
            .handle = handle,
            .is_open = true,
        };
    }

    pub fn close(self: *Self) void {
        if (self.is_open) {
            serialClose(self.handle);
            self.is_open = false;
        }
    }

    pub fn read(self: *Self, length: usize) Str {
        if (!self.is_open) {
            return Str{ .data = "", .allocator = std.heap.page_allocator, .borrowed = true };
        }
        return serialRead(self.handle, length);
    }

    pub fn write(self: *Self, data: []const u8) usize {
        if (!self.is_open) {
            return 0;
        }
        return serialWrite(self.handle, data);
    }

    pub fn available(self: *Self) usize {
        if (!self.is_open) {
            return 0;
        }
        return serialAvailable(self.handle);
    }
};

// ============================ SerialPort 构造函数 ============================
// 全局构造函数：serial(port, baud_rate)
pub fn newSerial(port: Str, baud_rate: i64) *SerialPort {
    const sp = std.heap.page_allocator.create(SerialPort) catch unreachable;
    sp.* = SerialPort.open(port.data, @as(u32, @intCast(baud_rate))) catch unreachable;
    return sp;
}

// Platform-specific handle type
pub const SerialHandle = if (builtin.os.tag == .windows) i32 else i32;

fn serialOpen(port: []const u8, baud_rate: u32) !SerialHandle {
    if (builtin.os.tag == .windows) {
        const w = @import("std.os.windows");
        const kernel32 = w.kernel32;

        const port_name = if (std.mem.startsWith(u8, port, "COM")) "\\\\.\\" ++ port else port;

        const handle = kernel32.CreateFileA(
            @as([*c]const u8, @ptrFromInt(@intFromPtr(port_name.ptr))),
            w.GENERIC_READ | w.GENERIC_WRITE,
            0,
            null,
            w.OPEN_EXISTING,
            0,
            null,
        );

        if (handle == w.INVALID_HANDLE_VALUE) {
            return error.OpenFailed;
        }

        var dcb: w.DCB = undefined;
        if (kernel32.GetCommState(handle, &dcb) == 0) {
            kernel32.CloseHandle(handle);
            return error.GetStateFailed;
        }

        dcb.BaudRate = baud_rate;
        dcb.ByteSize = 8;
        dcb.StopBits = 0;
        dcb.Parity = 0;

        if (kernel32.SetCommState(handle, &dcb) == 0) {
            kernel32.CloseHandle(handle);
            return error.SetStateFailed;
        }

        return @as(i32, @intCast(@intFromPtr(handle)));
    } else {
        const flags: u32 = std.os.O.RDWR | std.os.O.NOCTTY | std.os.O.NDELAY;
        const fd = try std.posix.open(port, flags, 0);

        var term: std.posix.termios = undefined;
        try std.posix.tcgetattr(fd, &term);

        const speed = switch (baud_rate) {
            300 => std.posix.B300,
            1200 => std.posix.B1200,
            2400 => std.posix.B2400,
            4800 => std.posix.B4800,
            9600 => std.posix.B9600,
            19200 => std.posix.B19200,
            38400 => std.posix.B38400,
            57600 => std.posix.B57600,
            115200 => std.posix.B115200,
            230400 => std.posix.B230400,
            else => std.posix.B9600,
        };

        term.speed = speed;
        term.cflag |= std.posix.PARENB;
        term.cflag &= ~std.posix.PARODD;
        term.cflag |= std.posix.CSTOPB;
        term.cflag |= std.posix.CS8;
        term.cflag |= std.posix.CLOCAL | std.posix.CREAD;

        term.lflag &= ~(@as(u32, std.posix.ECHO | std.posix.ECHOE | std.posix.ECHOK | std.posix.ECHOCTL | std.posix.ECHOKE | std.posix.ICANON | std.posix.IEXTEN | std.posix.ISIG));
        term.iflag &= ~(@as(u32, std.posix.BRKINT | std.posix.INPCK | std.posix.ISTRIP | std.posix.INLCR | std.posix.IGNCR | std.posix.ICRNL | std.posix.IXON | std.posix.IXOFF | std.posix.IXANY | std.posix.IMAXBEL));
        term.oflag &= ~@as(u32, std.posix.OPOST);
        term.cc[std.posix.VMIN] = 0;
        term.cc[std.posix.VTIME] = 0;

        try std.posix.tcsetattr(fd, std.posix.TCSANOW, &term);

        return fd;
    }
}

fn serialClose(handle: SerialHandle) void {
    if (builtin.os.tag == .windows) {
        const w = @import("std.os.windows");
        _ = w.kernel32.CloseHandle(@as(w.HANDLE, @ptrFromInt(@as(usize, @as(i32, handle)))));
    } else {
        std.posix.close(handle);
    }
}

fn serialRead(handle: SerialHandle, length: usize) Str {
    var buffer: [4096]u8 = undefined;
    const size: usize = @min(length, 4096);
    var bytes_read: usize = 0;

    if (builtin.os.tag == .windows) {
        const w = @import("std.os.windows");
        var bytes_read_win: u32 = 0;

        if (w.kernel32.ReadFile(
            @as(w.HANDLE, @ptrFromInt(@as(usize, @as(i32, handle)))),
            @as([*c]u8, @ptrFromInt(@intFromPtr(&buffer))),
            @as(u32, @as(usize, size)),
            &bytes_read_win,
            null,
        ) == 0) {
            return Str{ .data = "", .allocator = std.heap.page_allocator, .borrowed = true };
        }
        bytes_read = bytes_read_win;
    } else {
        bytes_read = std.posix.read(handle, buffer[0..size]) catch return Str{ .data = "", .allocator = std.heap.page_allocator, .borrowed = true };
    }

    const result = std.heap.page_allocator.alloc(u8, bytes_read) catch unreachable;
    @memcpy(result.ptr, buffer[0..bytes_read].ptr);

    return Str{
        .data = result,
        .allocator = std.heap.page_allocator,
        .borrowed = false,
    };
}

fn serialWrite(handle: SerialHandle, data: []const u8) usize {
    if (builtin.os.tag == .windows) {
        const w = @import("std.os.windows");
        var bytes_written: u32 = 0;

        if (w.kernel32.WriteFile(
            @as(w.HANDLE, @ptrFromInt(@as(usize, @as(i32, handle)))),
            @as([*c]const u8, @intFromPtr(data.ptr)),
            @as(u32, @as(usize, data.len)),
            &bytes_written,
            null,
        ) == 0) {
            return 0;
        }

        return bytes_written;
    } else {
        return std.posix.write(handle, data) catch return 0;
    }
}

fn serialAvailable(handle: SerialHandle) usize {
    if (builtin.os.tag == .windows) {
        const w = @import("std.os.windows");
        var comm_stat: w.COMSTAT = undefined;
        var errors: u32 = 0;

        if (w.kernel32.ClearCommError(@as(w.HANDLE, @ptrFromInt(@as(usize, @as(i32, handle)))), &errors, &comm_stat) == 0) {
            return 0;
        }

        return comm_stat.cbInQue;
    } else {
        var pollfds: [1]std.posix.pollfd = undefined;
        pollfds[0].fd = handle;
        pollfds[0].events = std.posix.POLLIN;
        pollfds[0].revents = 0;

        const result = std.posix.poll(&pollfds, 100) catch return 0;

        if (result > 0 and (pollfds[0].revents & std.posix.POLLIN) != 0) {
            return 1;
        }

        return 0;
    }
}

pub fn serialPortOpen(allocator: Allocator, port: Str, baud_rate: i64) i64 {
    _ = allocator;
    const port_slice = port.asSlice();
    const baud = @as(u32, @intCast(baud_rate));

    const serial = SerialPort.open(port_slice, baud) catch return -1;
    defer serial.close();

    return @as(i64, @intFromPtr(serial.handle));
}

pub fn serialPortRead(allocator: Allocator, handle_id: i64, length: i64) Str {
    _ = allocator;
    const handle: SerialHandle = @ptrFromInt(@as(usize, @intCast(handle_id)));
    const len: usize = @intCast(length);
    return serialRead(handle, len);
}

pub fn serialPortWrite(allocator: Allocator, handle_id: i64, data: Str) i64 {
    _ = allocator;
    const handle: SerialHandle = @ptrFromInt(@as(usize, @as(i32, handle_id)));
    const data_slice = data.asSlice();
    return @as(i64, @as(usize, serialWrite(handle, data_slice)));
}

pub fn serialPortClose(handle_id: i64) void {
    const handle: SerialHandle = @ptrFromInt(@as(usize, @as(i32, handle_id)));
    serialClose(handle);
}

pub fn serialPortAvailable(handle_id: i64) i64 {
    const handle: SerialHandle = @ptrFromInt(@as(usize, @as(i32, handle_id)));
    return @as(i64, @as(usize, serialAvailable(handle)));
}

pub const Mutex = struct {
    mutex: std.Thread.Mutex,

    pub fn create(allocator: Allocator) !Mutex {
        _ = allocator;
        return Mutex{ .mutex = std.Thread.Mutex{} };
    }

    pub fn lock(self: *Mutex) void {
        self.mutex.lock();
    }

    pub fn unlock(self: *Mutex) void {
        self.mutex.unlock();
    }
};

// ============================ Queue ============================
// 线程安全的消息队列，支持 int、float、str/bytes 四种类型
// 第一次 put 的类型决定队列的类型，后续 put 必须匹配该类型

// Queue 元素类型标签
pub const QueueItemType = enum(u8) {
    Undefined = 0, // 未设置类型（队列为空时）
    Int = 1,
    Float = 2,
    Str = 3, // str
    Bytes = 4, // bytes ([]u8) - 新增
};

// Queue 元素 - 支持多种类型
pub const QueueItem = struct {
    item_type: QueueItemType = .Undefined,
    int_val: i64 = 0,
    float_val: f64 = 0,
    str_val: Str = undefined,
    bytes_val: []u8 = &[_]u8{}, // bytes 专用（新增）
    bytes_allocator: Allocator = std.heap.page_allocator, // bytes 内存管理器（新增）

    // 从 i64 创建
    pub fn fromInt(val: i64) QueueItem {
        return QueueItem{
            .item_type = .Int,
            .int_val = val,
        };
    }

    // 从 f64 创建
    pub fn fromFloat(val: f64) QueueItem {
        return QueueItem{
            .item_type = .Float,
            .float_val = val,
        };
    }

    // 从 Str 创建（str）
    pub fn fromStr(val: Str) QueueItem {
        // 克隆字符串数据，因为原始数据可能来自栈内存或会被释放
        const new_str = Str{
            .data = val.allocator.dupe(u8, val.data) catch val.data,
            .allocator = val.allocator,
            .borrowed = false,
        };
        return QueueItem{
            .item_type = .Str,
            .str_val = new_str,
        };
    }

    // 从 []u8 创建（bytes 类型专用，新增）
    // 注意：使用 page_allocator 做临时存储，put_nowait 会用 queue.allocator 重新克隆
    pub fn fromBytes(val: []u8) QueueItem {
        // 临时复制数据，因为原始数据可能来自栈内存或会被释放
        const copied = std.heap.page_allocator.dupe(u8, val) catch val;
        return QueueItem{
            .item_type = .Bytes,
            .bytes_val = copied,
            .bytes_allocator = std.heap.page_allocator,
        };
    }

    // 获取 int 值
    pub fn getInt(self: QueueItem) i64 {
        return self.int_val;
    }

    // 获取 float 值
    pub fn getFloat(self: QueueItem) f64 {
        return self.float_val;
    }

    // 获取 bytes 值 - 转移所有权（新增）
    pub fn getBytes(self: QueueItem) []u8 {
        if (self.item_type != .Bytes) {
            return &[_]u8{};
        }
        // 转移所有权：将 item_type 设为 Undefined，让外部拥有数据
        var mutable = self;
        const data = mutable.bytes_val;
        mutable.item_type = .Undefined;
        mutable.bytes_val = &[_]u8{};
        return data;
    }

    // 获取 str 值 - 按值接收，克隆数据后释放原始item
    pub fn getStr(self: QueueItem) Str {
        if (self.item_type != .Str) {
            return Str{ .data = "", .allocator = std.heap.page_allocator, .borrowed = false };
        }
        // 保存allocator
        const allocator = self.str_val.allocator;
        // 克隆数据
        const cloned_data = allocator.dupe(u8, self.str_val.data) catch {
            // 如果克隆失败，转移所有权
            const data = self.str_val.data;
            var mutable = self;
            mutable.str_val.borrowed = true;
            mutable.item_type = .Undefined;
            return Str{
                .data = data,
                .allocator = allocator,
                .borrowed = false,
            };
        };
        // 释放原始item的数据
        var mutable = self;
        mutable.str_val.deinit();
        mutable.item_type = .Undefined;
        // 返回克隆的数据
        return Str{
            .data = cloned_data,
            .allocator = allocator,
            .borrowed = false,
        };
    }

    // 释放资源（处理 Str 和 Bytes 的内存）
    pub fn deinit(self: *QueueItem) void {
        if (self.item_type == .Str) {
            self.str_val.deinit();
            self.item_type = .Undefined;
        } else if (self.item_type == .Bytes) {
            if (self.bytes_val.len > 0) {
                self.bytes_allocator.free(self.bytes_val);
            }
            self.bytes_val = &[_]u8{};
            self.item_type = .Undefined;
        }
    }
};

// Queue 结构
pub const Queue = struct {
    items: std.ArrayList(QueueItem), // 存储 QueueItem
    mutex: std.Thread.Mutex,
    maxsize: usize,
    unfinished_tasks: usize, // 未完成的任务数，用于 task_done 和 join
    item_type: QueueItemType, // 队列的元素类型（第一次 put 后确定）
    allocator: Allocator,

    pub fn init(allocator: Allocator, maxsize: usize) Queue {
        return Queue{
            .items = std.ArrayList(QueueItem).init(allocator),
            .mutex = std.Thread.Mutex{},
            .maxsize = if (maxsize == 0) 0 else maxsize, // 0 表示无限制
            .unfinished_tasks = 0,
            .item_type = .Undefined,
            .allocator = allocator,
        };
    }

    // 兼容旧版本：create
    pub fn create(allocator: Allocator, maxsize: usize) Queue {
        return Queue.init(allocator, maxsize);
    }

    // put_nowait(item) - 非阻塞放入，满时静默丢弃
    // item 可以是 i64、f64 或 Str 类型
    pub fn put_nowait(self: *Queue, item: QueueItem) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        // 检查类型一致性
        if (self.item_type == .Undefined) {
            self.item_type = item.item_type;
        } else if (self.item_type != item.item_type) {
            return; // 类型不匹配，静默丢弃
        }

        if (self.maxsize > 0 and self.items.items.len >= self.maxsize) {
            return; // 队列满，静默返回
        }

        // 对于 Str 类型，需要克隆字符串以使用队列的 allocator
        var item_copy = item;
        if (item.item_type == .Str) {
            item_copy.str_val = item.str_val.cloneWithAllocator(self.allocator) catch unreachable;
        } else if (item.item_type == .Bytes) {
            // 同样用 queue.allocator 重新克隆 bytes
            item_copy.bytes_val = self.allocator.dupe(u8, item.bytes_val) catch unreachable;
            item_copy.bytes_allocator = self.allocator;
        }

        self.items.append(item_copy) catch unreachable;
        self.unfinished_tasks += 1; // 有新任务
    }

    // put(item, timeout_ms) - 带超时的放入
    // timeout_ms: 超时时间（毫秒），0 表示非阻塞，-1 表示无限等待
    pub fn put(self: *Queue, item: QueueItem, timeout_ms: i64) void {
        // 非阻塞
        if (timeout_ms == 0) {
            self.put_nowait(item);
            return;
        }

        // 无限等待
        if (timeout_ms < 0) {
            while (true) {
                self.mutex.lock();
                // 类型不匹配时立即返回（与 put_nowait 行为一致）
                if (self.item_type == .Undefined) {
                    self.item_type = item.item_type;
                } else if (self.item_type != item.item_type) {
                    self.mutex.unlock();
                    return; // 类型不匹配，静默丢弃
                }
                if (self.item_type == item.item_type and (self.maxsize == 0 or self.items.items.len < self.maxsize)) {
                    // 对于 Str/Bytes 类型，需要克隆以使用队列的 allocator
                    var item_copy = item;
                    if (item.item_type == .Str) {
                        item_copy.str_val = item.str_val.cloneWithAllocator(self.allocator) catch unreachable;
                    } else if (item.item_type == .Bytes) {
                        item_copy.bytes_val = self.allocator.dupe(u8, item.bytes_val) catch unreachable;
                        item_copy.bytes_allocator = self.allocator;
                    }
                    self.items.append(item_copy) catch unreachable;
                    self.unfinished_tasks += 1;
                    self.mutex.unlock();
                    return;
                }
                self.mutex.unlock();
                std.time.sleep(10 * std.time.ns_per_ms); // 10ms
            }
        }

        // 带超时等待
        const end_time = std.time.nanoTimestamp() + (timeout_ms * std.time.ns_per_ms);
        while (std.time.nanoTimestamp() < end_time) {
            self.mutex.lock();
            // 类型不匹配时立即返回（与 put_nowait 行为一致）
            if (self.item_type == .Undefined) {
                self.item_type = item.item_type;
            } else if (self.item_type != item.item_type) {
                self.mutex.unlock();
                return; // 类型不匹配，静默丢弃
            }
            if (self.item_type == item.item_type and (self.maxsize == 0 or self.items.items.len < self.maxsize)) {
                // 对于 Str/Bytes 类型，需要克隆以使用队列的 allocator
                var item_copy = item;
                if (item.item_type == .Str) {
                    item_copy.str_val = item.str_val.cloneWithAllocator(self.allocator) catch unreachable;
                } else if (item.item_type == .Bytes) {
                    item_copy.bytes_val = self.allocator.dupe(u8, item.bytes_val) catch unreachable;
                    item_copy.bytes_allocator = self.allocator;
                }
                self.items.append(item_copy) catch unreachable;
                self.unfinished_tasks += 1;
                self.mutex.unlock();
                return;
            }
            self.mutex.unlock();
            std.time.sleep(10 * std.time.ns_per_ms); // 10ms
        }

        return; // 超时
    }

    // get_nowait() - 非阻塞取出，空时返回空 QueueItem
    pub fn get_nowait(self: *Queue) QueueItem {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.items.items.len == 0) {
            return QueueItem{ .item_type = .Undefined };
        }
        return self.items.orderedRemove(0);
    }

    // empty() - 检查队列是否为空
    pub fn empty(self: *Queue) bool {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.items.items.len == 0;
    }

    // full() - 检查队列是否已满
    pub fn full(self: *Queue) bool {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.maxsize == 0) return false; // 无限制队列永远不会满
        return self.items.items.len >= self.maxsize;
    }

    // qsize() - 获取队列中的元素数量
    pub fn qsize(self: *Queue) usize {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.items.items.len;
    }

    // get_maxsize() - 获取队列的最大容量
    pub fn get_maxsize(self: *Queue) usize {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.maxsize;
    }

    // task_done() - 标记一个任务完成
    pub fn task_done(self: *Queue) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.unfinished_tasks > 0) {
            self.unfinished_tasks -= 1;
        }
    }

    // join() - 等待所有任务完成
    pub fn join(self: *Queue) void {
        while (true) {
            self.mutex.lock();
            if (self.unfinished_tasks == 0) {
                self.mutex.unlock();
                break;
            }
            self.mutex.unlock();
            std.time.sleep(10 * std.time.ns_per_ms); // 10ms
        }
        // 等待所有子线程结束
        joinAllThreads();
    }

    // push - 兼容接口（非阻塞放入）
    pub fn push(self: *Queue, item: QueueItem) void {
        self.put_nowait(item);
    }

    // pop - 兼容接口（非阻塞取出）
    pub fn pop(self: *Queue) QueueItem {
        return self.get_nowait();
    }

    // size - 兼容接口
    pub fn size(self: *Queue) usize {
        return self.qsize();
    }

    // getItemType - 获取队列元素类型
    pub fn getItemType(self: *Queue) QueueItemType {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.item_type;
    }

    // deinit - 清理队列中的所有元素
    pub fn deinit(self: *Queue) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        // 释放所有元素
        for (self.items.items) |*item| {
            item.deinit();
        }
        self.items.deinit();
    }
};

pub fn atomicAdd(ptr: *i64, value: i64) i64 {
    return @atomicRmw(i64, ptr, .Add, value, .seq_cst);
}

pub fn atomicSub(ptr: *i64, value: i64) i64 {
    return @atomicRmw(i64, ptr, .Sub, value, .seq_cst);
}

pub fn atomicLoad(ptr: *i64) i64 {
    return @atomicLoad(i64, ptr, .seq_cst);
}

pub fn atomicStore(ptr: *i64, value: i64) i64 {
    @atomicStore(i64, ptr, value, .seq_cst);
    return value;
}

pub fn httpPostJson(allocator: Allocator, url: Str, body: Str) Str {
    const parsed = parseUrl(url.data);

    const stream = std.net.tcpConnectToHost(allocator, parsed.host, parsed.port) catch unreachable;
    defer stream.close();

    const content_length = std.fmt.allocPrint(allocator, "{d}", .{body.data.len}) catch unreachable;
    defer allocator.free(content_length);

    const request = std.fmt.allocPrint(allocator, "POST {s} HTTP/1.1\r\nHost: {s}\r\nContent-Type: application/json\r\nContent-Length: {s}\r\nConnection: close\r\n\r\n{s}", .{
        parsed.path,
        parsed.host,
        content_length,
        body.data,
    }) catch unreachable;
    defer allocator.free(request);

    stream.writeAll(request) catch {
        stream.close();
        return error.Timeout;
    };

    var buffer: [8192]u8 = undefined;
    const bytes_read = stream.read(&buffer) catch unreachable;
    return Str{
        .data = buffer[0..bytes_read],
        .allocator = allocator,
        .borrowed = true,
    };
}

// ============================ 音频录音和播放 ============================
// 使用ALSA C库 (libasound) 直接调用，无需外部命令

// 导入ALSA C库
const alsa = @cImport(@cInclude("alsa/asoundlib.h"));

// 录音函数：录制指定秒数的音频，返回PCM数据
// 参数: duration(秒), sample_rate(采样率), channels(声道), device_name(设备名称), chunk(缓冲大小)
pub fn recordAudio(allocator: Allocator, duration: i64, sample_rate: i64, channels: i64, device_name_str: Str, chunk: i64) Str {
    var sample_rate_uint = @as(c_uint, @intCast(sample_rate));
    const channels_uint = @as(c_uint, @intCast(channels));
    const chunk_ulong = @as(c_ulong, @intCast(chunk));

    // 将设备名称转换为 C 字符串
    var device_name: [:0]const u8 = "default";
    var device_name_buf: ?[]u8 = null;
    defer if (device_name_buf) |buf| allocator.free(buf);
    if (device_name_str.data.len > 0) {
        device_name_buf = std.fmt.allocPrintZ(allocator, "{s}", .{device_name_str.data}) catch null;
        if (device_name_buf) |buf| {
            device_name = buf[0..buf.len :0];
        }
    }

    var capture_handle: ?*alsa.snd_pcm_t = undefined;
    var params: ?*alsa.snd_pcm_hw_params_t = undefined;

    // 打开录音设备，使用指定的设备名称
    if (alsa.snd_pcm_open(@as([*c]?*alsa.snd_pcm_t, @ptrCast(&capture_handle)), @ptrCast(device_name.ptr), alsa.SND_PCM_STREAM_CAPTURE, 0) < 0) {
        @panic("Cannot open audio device for recording");
    }
    defer _ = alsa.snd_pcm_close(capture_handle);

    // 分配参数空间
    _ = alsa.snd_pcm_hw_params_malloc(@as([*c]?*alsa.snd_pcm_hw_params_t, @ptrCast(&params)));
    defer alsa.snd_pcm_hw_params_free(params);

    // 设置参数
    if (alsa.snd_pcm_hw_params_any(capture_handle, params) < 0) {
        @panic("Cannot initialize hardware parameters");
    }

    if (alsa.snd_pcm_hw_params_set_access(capture_handle, params, alsa.SND_PCM_ACCESS_RW_INTERLEAVED) < 0) {
        @panic("Cannot set access type");
    }

    if (alsa.snd_pcm_hw_params_set_format(capture_handle, params, alsa.SND_PCM_FORMAT_S16_LE) < 0) {
        @panic("Cannot set sample format");
    }

    var dir: c_int = 0;
    if (alsa.snd_pcm_hw_params_set_rate_near(capture_handle, params, @ptrCast(&sample_rate_uint), &dir) < 0) {
        @panic("Cannot set sample rate");
    }

    if (alsa.snd_pcm_hw_params_set_channels(capture_handle, params, channels_uint) < 0) {
        @panic("Cannot set channel count");
    }

    if (alsa.snd_pcm_hw_params(capture_handle, params) < 0) {
        @panic("Cannot set hardware parameters");
    }

    // 准备录音
    if (alsa.snd_pcm_prepare(capture_handle) < 0) {
        @panic("Cannot prepare audio interface for recording");
    }

    // 计算缓冲区大小
    const bytes_per_sample: c_ulong = 2; // S16_LE = 2 bytes

    // 录制指定秒数的音频
    const total_frames = @as(c_ulong, @intCast(duration)) * sample_rate_uint;
    var frames_recorded: c_ulong = 0;
    var first_read: bool = true;

    // 分配内存存储音频数据
    var audio_data = std.ArrayList(u8).init(allocator);
    defer audio_data.deinit();

    while (frames_recorded < total_frames) {
        const frames_to_read = @min(chunk_ulong, total_frames - frames_recorded);
        const bytes_to_read = frames_to_read * channels_uint * bytes_per_sample;

        // 第一次读取前启动捕捉流
        if (first_read) {
            if (alsa.snd_pcm_start(capture_handle) < 0) {
                @panic("Cannot start audio capture");
            }
            first_read = false;
        }

        audio_data.ensureTotalCapacity(audio_data.items.len + bytes_to_read) catch unreachable;
        const buffer = audio_data.addManyAsSliceAssumeCapacity(bytes_to_read);

        var frames_read: c_long = alsa.snd_pcm_readi(capture_handle, buffer.ptr, frames_to_read);
        if (frames_read < 0) {
            // 尝试恢复音频接口
            frames_read = alsa.snd_pcm_recover(capture_handle, @as(c_int, @intCast(frames_read)), 0);
            if (frames_read < 0) {
                @panic("Read from audio interface failed");
            }
        }

        // 按实际读取的帧数计算字节数
        const actual_bytes = @as(usize, @intCast(frames_read)) * channels_uint * bytes_per_sample;
        frames_recorded += @as(c_ulong, @intCast(frames_read));
        // 调整 ArrayList 的实际长度
        audio_data.items.len = audio_data.items.len - bytes_to_read + actual_bytes;
    }

    return Str{
        .data = audio_data.items,
        .allocator = allocator,
        .borrowed = false,
    };
}

// 播放函数：播放PCM数据
// 参数: data(PCM数据), sample_rate(采样率), device_name(设备名称)
pub fn playAudio(allocator: Allocator, data: Str, sample_rate: i64, device_name_str: Str) void {
    var sample_rate_uint = @as(c_uint, @intCast(sample_rate));
    const channels: c_uint = 1;

    // 将设备名称转换为 C 字符串
    var device_name: [:0]const u8 = "default";
    var device_name_buf: ?[]u8 = null;
    defer if (device_name_buf) |buf| allocator.free(buf);
    if (device_name_str.data.len > 0) {
        device_name_buf = std.fmt.allocPrintZ(allocator, "{s}", .{device_name_str.data}) catch null;
        if (device_name_buf) |buf| {
            device_name = buf[0..buf.len :0];
        }
    }

    var playback_handle: ?*alsa.snd_pcm_t = undefined;
    var params: ?*alsa.snd_pcm_hw_params_t = undefined;

    // 打开播放设备，使用指定的设备名称
    if (alsa.snd_pcm_open(@as([*c]?*alsa.snd_pcm_t, @ptrCast(&playback_handle)), @ptrCast(device_name.ptr), alsa.SND_PCM_STREAM_PLAYBACK, 0) < 0) {
        @panic("Cannot open audio device for playback");
    }
    defer _ = alsa.snd_pcm_close(playback_handle);

    // 分配参数空间
    _ = alsa.snd_pcm_hw_params_malloc(@as([*c]?*alsa.snd_pcm_hw_params_t, @ptrCast(&params)));
    defer alsa.snd_pcm_hw_params_free(params);

    // 设置参数
    if (alsa.snd_pcm_hw_params_any(playback_handle, params) < 0) {
        @panic("Cannot initialize hardware parameters");
    }

    if (alsa.snd_pcm_hw_params_set_access(playback_handle, params, alsa.SND_PCM_ACCESS_RW_INTERLEAVED) < 0) {
        @panic("Cannot set access type");
    }

    if (alsa.snd_pcm_hw_params_set_format(playback_handle, params, alsa.SND_PCM_FORMAT_S16_LE) < 0) {
        @panic("Cannot set sample format");
    }

    var dir: c_int = 0;
    if (alsa.snd_pcm_hw_params_set_rate_near(playback_handle, params, @ptrCast(&sample_rate_uint), &dir) < 0) {
        @panic("Cannot set sample rate");
    }

    if (alsa.snd_pcm_hw_params_set_channels(playback_handle, params, channels) < 0) {
        @panic("Cannot set channel count");
    }

    if (alsa.snd_pcm_hw_params(playback_handle, params) < 0) {
        @panic("Cannot set hardware parameters");
    }

    // 准备播放
    if (alsa.snd_pcm_prepare(playback_handle) < 0) {
        @panic("Cannot prepare audio interface for playback");
    }

    // 播放音频数据
    const bytes_per_sample: c_ulong = 2;

    var frames_written: c_long = 0;
    var offset: usize = 0;

    while (offset < data.data.len) {
        const frames_to_write = @min(@as(c_ulong, 1024), @as(c_ulong, @intCast(data.data.len - offset)) / (channels * bytes_per_sample));

        var frames_written_loop: c_long = alsa.snd_pcm_writei(playback_handle, data.data.ptr + offset, frames_to_write);
        if (frames_written_loop < 0) {
            // 尝试恢复音频接口
            frames_written_loop = alsa.snd_pcm_recover(playback_handle, @as(c_int, @intCast(frames_written_loop)), 0);
            if (frames_written_loop < 0) {
                @panic("Write to audio interface failed");
            }
        }

        offset += @as(usize, @intCast(frames_written_loop)) * channels * bytes_per_sample;
        frames_written += frames_written_loop;
    }

    // 等待播放完成
    _ = alsa.snd_pcm_drain(playback_handle);
}

// 保存为WAV文件
pub fn saveWav(data: Str, filename: Str, sample_rate_str: Str) void {
    const sample_rate = std.fmt.parseInt(c_uint, sample_rate_str.data, 10) catch 16000;
    const channels: c_uint = 1;
    const bits_per_sample: c_uint = 16;

    const bytes_per_sample = bits_per_sample / 8;
    const byte_rate = sample_rate * channels * bytes_per_sample;
    const block_align = channels * bytes_per_sample;
    const data_size_u32: u32 = @intCast(data.data.len);
    const file_size: u32 = 36 + data_size_u32;

    // 创建文件
    const file = std.fs.createFileAbsolute(std.mem.span(@as([*:0]const u8, @ptrCast(filename.data))), .{}) catch unreachable;
    defer file.close();

    // 写入WAV头
    var header: [44]u8 = undefined;

    // RIFF chunk descriptor
    @memcpy(header[0..4], "RIFF");
    std.mem.writeInt(u32, header[4..8], file_size, .little);
    @memcpy(header[8..12], "WAVE");

    // fmt sub-chunk
    @memcpy(header[12..16], "fmt ");
    std.mem.writeInt(u32, header[16..20], 16, .little); // SubChunk1Size (16 for PCM)
    std.mem.writeInt(u16, header[20..22], 1, .little); // AudioFormat (1 for PCM)
    std.mem.writeInt(u16, header[22..24], @intCast(channels), .little);
    std.mem.writeInt(u32, header[24..28], sample_rate, .little);
    std.mem.writeInt(u32, header[28..32], byte_rate, .little);
    std.mem.writeInt(u16, header[32..34], @intCast(block_align), .little);
    std.mem.writeInt(u16, header[34..36], bits_per_sample, .little);

    // data sub-chunk
    @memcpy(header[36..40], "data");
    std.mem.writeInt(u32, header[40..44], data_size_u32, .little);

    file.writeAll(&header) catch unreachable;
    file.writeAll(data.data) catch unreachable;
}

// ============================ Async/Coroutine Support ============================
// 协程状态
pub const TaskState = enum {
    Created,
    Running,
    Waiting,
    Ready,
    Completed,
};

// 任务上下文
pub const TaskContext = struct {
    state: TaskState,
    data: ?*anyopaque,
    continuation: ?*anyopaque,
    wait_list: std.ArrayList(*TaskContext),
    allocator: Allocator,

    pub fn init(allocator: Allocator) TaskContext {
        return TaskContext{
            .state = .Created,
            .data = null,
            .continuation = null,
            .wait_list = std.ArrayList(*TaskContext).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *TaskContext) void {
        self.wait_list.deinit();
    }

    // 等待另一个任务完成
    pub fn waitFor(self: *TaskContext, other: *TaskContext) void {
        self.state = .Waiting;
        other.wait_list.append(self) catch unreachable;
    }

    // 标记任务为就绪
    pub fn ready(self: *TaskContext) void {
        self.state = .Ready;
    }
};

// 任务函数类型
pub const TaskFunc = fn (*TaskContext, ?*anyopaque) void;

// 任务
pub const Task = struct {
    ctx: TaskContext,
    func: TaskFunc,
    arg: ?*anyopaque,
};

// 异步任务调度器
pub const AsyncScheduler = struct {
    const Self = @This();

    tasks: std.ArrayList(*Task),
    allocator: Allocator,
    current: ?*Task,

    pub fn init(allocator: Allocator) Self {
        return Self{
            .tasks = std.ArrayList(*Task).init(allocator),
            .allocator = allocator,
            .current = null,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.tasks.items) |task| {
            task.ctx.deinit();
            self.allocator.destroy(task);
        }
        self.tasks.deinit();
    }

    // 创建并启动一个任务
    pub fn spawn(self: *Self, func: TaskFunc, arg: ?*anyopaque) *Task {
        const task = self.allocator.create(Task) catch unreachable;
        task.* = .{
            .ctx = TaskContext.init(self.allocator),
            .func = func,
            .arg = arg,
        };
        task.ctx.state = .Ready;
        self.tasks.append(task) catch unreachable;
        return task;
    }

    // 当前任务让出 CPU，等待另一个任务完成
    pub fn yieldAndWait(self: *Self, other: *TaskContext) void {
        if (self.current) |current| {
            current.ctx.waitFor(other);
        }
        self.yield();
    }

    // 当前任务让出 CPU
    pub fn yield(self: *Self) void {
        _ = self;
        // 在实际实现中，这里会切换到调度器的主循环
        // 调度器会选择下一个 Ready 状态的任务执行
    }

    // 运行所有任务直到完成
    pub fn runAll(self: *Self) void {
        while (true) {
            var has_work = false;

            // 遍历所有任务
            for (self.tasks.items) |task| {
                if (task.ctx.state == .Ready or task.ctx.state == .Created) {
                    self.current = task;
                    task.ctx.state = .Running;
                    task.func(&task.ctx, task.arg);

                    // 检查是否还有任务在工作
                    if (task.ctx.state == .Running) {
                        // 任务主动让出 CPU（通过 yieldAndWait 被调用）
                        has_work = true;
                    }
                }
            }

            if (!has_work) break;
        }
        self.current = null;
    }
};

// 全局调度器实例
var globalScheduler: ?AsyncScheduler = null;

pub fn getScheduler() *AsyncScheduler {
    if (globalScheduler == null) {
        globalScheduler = AsyncScheduler.init(std.heap.page_allocator);
    }
    return &globalScheduler.?;
}

// ============================ Future-based Async ============================
// Future 用于异步操作的结果
pub const FutureState = enum {
    Pending,
    Ready,
};

// Future 类型
pub const Future = struct {
    state: FutureState,
    result: ?*anyopaque,
    channel: std.Thread.Channel(void),
    allocator: Allocator,

    pub fn init(allocator: Allocator) Future {
        return Future{
            .state = .Pending,
            .result = null,
            .channel = std.Thread.Channel(void).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Future) void {
        self.channel.deinit();
    }

    // 完成 Future，设置结果
    pub fn complete(self: *Future, result: ?*anyopaque) void {
        self.result = result;
        self.state = .Ready;
        self.channel.send() catch unreachable;
    }

    // 等待 Future 完成
    pub fn awaitFuture(self: *Future) void {
        if (self.state == .Pending) {
            self.channel.recv();
        }
    }
};

// 异步任务函数类型（无参数，无返回值）
pub const AsyncTaskFunc = fn () void;

// 在新线程中启动异步任务
pub fn asyncTaskSpawn(task_func: AsyncTaskFunc) *Future {
    const future = std.heap.page_allocator.create(Future) catch unreachable;
    future.* = Future.init(std.heap.page_allocator);

    _ = std.Thread.spawn(.{}, struct {
        fn f(tf: AsyncTaskFunc, fut: *Future) void {
            tf();
            fut.complete(null);
        }
    }.f, .{ task_func, future });

    return future;
}

// 等待所有异步任务完成
pub fn asyncJoinAll() void {
    const scheduler = getScheduler();
    scheduler.runAll();
}

// 协程状态（保留兼容）
pub const CoroutineState = enum {
    Ready,
    Running,
    Suspended,
    Completed,
};

// 协程上下文（保留兼容）
pub const Coroutine = struct {
    state: CoroutineState,
    frame: anyframe,
};

// 协程管理器（保留兼容）
pub const AsyncRuntime = struct {
    const Self = @This();

    // 协程列表
    coroutines: std.ArrayList(Coroutine),
    allocator: Allocator,

    pub fn init(allocator: Allocator) Self {
        return Self{
            .coroutines = std.ArrayList(Coroutine).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.coroutines.deinit();
    }

    // 创建协程
    pub fn spawn(self: *Self, func: anytype) *Coroutine {
        _ = func;
        const coro = self.allocator.create(Coroutine) catch unreachable;
        coro.* = .{
            .state = .Ready,
            .frame = undefined,
        };
        self.coroutines.append(coro) catch unreachable;
        return coro;
    }

    // 等待所有协程完成
    pub fn waitAll(self: *Self) void {
        _ = self;
        // 在当前实现中，协程会同步执行
        // 未来可以实现真正的异步调度
    }
};

// 获取全局异步运行时
pub fn getAsyncRuntime() *AsyncRuntime {
    return getScheduler();
}

// ============================ Time Functions ============================

// 时间结构体
pub const TimeStruct = struct {
    year: i32,
    month: i32,
    day: i32,
    hour: i32,
    minute: i32,
    second: i32,
    weekday: i32,
};

// 格式化时间字符串
pub fn strftime(allocator: Allocator, format: Str) Str {
    _ = format;
    // 使用 C 库获取本地时间
    const timestamp = std.time.timestamp();
    const ts: ctime.time_t = @intCast(timestamp);

    const tm_ptr = ctime.localtime(&ts);
    const tm = tm_ptr.*;

    // 手动格式化时间
    var buf: [32]u8 = undefined;
    var pos: usize = 0;

    // 年份 4 位
    const year = tm.tm_year + 1900;
    buf[pos] = @as(u8, @intCast(@divTrunc(year, 1000) + '0'));
    buf[pos + 1] = @as(u8, @intCast(@mod(@divTrunc(year, 100), 10) + '0'));
    buf[pos + 2] = @as(u8, @intCast(@mod(@divTrunc(year, 10), 10) + '0'));
    buf[pos + 3] = @as(u8, @intCast(@mod(year, 10) + '0'));
    pos += 4;

    buf[pos] = '-';
    pos += 1;

    // 月份 2 位
    const month = tm.tm_mon + 1;
    buf[pos] = @as(u8, @intCast(@divTrunc(month, 10) + '0'));
    buf[pos + 1] = @as(u8, @intCast(@mod(month, 10) + '0'));
    pos += 2;

    buf[pos] = '-';
    pos += 1;

    // 日期 2 位
    const day = tm.tm_mday;
    buf[pos] = @as(u8, @intCast(@divTrunc(day, 10) + '0'));
    buf[pos + 1] = @as(u8, @intCast(@mod(day, 10) + '0'));
    pos += 2;

    buf[pos] = ' ';
    pos += 1;

    // 小时 2 位
    const hour = tm.tm_hour;
    buf[pos] = @as(u8, @intCast(@divTrunc(hour, 10) + '0'));
    buf[pos + 1] = @as(u8, @intCast(@mod(hour, 10) + '0'));
    pos += 2;

    buf[pos] = ':';
    pos += 1;

    // 分钟 2 位
    const min = tm.tm_min;
    buf[pos] = @as(u8, @intCast(@divTrunc(min, 10) + '0'));
    buf[pos + 1] = @as(u8, @intCast(@mod(min, 10) + '0'));
    pos += 2;

    buf[pos] = ':';
    pos += 1;

    // 秒 2 位
    const sec = tm.tm_sec;
    buf[pos] = @as(u8, @intCast(@divTrunc(sec, 10) + '0'));
    buf[pos + 1] = @as(u8, @intCast(@mod(sec, 10) + '0'));
    pos += 2;

    return Str.init(allocator, buf[0..pos]) catch unreachable;
}

// 返回本地时间结构体
pub fn localtime() TimeStruct {
    const timestamp = std.time.timestamp();
    const ts: ctime.time_t = @intCast(timestamp);

    const tm_ptr = ctime.localtime(&ts);
    const tm = tm_ptr.*;

    return TimeStruct{
        .year = @intCast(tm.tm_year + 1900),
        .month = @intCast(tm.tm_mon + 1),
        .day = @intCast(tm.tm_mday),
        .hour = @intCast(tm.tm_hour),
        .minute = @intCast(tm.tm_min),
        .second = @intCast(tm.tm_sec),
        .weekday = @intCast(tm.tm_wday),
    };
}

// 返回 UTC 时间结构体
pub fn gmtime() TimeStruct {
    const timestamp = std.time.timestamp();
    const ts: ctime.time_t = @intCast(timestamp);

    const tm_ptr = ctime.gmtime(&ts);
    const tm = tm_ptr.*;

    return TimeStruct{
        .year = @intCast(tm.tm_year + 1900),
        .month = @intCast(tm.tm_mon + 1),
        .day = @intCast(tm.tm_mday),
        .hour = @intCast(tm.tm_hour),
        .minute = @intCast(tm.tm_min),
        .second = @intCast(tm.tm_sec),
        .weekday = @intCast(tm.tm_wday),
    };
}

// 将时间戳转换为 TimeStruct（本地时间）
pub fn timestamp_to_struct(timestamp: f64) TimeStruct {
    // 如果 timestamp > 10^10，认为是毫秒级的时间戳，转换为秒
    const ts_float = if (timestamp > 10000000000.0) timestamp / 1000.0 else timestamp;
    const ts: ctime.time_t = @intCast(@as(i64, @intFromFloat(ts_float)));

    const tm_ptr = ctime.localtime(&ts);
    const tm = tm_ptr.*;

    return TimeStruct{
        .year = @intCast(tm.tm_year + 1900),
        .month = @intCast(tm.tm_mon + 1),
        .day = @intCast(tm.tm_mday),
        .hour = @intCast(tm.tm_hour),
        .minute = @intCast(tm.tm_min),
        .second = @intCast(tm.tm_sec),
        .weekday = @intCast(tm.tm_wday),
    };
}

// 将时间戳按指定格式转换为字符串
pub fn strftime_timestamp(allocator: Allocator, timestamp: f64, format: Str) Str {
    // 如果 timestamp > 10^10，认为是毫秒级的时间戳，转换为秒
    const ts_float = if (timestamp > 10000000000.0) timestamp / 1000.0 else timestamp;
    const ts: ctime.time_t = @intCast(@as(i64, @intFromFloat(ts_float)));

    const tm_ptr = ctime.localtime(&ts);
    const tm = tm_ptr.*;

    // 使用固定缓冲区
    var buf: [64]u8 = undefined;
    var pos: usize = 0;

    const fmt = format.data;
    var i: usize = 0;
    while (i < fmt.len) {
        if (i + 1 < fmt.len and fmt[i] == '%') {
            const c = fmt[i + 1];
            if (c == 'Y') {
                const n: i32 = tm.tm_year + 1900;
                const n0: u32 = @intCast(@divTrunc(n, 1000));
                const n1: u32 = @intCast(@mod(@divTrunc(n, 100), 10));
                const n2: u32 = @intCast(@mod(@divTrunc(n, 10), 10));
                const n3: u32 = @intCast(@mod(n, 10));
                buf[pos] = @as(u8, @intCast(n0 + '0'));
                buf[pos + 1] = @as(u8, @intCast(n1 + '0'));
                buf[pos + 2] = @as(u8, @intCast(n2 + '0'));
                buf[pos + 3] = @as(u8, @intCast(n3 + '0'));
                pos += 4;
                i += 2;
            } else if (c == 'm') {
                const n: i32 = tm.tm_mon + 1;
                buf[pos] = @as(u8, @intCast(@divTrunc(n, 10) + '0'));
                buf[pos + 1] = @as(u8, @intCast(@mod(n, 10) + '0'));
                pos += 2;
                i += 2;
            } else if (c == 'd') {
                const n: i32 = tm.tm_mday;
                buf[pos] = @as(u8, @intCast(@divTrunc(n, 10) + '0'));
                buf[pos + 1] = @as(u8, @intCast(@mod(n, 10) + '0'));
                pos += 2;
                i += 2;
            } else if (c == 'H') {
                const n: i32 = tm.tm_hour;
                buf[pos] = @as(u8, @intCast(@divTrunc(n, 10) + '0'));
                buf[pos + 1] = @as(u8, @intCast(@mod(n, 10) + '0'));
                pos += 2;
                i += 2;
            } else if (c == 'M') {
                const n: i32 = tm.tm_min;
                buf[pos] = @as(u8, @intCast(@divTrunc(n, 10) + '0'));
                buf[pos + 1] = @as(u8, @intCast(@mod(n, 10) + '0'));
                pos += 2;
                i += 2;
            } else if (c == 'S') {
                const n: i32 = tm.tm_sec;
                buf[pos] = @as(u8, @intCast(@divTrunc(n, 10) + '0'));
                buf[pos + 1] = @as(u8, @intCast(@mod(n, 10) + '0'));
                pos += 2;
                i += 2;
            } else {
                buf[pos] = fmt[i];
                pos += 1;
                i += 1;
            }
        } else {
            buf[pos] = fmt[i];
            pos += 1;
            i += 1;
        }
    }

    return Str.init(allocator, buf[0..pos]) catch unreachable;
}

// 将 TimeStruct 转换为时间戳（float）
pub fn mktime(ts: TimeStruct) f64 {
    var tm: ctime.struct_tm = undefined;
    tm.tm_year = @intCast(ts.year - 1900);
    tm.tm_mon = @intCast(ts.month - 1);
    tm.tm_mday = @intCast(ts.day);
    tm.tm_hour = @intCast(ts.hour);
    tm.tm_min = @intCast(ts.minute);
    tm.tm_sec = @intCast(ts.second);
    tm.tm_wday = @intCast(ts.weekday);
    tm.tm_yday = 0;
    tm.tm_isdst = 0;

    const result = ctime.mktime(&tm);
    return @as(f64, @floatFromInt(result));
}

// 将浮点数转换为字符串，去除末尾的零
pub fn floatToString(allocator: Allocator, value: f64) *Str {
    // 使用高精度格式化（保留15位小数），避免丢失精度，f64最大精度约15-17位
    const float_str = std.fmt.allocPrint(allocator, "{d:.15}", .{value}) catch unreachable;
    defer allocator.free(float_str);

    // 查找小数点位置
    var dot_pos: ?usize = null;
    for (float_str, 0..) |ch, i| {
        if (ch == '.') {
            dot_pos = i;
            break;
        }
    }

    // 只有在小数点后才修剪尾部零
    var end_idx: usize = float_str.len;
    if (dot_pos != null) {
        const dot_idx = dot_pos.?;

        // 从字符串末尾向前修剪小数点后的零
        while (end_idx > dot_idx + 1) { // 至少保留小数点后一位
            if (float_str[end_idx - 1] != '0') {
                break;
            }
            end_idx -= 1;
        }

        // 如果小数点后全为零，移除小数点
        if (end_idx == dot_idx + 1) {
            end_idx = dot_idx; // 移除小数点
        }
    }

    const result = allocator.create(Str) catch unreachable;
    result.* = Str.init(allocator, float_str[0..end_idx]) catch unreachable;
    return result;
}

// 将浮点数格式化为指定小数位数的字符串（用于 round 函数的双参数版本）
pub fn roundFloat(allocator: Allocator, value: f64, ndigits: i32) *Str {
    // 使用固定缓冲区格式化浮点数
    var buf: [64]u8 = undefined;
    const abs_ndigits = @as(u32, @intCast(@abs(ndigits)));

    // 根据 ndigits 使用不同的格式
    var float_str: []u8 = undefined;
    if (abs_ndigits == 0) {
        float_str = std.fmt.bufPrint(&buf, "{d:.0}", .{value}) catch "";
    } else if (abs_ndigits == 1) {
        float_str = std.fmt.bufPrint(&buf, "{d:.1}", .{value}) catch "";
    } else if (abs_ndigits == 2) {
        float_str = std.fmt.bufPrint(&buf, "{d:.2}", .{value}) catch "";
    } else if (abs_ndigits == 3) {
        float_str = std.fmt.bufPrint(&buf, "{d:.3}", .{value}) catch "";
    } else if (abs_ndigits == 4) {
        float_str = std.fmt.bufPrint(&buf, "{d:.4}", .{value}) catch "";
    } else if (abs_ndigits == 5) {
        float_str = std.fmt.bufPrint(&buf, "{d:.5}", .{value}) catch "";
    } else if (abs_ndigits == 6) {
        float_str = std.fmt.bufPrint(&buf, "{d:.6}", .{value}) catch "";
    } else {
        float_str = std.fmt.bufPrint(&buf, "{d:.10}", .{value}) catch "";
    }

    const result = allocator.create(Str) catch unreachable;
    result.* = Str.init(allocator, float_str) catch unreachable;
    return result;
}

// ============================ ShutdownEvent (优雅关闭事件) ============================
// 类似于 Python 的 asyncio.Event，用于信号处理和优雅关闭

const ShutdownEvent = struct {
    mutex: std.Thread.Mutex,
    is_set: bool,

    pub fn init() ShutdownEvent {
        return ShutdownEvent{
            .mutex = std.Thread.Mutex{},
            .is_set = false,
        };
    }

    pub fn set(self: *ShutdownEvent) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.is_set = true;
    }

    pub fn isSet(self: *ShutdownEvent) bool {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.is_set;
    }

    pub fn waitTimeout(self: *ShutdownEvent, timeout_ns: u64) bool {
        // 等待直到事件被设置或超时
        const start = std.time.nanoTimestamp();
        while (true) {
            self.mutex.lock();
            if (self.is_set) {
                self.mutex.unlock();
                return true;
            }
            self.mutex.unlock();

            // 检查是否超时
            const elapsed = @as(u64, @intCast(std.time.nanoTimestamp() - start));
            if (elapsed >= timeout_ns) {
                return false;
            }

            // 短暂睡眠避免忙等待
            std.time.sleep(@min(10_000_000, timeout_ns - elapsed)); // 10ms 或剩余时间
        }
    }
};

// 全局关闭事件
var shutdown_event_impl: ShutdownEvent = undefined;

// 初始化关闭事件（必须在 main 开始前调用）
pub fn initShutdownEvent() void {
    shutdown_event_impl = ShutdownEvent.init();
}

// 设置关闭事件（相当于 Python 的 event.set()）
pub fn setShutdownEvent() void {
    shutdown_event_impl.set();
}

// 检查关闭事件是否被设置（相当于 Python 的 event.is_set()）
pub fn isShutdownEventSet() bool {
    return shutdown_event_impl.isSet();
}

// 等待关闭事件（相当于 Python 的 event.wait()）
// 返回 true 表示事件被设置，false 表示超时
pub fn waitShutdownEvent(timeout_ns: u64) bool {
    return shutdown_event_impl.waitTimeout(timeout_ns);
}

// 阻止关闭事件（用于线程中检查）
pub fn shutdownRequested() bool {
    return shutdown_event_impl.isSet();
}

// ============================ Config (配置文件解析) ============================
// 类似于 Python 的 configparser，支持 INI 格式配置文件

pub const Config = struct {
    const Self = @This();

    // 使用嵌套结构存储配置：[section] -> key -> value
    sections: std.StringHashMap(std.StringHashMap([]const u8)),

    pub fn init() Self {
        return Self{
            .sections = std.StringHashMap(std.StringHashMap([]const u8)).init(std.heap.page_allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        var section_iter = self.sections.iterator();
        while (section_iter.next()) |section| {
            section.value_ptr.deinit();
        }
        self.sections.deinit();
    }

    // 解析 INI 格式配置文件
    pub fn load(self: *Self, filename: []const u8) bool {
        const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
            printFileError(filename, err, "Config.load");
            return false;
        };
        defer file.close();

        const stat = file.stat() catch return false;
        const content = file.readToEndAlloc(std.heap.page_allocator, stat.size) catch return false;
        defer std.heap.page_allocator.free(content);

        var current_section: ?*std.StringHashMap([]const u8) = null;

        var lines_iter = std.mem.splitScalar(u8, content, '\n');
        while (lines_iter.next()) |line| {
            // 去除行尾空白
            const trimmed = std.mem.trim(u8, line, " \t\r");

            // 跳过空行和注释
            if (trimmed.len == 0 or trimmed[0] == '#' or trimmed[0] == ';') {
                continue;
            }

            // 检查是否是 section 头 [section_name]
            if (trimmed.len > 2 and trimmed[0] == '[' and trimmed[trimmed.len - 1] == ']') {
                const section_name = trimmed[1 .. trimmed.len - 1];
                // 复制字符串，因为 content 会在函数结束时被释放
                const section_name_copy = std.heap.page_allocator.dupe(u8, section_name) catch continue;
                const section_ptr = self.sections.getOrPut(section_name_copy) catch continue;
                if (!section_ptr.found_existing) {
                    section_ptr.value_ptr.* = std.StringHashMap([]const u8).init(std.heap.page_allocator);
                }
                current_section = section_ptr.value_ptr;
                continue;
            }

            // 解析 key=value
            if (current_section) |section| {
                if (std.mem.indexOfScalar(u8, trimmed, '=')) |eq_pos| {
                    const key = std.mem.trim(u8, trimmed[0..eq_pos], " \t");
                    const value = std.mem.trim(u8, trimmed[eq_pos + 1 ..], " \t");
                    // 复制字符串，因为 content 会在函数结束时被释放
                    const key_copy = std.heap.page_allocator.dupe(u8, key) catch continue;
                    const value_copy = std.heap.page_allocator.dupe(u8, value) catch continue;
                    section.put(key_copy, value_copy) catch continue;
                }
            }
        }

        return true;
    }

    // 获取字符串值
    pub fn getStr(self: *Self, section: Str, key: Str) []const u8 {
        const s = self.sections.get(section.data) orelse return "";
        return s.get(key.data) orelse "";
    }

    // 获取整数值
    pub fn getInt(self: *Self, section: Str, key: Str, default: i64) i64 {
        const value = self.getStr(section, key);
        if (value.len == 0) return default;
        return std.fmt.parseInt(i64, value, 10) catch default;
    }

    // 获取浮点数值
    pub fn getFloat(self: *Self, section: Str, key: Str, default: f64) f64 {
        const value = self.getStr(section, key);
        if (value.len == 0) return default;
        return std.fmt.parseFloat(f64, value) catch default;
    }

    // 检查键是否存在
    pub fn hasKey(self: *Self, section: Str, key: Str) bool {
        const s = self.sections.get(section.data) orelse return false;
        return s.contains(key.data);
    }
};

// ============================ Config 构造函数 ============================
// 全局构造函数：config(filename)
pub fn newConfig(filename: Str) *Config {
    const cfg = std.heap.page_allocator.create(Config) catch unreachable;
    cfg.* = Config.init();
    _ = cfg.load(filename.data);
    return cfg;
}

// 创建并加载配置文件
pub fn loadConfig(filename: Str) *Config {
    const config = std.heap.page_allocator.create(Config) catch unreachable;
    config.* = Config.init();
    _ = config.load(filename.data);
    return config;
}

// ============================ TCPSocket 构造函数 ============================
// 全局构造函数：tcpsocket()
pub fn newTCPSocket() *TCPSocket {
    const sock = std.heap.page_allocator.create(TCPSocket) catch unreachable;
    sock.* = TCPSocket.create(std.heap.page_allocator) catch unreachable;
    return sock;
}

// ============================ UDPSocket 构造函数 ============================
// 全局构造函数：udpsocket()
pub fn newUDPSocket() *UDPSocket {
    const sock = std.heap.page_allocator.create(UDPSocket) catch unreachable;
    sock.* = UDPSocket.create(std.heap.page_allocator) catch unreachable;
    return sock;
}

// ============================ __cb_key_exists 辅助函数 ============================
// 用于 in 运算符：检查 dict 中是否存在指定 key
// 使用 anytype 支持任意 dict 类型（Dict(Str, i64)、Dict(Str, JsonValue) 等）
pub fn __cb_key_exists(dict: anytype, key: Str) bool {
    // comptime 检查 dict 类型是否有 contains 方法
    return @hasField(@TypeOf(dict), "map") and dict.contains(key);
}

// ============================ listContains 辅助函数 ============================
// 用于 in 运算符：检查 list 中是否存在指定元素
pub fn listContains(l: List(JsonValue), item: JsonValue) bool {
    for (l.items.items) |val| {
        if (val.eql(item)) {
            return true;
        }
    }
    return false;
}
