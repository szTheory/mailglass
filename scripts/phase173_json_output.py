#!/usr/bin/env python3
"""Write JSON under a trusted root using held directory descriptors."""

import errno
import json
import os
import secrets
import stat
import sys


def require_secure_primitives():
    required_flags = ("O_DIRECTORY", "O_NOFOLLOW")
    if any(not hasattr(os, flag) for flag in required_flags):
        raise RuntimeError("Secure JSON output requires O_DIRECTORY and O_NOFOLLOW")
    if os.open not in os.supports_dir_fd or os.stat not in os.supports_dir_fd or os.mkdir not in os.supports_dir_fd:
        raise RuntimeError("Secure JSON output requires directory-relative open and stat")
    # CPython reports os.rename (the same underlying renameat capability) in
    # supports_dir_fd, while os.replace's equivalent keyword support is not
    # listed there on some platforms.
    if os.rename not in os.supports_dir_fd:
        raise RuntimeError("Secure JSON output requires directory-relative atomic replace")
    if os.unlink not in os.supports_dir_fd:
        raise RuntimeError("Secure JSON output requires directory-relative unlink")
    if os.stat not in os.supports_follow_symlinks:
        raise RuntimeError("Secure JSON output requires no-follow stat")


def normalized_absolute(value):
    return os.path.normpath(os.path.abspath(value))


def open_directory_chain(absolute_path, start_fd):
    current_fd = os.dup(start_fd)
    try:
        for component in absolute_path.split(os.sep):
            if not component:
                continue
            next_fd = os.open(
                component,
                os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                dir_fd=current_fd,
            )
            os.close(current_fd)
            current_fd = next_fd
        return current_fd
    except Exception:
        os.close(current_fd)
        raise


def open_or_create_directory_chain(relative_path, start_fd):
    current_fd = os.dup(start_fd)
    try:
        for component in relative_path.split(os.sep):
            if not component or component == ".":
                continue
            if component == "..":
                raise RuntimeError("Directory path cannot escape its trusted root")
            try:
                next_fd = os.open(
                    component,
                    os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                    dir_fd=current_fd,
                )
            except FileNotFoundError:
                try:
                    os.mkdir(component, 0o700, dir_fd=current_fd)
                except FileExistsError:
                    # A concurrent creator may have won; the no-follow open
                    # below still verifies that it created a real directory.
                    pass
                next_fd = os.open(
                    component,
                    os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                    dir_fd=current_fd,
                )
            os.close(current_fd)
            current_fd = next_fd
        return current_fd
    except Exception:
        os.close(current_fd)
        raise


def open_directory_from_root(absolute_path, root_fd):
    relative = os.path.relpath(absolute_path, os.sep)
    return open_directory_chain(relative, root_fd)


def write_json(output_path, trusted_root, payload):
    require_secure_primitives()
    root_path = normalized_absolute(trusted_root)
    destination = normalized_absolute(output_path)
    parent_path, basename = os.path.split(destination)
    if not basename or basename in (".", ".."):
        raise RuntimeError("JSON evidence destination must be a file path")
    if os.path.commonpath((root_path, parent_path)) != root_path:
        raise RuntimeError(f"JSON evidence parent escapes its trusted root: {parent_path}")

    root_anchor = os.open(os.sep, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    root_fd = None
    parent_fd = None
    temporary = None
    file_fd = None
    try:
        # Ancestors of the configured trust anchor may be platform aliases
        # (for example, /var -> /private/var on macOS). Resolve only that
        # anchor, then enforce no-follow for every path component below it.
        root_fd = open_directory_from_root(os.path.realpath(root_path), root_anchor)
        parent_relative = os.path.relpath(parent_path, root_path)
        parent_fd = open_or_create_directory_chain(parent_relative, root_fd)

        try:
            existing = os.stat(basename, dir_fd=parent_fd, follow_symlinks=False)
        except FileNotFoundError:
            existing = None
        if existing is not None and not stat.S_ISREG(existing.st_mode):
            raise RuntimeError(f"JSON evidence destination is not a regular file: {destination}")

        for _ in range(8):
            temporary = f".{basename}.{os.getpid()}.{secrets.token_hex(8)}.tmp"
            try:
                file_fd = os.open(
                    temporary,
                    os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                    0o600,
                    dir_fd=parent_fd,
                )
                break
            except FileExistsError:
                temporary = None
        if file_fd is None:
            raise RuntimeError("Could not allocate a unique temporary JSON file")

        with os.fdopen(file_fd, "w", encoding="utf-8") as output:
            file_fd = None
            output.write(payload)
            output.flush()
            os.fsync(output.fileno())

        # Both names resolve relative to the same held, verified directory.
        os.replace(temporary, basename, src_dir_fd=parent_fd, dst_dir_fd=parent_fd)
        temporary = None
        os.fsync(parent_fd)
    finally:
        if file_fd is not None:
            os.close(file_fd)
        if temporary is not None and parent_fd is not None:
            try:
                os.unlink(temporary, dir_fd=parent_fd)
            except FileNotFoundError:
                pass
        if parent_fd is not None:
            os.close(parent_fd)
        if root_fd is not None:
            os.close(root_fd)
        os.close(root_anchor)


def write_file_exclusive(output_path, trusted_root, content):
    require_secure_primitives()
    root_path = normalized_absolute(trusted_root)
    destination = normalized_absolute(output_path)
    parent_path, basename = os.path.split(destination)
    if not basename or basename in (".", ".."):
        raise RuntimeError("File destination must be a file path")
    if os.path.commonpath((root_path, parent_path)) != root_path:
        raise RuntimeError(f"File destination parent escapes its trusted root: {parent_path}")

    root_anchor = os.open(os.sep, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    root_fd = None
    parent_fd = None
    file_fd = None
    try:
        root_fd = open_directory_from_root(os.path.realpath(root_path), root_anchor)
        parent_relative = os.path.relpath(parent_path, root_path)
        parent_fd = open_or_create_directory_chain(parent_relative, root_fd)
        file_fd = os.open(
            basename,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
            0o600,
            dir_fd=parent_fd,
        )
        with os.fdopen(file_fd, "wb") as output:
            file_fd = None
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
        os.fsync(parent_fd)
    finally:
        if file_fd is not None:
            os.close(file_fd)
        if parent_fd is not None:
            os.close(parent_fd)
        if root_fd is not None:
            os.close(root_fd)
        os.close(root_anchor)


if __name__ == "__main__":
    if len(sys.argv) not in (3, 4):
        raise SystemExit("usage: phase173_json_output.py TRUSTED_ROOT OUTPUT_PATH [--exclusive-file]")
    try:
        if len(sys.argv) == 4 and sys.argv[3] == "--exclusive-file":
            write_file_exclusive(sys.argv[2], sys.argv[1], sys.stdin.buffer.read())
        elif len(sys.argv) == 3:
            data = sys.stdin.read()
            json.loads(data)
            write_json(sys.argv[2], sys.argv[1], data)
        else:
            raise RuntimeError("unknown secure output mode")
    except (OSError, ValueError, RuntimeError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
