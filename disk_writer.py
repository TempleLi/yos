# !/bin/sh

import os
import argparse


def main():
    parser = argparse.ArgumentParser(description="将一二进制文件写入软盘中（仅仅是二进制数据，没有维护文件结构）")
    parser.add_argument("-bin", type=str, help="the binary file that will be write to disk", required=True)
    parser.add_argument("-image", default="a.img", help="the disk that we will write to")
    parser.add_argument("-offset", type=int, default=0, help="the offset in segments(512bytes)")
    args = parser.parse_args()
    with open(args.bin, "rb") as rf:
        bs = rf.read()
        if len(bs) <= 0:
            raise Exception("warning! %s: file size is 0" % (args.bin,))
        with os.fdopen(os.open(args.image, os.O_RDWR | os.O_CREAT), 'rb+') as wf:
            image_size = os.path.getsize(args.image)
            require_size = len(bs) + args.offset * 512
            if image_size < require_size:
                raise Exception("warning! the image size is insufficient,current=%d,requires=%d", image_size,
                                require_size)
            wf.seek(args.offset * 512)
            wf.write(bs)
            ok = True
            print("write %d bytes from %s to a.img at offset %d (512)" % (len(bs), args.bin, args.offset))


if __name__ == "__main__":
    main()
