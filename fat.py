# !/bin/sh
# 显示elf文件的信息
# reference orange's for more detail description
# you could also use 'readelf' to show more detail information about elf file
import sys
import os


# 无符号中等大小整数
def read_half(ba, p):
    bs = ba[p:p + 2]
    return int.from_bytes(bs, "little", signed=False), p + 2


# 无符号程序地址
def read_address(ba, p):
    bs = ba[p:p + 4]
    return int.from_bytes(bs, "little", signed=False), p + 4


# 无符号偏移
def read_offset(ba, p):
    bs = ba[p:p + 4]
    return int.from_bytes(bs, "little", signed=False), p + 4


# 有符号 int
def read_sign_word(ba, p):
    bs = ba[p:p + 4]
    return int.from_bytes(bs, "little", signed=True), p + 4


# 无符号int
def read_word(ba, p):
    bs = ba[p:p + 4]
    return int.from_bytes(bs, "little", signed=False), p + 4


# 无符号byte
def read_unsigned_char(ba, p):
    bs = ba[p:p + 1]
    return int.from_bytes(bs, "little", signed=False), p + 1


# 读取字节数组
def read_bytes(ba, p, n):
    return list(ba[p:p + n]), p + n


# ELF Header
class ElfHeader:
    def __init__(self, ba: bytes):
        p = 0
        self.e_indent, p = read_bytes(ba, p, 16)  # 0
        self.e_type, p = read_half(ba, p)  # 16
        self.e_machine, p = read_half(ba, p)  # 18
        self.e_version, p = read_word(ba, p)  # 20
        self.e_entry, p = read_address(ba, p)  # 24
        self.e_phoff, p = read_offset(ba, p)  # 28 0x1c
        self.e_shoff, p = read_offset(ba, p)  # 32
        self.e_flag, p = read_word(ba, p)  # 36
        self.e_ehsize, p = read_half(ba, p)  # 40
        self.e_phentsize, p = read_half(ba, p)  # 42
        self.e_phnum, p = read_half(ba, p)  # 44 0x2c
        self.e_shentsize, p = read_half(ba, p)
        self.e_shnum, p = read_half(ba, p)
        self.e_shstrndx, p = read_half(ba, p)
        self.s = p

    def print(self):
        print("the elf header information:")
        print("e_indent:\t%s \t 0x7F开头，接ELF三个字符..." % self.e_indent)
        print("e_type:\t%d \t2 表示一个可执行文件" % self.e_type)
        print("e_machine:\t%d \t 3 为 intel 80386" % self.e_machine)
        print("e_version:\t%d " % self.e_version)
        print("e_entry:\t0x%x \t入口地址" % self.e_entry)
        print("e_phoff:\t0x%x \t program header table 在文件中的偏移量" % self.e_phoff)
        print("e_shoff:\t0x%x \t section header table 的偏移量" % self.e_shoff)
        print("e_ehsize:\t0x%x\t the size of ELF header should 0x34 here" % self.e_ehsize)
        print("e_phentsize:\t0x%x\t the size of pragram header should 0x20 here" % self.e_phentsize)
        print("e_phnum:\t0x%x \t the number of programheader" % self.e_phnum)
        print("e_shentsize:\t0x%x \t the size of section header should 0x28 here" % self.e_shentsize)
        print("e_shnum:\t0x%x \t the number of section header" % self.e_shnum)
        print("e_shstrndx:\t0x%x \t" % self.e_shstrndx)

    def __sizeof__(self):
        return self.s


class ProgramHeader:
    def __init__(self, ba: bytes):
        p = 0
        self.p_type, p = read_word(ba, p)  # 0
        self.p_off, p = read_offset(ba, p)  # 4
        self.p_vaddr, p = read_address(ba, p)  # 8
        self.p_paddr, p = read_address(ba, p)  # 12
        self.p_filesz, p = read_word(ba, p)  # 16
        self.p_memsz, p = read_word(ba, p)  # 24
        self.p_flags, p = read_word(ba, p)  # 32
        self.p_align, p = read_word(ba, p)  # 40
        if p != 0x20:
            print("warning! the program header size is expected to be 0x20,but get %x" % p)

    def print(self):
        print("p_type:\t %d \t 段类型" % self.p_type)
        print("p_offset:\t 0x%x \t 段偏移地址" % self.p_off)
        print("p_vaddr:\t 0x%x \t 段在内存中的虚拟地址" % self.p_vaddr)
        print("p_paddr:\t 0x%x \t 段在内存中的物理地址（保留）" % self.p_paddr)

        print("p_fillesz:\t 0x%x \t 段在文件中的大小" % self.p_filesz)
        print("p_align:\t 0x%x \t 对齐方式" % self.p_align)


class SectionHeader:
    pass


def main():
    if len(sys.argv) <= 1:
        print("file is not specified")
        return
    file = sys.argv[1]
    if not os.path.exists(file):
        print("file %s not exist" % file)
        return
    with open(file, "rb") as f:
        bs = f.read()
        if bs[0] != 0x7f:
            print("the file is not an legal elf file,not start with 0x7f")
            return
        header = ElfHeader(bs)
        header.print()
        program_headers = []
        print("\n     program headers     \n")
        print("header count:%d" % header.e_phnum)
        for i in range(header.e_phnum):
            p = header.e_phoff + i * header.e_phentsize
            print("show header at 0x%x" % p)
            program_header = ProgramHeader(bs[p:])
            program_headers.append(program_header)
            program_header.print()


if __name__ == "__main__":
    main()
