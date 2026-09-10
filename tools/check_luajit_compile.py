#!/usr/bin/env python3
"""Compile production Lua files with Lupa's LuaJIT 2.1 backend.

Fengari and newer Lua runtimes accept functions with more upvalues than the
LuaJIT 5.1 runtime used by the game. This check catches production-only parser
limits such as "function has more than 60 upvalues" before packaging a build.
"""

from __future__ import annotations

from pathlib import Path
import sys


def main() -> int:
    try:
        from lupa.luajit21 import LuaRuntime
    except ImportError:
        print(
            "error: Lupa with the luajit21 backend is required; install the "
            "development-only 'lupa' Python package",
            file=sys.stderr,
        )
        return 2

    root = Path(__file__).resolve().parents[1]
    files = [root / "main.lua", *sorted((root / "lib").rglob("*.lua"))]
    lua = LuaRuntime(unpack_returned_tuples=True)
    compile_lua = lua.eval(
        "function(src, name) local f, e = loadstring(src, name); "
        "return f ~= nil, e end"
    )

    failures: list[tuple[Path, str]] = []
    for path in files:
        source = path.read_text(encoding="utf-8")
        ok, error = compile_lua(source, "@" + path.relative_to(root).as_posix())
        if not ok:
            failures.append((path.relative_to(root), str(error)))

    if failures:
        for path, error in failures:
            print(f"FAIL {path}: {error}", file=sys.stderr)
        return 1

    print(f"{len(files)} production Lua files compile under LuaJIT 2.1")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
