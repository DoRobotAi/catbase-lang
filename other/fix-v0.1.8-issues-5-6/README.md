# Workaround fix for issues #5 and #6 (v0.1.8)

This directory ships a **workaround fix** (a Zig-invocation shim) for two
compiler bugs found in the official `catbase v0.1.8` build:

- #5 — f-string containing escape sequences (`\n`, `\t`, `\"`, ...) always fails
  to compile (`string literal contains invalid byte: '\n'`)
- #6 — index assignment on a struct's dict field (`s.counts["b"] = 2`) fails with
  `expected type '*Dict', found '*const Dict'`

The `catcc` binary is closed-source (no `.go` files are published), so these
cannot be fixed in the compiler itself from outside. Both bugs, however, are
purely **code-generation defects**: the generated `.zig` is wrong, not the
runtime. The shim below repairs the generated `.zig` right before the real
Zig compiler runs, without touching the `catcc` binary.

## How it works

`catcc` invokes the Zig compiler as `<[zig] path>/zig ...` (the directory
configured in `conf/config.conf`). We point that setting at a wrapper script
which post-processes every generated `*.zig` file, then forwards to the real
`zig`.

```
.cat → catcc → runtime/<name>.zig → fixzig.pl → real zig → binary
```

### Fix 1 (issue #5) — f-string escapes

`catcc` emits f-string format text into Zig string literals **without
re-escaping**: raw `\n`/`\t`/`\r` bytes, raw `"` and invalid single-backslash
sequences land directly in the literal. `fixzig.pl` re-escapes **only** the
`initFmt(...)` / `initFmtWithStrip(...)` format-string literals:

- raw control bytes → `\n` `\t` `\r`
- raw `"` → `\"`
- invalid escape sequences (e.g. `\d`) → `\\d` (literal backslash, matching
  Python semantics)
- already-valid escapes (`\n`, `\\`, `\"`) are preserved unchanged

All other string literals in the generated file are left untouched, so
existing format specs (`:.2f`, `:5d`, `:<5d`, `:0>5d`, ...) keep working.

### Fix 2 (issue #6) — struct dict-field index assignment

`catcc` generates struct local variables as `const s: State = State{...}`.
A later `s.counts["b"] = 2` (lowered to `s.counts.put(...)`) then receives a
`*const Dict` receiver and fails to compile. `fixzig.pl` rewrites
function-body-level declarations of the form

```zig
const s: State = State{
```

to

```zig
var s: State = State{
```

which keeps container fields mutable. Inner `blk:`/label consts and genuine
non-struct `const` bindings are not matched, so nothing else changes.

## Install

```bash
mkdir -p /tmp/cbshim/bin
cp other/fix-v0.1.8-issues-5-6/bin/zig /tmp/cbshim/bin/zig
chmod +x /tmp/cbshim/bin/zig
cp other/fix-v0.1.8-issues-5-6/fixzig.pl /tmp/cbshim/fixzig.pl
# conf/config.conf:
#   [zig] path = /usr/local/zig   →   path = /tmp/cbshim/bin
```

(`fixzig.pl` must sit next to `bin/`; the shim locates it via its own path.)

## Verification

Host (Debian 13 x86_64, Zig 0.14.1) **and** Docker (`catbase-sandbox`,
bind-mounted `/root/catbase`, `/usr/local/zig`, shim dir): both issue
repros now compile and run:

```
bug1: print(f"hi {name}\n")  → hi cat + newline
bug2: s.counts["b"] = 2      → {"a":1} then {"a":1,"b":2}
```

Regression: a 60+ case suite (match guards, `any`/`is`, `set[T]`, struct
defaults, banker's `round`, integer literals, default args, static checker,
...) shows a failure set **identical** to the pre-fix baseline — zero
regressions. f-string format specs, plain-string escapes, `dict.put()`,
local dict/list index assignment and struct list-field assignment are
unaffected. Nested-struct mixed mutation (`tests/fixmix.cat`) works:
`o.inner.m["b"]=3`, `.put()`, `o.inner.xs[0]=10`.

`tests/` contains the two minimal repros plus the regression programs used.

## Note for maintainers (root cause in the compiler)

- **#5**: the f-string expander (in `genFString` / `parseFStringInnerExpr`
  territory) should `unescape` text segments when lexing, and **re-escape**
  them when emitting the Zig format literal — currently the unescaped text is
  written raw into the literal.
- **#6**: struct instances are uniformly emitted as Zig `const`; mutable
  container fields then get `*const` receivers. Emitting struct bindings as
  `var` (as it already does for local dicts/lists) fixes it at the source.
  A related symptom: `meta: dict[str,int] = {"a": 1}` as a struct-field
  default is rejected with `dict[str, int]` vs `dict[str,int]` "mismatch" —
  the type printer/compare inserts a space only in one of the two spellings.
- **New related bug found while verifying**: index assignment on a struct's
  dict field inside a function **other than `main`** drops the receiver
  prefix entirely — `c.d["k"] = 5` in `def makeC()` generates
  `_ = d.put(...)` instead of `_ = c.d.put(...)`
  (`use of undeclared identifier 'd'`). Repro: `tests/spdT_repro.cat`.
