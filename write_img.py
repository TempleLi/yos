#!/bin/sh

import os
import subprocess

segment = 512
out_file = "a.img"


def main():
    # check file exist
    files = ["boot.asm", "loader.asm"]
    bins = []

    subprocess.call(["cp", "backup.img", "a.img"])

    for f in files:
        if not os.path.exists(f):
            print("file %s not exist" % (f,))
            return
        out = f.replace(".asm", ".bin", 1)
        bins.append(out)
        if os.path.exists(out):
            print("remove file %s" % (out,))
            os.remove(out)
        code = subprocess.call(["nasm", f, "-o", out])
        if code != 0:
            print("compile %s fail" % (code,))
            return

    kds = ["kernel.asm", "string.asm", "start.c", "kliba.asm"]
    ops = []
    for f in kds:
        if f.endswith(".c"):
            ops.append(f.replace(".c", ".o", 1))
            code = subprocess.call(["gcc", "-m32", "-c", "-o", f.replace(".c", ".o", 1), f])
            if code != 0:
                return
        else:
            ops.append(f.replace(".asm", ".o", 1))
            code = subprocess.call(["nasm", "-f", "elf", "-o", f.replace(".asm", ".o", 1), f], )
            if code != 0:
                return
    print(ops)
    code = subprocess.call(["ld", "-s", "-m", "elf_i386", "-Ttext", "0x30400", "-o", "kernel.bin"] + ops)
    if code != 0:
        print("link kernel fail")
        return
    bins.append("kernel.bin")
    offset = 0
    # do not truncate the origin img file
    # copy from the internet
    for f in bins:
        with open(f, "rb") as rf:
            bs = rf.read()
            if len(bs) <= 0:
                print("warning! %s: file size is 0" % (f,))
                continue
            with os.fdopen(os.open(out_file, os.O_RDWR | os.O_CREAT), 'rb+') as wf:
                wf.seek(offset)
                wf.write(bs)
                print("%s write %d bytes to a.img at offset %d " % (f, len(bs), offset))
                offset += 512 * 10  # 默认10个扇区,一个byte 8个字节
    print("mission complete")
    # remove tmp file
    # subprocess.call(["rm", "*.o"])
    # subprocess.call(["rm", "*.bin"])


if __name__ == "__main__":
    main()
