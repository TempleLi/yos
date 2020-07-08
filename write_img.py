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

    # compile kernel
    kernel = "kernel.asm"
    if not os.path.exists(kernel):
        print("kernel file %s not exist" % kernel)
        return
    code = subprocess.call(["nasm", "-f", "elf", "kernel.asm", "-o", "kernel.o"])
    if code != 0:
        print("compile kernel.asm fail")
        return
    code = subprocess.call(["ld", "-m", "elf_i386", "-Ttext", "0x30400", "-s", "kernel.o", "-o", "kernel.bin"])
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


if __name__ == "__main__":
    main()
