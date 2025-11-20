
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49e60613          	addi	a2,a2,1182 # ffffffffc020d4f0 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0207ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	5c7030ef          	jal	ffffffffc0203e28 <memset>
    dtb_init();
ffffffffc0200066:	4c2000ef          	jal	ffffffffc0200528 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	44c000ef          	jal	ffffffffc02004b6 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	e0a58593          	addi	a1,a1,-502 # ffffffffc0203e78 <etext+0x2>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e2250513          	addi	a0,a0,-478 # ffffffffc0203e98 <etext+0x22>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	158000ef          	jal	ffffffffc02001da <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	0d4020ef          	jal	ffffffffc020215a <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	7f0000ef          	jal	ffffffffc020087a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	7ee000ef          	jal	ffffffffc020087c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	645020ef          	jal	ffffffffc0202ed6 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	55a030ef          	jal	ffffffffc02035f0 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	3ca000ef          	jal	ffffffffc0200464 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	7d0000ef          	jal	ffffffffc020086e <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	7a6030ef          	jal	ffffffffc0203848 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	7179                	addi	sp,sp,-48
ffffffffc02000a8:	f406                	sd	ra,40(sp)
ffffffffc02000aa:	f022                	sd	s0,32(sp)
ffffffffc02000ac:	ec26                	sd	s1,24(sp)
ffffffffc02000ae:	e84a                	sd	s2,16(sp)
ffffffffc02000b0:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc02000b2:	c901                	beqz	a0,ffffffffc02000c2 <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc02000b4:	85aa                	mv	a1,a0
ffffffffc02000b6:	00004517          	auipc	a0,0x4
ffffffffc02000ba:	dea50513          	addi	a0,a0,-534 # ffffffffc0203ea0 <etext+0x2a>
ffffffffc02000be:	0d6000ef          	jal	ffffffffc0200194 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000c2:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c4:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc02000c6:	00009997          	auipc	s3,0x9
ffffffffc02000ca:	f6a98993          	addi	s3,s3,-150 # ffffffffc0209030 <buf>
        c = getchar();
ffffffffc02000ce:	0fc000ef          	jal	ffffffffc02001ca <getchar>
ffffffffc02000d2:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d4:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d8:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000dc:	ff650693          	addi	a3,a0,-10
ffffffffc02000e0:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc02000e4:	02054963          	bltz	a0,ffffffffc0200116 <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e8:	02a95f63          	bge	s2,a0,ffffffffc0200126 <readline+0x80>
ffffffffc02000ec:	cf0d                	beqz	a4,ffffffffc0200126 <readline+0x80>
            cputchar(c);
ffffffffc02000ee:	0da000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i ++] = c;
ffffffffc02000f2:	009987b3          	add	a5,s3,s1
ffffffffc02000f6:	00878023          	sb	s0,0(a5)
ffffffffc02000fa:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc02000fc:	0ce000ef          	jal	ffffffffc02001ca <getchar>
ffffffffc0200100:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0200102:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200106:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc020010a:	ff650693          	addi	a3,a0,-10
ffffffffc020010e:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0200112:	fc055be3          	bgez	a0,ffffffffc02000e8 <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc0200116:	70a2                	ld	ra,40(sp)
ffffffffc0200118:	7402                	ld	s0,32(sp)
ffffffffc020011a:	64e2                	ld	s1,24(sp)
ffffffffc020011c:	6942                	ld	s2,16(sp)
ffffffffc020011e:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0200120:	4501                	li	a0,0
}
ffffffffc0200122:	6145                	addi	sp,sp,48
ffffffffc0200124:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc0200126:	eb81                	bnez	a5,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc0200128:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc020012a:	00905663          	blez	s1,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc020012e:	09a000ef          	jal	ffffffffc02001c8 <cputchar>
            i --;
ffffffffc0200132:	34fd                	addiw	s1,s1,-1
ffffffffc0200134:	bf69                	j	ffffffffc02000ce <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc0200136:	c291                	beqz	a3,ffffffffc020013a <readline+0x94>
ffffffffc0200138:	fa59                	bnez	a2,ffffffffc02000ce <readline+0x28>
            cputchar(c);
ffffffffc020013a:	8522                	mv	a0,s0
ffffffffc020013c:	08c000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i] = '\0';
ffffffffc0200140:	00009517          	auipc	a0,0x9
ffffffffc0200144:	ef050513          	addi	a0,a0,-272 # ffffffffc0209030 <buf>
ffffffffc0200148:	94aa                	add	s1,s1,a0
ffffffffc020014a:	00048023          	sb	zero,0(s1)
}
ffffffffc020014e:	70a2                	ld	ra,40(sp)
ffffffffc0200150:	7402                	ld	s0,32(sp)
ffffffffc0200152:	64e2                	ld	s1,24(sp)
ffffffffc0200154:	6942                	ld	s2,16(sp)
ffffffffc0200156:	69a2                	ld	s3,8(sp)
ffffffffc0200158:	6145                	addi	sp,sp,48
ffffffffc020015a:	8082                	ret

ffffffffc020015c <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015c:	1101                	addi	sp,sp,-32
ffffffffc020015e:	ec06                	sd	ra,24(sp)
ffffffffc0200160:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200162:	356000ef          	jal	ffffffffc02004b8 <cons_putc>
    (*cnt)++;
ffffffffc0200166:	65a2                	ld	a1,8(sp)
}
ffffffffc0200168:	60e2                	ld	ra,24(sp)
    (*cnt)++;
ffffffffc020016a:	419c                	lw	a5,0(a1)
ffffffffc020016c:	2785                	addiw	a5,a5,1
ffffffffc020016e:	c19c                	sw	a5,0(a1)
}
ffffffffc0200170:	6105                	addi	sp,sp,32
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe250513          	addi	a0,a0,-30 # ffffffffc020015c <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	087030ef          	jal	ffffffffc0203a0e <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40
{
ffffffffc020019a:	f42e                	sd	a1,40(sp)
ffffffffc020019c:	f832                	sd	a2,48(sp)
ffffffffc020019e:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a0:	862a                	mv	a2,a0
ffffffffc02001a2:	004c                	addi	a1,sp,4
ffffffffc02001a4:	00000517          	auipc	a0,0x0
ffffffffc02001a8:	fb850513          	addi	a0,a0,-72 # ffffffffc020015c <cputch>
ffffffffc02001ac:	869a                	mv	a3,t1
{
ffffffffc02001ae:	ec06                	sd	ra,24(sp)
ffffffffc02001b0:	e0ba                	sd	a4,64(sp)
ffffffffc02001b2:	e4be                	sd	a5,72(sp)
ffffffffc02001b4:	e8c2                	sd	a6,80(sp)
ffffffffc02001b6:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02001b8:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001bc:	053030ef          	jal	ffffffffc0203a0e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c0:	60e2                	ld	ra,24(sp)
ffffffffc02001c2:	4512                	lw	a0,4(sp)
ffffffffc02001c4:	6125                	addi	sp,sp,96
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001c8:	acc5                	j	ffffffffc02004b8 <cons_putc>

ffffffffc02001ca <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001ca:	1141                	addi	sp,sp,-16
ffffffffc02001cc:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001ce:	31e000ef          	jal	ffffffffc02004ec <cons_getc>
ffffffffc02001d2:	dd75                	beqz	a0,ffffffffc02001ce <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d4:	60a2                	ld	ra,8(sp)
ffffffffc02001d6:	0141                	addi	sp,sp,16
ffffffffc02001d8:	8082                	ret

ffffffffc02001da <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001da:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001dc:	00004517          	auipc	a0,0x4
ffffffffc02001e0:	ccc50513          	addi	a0,a0,-820 # ffffffffc0203ea8 <etext+0x32>
{
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e6:	fafff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ea:	00000597          	auipc	a1,0x0
ffffffffc02001ee:	e6058593          	addi	a1,a1,-416 # ffffffffc020004a <kern_init>
ffffffffc02001f2:	00004517          	auipc	a0,0x4
ffffffffc02001f6:	cd650513          	addi	a0,a0,-810 # ffffffffc0203ec8 <etext+0x52>
ffffffffc02001fa:	f9bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02001fe:	00004597          	auipc	a1,0x4
ffffffffc0200202:	c7858593          	addi	a1,a1,-904 # ffffffffc0203e76 <etext>
ffffffffc0200206:	00004517          	auipc	a0,0x4
ffffffffc020020a:	ce250513          	addi	a0,a0,-798 # ffffffffc0203ee8 <etext+0x72>
ffffffffc020020e:	f87ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200212:	00009597          	auipc	a1,0x9
ffffffffc0200216:	e1e58593          	addi	a1,a1,-482 # ffffffffc0209030 <buf>
ffffffffc020021a:	00004517          	auipc	a0,0x4
ffffffffc020021e:	cee50513          	addi	a0,a0,-786 # ffffffffc0203f08 <etext+0x92>
ffffffffc0200222:	f73ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200226:	0000d597          	auipc	a1,0xd
ffffffffc020022a:	2ca58593          	addi	a1,a1,714 # ffffffffc020d4f0 <end>
ffffffffc020022e:	00004517          	auipc	a0,0x4
ffffffffc0200232:	cfa50513          	addi	a0,a0,-774 # ffffffffc0203f28 <etext+0xb2>
ffffffffc0200236:	f5fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023a:	00000717          	auipc	a4,0x0
ffffffffc020023e:	e1070713          	addi	a4,a4,-496 # ffffffffc020004a <kern_init>
ffffffffc0200242:	0000d797          	auipc	a5,0xd
ffffffffc0200246:	6ad78793          	addi	a5,a5,1709 # ffffffffc020d8ef <end+0x3ff>
ffffffffc020024a:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020024c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200250:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200252:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200256:	95be                	add	a1,a1,a5
ffffffffc0200258:	85a9                	srai	a1,a1,0xa
ffffffffc020025a:	00004517          	auipc	a0,0x4
ffffffffc020025e:	cee50513          	addi	a0,a0,-786 # ffffffffc0203f48 <etext+0xd2>
}
ffffffffc0200262:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200264:	bf05                	j	ffffffffc0200194 <cprintf>

ffffffffc0200266 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc0200266:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200268:	00004617          	auipc	a2,0x4
ffffffffc020026c:	d1060613          	addi	a2,a2,-752 # ffffffffc0203f78 <etext+0x102>
ffffffffc0200270:	04900593          	li	a1,73
ffffffffc0200274:	00004517          	auipc	a0,0x4
ffffffffc0200278:	d1c50513          	addi	a0,a0,-740 # ffffffffc0203f90 <etext+0x11a>
{
ffffffffc020027c:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020027e:	188000ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0200282 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200282:	1101                	addi	sp,sp,-32
ffffffffc0200284:	e822                	sd	s0,16(sp)
ffffffffc0200286:	e426                	sd	s1,8(sp)
ffffffffc0200288:	ec06                	sd	ra,24(sp)
ffffffffc020028a:	00005417          	auipc	s0,0x5
ffffffffc020028e:	4be40413          	addi	s0,s0,1214 # ffffffffc0205748 <commands>
ffffffffc0200292:	00005497          	auipc	s1,0x5
ffffffffc0200296:	4fe48493          	addi	s1,s1,1278 # ffffffffc0205790 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020029a:	6410                	ld	a2,8(s0)
ffffffffc020029c:	600c                	ld	a1,0(s0)
ffffffffc020029e:	00004517          	auipc	a0,0x4
ffffffffc02002a2:	d0a50513          	addi	a0,a0,-758 # ffffffffc0203fa8 <etext+0x132>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002a6:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a8:	eedff0ef          	jal	ffffffffc0200194 <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ac:	fe9417e3          	bne	s0,s1,ffffffffc020029a <mon_help+0x18>
    }
    return 0;
}
ffffffffc02002b0:	60e2                	ld	ra,24(sp)
ffffffffc02002b2:	6442                	ld	s0,16(sp)
ffffffffc02002b4:	64a2                	ld	s1,8(sp)
ffffffffc02002b6:	4501                	li	a0,0
ffffffffc02002b8:	6105                	addi	sp,sp,32
ffffffffc02002ba:	8082                	ret

ffffffffc02002bc <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002bc:	1141                	addi	sp,sp,-16
ffffffffc02002be:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002c0:	f1bff0ef          	jal	ffffffffc02001da <print_kerninfo>
    return 0;
}
ffffffffc02002c4:	60a2                	ld	ra,8(sp)
ffffffffc02002c6:	4501                	li	a0,0
ffffffffc02002c8:	0141                	addi	sp,sp,16
ffffffffc02002ca:	8082                	ret

ffffffffc02002cc <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002cc:	1141                	addi	sp,sp,-16
ffffffffc02002ce:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002d0:	f97ff0ef          	jal	ffffffffc0200266 <print_stackframe>
    return 0;
}
ffffffffc02002d4:	60a2                	ld	ra,8(sp)
ffffffffc02002d6:	4501                	li	a0,0
ffffffffc02002d8:	0141                	addi	sp,sp,16
ffffffffc02002da:	8082                	ret

ffffffffc02002dc <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002dc:	7131                	addi	sp,sp,-192
ffffffffc02002de:	e952                	sd	s4,144(sp)
ffffffffc02002e0:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002e2:	00004517          	auipc	a0,0x4
ffffffffc02002e6:	cd650513          	addi	a0,a0,-810 # ffffffffc0203fb8 <etext+0x142>
kmonitor(struct trapframe *tf) {
ffffffffc02002ea:	fd06                	sd	ra,184(sp)
ffffffffc02002ec:	f922                	sd	s0,176(sp)
ffffffffc02002ee:	f526                	sd	s1,168(sp)
ffffffffc02002f0:	f14a                	sd	s2,160(sp)
ffffffffc02002f2:	e556                	sd	s5,136(sp)
ffffffffc02002f4:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002f6:	e9fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002fa:	00004517          	auipc	a0,0x4
ffffffffc02002fe:	ce650513          	addi	a0,a0,-794 # ffffffffc0203fe0 <etext+0x16a>
ffffffffc0200302:	e93ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc0200306:	000a0563          	beqz	s4,ffffffffc0200310 <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc020030a:	8552                	mv	a0,s4
ffffffffc020030c:	758000ef          	jal	ffffffffc0200a64 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200310:	4501                	li	a0,0
ffffffffc0200312:	4581                	li	a1,0
ffffffffc0200314:	4601                	li	a2,0
ffffffffc0200316:	48a1                	li	a7,8
ffffffffc0200318:	00000073          	ecall
ffffffffc020031c:	00005a97          	auipc	s5,0x5
ffffffffc0200320:	42ca8a93          	addi	s5,s5,1068 # ffffffffc0205748 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc0200324:	493d                	li	s2,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200326:	00004517          	auipc	a0,0x4
ffffffffc020032a:	ce250513          	addi	a0,a0,-798 # ffffffffc0204008 <etext+0x192>
ffffffffc020032e:	d79ff0ef          	jal	ffffffffc02000a6 <readline>
ffffffffc0200332:	842a                	mv	s0,a0
ffffffffc0200334:	d96d                	beqz	a0,ffffffffc0200326 <kmonitor+0x4a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200336:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020033a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020033c:	e99d                	bnez	a1,ffffffffc0200372 <kmonitor+0x96>
    int argc = 0;
ffffffffc020033e:	8b26                	mv	s6,s1
    if (argc == 0) {
ffffffffc0200340:	fe0b03e3          	beqz	s6,ffffffffc0200326 <kmonitor+0x4a>
ffffffffc0200344:	00005497          	auipc	s1,0x5
ffffffffc0200348:	40448493          	addi	s1,s1,1028 # ffffffffc0205748 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020034e:	6582                	ld	a1,0(sp)
ffffffffc0200350:	6088                	ld	a0,0(s1)
ffffffffc0200352:	269030ef          	jal	ffffffffc0203dba <strcmp>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200356:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200358:	c149                	beqz	a0,ffffffffc02003da <kmonitor+0xfe>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020035a:	2405                	addiw	s0,s0,1
ffffffffc020035c:	04e1                	addi	s1,s1,24
ffffffffc020035e:	fef418e3          	bne	s0,a5,ffffffffc020034e <kmonitor+0x72>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200362:	6582                	ld	a1,0(sp)
ffffffffc0200364:	00004517          	auipc	a0,0x4
ffffffffc0200368:	cd450513          	addi	a0,a0,-812 # ffffffffc0204038 <etext+0x1c2>
ffffffffc020036c:	e29ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200370:	bf5d                	j	ffffffffc0200326 <kmonitor+0x4a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200372:	00004517          	auipc	a0,0x4
ffffffffc0200376:	c9e50513          	addi	a0,a0,-866 # ffffffffc0204010 <etext+0x19a>
ffffffffc020037a:	29d030ef          	jal	ffffffffc0203e16 <strchr>
ffffffffc020037e:	c901                	beqz	a0,ffffffffc020038e <kmonitor+0xb2>
ffffffffc0200380:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200384:	00040023          	sb	zero,0(s0)
ffffffffc0200388:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	d9d5                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc020038c:	b7dd                	j	ffffffffc0200372 <kmonitor+0x96>
        if (*buf == '\0') {
ffffffffc020038e:	00044783          	lbu	a5,0(s0)
ffffffffc0200392:	d7d5                	beqz	a5,ffffffffc020033e <kmonitor+0x62>
        if (argc == MAXARGS - 1) {
ffffffffc0200394:	03248b63          	beq	s1,s2,ffffffffc02003ca <kmonitor+0xee>
        argv[argc ++] = buf;
ffffffffc0200398:	00349793          	slli	a5,s1,0x3
ffffffffc020039c:	978a                	add	a5,a5,sp
ffffffffc020039e:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a0:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003a4:	2485                	addiw	s1,s1,1
ffffffffc02003a6:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a8:	e591                	bnez	a1,ffffffffc02003b4 <kmonitor+0xd8>
ffffffffc02003aa:	bf59                	j	ffffffffc0200340 <kmonitor+0x64>
ffffffffc02003ac:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003b0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003b2:	d5d1                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc02003b4:	00004517          	auipc	a0,0x4
ffffffffc02003b8:	c5c50513          	addi	a0,a0,-932 # ffffffffc0204010 <etext+0x19a>
ffffffffc02003bc:	25b030ef          	jal	ffffffffc0203e16 <strchr>
ffffffffc02003c0:	d575                	beqz	a0,ffffffffc02003ac <kmonitor+0xd0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c2:	00044583          	lbu	a1,0(s0)
ffffffffc02003c6:	dda5                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc02003c8:	b76d                	j	ffffffffc0200372 <kmonitor+0x96>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003ca:	45c1                	li	a1,16
ffffffffc02003cc:	00004517          	auipc	a0,0x4
ffffffffc02003d0:	c4c50513          	addi	a0,a0,-948 # ffffffffc0204018 <etext+0x1a2>
ffffffffc02003d4:	dc1ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc02003d8:	b7c1                	j	ffffffffc0200398 <kmonitor+0xbc>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003da:	00141793          	slli	a5,s0,0x1
ffffffffc02003de:	97a2                	add	a5,a5,s0
ffffffffc02003e0:	078e                	slli	a5,a5,0x3
ffffffffc02003e2:	97d6                	add	a5,a5,s5
ffffffffc02003e4:	6b9c                	ld	a5,16(a5)
ffffffffc02003e6:	fffb051b          	addiw	a0,s6,-1
ffffffffc02003ea:	8652                	mv	a2,s4
ffffffffc02003ec:	002c                	addi	a1,sp,8
ffffffffc02003ee:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003f0:	f2055be3          	bgez	a0,ffffffffc0200326 <kmonitor+0x4a>
}
ffffffffc02003f4:	70ea                	ld	ra,184(sp)
ffffffffc02003f6:	744a                	ld	s0,176(sp)
ffffffffc02003f8:	74aa                	ld	s1,168(sp)
ffffffffc02003fa:	790a                	ld	s2,160(sp)
ffffffffc02003fc:	6a4a                	ld	s4,144(sp)
ffffffffc02003fe:	6aaa                	ld	s5,136(sp)
ffffffffc0200400:	6b0a                	ld	s6,128(sp)
ffffffffc0200402:	6129                	addi	sp,sp,192
ffffffffc0200404:	8082                	ret

ffffffffc0200406 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200406:	0000d317          	auipc	t1,0xd
ffffffffc020040a:	06232303          	lw	t1,98(t1) # ffffffffc020d468 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020040e:	715d                	addi	sp,sp,-80
ffffffffc0200410:	ec06                	sd	ra,24(sp)
ffffffffc0200412:	f436                	sd	a3,40(sp)
ffffffffc0200414:	f83a                	sd	a4,48(sp)
ffffffffc0200416:	fc3e                	sd	a5,56(sp)
ffffffffc0200418:	e0c2                	sd	a6,64(sp)
ffffffffc020041a:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020041c:	02031e63          	bnez	t1,ffffffffc0200458 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200420:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200422:	103c                	addi	a5,sp,40
ffffffffc0200424:	e822                	sd	s0,16(sp)
ffffffffc0200426:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200428:	862e                	mv	a2,a1
ffffffffc020042a:	85aa                	mv	a1,a0
ffffffffc020042c:	00004517          	auipc	a0,0x4
ffffffffc0200430:	cb450513          	addi	a0,a0,-844 # ffffffffc02040e0 <etext+0x26a>
    is_panic = 1;
ffffffffc0200434:	0000d697          	auipc	a3,0xd
ffffffffc0200438:	02e6aa23          	sw	a4,52(a3) # ffffffffc020d468 <is_panic>
    va_start(ap, fmt);
ffffffffc020043c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020043e:	d57ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200442:	65a2                	ld	a1,8(sp)
ffffffffc0200444:	8522                	mv	a0,s0
ffffffffc0200446:	d2fff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020044a:	00004517          	auipc	a0,0x4
ffffffffc020044e:	cb650513          	addi	a0,a0,-842 # ffffffffc0204100 <etext+0x28a>
ffffffffc0200452:	d43ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200456:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200458:	41c000ef          	jal	ffffffffc0200874 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020045c:	4501                	li	a0,0
ffffffffc020045e:	e7fff0ef          	jal	ffffffffc02002dc <kmonitor>
    while (1) {
ffffffffc0200462:	bfed                	j	ffffffffc020045c <__panic+0x56>

ffffffffc0200464 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046a:	0000d717          	auipc	a4,0xd
ffffffffc020046e:	00f73323          	sd	a5,6(a4) # ffffffffc020d470 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200472:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200476:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200478:	953e                	add	a0,a0,a5
ffffffffc020047a:	4601                	li	a2,0
ffffffffc020047c:	4881                	li	a7,0
ffffffffc020047e:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200482:	02000793          	li	a5,32
ffffffffc0200486:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020048a:	00004517          	auipc	a0,0x4
ffffffffc020048e:	c7e50513          	addi	a0,a0,-898 # ffffffffc0204108 <etext+0x292>
    ticks = 0;
ffffffffc0200492:	0000d797          	auipc	a5,0xd
ffffffffc0200496:	fe07b323          	sd	zero,-26(a5) # ffffffffc020d478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020049a:	b9ed                	j	ffffffffc0200194 <cprintf>

ffffffffc020049c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020049c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004a0:	0000d797          	auipc	a5,0xd
ffffffffc02004a4:	fd07b783          	ld	a5,-48(a5) # ffffffffc020d470 <timebase>
ffffffffc02004a8:	4581                	li	a1,0
ffffffffc02004aa:	4601                	li	a2,0
ffffffffc02004ac:	953e                	add	a0,a0,a5
ffffffffc02004ae:	4881                	li	a7,0
ffffffffc02004b0:	00000073          	ecall
ffffffffc02004b4:	8082                	ret

ffffffffc02004b6 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004b6:	8082                	ret

ffffffffc02004b8 <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004b8:	100027f3          	csrr	a5,sstatus
ffffffffc02004bc:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02004be:	0ff57513          	zext.b	a0,a0
ffffffffc02004c2:	e799                	bnez	a5,ffffffffc02004d0 <cons_putc+0x18>
ffffffffc02004c4:	4581                	li	a1,0
ffffffffc02004c6:	4601                	li	a2,0
ffffffffc02004c8:	4885                	li	a7,1
ffffffffc02004ca:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02004ce:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02004d0:	1101                	addi	sp,sp,-32
ffffffffc02004d2:	ec06                	sd	ra,24(sp)
ffffffffc02004d4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02004d6:	39e000ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02004da:	6522                	ld	a0,8(sp)
ffffffffc02004dc:	4581                	li	a1,0
ffffffffc02004de:	4601                	li	a2,0
ffffffffc02004e0:	4885                	li	a7,1
ffffffffc02004e2:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02004e6:	60e2                	ld	ra,24(sp)
ffffffffc02004e8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02004ea:	a651                	j	ffffffffc020086e <intr_enable>

ffffffffc02004ec <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004ec:	100027f3          	csrr	a5,sstatus
ffffffffc02004f0:	8b89                	andi	a5,a5,2
ffffffffc02004f2:	eb89                	bnez	a5,ffffffffc0200504 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02004f4:	4501                	li	a0,0
ffffffffc02004f6:	4581                	li	a1,0
ffffffffc02004f8:	4601                	li	a2,0
ffffffffc02004fa:	4889                	li	a7,2
ffffffffc02004fc:	00000073          	ecall
ffffffffc0200500:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200502:	8082                	ret
int cons_getc(void) {
ffffffffc0200504:	1101                	addi	sp,sp,-32
ffffffffc0200506:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200508:	36c000ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc020050c:	4501                	li	a0,0
ffffffffc020050e:	4581                	li	a1,0
ffffffffc0200510:	4601                	li	a2,0
ffffffffc0200512:	4889                	li	a7,2
ffffffffc0200514:	00000073          	ecall
ffffffffc0200518:	2501                	sext.w	a0,a0
ffffffffc020051a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020051c:	352000ef          	jal	ffffffffc020086e <intr_enable>
}
ffffffffc0200520:	60e2                	ld	ra,24(sp)
ffffffffc0200522:	6522                	ld	a0,8(sp)
ffffffffc0200524:	6105                	addi	sp,sp,32
ffffffffc0200526:	8082                	ret

ffffffffc0200528 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200528:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020052a:	00004517          	auipc	a0,0x4
ffffffffc020052e:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0204128 <etext+0x2b2>
void dtb_init(void) {
ffffffffc0200532:	f406                	sd	ra,40(sp)
ffffffffc0200534:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200536:	c5fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020053a:	00009597          	auipc	a1,0x9
ffffffffc020053e:	ac65b583          	ld	a1,-1338(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc0200542:	00004517          	auipc	a0,0x4
ffffffffc0200546:	bf650513          	addi	a0,a0,-1034 # ffffffffc0204138 <etext+0x2c2>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020054a:	00009417          	auipc	s0,0x9
ffffffffc020054e:	abe40413          	addi	s0,s0,-1346 # ffffffffc0209008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200552:	c43ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200556:	600c                	ld	a1,0(s0)
ffffffffc0200558:	00004517          	auipc	a0,0x4
ffffffffc020055c:	bf050513          	addi	a0,a0,-1040 # ffffffffc0204148 <etext+0x2d2>
ffffffffc0200560:	c35ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200564:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200566:	00004517          	auipc	a0,0x4
ffffffffc020056a:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0204160 <etext+0x2ea>
    if (boot_dtb == 0) {
ffffffffc020056e:	10070163          	beqz	a4,ffffffffc0200670 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200572:	57f5                	li	a5,-3
ffffffffc0200574:	07fa                	slli	a5,a5,0x1e
ffffffffc0200576:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200578:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020057a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020057e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed29fd>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200582:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200586:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200592:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200596:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200598:	8e49                	or	a2,a2,a0
ffffffffc020059a:	0ff7f793          	zext.b	a5,a5
ffffffffc020059e:	8dd1                	or	a1,a1,a2
ffffffffc02005a0:	07a2                	slli	a5,a5,0x8
ffffffffc02005a2:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a4:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02005a8:	0cd59863          	bne	a1,a3,ffffffffc0200678 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02005ac:	4710                	lw	a2,8(a4)
ffffffffc02005ae:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b0:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02005b6:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02005be:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02005c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02005ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ce:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005d2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02005da:	01c56533          	or	a0,a0,t3
ffffffffc02005de:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e2:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005e6:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ea:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02005f2:	8c49                	or	s0,s0,a0
ffffffffc02005f4:	0622                	slli	a2,a2,0x8
ffffffffc02005f6:	8fcd                	or	a5,a5,a1
ffffffffc02005f8:	06a2                	slli	a3,a3,0x8
ffffffffc02005fa:	8c51                	or	s0,s0,a2
ffffffffc02005fc:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005fe:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200600:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200602:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200604:	9381                	srli	a5,a5,0x20
ffffffffc0200606:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200608:	4301                	li	t1,0
        switch (token) {
ffffffffc020060a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020060c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020060e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200612:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200614:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200616:	0087579b          	srliw	a5,a4,0x8
ffffffffc020061a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200622:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200626:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020062a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020062e:	8ed1                	or	a3,a3,a2
ffffffffc0200630:	0ff77713          	zext.b	a4,a4
ffffffffc0200634:	8fd5                	or	a5,a5,a3
ffffffffc0200636:	0722                	slli	a4,a4,0x8
ffffffffc0200638:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020063a:	05178763          	beq	a5,a7,ffffffffc0200688 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020063e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200640:	00f8e963          	bltu	a7,a5,ffffffffc0200652 <dtb_init+0x12a>
ffffffffc0200644:	07c78d63          	beq	a5,t3,ffffffffc02006be <dtb_init+0x196>
ffffffffc0200648:	4709                	li	a4,2
ffffffffc020064a:	00e79763          	bne	a5,a4,ffffffffc0200658 <dtb_init+0x130>
ffffffffc020064e:	4301                	li	t1,0
ffffffffc0200650:	b7d1                	j	ffffffffc0200614 <dtb_init+0xec>
ffffffffc0200652:	4711                	li	a4,4
ffffffffc0200654:	fce780e3          	beq	a5,a4,ffffffffc0200614 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200658:	00004517          	auipc	a0,0x4
ffffffffc020065c:	bd050513          	addi	a0,a0,-1072 # ffffffffc0204228 <etext+0x3b2>
ffffffffc0200660:	b35ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200664:	64e2                	ld	s1,24(sp)
ffffffffc0200666:	6942                	ld	s2,16(sp)
ffffffffc0200668:	00004517          	auipc	a0,0x4
ffffffffc020066c:	bf850513          	addi	a0,a0,-1032 # ffffffffc0204260 <etext+0x3ea>
}
ffffffffc0200670:	7402                	ld	s0,32(sp)
ffffffffc0200672:	70a2                	ld	ra,40(sp)
ffffffffc0200674:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200676:	be39                	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200678:	7402                	ld	s0,32(sp)
ffffffffc020067a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020067c:	00004517          	auipc	a0,0x4
ffffffffc0200680:	b0450513          	addi	a0,a0,-1276 # ffffffffc0204180 <etext+0x30a>
}
ffffffffc0200684:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200686:	b639                	j	ffffffffc0200194 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200688:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020068e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200692:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200696:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a2:	8ed1                	or	a3,a3,a2
ffffffffc02006a4:	0ff77713          	zext.b	a4,a4
ffffffffc02006a8:	8fd5                	or	a5,a5,a3
ffffffffc02006aa:	0722                	slli	a4,a4,0x8
ffffffffc02006ac:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ae:	04031463          	bnez	t1,ffffffffc02006f6 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006b2:	1782                	slli	a5,a5,0x20
ffffffffc02006b4:	9381                	srli	a5,a5,0x20
ffffffffc02006b6:	043d                	addi	s0,s0,15
ffffffffc02006b8:	943e                	add	s0,s0,a5
ffffffffc02006ba:	9871                	andi	s0,s0,-4
                break;
ffffffffc02006bc:	bfa1                	j	ffffffffc0200614 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02006be:	8522                	mv	a0,s0
ffffffffc02006c0:	e01a                	sd	t1,0(sp)
ffffffffc02006c2:	6b2030ef          	jal	ffffffffc0203d74 <strlen>
ffffffffc02006c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006c8:	4619                	li	a2,6
ffffffffc02006ca:	8522                	mv	a0,s0
ffffffffc02006cc:	00004597          	auipc	a1,0x4
ffffffffc02006d0:	adc58593          	addi	a1,a1,-1316 # ffffffffc02041a8 <etext+0x332>
ffffffffc02006d4:	71a030ef          	jal	ffffffffc0203dee <strncmp>
ffffffffc02006d8:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006da:	0411                	addi	s0,s0,4
ffffffffc02006dc:	0004879b          	sext.w	a5,s1
ffffffffc02006e0:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006e2:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006e6:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006e8:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02006ec:	00ff0837          	lui	a6,0xff0
ffffffffc02006f0:	488d                	li	a7,3
ffffffffc02006f2:	4e05                	li	t3,1
ffffffffc02006f4:	b705                	j	ffffffffc0200614 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006f6:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f8:	00004597          	auipc	a1,0x4
ffffffffc02006fc:	ab858593          	addi	a1,a1,-1352 # ffffffffc02041b0 <etext+0x33a>
ffffffffc0200700:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200706:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020070e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200712:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200716:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071a:	8ed1                	or	a3,a3,a2
ffffffffc020071c:	0ff77713          	zext.b	a4,a4
ffffffffc0200720:	0722                	slli	a4,a4,0x8
ffffffffc0200722:	8d55                	or	a0,a0,a3
ffffffffc0200724:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200726:	1502                	slli	a0,a0,0x20
ffffffffc0200728:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020072a:	954a                	add	a0,a0,s2
ffffffffc020072c:	e01a                	sd	t1,0(sp)
ffffffffc020072e:	68c030ef          	jal	ffffffffc0203dba <strcmp>
ffffffffc0200732:	67a2                	ld	a5,8(sp)
ffffffffc0200734:	473d                	li	a4,15
ffffffffc0200736:	6302                	ld	t1,0(sp)
ffffffffc0200738:	00ff0837          	lui	a6,0xff0
ffffffffc020073c:	488d                	li	a7,3
ffffffffc020073e:	4e05                	li	t3,1
ffffffffc0200740:	f6f779e3          	bgeu	a4,a5,ffffffffc02006b2 <dtb_init+0x18a>
ffffffffc0200744:	f53d                	bnez	a0,ffffffffc02006b2 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200746:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020074a:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020074e:	00004517          	auipc	a0,0x4
ffffffffc0200752:	a6a50513          	addi	a0,a0,-1430 # ffffffffc02041b8 <etext+0x342>
           fdt32_to_cpu(x >> 32);
ffffffffc0200756:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020075a:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020075e:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200762:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200766:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076a:	0187959b          	slliw	a1,a5,0x18
ffffffffc020076e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200772:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200776:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020077a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077e:	01037333          	and	t1,t1,a6
ffffffffc0200782:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200786:	01e5e5b3          	or	a1,a1,t5
ffffffffc020078a:	0ff7f793          	zext.b	a5,a5
ffffffffc020078e:	01de6e33          	or	t3,t3,t4
ffffffffc0200792:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200796:	01067633          	and	a2,a2,a6
ffffffffc020079a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020079e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	07a2                	slli	a5,a5,0x8
ffffffffc02007a4:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02007a8:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02007ac:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02007b0:	8ddd                	or	a1,a1,a5
ffffffffc02007b2:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007b6:	0186979b          	slliw	a5,a3,0x18
ffffffffc02007ba:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007be:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ce:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d2:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d6:	08a2                	slli	a7,a7,0x8
ffffffffc02007d8:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007dc:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007e0:	0ff6f693          	zext.b	a3,a3
ffffffffc02007e4:	01de6833          	or	a6,t3,t4
ffffffffc02007e8:	0ff77713          	zext.b	a4,a4
ffffffffc02007ec:	01166633          	or	a2,a2,a7
ffffffffc02007f0:	0067e7b3          	or	a5,a5,t1
ffffffffc02007f4:	06a2                	slli	a3,a3,0x8
ffffffffc02007f6:	01046433          	or	s0,s0,a6
ffffffffc02007fa:	0722                	slli	a4,a4,0x8
ffffffffc02007fc:	8fd5                	or	a5,a5,a3
ffffffffc02007fe:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200800:	1582                	slli	a1,a1,0x20
ffffffffc0200802:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200804:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200806:	9201                	srli	a2,a2,0x20
ffffffffc0200808:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020080a:	1402                	slli	s0,s0,0x20
ffffffffc020080c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200810:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200812:	983ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200816:	85a6                	mv	a1,s1
ffffffffc0200818:	00004517          	auipc	a0,0x4
ffffffffc020081c:	9c050513          	addi	a0,a0,-1600 # ffffffffc02041d8 <etext+0x362>
ffffffffc0200820:	975ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200824:	01445613          	srli	a2,s0,0x14
ffffffffc0200828:	85a2                	mv	a1,s0
ffffffffc020082a:	00004517          	auipc	a0,0x4
ffffffffc020082e:	9c650513          	addi	a0,a0,-1594 # ffffffffc02041f0 <etext+0x37a>
ffffffffc0200832:	963ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200836:	009405b3          	add	a1,s0,s1
ffffffffc020083a:	15fd                	addi	a1,a1,-1
ffffffffc020083c:	00004517          	auipc	a0,0x4
ffffffffc0200840:	9d450513          	addi	a0,a0,-1580 # ffffffffc0204210 <etext+0x39a>
ffffffffc0200844:	951ff0ef          	jal	ffffffffc0200194 <cprintf>
        memory_base = mem_base;
ffffffffc0200848:	0000d797          	auipc	a5,0xd
ffffffffc020084c:	c497b023          	sd	s1,-960(a5) # ffffffffc020d488 <memory_base>
        memory_size = mem_size;
ffffffffc0200850:	0000d797          	auipc	a5,0xd
ffffffffc0200854:	c287b823          	sd	s0,-976(a5) # ffffffffc020d480 <memory_size>
ffffffffc0200858:	b531                	j	ffffffffc0200664 <dtb_init+0x13c>

ffffffffc020085a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020085a:	0000d517          	auipc	a0,0xd
ffffffffc020085e:	c2e53503          	ld	a0,-978(a0) # ffffffffc020d488 <memory_base>
ffffffffc0200862:	8082                	ret

ffffffffc0200864 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200864:	0000d517          	auipc	a0,0xd
ffffffffc0200868:	c1c53503          	ld	a0,-996(a0) # ffffffffc020d480 <memory_size>
ffffffffc020086c:	8082                	ret

ffffffffc020086e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020086e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200872:	8082                	ret

ffffffffc0200874 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200874:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200878:	8082                	ret

ffffffffc020087a <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020087a:	8082                	ret

ffffffffc020087c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020087c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200880:	00000797          	auipc	a5,0x0
ffffffffc0200884:	40078793          	addi	a5,a5,1024 # ffffffffc0200c80 <__alltraps>
ffffffffc0200888:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020088c:	000407b7          	lui	a5,0x40
ffffffffc0200890:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200894:	8082                	ret

ffffffffc0200896 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200896:	610c                	ld	a1,0(a0)
{
ffffffffc0200898:	1141                	addi	sp,sp,-16
ffffffffc020089a:	e022                	sd	s0,0(sp)
ffffffffc020089c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020089e:	00004517          	auipc	a0,0x4
ffffffffc02008a2:	9da50513          	addi	a0,a0,-1574 # ffffffffc0204278 <etext+0x402>
{
ffffffffc02008a6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02008a8:	8edff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02008ac:	640c                	ld	a1,8(s0)
ffffffffc02008ae:	00004517          	auipc	a0,0x4
ffffffffc02008b2:	9e250513          	addi	a0,a0,-1566 # ffffffffc0204290 <etext+0x41a>
ffffffffc02008b6:	8dfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02008ba:	680c                	ld	a1,16(s0)
ffffffffc02008bc:	00004517          	auipc	a0,0x4
ffffffffc02008c0:	9ec50513          	addi	a0,a0,-1556 # ffffffffc02042a8 <etext+0x432>
ffffffffc02008c4:	8d1ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02008c8:	6c0c                	ld	a1,24(s0)
ffffffffc02008ca:	00004517          	auipc	a0,0x4
ffffffffc02008ce:	9f650513          	addi	a0,a0,-1546 # ffffffffc02042c0 <etext+0x44a>
ffffffffc02008d2:	8c3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02008d6:	700c                	ld	a1,32(s0)
ffffffffc02008d8:	00004517          	auipc	a0,0x4
ffffffffc02008dc:	a0050513          	addi	a0,a0,-1536 # ffffffffc02042d8 <etext+0x462>
ffffffffc02008e0:	8b5ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008e4:	740c                	ld	a1,40(s0)
ffffffffc02008e6:	00004517          	auipc	a0,0x4
ffffffffc02008ea:	a0a50513          	addi	a0,a0,-1526 # ffffffffc02042f0 <etext+0x47a>
ffffffffc02008ee:	8a7ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008f2:	780c                	ld	a1,48(s0)
ffffffffc02008f4:	00004517          	auipc	a0,0x4
ffffffffc02008f8:	a1450513          	addi	a0,a0,-1516 # ffffffffc0204308 <etext+0x492>
ffffffffc02008fc:	899ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200900:	7c0c                	ld	a1,56(s0)
ffffffffc0200902:	00004517          	auipc	a0,0x4
ffffffffc0200906:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0204320 <etext+0x4aa>
ffffffffc020090a:	88bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020090e:	602c                	ld	a1,64(s0)
ffffffffc0200910:	00004517          	auipc	a0,0x4
ffffffffc0200914:	a2850513          	addi	a0,a0,-1496 # ffffffffc0204338 <etext+0x4c2>
ffffffffc0200918:	87dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc020091c:	642c                	ld	a1,72(s0)
ffffffffc020091e:	00004517          	auipc	a0,0x4
ffffffffc0200922:	a3250513          	addi	a0,a0,-1486 # ffffffffc0204350 <etext+0x4da>
ffffffffc0200926:	86fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020092a:	682c                	ld	a1,80(s0)
ffffffffc020092c:	00004517          	auipc	a0,0x4
ffffffffc0200930:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0204368 <etext+0x4f2>
ffffffffc0200934:	861ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200938:	6c2c                	ld	a1,88(s0)
ffffffffc020093a:	00004517          	auipc	a0,0x4
ffffffffc020093e:	a4650513          	addi	a0,a0,-1466 # ffffffffc0204380 <etext+0x50a>
ffffffffc0200942:	853ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200946:	702c                	ld	a1,96(s0)
ffffffffc0200948:	00004517          	auipc	a0,0x4
ffffffffc020094c:	a5050513          	addi	a0,a0,-1456 # ffffffffc0204398 <etext+0x522>
ffffffffc0200950:	845ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200954:	742c                	ld	a1,104(s0)
ffffffffc0200956:	00004517          	auipc	a0,0x4
ffffffffc020095a:	a5a50513          	addi	a0,a0,-1446 # ffffffffc02043b0 <etext+0x53a>
ffffffffc020095e:	837ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200962:	782c                	ld	a1,112(s0)
ffffffffc0200964:	00004517          	auipc	a0,0x4
ffffffffc0200968:	a6450513          	addi	a0,a0,-1436 # ffffffffc02043c8 <etext+0x552>
ffffffffc020096c:	829ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200970:	7c2c                	ld	a1,120(s0)
ffffffffc0200972:	00004517          	auipc	a0,0x4
ffffffffc0200976:	a6e50513          	addi	a0,a0,-1426 # ffffffffc02043e0 <etext+0x56a>
ffffffffc020097a:	81bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020097e:	604c                	ld	a1,128(s0)
ffffffffc0200980:	00004517          	auipc	a0,0x4
ffffffffc0200984:	a7850513          	addi	a0,a0,-1416 # ffffffffc02043f8 <etext+0x582>
ffffffffc0200988:	80dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020098c:	644c                	ld	a1,136(s0)
ffffffffc020098e:	00004517          	auipc	a0,0x4
ffffffffc0200992:	a8250513          	addi	a0,a0,-1406 # ffffffffc0204410 <etext+0x59a>
ffffffffc0200996:	ffeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020099a:	684c                	ld	a1,144(s0)
ffffffffc020099c:	00004517          	auipc	a0,0x4
ffffffffc02009a0:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0204428 <etext+0x5b2>
ffffffffc02009a4:	ff0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02009a8:	6c4c                	ld	a1,152(s0)
ffffffffc02009aa:	00004517          	auipc	a0,0x4
ffffffffc02009ae:	a9650513          	addi	a0,a0,-1386 # ffffffffc0204440 <etext+0x5ca>
ffffffffc02009b2:	fe2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02009b6:	704c                	ld	a1,160(s0)
ffffffffc02009b8:	00004517          	auipc	a0,0x4
ffffffffc02009bc:	aa050513          	addi	a0,a0,-1376 # ffffffffc0204458 <etext+0x5e2>
ffffffffc02009c0:	fd4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02009c4:	744c                	ld	a1,168(s0)
ffffffffc02009c6:	00004517          	auipc	a0,0x4
ffffffffc02009ca:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0204470 <etext+0x5fa>
ffffffffc02009ce:	fc6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02009d2:	784c                	ld	a1,176(s0)
ffffffffc02009d4:	00004517          	auipc	a0,0x4
ffffffffc02009d8:	ab450513          	addi	a0,a0,-1356 # ffffffffc0204488 <etext+0x612>
ffffffffc02009dc:	fb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009e0:	7c4c                	ld	a1,184(s0)
ffffffffc02009e2:	00004517          	auipc	a0,0x4
ffffffffc02009e6:	abe50513          	addi	a0,a0,-1346 # ffffffffc02044a0 <etext+0x62a>
ffffffffc02009ea:	faaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009ee:	606c                	ld	a1,192(s0)
ffffffffc02009f0:	00004517          	auipc	a0,0x4
ffffffffc02009f4:	ac850513          	addi	a0,a0,-1336 # ffffffffc02044b8 <etext+0x642>
ffffffffc02009f8:	f9cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009fc:	646c                	ld	a1,200(s0)
ffffffffc02009fe:	00004517          	auipc	a0,0x4
ffffffffc0200a02:	ad250513          	addi	a0,a0,-1326 # ffffffffc02044d0 <etext+0x65a>
ffffffffc0200a06:	f8eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a0a:	686c                	ld	a1,208(s0)
ffffffffc0200a0c:	00004517          	auipc	a0,0x4
ffffffffc0200a10:	adc50513          	addi	a0,a0,-1316 # ffffffffc02044e8 <etext+0x672>
ffffffffc0200a14:	f80ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200a18:	6c6c                	ld	a1,216(s0)
ffffffffc0200a1a:	00004517          	auipc	a0,0x4
ffffffffc0200a1e:	ae650513          	addi	a0,a0,-1306 # ffffffffc0204500 <etext+0x68a>
ffffffffc0200a22:	f72ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200a26:	706c                	ld	a1,224(s0)
ffffffffc0200a28:	00004517          	auipc	a0,0x4
ffffffffc0200a2c:	af050513          	addi	a0,a0,-1296 # ffffffffc0204518 <etext+0x6a2>
ffffffffc0200a30:	f64ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200a34:	746c                	ld	a1,232(s0)
ffffffffc0200a36:	00004517          	auipc	a0,0x4
ffffffffc0200a3a:	afa50513          	addi	a0,a0,-1286 # ffffffffc0204530 <etext+0x6ba>
ffffffffc0200a3e:	f56ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a42:	786c                	ld	a1,240(s0)
ffffffffc0200a44:	00004517          	auipc	a0,0x4
ffffffffc0200a48:	b0450513          	addi	a0,a0,-1276 # ffffffffc0204548 <etext+0x6d2>
ffffffffc0200a4c:	f48ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a50:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a52:	6402                	ld	s0,0(sp)
ffffffffc0200a54:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a56:	00004517          	auipc	a0,0x4
ffffffffc0200a5a:	b0a50513          	addi	a0,a0,-1270 # ffffffffc0204560 <etext+0x6ea>
}
ffffffffc0200a5e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a60:	f34ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200a64 <print_trapframe>:
{
ffffffffc0200a64:	1141                	addi	sp,sp,-16
ffffffffc0200a66:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a68:	85aa                	mv	a1,a0
{
ffffffffc0200a6a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a6c:	00004517          	auipc	a0,0x4
ffffffffc0200a70:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0204578 <etext+0x702>
{
ffffffffc0200a74:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a76:	f1eff0ef          	jal	ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a7a:	8522                	mv	a0,s0
ffffffffc0200a7c:	e1bff0ef          	jal	ffffffffc0200896 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a80:	10043583          	ld	a1,256(s0)
ffffffffc0200a84:	00004517          	auipc	a0,0x4
ffffffffc0200a88:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0204590 <etext+0x71a>
ffffffffc0200a8c:	f08ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a90:	10843583          	ld	a1,264(s0)
ffffffffc0200a94:	00004517          	auipc	a0,0x4
ffffffffc0200a98:	b1450513          	addi	a0,a0,-1260 # ffffffffc02045a8 <etext+0x732>
ffffffffc0200a9c:	ef8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200aa0:	11043583          	ld	a1,272(s0)
ffffffffc0200aa4:	00004517          	auipc	a0,0x4
ffffffffc0200aa8:	b1c50513          	addi	a0,a0,-1252 # ffffffffc02045c0 <etext+0x74a>
ffffffffc0200aac:	ee8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200ab4:	6402                	ld	s0,0(sp)
ffffffffc0200ab6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab8:	00004517          	auipc	a0,0x4
ffffffffc0200abc:	b2050513          	addi	a0,a0,-1248 # ffffffffc02045d8 <etext+0x762>
}
ffffffffc0200ac0:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ac2:	ed2ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ac6 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    static int num = 0;
    switch (cause)
ffffffffc0200ac6:	11853783          	ld	a5,280(a0)
ffffffffc0200aca:	472d                	li	a4,11
ffffffffc0200acc:	0786                	slli	a5,a5,0x1
ffffffffc0200ace:	8385                	srli	a5,a5,0x1
ffffffffc0200ad0:	08f76e63          	bltu	a4,a5,ffffffffc0200b6c <interrupt_handler+0xa6>
ffffffffc0200ad4:	00005717          	auipc	a4,0x5
ffffffffc0200ad8:	cbc70713          	addi	a4,a4,-836 # ffffffffc0205790 <commands+0x48>
ffffffffc0200adc:	078a                	slli	a5,a5,0x2
ffffffffc0200ade:	97ba                	add	a5,a5,a4
ffffffffc0200ae0:	439c                	lw	a5,0(a5)
ffffffffc0200ae2:	97ba                	add	a5,a5,a4
ffffffffc0200ae4:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ae6:	00004517          	auipc	a0,0x4
ffffffffc0200aea:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0204650 <etext+0x7da>
ffffffffc0200aee:	ea6ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200af2:	00004517          	auipc	a0,0x4
ffffffffc0200af6:	b3e50513          	addi	a0,a0,-1218 # ffffffffc0204630 <etext+0x7ba>
ffffffffc0200afa:	e9aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200afe:	00004517          	auipc	a0,0x4
ffffffffc0200b02:	af250513          	addi	a0,a0,-1294 # ffffffffc02045f0 <etext+0x77a>
ffffffffc0200b06:	e8eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b0a:	00004517          	auipc	a0,0x4
ffffffffc0200b0e:	b0650513          	addi	a0,a0,-1274 # ffffffffc0204610 <etext+0x79a>
ffffffffc0200b12:	e82ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200b16:	1141                	addi	sp,sp,-16
ffffffffc0200b18:	e406                	sd	ra,8(sp)
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 请补充你在lab3中的代码 */ 
        clock_set_next_event();
ffffffffc0200b1a:	983ff0ef          	jal	ffffffffc020049c <clock_set_next_event>
        if (++ticks % TICK_NUM == 0) {
ffffffffc0200b1e:	0000d697          	auipc	a3,0xd
ffffffffc0200b22:	95a6b683          	ld	a3,-1702(a3) # ffffffffc020d478 <ticks>
ffffffffc0200b26:	28f5c737          	lui	a4,0x28f5c
ffffffffc0200b2a:	28f70713          	addi	a4,a4,655 # 28f5c28f <kern_entry-0xffffffff972a3d71>
ffffffffc0200b2e:	5c28f7b7          	lui	a5,0x5c28f
ffffffffc0200b32:	5c378793          	addi	a5,a5,1475 # 5c28f5c3 <kern_entry-0xffffffff63f70a3d>
ffffffffc0200b36:	0685                	addi	a3,a3,1
ffffffffc0200b38:	1702                	slli	a4,a4,0x20
ffffffffc0200b3a:	973e                	add	a4,a4,a5
ffffffffc0200b3c:	0026d793          	srli	a5,a3,0x2
ffffffffc0200b40:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc0200b44:	06400593          	li	a1,100
ffffffffc0200b48:	0000d717          	auipc	a4,0xd
ffffffffc0200b4c:	92d73823          	sd	a3,-1744(a4) # ffffffffc020d478 <ticks>
ffffffffc0200b50:	8389                	srli	a5,a5,0x2
ffffffffc0200b52:	02b787b3          	mul	a5,a5,a1
ffffffffc0200b56:	00f68c63          	beq	a3,a5,ffffffffc0200b6e <interrupt_handler+0xa8>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200b5a:	60a2                	ld	ra,8(sp)
ffffffffc0200b5c:	0141                	addi	sp,sp,16
ffffffffc0200b5e:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200b60:	00004517          	auipc	a0,0x4
ffffffffc0200b64:	b2050513          	addi	a0,a0,-1248 # ffffffffc0204680 <etext+0x80a>
ffffffffc0200b68:	e2cff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200b6c:	bde5                	j	ffffffffc0200a64 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b6e:	00004517          	auipc	a0,0x4
ffffffffc0200b72:	b0250513          	addi	a0,a0,-1278 # ffffffffc0204670 <etext+0x7fa>
ffffffffc0200b76:	e1eff0ef          	jal	ffffffffc0200194 <cprintf>
            if (++num == 10) {
ffffffffc0200b7a:	0000d797          	auipc	a5,0xd
ffffffffc0200b7e:	9167a783          	lw	a5,-1770(a5) # ffffffffc020d490 <num.0>
ffffffffc0200b82:	4729                	li	a4,10
ffffffffc0200b84:	2785                	addiw	a5,a5,1
ffffffffc0200b86:	0000d697          	auipc	a3,0xd
ffffffffc0200b8a:	90f6a523          	sw	a5,-1782(a3) # ffffffffc020d490 <num.0>
ffffffffc0200b8e:	fce796e3          	bne	a5,a4,ffffffffc0200b5a <interrupt_handler+0x94>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200b92:	4501                	li	a0,0
ffffffffc0200b94:	4581                	li	a1,0
ffffffffc0200b96:	4601                	li	a2,0
ffffffffc0200b98:	48a1                	li	a7,8
ffffffffc0200b9a:	00000073          	ecall
}
ffffffffc0200b9e:	bf75                	j	ffffffffc0200b5a <interrupt_handler+0x94>

ffffffffc0200ba0 <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200ba0:	11853783          	ld	a5,280(a0)
ffffffffc0200ba4:	473d                	li	a4,15
ffffffffc0200ba6:	0cf76563          	bltu	a4,a5,ffffffffc0200c70 <exception_handler+0xd0>
ffffffffc0200baa:	00005717          	auipc	a4,0x5
ffffffffc0200bae:	c1670713          	addi	a4,a4,-1002 # ffffffffc02057c0 <commands+0x78>
ffffffffc0200bb2:	078a                	slli	a5,a5,0x2
ffffffffc0200bb4:	97ba                	add	a5,a5,a4
ffffffffc0200bb6:	439c                	lw	a5,0(a5)
ffffffffc0200bb8:	97ba                	add	a5,a5,a4
ffffffffc0200bba:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200bbc:	00004517          	auipc	a0,0x4
ffffffffc0200bc0:	c6450513          	addi	a0,a0,-924 # ffffffffc0204820 <etext+0x9aa>
ffffffffc0200bc4:	dd0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200bc8:	00004517          	auipc	a0,0x4
ffffffffc0200bcc:	ad850513          	addi	a0,a0,-1320 # ffffffffc02046a0 <etext+0x82a>
ffffffffc0200bd0:	dc4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200bd4:	00004517          	auipc	a0,0x4
ffffffffc0200bd8:	aec50513          	addi	a0,a0,-1300 # ffffffffc02046c0 <etext+0x84a>
ffffffffc0200bdc:	db8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200be0:	00004517          	auipc	a0,0x4
ffffffffc0200be4:	b0050513          	addi	a0,a0,-1280 # ffffffffc02046e0 <etext+0x86a>
ffffffffc0200be8:	dacff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200bec:	00004517          	auipc	a0,0x4
ffffffffc0200bf0:	b0c50513          	addi	a0,a0,-1268 # ffffffffc02046f8 <etext+0x882>
ffffffffc0200bf4:	da0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200bf8:	00004517          	auipc	a0,0x4
ffffffffc0200bfc:	b1050513          	addi	a0,a0,-1264 # ffffffffc0204708 <etext+0x892>
ffffffffc0200c00:	d94ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200c04:	00004517          	auipc	a0,0x4
ffffffffc0200c08:	b2450513          	addi	a0,a0,-1244 # ffffffffc0204728 <etext+0x8b2>
ffffffffc0200c0c:	d88ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200c10:	00004517          	auipc	a0,0x4
ffffffffc0200c14:	b3050513          	addi	a0,a0,-1232 # ffffffffc0204740 <etext+0x8ca>
ffffffffc0200c18:	d7cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200c1c:	00004517          	auipc	a0,0x4
ffffffffc0200c20:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0204758 <etext+0x8e2>
ffffffffc0200c24:	d70ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200c28:	00004517          	auipc	a0,0x4
ffffffffc0200c2c:	b4850513          	addi	a0,a0,-1208 # ffffffffc0204770 <etext+0x8fa>
ffffffffc0200c30:	d64ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200c34:	00004517          	auipc	a0,0x4
ffffffffc0200c38:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0204790 <etext+0x91a>
ffffffffc0200c3c:	d58ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200c40:	00004517          	auipc	a0,0x4
ffffffffc0200c44:	b7050513          	addi	a0,a0,-1168 # ffffffffc02047b0 <etext+0x93a>
ffffffffc0200c48:	d4cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200c4c:	00004517          	auipc	a0,0x4
ffffffffc0200c50:	b8450513          	addi	a0,a0,-1148 # ffffffffc02047d0 <etext+0x95a>
ffffffffc0200c54:	d40ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200c58:	00004517          	auipc	a0,0x4
ffffffffc0200c5c:	b9850513          	addi	a0,a0,-1128 # ffffffffc02047f0 <etext+0x97a>
ffffffffc0200c60:	d34ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200c64:	00004517          	auipc	a0,0x4
ffffffffc0200c68:	ba450513          	addi	a0,a0,-1116 # ffffffffc0204808 <etext+0x992>
ffffffffc0200c6c:	d28ff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200c70:	bbd5                	j	ffffffffc0200a64 <print_trapframe>

ffffffffc0200c72 <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200c72:	11853783          	ld	a5,280(a0)
ffffffffc0200c76:	0007c363          	bltz	a5,ffffffffc0200c7c <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200c7a:	b71d                	j	ffffffffc0200ba0 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200c7c:	b5a9                	j	ffffffffc0200ac6 <interrupt_handler>
	...

ffffffffc0200c80 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200c80:	14011073          	csrw	sscratch,sp
ffffffffc0200c84:	712d                	addi	sp,sp,-288
ffffffffc0200c86:	e406                	sd	ra,8(sp)
ffffffffc0200c88:	ec0e                	sd	gp,24(sp)
ffffffffc0200c8a:	f012                	sd	tp,32(sp)
ffffffffc0200c8c:	f416                	sd	t0,40(sp)
ffffffffc0200c8e:	f81a                	sd	t1,48(sp)
ffffffffc0200c90:	fc1e                	sd	t2,56(sp)
ffffffffc0200c92:	e0a2                	sd	s0,64(sp)
ffffffffc0200c94:	e4a6                	sd	s1,72(sp)
ffffffffc0200c96:	e8aa                	sd	a0,80(sp)
ffffffffc0200c98:	ecae                	sd	a1,88(sp)
ffffffffc0200c9a:	f0b2                	sd	a2,96(sp)
ffffffffc0200c9c:	f4b6                	sd	a3,104(sp)
ffffffffc0200c9e:	f8ba                	sd	a4,112(sp)
ffffffffc0200ca0:	fcbe                	sd	a5,120(sp)
ffffffffc0200ca2:	e142                	sd	a6,128(sp)
ffffffffc0200ca4:	e546                	sd	a7,136(sp)
ffffffffc0200ca6:	e94a                	sd	s2,144(sp)
ffffffffc0200ca8:	ed4e                	sd	s3,152(sp)
ffffffffc0200caa:	f152                	sd	s4,160(sp)
ffffffffc0200cac:	f556                	sd	s5,168(sp)
ffffffffc0200cae:	f95a                	sd	s6,176(sp)
ffffffffc0200cb0:	fd5e                	sd	s7,184(sp)
ffffffffc0200cb2:	e1e2                	sd	s8,192(sp)
ffffffffc0200cb4:	e5e6                	sd	s9,200(sp)
ffffffffc0200cb6:	e9ea                	sd	s10,208(sp)
ffffffffc0200cb8:	edee                	sd	s11,216(sp)
ffffffffc0200cba:	f1f2                	sd	t3,224(sp)
ffffffffc0200cbc:	f5f6                	sd	t4,232(sp)
ffffffffc0200cbe:	f9fa                	sd	t5,240(sp)
ffffffffc0200cc0:	fdfe                	sd	t6,248(sp)
ffffffffc0200cc2:	14002473          	csrr	s0,sscratch
ffffffffc0200cc6:	100024f3          	csrr	s1,sstatus
ffffffffc0200cca:	14102973          	csrr	s2,sepc
ffffffffc0200cce:	143029f3          	csrr	s3,stval
ffffffffc0200cd2:	14202a73          	csrr	s4,scause
ffffffffc0200cd6:	e822                	sd	s0,16(sp)
ffffffffc0200cd8:	e226                	sd	s1,256(sp)
ffffffffc0200cda:	e64a                	sd	s2,264(sp)
ffffffffc0200cdc:	ea4e                	sd	s3,272(sp)
ffffffffc0200cde:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200ce0:	850a                	mv	a0,sp
    jal trap
ffffffffc0200ce2:	f91ff0ef          	jal	ffffffffc0200c72 <trap>

ffffffffc0200ce6 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200ce6:	6492                	ld	s1,256(sp)
ffffffffc0200ce8:	6932                	ld	s2,264(sp)
ffffffffc0200cea:	10049073          	csrw	sstatus,s1
ffffffffc0200cee:	14191073          	csrw	sepc,s2
ffffffffc0200cf2:	60a2                	ld	ra,8(sp)
ffffffffc0200cf4:	61e2                	ld	gp,24(sp)
ffffffffc0200cf6:	7202                	ld	tp,32(sp)
ffffffffc0200cf8:	72a2                	ld	t0,40(sp)
ffffffffc0200cfa:	7342                	ld	t1,48(sp)
ffffffffc0200cfc:	73e2                	ld	t2,56(sp)
ffffffffc0200cfe:	6406                	ld	s0,64(sp)
ffffffffc0200d00:	64a6                	ld	s1,72(sp)
ffffffffc0200d02:	6546                	ld	a0,80(sp)
ffffffffc0200d04:	65e6                	ld	a1,88(sp)
ffffffffc0200d06:	7606                	ld	a2,96(sp)
ffffffffc0200d08:	76a6                	ld	a3,104(sp)
ffffffffc0200d0a:	7746                	ld	a4,112(sp)
ffffffffc0200d0c:	77e6                	ld	a5,120(sp)
ffffffffc0200d0e:	680a                	ld	a6,128(sp)
ffffffffc0200d10:	68aa                	ld	a7,136(sp)
ffffffffc0200d12:	694a                	ld	s2,144(sp)
ffffffffc0200d14:	69ea                	ld	s3,152(sp)
ffffffffc0200d16:	7a0a                	ld	s4,160(sp)
ffffffffc0200d18:	7aaa                	ld	s5,168(sp)
ffffffffc0200d1a:	7b4a                	ld	s6,176(sp)
ffffffffc0200d1c:	7bea                	ld	s7,184(sp)
ffffffffc0200d1e:	6c0e                	ld	s8,192(sp)
ffffffffc0200d20:	6cae                	ld	s9,200(sp)
ffffffffc0200d22:	6d4e                	ld	s10,208(sp)
ffffffffc0200d24:	6dee                	ld	s11,216(sp)
ffffffffc0200d26:	7e0e                	ld	t3,224(sp)
ffffffffc0200d28:	7eae                	ld	t4,232(sp)
ffffffffc0200d2a:	7f4e                	ld	t5,240(sp)
ffffffffc0200d2c:	7fee                	ld	t6,248(sp)
ffffffffc0200d2e:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200d30:	10200073          	sret

ffffffffc0200d34 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d34:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d36:	bf45                	j	ffffffffc0200ce6 <__trapret>
ffffffffc0200d38:	0001                	nop

ffffffffc0200d3a <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200d3a:	00008797          	auipc	a5,0x8
ffffffffc0200d3e:	6f678793          	addi	a5,a5,1782 # ffffffffc0209430 <free_area>
ffffffffc0200d42:	e79c                	sd	a5,8(a5)
ffffffffc0200d44:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200d46:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200d4a:	8082                	ret

ffffffffc0200d4c <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200d4c:	00008517          	auipc	a0,0x8
ffffffffc0200d50:	6f456503          	lwu	a0,1780(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200d54:	8082                	ret

ffffffffc0200d56 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200d56:	711d                	addi	sp,sp,-96
ffffffffc0200d58:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200d5a:	00008917          	auipc	s2,0x8
ffffffffc0200d5e:	6d690913          	addi	s2,s2,1750 # ffffffffc0209430 <free_area>
ffffffffc0200d62:	00893783          	ld	a5,8(s2)
ffffffffc0200d66:	ec86                	sd	ra,88(sp)
ffffffffc0200d68:	e8a2                	sd	s0,80(sp)
ffffffffc0200d6a:	e4a6                	sd	s1,72(sp)
ffffffffc0200d6c:	fc4e                	sd	s3,56(sp)
ffffffffc0200d6e:	f852                	sd	s4,48(sp)
ffffffffc0200d70:	f456                	sd	s5,40(sp)
ffffffffc0200d72:	f05a                	sd	s6,32(sp)
ffffffffc0200d74:	ec5e                	sd	s7,24(sp)
ffffffffc0200d76:	e862                	sd	s8,16(sp)
ffffffffc0200d78:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d7a:	2f278763          	beq	a5,s2,ffffffffc0201068 <default_check+0x312>
    int count = 0, total = 0;
ffffffffc0200d7e:	4401                	li	s0,0
ffffffffc0200d80:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d82:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d86:	8b09                	andi	a4,a4,2
ffffffffc0200d88:	2e070463          	beqz	a4,ffffffffc0201070 <default_check+0x31a>
        count ++, total += p->property;
ffffffffc0200d8c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d90:	679c                	ld	a5,8(a5)
ffffffffc0200d92:	2485                	addiw	s1,s1,1
ffffffffc0200d94:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d96:	ff2796e3          	bne	a5,s2,ffffffffc0200d82 <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200d9a:	89a2                	mv	s3,s0
ffffffffc0200d9c:	745000ef          	jal	ffffffffc0201ce0 <nr_free_pages>
ffffffffc0200da0:	73351863          	bne	a0,s3,ffffffffc02014d0 <default_check+0x77a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200da4:	4505                	li	a0,1
ffffffffc0200da6:	6c9000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200daa:	8a2a                	mv	s4,a0
ffffffffc0200dac:	46050263          	beqz	a0,ffffffffc0201210 <default_check+0x4ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200db0:	4505                	li	a0,1
ffffffffc0200db2:	6bd000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200db6:	89aa                	mv	s3,a0
ffffffffc0200db8:	72050c63          	beqz	a0,ffffffffc02014f0 <default_check+0x79a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200dbc:	4505                	li	a0,1
ffffffffc0200dbe:	6b1000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200dc2:	8aaa                	mv	s5,a0
ffffffffc0200dc4:	4c050663          	beqz	a0,ffffffffc0201290 <default_check+0x53a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200dc8:	40aa07b3          	sub	a5,s4,a0
ffffffffc0200dcc:	40a98733          	sub	a4,s3,a0
ffffffffc0200dd0:	0017b793          	seqz	a5,a5
ffffffffc0200dd4:	00173713          	seqz	a4,a4
ffffffffc0200dd8:	8fd9                	or	a5,a5,a4
ffffffffc0200dda:	30079b63          	bnez	a5,ffffffffc02010f0 <default_check+0x39a>
ffffffffc0200dde:	313a0963          	beq	s4,s3,ffffffffc02010f0 <default_check+0x39a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200de2:	000a2783          	lw	a5,0(s4)
ffffffffc0200de6:	2a079563          	bnez	a5,ffffffffc0201090 <default_check+0x33a>
ffffffffc0200dea:	0009a783          	lw	a5,0(s3)
ffffffffc0200dee:	2a079163          	bnez	a5,ffffffffc0201090 <default_check+0x33a>
ffffffffc0200df2:	411c                	lw	a5,0(a0)
ffffffffc0200df4:	28079e63          	bnez	a5,ffffffffc0201090 <default_check+0x33a>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200df8:	0000c797          	auipc	a5,0xc
ffffffffc0200dfc:	6d07b783          	ld	a5,1744(a5) # ffffffffc020d4c8 <pages>
ffffffffc0200e00:	00005617          	auipc	a2,0x5
ffffffffc0200e04:	bc863603          	ld	a2,-1080(a2) # ffffffffc02059c8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e08:	0000c697          	auipc	a3,0xc
ffffffffc0200e0c:	6b86b683          	ld	a3,1720(a3) # ffffffffc020d4c0 <npage>
ffffffffc0200e10:	40fa0733          	sub	a4,s4,a5
ffffffffc0200e14:	8719                	srai	a4,a4,0x6
ffffffffc0200e16:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e18:	0732                	slli	a4,a4,0xc
ffffffffc0200e1a:	06b2                	slli	a3,a3,0xc
ffffffffc0200e1c:	2ad77a63          	bgeu	a4,a3,ffffffffc02010d0 <default_check+0x37a>
    return page - pages + nbase;
ffffffffc0200e20:	40f98733          	sub	a4,s3,a5
ffffffffc0200e24:	8719                	srai	a4,a4,0x6
ffffffffc0200e26:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e28:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e2a:	4ed77363          	bgeu	a4,a3,ffffffffc0201310 <default_check+0x5ba>
    return page - pages + nbase;
ffffffffc0200e2e:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e32:	8799                	srai	a5,a5,0x6
ffffffffc0200e34:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e36:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e38:	32d7fc63          	bgeu	a5,a3,ffffffffc0201170 <default_check+0x41a>
    assert(alloc_page() == NULL);
ffffffffc0200e3c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e3e:	00093c03          	ld	s8,0(s2)
ffffffffc0200e42:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e46:	00008b17          	auipc	s6,0x8
ffffffffc0200e4a:	5fab2b03          	lw	s6,1530(s6) # ffffffffc0209440 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200e4e:	01293023          	sd	s2,0(s2)
ffffffffc0200e52:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200e56:	00008797          	auipc	a5,0x8
ffffffffc0200e5a:	5e07a523          	sw	zero,1514(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e5e:	611000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200e62:	2e051763          	bnez	a0,ffffffffc0201150 <default_check+0x3fa>
    free_page(p0);
ffffffffc0200e66:	8552                	mv	a0,s4
ffffffffc0200e68:	4585                	li	a1,1
ffffffffc0200e6a:	63f000ef          	jal	ffffffffc0201ca8 <free_pages>
    free_page(p1);
ffffffffc0200e6e:	854e                	mv	a0,s3
ffffffffc0200e70:	4585                	li	a1,1
ffffffffc0200e72:	637000ef          	jal	ffffffffc0201ca8 <free_pages>
    free_page(p2);
ffffffffc0200e76:	8556                	mv	a0,s5
ffffffffc0200e78:	4585                	li	a1,1
ffffffffc0200e7a:	62f000ef          	jal	ffffffffc0201ca8 <free_pages>
    assert(nr_free == 3);
ffffffffc0200e7e:	00008717          	auipc	a4,0x8
ffffffffc0200e82:	5c272703          	lw	a4,1474(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200e86:	478d                	li	a5,3
ffffffffc0200e88:	2af71463          	bne	a4,a5,ffffffffc0201130 <default_check+0x3da>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e8c:	4505                	li	a0,1
ffffffffc0200e8e:	5e1000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200e92:	89aa                	mv	s3,a0
ffffffffc0200e94:	26050e63          	beqz	a0,ffffffffc0201110 <default_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e98:	4505                	li	a0,1
ffffffffc0200e9a:	5d5000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200e9e:	8aaa                	mv	s5,a0
ffffffffc0200ea0:	3c050863          	beqz	a0,ffffffffc0201270 <default_check+0x51a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ea4:	4505                	li	a0,1
ffffffffc0200ea6:	5c9000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200eaa:	8a2a                	mv	s4,a0
ffffffffc0200eac:	3a050263          	beqz	a0,ffffffffc0201250 <default_check+0x4fa>
    assert(alloc_page() == NULL);
ffffffffc0200eb0:	4505                	li	a0,1
ffffffffc0200eb2:	5bd000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200eb6:	36051d63          	bnez	a0,ffffffffc0201230 <default_check+0x4da>
    free_page(p0);
ffffffffc0200eba:	4585                	li	a1,1
ffffffffc0200ebc:	854e                	mv	a0,s3
ffffffffc0200ebe:	5eb000ef          	jal	ffffffffc0201ca8 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200ec2:	00893783          	ld	a5,8(s2)
ffffffffc0200ec6:	1f278563          	beq	a5,s2,ffffffffc02010b0 <default_check+0x35a>
    assert((p = alloc_page()) == p0);
ffffffffc0200eca:	4505                	li	a0,1
ffffffffc0200ecc:	5a3000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200ed0:	8caa                	mv	s9,a0
ffffffffc0200ed2:	30a99f63          	bne	s3,a0,ffffffffc02011f0 <default_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc0200ed6:	4505                	li	a0,1
ffffffffc0200ed8:	597000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200edc:	2e051a63          	bnez	a0,ffffffffc02011d0 <default_check+0x47a>
    assert(nr_free == 0);
ffffffffc0200ee0:	00008797          	auipc	a5,0x8
ffffffffc0200ee4:	5607a783          	lw	a5,1376(a5) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200ee8:	2c079463          	bnez	a5,ffffffffc02011b0 <default_check+0x45a>
    free_page(p);
ffffffffc0200eec:	8566                	mv	a0,s9
ffffffffc0200eee:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200ef0:	01893023          	sd	s8,0(s2)
ffffffffc0200ef4:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200ef8:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200efc:	5ad000ef          	jal	ffffffffc0201ca8 <free_pages>
    free_page(p1);
ffffffffc0200f00:	8556                	mv	a0,s5
ffffffffc0200f02:	4585                	li	a1,1
ffffffffc0200f04:	5a5000ef          	jal	ffffffffc0201ca8 <free_pages>
    free_page(p2);
ffffffffc0200f08:	8552                	mv	a0,s4
ffffffffc0200f0a:	4585                	li	a1,1
ffffffffc0200f0c:	59d000ef          	jal	ffffffffc0201ca8 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f10:	4515                	li	a0,5
ffffffffc0200f12:	55d000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200f16:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f18:	26050c63          	beqz	a0,ffffffffc0201190 <default_check+0x43a>
ffffffffc0200f1c:	651c                	ld	a5,8(a0)
ffffffffc0200f1e:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f20:	8b85                	andi	a5,a5,1
ffffffffc0200f22:	54079763          	bnez	a5,ffffffffc0201470 <default_check+0x71a>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f26:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f28:	00093b83          	ld	s7,0(s2)
ffffffffc0200f2c:	00893b03          	ld	s6,8(s2)
ffffffffc0200f30:	01293023          	sd	s2,0(s2)
ffffffffc0200f34:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200f38:	537000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200f3c:	50051a63          	bnez	a0,ffffffffc0201450 <default_check+0x6fa>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200f40:	08098a13          	addi	s4,s3,128
ffffffffc0200f44:	8552                	mv	a0,s4
ffffffffc0200f46:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200f48:	00008c17          	auipc	s8,0x8
ffffffffc0200f4c:	4f8c2c03          	lw	s8,1272(s8) # ffffffffc0209440 <free_area+0x10>
    nr_free = 0;
ffffffffc0200f50:	00008797          	auipc	a5,0x8
ffffffffc0200f54:	4e07a823          	sw	zero,1264(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200f58:	551000ef          	jal	ffffffffc0201ca8 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f5c:	4511                	li	a0,4
ffffffffc0200f5e:	511000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200f62:	4c051763          	bnez	a0,ffffffffc0201430 <default_check+0x6da>
ffffffffc0200f66:	0889b783          	ld	a5,136(s3)
ffffffffc0200f6a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200f6c:	8b85                	andi	a5,a5,1
ffffffffc0200f6e:	4a078163          	beqz	a5,ffffffffc0201410 <default_check+0x6ba>
ffffffffc0200f72:	0909a503          	lw	a0,144(s3)
ffffffffc0200f76:	478d                	li	a5,3
ffffffffc0200f78:	48f51c63          	bne	a0,a5,ffffffffc0201410 <default_check+0x6ba>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200f7c:	4f3000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200f80:	8aaa                	mv	s5,a0
ffffffffc0200f82:	46050763          	beqz	a0,ffffffffc02013f0 <default_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc0200f86:	4505                	li	a0,1
ffffffffc0200f88:	4e7000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200f8c:	44051263          	bnez	a0,ffffffffc02013d0 <default_check+0x67a>
    assert(p0 + 2 == p1);
ffffffffc0200f90:	435a1063          	bne	s4,s5,ffffffffc02013b0 <default_check+0x65a>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200f94:	4585                	li	a1,1
ffffffffc0200f96:	854e                	mv	a0,s3
ffffffffc0200f98:	511000ef          	jal	ffffffffc0201ca8 <free_pages>
    free_pages(p1, 3);
ffffffffc0200f9c:	8552                	mv	a0,s4
ffffffffc0200f9e:	458d                	li	a1,3
ffffffffc0200fa0:	509000ef          	jal	ffffffffc0201ca8 <free_pages>
ffffffffc0200fa4:	0089b783          	ld	a5,8(s3)
ffffffffc0200fa8:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200faa:	8b85                	andi	a5,a5,1
ffffffffc0200fac:	3e078263          	beqz	a5,ffffffffc0201390 <default_check+0x63a>
ffffffffc0200fb0:	0109aa83          	lw	s5,16(s3)
ffffffffc0200fb4:	4785                	li	a5,1
ffffffffc0200fb6:	3cfa9d63          	bne	s5,a5,ffffffffc0201390 <default_check+0x63a>
ffffffffc0200fba:	008a3783          	ld	a5,8(s4)
ffffffffc0200fbe:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200fc0:	8b85                	andi	a5,a5,1
ffffffffc0200fc2:	3a078763          	beqz	a5,ffffffffc0201370 <default_check+0x61a>
ffffffffc0200fc6:	010a2703          	lw	a4,16(s4)
ffffffffc0200fca:	478d                	li	a5,3
ffffffffc0200fcc:	3af71263          	bne	a4,a5,ffffffffc0201370 <default_check+0x61a>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200fd0:	8556                	mv	a0,s5
ffffffffc0200fd2:	49d000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200fd6:	36a99d63          	bne	s3,a0,ffffffffc0201350 <default_check+0x5fa>
    free_page(p0);
ffffffffc0200fda:	85d6                	mv	a1,s5
ffffffffc0200fdc:	4cd000ef          	jal	ffffffffc0201ca8 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200fe0:	4509                	li	a0,2
ffffffffc0200fe2:	48d000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0200fe6:	34aa1563          	bne	s4,a0,ffffffffc0201330 <default_check+0x5da>

    free_pages(p0, 2);
ffffffffc0200fea:	4589                	li	a1,2
ffffffffc0200fec:	4bd000ef          	jal	ffffffffc0201ca8 <free_pages>
    free_page(p2);
ffffffffc0200ff0:	04098513          	addi	a0,s3,64
ffffffffc0200ff4:	85d6                	mv	a1,s5
ffffffffc0200ff6:	4b3000ef          	jal	ffffffffc0201ca8 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200ffa:	4515                	li	a0,5
ffffffffc0200ffc:	473000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc0201000:	89aa                	mv	s3,a0
ffffffffc0201002:	48050763          	beqz	a0,ffffffffc0201490 <default_check+0x73a>
    assert(alloc_page() == NULL);
ffffffffc0201006:	8556                	mv	a0,s5
ffffffffc0201008:	467000ef          	jal	ffffffffc0201c6e <alloc_pages>
ffffffffc020100c:	2e051263          	bnez	a0,ffffffffc02012f0 <default_check+0x59a>

    assert(nr_free == 0);
ffffffffc0201010:	00008797          	auipc	a5,0x8
ffffffffc0201014:	4307a783          	lw	a5,1072(a5) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201018:	2a079c63          	bnez	a5,ffffffffc02012d0 <default_check+0x57a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020101c:	854e                	mv	a0,s3
ffffffffc020101e:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0201020:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0201024:	01793023          	sd	s7,0(s2)
ffffffffc0201028:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc020102c:	47d000ef          	jal	ffffffffc0201ca8 <free_pages>
    return listelm->next;
ffffffffc0201030:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201034:	01278963          	beq	a5,s2,ffffffffc0201046 <default_check+0x2f0>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201038:	ff87a703          	lw	a4,-8(a5)
ffffffffc020103c:	679c                	ld	a5,8(a5)
ffffffffc020103e:	34fd                	addiw	s1,s1,-1
ffffffffc0201040:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201042:	ff279be3          	bne	a5,s2,ffffffffc0201038 <default_check+0x2e2>
    }
    assert(count == 0);
ffffffffc0201046:	26049563          	bnez	s1,ffffffffc02012b0 <default_check+0x55a>
    assert(total == 0);
ffffffffc020104a:	46041363          	bnez	s0,ffffffffc02014b0 <default_check+0x75a>
}
ffffffffc020104e:	60e6                	ld	ra,88(sp)
ffffffffc0201050:	6446                	ld	s0,80(sp)
ffffffffc0201052:	64a6                	ld	s1,72(sp)
ffffffffc0201054:	6906                	ld	s2,64(sp)
ffffffffc0201056:	79e2                	ld	s3,56(sp)
ffffffffc0201058:	7a42                	ld	s4,48(sp)
ffffffffc020105a:	7aa2                	ld	s5,40(sp)
ffffffffc020105c:	7b02                	ld	s6,32(sp)
ffffffffc020105e:	6be2                	ld	s7,24(sp)
ffffffffc0201060:	6c42                	ld	s8,16(sp)
ffffffffc0201062:	6ca2                	ld	s9,8(sp)
ffffffffc0201064:	6125                	addi	sp,sp,96
ffffffffc0201066:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201068:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020106a:	4401                	li	s0,0
ffffffffc020106c:	4481                	li	s1,0
ffffffffc020106e:	b33d                	j	ffffffffc0200d9c <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0201070:	00003697          	auipc	a3,0x3
ffffffffc0201074:	7c868693          	addi	a3,a3,1992 # ffffffffc0204838 <etext+0x9c2>
ffffffffc0201078:	00003617          	auipc	a2,0x3
ffffffffc020107c:	7d060613          	addi	a2,a2,2000 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201080:	0f000593          	li	a1,240
ffffffffc0201084:	00003517          	auipc	a0,0x3
ffffffffc0201088:	7dc50513          	addi	a0,a0,2012 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020108c:	b7aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201090:	00004697          	auipc	a3,0x4
ffffffffc0201094:	89068693          	addi	a3,a3,-1904 # ffffffffc0204920 <etext+0xaaa>
ffffffffc0201098:	00003617          	auipc	a2,0x3
ffffffffc020109c:	7b060613          	addi	a2,a2,1968 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02010a0:	0be00593          	li	a1,190
ffffffffc02010a4:	00003517          	auipc	a0,0x3
ffffffffc02010a8:	7bc50513          	addi	a0,a0,1980 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02010ac:	b5aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02010b0:	00004697          	auipc	a3,0x4
ffffffffc02010b4:	93868693          	addi	a3,a3,-1736 # ffffffffc02049e8 <etext+0xb72>
ffffffffc02010b8:	00003617          	auipc	a2,0x3
ffffffffc02010bc:	79060613          	addi	a2,a2,1936 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02010c0:	0d900593          	li	a1,217
ffffffffc02010c4:	00003517          	auipc	a0,0x3
ffffffffc02010c8:	79c50513          	addi	a0,a0,1948 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02010cc:	b3aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010d0:	00004697          	auipc	a3,0x4
ffffffffc02010d4:	89068693          	addi	a3,a3,-1904 # ffffffffc0204960 <etext+0xaea>
ffffffffc02010d8:	00003617          	auipc	a2,0x3
ffffffffc02010dc:	77060613          	addi	a2,a2,1904 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02010e0:	0c000593          	li	a1,192
ffffffffc02010e4:	00003517          	auipc	a0,0x3
ffffffffc02010e8:	77c50513          	addi	a0,a0,1916 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02010ec:	b1aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010f0:	00004697          	auipc	a3,0x4
ffffffffc02010f4:	80868693          	addi	a3,a3,-2040 # ffffffffc02048f8 <etext+0xa82>
ffffffffc02010f8:	00003617          	auipc	a2,0x3
ffffffffc02010fc:	75060613          	addi	a2,a2,1872 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201100:	0bd00593          	li	a1,189
ffffffffc0201104:	00003517          	auipc	a0,0x3
ffffffffc0201108:	75c50513          	addi	a0,a0,1884 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020110c:	afaff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201110:	00003697          	auipc	a3,0x3
ffffffffc0201114:	78868693          	addi	a3,a3,1928 # ffffffffc0204898 <etext+0xa22>
ffffffffc0201118:	00003617          	auipc	a2,0x3
ffffffffc020111c:	73060613          	addi	a2,a2,1840 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201120:	0d200593          	li	a1,210
ffffffffc0201124:	00003517          	auipc	a0,0x3
ffffffffc0201128:	73c50513          	addi	a0,a0,1852 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020112c:	adaff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 3);
ffffffffc0201130:	00004697          	auipc	a3,0x4
ffffffffc0201134:	8a868693          	addi	a3,a3,-1880 # ffffffffc02049d8 <etext+0xb62>
ffffffffc0201138:	00003617          	auipc	a2,0x3
ffffffffc020113c:	71060613          	addi	a2,a2,1808 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201140:	0d000593          	li	a1,208
ffffffffc0201144:	00003517          	auipc	a0,0x3
ffffffffc0201148:	71c50513          	addi	a0,a0,1820 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020114c:	abaff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201150:	00004697          	auipc	a3,0x4
ffffffffc0201154:	87068693          	addi	a3,a3,-1936 # ffffffffc02049c0 <etext+0xb4a>
ffffffffc0201158:	00003617          	auipc	a2,0x3
ffffffffc020115c:	6f060613          	addi	a2,a2,1776 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201160:	0cb00593          	li	a1,203
ffffffffc0201164:	00003517          	auipc	a0,0x3
ffffffffc0201168:	6fc50513          	addi	a0,a0,1788 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020116c:	a9aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201170:	00004697          	auipc	a3,0x4
ffffffffc0201174:	83068693          	addi	a3,a3,-2000 # ffffffffc02049a0 <etext+0xb2a>
ffffffffc0201178:	00003617          	auipc	a2,0x3
ffffffffc020117c:	6d060613          	addi	a2,a2,1744 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201180:	0c200593          	li	a1,194
ffffffffc0201184:	00003517          	auipc	a0,0x3
ffffffffc0201188:	6dc50513          	addi	a0,a0,1756 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020118c:	a7aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 != NULL);
ffffffffc0201190:	00004697          	auipc	a3,0x4
ffffffffc0201194:	8a068693          	addi	a3,a3,-1888 # ffffffffc0204a30 <etext+0xbba>
ffffffffc0201198:	00003617          	auipc	a2,0x3
ffffffffc020119c:	6b060613          	addi	a2,a2,1712 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02011a0:	0f800593          	li	a1,248
ffffffffc02011a4:	00003517          	auipc	a0,0x3
ffffffffc02011a8:	6bc50513          	addi	a0,a0,1724 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02011ac:	a5aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 0);
ffffffffc02011b0:	00004697          	auipc	a3,0x4
ffffffffc02011b4:	87068693          	addi	a3,a3,-1936 # ffffffffc0204a20 <etext+0xbaa>
ffffffffc02011b8:	00003617          	auipc	a2,0x3
ffffffffc02011bc:	69060613          	addi	a2,a2,1680 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02011c0:	0df00593          	li	a1,223
ffffffffc02011c4:	00003517          	auipc	a0,0x3
ffffffffc02011c8:	69c50513          	addi	a0,a0,1692 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02011cc:	a3aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011d0:	00003697          	auipc	a3,0x3
ffffffffc02011d4:	7f068693          	addi	a3,a3,2032 # ffffffffc02049c0 <etext+0xb4a>
ffffffffc02011d8:	00003617          	auipc	a2,0x3
ffffffffc02011dc:	67060613          	addi	a2,a2,1648 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02011e0:	0dd00593          	li	a1,221
ffffffffc02011e4:	00003517          	auipc	a0,0x3
ffffffffc02011e8:	67c50513          	addi	a0,a0,1660 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02011ec:	a1aff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02011f0:	00004697          	auipc	a3,0x4
ffffffffc02011f4:	81068693          	addi	a3,a3,-2032 # ffffffffc0204a00 <etext+0xb8a>
ffffffffc02011f8:	00003617          	auipc	a2,0x3
ffffffffc02011fc:	65060613          	addi	a2,a2,1616 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201200:	0dc00593          	li	a1,220
ffffffffc0201204:	00003517          	auipc	a0,0x3
ffffffffc0201208:	65c50513          	addi	a0,a0,1628 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020120c:	9faff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201210:	00003697          	auipc	a3,0x3
ffffffffc0201214:	68868693          	addi	a3,a3,1672 # ffffffffc0204898 <etext+0xa22>
ffffffffc0201218:	00003617          	auipc	a2,0x3
ffffffffc020121c:	63060613          	addi	a2,a2,1584 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201220:	0b900593          	li	a1,185
ffffffffc0201224:	00003517          	auipc	a0,0x3
ffffffffc0201228:	63c50513          	addi	a0,a0,1596 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020122c:	9daff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201230:	00003697          	auipc	a3,0x3
ffffffffc0201234:	79068693          	addi	a3,a3,1936 # ffffffffc02049c0 <etext+0xb4a>
ffffffffc0201238:	00003617          	auipc	a2,0x3
ffffffffc020123c:	61060613          	addi	a2,a2,1552 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201240:	0d600593          	li	a1,214
ffffffffc0201244:	00003517          	auipc	a0,0x3
ffffffffc0201248:	61c50513          	addi	a0,a0,1564 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020124c:	9baff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201250:	00003697          	auipc	a3,0x3
ffffffffc0201254:	68868693          	addi	a3,a3,1672 # ffffffffc02048d8 <etext+0xa62>
ffffffffc0201258:	00003617          	auipc	a2,0x3
ffffffffc020125c:	5f060613          	addi	a2,a2,1520 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201260:	0d400593          	li	a1,212
ffffffffc0201264:	00003517          	auipc	a0,0x3
ffffffffc0201268:	5fc50513          	addi	a0,a0,1532 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020126c:	99aff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201270:	00003697          	auipc	a3,0x3
ffffffffc0201274:	64868693          	addi	a3,a3,1608 # ffffffffc02048b8 <etext+0xa42>
ffffffffc0201278:	00003617          	auipc	a2,0x3
ffffffffc020127c:	5d060613          	addi	a2,a2,1488 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201280:	0d300593          	li	a1,211
ffffffffc0201284:	00003517          	auipc	a0,0x3
ffffffffc0201288:	5dc50513          	addi	a0,a0,1500 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020128c:	97aff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201290:	00003697          	auipc	a3,0x3
ffffffffc0201294:	64868693          	addi	a3,a3,1608 # ffffffffc02048d8 <etext+0xa62>
ffffffffc0201298:	00003617          	auipc	a2,0x3
ffffffffc020129c:	5b060613          	addi	a2,a2,1456 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02012a0:	0bb00593          	li	a1,187
ffffffffc02012a4:	00003517          	auipc	a0,0x3
ffffffffc02012a8:	5bc50513          	addi	a0,a0,1468 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02012ac:	95aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(count == 0);
ffffffffc02012b0:	00004697          	auipc	a3,0x4
ffffffffc02012b4:	8d068693          	addi	a3,a3,-1840 # ffffffffc0204b80 <etext+0xd0a>
ffffffffc02012b8:	00003617          	auipc	a2,0x3
ffffffffc02012bc:	59060613          	addi	a2,a2,1424 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02012c0:	12500593          	li	a1,293
ffffffffc02012c4:	00003517          	auipc	a0,0x3
ffffffffc02012c8:	59c50513          	addi	a0,a0,1436 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02012cc:	93aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 0);
ffffffffc02012d0:	00003697          	auipc	a3,0x3
ffffffffc02012d4:	75068693          	addi	a3,a3,1872 # ffffffffc0204a20 <etext+0xbaa>
ffffffffc02012d8:	00003617          	auipc	a2,0x3
ffffffffc02012dc:	57060613          	addi	a2,a2,1392 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02012e0:	11a00593          	li	a1,282
ffffffffc02012e4:	00003517          	auipc	a0,0x3
ffffffffc02012e8:	57c50513          	addi	a0,a0,1404 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02012ec:	91aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012f0:	00003697          	auipc	a3,0x3
ffffffffc02012f4:	6d068693          	addi	a3,a3,1744 # ffffffffc02049c0 <etext+0xb4a>
ffffffffc02012f8:	00003617          	auipc	a2,0x3
ffffffffc02012fc:	55060613          	addi	a2,a2,1360 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201300:	11800593          	li	a1,280
ffffffffc0201304:	00003517          	auipc	a0,0x3
ffffffffc0201308:	55c50513          	addi	a0,a0,1372 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020130c:	8faff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201310:	00003697          	auipc	a3,0x3
ffffffffc0201314:	67068693          	addi	a3,a3,1648 # ffffffffc0204980 <etext+0xb0a>
ffffffffc0201318:	00003617          	auipc	a2,0x3
ffffffffc020131c:	53060613          	addi	a2,a2,1328 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201320:	0c100593          	li	a1,193
ffffffffc0201324:	00003517          	auipc	a0,0x3
ffffffffc0201328:	53c50513          	addi	a0,a0,1340 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020132c:	8daff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201330:	00004697          	auipc	a3,0x4
ffffffffc0201334:	81068693          	addi	a3,a3,-2032 # ffffffffc0204b40 <etext+0xcca>
ffffffffc0201338:	00003617          	auipc	a2,0x3
ffffffffc020133c:	51060613          	addi	a2,a2,1296 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201340:	11200593          	li	a1,274
ffffffffc0201344:	00003517          	auipc	a0,0x3
ffffffffc0201348:	51c50513          	addi	a0,a0,1308 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020134c:	8baff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201350:	00003697          	auipc	a3,0x3
ffffffffc0201354:	7d068693          	addi	a3,a3,2000 # ffffffffc0204b20 <etext+0xcaa>
ffffffffc0201358:	00003617          	auipc	a2,0x3
ffffffffc020135c:	4f060613          	addi	a2,a2,1264 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201360:	11000593          	li	a1,272
ffffffffc0201364:	00003517          	auipc	a0,0x3
ffffffffc0201368:	4fc50513          	addi	a0,a0,1276 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020136c:	89aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201370:	00003697          	auipc	a3,0x3
ffffffffc0201374:	78868693          	addi	a3,a3,1928 # ffffffffc0204af8 <etext+0xc82>
ffffffffc0201378:	00003617          	auipc	a2,0x3
ffffffffc020137c:	4d060613          	addi	a2,a2,1232 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201380:	10e00593          	li	a1,270
ffffffffc0201384:	00003517          	auipc	a0,0x3
ffffffffc0201388:	4dc50513          	addi	a0,a0,1244 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020138c:	87aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201390:	00003697          	auipc	a3,0x3
ffffffffc0201394:	74068693          	addi	a3,a3,1856 # ffffffffc0204ad0 <etext+0xc5a>
ffffffffc0201398:	00003617          	auipc	a2,0x3
ffffffffc020139c:	4b060613          	addi	a2,a2,1200 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02013a0:	10d00593          	li	a1,269
ffffffffc02013a4:	00003517          	auipc	a0,0x3
ffffffffc02013a8:	4bc50513          	addi	a0,a0,1212 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02013ac:	85aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02013b0:	00003697          	auipc	a3,0x3
ffffffffc02013b4:	71068693          	addi	a3,a3,1808 # ffffffffc0204ac0 <etext+0xc4a>
ffffffffc02013b8:	00003617          	auipc	a2,0x3
ffffffffc02013bc:	49060613          	addi	a2,a2,1168 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02013c0:	10800593          	li	a1,264
ffffffffc02013c4:	00003517          	auipc	a0,0x3
ffffffffc02013c8:	49c50513          	addi	a0,a0,1180 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02013cc:	83aff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013d0:	00003697          	auipc	a3,0x3
ffffffffc02013d4:	5f068693          	addi	a3,a3,1520 # ffffffffc02049c0 <etext+0xb4a>
ffffffffc02013d8:	00003617          	auipc	a2,0x3
ffffffffc02013dc:	47060613          	addi	a2,a2,1136 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02013e0:	10700593          	li	a1,263
ffffffffc02013e4:	00003517          	auipc	a0,0x3
ffffffffc02013e8:	47c50513          	addi	a0,a0,1148 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02013ec:	81aff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02013f0:	00003697          	auipc	a3,0x3
ffffffffc02013f4:	6b068693          	addi	a3,a3,1712 # ffffffffc0204aa0 <etext+0xc2a>
ffffffffc02013f8:	00003617          	auipc	a2,0x3
ffffffffc02013fc:	45060613          	addi	a2,a2,1104 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201400:	10600593          	li	a1,262
ffffffffc0201404:	00003517          	auipc	a0,0x3
ffffffffc0201408:	45c50513          	addi	a0,a0,1116 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020140c:	ffbfe0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201410:	00003697          	auipc	a3,0x3
ffffffffc0201414:	66068693          	addi	a3,a3,1632 # ffffffffc0204a70 <etext+0xbfa>
ffffffffc0201418:	00003617          	auipc	a2,0x3
ffffffffc020141c:	43060613          	addi	a2,a2,1072 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201420:	10500593          	li	a1,261
ffffffffc0201424:	00003517          	auipc	a0,0x3
ffffffffc0201428:	43c50513          	addi	a0,a0,1084 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020142c:	fdbfe0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201430:	00003697          	auipc	a3,0x3
ffffffffc0201434:	62868693          	addi	a3,a3,1576 # ffffffffc0204a58 <etext+0xbe2>
ffffffffc0201438:	00003617          	auipc	a2,0x3
ffffffffc020143c:	41060613          	addi	a2,a2,1040 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201440:	10400593          	li	a1,260
ffffffffc0201444:	00003517          	auipc	a0,0x3
ffffffffc0201448:	41c50513          	addi	a0,a0,1052 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020144c:	fbbfe0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201450:	00003697          	auipc	a3,0x3
ffffffffc0201454:	57068693          	addi	a3,a3,1392 # ffffffffc02049c0 <etext+0xb4a>
ffffffffc0201458:	00003617          	auipc	a2,0x3
ffffffffc020145c:	3f060613          	addi	a2,a2,1008 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201460:	0fe00593          	li	a1,254
ffffffffc0201464:	00003517          	auipc	a0,0x3
ffffffffc0201468:	3fc50513          	addi	a0,a0,1020 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020146c:	f9bfe0ef          	jal	ffffffffc0200406 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201470:	00003697          	auipc	a3,0x3
ffffffffc0201474:	5d068693          	addi	a3,a3,1488 # ffffffffc0204a40 <etext+0xbca>
ffffffffc0201478:	00003617          	auipc	a2,0x3
ffffffffc020147c:	3d060613          	addi	a2,a2,976 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201480:	0f900593          	li	a1,249
ffffffffc0201484:	00003517          	auipc	a0,0x3
ffffffffc0201488:	3dc50513          	addi	a0,a0,988 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020148c:	f7bfe0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201490:	00003697          	auipc	a3,0x3
ffffffffc0201494:	6d068693          	addi	a3,a3,1744 # ffffffffc0204b60 <etext+0xcea>
ffffffffc0201498:	00003617          	auipc	a2,0x3
ffffffffc020149c:	3b060613          	addi	a2,a2,944 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02014a0:	11700593          	li	a1,279
ffffffffc02014a4:	00003517          	auipc	a0,0x3
ffffffffc02014a8:	3bc50513          	addi	a0,a0,956 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02014ac:	f5bfe0ef          	jal	ffffffffc0200406 <__panic>
    assert(total == 0);
ffffffffc02014b0:	00003697          	auipc	a3,0x3
ffffffffc02014b4:	6e068693          	addi	a3,a3,1760 # ffffffffc0204b90 <etext+0xd1a>
ffffffffc02014b8:	00003617          	auipc	a2,0x3
ffffffffc02014bc:	39060613          	addi	a2,a2,912 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02014c0:	12600593          	li	a1,294
ffffffffc02014c4:	00003517          	auipc	a0,0x3
ffffffffc02014c8:	39c50513          	addi	a0,a0,924 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02014cc:	f3bfe0ef          	jal	ffffffffc0200406 <__panic>
    assert(total == nr_free_pages());
ffffffffc02014d0:	00003697          	auipc	a3,0x3
ffffffffc02014d4:	3a868693          	addi	a3,a3,936 # ffffffffc0204878 <etext+0xa02>
ffffffffc02014d8:	00003617          	auipc	a2,0x3
ffffffffc02014dc:	37060613          	addi	a2,a2,880 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02014e0:	0f300593          	li	a1,243
ffffffffc02014e4:	00003517          	auipc	a0,0x3
ffffffffc02014e8:	37c50513          	addi	a0,a0,892 # ffffffffc0204860 <etext+0x9ea>
ffffffffc02014ec:	f1bfe0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014f0:	00003697          	auipc	a3,0x3
ffffffffc02014f4:	3c868693          	addi	a3,a3,968 # ffffffffc02048b8 <etext+0xa42>
ffffffffc02014f8:	00003617          	auipc	a2,0x3
ffffffffc02014fc:	35060613          	addi	a2,a2,848 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201500:	0ba00593          	li	a1,186
ffffffffc0201504:	00003517          	auipc	a0,0x3
ffffffffc0201508:	35c50513          	addi	a0,a0,860 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020150c:	efbfe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201510 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201510:	1141                	addi	sp,sp,-16
ffffffffc0201512:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201514:	14058663          	beqz	a1,ffffffffc0201660 <default_free_pages+0x150>
    for (; p != base + n; p ++) {
ffffffffc0201518:	00659713          	slli	a4,a1,0x6
ffffffffc020151c:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201520:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201522:	c30d                	beqz	a4,ffffffffc0201544 <default_free_pages+0x34>
ffffffffc0201524:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201526:	8b05                	andi	a4,a4,1
ffffffffc0201528:	10071c63          	bnez	a4,ffffffffc0201640 <default_free_pages+0x130>
ffffffffc020152c:	6798                	ld	a4,8(a5)
ffffffffc020152e:	8b09                	andi	a4,a4,2
ffffffffc0201530:	10071863          	bnez	a4,ffffffffc0201640 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc0201534:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201538:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020153c:	04078793          	addi	a5,a5,64
ffffffffc0201540:	fed792e3          	bne	a5,a3,ffffffffc0201524 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201544:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201546:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020154a:	4789                	li	a5,2
ffffffffc020154c:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201550:	00008717          	auipc	a4,0x8
ffffffffc0201554:	ef072703          	lw	a4,-272(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201558:	00008697          	auipc	a3,0x8
ffffffffc020155c:	ed868693          	addi	a3,a3,-296 # ffffffffc0209430 <free_area>
    return list->next == list;
ffffffffc0201560:	669c                	ld	a5,8(a3)
ffffffffc0201562:	9f2d                	addw	a4,a4,a1
ffffffffc0201564:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201566:	0ad78163          	beq	a5,a3,ffffffffc0201608 <default_free_pages+0xf8>
            struct Page* page = le2page(le, page_link);
ffffffffc020156a:	fe878713          	addi	a4,a5,-24
ffffffffc020156e:	4581                	li	a1,0
ffffffffc0201570:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201574:	00e56a63          	bltu	a0,a4,ffffffffc0201588 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201578:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020157a:	04d70c63          	beq	a4,a3,ffffffffc02015d2 <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc020157e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201580:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201584:	fee57ae3          	bgeu	a0,a4,ffffffffc0201578 <default_free_pages+0x68>
ffffffffc0201588:	c199                	beqz	a1,ffffffffc020158e <default_free_pages+0x7e>
ffffffffc020158a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020158e:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201590:	e390                	sd	a2,0(a5)
ffffffffc0201592:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc0201594:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201596:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201598:	00d70d63          	beq	a4,a3,ffffffffc02015b2 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc020159c:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02015a0:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc02015a4:	02059813          	slli	a6,a1,0x20
ffffffffc02015a8:	01a85793          	srli	a5,a6,0x1a
ffffffffc02015ac:	97b2                	add	a5,a5,a2
ffffffffc02015ae:	02f50c63          	beq	a0,a5,ffffffffc02015e6 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02015b2:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02015b4:	00d78c63          	beq	a5,a3,ffffffffc02015cc <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc02015b8:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02015ba:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc02015be:	02061593          	slli	a1,a2,0x20
ffffffffc02015c2:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02015c6:	972a                	add	a4,a4,a0
ffffffffc02015c8:	04e68c63          	beq	a3,a4,ffffffffc0201620 <default_free_pages+0x110>
}
ffffffffc02015cc:	60a2                	ld	ra,8(sp)
ffffffffc02015ce:	0141                	addi	sp,sp,16
ffffffffc02015d0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015d2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015d4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02015d6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015d8:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02015da:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015dc:	02d70f63          	beq	a4,a3,ffffffffc020161a <default_free_pages+0x10a>
ffffffffc02015e0:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02015e2:	87ba                	mv	a5,a4
ffffffffc02015e4:	bf71                	j	ffffffffc0201580 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02015e6:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02015e8:	5875                	li	a6,-3
ffffffffc02015ea:	9fad                	addw	a5,a5,a1
ffffffffc02015ec:	fef72c23          	sw	a5,-8(a4)
ffffffffc02015f0:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015f4:	01853803          	ld	a6,24(a0)
ffffffffc02015f8:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02015fa:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02015fc:	00b83423          	sd	a1,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    return listelm->next;
ffffffffc0201600:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201602:	0105b023          	sd	a6,0(a1)
ffffffffc0201606:	b77d                	j	ffffffffc02015b4 <default_free_pages+0xa4>
}
ffffffffc0201608:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020160a:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc020160e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201610:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201612:	e398                	sd	a4,0(a5)
ffffffffc0201614:	e798                	sd	a4,8(a5)
}
ffffffffc0201616:	0141                	addi	sp,sp,16
ffffffffc0201618:	8082                	ret
ffffffffc020161a:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020161c:	873e                	mv	a4,a5
ffffffffc020161e:	bfad                	j	ffffffffc0201598 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc0201620:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201624:	56f5                	li	a3,-3
ffffffffc0201626:	9f31                	addw	a4,a4,a2
ffffffffc0201628:	c918                	sw	a4,16(a0)
ffffffffc020162a:	ff078713          	addi	a4,a5,-16
ffffffffc020162e:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201632:	6398                	ld	a4,0(a5)
ffffffffc0201634:	679c                	ld	a5,8(a5)
}
ffffffffc0201636:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201638:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020163a:	e398                	sd	a4,0(a5)
ffffffffc020163c:	0141                	addi	sp,sp,16
ffffffffc020163e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201640:	00003697          	auipc	a3,0x3
ffffffffc0201644:	56868693          	addi	a3,a3,1384 # ffffffffc0204ba8 <etext+0xd32>
ffffffffc0201648:	00003617          	auipc	a2,0x3
ffffffffc020164c:	20060613          	addi	a2,a2,512 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201650:	08300593          	li	a1,131
ffffffffc0201654:	00003517          	auipc	a0,0x3
ffffffffc0201658:	20c50513          	addi	a0,a0,524 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020165c:	dabfe0ef          	jal	ffffffffc0200406 <__panic>
    assert(n > 0);
ffffffffc0201660:	00003697          	auipc	a3,0x3
ffffffffc0201664:	54068693          	addi	a3,a3,1344 # ffffffffc0204ba0 <etext+0xd2a>
ffffffffc0201668:	00003617          	auipc	a2,0x3
ffffffffc020166c:	1e060613          	addi	a2,a2,480 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201670:	08000593          	li	a1,128
ffffffffc0201674:	00003517          	auipc	a0,0x3
ffffffffc0201678:	1ec50513          	addi	a0,a0,492 # ffffffffc0204860 <etext+0x9ea>
ffffffffc020167c:	d8bfe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201680 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201680:	c951                	beqz	a0,ffffffffc0201714 <default_alloc_pages+0x94>
    if (n > nr_free) {
ffffffffc0201682:	00008597          	auipc	a1,0x8
ffffffffc0201686:	dbe5a583          	lw	a1,-578(a1) # ffffffffc0209440 <free_area+0x10>
ffffffffc020168a:	86aa                	mv	a3,a0
ffffffffc020168c:	02059793          	slli	a5,a1,0x20
ffffffffc0201690:	9381                	srli	a5,a5,0x20
ffffffffc0201692:	00a7ef63          	bltu	a5,a0,ffffffffc02016b0 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc0201696:	00008617          	auipc	a2,0x8
ffffffffc020169a:	d9a60613          	addi	a2,a2,-614 # ffffffffc0209430 <free_area>
ffffffffc020169e:	87b2                	mv	a5,a2
ffffffffc02016a0:	a029                	j	ffffffffc02016aa <default_alloc_pages+0x2a>
        if (p->property >= n) {
ffffffffc02016a2:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02016a6:	00d77763          	bgeu	a4,a3,ffffffffc02016b4 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc02016aa:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02016ac:	fec79be3          	bne	a5,a2,ffffffffc02016a2 <default_alloc_pages+0x22>
        return NULL;
ffffffffc02016b0:	4501                	li	a0,0
}
ffffffffc02016b2:	8082                	ret
        if (page->property > n) {
ffffffffc02016b4:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02016b8:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016bc:	6798                	ld	a4,8(a5)
ffffffffc02016be:	02089313          	slli	t1,a7,0x20
ffffffffc02016c2:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc02016c6:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02016ca:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc02016ce:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc02016d2:	0266fa63          	bgeu	a3,t1,ffffffffc0201706 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02016d6:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc02016da:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc02016de:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02016e0:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016e4:	00870313          	addi	t1,a4,8
ffffffffc02016e8:	4889                	li	a7,2
ffffffffc02016ea:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02016ee:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc02016f2:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc02016f6:	0068b023          	sd	t1,0(a7)
ffffffffc02016fa:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc02016fe:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc0201702:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc0201706:	9d95                	subw	a1,a1,a3
ffffffffc0201708:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020170a:	5775                	li	a4,-3
ffffffffc020170c:	17c1                	addi	a5,a5,-16
ffffffffc020170e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201712:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201714:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201716:	00003697          	auipc	a3,0x3
ffffffffc020171a:	48a68693          	addi	a3,a3,1162 # ffffffffc0204ba0 <etext+0xd2a>
ffffffffc020171e:	00003617          	auipc	a2,0x3
ffffffffc0201722:	12a60613          	addi	a2,a2,298 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201726:	06200593          	li	a1,98
ffffffffc020172a:	00003517          	auipc	a0,0x3
ffffffffc020172e:	13650513          	addi	a0,a0,310 # ffffffffc0204860 <etext+0x9ea>
default_alloc_pages(size_t n) {
ffffffffc0201732:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201734:	cd3fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201738 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201738:	1141                	addi	sp,sp,-16
ffffffffc020173a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020173c:	c9e1                	beqz	a1,ffffffffc020180c <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc020173e:	00659713          	slli	a4,a1,0x6
ffffffffc0201742:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201746:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201748:	cf11                	beqz	a4,ffffffffc0201764 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020174a:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020174c:	8b05                	andi	a4,a4,1
ffffffffc020174e:	cf59                	beqz	a4,ffffffffc02017ec <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201750:	0007a823          	sw	zero,16(a5)
ffffffffc0201754:	0007b423          	sd	zero,8(a5)
ffffffffc0201758:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020175c:	04078793          	addi	a5,a5,64
ffffffffc0201760:	fed795e3          	bne	a5,a3,ffffffffc020174a <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201764:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201766:	4789                	li	a5,2
ffffffffc0201768:	00850713          	addi	a4,a0,8
ffffffffc020176c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201770:	00008717          	auipc	a4,0x8
ffffffffc0201774:	cd072703          	lw	a4,-816(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201778:	00008697          	auipc	a3,0x8
ffffffffc020177c:	cb868693          	addi	a3,a3,-840 # ffffffffc0209430 <free_area>
    return list->next == list;
ffffffffc0201780:	669c                	ld	a5,8(a3)
ffffffffc0201782:	9f2d                	addw	a4,a4,a1
ffffffffc0201784:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201786:	04d78663          	beq	a5,a3,ffffffffc02017d2 <default_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc020178a:	fe878713          	addi	a4,a5,-24
ffffffffc020178e:	4581                	li	a1,0
ffffffffc0201790:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201794:	00e56a63          	bltu	a0,a4,ffffffffc02017a8 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201798:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020179a:	02d70263          	beq	a4,a3,ffffffffc02017be <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc020179e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02017a0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02017a4:	fee57ae3          	bgeu	a0,a4,ffffffffc0201798 <default_init_memmap+0x60>
ffffffffc02017a8:	c199                	beqz	a1,ffffffffc02017ae <default_init_memmap+0x76>
ffffffffc02017aa:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017ae:	6398                	ld	a4,0(a5)
}
ffffffffc02017b0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02017b2:	e390                	sd	a2,0(a5)
ffffffffc02017b4:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02017b6:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02017b8:	f11c                	sd	a5,32(a0)
ffffffffc02017ba:	0141                	addi	sp,sp,16
ffffffffc02017bc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017be:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017c0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017c2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017c4:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02017c6:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02017c8:	00d70e63          	beq	a4,a3,ffffffffc02017e4 <default_init_memmap+0xac>
ffffffffc02017cc:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02017ce:	87ba                	mv	a5,a4
ffffffffc02017d0:	bfc1                	j	ffffffffc02017a0 <default_init_memmap+0x68>
}
ffffffffc02017d2:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02017d4:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02017d8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017da:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02017dc:	e398                	sd	a4,0(a5)
ffffffffc02017de:	e798                	sd	a4,8(a5)
}
ffffffffc02017e0:	0141                	addi	sp,sp,16
ffffffffc02017e2:	8082                	ret
ffffffffc02017e4:	60a2                	ld	ra,8(sp)
ffffffffc02017e6:	e290                	sd	a2,0(a3)
ffffffffc02017e8:	0141                	addi	sp,sp,16
ffffffffc02017ea:	8082                	ret
        assert(PageReserved(p));
ffffffffc02017ec:	00003697          	auipc	a3,0x3
ffffffffc02017f0:	3e468693          	addi	a3,a3,996 # ffffffffc0204bd0 <etext+0xd5a>
ffffffffc02017f4:	00003617          	auipc	a2,0x3
ffffffffc02017f8:	05460613          	addi	a2,a2,84 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02017fc:	04900593          	li	a1,73
ffffffffc0201800:	00003517          	auipc	a0,0x3
ffffffffc0201804:	06050513          	addi	a0,a0,96 # ffffffffc0204860 <etext+0x9ea>
ffffffffc0201808:	bfffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(n > 0);
ffffffffc020180c:	00003697          	auipc	a3,0x3
ffffffffc0201810:	39468693          	addi	a3,a3,916 # ffffffffc0204ba0 <etext+0xd2a>
ffffffffc0201814:	00003617          	auipc	a2,0x3
ffffffffc0201818:	03460613          	addi	a2,a2,52 # ffffffffc0204848 <etext+0x9d2>
ffffffffc020181c:	04600593          	li	a1,70
ffffffffc0201820:	00003517          	auipc	a0,0x3
ffffffffc0201824:	04050513          	addi	a0,a0,64 # ffffffffc0204860 <etext+0x9ea>
ffffffffc0201828:	bdffe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020182c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc020182c:	c531                	beqz	a0,ffffffffc0201878 <slob_free+0x4c>
		return;

	if (size)
ffffffffc020182e:	e9b9                	bnez	a1,ffffffffc0201884 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201830:	100027f3          	csrr	a5,sstatus
ffffffffc0201834:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201836:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201838:	efb1                	bnez	a5,ffffffffc0201894 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020183a:	00007797          	auipc	a5,0x7
ffffffffc020183e:	7e67b783          	ld	a5,2022(a5) # ffffffffc0209020 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201842:	873e                	mv	a4,a5
ffffffffc0201844:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201846:	02a77a63          	bgeu	a4,a0,ffffffffc020187a <slob_free+0x4e>
ffffffffc020184a:	00f56463          	bltu	a0,a5,ffffffffc0201852 <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020184e:	fef76ae3          	bltu	a4,a5,ffffffffc0201842 <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc0201852:	4110                	lw	a2,0(a0)
ffffffffc0201854:	00461693          	slli	a3,a2,0x4
ffffffffc0201858:	96aa                	add	a3,a3,a0
ffffffffc020185a:	0ad78463          	beq	a5,a3,ffffffffc0201902 <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc020185e:	4310                	lw	a2,0(a4)
ffffffffc0201860:	e51c                	sd	a5,8(a0)
ffffffffc0201862:	00461693          	slli	a3,a2,0x4
ffffffffc0201866:	96ba                	add	a3,a3,a4
ffffffffc0201868:	08d50163          	beq	a0,a3,ffffffffc02018ea <slob_free+0xbe>
ffffffffc020186c:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc020186e:	00007797          	auipc	a5,0x7
ffffffffc0201872:	7ae7b923          	sd	a4,1970(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc0201876:	e9a5                	bnez	a1,ffffffffc02018e6 <slob_free+0xba>
ffffffffc0201878:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020187a:	fcf574e3          	bgeu	a0,a5,ffffffffc0201842 <slob_free+0x16>
ffffffffc020187e:	fcf762e3          	bltu	a4,a5,ffffffffc0201842 <slob_free+0x16>
ffffffffc0201882:	bfc1                	j	ffffffffc0201852 <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201884:	25bd                	addiw	a1,a1,15
ffffffffc0201886:	8191                	srli	a1,a1,0x4
ffffffffc0201888:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020188a:	100027f3          	csrr	a5,sstatus
ffffffffc020188e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201890:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201892:	d7c5                	beqz	a5,ffffffffc020183a <slob_free+0xe>
{
ffffffffc0201894:	1101                	addi	sp,sp,-32
ffffffffc0201896:	e42a                	sd	a0,8(sp)
ffffffffc0201898:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020189a:	fdbfe0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc020189e:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018a0:	00007797          	auipc	a5,0x7
ffffffffc02018a4:	7807b783          	ld	a5,1920(a5) # ffffffffc0209020 <slobfree>
ffffffffc02018a8:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018aa:	873e                	mv	a4,a5
ffffffffc02018ac:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018ae:	06a77663          	bgeu	a4,a0,ffffffffc020191a <slob_free+0xee>
ffffffffc02018b2:	00f56463          	bltu	a0,a5,ffffffffc02018ba <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018b6:	fef76ae3          	bltu	a4,a5,ffffffffc02018aa <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc02018ba:	4110                	lw	a2,0(a0)
ffffffffc02018bc:	00461693          	slli	a3,a2,0x4
ffffffffc02018c0:	96aa                	add	a3,a3,a0
ffffffffc02018c2:	06d78363          	beq	a5,a3,ffffffffc0201928 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc02018c6:	4310                	lw	a2,0(a4)
ffffffffc02018c8:	e51c                	sd	a5,8(a0)
ffffffffc02018ca:	00461693          	slli	a3,a2,0x4
ffffffffc02018ce:	96ba                	add	a3,a3,a4
ffffffffc02018d0:	06d50163          	beq	a0,a3,ffffffffc0201932 <slob_free+0x106>
ffffffffc02018d4:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc02018d6:	00007797          	auipc	a5,0x7
ffffffffc02018da:	74e7b523          	sd	a4,1866(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc02018de:	e1a9                	bnez	a1,ffffffffc0201920 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02018e0:	60e2                	ld	ra,24(sp)
ffffffffc02018e2:	6105                	addi	sp,sp,32
ffffffffc02018e4:	8082                	ret
        intr_enable();
ffffffffc02018e6:	f89fe06f          	j	ffffffffc020086e <intr_enable>
		cur->units += b->units;
ffffffffc02018ea:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc02018ec:	853e                	mv	a0,a5
ffffffffc02018ee:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc02018f0:	00c687bb          	addw	a5,a3,a2
ffffffffc02018f4:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc02018f6:	00007797          	auipc	a5,0x7
ffffffffc02018fa:	72e7b523          	sd	a4,1834(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc02018fe:	ddad                	beqz	a1,ffffffffc0201878 <slob_free+0x4c>
ffffffffc0201900:	b7dd                	j	ffffffffc02018e6 <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201902:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201904:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201906:	9eb1                	addw	a3,a3,a2
ffffffffc0201908:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc020190a:	4310                	lw	a2,0(a4)
ffffffffc020190c:	e51c                	sd	a5,8(a0)
ffffffffc020190e:	00461693          	slli	a3,a2,0x4
ffffffffc0201912:	96ba                	add	a3,a3,a4
ffffffffc0201914:	f4d51ce3          	bne	a0,a3,ffffffffc020186c <slob_free+0x40>
ffffffffc0201918:	bfc9                	j	ffffffffc02018ea <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020191a:	f8f56ee3          	bltu	a0,a5,ffffffffc02018b6 <slob_free+0x8a>
ffffffffc020191e:	b771                	j	ffffffffc02018aa <slob_free+0x7e>
}
ffffffffc0201920:	60e2                	ld	ra,24(sp)
ffffffffc0201922:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201924:	f4bfe06f          	j	ffffffffc020086e <intr_enable>
		b->units += cur->next->units;
ffffffffc0201928:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc020192a:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc020192c:	9eb1                	addw	a3,a3,a2
ffffffffc020192e:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201930:	bf59                	j	ffffffffc02018c6 <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201932:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201934:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201936:	00c687bb          	addw	a5,a3,a2
ffffffffc020193a:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc020193c:	bf61                	j	ffffffffc02018d4 <slob_free+0xa8>

ffffffffc020193e <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc020193e:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201940:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201942:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201946:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201948:	326000ef          	jal	ffffffffc0201c6e <alloc_pages>
	if (!page)
ffffffffc020194c:	c91d                	beqz	a0,ffffffffc0201982 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc020194e:	0000c697          	auipc	a3,0xc
ffffffffc0201952:	b7a6b683          	ld	a3,-1158(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201956:	00004797          	auipc	a5,0x4
ffffffffc020195a:	0727b783          	ld	a5,114(a5) # ffffffffc02059c8 <nbase>
    return KADDR(page2pa(page));
ffffffffc020195e:	0000c717          	auipc	a4,0xc
ffffffffc0201962:	b6273703          	ld	a4,-1182(a4) # ffffffffc020d4c0 <npage>
    return page - pages + nbase;
ffffffffc0201966:	8d15                	sub	a0,a0,a3
ffffffffc0201968:	8519                	srai	a0,a0,0x6
ffffffffc020196a:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc020196c:	00c51793          	slli	a5,a0,0xc
ffffffffc0201970:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201972:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201974:	00e7fa63          	bgeu	a5,a4,ffffffffc0201988 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201978:	0000c797          	auipc	a5,0xc
ffffffffc020197c:	b407b783          	ld	a5,-1216(a5) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201980:	953e                	add	a0,a0,a5
}
ffffffffc0201982:	60a2                	ld	ra,8(sp)
ffffffffc0201984:	0141                	addi	sp,sp,16
ffffffffc0201986:	8082                	ret
ffffffffc0201988:	86aa                	mv	a3,a0
ffffffffc020198a:	00003617          	auipc	a2,0x3
ffffffffc020198e:	26e60613          	addi	a2,a2,622 # ffffffffc0204bf8 <etext+0xd82>
ffffffffc0201992:	07100593          	li	a1,113
ffffffffc0201996:	00003517          	auipc	a0,0x3
ffffffffc020199a:	28a50513          	addi	a0,a0,650 # ffffffffc0204c20 <etext+0xdaa>
ffffffffc020199e:	a69fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc02019a2 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc02019a2:	7179                	addi	sp,sp,-48
ffffffffc02019a4:	f406                	sd	ra,40(sp)
ffffffffc02019a6:	f022                	sd	s0,32(sp)
ffffffffc02019a8:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02019aa:	01050713          	addi	a4,a0,16
ffffffffc02019ae:	6785                	lui	a5,0x1
ffffffffc02019b0:	0af77e63          	bgeu	a4,a5,ffffffffc0201a6c <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019b4:	00f50413          	addi	s0,a0,15
ffffffffc02019b8:	8011                	srli	s0,s0,0x4
ffffffffc02019ba:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019bc:	100025f3          	csrr	a1,sstatus
ffffffffc02019c0:	8989                	andi	a1,a1,2
ffffffffc02019c2:	edd1                	bnez	a1,ffffffffc0201a5e <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc02019c4:	00007497          	auipc	s1,0x7
ffffffffc02019c8:	65c48493          	addi	s1,s1,1628 # ffffffffc0209020 <slobfree>
ffffffffc02019cc:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019ce:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc02019d0:	4314                	lw	a3,0(a4)
ffffffffc02019d2:	0886da63          	bge	a3,s0,ffffffffc0201a66 <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc02019d6:	00e60a63          	beq	a2,a4,ffffffffc02019ea <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019da:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc02019dc:	4394                	lw	a3,0(a5)
ffffffffc02019de:	0286d863          	bge	a3,s0,ffffffffc0201a0e <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc02019e2:	6090                	ld	a2,0(s1)
ffffffffc02019e4:	873e                	mv	a4,a5
ffffffffc02019e6:	fee61ae3          	bne	a2,a4,ffffffffc02019da <slob_alloc.constprop.0+0x38>
    if (flag) {
ffffffffc02019ea:	e9b1                	bnez	a1,ffffffffc0201a3e <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02019ec:	4501                	li	a0,0
ffffffffc02019ee:	f51ff0ef          	jal	ffffffffc020193e <__slob_get_free_pages.constprop.0>
ffffffffc02019f2:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc02019f4:	c915                	beqz	a0,ffffffffc0201a28 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc02019f6:	6585                	lui	a1,0x1
ffffffffc02019f8:	e35ff0ef          	jal	ffffffffc020182c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019fc:	100025f3          	csrr	a1,sstatus
ffffffffc0201a00:	8989                	andi	a1,a1,2
ffffffffc0201a02:	e98d                	bnez	a1,ffffffffc0201a34 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201a04:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a06:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201a08:	4394                	lw	a3,0(a5)
ffffffffc0201a0a:	fc86cce3          	blt	a3,s0,ffffffffc02019e2 <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201a0e:	04d40563          	beq	s0,a3,ffffffffc0201a58 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201a12:	00441613          	slli	a2,s0,0x4
ffffffffc0201a16:	963e                	add	a2,a2,a5
ffffffffc0201a18:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201a1a:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201a1c:	9e81                	subw	a3,a3,s0
ffffffffc0201a1e:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201a20:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201a22:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201a24:	e098                	sd	a4,0(s1)
    if (flag) {
ffffffffc0201a26:	ed99                	bnez	a1,ffffffffc0201a44 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201a28:	70a2                	ld	ra,40(sp)
ffffffffc0201a2a:	7402                	ld	s0,32(sp)
ffffffffc0201a2c:	64e2                	ld	s1,24(sp)
ffffffffc0201a2e:	853e                	mv	a0,a5
ffffffffc0201a30:	6145                	addi	sp,sp,48
ffffffffc0201a32:	8082                	ret
        intr_disable();
ffffffffc0201a34:	e41fe0ef          	jal	ffffffffc0200874 <intr_disable>
			cur = slobfree;
ffffffffc0201a38:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201a3a:	4585                	li	a1,1
ffffffffc0201a3c:	b7e9                	j	ffffffffc0201a06 <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201a3e:	e31fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201a42:	b76d                	j	ffffffffc02019ec <slob_alloc.constprop.0+0x4a>
ffffffffc0201a44:	e43e                	sd	a5,8(sp)
ffffffffc0201a46:	e29fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201a4a:	67a2                	ld	a5,8(sp)
}
ffffffffc0201a4c:	70a2                	ld	ra,40(sp)
ffffffffc0201a4e:	7402                	ld	s0,32(sp)
ffffffffc0201a50:	64e2                	ld	s1,24(sp)
ffffffffc0201a52:	853e                	mv	a0,a5
ffffffffc0201a54:	6145                	addi	sp,sp,48
ffffffffc0201a56:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a58:	6794                	ld	a3,8(a5)
ffffffffc0201a5a:	e714                	sd	a3,8(a4)
ffffffffc0201a5c:	b7e1                	j	ffffffffc0201a24 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201a5e:	e17fe0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc0201a62:	4585                	li	a1,1
ffffffffc0201a64:	b785                	j	ffffffffc02019c4 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a66:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201a68:	8732                	mv	a4,a2
ffffffffc0201a6a:	b755                	j	ffffffffc0201a0e <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a6c:	00003697          	auipc	a3,0x3
ffffffffc0201a70:	1c468693          	addi	a3,a3,452 # ffffffffc0204c30 <etext+0xdba>
ffffffffc0201a74:	00003617          	auipc	a2,0x3
ffffffffc0201a78:	dd460613          	addi	a2,a2,-556 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0201a7c:	06300593          	li	a1,99
ffffffffc0201a80:	00003517          	auipc	a0,0x3
ffffffffc0201a84:	1d050513          	addi	a0,a0,464 # ffffffffc0204c50 <etext+0xdda>
ffffffffc0201a88:	97ffe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201a8c <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201a8c:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201a8e:	00003517          	auipc	a0,0x3
ffffffffc0201a92:	1da50513          	addi	a0,a0,474 # ffffffffc0204c68 <etext+0xdf2>
{
ffffffffc0201a96:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201a98:	efcfe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201a9c:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a9e:	00003517          	auipc	a0,0x3
ffffffffc0201aa2:	1e250513          	addi	a0,a0,482 # ffffffffc0204c80 <etext+0xe0a>
}
ffffffffc0201aa6:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201aa8:	eecfe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201aac <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201aac:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201aae:	6685                	lui	a3,0x1
{
ffffffffc0201ab0:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ab2:	16bd                	addi	a3,a3,-17 # fef <kern_entry-0xffffffffc01ff011>
ffffffffc0201ab4:	04a6f963          	bgeu	a3,a0,ffffffffc0201b06 <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201ab8:	e42a                	sd	a0,8(sp)
ffffffffc0201aba:	4561                	li	a0,24
ffffffffc0201abc:	e822                	sd	s0,16(sp)
ffffffffc0201abe:	ee5ff0ef          	jal	ffffffffc02019a2 <slob_alloc.constprop.0>
ffffffffc0201ac2:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201ac4:	c541                	beqz	a0,ffffffffc0201b4c <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201ac6:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201ac8:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201aca:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201acc:	00f75763          	bge	a4,a5,ffffffffc0201ada <kmalloc+0x2e>
ffffffffc0201ad0:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201ad4:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201ad6:	fef74de3          	blt	a4,a5,ffffffffc0201ad0 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201ada:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201adc:	e63ff0ef          	jal	ffffffffc020193e <__slob_get_free_pages.constprop.0>
ffffffffc0201ae0:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201ae2:	cd31                	beqz	a0,ffffffffc0201b3e <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ae4:	100027f3          	csrr	a5,sstatus
ffffffffc0201ae8:	8b89                	andi	a5,a5,2
ffffffffc0201aea:	eb85                	bnez	a5,ffffffffc0201b1a <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201aec:	0000c797          	auipc	a5,0xc
ffffffffc0201af0:	9ac7b783          	ld	a5,-1620(a5) # ffffffffc020d498 <bigblocks>
		bigblocks = bb;
ffffffffc0201af4:	0000c717          	auipc	a4,0xc
ffffffffc0201af8:	9a873223          	sd	s0,-1628(a4) # ffffffffc020d498 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201afc:	e81c                	sd	a5,16(s0)
    if (flag) {
ffffffffc0201afe:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201b00:	60e2                	ld	ra,24(sp)
ffffffffc0201b02:	6105                	addi	sp,sp,32
ffffffffc0201b04:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201b06:	0541                	addi	a0,a0,16
ffffffffc0201b08:	e9bff0ef          	jal	ffffffffc02019a2 <slob_alloc.constprop.0>
ffffffffc0201b0c:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b0e:	0541                	addi	a0,a0,16
ffffffffc0201b10:	fbe5                	bnez	a5,ffffffffc0201b00 <kmalloc+0x54>
		return 0;
ffffffffc0201b12:	4501                	li	a0,0
}
ffffffffc0201b14:	60e2                	ld	ra,24(sp)
ffffffffc0201b16:	6105                	addi	sp,sp,32
ffffffffc0201b18:	8082                	ret
        intr_disable();
ffffffffc0201b1a:	d5bfe0ef          	jal	ffffffffc0200874 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b1e:	0000c797          	auipc	a5,0xc
ffffffffc0201b22:	97a7b783          	ld	a5,-1670(a5) # ffffffffc020d498 <bigblocks>
		bigblocks = bb;
ffffffffc0201b26:	0000c717          	auipc	a4,0xc
ffffffffc0201b2a:	96873923          	sd	s0,-1678(a4) # ffffffffc020d498 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201b2e:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201b30:	d3ffe0ef          	jal	ffffffffc020086e <intr_enable>
		return bb->pages;
ffffffffc0201b34:	6408                	ld	a0,8(s0)
}
ffffffffc0201b36:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201b38:	6442                	ld	s0,16(sp)
}
ffffffffc0201b3a:	6105                	addi	sp,sp,32
ffffffffc0201b3c:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b3e:	8522                	mv	a0,s0
ffffffffc0201b40:	45e1                	li	a1,24
ffffffffc0201b42:	cebff0ef          	jal	ffffffffc020182c <slob_free>
		return 0;
ffffffffc0201b46:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b48:	6442                	ld	s0,16(sp)
ffffffffc0201b4a:	b7e9                	j	ffffffffc0201b14 <kmalloc+0x68>
ffffffffc0201b4c:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201b4e:	4501                	li	a0,0
ffffffffc0201b50:	b7d1                	j	ffffffffc0201b14 <kmalloc+0x68>

ffffffffc0201b52 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b52:	c571                	beqz	a0,ffffffffc0201c1e <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201b54:	03451793          	slli	a5,a0,0x34
ffffffffc0201b58:	e3e1                	bnez	a5,ffffffffc0201c18 <kfree+0xc6>
{
ffffffffc0201b5a:	1101                	addi	sp,sp,-32
ffffffffc0201b5c:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b5e:	100027f3          	csrr	a5,sstatus
ffffffffc0201b62:	8b89                	andi	a5,a5,2
ffffffffc0201b64:	e7c1                	bnez	a5,ffffffffc0201bec <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b66:	0000c797          	auipc	a5,0xc
ffffffffc0201b6a:	9327b783          	ld	a5,-1742(a5) # ffffffffc020d498 <bigblocks>
    return 0;
ffffffffc0201b6e:	4581                	li	a1,0
ffffffffc0201b70:	cbad                	beqz	a5,ffffffffc0201be2 <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b72:	0000c617          	auipc	a2,0xc
ffffffffc0201b76:	92660613          	addi	a2,a2,-1754 # ffffffffc020d498 <bigblocks>
ffffffffc0201b7a:	a021                	j	ffffffffc0201b82 <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b7c:	01070613          	addi	a2,a4,16
ffffffffc0201b80:	c3a5                	beqz	a5,ffffffffc0201be0 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201b82:	6794                	ld	a3,8(a5)
ffffffffc0201b84:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201b86:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201b88:	fea69ae3          	bne	a3,a0,ffffffffc0201b7c <kfree+0x2a>
				*last = bb->next;
ffffffffc0201b8c:	e21c                	sd	a5,0(a2)
    if (flag) {
ffffffffc0201b8e:	edb5                	bnez	a1,ffffffffc0201c0a <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201b90:	c02007b7          	lui	a5,0xc0200
ffffffffc0201b94:	0af56263          	bltu	a0,a5,ffffffffc0201c38 <kfree+0xe6>
ffffffffc0201b98:	0000c797          	auipc	a5,0xc
ffffffffc0201b9c:	9207b783          	ld	a5,-1760(a5) # ffffffffc020d4b8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201ba0:	0000c697          	auipc	a3,0xc
ffffffffc0201ba4:	9206b683          	ld	a3,-1760(a3) # ffffffffc020d4c0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201ba8:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201baa:	00c55793          	srli	a5,a0,0xc
ffffffffc0201bae:	06d7f963          	bgeu	a5,a3,ffffffffc0201c20 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201bb2:	00004617          	auipc	a2,0x4
ffffffffc0201bb6:	e1663603          	ld	a2,-490(a2) # ffffffffc02059c8 <nbase>
ffffffffc0201bba:	0000c517          	auipc	a0,0xc
ffffffffc0201bbe:	90e53503          	ld	a0,-1778(a0) # ffffffffc020d4c8 <pages>
	free_pages(kva2page((void*)kva), 1 << order);
ffffffffc0201bc2:	4314                	lw	a3,0(a4)
ffffffffc0201bc4:	8f91                	sub	a5,a5,a2
ffffffffc0201bc6:	079a                	slli	a5,a5,0x6
ffffffffc0201bc8:	4585                	li	a1,1
ffffffffc0201bca:	953e                	add	a0,a0,a5
ffffffffc0201bcc:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201bd0:	e03a                	sd	a4,0(sp)
ffffffffc0201bd2:	0d6000ef          	jal	ffffffffc0201ca8 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bd6:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201bd8:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bda:	45e1                	li	a1,24
}
ffffffffc0201bdc:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bde:	b1b9                	j	ffffffffc020182c <slob_free>
ffffffffc0201be0:	e185                	bnez	a1,ffffffffc0201c00 <kfree+0xae>
}
ffffffffc0201be2:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201be4:	1541                	addi	a0,a0,-16
ffffffffc0201be6:	4581                	li	a1,0
}
ffffffffc0201be8:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201bea:	b189                	j	ffffffffc020182c <slob_free>
        intr_disable();
ffffffffc0201bec:	e02a                	sd	a0,0(sp)
ffffffffc0201bee:	c87fe0ef          	jal	ffffffffc0200874 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201bf2:	0000c797          	auipc	a5,0xc
ffffffffc0201bf6:	8a67b783          	ld	a5,-1882(a5) # ffffffffc020d498 <bigblocks>
ffffffffc0201bfa:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201bfc:	4585                	li	a1,1
ffffffffc0201bfe:	fbb5                	bnez	a5,ffffffffc0201b72 <kfree+0x20>
ffffffffc0201c00:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201c02:	c6dfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201c06:	6502                	ld	a0,0(sp)
ffffffffc0201c08:	bfe9                	j	ffffffffc0201be2 <kfree+0x90>
ffffffffc0201c0a:	e42a                	sd	a0,8(sp)
ffffffffc0201c0c:	e03a                	sd	a4,0(sp)
ffffffffc0201c0e:	c61fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201c12:	6522                	ld	a0,8(sp)
ffffffffc0201c14:	6702                	ld	a4,0(sp)
ffffffffc0201c16:	bfad                	j	ffffffffc0201b90 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c18:	1541                	addi	a0,a0,-16
ffffffffc0201c1a:	4581                	li	a1,0
ffffffffc0201c1c:	b901                	j	ffffffffc020182c <slob_free>
ffffffffc0201c1e:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c20:	00003617          	auipc	a2,0x3
ffffffffc0201c24:	0a860613          	addi	a2,a2,168 # ffffffffc0204cc8 <etext+0xe52>
ffffffffc0201c28:	06900593          	li	a1,105
ffffffffc0201c2c:	00003517          	auipc	a0,0x3
ffffffffc0201c30:	ff450513          	addi	a0,a0,-12 # ffffffffc0204c20 <etext+0xdaa>
ffffffffc0201c34:	fd2fe0ef          	jal	ffffffffc0200406 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c38:	86aa                	mv	a3,a0
ffffffffc0201c3a:	00003617          	auipc	a2,0x3
ffffffffc0201c3e:	06660613          	addi	a2,a2,102 # ffffffffc0204ca0 <etext+0xe2a>
ffffffffc0201c42:	07700593          	li	a1,119
ffffffffc0201c46:	00003517          	auipc	a0,0x3
ffffffffc0201c4a:	fda50513          	addi	a0,a0,-38 # ffffffffc0204c20 <etext+0xdaa>
ffffffffc0201c4e:	fb8fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201c52 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201c52:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c54:	00003617          	auipc	a2,0x3
ffffffffc0201c58:	07460613          	addi	a2,a2,116 # ffffffffc0204cc8 <etext+0xe52>
ffffffffc0201c5c:	06900593          	li	a1,105
ffffffffc0201c60:	00003517          	auipc	a0,0x3
ffffffffc0201c64:	fc050513          	addi	a0,a0,-64 # ffffffffc0204c20 <etext+0xdaa>
pa2page(uintptr_t pa)
ffffffffc0201c68:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c6a:	f9cfe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201c6e <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c6e:	100027f3          	csrr	a5,sstatus
ffffffffc0201c72:	8b89                	andi	a5,a5,2
ffffffffc0201c74:	e799                	bnez	a5,ffffffffc0201c82 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c76:	0000c797          	auipc	a5,0xc
ffffffffc0201c7a:	82a7b783          	ld	a5,-2006(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201c7e:	6f9c                	ld	a5,24(a5)
ffffffffc0201c80:	8782                	jr	a5
{
ffffffffc0201c82:	1101                	addi	sp,sp,-32
ffffffffc0201c84:	ec06                	sd	ra,24(sp)
ffffffffc0201c86:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201c88:	bedfe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c8c:	0000c797          	auipc	a5,0xc
ffffffffc0201c90:	8147b783          	ld	a5,-2028(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201c94:	6522                	ld	a0,8(sp)
ffffffffc0201c96:	6f9c                	ld	a5,24(a5)
ffffffffc0201c98:	9782                	jalr	a5
ffffffffc0201c9a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201c9c:	bd3fe0ef          	jal	ffffffffc020086e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201ca0:	60e2                	ld	ra,24(sp)
ffffffffc0201ca2:	6522                	ld	a0,8(sp)
ffffffffc0201ca4:	6105                	addi	sp,sp,32
ffffffffc0201ca6:	8082                	ret

ffffffffc0201ca8 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ca8:	100027f3          	csrr	a5,sstatus
ffffffffc0201cac:	8b89                	andi	a5,a5,2
ffffffffc0201cae:	e799                	bnez	a5,ffffffffc0201cbc <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201cb0:	0000b797          	auipc	a5,0xb
ffffffffc0201cb4:	7f07b783          	ld	a5,2032(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cb8:	739c                	ld	a5,32(a5)
ffffffffc0201cba:	8782                	jr	a5
{
ffffffffc0201cbc:	1101                	addi	sp,sp,-32
ffffffffc0201cbe:	ec06                	sd	ra,24(sp)
ffffffffc0201cc0:	e42e                	sd	a1,8(sp)
ffffffffc0201cc2:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201cc4:	bb1fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201cc8:	0000b797          	auipc	a5,0xb
ffffffffc0201ccc:	7d87b783          	ld	a5,2008(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cd0:	65a2                	ld	a1,8(sp)
ffffffffc0201cd2:	6502                	ld	a0,0(sp)
ffffffffc0201cd4:	739c                	ld	a5,32(a5)
ffffffffc0201cd6:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201cd8:	60e2                	ld	ra,24(sp)
ffffffffc0201cda:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201cdc:	b93fe06f          	j	ffffffffc020086e <intr_enable>

ffffffffc0201ce0 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ce0:	100027f3          	csrr	a5,sstatus
ffffffffc0201ce4:	8b89                	andi	a5,a5,2
ffffffffc0201ce6:	e799                	bnez	a5,ffffffffc0201cf4 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ce8:	0000b797          	auipc	a5,0xb
ffffffffc0201cec:	7b87b783          	ld	a5,1976(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cf0:	779c                	ld	a5,40(a5)
ffffffffc0201cf2:	8782                	jr	a5
{
ffffffffc0201cf4:	1101                	addi	sp,sp,-32
ffffffffc0201cf6:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201cf8:	b7dfe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201cfc:	0000b797          	auipc	a5,0xb
ffffffffc0201d00:	7a47b783          	ld	a5,1956(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201d04:	779c                	ld	a5,40(a5)
ffffffffc0201d06:	9782                	jalr	a5
ffffffffc0201d08:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201d0a:	b65fe0ef          	jal	ffffffffc020086e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201d0e:	60e2                	ld	ra,24(sp)
ffffffffc0201d10:	6522                	ld	a0,8(sp)
ffffffffc0201d12:	6105                	addi	sp,sp,32
ffffffffc0201d14:	8082                	ret

ffffffffc0201d16 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d16:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201d1a:	1ff7f793          	andi	a5,a5,511
ffffffffc0201d1e:	078e                	slli	a5,a5,0x3
ffffffffc0201d20:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201d24:	6314                	ld	a3,0(a4)
{
ffffffffc0201d26:	7139                	addi	sp,sp,-64
ffffffffc0201d28:	f822                	sd	s0,48(sp)
ffffffffc0201d2a:	f426                	sd	s1,40(sp)
ffffffffc0201d2c:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201d2e:	0016f793          	andi	a5,a3,1
{
ffffffffc0201d32:	842e                	mv	s0,a1
ffffffffc0201d34:	8832                	mv	a6,a2
ffffffffc0201d36:	0000b497          	auipc	s1,0xb
ffffffffc0201d3a:	78a48493          	addi	s1,s1,1930 # ffffffffc020d4c0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201d3e:	ebd1                	bnez	a5,ffffffffc0201dd2 <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d40:	16060d63          	beqz	a2,ffffffffc0201eba <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d44:	100027f3          	csrr	a5,sstatus
ffffffffc0201d48:	8b89                	andi	a5,a5,2
ffffffffc0201d4a:	16079e63          	bnez	a5,ffffffffc0201ec6 <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d4e:	0000b797          	auipc	a5,0xb
ffffffffc0201d52:	7527b783          	ld	a5,1874(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201d56:	4505                	li	a0,1
ffffffffc0201d58:	e43a                	sd	a4,8(sp)
ffffffffc0201d5a:	6f9c                	ld	a5,24(a5)
ffffffffc0201d5c:	e832                	sd	a2,16(sp)
ffffffffc0201d5e:	9782                	jalr	a5
ffffffffc0201d60:	6722                	ld	a4,8(sp)
ffffffffc0201d62:	6842                	ld	a6,16(sp)
ffffffffc0201d64:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d66:	14078a63          	beqz	a5,ffffffffc0201eba <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201d6a:	0000b517          	auipc	a0,0xb
ffffffffc0201d6e:	75e53503          	ld	a0,1886(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201d72:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201d76:	0000b497          	auipc	s1,0xb
ffffffffc0201d7a:	74a48493          	addi	s1,s1,1866 # ffffffffc020d4c0 <npage>
ffffffffc0201d7e:	40a78533          	sub	a0,a5,a0
ffffffffc0201d82:	8519                	srai	a0,a0,0x6
ffffffffc0201d84:	9546                	add	a0,a0,a7
ffffffffc0201d86:	6090                	ld	a2,0(s1)
ffffffffc0201d88:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201d8c:	4585                	li	a1,1
ffffffffc0201d8e:	82b1                	srli	a3,a3,0xc
ffffffffc0201d90:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d92:	0532                	slli	a0,a0,0xc
ffffffffc0201d94:	1ac6f763          	bgeu	a3,a2,ffffffffc0201f42 <get_pte+0x22c>
ffffffffc0201d98:	0000b697          	auipc	a3,0xb
ffffffffc0201d9c:	7206b683          	ld	a3,1824(a3) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201da0:	6605                	lui	a2,0x1
ffffffffc0201da2:	4581                	li	a1,0
ffffffffc0201da4:	9536                	add	a0,a0,a3
ffffffffc0201da6:	ec42                	sd	a6,24(sp)
ffffffffc0201da8:	e83e                	sd	a5,16(sp)
ffffffffc0201daa:	e43a                	sd	a4,8(sp)
ffffffffc0201dac:	07c020ef          	jal	ffffffffc0203e28 <memset>
    return page - pages + nbase;
ffffffffc0201db0:	0000b697          	auipc	a3,0xb
ffffffffc0201db4:	7186b683          	ld	a3,1816(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201db8:	67c2                	ld	a5,16(sp)
ffffffffc0201dba:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201dbe:	6722                	ld	a4,8(sp)
ffffffffc0201dc0:	40d786b3          	sub	a3,a5,a3
ffffffffc0201dc4:	8699                	srai	a3,a3,0x6
ffffffffc0201dc6:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201dc8:	06aa                	slli	a3,a3,0xa
ffffffffc0201dca:	6862                	ld	a6,24(sp)
ffffffffc0201dcc:	0116e693          	ori	a3,a3,17
ffffffffc0201dd0:	e314                	sd	a3,0(a4)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201dd2:	c006f693          	andi	a3,a3,-1024
ffffffffc0201dd6:	6098                	ld	a4,0(s1)
ffffffffc0201dd8:	068a                	slli	a3,a3,0x2
ffffffffc0201dda:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201dde:	14e7f663          	bgeu	a5,a4,ffffffffc0201f2a <get_pte+0x214>
ffffffffc0201de2:	0000b897          	auipc	a7,0xb
ffffffffc0201de6:	6d688893          	addi	a7,a7,1750 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201dea:	0008b603          	ld	a2,0(a7)
ffffffffc0201dee:	01545793          	srli	a5,s0,0x15
ffffffffc0201df2:	1ff7f793          	andi	a5,a5,511
ffffffffc0201df6:	96b2                	add	a3,a3,a2
ffffffffc0201df8:	078e                	slli	a5,a5,0x3
ffffffffc0201dfa:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201dfc:	6394                	ld	a3,0(a5)
ffffffffc0201dfe:	0016f613          	andi	a2,a3,1
ffffffffc0201e02:	e659                	bnez	a2,ffffffffc0201e90 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e04:	0a080b63          	beqz	a6,ffffffffc0201eba <get_pte+0x1a4>
ffffffffc0201e08:	10002773          	csrr	a4,sstatus
ffffffffc0201e0c:	8b09                	andi	a4,a4,2
ffffffffc0201e0e:	ef71                	bnez	a4,ffffffffc0201eea <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e10:	0000b717          	auipc	a4,0xb
ffffffffc0201e14:	69073703          	ld	a4,1680(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201e18:	4505                	li	a0,1
ffffffffc0201e1a:	e43e                	sd	a5,8(sp)
ffffffffc0201e1c:	6f18                	ld	a4,24(a4)
ffffffffc0201e1e:	9702                	jalr	a4
ffffffffc0201e20:	67a2                	ld	a5,8(sp)
ffffffffc0201e22:	872a                	mv	a4,a0
ffffffffc0201e24:	0000b897          	auipc	a7,0xb
ffffffffc0201e28:	69488893          	addi	a7,a7,1684 # ffffffffc020d4b8 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e2c:	c759                	beqz	a4,ffffffffc0201eba <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201e2e:	0000b697          	auipc	a3,0xb
ffffffffc0201e32:	69a6b683          	ld	a3,1690(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201e36:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e3a:	608c                	ld	a1,0(s1)
ffffffffc0201e3c:	40d706b3          	sub	a3,a4,a3
ffffffffc0201e40:	8699                	srai	a3,a3,0x6
ffffffffc0201e42:	96c2                	add	a3,a3,a6
ffffffffc0201e44:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0201e48:	4505                	li	a0,1
ffffffffc0201e4a:	8231                	srli	a2,a2,0xc
ffffffffc0201e4c:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e4e:	06b2                	slli	a3,a3,0xc
ffffffffc0201e50:	10b67663          	bgeu	a2,a1,ffffffffc0201f5c <get_pte+0x246>
ffffffffc0201e54:	0008b503          	ld	a0,0(a7)
ffffffffc0201e58:	6605                	lui	a2,0x1
ffffffffc0201e5a:	4581                	li	a1,0
ffffffffc0201e5c:	9536                	add	a0,a0,a3
ffffffffc0201e5e:	e83a                	sd	a4,16(sp)
ffffffffc0201e60:	e43e                	sd	a5,8(sp)
ffffffffc0201e62:	7c7010ef          	jal	ffffffffc0203e28 <memset>
    return page - pages + nbase;
ffffffffc0201e66:	0000b697          	auipc	a3,0xb
ffffffffc0201e6a:	6626b683          	ld	a3,1634(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201e6e:	6742                	ld	a4,16(sp)
ffffffffc0201e70:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e74:	67a2                	ld	a5,8(sp)
ffffffffc0201e76:	40d706b3          	sub	a3,a4,a3
ffffffffc0201e7a:	8699                	srai	a3,a3,0x6
ffffffffc0201e7c:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e7e:	06aa                	slli	a3,a3,0xa
ffffffffc0201e80:	0116e693          	ori	a3,a3,17
ffffffffc0201e84:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e86:	6098                	ld	a4,0(s1)
ffffffffc0201e88:	0000b897          	auipc	a7,0xb
ffffffffc0201e8c:	63088893          	addi	a7,a7,1584 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201e90:	c006f693          	andi	a3,a3,-1024
ffffffffc0201e94:	068a                	slli	a3,a3,0x2
ffffffffc0201e96:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e9a:	06e7fc63          	bgeu	a5,a4,ffffffffc0201f12 <get_pte+0x1fc>
ffffffffc0201e9e:	0008b783          	ld	a5,0(a7)
ffffffffc0201ea2:	8031                	srli	s0,s0,0xc
ffffffffc0201ea4:	1ff47413          	andi	s0,s0,511
ffffffffc0201ea8:	040e                	slli	s0,s0,0x3
ffffffffc0201eaa:	96be                	add	a3,a3,a5
}
ffffffffc0201eac:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201eae:	00868533          	add	a0,a3,s0
}
ffffffffc0201eb2:	7442                	ld	s0,48(sp)
ffffffffc0201eb4:	74a2                	ld	s1,40(sp)
ffffffffc0201eb6:	6121                	addi	sp,sp,64
ffffffffc0201eb8:	8082                	ret
ffffffffc0201eba:	70e2                	ld	ra,56(sp)
ffffffffc0201ebc:	7442                	ld	s0,48(sp)
ffffffffc0201ebe:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc0201ec0:	4501                	li	a0,0
}
ffffffffc0201ec2:	6121                	addi	sp,sp,64
ffffffffc0201ec4:	8082                	ret
        intr_disable();
ffffffffc0201ec6:	e83a                	sd	a4,16(sp)
ffffffffc0201ec8:	ec32                	sd	a2,24(sp)
ffffffffc0201eca:	9abfe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ece:	0000b797          	auipc	a5,0xb
ffffffffc0201ed2:	5d27b783          	ld	a5,1490(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201ed6:	4505                	li	a0,1
ffffffffc0201ed8:	6f9c                	ld	a5,24(a5)
ffffffffc0201eda:	9782                	jalr	a5
ffffffffc0201edc:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201ede:	991fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201ee2:	6862                	ld	a6,24(sp)
ffffffffc0201ee4:	6742                	ld	a4,16(sp)
ffffffffc0201ee6:	67a2                	ld	a5,8(sp)
ffffffffc0201ee8:	bdbd                	j	ffffffffc0201d66 <get_pte+0x50>
        intr_disable();
ffffffffc0201eea:	e83e                	sd	a5,16(sp)
ffffffffc0201eec:	989fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0201ef0:	0000b717          	auipc	a4,0xb
ffffffffc0201ef4:	5b073703          	ld	a4,1456(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201ef8:	4505                	li	a0,1
ffffffffc0201efa:	6f18                	ld	a4,24(a4)
ffffffffc0201efc:	9702                	jalr	a4
ffffffffc0201efe:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201f00:	96ffe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201f04:	6722                	ld	a4,8(sp)
ffffffffc0201f06:	67c2                	ld	a5,16(sp)
ffffffffc0201f08:	0000b897          	auipc	a7,0xb
ffffffffc0201f0c:	5b088893          	addi	a7,a7,1456 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201f10:	bf31                	j	ffffffffc0201e2c <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f12:	00003617          	auipc	a2,0x3
ffffffffc0201f16:	ce660613          	addi	a2,a2,-794 # ffffffffc0204bf8 <etext+0xd82>
ffffffffc0201f1a:	0fb00593          	li	a1,251
ffffffffc0201f1e:	00003517          	auipc	a0,0x3
ffffffffc0201f22:	dca50513          	addi	a0,a0,-566 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0201f26:	ce0fe0ef          	jal	ffffffffc0200406 <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f2a:	00003617          	auipc	a2,0x3
ffffffffc0201f2e:	cce60613          	addi	a2,a2,-818 # ffffffffc0204bf8 <etext+0xd82>
ffffffffc0201f32:	0ee00593          	li	a1,238
ffffffffc0201f36:	00003517          	auipc	a0,0x3
ffffffffc0201f3a:	db250513          	addi	a0,a0,-590 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0201f3e:	cc8fe0ef          	jal	ffffffffc0200406 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f42:	86aa                	mv	a3,a0
ffffffffc0201f44:	00003617          	auipc	a2,0x3
ffffffffc0201f48:	cb460613          	addi	a2,a2,-844 # ffffffffc0204bf8 <etext+0xd82>
ffffffffc0201f4c:	0eb00593          	li	a1,235
ffffffffc0201f50:	00003517          	auipc	a0,0x3
ffffffffc0201f54:	d9850513          	addi	a0,a0,-616 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0201f58:	caefe0ef          	jal	ffffffffc0200406 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f5c:	00003617          	auipc	a2,0x3
ffffffffc0201f60:	c9c60613          	addi	a2,a2,-868 # ffffffffc0204bf8 <etext+0xd82>
ffffffffc0201f64:	0f800593          	li	a1,248
ffffffffc0201f68:	00003517          	auipc	a0,0x3
ffffffffc0201f6c:	d8050513          	addi	a0,a0,-640 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0201f70:	c96fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201f74 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201f74:	1141                	addi	sp,sp,-16
ffffffffc0201f76:	e022                	sd	s0,0(sp)
ffffffffc0201f78:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f7a:	4601                	li	a2,0
{
ffffffffc0201f7c:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f7e:	d99ff0ef          	jal	ffffffffc0201d16 <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f82:	c011                	beqz	s0,ffffffffc0201f86 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f84:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f86:	c511                	beqz	a0,ffffffffc0201f92 <get_page+0x1e>
ffffffffc0201f88:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f8a:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f8c:	0017f713          	andi	a4,a5,1
ffffffffc0201f90:	e709                	bnez	a4,ffffffffc0201f9a <get_page+0x26>
}
ffffffffc0201f92:	60a2                	ld	ra,8(sp)
ffffffffc0201f94:	6402                	ld	s0,0(sp)
ffffffffc0201f96:	0141                	addi	sp,sp,16
ffffffffc0201f98:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0201f9a:	0000b717          	auipc	a4,0xb
ffffffffc0201f9e:	52673703          	ld	a4,1318(a4) # ffffffffc020d4c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fa2:	078a                	slli	a5,a5,0x2
ffffffffc0201fa4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201fa6:	00e7ff63          	bgeu	a5,a4,ffffffffc0201fc4 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc0201faa:	0000b517          	auipc	a0,0xb
ffffffffc0201fae:	51e53503          	ld	a0,1310(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201fb2:	60a2                	ld	ra,8(sp)
ffffffffc0201fb4:	6402                	ld	s0,0(sp)
ffffffffc0201fb6:	079a                	slli	a5,a5,0x6
ffffffffc0201fb8:	fe000737          	lui	a4,0xfe000
ffffffffc0201fbc:	97ba                	add	a5,a5,a4
ffffffffc0201fbe:	953e                	add	a0,a0,a5
ffffffffc0201fc0:	0141                	addi	sp,sp,16
ffffffffc0201fc2:	8082                	ret
ffffffffc0201fc4:	c8fff0ef          	jal	ffffffffc0201c52 <pa2page.part.0>

ffffffffc0201fc8 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201fc8:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fca:	4601                	li	a2,0
{
ffffffffc0201fcc:	e822                	sd	s0,16(sp)
ffffffffc0201fce:	ec06                	sd	ra,24(sp)
ffffffffc0201fd0:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fd2:	d45ff0ef          	jal	ffffffffc0201d16 <get_pte>
    if (ptep != NULL)
ffffffffc0201fd6:	c511                	beqz	a0,ffffffffc0201fe2 <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc0201fd8:	6118                	ld	a4,0(a0)
ffffffffc0201fda:	87aa                	mv	a5,a0
ffffffffc0201fdc:	00177693          	andi	a3,a4,1
ffffffffc0201fe0:	e689                	bnez	a3,ffffffffc0201fea <page_remove+0x22>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201fe2:	60e2                	ld	ra,24(sp)
ffffffffc0201fe4:	6442                	ld	s0,16(sp)
ffffffffc0201fe6:	6105                	addi	sp,sp,32
ffffffffc0201fe8:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0201fea:	0000b697          	auipc	a3,0xb
ffffffffc0201fee:	4d66b683          	ld	a3,1238(a3) # ffffffffc020d4c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0201ff2:	070a                	slli	a4,a4,0x2
ffffffffc0201ff4:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0201ff6:	06d77563          	bgeu	a4,a3,ffffffffc0202060 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ffa:	0000b517          	auipc	a0,0xb
ffffffffc0201ffe:	4ce53503          	ld	a0,1230(a0) # ffffffffc020d4c8 <pages>
ffffffffc0202002:	071a                	slli	a4,a4,0x6
ffffffffc0202004:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202008:	9736                	add	a4,a4,a3
ffffffffc020200a:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc020200c:	4118                	lw	a4,0(a0)
ffffffffc020200e:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3ddf2b0f>
ffffffffc0202010:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202012:	cb09                	beqz	a4,ffffffffc0202024 <page_remove+0x5c>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202014:	0007b023          	sd	zero,0(a5)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202018:	12040073          	sfence.vma	s0
}
ffffffffc020201c:	60e2                	ld	ra,24(sp)
ffffffffc020201e:	6442                	ld	s0,16(sp)
ffffffffc0202020:	6105                	addi	sp,sp,32
ffffffffc0202022:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202024:	10002773          	csrr	a4,sstatus
ffffffffc0202028:	8b09                	andi	a4,a4,2
ffffffffc020202a:	eb19                	bnez	a4,ffffffffc0202040 <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc020202c:	0000b717          	auipc	a4,0xb
ffffffffc0202030:	47473703          	ld	a4,1140(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0202034:	4585                	li	a1,1
ffffffffc0202036:	e03e                	sd	a5,0(sp)
ffffffffc0202038:	7318                	ld	a4,32(a4)
ffffffffc020203a:	9702                	jalr	a4
    if (flag) {
ffffffffc020203c:	6782                	ld	a5,0(sp)
ffffffffc020203e:	bfd9                	j	ffffffffc0202014 <page_remove+0x4c>
        intr_disable();
ffffffffc0202040:	e43e                	sd	a5,8(sp)
ffffffffc0202042:	e02a                	sd	a0,0(sp)
ffffffffc0202044:	831fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0202048:	0000b717          	auipc	a4,0xb
ffffffffc020204c:	45873703          	ld	a4,1112(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0202050:	6502                	ld	a0,0(sp)
ffffffffc0202052:	4585                	li	a1,1
ffffffffc0202054:	7318                	ld	a4,32(a4)
ffffffffc0202056:	9702                	jalr	a4
        intr_enable();
ffffffffc0202058:	817fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020205c:	67a2                	ld	a5,8(sp)
ffffffffc020205e:	bf5d                	j	ffffffffc0202014 <page_remove+0x4c>
ffffffffc0202060:	bf3ff0ef          	jal	ffffffffc0201c52 <pa2page.part.0>

ffffffffc0202064 <page_insert>:
{
ffffffffc0202064:	7139                	addi	sp,sp,-64
ffffffffc0202066:	f426                	sd	s1,40(sp)
ffffffffc0202068:	84b2                	mv	s1,a2
ffffffffc020206a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020206c:	4605                	li	a2,1
{
ffffffffc020206e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202070:	85a6                	mv	a1,s1
{
ffffffffc0202072:	fc06                	sd	ra,56(sp)
ffffffffc0202074:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202076:	ca1ff0ef          	jal	ffffffffc0201d16 <get_pte>
    if (ptep == NULL)
ffffffffc020207a:	cd61                	beqz	a0,ffffffffc0202152 <page_insert+0xee>
    page->ref += 1;
ffffffffc020207c:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc020207e:	611c                	ld	a5,0(a0)
ffffffffc0202080:	66a2                	ld	a3,8(sp)
ffffffffc0202082:	0015861b          	addiw	a2,a1,1 # 1001 <kern_entry-0xffffffffc01fefff>
ffffffffc0202086:	c010                	sw	a2,0(s0)
ffffffffc0202088:	0017f613          	andi	a2,a5,1
ffffffffc020208c:	872a                	mv	a4,a0
ffffffffc020208e:	e61d                	bnez	a2,ffffffffc02020bc <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc0202090:	0000b617          	auipc	a2,0xb
ffffffffc0202094:	43863603          	ld	a2,1080(a2) # ffffffffc020d4c8 <pages>
    return page - pages + nbase;
ffffffffc0202098:	8c11                	sub	s0,s0,a2
ffffffffc020209a:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020209c:	200007b7          	lui	a5,0x20000
ffffffffc02020a0:	042a                	slli	s0,s0,0xa
ffffffffc02020a2:	943e                	add	s0,s0,a5
ffffffffc02020a4:	8ec1                	or	a3,a3,s0
ffffffffc02020a6:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02020aa:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020ac:	12048073          	sfence.vma	s1
    return 0;
ffffffffc02020b0:	4501                	li	a0,0
}
ffffffffc02020b2:	70e2                	ld	ra,56(sp)
ffffffffc02020b4:	7442                	ld	s0,48(sp)
ffffffffc02020b6:	74a2                	ld	s1,40(sp)
ffffffffc02020b8:	6121                	addi	sp,sp,64
ffffffffc02020ba:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02020bc:	0000b617          	auipc	a2,0xb
ffffffffc02020c0:	40463603          	ld	a2,1028(a2) # ffffffffc020d4c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02020c4:	078a                	slli	a5,a5,0x2
ffffffffc02020c6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020c8:	08c7f763          	bgeu	a5,a2,ffffffffc0202156 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02020cc:	0000b617          	auipc	a2,0xb
ffffffffc02020d0:	3fc63603          	ld	a2,1020(a2) # ffffffffc020d4c8 <pages>
ffffffffc02020d4:	fe000537          	lui	a0,0xfe000
ffffffffc02020d8:	079a                	slli	a5,a5,0x6
ffffffffc02020da:	97aa                	add	a5,a5,a0
ffffffffc02020dc:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc02020e0:	00a40963          	beq	s0,a0,ffffffffc02020f2 <page_insert+0x8e>
    page->ref -= 1;
ffffffffc02020e4:	411c                	lw	a5,0(a0)
ffffffffc02020e6:	37fd                	addiw	a5,a5,-1 # 1fffffff <kern_entry-0xffffffffa0200001>
ffffffffc02020e8:	c11c                	sw	a5,0(a0)
        if (page_ref(page) ==
ffffffffc02020ea:	c791                	beqz	a5,ffffffffc02020f6 <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020ec:	12048073          	sfence.vma	s1
}
ffffffffc02020f0:	b765                	j	ffffffffc0202098 <page_insert+0x34>
ffffffffc02020f2:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc02020f4:	b755                	j	ffffffffc0202098 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02020f6:	100027f3          	csrr	a5,sstatus
ffffffffc02020fa:	8b89                	andi	a5,a5,2
ffffffffc02020fc:	e39d                	bnez	a5,ffffffffc0202122 <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc02020fe:	0000b797          	auipc	a5,0xb
ffffffffc0202102:	3a27b783          	ld	a5,930(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0202106:	4585                	li	a1,1
ffffffffc0202108:	e83a                	sd	a4,16(sp)
ffffffffc020210a:	739c                	ld	a5,32(a5)
ffffffffc020210c:	e436                	sd	a3,8(sp)
ffffffffc020210e:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202110:	0000b617          	auipc	a2,0xb
ffffffffc0202114:	3b863603          	ld	a2,952(a2) # ffffffffc020d4c8 <pages>
ffffffffc0202118:	66a2                	ld	a3,8(sp)
ffffffffc020211a:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020211c:	12048073          	sfence.vma	s1
ffffffffc0202120:	bfa5                	j	ffffffffc0202098 <page_insert+0x34>
        intr_disable();
ffffffffc0202122:	ec3a                	sd	a4,24(sp)
ffffffffc0202124:	e836                	sd	a3,16(sp)
ffffffffc0202126:	e42a                	sd	a0,8(sp)
ffffffffc0202128:	f4cfe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020212c:	0000b797          	auipc	a5,0xb
ffffffffc0202130:	3747b783          	ld	a5,884(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0202134:	6522                	ld	a0,8(sp)
ffffffffc0202136:	4585                	li	a1,1
ffffffffc0202138:	739c                	ld	a5,32(a5)
ffffffffc020213a:	9782                	jalr	a5
        intr_enable();
ffffffffc020213c:	f32fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202140:	0000b617          	auipc	a2,0xb
ffffffffc0202144:	38863603          	ld	a2,904(a2) # ffffffffc020d4c8 <pages>
ffffffffc0202148:	6762                	ld	a4,24(sp)
ffffffffc020214a:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020214c:	12048073          	sfence.vma	s1
ffffffffc0202150:	b7a1                	j	ffffffffc0202098 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc0202152:	5571                	li	a0,-4
ffffffffc0202154:	bfb9                	j	ffffffffc02020b2 <page_insert+0x4e>
ffffffffc0202156:	afdff0ef          	jal	ffffffffc0201c52 <pa2page.part.0>

ffffffffc020215a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020215a:	00003797          	auipc	a5,0x3
ffffffffc020215e:	6a678793          	addi	a5,a5,1702 # ffffffffc0205800 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202162:	638c                	ld	a1,0(a5)
{
ffffffffc0202164:	7159                	addi	sp,sp,-112
ffffffffc0202166:	f486                	sd	ra,104(sp)
ffffffffc0202168:	e8ca                	sd	s2,80(sp)
ffffffffc020216a:	e4ce                	sd	s3,72(sp)
ffffffffc020216c:	f85a                	sd	s6,48(sp)
ffffffffc020216e:	f0a2                	sd	s0,96(sp)
ffffffffc0202170:	eca6                	sd	s1,88(sp)
ffffffffc0202172:	e0d2                	sd	s4,64(sp)
ffffffffc0202174:	fc56                	sd	s5,56(sp)
ffffffffc0202176:	f45e                	sd	s7,40(sp)
ffffffffc0202178:	f062                	sd	s8,32(sp)
ffffffffc020217a:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020217c:	0000bb17          	auipc	s6,0xb
ffffffffc0202180:	324b0b13          	addi	s6,s6,804 # ffffffffc020d4a0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202184:	00003517          	auipc	a0,0x3
ffffffffc0202188:	b7450513          	addi	a0,a0,-1164 # ffffffffc0204cf8 <etext+0xe82>
    pmm_manager = &default_pmm_manager;
ffffffffc020218c:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202190:	804fe0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202194:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202198:	0000b997          	auipc	s3,0xb
ffffffffc020219c:	32098993          	addi	s3,s3,800 # ffffffffc020d4b8 <va_pa_offset>
    pmm_manager->init();
ffffffffc02021a0:	679c                	ld	a5,8(a5)
ffffffffc02021a2:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02021a4:	57f5                	li	a5,-3
ffffffffc02021a6:	07fa                	slli	a5,a5,0x1e
ffffffffc02021a8:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02021ac:	eaefe0ef          	jal	ffffffffc020085a <get_memory_base>
ffffffffc02021b0:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02021b2:	eb2fe0ef          	jal	ffffffffc0200864 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02021b6:	70050e63          	beqz	a0,ffffffffc02028d2 <pmm_init+0x778>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021ba:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02021bc:	00003517          	auipc	a0,0x3
ffffffffc02021c0:	b7450513          	addi	a0,a0,-1164 # ffffffffc0204d30 <etext+0xeba>
ffffffffc02021c4:	fd1fd0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021c8:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02021cc:	864a                	mv	a2,s2
ffffffffc02021ce:	85a6                	mv	a1,s1
ffffffffc02021d0:	fff40693          	addi	a3,s0,-1
ffffffffc02021d4:	00003517          	auipc	a0,0x3
ffffffffc02021d8:	b7450513          	addi	a0,a0,-1164 # ffffffffc0204d48 <etext+0xed2>
ffffffffc02021dc:	fb9fd0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc02021e0:	c80007b7          	lui	a5,0xc8000
ffffffffc02021e4:	8522                	mv	a0,s0
ffffffffc02021e6:	5287ed63          	bltu	a5,s0,ffffffffc0202720 <pmm_init+0x5c6>
ffffffffc02021ea:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021ec:	0000c617          	auipc	a2,0xc
ffffffffc02021f0:	30360613          	addi	a2,a2,771 # ffffffffc020e4ef <end+0xfff>
ffffffffc02021f4:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc02021f6:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021f8:	0000bb97          	auipc	s7,0xb
ffffffffc02021fc:	2d0b8b93          	addi	s7,s7,720 # ffffffffc020d4c8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202200:	0000b497          	auipc	s1,0xb
ffffffffc0202204:	2c048493          	addi	s1,s1,704 # ffffffffc020d4c0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202208:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc020220c:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020220e:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202212:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202214:	02f50763          	beq	a0,a5,ffffffffc0202242 <pmm_init+0xe8>
ffffffffc0202218:	4701                	li	a4,0
ffffffffc020221a:	4585                	li	a1,1
ffffffffc020221c:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202220:	00671793          	slli	a5,a4,0x6
ffffffffc0202224:	97b2                	add	a5,a5,a2
ffffffffc0202226:	07a1                	addi	a5,a5,8 # 80008 <kern_entry-0xffffffffc017fff8>
ffffffffc0202228:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020222c:	6088                	ld	a0,0(s1)
ffffffffc020222e:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202230:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202234:	00d507b3          	add	a5,a0,a3
ffffffffc0202238:	fef764e3          	bltu	a4,a5,ffffffffc0202220 <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020223c:	079a                	slli	a5,a5,0x6
ffffffffc020223e:	00f606b3          	add	a3,a2,a5
ffffffffc0202242:	c02007b7          	lui	a5,0xc0200
ffffffffc0202246:	16f6eee3          	bltu	a3,a5,ffffffffc0202bc2 <pmm_init+0xa68>
ffffffffc020224a:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020224e:	77fd                	lui	a5,0xfffff
ffffffffc0202250:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202252:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202254:	4e86ed63          	bltu	a3,s0,ffffffffc020274e <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202258:	00003517          	auipc	a0,0x3
ffffffffc020225c:	b1850513          	addi	a0,a0,-1256 # ffffffffc0204d70 <etext+0xefa>
ffffffffc0202260:	f35fd0ef          	jal	ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202264:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202268:	0000b917          	auipc	s2,0xb
ffffffffc020226c:	24890913          	addi	s2,s2,584 # ffffffffc020d4b0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202270:	7b9c                	ld	a5,48(a5)
ffffffffc0202272:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202274:	00003517          	auipc	a0,0x3
ffffffffc0202278:	b1450513          	addi	a0,a0,-1260 # ffffffffc0204d88 <etext+0xf12>
ffffffffc020227c:	f19fd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202280:	00006697          	auipc	a3,0x6
ffffffffc0202284:	d8068693          	addi	a3,a3,-640 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0202288:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020228c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202290:	2af6eee3          	bltu	a3,a5,ffffffffc0202d4c <pmm_init+0xbf2>
ffffffffc0202294:	0009b783          	ld	a5,0(s3)
ffffffffc0202298:	8e9d                	sub	a3,a3,a5
ffffffffc020229a:	0000b797          	auipc	a5,0xb
ffffffffc020229e:	20d7b723          	sd	a3,526(a5) # ffffffffc020d4a8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02022a2:	100027f3          	csrr	a5,sstatus
ffffffffc02022a6:	8b89                	andi	a5,a5,2
ffffffffc02022a8:	48079963          	bnez	a5,ffffffffc020273a <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02022ac:	000b3783          	ld	a5,0(s6)
ffffffffc02022b0:	779c                	ld	a5,40(a5)
ffffffffc02022b2:	9782                	jalr	a5
ffffffffc02022b4:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02022b6:	6098                	ld	a4,0(s1)
ffffffffc02022b8:	c80007b7          	lui	a5,0xc8000
ffffffffc02022bc:	83b1                	srli	a5,a5,0xc
ffffffffc02022be:	66e7e663          	bltu	a5,a4,ffffffffc020292a <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02022c2:	00093503          	ld	a0,0(s2)
ffffffffc02022c6:	64050263          	beqz	a0,ffffffffc020290a <pmm_init+0x7b0>
ffffffffc02022ca:	03451793          	slli	a5,a0,0x34
ffffffffc02022ce:	62079e63          	bnez	a5,ffffffffc020290a <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02022d2:	4601                	li	a2,0
ffffffffc02022d4:	4581                	li	a1,0
ffffffffc02022d6:	c9fff0ef          	jal	ffffffffc0201f74 <get_page>
ffffffffc02022da:	240519e3          	bnez	a0,ffffffffc0202d2c <pmm_init+0xbd2>
ffffffffc02022de:	100027f3          	csrr	a5,sstatus
ffffffffc02022e2:	8b89                	andi	a5,a5,2
ffffffffc02022e4:	44079063          	bnez	a5,ffffffffc0202724 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022e8:	000b3783          	ld	a5,0(s6)
ffffffffc02022ec:	4505                	li	a0,1
ffffffffc02022ee:	6f9c                	ld	a5,24(a5)
ffffffffc02022f0:	9782                	jalr	a5
ffffffffc02022f2:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02022f4:	00093503          	ld	a0,0(s2)
ffffffffc02022f8:	4681                	li	a3,0
ffffffffc02022fa:	4601                	li	a2,0
ffffffffc02022fc:	85d2                	mv	a1,s4
ffffffffc02022fe:	d67ff0ef          	jal	ffffffffc0202064 <page_insert>
ffffffffc0202302:	280511e3          	bnez	a0,ffffffffc0202d84 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202306:	00093503          	ld	a0,0(s2)
ffffffffc020230a:	4601                	li	a2,0
ffffffffc020230c:	4581                	li	a1,0
ffffffffc020230e:	a09ff0ef          	jal	ffffffffc0201d16 <get_pte>
ffffffffc0202312:	240509e3          	beqz	a0,ffffffffc0202d64 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc0202316:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202318:	0017f713          	andi	a4,a5,1
ffffffffc020231c:	58070f63          	beqz	a4,ffffffffc02028ba <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202320:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202322:	078a                	slli	a5,a5,0x2
ffffffffc0202324:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202326:	58e7f863          	bgeu	a5,a4,ffffffffc02028b6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020232a:	000bb683          	ld	a3,0(s7)
ffffffffc020232e:	079a                	slli	a5,a5,0x6
ffffffffc0202330:	fe000637          	lui	a2,0xfe000
ffffffffc0202334:	97b2                	add	a5,a5,a2
ffffffffc0202336:	97b6                	add	a5,a5,a3
ffffffffc0202338:	14fa1ae3          	bne	s4,a5,ffffffffc0202c8c <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc020233c:	000a2683          	lw	a3,0(s4)
ffffffffc0202340:	4785                	li	a5,1
ffffffffc0202342:	12f695e3          	bne	a3,a5,ffffffffc0202c6c <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202346:	00093503          	ld	a0,0(s2)
ffffffffc020234a:	77fd                	lui	a5,0xfffff
ffffffffc020234c:	6114                	ld	a3,0(a0)
ffffffffc020234e:	068a                	slli	a3,a3,0x2
ffffffffc0202350:	8efd                	and	a3,a3,a5
ffffffffc0202352:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202356:	0ee67fe3          	bgeu	a2,a4,ffffffffc0202c54 <pmm_init+0xafa>
ffffffffc020235a:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020235e:	96e2                	add	a3,a3,s8
ffffffffc0202360:	0006ba83          	ld	s5,0(a3)
ffffffffc0202364:	0a8a                	slli	s5,s5,0x2
ffffffffc0202366:	00fafab3          	and	s5,s5,a5
ffffffffc020236a:	00cad793          	srli	a5,s5,0xc
ffffffffc020236e:	0ce7f6e3          	bgeu	a5,a4,ffffffffc0202c3a <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202372:	4601                	li	a2,0
ffffffffc0202374:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202376:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202378:	99fff0ef          	jal	ffffffffc0201d16 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020237c:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020237e:	05851ee3          	bne	a0,s8,ffffffffc0202bda <pmm_init+0xa80>
ffffffffc0202382:	100027f3          	csrr	a5,sstatus
ffffffffc0202386:	8b89                	andi	a5,a5,2
ffffffffc0202388:	3e079b63          	bnez	a5,ffffffffc020277e <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc020238c:	000b3783          	ld	a5,0(s6)
ffffffffc0202390:	4505                	li	a0,1
ffffffffc0202392:	6f9c                	ld	a5,24(a5)
ffffffffc0202394:	9782                	jalr	a5
ffffffffc0202396:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202398:	00093503          	ld	a0,0(s2)
ffffffffc020239c:	46d1                	li	a3,20
ffffffffc020239e:	6605                	lui	a2,0x1
ffffffffc02023a0:	85e2                	mv	a1,s8
ffffffffc02023a2:	cc3ff0ef          	jal	ffffffffc0202064 <page_insert>
ffffffffc02023a6:	06051ae3          	bnez	a0,ffffffffc0202c1a <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023aa:	00093503          	ld	a0,0(s2)
ffffffffc02023ae:	4601                	li	a2,0
ffffffffc02023b0:	6585                	lui	a1,0x1
ffffffffc02023b2:	965ff0ef          	jal	ffffffffc0201d16 <get_pte>
ffffffffc02023b6:	040502e3          	beqz	a0,ffffffffc0202bfa <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc02023ba:	611c                	ld	a5,0(a0)
ffffffffc02023bc:	0107f713          	andi	a4,a5,16
ffffffffc02023c0:	7e070163          	beqz	a4,ffffffffc0202ba2 <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc02023c4:	8b91                	andi	a5,a5,4
ffffffffc02023c6:	7a078e63          	beqz	a5,ffffffffc0202b82 <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02023ca:	00093503          	ld	a0,0(s2)
ffffffffc02023ce:	611c                	ld	a5,0(a0)
ffffffffc02023d0:	8bc1                	andi	a5,a5,16
ffffffffc02023d2:	78078863          	beqz	a5,ffffffffc0202b62 <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc02023d6:	000c2703          	lw	a4,0(s8)
ffffffffc02023da:	4785                	li	a5,1
ffffffffc02023dc:	76f71363          	bne	a4,a5,ffffffffc0202b42 <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02023e0:	4681                	li	a3,0
ffffffffc02023e2:	6605                	lui	a2,0x1
ffffffffc02023e4:	85d2                	mv	a1,s4
ffffffffc02023e6:	c7fff0ef          	jal	ffffffffc0202064 <page_insert>
ffffffffc02023ea:	72051c63          	bnez	a0,ffffffffc0202b22 <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc02023ee:	000a2703          	lw	a4,0(s4)
ffffffffc02023f2:	4789                	li	a5,2
ffffffffc02023f4:	70f71763          	bne	a4,a5,ffffffffc0202b02 <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc02023f8:	000c2783          	lw	a5,0(s8)
ffffffffc02023fc:	6e079363          	bnez	a5,ffffffffc0202ae2 <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202400:	00093503          	ld	a0,0(s2)
ffffffffc0202404:	4601                	li	a2,0
ffffffffc0202406:	6585                	lui	a1,0x1
ffffffffc0202408:	90fff0ef          	jal	ffffffffc0201d16 <get_pte>
ffffffffc020240c:	6a050b63          	beqz	a0,ffffffffc0202ac2 <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202410:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202412:	00177793          	andi	a5,a4,1
ffffffffc0202416:	4a078263          	beqz	a5,ffffffffc02028ba <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc020241a:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020241c:	00271793          	slli	a5,a4,0x2
ffffffffc0202420:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202422:	48d7fa63          	bgeu	a5,a3,ffffffffc02028b6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202426:	000bb683          	ld	a3,0(s7)
ffffffffc020242a:	fff80ab7          	lui	s5,0xfff80
ffffffffc020242e:	97d6                	add	a5,a5,s5
ffffffffc0202430:	079a                	slli	a5,a5,0x6
ffffffffc0202432:	97b6                	add	a5,a5,a3
ffffffffc0202434:	66fa1763          	bne	s4,a5,ffffffffc0202aa2 <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202438:	8b41                	andi	a4,a4,16
ffffffffc020243a:	64071463          	bnez	a4,ffffffffc0202a82 <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc020243e:	00093503          	ld	a0,0(s2)
ffffffffc0202442:	4581                	li	a1,0
ffffffffc0202444:	b85ff0ef          	jal	ffffffffc0201fc8 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202448:	000a2c83          	lw	s9,0(s4)
ffffffffc020244c:	4785                	li	a5,1
ffffffffc020244e:	60fc9a63          	bne	s9,a5,ffffffffc0202a62 <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202452:	000c2783          	lw	a5,0(s8)
ffffffffc0202456:	5e079663          	bnez	a5,ffffffffc0202a42 <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc020245a:	00093503          	ld	a0,0(s2)
ffffffffc020245e:	6585                	lui	a1,0x1
ffffffffc0202460:	b69ff0ef          	jal	ffffffffc0201fc8 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202464:	000a2783          	lw	a5,0(s4)
ffffffffc0202468:	52079d63          	bnez	a5,ffffffffc02029a2 <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc020246c:	000c2783          	lw	a5,0(s8)
ffffffffc0202470:	50079963          	bnez	a5,ffffffffc0202982 <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202474:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202478:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020247a:	000a3783          	ld	a5,0(s4)
ffffffffc020247e:	078a                	slli	a5,a5,0x2
ffffffffc0202480:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202482:	42e7fa63          	bgeu	a5,a4,ffffffffc02028b6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202486:	000bb503          	ld	a0,0(s7)
ffffffffc020248a:	97d6                	add	a5,a5,s5
ffffffffc020248c:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc020248e:	00f506b3          	add	a3,a0,a5
ffffffffc0202492:	4294                	lw	a3,0(a3)
ffffffffc0202494:	4d969763          	bne	a3,s9,ffffffffc0202962 <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202498:	8799                	srai	a5,a5,0x6
ffffffffc020249a:	00080637          	lui	a2,0x80
ffffffffc020249e:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02024a0:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02024a4:	4ae7f363          	bgeu	a5,a4,ffffffffc020294a <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02024a8:	0009b783          	ld	a5,0(s3)
ffffffffc02024ac:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc02024ae:	639c                	ld	a5,0(a5)
ffffffffc02024b0:	078a                	slli	a5,a5,0x2
ffffffffc02024b2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024b4:	40e7f163          	bgeu	a5,a4,ffffffffc02028b6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02024b8:	8f91                	sub	a5,a5,a2
ffffffffc02024ba:	079a                	slli	a5,a5,0x6
ffffffffc02024bc:	953e                	add	a0,a0,a5
ffffffffc02024be:	100027f3          	csrr	a5,sstatus
ffffffffc02024c2:	8b89                	andi	a5,a5,2
ffffffffc02024c4:	30079863          	bnez	a5,ffffffffc02027d4 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc02024c8:	000b3783          	ld	a5,0(s6)
ffffffffc02024cc:	4585                	li	a1,1
ffffffffc02024ce:	739c                	ld	a5,32(a5)
ffffffffc02024d0:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02024d2:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02024d6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024d8:	078a                	slli	a5,a5,0x2
ffffffffc02024da:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024dc:	3ce7fd63          	bgeu	a5,a4,ffffffffc02028b6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02024e0:	000bb503          	ld	a0,0(s7)
ffffffffc02024e4:	fe000737          	lui	a4,0xfe000
ffffffffc02024e8:	079a                	slli	a5,a5,0x6
ffffffffc02024ea:	97ba                	add	a5,a5,a4
ffffffffc02024ec:	953e                	add	a0,a0,a5
ffffffffc02024ee:	100027f3          	csrr	a5,sstatus
ffffffffc02024f2:	8b89                	andi	a5,a5,2
ffffffffc02024f4:	2c079463          	bnez	a5,ffffffffc02027bc <pmm_init+0x662>
ffffffffc02024f8:	000b3783          	ld	a5,0(s6)
ffffffffc02024fc:	4585                	li	a1,1
ffffffffc02024fe:	739c                	ld	a5,32(a5)
ffffffffc0202500:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202502:	00093783          	ld	a5,0(s2)
ffffffffc0202506:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b10>
    asm volatile("sfence.vma");
ffffffffc020250a:	12000073          	sfence.vma
ffffffffc020250e:	100027f3          	csrr	a5,sstatus
ffffffffc0202512:	8b89                	andi	a5,a5,2
ffffffffc0202514:	28079a63          	bnez	a5,ffffffffc02027a8 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202518:	000b3783          	ld	a5,0(s6)
ffffffffc020251c:	779c                	ld	a5,40(a5)
ffffffffc020251e:	9782                	jalr	a5
ffffffffc0202520:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202522:	4d441063          	bne	s0,s4,ffffffffc02029e2 <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202526:	00003517          	auipc	a0,0x3
ffffffffc020252a:	bb250513          	addi	a0,a0,-1102 # ffffffffc02050d8 <etext+0x1262>
ffffffffc020252e:	c67fd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0202532:	100027f3          	csrr	a5,sstatus
ffffffffc0202536:	8b89                	andi	a5,a5,2
ffffffffc0202538:	24079e63          	bnez	a5,ffffffffc0202794 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc020253c:	000b3783          	ld	a5,0(s6)
ffffffffc0202540:	779c                	ld	a5,40(a5)
ffffffffc0202542:	9782                	jalr	a5
ffffffffc0202544:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202546:	609c                	ld	a5,0(s1)
ffffffffc0202548:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020254c:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020254e:	00c79713          	slli	a4,a5,0xc
ffffffffc0202552:	6a85                	lui	s5,0x1
ffffffffc0202554:	02e47c63          	bgeu	s0,a4,ffffffffc020258c <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202558:	00c45713          	srli	a4,s0,0xc
ffffffffc020255c:	30f77063          	bgeu	a4,a5,ffffffffc020285c <pmm_init+0x702>
ffffffffc0202560:	0009b583          	ld	a1,0(s3)
ffffffffc0202564:	00093503          	ld	a0,0(s2)
ffffffffc0202568:	4601                	li	a2,0
ffffffffc020256a:	95a2                	add	a1,a1,s0
ffffffffc020256c:	faaff0ef          	jal	ffffffffc0201d16 <get_pte>
ffffffffc0202570:	32050363          	beqz	a0,ffffffffc0202896 <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202574:	611c                	ld	a5,0(a0)
ffffffffc0202576:	078a                	slli	a5,a5,0x2
ffffffffc0202578:	0147f7b3          	and	a5,a5,s4
ffffffffc020257c:	2e879d63          	bne	a5,s0,ffffffffc0202876 <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202580:	609c                	ld	a5,0(s1)
ffffffffc0202582:	9456                	add	s0,s0,s5
ffffffffc0202584:	00c79713          	slli	a4,a5,0xc
ffffffffc0202588:	fce468e3          	bltu	s0,a4,ffffffffc0202558 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc020258c:	00093783          	ld	a5,0(s2)
ffffffffc0202590:	639c                	ld	a5,0(a5)
ffffffffc0202592:	42079863          	bnez	a5,ffffffffc02029c2 <pmm_init+0x868>
ffffffffc0202596:	100027f3          	csrr	a5,sstatus
ffffffffc020259a:	8b89                	andi	a5,a5,2
ffffffffc020259c:	24079863          	bnez	a5,ffffffffc02027ec <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc02025a0:	000b3783          	ld	a5,0(s6)
ffffffffc02025a4:	4505                	li	a0,1
ffffffffc02025a6:	6f9c                	ld	a5,24(a5)
ffffffffc02025a8:	9782                	jalr	a5
ffffffffc02025aa:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025ac:	00093503          	ld	a0,0(s2)
ffffffffc02025b0:	4699                	li	a3,6
ffffffffc02025b2:	10000613          	li	a2,256
ffffffffc02025b6:	85a2                	mv	a1,s0
ffffffffc02025b8:	aadff0ef          	jal	ffffffffc0202064 <page_insert>
ffffffffc02025bc:	46051363          	bnez	a0,ffffffffc0202a22 <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc02025c0:	4018                	lw	a4,0(s0)
ffffffffc02025c2:	4785                	li	a5,1
ffffffffc02025c4:	42f71f63          	bne	a4,a5,ffffffffc0202a02 <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025c8:	00093503          	ld	a0,0(s2)
ffffffffc02025cc:	6605                	lui	a2,0x1
ffffffffc02025ce:	10060613          	addi	a2,a2,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025d2:	4699                	li	a3,6
ffffffffc02025d4:	85a2                	mv	a1,s0
ffffffffc02025d6:	a8fff0ef          	jal	ffffffffc0202064 <page_insert>
ffffffffc02025da:	72051963          	bnez	a0,ffffffffc0202d0c <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc02025de:	4018                	lw	a4,0(s0)
ffffffffc02025e0:	4789                	li	a5,2
ffffffffc02025e2:	70f71563          	bne	a4,a5,ffffffffc0202cec <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02025e6:	00003597          	auipc	a1,0x3
ffffffffc02025ea:	c3a58593          	addi	a1,a1,-966 # ffffffffc0205220 <etext+0x13aa>
ffffffffc02025ee:	10000513          	li	a0,256
ffffffffc02025f2:	7b6010ef          	jal	ffffffffc0203da8 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02025f6:	6585                	lui	a1,0x1
ffffffffc02025f8:	10058593          	addi	a1,a1,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025fc:	10000513          	li	a0,256
ffffffffc0202600:	7ba010ef          	jal	ffffffffc0203dba <strcmp>
ffffffffc0202604:	6c051463          	bnez	a0,ffffffffc0202ccc <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202608:	000bb683          	ld	a3,0(s7)
ffffffffc020260c:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202610:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202612:	40d406b3          	sub	a3,s0,a3
ffffffffc0202616:	8699                	srai	a3,a3,0x6
ffffffffc0202618:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020261a:	00c69793          	slli	a5,a3,0xc
ffffffffc020261e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202620:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202622:	32e7f463          	bgeu	a5,a4,ffffffffc020294a <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202626:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020262a:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020262e:	97b6                	add	a5,a5,a3
ffffffffc0202630:	10078023          	sb	zero,256(a5) # 80100 <kern_entry-0xffffffffc017ff00>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202634:	740010ef          	jal	ffffffffc0203d74 <strlen>
ffffffffc0202638:	66051a63          	bnez	a0,ffffffffc0202cac <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc020263c:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202640:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202642:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fdf1b10>
ffffffffc0202646:	078a                	slli	a5,a5,0x2
ffffffffc0202648:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020264a:	26e7f663          	bgeu	a5,a4,ffffffffc02028b6 <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc020264e:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202652:	2ee7fc63          	bgeu	a5,a4,ffffffffc020294a <pmm_init+0x7f0>
ffffffffc0202656:	0009b783          	ld	a5,0(s3)
ffffffffc020265a:	00f689b3          	add	s3,a3,a5
ffffffffc020265e:	100027f3          	csrr	a5,sstatus
ffffffffc0202662:	8b89                	andi	a5,a5,2
ffffffffc0202664:	1e079163          	bnez	a5,ffffffffc0202846 <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202668:	000b3783          	ld	a5,0(s6)
ffffffffc020266c:	8522                	mv	a0,s0
ffffffffc020266e:	4585                	li	a1,1
ffffffffc0202670:	739c                	ld	a5,32(a5)
ffffffffc0202672:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202674:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202678:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020267a:	078a                	slli	a5,a5,0x2
ffffffffc020267c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020267e:	22e7fc63          	bgeu	a5,a4,ffffffffc02028b6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202682:	000bb503          	ld	a0,0(s7)
ffffffffc0202686:	fe000737          	lui	a4,0xfe000
ffffffffc020268a:	079a                	slli	a5,a5,0x6
ffffffffc020268c:	97ba                	add	a5,a5,a4
ffffffffc020268e:	953e                	add	a0,a0,a5
ffffffffc0202690:	100027f3          	csrr	a5,sstatus
ffffffffc0202694:	8b89                	andi	a5,a5,2
ffffffffc0202696:	18079c63          	bnez	a5,ffffffffc020282e <pmm_init+0x6d4>
ffffffffc020269a:	000b3783          	ld	a5,0(s6)
ffffffffc020269e:	4585                	li	a1,1
ffffffffc02026a0:	739c                	ld	a5,32(a5)
ffffffffc02026a2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02026a4:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02026a8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02026aa:	078a                	slli	a5,a5,0x2
ffffffffc02026ac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026ae:	20e7f463          	bgeu	a5,a4,ffffffffc02028b6 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02026b2:	000bb503          	ld	a0,0(s7)
ffffffffc02026b6:	fe000737          	lui	a4,0xfe000
ffffffffc02026ba:	079a                	slli	a5,a5,0x6
ffffffffc02026bc:	97ba                	add	a5,a5,a4
ffffffffc02026be:	953e                	add	a0,a0,a5
ffffffffc02026c0:	100027f3          	csrr	a5,sstatus
ffffffffc02026c4:	8b89                	andi	a5,a5,2
ffffffffc02026c6:	14079863          	bnez	a5,ffffffffc0202816 <pmm_init+0x6bc>
ffffffffc02026ca:	000b3783          	ld	a5,0(s6)
ffffffffc02026ce:	4585                	li	a1,1
ffffffffc02026d0:	739c                	ld	a5,32(a5)
ffffffffc02026d2:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02026d4:	00093783          	ld	a5,0(s2)
ffffffffc02026d8:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc02026dc:	12000073          	sfence.vma
ffffffffc02026e0:	100027f3          	csrr	a5,sstatus
ffffffffc02026e4:	8b89                	andi	a5,a5,2
ffffffffc02026e6:	10079e63          	bnez	a5,ffffffffc0202802 <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026ea:	000b3783          	ld	a5,0(s6)
ffffffffc02026ee:	779c                	ld	a5,40(a5)
ffffffffc02026f0:	9782                	jalr	a5
ffffffffc02026f2:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02026f4:	1e8c1b63          	bne	s8,s0,ffffffffc02028ea <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02026f8:	00003517          	auipc	a0,0x3
ffffffffc02026fc:	ba050513          	addi	a0,a0,-1120 # ffffffffc0205298 <etext+0x1422>
ffffffffc0202700:	a95fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0202704:	7406                	ld	s0,96(sp)
ffffffffc0202706:	70a6                	ld	ra,104(sp)
ffffffffc0202708:	64e6                	ld	s1,88(sp)
ffffffffc020270a:	6946                	ld	s2,80(sp)
ffffffffc020270c:	69a6                	ld	s3,72(sp)
ffffffffc020270e:	6a06                	ld	s4,64(sp)
ffffffffc0202710:	7ae2                	ld	s5,56(sp)
ffffffffc0202712:	7b42                	ld	s6,48(sp)
ffffffffc0202714:	7ba2                	ld	s7,40(sp)
ffffffffc0202716:	7c02                	ld	s8,32(sp)
ffffffffc0202718:	6ce2                	ld	s9,24(sp)
ffffffffc020271a:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc020271c:	b70ff06f          	j	ffffffffc0201a8c <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202720:	853e                	mv	a0,a5
ffffffffc0202722:	b4e1                	j	ffffffffc02021ea <pmm_init+0x90>
        intr_disable();
ffffffffc0202724:	950fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202728:	000b3783          	ld	a5,0(s6)
ffffffffc020272c:	4505                	li	a0,1
ffffffffc020272e:	6f9c                	ld	a5,24(a5)
ffffffffc0202730:	9782                	jalr	a5
ffffffffc0202732:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202734:	93afe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202738:	be75                	j	ffffffffc02022f4 <pmm_init+0x19a>
        intr_disable();
ffffffffc020273a:	93afe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020273e:	000b3783          	ld	a5,0(s6)
ffffffffc0202742:	779c                	ld	a5,40(a5)
ffffffffc0202744:	9782                	jalr	a5
ffffffffc0202746:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202748:	926fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020274c:	b6ad                	j	ffffffffc02022b6 <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020274e:	6705                	lui	a4,0x1
ffffffffc0202750:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0202752:	96ba                	add	a3,a3,a4
ffffffffc0202754:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202756:	00c7d713          	srli	a4,a5,0xc
ffffffffc020275a:	14a77e63          	bgeu	a4,a0,ffffffffc02028b6 <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc020275e:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202762:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202764:	071a                	slli	a4,a4,0x6
ffffffffc0202766:	fe0007b7          	lui	a5,0xfe000
ffffffffc020276a:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc020276c:	6a9c                	ld	a5,16(a3)
ffffffffc020276e:	00c45593          	srli	a1,s0,0xc
ffffffffc0202772:	00e60533          	add	a0,a2,a4
ffffffffc0202776:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202778:	0009b583          	ld	a1,0(s3)
}
ffffffffc020277c:	bcf1                	j	ffffffffc0202258 <pmm_init+0xfe>
        intr_disable();
ffffffffc020277e:	8f6fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202782:	000b3783          	ld	a5,0(s6)
ffffffffc0202786:	4505                	li	a0,1
ffffffffc0202788:	6f9c                	ld	a5,24(a5)
ffffffffc020278a:	9782                	jalr	a5
ffffffffc020278c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020278e:	8e0fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202792:	b119                	j	ffffffffc0202398 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202794:	8e0fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202798:	000b3783          	ld	a5,0(s6)
ffffffffc020279c:	779c                	ld	a5,40(a5)
ffffffffc020279e:	9782                	jalr	a5
ffffffffc02027a0:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02027a2:	8ccfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027a6:	b345                	j	ffffffffc0202546 <pmm_init+0x3ec>
        intr_disable();
ffffffffc02027a8:	8ccfe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02027ac:	000b3783          	ld	a5,0(s6)
ffffffffc02027b0:	779c                	ld	a5,40(a5)
ffffffffc02027b2:	9782                	jalr	a5
ffffffffc02027b4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027b6:	8b8fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027ba:	b3a5                	j	ffffffffc0202522 <pmm_init+0x3c8>
ffffffffc02027bc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027be:	8b6fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027c2:	000b3783          	ld	a5,0(s6)
ffffffffc02027c6:	6522                	ld	a0,8(sp)
ffffffffc02027c8:	4585                	li	a1,1
ffffffffc02027ca:	739c                	ld	a5,32(a5)
ffffffffc02027cc:	9782                	jalr	a5
        intr_enable();
ffffffffc02027ce:	8a0fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027d2:	bb05                	j	ffffffffc0202502 <pmm_init+0x3a8>
ffffffffc02027d4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027d6:	89efe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02027da:	000b3783          	ld	a5,0(s6)
ffffffffc02027de:	6522                	ld	a0,8(sp)
ffffffffc02027e0:	4585                	li	a1,1
ffffffffc02027e2:	739c                	ld	a5,32(a5)
ffffffffc02027e4:	9782                	jalr	a5
        intr_enable();
ffffffffc02027e6:	888fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027ea:	b1e5                	j	ffffffffc02024d2 <pmm_init+0x378>
        intr_disable();
ffffffffc02027ec:	888fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027f0:	000b3783          	ld	a5,0(s6)
ffffffffc02027f4:	4505                	li	a0,1
ffffffffc02027f6:	6f9c                	ld	a5,24(a5)
ffffffffc02027f8:	9782                	jalr	a5
ffffffffc02027fa:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02027fc:	872fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202800:	b375                	j	ffffffffc02025ac <pmm_init+0x452>
        intr_disable();
ffffffffc0202802:	872fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202806:	000b3783          	ld	a5,0(s6)
ffffffffc020280a:	779c                	ld	a5,40(a5)
ffffffffc020280c:	9782                	jalr	a5
ffffffffc020280e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202810:	85efe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202814:	b5c5                	j	ffffffffc02026f4 <pmm_init+0x59a>
ffffffffc0202816:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202818:	85cfe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020281c:	000b3783          	ld	a5,0(s6)
ffffffffc0202820:	6522                	ld	a0,8(sp)
ffffffffc0202822:	4585                	li	a1,1
ffffffffc0202824:	739c                	ld	a5,32(a5)
ffffffffc0202826:	9782                	jalr	a5
        intr_enable();
ffffffffc0202828:	846fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020282c:	b565                	j	ffffffffc02026d4 <pmm_init+0x57a>
ffffffffc020282e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202830:	844fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0202834:	000b3783          	ld	a5,0(s6)
ffffffffc0202838:	6522                	ld	a0,8(sp)
ffffffffc020283a:	4585                	li	a1,1
ffffffffc020283c:	739c                	ld	a5,32(a5)
ffffffffc020283e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202840:	82efe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202844:	b585                	j	ffffffffc02026a4 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202846:	82efe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc020284a:	000b3783          	ld	a5,0(s6)
ffffffffc020284e:	8522                	mv	a0,s0
ffffffffc0202850:	4585                	li	a1,1
ffffffffc0202852:	739c                	ld	a5,32(a5)
ffffffffc0202854:	9782                	jalr	a5
        intr_enable();
ffffffffc0202856:	818fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020285a:	bd29                	j	ffffffffc0202674 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020285c:	86a2                	mv	a3,s0
ffffffffc020285e:	00002617          	auipc	a2,0x2
ffffffffc0202862:	39a60613          	addi	a2,a2,922 # ffffffffc0204bf8 <etext+0xd82>
ffffffffc0202866:	1a400593          	li	a1,420
ffffffffc020286a:	00002517          	auipc	a0,0x2
ffffffffc020286e:	47e50513          	addi	a0,a0,1150 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202872:	b95fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202876:	00003697          	auipc	a3,0x3
ffffffffc020287a:	8c268693          	addi	a3,a3,-1854 # ffffffffc0205138 <etext+0x12c2>
ffffffffc020287e:	00002617          	auipc	a2,0x2
ffffffffc0202882:	fca60613          	addi	a2,a2,-54 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202886:	1a500593          	li	a1,421
ffffffffc020288a:	00002517          	auipc	a0,0x2
ffffffffc020288e:	45e50513          	addi	a0,a0,1118 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202892:	b75fd0ef          	jal	ffffffffc0200406 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202896:	00003697          	auipc	a3,0x3
ffffffffc020289a:	86268693          	addi	a3,a3,-1950 # ffffffffc02050f8 <etext+0x1282>
ffffffffc020289e:	00002617          	auipc	a2,0x2
ffffffffc02028a2:	faa60613          	addi	a2,a2,-86 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02028a6:	1a400593          	li	a1,420
ffffffffc02028aa:	00002517          	auipc	a0,0x2
ffffffffc02028ae:	43e50513          	addi	a0,a0,1086 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc02028b2:	b55fd0ef          	jal	ffffffffc0200406 <__panic>
ffffffffc02028b6:	b9cff0ef          	jal	ffffffffc0201c52 <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc02028ba:	00002617          	auipc	a2,0x2
ffffffffc02028be:	5de60613          	addi	a2,a2,1502 # ffffffffc0204e98 <etext+0x1022>
ffffffffc02028c2:	07f00593          	li	a1,127
ffffffffc02028c6:	00002517          	auipc	a0,0x2
ffffffffc02028ca:	35a50513          	addi	a0,a0,858 # ffffffffc0204c20 <etext+0xdaa>
ffffffffc02028ce:	b39fd0ef          	jal	ffffffffc0200406 <__panic>
        panic("DTB memory info not available");
ffffffffc02028d2:	00002617          	auipc	a2,0x2
ffffffffc02028d6:	43e60613          	addi	a2,a2,1086 # ffffffffc0204d10 <etext+0xe9a>
ffffffffc02028da:	06400593          	li	a1,100
ffffffffc02028de:	00002517          	auipc	a0,0x2
ffffffffc02028e2:	40a50513          	addi	a0,a0,1034 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc02028e6:	b21fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02028ea:	00002697          	auipc	a3,0x2
ffffffffc02028ee:	7c668693          	addi	a3,a3,1990 # ffffffffc02050b0 <etext+0x123a>
ffffffffc02028f2:	00002617          	auipc	a2,0x2
ffffffffc02028f6:	f5660613          	addi	a2,a2,-170 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02028fa:	1bf00593          	li	a1,447
ffffffffc02028fe:	00002517          	auipc	a0,0x2
ffffffffc0202902:	3ea50513          	addi	a0,a0,1002 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202906:	b01fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020290a:	00002697          	auipc	a3,0x2
ffffffffc020290e:	4be68693          	addi	a3,a3,1214 # ffffffffc0204dc8 <etext+0xf52>
ffffffffc0202912:	00002617          	auipc	a2,0x2
ffffffffc0202916:	f3660613          	addi	a2,a2,-202 # ffffffffc0204848 <etext+0x9d2>
ffffffffc020291a:	16600593          	li	a1,358
ffffffffc020291e:	00002517          	auipc	a0,0x2
ffffffffc0202922:	3ca50513          	addi	a0,a0,970 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202926:	ae1fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020292a:	00002697          	auipc	a3,0x2
ffffffffc020292e:	47e68693          	addi	a3,a3,1150 # ffffffffc0204da8 <etext+0xf32>
ffffffffc0202932:	00002617          	auipc	a2,0x2
ffffffffc0202936:	f1660613          	addi	a2,a2,-234 # ffffffffc0204848 <etext+0x9d2>
ffffffffc020293a:	16500593          	li	a1,357
ffffffffc020293e:	00002517          	auipc	a0,0x2
ffffffffc0202942:	3aa50513          	addi	a0,a0,938 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202946:	ac1fd0ef          	jal	ffffffffc0200406 <__panic>
    return KADDR(page2pa(page));
ffffffffc020294a:	00002617          	auipc	a2,0x2
ffffffffc020294e:	2ae60613          	addi	a2,a2,686 # ffffffffc0204bf8 <etext+0xd82>
ffffffffc0202952:	07100593          	li	a1,113
ffffffffc0202956:	00002517          	auipc	a0,0x2
ffffffffc020295a:	2ca50513          	addi	a0,a0,714 # ffffffffc0204c20 <etext+0xdaa>
ffffffffc020295e:	aa9fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202962:	00002697          	auipc	a3,0x2
ffffffffc0202966:	71e68693          	addi	a3,a3,1822 # ffffffffc0205080 <etext+0x120a>
ffffffffc020296a:	00002617          	auipc	a2,0x2
ffffffffc020296e:	ede60613          	addi	a2,a2,-290 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202972:	18d00593          	li	a1,397
ffffffffc0202976:	00002517          	auipc	a0,0x2
ffffffffc020297a:	37250513          	addi	a0,a0,882 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc020297e:	a89fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202982:	00002697          	auipc	a3,0x2
ffffffffc0202986:	6b668693          	addi	a3,a3,1718 # ffffffffc0205038 <etext+0x11c2>
ffffffffc020298a:	00002617          	auipc	a2,0x2
ffffffffc020298e:	ebe60613          	addi	a2,a2,-322 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202992:	18b00593          	li	a1,395
ffffffffc0202996:	00002517          	auipc	a0,0x2
ffffffffc020299a:	35250513          	addi	a0,a0,850 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc020299e:	a69fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02029a2:	00002697          	auipc	a3,0x2
ffffffffc02029a6:	6c668693          	addi	a3,a3,1734 # ffffffffc0205068 <etext+0x11f2>
ffffffffc02029aa:	00002617          	auipc	a2,0x2
ffffffffc02029ae:	e9e60613          	addi	a2,a2,-354 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02029b2:	18a00593          	li	a1,394
ffffffffc02029b6:	00002517          	auipc	a0,0x2
ffffffffc02029ba:	33250513          	addi	a0,a0,818 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc02029be:	a49fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02029c2:	00002697          	auipc	a3,0x2
ffffffffc02029c6:	78e68693          	addi	a3,a3,1934 # ffffffffc0205150 <etext+0x12da>
ffffffffc02029ca:	00002617          	auipc	a2,0x2
ffffffffc02029ce:	e7e60613          	addi	a2,a2,-386 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02029d2:	1a800593          	li	a1,424
ffffffffc02029d6:	00002517          	auipc	a0,0x2
ffffffffc02029da:	31250513          	addi	a0,a0,786 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc02029de:	a29fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02029e2:	00002697          	auipc	a3,0x2
ffffffffc02029e6:	6ce68693          	addi	a3,a3,1742 # ffffffffc02050b0 <etext+0x123a>
ffffffffc02029ea:	00002617          	auipc	a2,0x2
ffffffffc02029ee:	e5e60613          	addi	a2,a2,-418 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02029f2:	19500593          	li	a1,405
ffffffffc02029f6:	00002517          	auipc	a0,0x2
ffffffffc02029fa:	2f250513          	addi	a0,a0,754 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc02029fe:	a09fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202a02:	00002697          	auipc	a3,0x2
ffffffffc0202a06:	7a668693          	addi	a3,a3,1958 # ffffffffc02051a8 <etext+0x1332>
ffffffffc0202a0a:	00002617          	auipc	a2,0x2
ffffffffc0202a0e:	e3e60613          	addi	a2,a2,-450 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202a12:	1ad00593          	li	a1,429
ffffffffc0202a16:	00002517          	auipc	a0,0x2
ffffffffc0202a1a:	2d250513          	addi	a0,a0,722 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202a1e:	9e9fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a22:	00002697          	auipc	a3,0x2
ffffffffc0202a26:	74668693          	addi	a3,a3,1862 # ffffffffc0205168 <etext+0x12f2>
ffffffffc0202a2a:	00002617          	auipc	a2,0x2
ffffffffc0202a2e:	e1e60613          	addi	a2,a2,-482 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202a32:	1ac00593          	li	a1,428
ffffffffc0202a36:	00002517          	auipc	a0,0x2
ffffffffc0202a3a:	2b250513          	addi	a0,a0,690 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202a3e:	9c9fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a42:	00002697          	auipc	a3,0x2
ffffffffc0202a46:	5f668693          	addi	a3,a3,1526 # ffffffffc0205038 <etext+0x11c2>
ffffffffc0202a4a:	00002617          	auipc	a2,0x2
ffffffffc0202a4e:	dfe60613          	addi	a2,a2,-514 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202a52:	18700593          	li	a1,391
ffffffffc0202a56:	00002517          	auipc	a0,0x2
ffffffffc0202a5a:	29250513          	addi	a0,a0,658 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202a5e:	9a9fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202a62:	00002697          	auipc	a3,0x2
ffffffffc0202a66:	47668693          	addi	a3,a3,1142 # ffffffffc0204ed8 <etext+0x1062>
ffffffffc0202a6a:	00002617          	auipc	a2,0x2
ffffffffc0202a6e:	dde60613          	addi	a2,a2,-546 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202a72:	18600593          	li	a1,390
ffffffffc0202a76:	00002517          	auipc	a0,0x2
ffffffffc0202a7a:	27250513          	addi	a0,a0,626 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202a7e:	989fd0ef          	jal	ffffffffc0200406 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a82:	00002697          	auipc	a3,0x2
ffffffffc0202a86:	5ce68693          	addi	a3,a3,1486 # ffffffffc0205050 <etext+0x11da>
ffffffffc0202a8a:	00002617          	auipc	a2,0x2
ffffffffc0202a8e:	dbe60613          	addi	a2,a2,-578 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202a92:	18300593          	li	a1,387
ffffffffc0202a96:	00002517          	auipc	a0,0x2
ffffffffc0202a9a:	25250513          	addi	a0,a0,594 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202a9e:	969fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202aa2:	00002697          	auipc	a3,0x2
ffffffffc0202aa6:	41e68693          	addi	a3,a3,1054 # ffffffffc0204ec0 <etext+0x104a>
ffffffffc0202aaa:	00002617          	auipc	a2,0x2
ffffffffc0202aae:	d9e60613          	addi	a2,a2,-610 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202ab2:	18200593          	li	a1,386
ffffffffc0202ab6:	00002517          	auipc	a0,0x2
ffffffffc0202aba:	23250513          	addi	a0,a0,562 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202abe:	949fd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202ac2:	00002697          	auipc	a3,0x2
ffffffffc0202ac6:	49e68693          	addi	a3,a3,1182 # ffffffffc0204f60 <etext+0x10ea>
ffffffffc0202aca:	00002617          	auipc	a2,0x2
ffffffffc0202ace:	d7e60613          	addi	a2,a2,-642 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202ad2:	18100593          	li	a1,385
ffffffffc0202ad6:	00002517          	auipc	a0,0x2
ffffffffc0202ada:	21250513          	addi	a0,a0,530 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202ade:	929fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202ae2:	00002697          	auipc	a3,0x2
ffffffffc0202ae6:	55668693          	addi	a3,a3,1366 # ffffffffc0205038 <etext+0x11c2>
ffffffffc0202aea:	00002617          	auipc	a2,0x2
ffffffffc0202aee:	d5e60613          	addi	a2,a2,-674 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202af2:	18000593          	li	a1,384
ffffffffc0202af6:	00002517          	auipc	a0,0x2
ffffffffc0202afa:	1f250513          	addi	a0,a0,498 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202afe:	909fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202b02:	00002697          	auipc	a3,0x2
ffffffffc0202b06:	51e68693          	addi	a3,a3,1310 # ffffffffc0205020 <etext+0x11aa>
ffffffffc0202b0a:	00002617          	auipc	a2,0x2
ffffffffc0202b0e:	d3e60613          	addi	a2,a2,-706 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202b12:	17f00593          	li	a1,383
ffffffffc0202b16:	00002517          	auipc	a0,0x2
ffffffffc0202b1a:	1d250513          	addi	a0,a0,466 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202b1e:	8e9fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202b22:	00002697          	auipc	a3,0x2
ffffffffc0202b26:	4ce68693          	addi	a3,a3,1230 # ffffffffc0204ff0 <etext+0x117a>
ffffffffc0202b2a:	00002617          	auipc	a2,0x2
ffffffffc0202b2e:	d1e60613          	addi	a2,a2,-738 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202b32:	17e00593          	li	a1,382
ffffffffc0202b36:	00002517          	auipc	a0,0x2
ffffffffc0202b3a:	1b250513          	addi	a0,a0,434 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202b3e:	8c9fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202b42:	00002697          	auipc	a3,0x2
ffffffffc0202b46:	49668693          	addi	a3,a3,1174 # ffffffffc0204fd8 <etext+0x1162>
ffffffffc0202b4a:	00002617          	auipc	a2,0x2
ffffffffc0202b4e:	cfe60613          	addi	a2,a2,-770 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202b52:	17c00593          	li	a1,380
ffffffffc0202b56:	00002517          	auipc	a0,0x2
ffffffffc0202b5a:	19250513          	addi	a0,a0,402 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202b5e:	8a9fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b62:	00002697          	auipc	a3,0x2
ffffffffc0202b66:	45668693          	addi	a3,a3,1110 # ffffffffc0204fb8 <etext+0x1142>
ffffffffc0202b6a:	00002617          	auipc	a2,0x2
ffffffffc0202b6e:	cde60613          	addi	a2,a2,-802 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202b72:	17b00593          	li	a1,379
ffffffffc0202b76:	00002517          	auipc	a0,0x2
ffffffffc0202b7a:	17250513          	addi	a0,a0,370 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202b7e:	889fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b82:	00002697          	auipc	a3,0x2
ffffffffc0202b86:	42668693          	addi	a3,a3,1062 # ffffffffc0204fa8 <etext+0x1132>
ffffffffc0202b8a:	00002617          	auipc	a2,0x2
ffffffffc0202b8e:	cbe60613          	addi	a2,a2,-834 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202b92:	17a00593          	li	a1,378
ffffffffc0202b96:	00002517          	auipc	a0,0x2
ffffffffc0202b9a:	15250513          	addi	a0,a0,338 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202b9e:	869fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202ba2:	00002697          	auipc	a3,0x2
ffffffffc0202ba6:	3f668693          	addi	a3,a3,1014 # ffffffffc0204f98 <etext+0x1122>
ffffffffc0202baa:	00002617          	auipc	a2,0x2
ffffffffc0202bae:	c9e60613          	addi	a2,a2,-866 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202bb2:	17900593          	li	a1,377
ffffffffc0202bb6:	00002517          	auipc	a0,0x2
ffffffffc0202bba:	13250513          	addi	a0,a0,306 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202bbe:	849fd0ef          	jal	ffffffffc0200406 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202bc2:	00002617          	auipc	a2,0x2
ffffffffc0202bc6:	0de60613          	addi	a2,a2,222 # ffffffffc0204ca0 <etext+0xe2a>
ffffffffc0202bca:	08000593          	li	a1,128
ffffffffc0202bce:	00002517          	auipc	a0,0x2
ffffffffc0202bd2:	11a50513          	addi	a0,a0,282 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202bd6:	831fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202bda:	00002697          	auipc	a3,0x2
ffffffffc0202bde:	31668693          	addi	a3,a3,790 # ffffffffc0204ef0 <etext+0x107a>
ffffffffc0202be2:	00002617          	auipc	a2,0x2
ffffffffc0202be6:	c6660613          	addi	a2,a2,-922 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202bea:	17400593          	li	a1,372
ffffffffc0202bee:	00002517          	auipc	a0,0x2
ffffffffc0202bf2:	0fa50513          	addi	a0,a0,250 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202bf6:	811fd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202bfa:	00002697          	auipc	a3,0x2
ffffffffc0202bfe:	36668693          	addi	a3,a3,870 # ffffffffc0204f60 <etext+0x10ea>
ffffffffc0202c02:	00002617          	auipc	a2,0x2
ffffffffc0202c06:	c4660613          	addi	a2,a2,-954 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202c0a:	17800593          	li	a1,376
ffffffffc0202c0e:	00002517          	auipc	a0,0x2
ffffffffc0202c12:	0da50513          	addi	a0,a0,218 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202c16:	ff0fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202c1a:	00002697          	auipc	a3,0x2
ffffffffc0202c1e:	30668693          	addi	a3,a3,774 # ffffffffc0204f20 <etext+0x10aa>
ffffffffc0202c22:	00002617          	auipc	a2,0x2
ffffffffc0202c26:	c2660613          	addi	a2,a2,-986 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202c2a:	17700593          	li	a1,375
ffffffffc0202c2e:	00002517          	auipc	a0,0x2
ffffffffc0202c32:	0ba50513          	addi	a0,a0,186 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202c36:	fd0fd0ef          	jal	ffffffffc0200406 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202c3a:	86d6                	mv	a3,s5
ffffffffc0202c3c:	00002617          	auipc	a2,0x2
ffffffffc0202c40:	fbc60613          	addi	a2,a2,-68 # ffffffffc0204bf8 <etext+0xd82>
ffffffffc0202c44:	17300593          	li	a1,371
ffffffffc0202c48:	00002517          	auipc	a0,0x2
ffffffffc0202c4c:	0a050513          	addi	a0,a0,160 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202c50:	fb6fd0ef          	jal	ffffffffc0200406 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202c54:	00002617          	auipc	a2,0x2
ffffffffc0202c58:	fa460613          	addi	a2,a2,-92 # ffffffffc0204bf8 <etext+0xd82>
ffffffffc0202c5c:	17200593          	li	a1,370
ffffffffc0202c60:	00002517          	auipc	a0,0x2
ffffffffc0202c64:	08850513          	addi	a0,a0,136 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202c68:	f9efd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202c6c:	00002697          	auipc	a3,0x2
ffffffffc0202c70:	26c68693          	addi	a3,a3,620 # ffffffffc0204ed8 <etext+0x1062>
ffffffffc0202c74:	00002617          	auipc	a2,0x2
ffffffffc0202c78:	bd460613          	addi	a2,a2,-1068 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202c7c:	17000593          	li	a1,368
ffffffffc0202c80:	00002517          	auipc	a0,0x2
ffffffffc0202c84:	06850513          	addi	a0,a0,104 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202c88:	f7efd0ef          	jal	ffffffffc0200406 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c8c:	00002697          	auipc	a3,0x2
ffffffffc0202c90:	23468693          	addi	a3,a3,564 # ffffffffc0204ec0 <etext+0x104a>
ffffffffc0202c94:	00002617          	auipc	a2,0x2
ffffffffc0202c98:	bb460613          	addi	a2,a2,-1100 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202c9c:	16f00593          	li	a1,367
ffffffffc0202ca0:	00002517          	auipc	a0,0x2
ffffffffc0202ca4:	04850513          	addi	a0,a0,72 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202ca8:	f5efd0ef          	jal	ffffffffc0200406 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202cac:	00002697          	auipc	a3,0x2
ffffffffc0202cb0:	5c468693          	addi	a3,a3,1476 # ffffffffc0205270 <etext+0x13fa>
ffffffffc0202cb4:	00002617          	auipc	a2,0x2
ffffffffc0202cb8:	b9460613          	addi	a2,a2,-1132 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202cbc:	1b600593          	li	a1,438
ffffffffc0202cc0:	00002517          	auipc	a0,0x2
ffffffffc0202cc4:	02850513          	addi	a0,a0,40 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202cc8:	f3efd0ef          	jal	ffffffffc0200406 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202ccc:	00002697          	auipc	a3,0x2
ffffffffc0202cd0:	56c68693          	addi	a3,a3,1388 # ffffffffc0205238 <etext+0x13c2>
ffffffffc0202cd4:	00002617          	auipc	a2,0x2
ffffffffc0202cd8:	b7460613          	addi	a2,a2,-1164 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202cdc:	1b300593          	li	a1,435
ffffffffc0202ce0:	00002517          	auipc	a0,0x2
ffffffffc0202ce4:	00850513          	addi	a0,a0,8 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202ce8:	f1efd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202cec:	00002697          	auipc	a3,0x2
ffffffffc0202cf0:	51c68693          	addi	a3,a3,1308 # ffffffffc0205208 <etext+0x1392>
ffffffffc0202cf4:	00002617          	auipc	a2,0x2
ffffffffc0202cf8:	b5460613          	addi	a2,a2,-1196 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202cfc:	1af00593          	li	a1,431
ffffffffc0202d00:	00002517          	auipc	a0,0x2
ffffffffc0202d04:	fe850513          	addi	a0,a0,-24 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202d08:	efefd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202d0c:	00002697          	auipc	a3,0x2
ffffffffc0202d10:	4b468693          	addi	a3,a3,1204 # ffffffffc02051c0 <etext+0x134a>
ffffffffc0202d14:	00002617          	auipc	a2,0x2
ffffffffc0202d18:	b3460613          	addi	a2,a2,-1228 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202d1c:	1ae00593          	li	a1,430
ffffffffc0202d20:	00002517          	auipc	a0,0x2
ffffffffc0202d24:	fc850513          	addi	a0,a0,-56 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202d28:	edefd0ef          	jal	ffffffffc0200406 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202d2c:	00002697          	auipc	a3,0x2
ffffffffc0202d30:	0dc68693          	addi	a3,a3,220 # ffffffffc0204e08 <etext+0xf92>
ffffffffc0202d34:	00002617          	auipc	a2,0x2
ffffffffc0202d38:	b1460613          	addi	a2,a2,-1260 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202d3c:	16700593          	li	a1,359
ffffffffc0202d40:	00002517          	auipc	a0,0x2
ffffffffc0202d44:	fa850513          	addi	a0,a0,-88 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202d48:	ebefd0ef          	jal	ffffffffc0200406 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202d4c:	00002617          	auipc	a2,0x2
ffffffffc0202d50:	f5460613          	addi	a2,a2,-172 # ffffffffc0204ca0 <etext+0xe2a>
ffffffffc0202d54:	0cb00593          	li	a1,203
ffffffffc0202d58:	00002517          	auipc	a0,0x2
ffffffffc0202d5c:	f9050513          	addi	a0,a0,-112 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202d60:	ea6fd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202d64:	00002697          	auipc	a3,0x2
ffffffffc0202d68:	10468693          	addi	a3,a3,260 # ffffffffc0204e68 <etext+0xff2>
ffffffffc0202d6c:	00002617          	auipc	a2,0x2
ffffffffc0202d70:	adc60613          	addi	a2,a2,-1316 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202d74:	16e00593          	li	a1,366
ffffffffc0202d78:	00002517          	auipc	a0,0x2
ffffffffc0202d7c:	f7050513          	addi	a0,a0,-144 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202d80:	e86fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d84:	00002697          	auipc	a3,0x2
ffffffffc0202d88:	0b468693          	addi	a3,a3,180 # ffffffffc0204e38 <etext+0xfc2>
ffffffffc0202d8c:	00002617          	auipc	a2,0x2
ffffffffc0202d90:	abc60613          	addi	a2,a2,-1348 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202d94:	16b00593          	li	a1,363
ffffffffc0202d98:	00002517          	auipc	a0,0x2
ffffffffc0202d9c:	f5050513          	addi	a0,a0,-176 # ffffffffc0204ce8 <etext+0xe72>
ffffffffc0202da0:	e66fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202da4 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202da4:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202da6:	00002697          	auipc	a3,0x2
ffffffffc0202daa:	51268693          	addi	a3,a3,1298 # ffffffffc02052b8 <etext+0x1442>
ffffffffc0202dae:	00002617          	auipc	a2,0x2
ffffffffc0202db2:	a9a60613          	addi	a2,a2,-1382 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202db6:	08800593          	li	a1,136
ffffffffc0202dba:	00002517          	auipc	a0,0x2
ffffffffc0202dbe:	51e50513          	addi	a0,a0,1310 # ffffffffc02052d8 <etext+0x1462>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202dc2:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202dc4:	e42fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202dc8 <find_vma>:
    if (mm != NULL)
ffffffffc0202dc8:	c505                	beqz	a0,ffffffffc0202df0 <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc0202dca:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202dcc:	c781                	beqz	a5,ffffffffc0202dd4 <find_vma+0xc>
ffffffffc0202dce:	6798                	ld	a4,8(a5)
ffffffffc0202dd0:	02e5f363          	bgeu	a1,a4,ffffffffc0202df6 <find_vma+0x2e>
    return listelm->next;
ffffffffc0202dd4:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc0202dd6:	00f50d63          	beq	a0,a5,ffffffffc0202df0 <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202dda:	fe87b703          	ld	a4,-24(a5) # fffffffffdffffe8 <end+0x3ddf2af8>
ffffffffc0202dde:	00e5e663          	bltu	a1,a4,ffffffffc0202dea <find_vma+0x22>
ffffffffc0202de2:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202de6:	00e5ee63          	bltu	a1,a4,ffffffffc0202e02 <find_vma+0x3a>
ffffffffc0202dea:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202dec:	fef517e3          	bne	a0,a5,ffffffffc0202dda <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc0202df0:	4781                	li	a5,0
}
ffffffffc0202df2:	853e                	mv	a0,a5
ffffffffc0202df4:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202df6:	6b98                	ld	a4,16(a5)
ffffffffc0202df8:	fce5fee3          	bgeu	a1,a4,ffffffffc0202dd4 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0202dfc:	e91c                	sd	a5,16(a0)
}
ffffffffc0202dfe:	853e                	mv	a0,a5
ffffffffc0202e00:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202e02:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202e04:	e91c                	sd	a5,16(a0)
ffffffffc0202e06:	bfe5                	j	ffffffffc0202dfe <find_vma+0x36>

ffffffffc0202e08 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e08:	6590                	ld	a2,8(a1)
ffffffffc0202e0a:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202e0e:	1141                	addi	sp,sp,-16
ffffffffc0202e10:	e406                	sd	ra,8(sp)
ffffffffc0202e12:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e14:	01066763          	bltu	a2,a6,ffffffffc0202e22 <insert_vma_struct+0x1a>
ffffffffc0202e18:	a8b9                	j	ffffffffc0202e76 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e1a:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202e1e:	04e66763          	bltu	a2,a4,ffffffffc0202e6c <insert_vma_struct+0x64>
ffffffffc0202e22:	86be                	mv	a3,a5
ffffffffc0202e24:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202e26:	fef51ae3          	bne	a0,a5,ffffffffc0202e1a <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202e2a:	02a68463          	beq	a3,a0,ffffffffc0202e52 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202e2e:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e32:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202e36:	08e8f063          	bgeu	a7,a4,ffffffffc0202eb6 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e3a:	04e66e63          	bltu	a2,a4,ffffffffc0202e96 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc0202e3e:	00f50a63          	beq	a0,a5,ffffffffc0202e52 <insert_vma_struct+0x4a>
ffffffffc0202e42:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e46:	05076863          	bltu	a4,a6,ffffffffc0202e96 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0202e4a:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202e4e:	02c77263          	bgeu	a4,a2,ffffffffc0202e72 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202e52:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202e54:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202e56:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202e5a:	e390                	sd	a2,0(a5)
ffffffffc0202e5c:	e690                	sd	a2,8(a3)
}
ffffffffc0202e5e:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202e60:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202e62:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202e64:	2705                	addiw	a4,a4,1
ffffffffc0202e66:	d118                	sw	a4,32(a0)
}
ffffffffc0202e68:	0141                	addi	sp,sp,16
ffffffffc0202e6a:	8082                	ret
    if (le_prev != list)
ffffffffc0202e6c:	fca691e3          	bne	a3,a0,ffffffffc0202e2e <insert_vma_struct+0x26>
ffffffffc0202e70:	bfd9                	j	ffffffffc0202e46 <insert_vma_struct+0x3e>
ffffffffc0202e72:	f33ff0ef          	jal	ffffffffc0202da4 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e76:	00002697          	auipc	a3,0x2
ffffffffc0202e7a:	47268693          	addi	a3,a3,1138 # ffffffffc02052e8 <etext+0x1472>
ffffffffc0202e7e:	00002617          	auipc	a2,0x2
ffffffffc0202e82:	9ca60613          	addi	a2,a2,-1590 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202e86:	08e00593          	li	a1,142
ffffffffc0202e8a:	00002517          	auipc	a0,0x2
ffffffffc0202e8e:	44e50513          	addi	a0,a0,1102 # ffffffffc02052d8 <etext+0x1462>
ffffffffc0202e92:	d74fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e96:	00002697          	auipc	a3,0x2
ffffffffc0202e9a:	49268693          	addi	a3,a3,1170 # ffffffffc0205328 <etext+0x14b2>
ffffffffc0202e9e:	00002617          	auipc	a2,0x2
ffffffffc0202ea2:	9aa60613          	addi	a2,a2,-1622 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202ea6:	08700593          	li	a1,135
ffffffffc0202eaa:	00002517          	auipc	a0,0x2
ffffffffc0202eae:	42e50513          	addi	a0,a0,1070 # ffffffffc02052d8 <etext+0x1462>
ffffffffc0202eb2:	d54fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202eb6:	00002697          	auipc	a3,0x2
ffffffffc0202eba:	45268693          	addi	a3,a3,1106 # ffffffffc0205308 <etext+0x1492>
ffffffffc0202ebe:	00002617          	auipc	a2,0x2
ffffffffc0202ec2:	98a60613          	addi	a2,a2,-1654 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0202ec6:	08600593          	li	a1,134
ffffffffc0202eca:	00002517          	auipc	a0,0x2
ffffffffc0202ece:	40e50513          	addi	a0,a0,1038 # ffffffffc02052d8 <etext+0x1462>
ffffffffc0202ed2:	d34fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202ed6 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202ed6:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ed8:	03000513          	li	a0,48
{
ffffffffc0202edc:	fc06                	sd	ra,56(sp)
ffffffffc0202ede:	f822                	sd	s0,48(sp)
ffffffffc0202ee0:	f426                	sd	s1,40(sp)
ffffffffc0202ee2:	f04a                	sd	s2,32(sp)
ffffffffc0202ee4:	ec4e                	sd	s3,24(sp)
ffffffffc0202ee6:	e852                	sd	s4,16(sp)
ffffffffc0202ee8:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202eea:	bc3fe0ef          	jal	ffffffffc0201aac <kmalloc>
    if (mm != NULL)
ffffffffc0202eee:	18050a63          	beqz	a0,ffffffffc0203082 <vmm_init+0x1ac>
ffffffffc0202ef2:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0202ef4:	e508                	sd	a0,8(a0)
ffffffffc0202ef6:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202ef8:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202efc:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202f00:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202f04:	02053423          	sd	zero,40(a0)
ffffffffc0202f08:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f0c:	03000513          	li	a0,48
ffffffffc0202f10:	b9dfe0ef          	jal	ffffffffc0201aac <kmalloc>
    if (vma != NULL)
ffffffffc0202f14:	14050763          	beqz	a0,ffffffffc0203062 <vmm_init+0x18c>
        vma->vm_end = vm_end;
ffffffffc0202f18:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0202f1c:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f1e:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0202f22:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f24:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0202f26:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0202f28:	8522                	mv	a0,s0
ffffffffc0202f2a:	edfff0ef          	jal	ffffffffc0202e08 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202f2e:	fcf9                	bnez	s1,ffffffffc0202f0c <vmm_init+0x36>
ffffffffc0202f30:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f34:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f38:	03000513          	li	a0,48
ffffffffc0202f3c:	b71fe0ef          	jal	ffffffffc0201aac <kmalloc>
    if (vma != NULL)
ffffffffc0202f40:	16050163          	beqz	a0,ffffffffc02030a2 <vmm_init+0x1cc>
        vma->vm_end = vm_end;
ffffffffc0202f44:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0202f48:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f4a:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0202f4e:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f50:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f52:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0202f54:	8522                	mv	a0,s0
ffffffffc0202f56:	eb3ff0ef          	jal	ffffffffc0202e08 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f5a:	fd249fe3          	bne	s1,s2,ffffffffc0202f38 <vmm_init+0x62>
    return listelm->next;
ffffffffc0202f5e:	641c                	ld	a5,8(s0)
ffffffffc0202f60:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202f62:	1fb00593          	li	a1,507
ffffffffc0202f66:	8abe                	mv	s5,a5
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202f68:	20f40d63          	beq	s0,a5,ffffffffc0203182 <vmm_init+0x2ac>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202f6c:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202f70:	ffe70693          	addi	a3,a4,-2
ffffffffc0202f74:	14d61763          	bne	a2,a3,ffffffffc02030c2 <vmm_init+0x1ec>
ffffffffc0202f78:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202f7c:	14e69363          	bne	a3,a4,ffffffffc02030c2 <vmm_init+0x1ec>
    for (i = 1; i <= step2; i++)
ffffffffc0202f80:	0715                	addi	a4,a4,5
ffffffffc0202f82:	679c                	ld	a5,8(a5)
ffffffffc0202f84:	feb712e3          	bne	a4,a1,ffffffffc0202f68 <vmm_init+0x92>
ffffffffc0202f88:	491d                	li	s2,7
ffffffffc0202f8a:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202f8c:	85a6                	mv	a1,s1
ffffffffc0202f8e:	8522                	mv	a0,s0
ffffffffc0202f90:	e39ff0ef          	jal	ffffffffc0202dc8 <find_vma>
ffffffffc0202f94:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0202f96:	22050663          	beqz	a0,ffffffffc02031c2 <vmm_init+0x2ec>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202f9a:	00148593          	addi	a1,s1,1
ffffffffc0202f9e:	8522                	mv	a0,s0
ffffffffc0202fa0:	e29ff0ef          	jal	ffffffffc0202dc8 <find_vma>
ffffffffc0202fa4:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202fa6:	1e050e63          	beqz	a0,ffffffffc02031a2 <vmm_init+0x2cc>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202faa:	85ca                	mv	a1,s2
ffffffffc0202fac:	8522                	mv	a0,s0
ffffffffc0202fae:	e1bff0ef          	jal	ffffffffc0202dc8 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202fb2:	1a051863          	bnez	a0,ffffffffc0203162 <vmm_init+0x28c>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202fb6:	00348593          	addi	a1,s1,3
ffffffffc0202fba:	8522                	mv	a0,s0
ffffffffc0202fbc:	e0dff0ef          	jal	ffffffffc0202dc8 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202fc0:	18051163          	bnez	a0,ffffffffc0203142 <vmm_init+0x26c>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202fc4:	00448593          	addi	a1,s1,4
ffffffffc0202fc8:	8522                	mv	a0,s0
ffffffffc0202fca:	dffff0ef          	jal	ffffffffc0202dc8 <find_vma>
        assert(vma5 == NULL);
ffffffffc0202fce:	14051a63          	bnez	a0,ffffffffc0203122 <vmm_init+0x24c>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202fd2:	008a3783          	ld	a5,8(s4)
ffffffffc0202fd6:	12979663          	bne	a5,s1,ffffffffc0203102 <vmm_init+0x22c>
ffffffffc0202fda:	010a3783          	ld	a5,16(s4)
ffffffffc0202fde:	13279263          	bne	a5,s2,ffffffffc0203102 <vmm_init+0x22c>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202fe2:	0089b783          	ld	a5,8(s3)
ffffffffc0202fe6:	0e979e63          	bne	a5,s1,ffffffffc02030e2 <vmm_init+0x20c>
ffffffffc0202fea:	0109b783          	ld	a5,16(s3)
ffffffffc0202fee:	0f279a63          	bne	a5,s2,ffffffffc02030e2 <vmm_init+0x20c>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202ff2:	0495                	addi	s1,s1,5
ffffffffc0202ff4:	1f900793          	li	a5,505
ffffffffc0202ff8:	0915                	addi	s2,s2,5
ffffffffc0202ffa:	f8f499e3          	bne	s1,a5,ffffffffc0202f8c <vmm_init+0xb6>
ffffffffc0202ffe:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203000:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203002:	85a6                	mv	a1,s1
ffffffffc0203004:	8522                	mv	a0,s0
ffffffffc0203006:	dc3ff0ef          	jal	ffffffffc0202dc8 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc020300a:	1c051c63          	bnez	a0,ffffffffc02031e2 <vmm_init+0x30c>
    for (i = 4; i >= 0; i--)
ffffffffc020300e:	14fd                	addi	s1,s1,-1
ffffffffc0203010:	ff2499e3          	bne	s1,s2,ffffffffc0203002 <vmm_init+0x12c>
    while ((le = list_next(list)) != list)
ffffffffc0203014:	028a8063          	beq	s5,s0,ffffffffc0203034 <vmm_init+0x15e>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203018:	008ab783          	ld	a5,8(s5) # 1008 <kern_entry-0xffffffffc01feff8>
ffffffffc020301c:	000ab703          	ld	a4,0(s5)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203020:	fe0a8513          	addi	a0,s5,-32
    prev->next = next;
ffffffffc0203024:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203026:	e398                	sd	a4,0(a5)
ffffffffc0203028:	b2bfe0ef          	jal	ffffffffc0201b52 <kfree>
    return listelm->next;
ffffffffc020302c:	641c                	ld	a5,8(s0)
ffffffffc020302e:	8abe                	mv	s5,a5
    while ((le = list_next(list)) != list)
ffffffffc0203030:	fef414e3          	bne	s0,a5,ffffffffc0203018 <vmm_init+0x142>
    kfree(mm); // kfree mm
ffffffffc0203034:	8522                	mv	a0,s0
ffffffffc0203036:	b1dfe0ef          	jal	ffffffffc0201b52 <kfree>
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc020303a:	00002517          	auipc	a0,0x2
ffffffffc020303e:	46e50513          	addi	a0,a0,1134 # ffffffffc02054a8 <etext+0x1632>
ffffffffc0203042:	952fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0203046:	7442                	ld	s0,48(sp)
ffffffffc0203048:	70e2                	ld	ra,56(sp)
ffffffffc020304a:	74a2                	ld	s1,40(sp)
ffffffffc020304c:	7902                	ld	s2,32(sp)
ffffffffc020304e:	69e2                	ld	s3,24(sp)
ffffffffc0203050:	6a42                	ld	s4,16(sp)
ffffffffc0203052:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203054:	00002517          	auipc	a0,0x2
ffffffffc0203058:	47450513          	addi	a0,a0,1140 # ffffffffc02054c8 <etext+0x1652>
}
ffffffffc020305c:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc020305e:	936fd06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc0203062:	00002697          	auipc	a3,0x2
ffffffffc0203066:	2f668693          	addi	a3,a3,758 # ffffffffc0205358 <etext+0x14e2>
ffffffffc020306a:	00001617          	auipc	a2,0x1
ffffffffc020306e:	7de60613          	addi	a2,a2,2014 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0203072:	0da00593          	li	a1,218
ffffffffc0203076:	00002517          	auipc	a0,0x2
ffffffffc020307a:	26250513          	addi	a0,a0,610 # ffffffffc02052d8 <etext+0x1462>
ffffffffc020307e:	b88fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(mm != NULL);
ffffffffc0203082:	00002697          	auipc	a3,0x2
ffffffffc0203086:	2c668693          	addi	a3,a3,710 # ffffffffc0205348 <etext+0x14d2>
ffffffffc020308a:	00001617          	auipc	a2,0x1
ffffffffc020308e:	7be60613          	addi	a2,a2,1982 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0203092:	0d200593          	li	a1,210
ffffffffc0203096:	00002517          	auipc	a0,0x2
ffffffffc020309a:	24250513          	addi	a0,a0,578 # ffffffffc02052d8 <etext+0x1462>
ffffffffc020309e:	b68fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma != NULL);
ffffffffc02030a2:	00002697          	auipc	a3,0x2
ffffffffc02030a6:	2b668693          	addi	a3,a3,694 # ffffffffc0205358 <etext+0x14e2>
ffffffffc02030aa:	00001617          	auipc	a2,0x1
ffffffffc02030ae:	79e60613          	addi	a2,a2,1950 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02030b2:	0e100593          	li	a1,225
ffffffffc02030b6:	00002517          	auipc	a0,0x2
ffffffffc02030ba:	22250513          	addi	a0,a0,546 # ffffffffc02052d8 <etext+0x1462>
ffffffffc02030be:	b48fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02030c2:	00002697          	auipc	a3,0x2
ffffffffc02030c6:	2be68693          	addi	a3,a3,702 # ffffffffc0205380 <etext+0x150a>
ffffffffc02030ca:	00001617          	auipc	a2,0x1
ffffffffc02030ce:	77e60613          	addi	a2,a2,1918 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02030d2:	0eb00593          	li	a1,235
ffffffffc02030d6:	00002517          	auipc	a0,0x2
ffffffffc02030da:	20250513          	addi	a0,a0,514 # ffffffffc02052d8 <etext+0x1462>
ffffffffc02030de:	b28fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02030e2:	00002697          	auipc	a3,0x2
ffffffffc02030e6:	35668693          	addi	a3,a3,854 # ffffffffc0205438 <etext+0x15c2>
ffffffffc02030ea:	00001617          	auipc	a2,0x1
ffffffffc02030ee:	75e60613          	addi	a2,a2,1886 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02030f2:	0fd00593          	li	a1,253
ffffffffc02030f6:	00002517          	auipc	a0,0x2
ffffffffc02030fa:	1e250513          	addi	a0,a0,482 # ffffffffc02052d8 <etext+0x1462>
ffffffffc02030fe:	b08fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203102:	00002697          	auipc	a3,0x2
ffffffffc0203106:	30668693          	addi	a3,a3,774 # ffffffffc0205408 <etext+0x1592>
ffffffffc020310a:	00001617          	auipc	a2,0x1
ffffffffc020310e:	73e60613          	addi	a2,a2,1854 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0203112:	0fc00593          	li	a1,252
ffffffffc0203116:	00002517          	auipc	a0,0x2
ffffffffc020311a:	1c250513          	addi	a0,a0,450 # ffffffffc02052d8 <etext+0x1462>
ffffffffc020311e:	ae8fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma5 == NULL);
ffffffffc0203122:	00002697          	auipc	a3,0x2
ffffffffc0203126:	2d668693          	addi	a3,a3,726 # ffffffffc02053f8 <etext+0x1582>
ffffffffc020312a:	00001617          	auipc	a2,0x1
ffffffffc020312e:	71e60613          	addi	a2,a2,1822 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0203132:	0fa00593          	li	a1,250
ffffffffc0203136:	00002517          	auipc	a0,0x2
ffffffffc020313a:	1a250513          	addi	a0,a0,418 # ffffffffc02052d8 <etext+0x1462>
ffffffffc020313e:	ac8fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma4 == NULL);
ffffffffc0203142:	00002697          	auipc	a3,0x2
ffffffffc0203146:	2a668693          	addi	a3,a3,678 # ffffffffc02053e8 <etext+0x1572>
ffffffffc020314a:	00001617          	auipc	a2,0x1
ffffffffc020314e:	6fe60613          	addi	a2,a2,1790 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0203152:	0f800593          	li	a1,248
ffffffffc0203156:	00002517          	auipc	a0,0x2
ffffffffc020315a:	18250513          	addi	a0,a0,386 # ffffffffc02052d8 <etext+0x1462>
ffffffffc020315e:	aa8fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma3 == NULL);
ffffffffc0203162:	00002697          	auipc	a3,0x2
ffffffffc0203166:	27668693          	addi	a3,a3,630 # ffffffffc02053d8 <etext+0x1562>
ffffffffc020316a:	00001617          	auipc	a2,0x1
ffffffffc020316e:	6de60613          	addi	a2,a2,1758 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0203172:	0f600593          	li	a1,246
ffffffffc0203176:	00002517          	auipc	a0,0x2
ffffffffc020317a:	16250513          	addi	a0,a0,354 # ffffffffc02052d8 <etext+0x1462>
ffffffffc020317e:	a88fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203182:	00002697          	auipc	a3,0x2
ffffffffc0203186:	1e668693          	addi	a3,a3,486 # ffffffffc0205368 <etext+0x14f2>
ffffffffc020318a:	00001617          	auipc	a2,0x1
ffffffffc020318e:	6be60613          	addi	a2,a2,1726 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0203192:	0e900593          	li	a1,233
ffffffffc0203196:	00002517          	auipc	a0,0x2
ffffffffc020319a:	14250513          	addi	a0,a0,322 # ffffffffc02052d8 <etext+0x1462>
ffffffffc020319e:	a68fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma2 != NULL);
ffffffffc02031a2:	00002697          	auipc	a3,0x2
ffffffffc02031a6:	22668693          	addi	a3,a3,550 # ffffffffc02053c8 <etext+0x1552>
ffffffffc02031aa:	00001617          	auipc	a2,0x1
ffffffffc02031ae:	69e60613          	addi	a2,a2,1694 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02031b2:	0f400593          	li	a1,244
ffffffffc02031b6:	00002517          	auipc	a0,0x2
ffffffffc02031ba:	12250513          	addi	a0,a0,290 # ffffffffc02052d8 <etext+0x1462>
ffffffffc02031be:	a48fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma1 != NULL);
ffffffffc02031c2:	00002697          	auipc	a3,0x2
ffffffffc02031c6:	1f668693          	addi	a3,a3,502 # ffffffffc02053b8 <etext+0x1542>
ffffffffc02031ca:	00001617          	auipc	a2,0x1
ffffffffc02031ce:	67e60613          	addi	a2,a2,1662 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02031d2:	0f200593          	li	a1,242
ffffffffc02031d6:	00002517          	auipc	a0,0x2
ffffffffc02031da:	10250513          	addi	a0,a0,258 # ffffffffc02052d8 <etext+0x1462>
ffffffffc02031de:	a28fd0ef          	jal	ffffffffc0200406 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc02031e2:	6914                	ld	a3,16(a0)
ffffffffc02031e4:	6510                	ld	a2,8(a0)
ffffffffc02031e6:	0004859b          	sext.w	a1,s1
ffffffffc02031ea:	00002517          	auipc	a0,0x2
ffffffffc02031ee:	27e50513          	addi	a0,a0,638 # ffffffffc0205468 <etext+0x15f2>
ffffffffc02031f2:	fa3fc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc02031f6:	00002697          	auipc	a3,0x2
ffffffffc02031fa:	29a68693          	addi	a3,a3,666 # ffffffffc0205490 <etext+0x161a>
ffffffffc02031fe:	00001617          	auipc	a2,0x1
ffffffffc0203202:	64a60613          	addi	a2,a2,1610 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0203206:	10700593          	li	a1,263
ffffffffc020320a:	00002517          	auipc	a0,0x2
ffffffffc020320e:	0ce50513          	addi	a0,a0,206 # ffffffffc02052d8 <etext+0x1462>
ffffffffc0203212:	9f4fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0203216 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203216:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203218:	9402                	jalr	s0

	jal do_exit
ffffffffc020321a:	3ba000ef          	jal	ffffffffc02035d4 <do_exit>

ffffffffc020321e <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc020321e:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203220:	0e800513          	li	a0,232
{
ffffffffc0203224:	e022                	sd	s0,0(sp)
ffffffffc0203226:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203228:	885fe0ef          	jal	ffffffffc0201aac <kmalloc>
ffffffffc020322c:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc020322e:	c521                	beqz	a0,ffffffffc0203276 <alloc_proc+0x58>
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        // 初始化进程状态为未初始化
        proc->state = PROC_UNINIT;
ffffffffc0203230:	57fd                	li	a5,-1
ffffffffc0203232:	1782                	slli	a5,a5,0x20
ffffffffc0203234:	e11c                	sd	a5,0(a0)
        // 初始化进程ID为-1（无效ID）
        proc->pid = -1;
        // 初始化运行次数为0
        proc->runs = 0;
ffffffffc0203236:	00052423          	sw	zero,8(a0)
        // 初始化内核栈地址为0
        proc->kstack = 0;
ffffffffc020323a:	00053823          	sd	zero,16(a0)
        // 初始化不需要重新调度
        proc->need_resched = 0;
ffffffffc020323e:	00052c23          	sw	zero,24(a0)
        // 初始化父进程指针为NULL
        proc->parent = NULL;
ffffffffc0203242:	02053023          	sd	zero,32(a0)
        // 初始化内存管理结构为NULL
        proc->mm = NULL;
ffffffffc0203246:	02053423          	sd	zero,40(a0)
        // 初始化上下文结构体（全部设为0）
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc020324a:	07000613          	li	a2,112
ffffffffc020324e:	4581                	li	a1,0
ffffffffc0203250:	03050513          	addi	a0,a0,48
ffffffffc0203254:	3d5000ef          	jal	ffffffffc0203e28 <memset>
        // 初始化陷阱帧指针为NULL
        proc->tf = NULL;
        // 初始化页目录基址为boot_pgdir
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203258:	0000a797          	auipc	a5,0xa
ffffffffc020325c:	2507b783          	ld	a5,592(a5) # ffffffffc020d4a8 <boot_pgdir_pa>
        proc->tf = NULL;
ffffffffc0203260:	0a043023          	sd	zero,160(s0) # ffffffffc02000a0 <kern_init+0x56>
        // 初始化标志位为0
        proc->flags = 0;
ffffffffc0203264:	0a042823          	sw	zero,176(s0)
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203268:	f45c                	sd	a5,168(s0)
        // 初始化进程名称为空字符串
        memset(proc->name, 0, PROC_NAME_LEN + 1); 
ffffffffc020326a:	0b440513          	addi	a0,s0,180
ffffffffc020326e:	4641                	li	a2,16
ffffffffc0203270:	4581                	li	a1,0
ffffffffc0203272:	3b7000ef          	jal	ffffffffc0203e28 <memset>
    }
    return proc;
}
ffffffffc0203276:	60a2                	ld	ra,8(sp)
ffffffffc0203278:	8522                	mv	a0,s0
ffffffffc020327a:	6402                	ld	s0,0(sp)
ffffffffc020327c:	0141                	addi	sp,sp,16
ffffffffc020327e:	8082                	ret

ffffffffc0203280 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203280:	0000a797          	auipc	a5,0xa
ffffffffc0203284:	2587b783          	ld	a5,600(a5) # ffffffffc020d4d8 <current>
ffffffffc0203288:	73c8                	ld	a0,160(a5)
ffffffffc020328a:	aabfd06f          	j	ffffffffc0200d34 <forkrets>

ffffffffc020328e <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc020328e:	1101                	addi	sp,sp,-32
ffffffffc0203290:	e822                	sd	s0,16(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203292:	0000a417          	auipc	s0,0xa
ffffffffc0203296:	24643403          	ld	s0,582(s0) # ffffffffc020d4d8 <current>
{
ffffffffc020329a:	e04a                	sd	s2,0(sp)
    memset(name, 0, sizeof(name));
ffffffffc020329c:	4641                	li	a2,16
{
ffffffffc020329e:	892a                	mv	s2,a0
    memset(name, 0, sizeof(name));
ffffffffc02032a0:	4581                	li	a1,0
ffffffffc02032a2:	00006517          	auipc	a0,0x6
ffffffffc02032a6:	1a650513          	addi	a0,a0,422 # ffffffffc0209448 <name.2>
{
ffffffffc02032aa:	ec06                	sd	ra,24(sp)
ffffffffc02032ac:	e426                	sd	s1,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032ae:	4044                	lw	s1,4(s0)
    memset(name, 0, sizeof(name));
ffffffffc02032b0:	379000ef          	jal	ffffffffc0203e28 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02032b4:	0b440593          	addi	a1,s0,180
ffffffffc02032b8:	463d                	li	a2,15
ffffffffc02032ba:	00006517          	auipc	a0,0x6
ffffffffc02032be:	18e50513          	addi	a0,a0,398 # ffffffffc0209448 <name.2>
ffffffffc02032c2:	379000ef          	jal	ffffffffc0203e3a <memcpy>
ffffffffc02032c6:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032c8:	85a6                	mv	a1,s1
ffffffffc02032ca:	00002517          	auipc	a0,0x2
ffffffffc02032ce:	21650513          	addi	a0,a0,534 # ffffffffc02054e0 <etext+0x166a>
ffffffffc02032d2:	ec3fc0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc02032d6:	85ca                	mv	a1,s2
ffffffffc02032d8:	00002517          	auipc	a0,0x2
ffffffffc02032dc:	23050513          	addi	a0,a0,560 # ffffffffc0205508 <etext+0x1692>
ffffffffc02032e0:	eb5fc0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02032e4:	00002517          	auipc	a0,0x2
ffffffffc02032e8:	23450513          	addi	a0,a0,564 # ffffffffc0205518 <etext+0x16a2>
ffffffffc02032ec:	ea9fc0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02032f0:	60e2                	ld	ra,24(sp)
ffffffffc02032f2:	6442                	ld	s0,16(sp)
ffffffffc02032f4:	64a2                	ld	s1,8(sp)
ffffffffc02032f6:	6902                	ld	s2,0(sp)
ffffffffc02032f8:	4501                	li	a0,0
ffffffffc02032fa:	6105                	addi	sp,sp,32
ffffffffc02032fc:	8082                	ret

ffffffffc02032fe <proc_run>:
    if (proc != current)
ffffffffc02032fe:	0000a717          	auipc	a4,0xa
ffffffffc0203302:	1da73703          	ld	a4,474(a4) # ffffffffc020d4d8 <current>
ffffffffc0203306:	04a70563          	beq	a4,a0,ffffffffc0203350 <proc_run+0x52>
{
ffffffffc020330a:	1101                	addi	sp,sp,-32
ffffffffc020330c:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020330e:	100027f3          	csrr	a5,sstatus
ffffffffc0203312:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203314:	4681                	li	a3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203316:	ef95                	bnez	a5,ffffffffc0203352 <proc_run+0x54>
            lsatp(next->pgdir);
ffffffffc0203318:	755c                	ld	a5,168(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc020331a:	80000637          	lui	a2,0x80000
ffffffffc020331e:	e036                	sd	a3,0(sp)
ffffffffc0203320:	00c7d79b          	srliw	a5,a5,0xc
            current = proc;
ffffffffc0203324:	0000a597          	auipc	a1,0xa
ffffffffc0203328:	1aa5ba23          	sd	a0,436(a1) # ffffffffc020d4d8 <current>
ffffffffc020332c:	8fd1                	or	a5,a5,a2
ffffffffc020332e:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0203332:	03050593          	addi	a1,a0,48
ffffffffc0203336:	03070513          	addi	a0,a4,48
ffffffffc020333a:	528000ef          	jal	ffffffffc0203862 <switch_to>
    if (flag) {
ffffffffc020333e:	6682                	ld	a3,0(sp)
ffffffffc0203340:	e681                	bnez	a3,ffffffffc0203348 <proc_run+0x4a>
}
ffffffffc0203342:	60e2                	ld	ra,24(sp)
ffffffffc0203344:	6105                	addi	sp,sp,32
ffffffffc0203346:	8082                	ret
ffffffffc0203348:	60e2                	ld	ra,24(sp)
ffffffffc020334a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020334c:	d22fd06f          	j	ffffffffc020086e <intr_enable>
ffffffffc0203350:	8082                	ret
ffffffffc0203352:	e42a                	sd	a0,8(sp)
ffffffffc0203354:	e03a                	sd	a4,0(sp)
        intr_disable();
ffffffffc0203356:	d1efd0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc020335a:	6522                	ld	a0,8(sp)
ffffffffc020335c:	6702                	ld	a4,0(sp)
ffffffffc020335e:	4685                	li	a3,1
ffffffffc0203360:	bf65                	j	ffffffffc0203318 <proc_run+0x1a>

ffffffffc0203362 <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc0203362:	0000a717          	auipc	a4,0xa
ffffffffc0203366:	16e72703          	lw	a4,366(a4) # ffffffffc020d4d0 <nr_process>
ffffffffc020336a:	6785                	lui	a5,0x1
ffffffffc020336c:	1cf75e63          	bge	a4,a5,ffffffffc0203548 <do_fork+0x1e6>
{
ffffffffc0203370:	7179                	addi	sp,sp,-48
ffffffffc0203372:	f022                	sd	s0,32(sp)
ffffffffc0203374:	ec26                	sd	s1,24(sp)
ffffffffc0203376:	e84a                	sd	s2,16(sp)
ffffffffc0203378:	f406                	sd	ra,40(sp)
ffffffffc020337a:	892e                	mv	s2,a1
ffffffffc020337c:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL){
ffffffffc020337e:	ea1ff0ef          	jal	ffffffffc020321e <alloc_proc>
ffffffffc0203382:	84aa                	mv	s1,a0
ffffffffc0203384:	1c050063          	beqz	a0,ffffffffc0203544 <do_fork+0x1e2>
ffffffffc0203388:	e44e                	sd	s3,8(sp)
    proc->parent = current;
ffffffffc020338a:	0000a997          	auipc	s3,0xa
ffffffffc020338e:	14e98993          	addi	s3,s3,334 # ffffffffc020d4d8 <current>
ffffffffc0203392:	0009b783          	ld	a5,0(s3)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203396:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0203398:	f09c                	sd	a5,32(s1)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020339a:	8d5fe0ef          	jal	ffffffffc0201c6e <alloc_pages>
    if (page != NULL)
ffffffffc020339e:	18050f63          	beqz	a0,ffffffffc020353c <do_fork+0x1da>
    return page - pages + nbase;
ffffffffc02033a2:	0000a697          	auipc	a3,0xa
ffffffffc02033a6:	1266b683          	ld	a3,294(a3) # ffffffffc020d4c8 <pages>
ffffffffc02033aa:	00002797          	auipc	a5,0x2
ffffffffc02033ae:	61e7b783          	ld	a5,1566(a5) # ffffffffc02059c8 <nbase>
    return KADDR(page2pa(page));
ffffffffc02033b2:	0000a717          	auipc	a4,0xa
ffffffffc02033b6:	10e73703          	ld	a4,270(a4) # ffffffffc020d4c0 <npage>
    return page - pages + nbase;
ffffffffc02033ba:	40d506b3          	sub	a3,a0,a3
ffffffffc02033be:	8699                	srai	a3,a3,0x6
ffffffffc02033c0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02033c2:	00c69793          	slli	a5,a3,0xc
ffffffffc02033c6:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02033c8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033ca:	1ae7f163          	bgeu	a5,a4,ffffffffc020356c <do_fork+0x20a>
    assert(current->mm == NULL);
ffffffffc02033ce:	0009b783          	ld	a5,0(s3)
ffffffffc02033d2:	0000a717          	auipc	a4,0xa
ffffffffc02033d6:	0e673703          	ld	a4,230(a4) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc02033da:	779c                	ld	a5,40(a5)
ffffffffc02033dc:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02033de:	e894                	sd	a3,16(s1)
    assert(current->mm == NULL);
ffffffffc02033e0:	16079663          	bnez	a5,ffffffffc020354c <do_fork+0x1ea>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033e4:	6789                	lui	a5,0x2
ffffffffc02033e6:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc02033ea:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02033ec:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033ee:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc02033f0:	87b6                	mv	a5,a3
ffffffffc02033f2:	12040713          	addi	a4,s0,288
ffffffffc02033f6:	6a0c                	ld	a1,16(a2)
ffffffffc02033f8:	00063803          	ld	a6,0(a2) # ffffffff80000000 <kern_entry-0x40200000>
ffffffffc02033fc:	6608                	ld	a0,8(a2)
ffffffffc02033fe:	eb8c                	sd	a1,16(a5)
ffffffffc0203400:	0107b023          	sd	a6,0(a5)
ffffffffc0203404:	e788                	sd	a0,8(a5)
ffffffffc0203406:	6e0c                	ld	a1,24(a2)
ffffffffc0203408:	02060613          	addi	a2,a2,32
ffffffffc020340c:	02078793          	addi	a5,a5,32
ffffffffc0203410:	feb7bc23          	sd	a1,-8(a5)
ffffffffc0203414:	fee611e3          	bne	a2,a4,ffffffffc02033f6 <do_fork+0x94>
    proc->tf->gpr.a0 = 0;
ffffffffc0203418:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020341c:	10090263          	beqz	s2,ffffffffc0203520 <do_fork+0x1be>
    if (++last_pid >= MAX_PID)
ffffffffc0203420:	00006517          	auipc	a0,0x6
ffffffffc0203424:	c0c52503          	lw	a0,-1012(a0) # ffffffffc020902c <last_pid.1>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203428:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020342c:	00000797          	auipc	a5,0x0
ffffffffc0203430:	e5478793          	addi	a5,a5,-428 # ffffffffc0203280 <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc0203434:	2505                	addiw	a0,a0,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203436:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203438:	fc94                	sd	a3,56(s1)
    if (++last_pid >= MAX_PID)
ffffffffc020343a:	00006717          	auipc	a4,0x6
ffffffffc020343e:	bea72923          	sw	a0,-1038(a4) # ffffffffc020902c <last_pid.1>
ffffffffc0203442:	6789                	lui	a5,0x2
ffffffffc0203444:	0ef55063          	bge	a0,a5,ffffffffc0203524 <do_fork+0x1c2>
    if (last_pid >= next_safe)
ffffffffc0203448:	00006797          	auipc	a5,0x6
ffffffffc020344c:	be07a783          	lw	a5,-1056(a5) # ffffffffc0209028 <next_safe.0>
ffffffffc0203450:	0000a417          	auipc	s0,0xa
ffffffffc0203454:	00840413          	addi	s0,s0,8 # ffffffffc020d458 <proc_list>
ffffffffc0203458:	06f54563          	blt	a0,a5,ffffffffc02034c2 <do_fork+0x160>
ffffffffc020345c:	0000a417          	auipc	s0,0xa
ffffffffc0203460:	ffc40413          	addi	s0,s0,-4 # ffffffffc020d458 <proc_list>
ffffffffc0203464:	00843883          	ld	a7,8(s0)
        next_safe = MAX_PID;
ffffffffc0203468:	6789                	lui	a5,0x2
ffffffffc020346a:	00006717          	auipc	a4,0x6
ffffffffc020346e:	baf72f23          	sw	a5,-1090(a4) # ffffffffc0209028 <next_safe.0>
ffffffffc0203472:	86aa                	mv	a3,a0
ffffffffc0203474:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0203476:	04888063          	beq	a7,s0,ffffffffc02034b6 <do_fork+0x154>
ffffffffc020347a:	882e                	mv	a6,a1
ffffffffc020347c:	87c6                	mv	a5,a7
ffffffffc020347e:	6609                	lui	a2,0x2
ffffffffc0203480:	a811                	j	ffffffffc0203494 <do_fork+0x132>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203482:	00e6d663          	bge	a3,a4,ffffffffc020348e <do_fork+0x12c>
ffffffffc0203486:	00c75463          	bge	a4,a2,ffffffffc020348e <do_fork+0x12c>
                next_safe = proc->pid;
ffffffffc020348a:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020348c:	4805                	li	a6,1
ffffffffc020348e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203490:	00878d63          	beq	a5,s0,ffffffffc02034aa <do_fork+0x148>
            if (proc->pid == last_pid)
ffffffffc0203494:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc0203498:	fed715e3          	bne	a4,a3,ffffffffc0203482 <do_fork+0x120>
                if (++last_pid >= next_safe)
ffffffffc020349c:	2685                	addiw	a3,a3,1
ffffffffc020349e:	08c6d963          	bge	a3,a2,ffffffffc0203530 <do_fork+0x1ce>
ffffffffc02034a2:	679c                	ld	a5,8(a5)
ffffffffc02034a4:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02034a6:	fe8797e3          	bne	a5,s0,ffffffffc0203494 <do_fork+0x132>
ffffffffc02034aa:	00080663          	beqz	a6,ffffffffc02034b6 <do_fork+0x154>
ffffffffc02034ae:	00006797          	auipc	a5,0x6
ffffffffc02034b2:	b6c7ad23          	sw	a2,-1158(a5) # ffffffffc0209028 <next_safe.0>
ffffffffc02034b6:	c591                	beqz	a1,ffffffffc02034c2 <do_fork+0x160>
ffffffffc02034b8:	00006797          	auipc	a5,0x6
ffffffffc02034bc:	b6d7aa23          	sw	a3,-1164(a5) # ffffffffc020902c <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02034c0:	8536                	mv	a0,a3
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02034c2:	45a9                	li	a1,10
    proc->pid = get_pid();    
ffffffffc02034c4:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02034c6:	4cc000ef          	jal	ffffffffc0203992 <hash32>
ffffffffc02034ca:	02051793          	slli	a5,a0,0x20
ffffffffc02034ce:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02034d2:	00006797          	auipc	a5,0x6
ffffffffc02034d6:	f8678793          	addi	a5,a5,-122 # ffffffffc0209458 <hash_list>
ffffffffc02034da:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02034dc:	6518                	ld	a4,8(a0)
ffffffffc02034de:	0d848793          	addi	a5,s1,216
ffffffffc02034e2:	6414                	ld	a3,8(s0)
    prev->next = next->prev = elm;
ffffffffc02034e4:	e31c                	sd	a5,0(a4)
ffffffffc02034e6:	e51c                	sd	a5,8(a0)
    nr_process++;
ffffffffc02034e8:	0000a797          	auipc	a5,0xa
ffffffffc02034ec:	fe87a783          	lw	a5,-24(a5) # ffffffffc020d4d0 <nr_process>
    elm->next = next;
ffffffffc02034f0:	f0f8                	sd	a4,224(s1)
    elm->prev = prev;
ffffffffc02034f2:	ece8                	sd	a0,216(s1)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02034f4:	0c848713          	addi	a4,s1,200
    prev->next = next->prev = elm;
ffffffffc02034f8:	e298                	sd	a4,0(a3)
    wakeup_proc(proc);
ffffffffc02034fa:	8526                	mv	a0,s1
    nr_process++;
ffffffffc02034fc:	2785                	addiw	a5,a5,1
    elm->next = next;
ffffffffc02034fe:	e8f4                	sd	a3,208(s1)
    elm->prev = prev;
ffffffffc0203500:	e4e0                	sd	s0,200(s1)
    prev->next = next->prev = elm;
ffffffffc0203502:	e418                	sd	a4,8(s0)
ffffffffc0203504:	0000a717          	auipc	a4,0xa
ffffffffc0203508:	fcf72623          	sw	a5,-52(a4) # ffffffffc020d4d0 <nr_process>
    wakeup_proc(proc);
ffffffffc020350c:	3c0000ef          	jal	ffffffffc02038cc <wakeup_proc>
    ret = proc->pid;
ffffffffc0203510:	40c8                	lw	a0,4(s1)
ffffffffc0203512:	69a2                	ld	s3,8(sp)
}
ffffffffc0203514:	70a2                	ld	ra,40(sp)
ffffffffc0203516:	7402                	ld	s0,32(sp)
ffffffffc0203518:	64e2                	ld	s1,24(sp)
ffffffffc020351a:	6942                	ld	s2,16(sp)
ffffffffc020351c:	6145                	addi	sp,sp,48
ffffffffc020351e:	8082                	ret
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203520:	8936                	mv	s2,a3
ffffffffc0203522:	bdfd                	j	ffffffffc0203420 <do_fork+0xbe>
        last_pid = 1;
ffffffffc0203524:	4505                	li	a0,1
ffffffffc0203526:	00006797          	auipc	a5,0x6
ffffffffc020352a:	b0a7a323          	sw	a0,-1274(a5) # ffffffffc020902c <last_pid.1>
        goto inside;
ffffffffc020352e:	b73d                	j	ffffffffc020345c <do_fork+0xfa>
                    if (last_pid >= MAX_PID)
ffffffffc0203530:	6789                	lui	a5,0x2
ffffffffc0203532:	00f6c363          	blt	a3,a5,ffffffffc0203538 <do_fork+0x1d6>
                        last_pid = 1;
ffffffffc0203536:	4685                	li	a3,1
                    goto repeat;
ffffffffc0203538:	4585                	li	a1,1
ffffffffc020353a:	bf35                	j	ffffffffc0203476 <do_fork+0x114>
    kfree(proc);
ffffffffc020353c:	8526                	mv	a0,s1
ffffffffc020353e:	e14fe0ef          	jal	ffffffffc0201b52 <kfree>
ffffffffc0203542:	69a2                	ld	s3,8(sp)
    ret = -E_NO_MEM;
ffffffffc0203544:	5571                	li	a0,-4
ffffffffc0203546:	b7f9                	j	ffffffffc0203514 <do_fork+0x1b2>
    int ret = -E_NO_FREE_PROC;
ffffffffc0203548:	556d                	li	a0,-5
}
ffffffffc020354a:	8082                	ret
    assert(current->mm == NULL);
ffffffffc020354c:	00002697          	auipc	a3,0x2
ffffffffc0203550:	fec68693          	addi	a3,a3,-20 # ffffffffc0205538 <etext+0x16c2>
ffffffffc0203554:	00001617          	auipc	a2,0x1
ffffffffc0203558:	2f460613          	addi	a2,a2,756 # ffffffffc0204848 <etext+0x9d2>
ffffffffc020355c:	13300593          	li	a1,307
ffffffffc0203560:	00002517          	auipc	a0,0x2
ffffffffc0203564:	ff050513          	addi	a0,a0,-16 # ffffffffc0205550 <etext+0x16da>
ffffffffc0203568:	e9ffc0ef          	jal	ffffffffc0200406 <__panic>
ffffffffc020356c:	00001617          	auipc	a2,0x1
ffffffffc0203570:	68c60613          	addi	a2,a2,1676 # ffffffffc0204bf8 <etext+0xd82>
ffffffffc0203574:	07100593          	li	a1,113
ffffffffc0203578:	00001517          	auipc	a0,0x1
ffffffffc020357c:	6a850513          	addi	a0,a0,1704 # ffffffffc0204c20 <etext+0xdaa>
ffffffffc0203580:	e87fc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0203584 <kernel_thread>:
{
ffffffffc0203584:	7129                	addi	sp,sp,-320
ffffffffc0203586:	fa22                	sd	s0,304(sp)
ffffffffc0203588:	f626                	sd	s1,296(sp)
ffffffffc020358a:	f24a                	sd	s2,288(sp)
ffffffffc020358c:	842a                	mv	s0,a0
ffffffffc020358e:	84ae                	mv	s1,a1
ffffffffc0203590:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203592:	850a                	mv	a0,sp
ffffffffc0203594:	12000613          	li	a2,288
ffffffffc0203598:	4581                	li	a1,0
{
ffffffffc020359a:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020359c:	08d000ef          	jal	ffffffffc0203e28 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02035a0:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02035a2:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02035a4:	100027f3          	csrr	a5,sstatus
ffffffffc02035a8:	edd7f793          	andi	a5,a5,-291
ffffffffc02035ac:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035b0:	860a                	mv	a2,sp
ffffffffc02035b2:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02035b6:	00000717          	auipc	a4,0x0
ffffffffc02035ba:	c6070713          	addi	a4,a4,-928 # ffffffffc0203216 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035be:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02035c0:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02035c2:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035c4:	d9fff0ef          	jal	ffffffffc0203362 <do_fork>
}
ffffffffc02035c8:	70f2                	ld	ra,312(sp)
ffffffffc02035ca:	7452                	ld	s0,304(sp)
ffffffffc02035cc:	74b2                	ld	s1,296(sp)
ffffffffc02035ce:	7912                	ld	s2,288(sp)
ffffffffc02035d0:	6131                	addi	sp,sp,320
ffffffffc02035d2:	8082                	ret

ffffffffc02035d4 <do_exit>:
{
ffffffffc02035d4:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc02035d6:	00002617          	auipc	a2,0x2
ffffffffc02035da:	f9260613          	addi	a2,a2,-110 # ffffffffc0205568 <etext+0x16f2>
ffffffffc02035de:	19100593          	li	a1,401
ffffffffc02035e2:	00002517          	auipc	a0,0x2
ffffffffc02035e6:	f6e50513          	addi	a0,a0,-146 # ffffffffc0205550 <etext+0x16da>
{
ffffffffc02035ea:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc02035ec:	e1bfc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc02035f0 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc02035f0:	7179                	addi	sp,sp,-48
ffffffffc02035f2:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc02035f4:	0000a797          	auipc	a5,0xa
ffffffffc02035f8:	e6478793          	addi	a5,a5,-412 # ffffffffc020d458 <proc_list>
ffffffffc02035fc:	f406                	sd	ra,40(sp)
ffffffffc02035fe:	f022                	sd	s0,32(sp)
ffffffffc0203600:	e84a                	sd	s2,16(sp)
ffffffffc0203602:	e44e                	sd	s3,8(sp)
ffffffffc0203604:	00006497          	auipc	s1,0x6
ffffffffc0203608:	e5448493          	addi	s1,s1,-428 # ffffffffc0209458 <hash_list>
ffffffffc020360c:	e79c                	sd	a5,8(a5)
ffffffffc020360e:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0203610:	0000a717          	auipc	a4,0xa
ffffffffc0203614:	e4870713          	addi	a4,a4,-440 # ffffffffc020d458 <proc_list>
ffffffffc0203618:	87a6                	mv	a5,s1
ffffffffc020361a:	e79c                	sd	a5,8(a5)
ffffffffc020361c:	e39c                	sd	a5,0(a5)
ffffffffc020361e:	07c1                	addi	a5,a5,16
ffffffffc0203620:	fee79de3          	bne	a5,a4,ffffffffc020361a <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0203624:	bfbff0ef          	jal	ffffffffc020321e <alloc_proc>
ffffffffc0203628:	0000a917          	auipc	s2,0xa
ffffffffc020362c:	ec090913          	addi	s2,s2,-320 # ffffffffc020d4e8 <idleproc>
ffffffffc0203630:	00a93023          	sd	a0,0(s2)
ffffffffc0203634:	1a050263          	beqz	a0,ffffffffc02037d8 <proc_init+0x1e8>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203638:	07000513          	li	a0,112
ffffffffc020363c:	c70fe0ef          	jal	ffffffffc0201aac <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203640:	07000613          	li	a2,112
ffffffffc0203644:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203646:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203648:	7e0000ef          	jal	ffffffffc0203e28 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc020364c:	00093503          	ld	a0,0(s2)
ffffffffc0203650:	85a2                	mv	a1,s0
ffffffffc0203652:	07000613          	li	a2,112
ffffffffc0203656:	03050513          	addi	a0,a0,48
ffffffffc020365a:	7f8000ef          	jal	ffffffffc0203e52 <memcmp>
ffffffffc020365e:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203660:	453d                	li	a0,15
ffffffffc0203662:	c4afe0ef          	jal	ffffffffc0201aac <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0203666:	463d                	li	a2,15
ffffffffc0203668:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc020366a:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020366c:	7bc000ef          	jal	ffffffffc0203e28 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc0203670:	00093503          	ld	a0,0(s2)
ffffffffc0203674:	85a2                	mv	a1,s0
ffffffffc0203676:	463d                	li	a2,15
ffffffffc0203678:	0b450513          	addi	a0,a0,180
ffffffffc020367c:	7d6000ef          	jal	ffffffffc0203e52 <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203680:	00093783          	ld	a5,0(s2)
ffffffffc0203684:	0000a717          	auipc	a4,0xa
ffffffffc0203688:	e2473703          	ld	a4,-476(a4) # ffffffffc020d4a8 <boot_pgdir_pa>
ffffffffc020368c:	77d4                	ld	a3,168(a5)
ffffffffc020368e:	0ee68863          	beq	a3,a4,ffffffffc020377e <proc_init+0x18e>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0203692:	4709                	li	a4,2
ffffffffc0203694:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0203696:	00003717          	auipc	a4,0x3
ffffffffc020369a:	96a70713          	addi	a4,a4,-1686 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020369e:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036a2:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc02036a4:	4705                	li	a4,1
ffffffffc02036a6:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036a8:	8522                	mv	a0,s0
ffffffffc02036aa:	4641                	li	a2,16
ffffffffc02036ac:	4581                	li	a1,0
ffffffffc02036ae:	77a000ef          	jal	ffffffffc0203e28 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02036b2:	8522                	mv	a0,s0
ffffffffc02036b4:	463d                	li	a2,15
ffffffffc02036b6:	00002597          	auipc	a1,0x2
ffffffffc02036ba:	efa58593          	addi	a1,a1,-262 # ffffffffc02055b0 <etext+0x173a>
ffffffffc02036be:	77c000ef          	jal	ffffffffc0203e3a <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc02036c2:	0000a797          	auipc	a5,0xa
ffffffffc02036c6:	e0e7a783          	lw	a5,-498(a5) # ffffffffc020d4d0 <nr_process>

    current = idleproc;
ffffffffc02036ca:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036ce:	4601                	li	a2,0
    nr_process++;
ffffffffc02036d0:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036d2:	00002597          	auipc	a1,0x2
ffffffffc02036d6:	ee658593          	addi	a1,a1,-282 # ffffffffc02055b8 <etext+0x1742>
ffffffffc02036da:	00000517          	auipc	a0,0x0
ffffffffc02036de:	bb450513          	addi	a0,a0,-1100 # ffffffffc020328e <init_main>
    current = idleproc;
ffffffffc02036e2:	0000a697          	auipc	a3,0xa
ffffffffc02036e6:	dee6bb23          	sd	a4,-522(a3) # ffffffffc020d4d8 <current>
    nr_process++;
ffffffffc02036ea:	0000a717          	auipc	a4,0xa
ffffffffc02036ee:	def72323          	sw	a5,-538(a4) # ffffffffc020d4d0 <nr_process>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036f2:	e93ff0ef          	jal	ffffffffc0203584 <kernel_thread>
ffffffffc02036f6:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc02036f8:	0ea05c63          	blez	a0,ffffffffc02037f0 <proc_init+0x200>
    if (0 < pid && pid < MAX_PID)
ffffffffc02036fc:	6789                	lui	a5,0x2
ffffffffc02036fe:	17f9                	addi	a5,a5,-2 # 1ffe <kern_entry-0xffffffffc01fe002>
ffffffffc0203700:	fff5071b          	addiw	a4,a0,-1
ffffffffc0203704:	02e7e463          	bltu	a5,a4,ffffffffc020372c <proc_init+0x13c>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0203708:	45a9                	li	a1,10
ffffffffc020370a:	288000ef          	jal	ffffffffc0203992 <hash32>
ffffffffc020370e:	02051713          	slli	a4,a0,0x20
ffffffffc0203712:	01c75793          	srli	a5,a4,0x1c
ffffffffc0203716:	00f486b3          	add	a3,s1,a5
ffffffffc020371a:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020371c:	a029                	j	ffffffffc0203726 <proc_init+0x136>
            if (proc->pid == pid)
ffffffffc020371e:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0203722:	0a870863          	beq	a4,s0,ffffffffc02037d2 <proc_init+0x1e2>
    return listelm->next;
ffffffffc0203726:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203728:	fef69be3          	bne	a3,a5,ffffffffc020371e <proc_init+0x12e>
    return NULL;
ffffffffc020372c:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020372e:	0b478413          	addi	s0,a5,180
ffffffffc0203732:	4641                	li	a2,16
ffffffffc0203734:	4581                	li	a1,0
ffffffffc0203736:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0203738:	0000a717          	auipc	a4,0xa
ffffffffc020373c:	daf73423          	sd	a5,-600(a4) # ffffffffc020d4e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203740:	6e8000ef          	jal	ffffffffc0203e28 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203744:	8522                	mv	a0,s0
ffffffffc0203746:	463d                	li	a2,15
ffffffffc0203748:	00002597          	auipc	a1,0x2
ffffffffc020374c:	ea058593          	addi	a1,a1,-352 # ffffffffc02055e8 <etext+0x1772>
ffffffffc0203750:	6ea000ef          	jal	ffffffffc0203e3a <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203754:	00093783          	ld	a5,0(s2)
ffffffffc0203758:	cbe1                	beqz	a5,ffffffffc0203828 <proc_init+0x238>
ffffffffc020375a:	43dc                	lw	a5,4(a5)
ffffffffc020375c:	e7f1                	bnez	a5,ffffffffc0203828 <proc_init+0x238>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020375e:	0000a797          	auipc	a5,0xa
ffffffffc0203762:	d827b783          	ld	a5,-638(a5) # ffffffffc020d4e0 <initproc>
ffffffffc0203766:	c3cd                	beqz	a5,ffffffffc0203808 <proc_init+0x218>
ffffffffc0203768:	43d8                	lw	a4,4(a5)
ffffffffc020376a:	4785                	li	a5,1
ffffffffc020376c:	08f71e63          	bne	a4,a5,ffffffffc0203808 <proc_init+0x218>
}
ffffffffc0203770:	70a2                	ld	ra,40(sp)
ffffffffc0203772:	7402                	ld	s0,32(sp)
ffffffffc0203774:	64e2                	ld	s1,24(sp)
ffffffffc0203776:	6942                	ld	s2,16(sp)
ffffffffc0203778:	69a2                	ld	s3,8(sp)
ffffffffc020377a:	6145                	addi	sp,sp,48
ffffffffc020377c:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc020377e:	73d8                	ld	a4,160(a5)
ffffffffc0203780:	f00719e3          	bnez	a4,ffffffffc0203692 <proc_init+0xa2>
ffffffffc0203784:	f00997e3          	bnez	s3,ffffffffc0203692 <proc_init+0xa2>
ffffffffc0203788:	4398                	lw	a4,0(a5)
ffffffffc020378a:	f00714e3          	bnez	a4,ffffffffc0203692 <proc_init+0xa2>
ffffffffc020378e:	43d4                	lw	a3,4(a5)
ffffffffc0203790:	577d                	li	a4,-1
ffffffffc0203792:	f0e690e3          	bne	a3,a4,ffffffffc0203692 <proc_init+0xa2>
ffffffffc0203796:	4798                	lw	a4,8(a5)
ffffffffc0203798:	ee071de3          	bnez	a4,ffffffffc0203692 <proc_init+0xa2>
ffffffffc020379c:	6b98                	ld	a4,16(a5)
ffffffffc020379e:	ee071ae3          	bnez	a4,ffffffffc0203692 <proc_init+0xa2>
ffffffffc02037a2:	4f98                	lw	a4,24(a5)
ffffffffc02037a4:	ee0717e3          	bnez	a4,ffffffffc0203692 <proc_init+0xa2>
ffffffffc02037a8:	7398                	ld	a4,32(a5)
ffffffffc02037aa:	ee0714e3          	bnez	a4,ffffffffc0203692 <proc_init+0xa2>
ffffffffc02037ae:	7798                	ld	a4,40(a5)
ffffffffc02037b0:	ee0711e3          	bnez	a4,ffffffffc0203692 <proc_init+0xa2>
ffffffffc02037b4:	0b07a703          	lw	a4,176(a5)
ffffffffc02037b8:	8f49                	or	a4,a4,a0
ffffffffc02037ba:	2701                	sext.w	a4,a4
ffffffffc02037bc:	ec071be3          	bnez	a4,ffffffffc0203692 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc02037c0:	00002517          	auipc	a0,0x2
ffffffffc02037c4:	dd850513          	addi	a0,a0,-552 # ffffffffc0205598 <etext+0x1722>
ffffffffc02037c8:	9cdfc0ef          	jal	ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc02037cc:	00093783          	ld	a5,0(s2)
ffffffffc02037d0:	b5c9                	j	ffffffffc0203692 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02037d2:	f2878793          	addi	a5,a5,-216
ffffffffc02037d6:	bfa1                	j	ffffffffc020372e <proc_init+0x13e>
        panic("cannot alloc idleproc.\n");
ffffffffc02037d8:	00002617          	auipc	a2,0x2
ffffffffc02037dc:	da860613          	addi	a2,a2,-600 # ffffffffc0205580 <etext+0x170a>
ffffffffc02037e0:	1ac00593          	li	a1,428
ffffffffc02037e4:	00002517          	auipc	a0,0x2
ffffffffc02037e8:	d6c50513          	addi	a0,a0,-660 # ffffffffc0205550 <etext+0x16da>
ffffffffc02037ec:	c1bfc0ef          	jal	ffffffffc0200406 <__panic>
        panic("create init_main failed.\n");
ffffffffc02037f0:	00002617          	auipc	a2,0x2
ffffffffc02037f4:	dd860613          	addi	a2,a2,-552 # ffffffffc02055c8 <etext+0x1752>
ffffffffc02037f8:	1c900593          	li	a1,457
ffffffffc02037fc:	00002517          	auipc	a0,0x2
ffffffffc0203800:	d5450513          	addi	a0,a0,-684 # ffffffffc0205550 <etext+0x16da>
ffffffffc0203804:	c03fc0ef          	jal	ffffffffc0200406 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203808:	00002697          	auipc	a3,0x2
ffffffffc020380c:	e1068693          	addi	a3,a3,-496 # ffffffffc0205618 <etext+0x17a2>
ffffffffc0203810:	00001617          	auipc	a2,0x1
ffffffffc0203814:	03860613          	addi	a2,a2,56 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0203818:	1d000593          	li	a1,464
ffffffffc020381c:	00002517          	auipc	a0,0x2
ffffffffc0203820:	d3450513          	addi	a0,a0,-716 # ffffffffc0205550 <etext+0x16da>
ffffffffc0203824:	be3fc0ef          	jal	ffffffffc0200406 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203828:	00002697          	auipc	a3,0x2
ffffffffc020382c:	dc868693          	addi	a3,a3,-568 # ffffffffc02055f0 <etext+0x177a>
ffffffffc0203830:	00001617          	auipc	a2,0x1
ffffffffc0203834:	01860613          	addi	a2,a2,24 # ffffffffc0204848 <etext+0x9d2>
ffffffffc0203838:	1cf00593          	li	a1,463
ffffffffc020383c:	00002517          	auipc	a0,0x2
ffffffffc0203840:	d1450513          	addi	a0,a0,-748 # ffffffffc0205550 <etext+0x16da>
ffffffffc0203844:	bc3fc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0203848 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0203848:	1141                	addi	sp,sp,-16
ffffffffc020384a:	e022                	sd	s0,0(sp)
ffffffffc020384c:	e406                	sd	ra,8(sp)
ffffffffc020384e:	0000a417          	auipc	s0,0xa
ffffffffc0203852:	c8a40413          	addi	s0,s0,-886 # ffffffffc020d4d8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0203856:	6018                	ld	a4,0(s0)
ffffffffc0203858:	4f1c                	lw	a5,24(a4)
ffffffffc020385a:	dffd                	beqz	a5,ffffffffc0203858 <cpu_idle+0x10>
        {
            schedule();
ffffffffc020385c:	0a2000ef          	jal	ffffffffc02038fe <schedule>
ffffffffc0203860:	bfdd                	j	ffffffffc0203856 <cpu_idle+0xe>

ffffffffc0203862 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0203862:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0203866:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020386a:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020386c:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020386e:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0203872:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0203876:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020387a:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020387e:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0203882:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0203886:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc020388a:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020388e:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0203892:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0203896:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020389a:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020389e:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02038a0:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02038a2:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02038a6:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02038aa:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02038ae:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02038b2:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02038b6:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02038ba:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02038be:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02038c2:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02038c6:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02038ca:	8082                	ret

ffffffffc02038cc <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038cc:	411c                	lw	a5,0(a0)
ffffffffc02038ce:	4705                	li	a4,1
ffffffffc02038d0:	37f9                	addiw	a5,a5,-2
ffffffffc02038d2:	00f77563          	bgeu	a4,a5,ffffffffc02038dc <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc02038d6:	4789                	li	a5,2
ffffffffc02038d8:	c11c                	sw	a5,0(a0)
ffffffffc02038da:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc02038dc:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038de:	00002697          	auipc	a3,0x2
ffffffffc02038e2:	d6268693          	addi	a3,a3,-670 # ffffffffc0205640 <etext+0x17ca>
ffffffffc02038e6:	00001617          	auipc	a2,0x1
ffffffffc02038ea:	f6260613          	addi	a2,a2,-158 # ffffffffc0204848 <etext+0x9d2>
ffffffffc02038ee:	45a5                	li	a1,9
ffffffffc02038f0:	00002517          	auipc	a0,0x2
ffffffffc02038f4:	d9050513          	addi	a0,a0,-624 # ffffffffc0205680 <etext+0x180a>
wakeup_proc(struct proc_struct *proc) {
ffffffffc02038f8:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038fa:	b0dfc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc02038fe <schedule>:
}

void
schedule(void) {
ffffffffc02038fe:	1101                	addi	sp,sp,-32
ffffffffc0203900:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203902:	100027f3          	csrr	a5,sstatus
ffffffffc0203906:	8b89                	andi	a5,a5,2
ffffffffc0203908:	4301                	li	t1,0
ffffffffc020390a:	e3c1                	bnez	a5,ffffffffc020398a <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020390c:	0000a897          	auipc	a7,0xa
ffffffffc0203910:	bcc8b883          	ld	a7,-1076(a7) # ffffffffc020d4d8 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203914:	0000a517          	auipc	a0,0xa
ffffffffc0203918:	bd453503          	ld	a0,-1068(a0) # ffffffffc020d4e8 <idleproc>
        current->need_resched = 0;
ffffffffc020391c:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203920:	04a88f63          	beq	a7,a0,ffffffffc020397e <schedule+0x80>
ffffffffc0203924:	0c888693          	addi	a3,a7,200
ffffffffc0203928:	0000a617          	auipc	a2,0xa
ffffffffc020392c:	b3060613          	addi	a2,a2,-1232 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc0203930:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0203932:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203934:	4809                	li	a6,2
ffffffffc0203936:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0203938:	00c78863          	beq	a5,a2,ffffffffc0203948 <schedule+0x4a>
                if (next->state == PROC_RUNNABLE) {
ffffffffc020393c:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0203940:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203944:	03070363          	beq	a4,a6,ffffffffc020396a <schedule+0x6c>
                    break;
                }
            }
        } while (le != last);
ffffffffc0203948:	fef697e3          	bne	a3,a5,ffffffffc0203936 <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc020394c:	ed99                	bnez	a1,ffffffffc020396a <schedule+0x6c>
            next = idleproc;
        }
        next->runs ++;
ffffffffc020394e:	451c                	lw	a5,8(a0)
ffffffffc0203950:	2785                	addiw	a5,a5,1
ffffffffc0203952:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0203954:	00a88663          	beq	a7,a0,ffffffffc0203960 <schedule+0x62>
ffffffffc0203958:	e41a                	sd	t1,8(sp)
            proc_run(next);
ffffffffc020395a:	9a5ff0ef          	jal	ffffffffc02032fe <proc_run>
ffffffffc020395e:	6322                	ld	t1,8(sp)
    if (flag) {
ffffffffc0203960:	00031b63          	bnez	t1,ffffffffc0203976 <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0203964:	60e2                	ld	ra,24(sp)
ffffffffc0203966:	6105                	addi	sp,sp,32
ffffffffc0203968:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc020396a:	4198                	lw	a4,0(a1)
ffffffffc020396c:	4789                	li	a5,2
ffffffffc020396e:	fef710e3          	bne	a4,a5,ffffffffc020394e <schedule+0x50>
ffffffffc0203972:	852e                	mv	a0,a1
ffffffffc0203974:	bfe9                	j	ffffffffc020394e <schedule+0x50>
}
ffffffffc0203976:	60e2                	ld	ra,24(sp)
ffffffffc0203978:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020397a:	ef5fc06f          	j	ffffffffc020086e <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020397e:	0000a617          	auipc	a2,0xa
ffffffffc0203982:	ada60613          	addi	a2,a2,-1318 # ffffffffc020d458 <proc_list>
ffffffffc0203986:	86b2                	mv	a3,a2
ffffffffc0203988:	b765                	j	ffffffffc0203930 <schedule+0x32>
        intr_disable();
ffffffffc020398a:	eebfc0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc020398e:	4305                	li	t1,1
ffffffffc0203990:	bfb5                	j	ffffffffc020390c <schedule+0xe>

ffffffffc0203992 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0203992:	9e3707b7          	lui	a5,0x9e370
ffffffffc0203996:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <kern_entry-0x21e8ffff>
ffffffffc0203998:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc020399c:	02000513          	li	a0,32
ffffffffc02039a0:	9d0d                	subw	a0,a0,a1
}
ffffffffc02039a2:	00a7d53b          	srlw	a0,a5,a0
ffffffffc02039a6:	8082                	ret

ffffffffc02039a8 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039a8:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02039aa:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039ae:	f022                	sd	s0,32(sp)
ffffffffc02039b0:	ec26                	sd	s1,24(sp)
ffffffffc02039b2:	e84a                	sd	s2,16(sp)
ffffffffc02039b4:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02039b6:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039ba:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02039bc:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02039c0:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039c4:	84aa                	mv	s1,a0
ffffffffc02039c6:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc02039c8:	03067d63          	bgeu	a2,a6,ffffffffc0203a02 <printnum+0x5a>
ffffffffc02039cc:	e44e                	sd	s3,8(sp)
ffffffffc02039ce:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02039d0:	4785                	li	a5,1
ffffffffc02039d2:	00e7d763          	bge	a5,a4,ffffffffc02039e0 <printnum+0x38>
            putch(padc, putdat);
ffffffffc02039d6:	85ca                	mv	a1,s2
ffffffffc02039d8:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02039da:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02039dc:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02039de:	fc65                	bnez	s0,ffffffffc02039d6 <printnum+0x2e>
ffffffffc02039e0:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039e2:	00002797          	auipc	a5,0x2
ffffffffc02039e6:	cb678793          	addi	a5,a5,-842 # ffffffffc0205698 <etext+0x1822>
ffffffffc02039ea:	97d2                	add	a5,a5,s4
}
ffffffffc02039ec:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039ee:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02039f2:	70a2                	ld	ra,40(sp)
ffffffffc02039f4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039f6:	85ca                	mv	a1,s2
ffffffffc02039f8:	87a6                	mv	a5,s1
}
ffffffffc02039fa:	6942                	ld	s2,16(sp)
ffffffffc02039fc:	64e2                	ld	s1,24(sp)
ffffffffc02039fe:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a00:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203a02:	03065633          	divu	a2,a2,a6
ffffffffc0203a06:	8722                	mv	a4,s0
ffffffffc0203a08:	fa1ff0ef          	jal	ffffffffc02039a8 <printnum>
ffffffffc0203a0c:	bfd9                	j	ffffffffc02039e2 <printnum+0x3a>

ffffffffc0203a0e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203a0e:	7119                	addi	sp,sp,-128
ffffffffc0203a10:	f4a6                	sd	s1,104(sp)
ffffffffc0203a12:	f0ca                	sd	s2,96(sp)
ffffffffc0203a14:	ecce                	sd	s3,88(sp)
ffffffffc0203a16:	e8d2                	sd	s4,80(sp)
ffffffffc0203a18:	e4d6                	sd	s5,72(sp)
ffffffffc0203a1a:	e0da                	sd	s6,64(sp)
ffffffffc0203a1c:	f862                	sd	s8,48(sp)
ffffffffc0203a1e:	fc86                	sd	ra,120(sp)
ffffffffc0203a20:	f8a2                	sd	s0,112(sp)
ffffffffc0203a22:	fc5e                	sd	s7,56(sp)
ffffffffc0203a24:	f466                	sd	s9,40(sp)
ffffffffc0203a26:	f06a                	sd	s10,32(sp)
ffffffffc0203a28:	ec6e                	sd	s11,24(sp)
ffffffffc0203a2a:	84aa                	mv	s1,a0
ffffffffc0203a2c:	8c32                	mv	s8,a2
ffffffffc0203a2e:	8a36                	mv	s4,a3
ffffffffc0203a30:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a32:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a36:	05500b13          	li	s6,85
ffffffffc0203a3a:	00002a97          	auipc	s5,0x2
ffffffffc0203a3e:	dfea8a93          	addi	s5,s5,-514 # ffffffffc0205838 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a42:	000c4503          	lbu	a0,0(s8)
ffffffffc0203a46:	001c0413          	addi	s0,s8,1
ffffffffc0203a4a:	01350a63          	beq	a0,s3,ffffffffc0203a5e <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0203a4e:	cd0d                	beqz	a0,ffffffffc0203a88 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0203a50:	85ca                	mv	a1,s2
ffffffffc0203a52:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a54:	00044503          	lbu	a0,0(s0)
ffffffffc0203a58:	0405                	addi	s0,s0,1
ffffffffc0203a5a:	ff351ae3          	bne	a0,s3,ffffffffc0203a4e <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0203a5e:	5cfd                	li	s9,-1
ffffffffc0203a60:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0203a62:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0203a66:	4b81                	li	s7,0
ffffffffc0203a68:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a6a:	00044683          	lbu	a3,0(s0)
ffffffffc0203a6e:	00140c13          	addi	s8,s0,1
ffffffffc0203a72:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0203a76:	0ff5f593          	zext.b	a1,a1
ffffffffc0203a7a:	02bb6663          	bltu	s6,a1,ffffffffc0203aa6 <vprintfmt+0x98>
ffffffffc0203a7e:	058a                	slli	a1,a1,0x2
ffffffffc0203a80:	95d6                	add	a1,a1,s5
ffffffffc0203a82:	4198                	lw	a4,0(a1)
ffffffffc0203a84:	9756                	add	a4,a4,s5
ffffffffc0203a86:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203a88:	70e6                	ld	ra,120(sp)
ffffffffc0203a8a:	7446                	ld	s0,112(sp)
ffffffffc0203a8c:	74a6                	ld	s1,104(sp)
ffffffffc0203a8e:	7906                	ld	s2,96(sp)
ffffffffc0203a90:	69e6                	ld	s3,88(sp)
ffffffffc0203a92:	6a46                	ld	s4,80(sp)
ffffffffc0203a94:	6aa6                	ld	s5,72(sp)
ffffffffc0203a96:	6b06                	ld	s6,64(sp)
ffffffffc0203a98:	7be2                	ld	s7,56(sp)
ffffffffc0203a9a:	7c42                	ld	s8,48(sp)
ffffffffc0203a9c:	7ca2                	ld	s9,40(sp)
ffffffffc0203a9e:	7d02                	ld	s10,32(sp)
ffffffffc0203aa0:	6de2                	ld	s11,24(sp)
ffffffffc0203aa2:	6109                	addi	sp,sp,128
ffffffffc0203aa4:	8082                	ret
            putch('%', putdat);
ffffffffc0203aa6:	85ca                	mv	a1,s2
ffffffffc0203aa8:	02500513          	li	a0,37
ffffffffc0203aac:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203aae:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203ab2:	02500713          	li	a4,37
ffffffffc0203ab6:	8c22                	mv	s8,s0
ffffffffc0203ab8:	f8e785e3          	beq	a5,a4,ffffffffc0203a42 <vprintfmt+0x34>
ffffffffc0203abc:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0203ac0:	1c7d                	addi	s8,s8,-1
ffffffffc0203ac2:	fee79de3          	bne	a5,a4,ffffffffc0203abc <vprintfmt+0xae>
ffffffffc0203ac6:	bfb5                	j	ffffffffc0203a42 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0203ac8:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0203acc:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0203ace:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0203ad2:	fd06071b          	addiw	a4,a2,-48
ffffffffc0203ad6:	24e56a63          	bltu	a0,a4,ffffffffc0203d2a <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0203ada:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203adc:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0203ade:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0203ae2:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203ae6:	0197073b          	addw	a4,a4,s9
ffffffffc0203aea:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203aee:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203af0:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203af4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203af6:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0203afa:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0203afe:	feb570e3          	bgeu	a0,a1,ffffffffc0203ade <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0203b02:	f60d54e3          	bgez	s10,ffffffffc0203a6a <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0203b06:	8d66                	mv	s10,s9
ffffffffc0203b08:	5cfd                	li	s9,-1
ffffffffc0203b0a:	b785                	j	ffffffffc0203a6a <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b0c:	8db6                	mv	s11,a3
ffffffffc0203b0e:	8462                	mv	s0,s8
ffffffffc0203b10:	bfa9                	j	ffffffffc0203a6a <vprintfmt+0x5c>
ffffffffc0203b12:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0203b14:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0203b16:	bf91                	j	ffffffffc0203a6a <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0203b18:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b1a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b1e:	00f74463          	blt	a4,a5,ffffffffc0203b26 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0203b22:	1a078763          	beqz	a5,ffffffffc0203cd0 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0203b26:	000a3603          	ld	a2,0(s4)
ffffffffc0203b2a:	46c1                	li	a3,16
ffffffffc0203b2c:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203b2e:	000d879b          	sext.w	a5,s11
ffffffffc0203b32:	876a                	mv	a4,s10
ffffffffc0203b34:	85ca                	mv	a1,s2
ffffffffc0203b36:	8526                	mv	a0,s1
ffffffffc0203b38:	e71ff0ef          	jal	ffffffffc02039a8 <printnum>
            break;
ffffffffc0203b3c:	b719                	j	ffffffffc0203a42 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0203b3e:	000a2503          	lw	a0,0(s4)
ffffffffc0203b42:	85ca                	mv	a1,s2
ffffffffc0203b44:	0a21                	addi	s4,s4,8
ffffffffc0203b46:	9482                	jalr	s1
            break;
ffffffffc0203b48:	bded                	j	ffffffffc0203a42 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203b4a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b4c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b50:	00f74463          	blt	a4,a5,ffffffffc0203b58 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0203b54:	16078963          	beqz	a5,ffffffffc0203cc6 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0203b58:	000a3603          	ld	a2,0(s4)
ffffffffc0203b5c:	46a9                	li	a3,10
ffffffffc0203b5e:	8a2e                	mv	s4,a1
ffffffffc0203b60:	b7f9                	j	ffffffffc0203b2e <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0203b62:	85ca                	mv	a1,s2
ffffffffc0203b64:	03000513          	li	a0,48
ffffffffc0203b68:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0203b6a:	85ca                	mv	a1,s2
ffffffffc0203b6c:	07800513          	li	a0,120
ffffffffc0203b70:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203b72:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0203b76:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203b78:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203b7a:	bf55                	j	ffffffffc0203b2e <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0203b7c:	85ca                	mv	a1,s2
ffffffffc0203b7e:	02500513          	li	a0,37
ffffffffc0203b82:	9482                	jalr	s1
            break;
ffffffffc0203b84:	bd7d                	j	ffffffffc0203a42 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0203b86:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b8a:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0203b8c:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0203b8e:	bf95                	j	ffffffffc0203b02 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0203b90:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b92:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b96:	00f74463          	blt	a4,a5,ffffffffc0203b9e <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0203b9a:	12078163          	beqz	a5,ffffffffc0203cbc <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0203b9e:	000a3603          	ld	a2,0(s4)
ffffffffc0203ba2:	46a1                	li	a3,8
ffffffffc0203ba4:	8a2e                	mv	s4,a1
ffffffffc0203ba6:	b761                	j	ffffffffc0203b2e <vprintfmt+0x120>
            if (width < 0)
ffffffffc0203ba8:	876a                	mv	a4,s10
ffffffffc0203baa:	000d5363          	bgez	s10,ffffffffc0203bb0 <vprintfmt+0x1a2>
ffffffffc0203bae:	4701                	li	a4,0
ffffffffc0203bb0:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bb4:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203bb6:	bd55                	j	ffffffffc0203a6a <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0203bb8:	000d841b          	sext.w	s0,s11
ffffffffc0203bbc:	fd340793          	addi	a5,s0,-45
ffffffffc0203bc0:	00f037b3          	snez	a5,a5
ffffffffc0203bc4:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203bc8:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0203bcc:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203bce:	008a0793          	addi	a5,s4,8
ffffffffc0203bd2:	e43e                	sd	a5,8(sp)
ffffffffc0203bd4:	100d8c63          	beqz	s11,ffffffffc0203cec <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0203bd8:	12071363          	bnez	a4,ffffffffc0203cfe <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203bdc:	000dc783          	lbu	a5,0(s11)
ffffffffc0203be0:	0007851b          	sext.w	a0,a5
ffffffffc0203be4:	c78d                	beqz	a5,ffffffffc0203c0e <vprintfmt+0x200>
ffffffffc0203be6:	0d85                	addi	s11,s11,1
ffffffffc0203be8:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203bea:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203bee:	000cc563          	bltz	s9,ffffffffc0203bf8 <vprintfmt+0x1ea>
ffffffffc0203bf2:	3cfd                	addiw	s9,s9,-1
ffffffffc0203bf4:	008c8d63          	beq	s9,s0,ffffffffc0203c0e <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203bf8:	020b9663          	bnez	s7,ffffffffc0203c24 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0203bfc:	85ca                	mv	a1,s2
ffffffffc0203bfe:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c00:	000dc783          	lbu	a5,0(s11)
ffffffffc0203c04:	0d85                	addi	s11,s11,1
ffffffffc0203c06:	3d7d                	addiw	s10,s10,-1
ffffffffc0203c08:	0007851b          	sext.w	a0,a5
ffffffffc0203c0c:	f3ed                	bnez	a5,ffffffffc0203bee <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0203c0e:	01a05963          	blez	s10,ffffffffc0203c20 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0203c12:	85ca                	mv	a1,s2
ffffffffc0203c14:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0203c18:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0203c1a:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0203c1c:	fe0d1be3          	bnez	s10,ffffffffc0203c12 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c20:	6a22                	ld	s4,8(sp)
ffffffffc0203c22:	b505                	j	ffffffffc0203a42 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c24:	3781                	addiw	a5,a5,-32
ffffffffc0203c26:	fcfa7be3          	bgeu	s4,a5,ffffffffc0203bfc <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0203c2a:	03f00513          	li	a0,63
ffffffffc0203c2e:	85ca                	mv	a1,s2
ffffffffc0203c30:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c32:	000dc783          	lbu	a5,0(s11)
ffffffffc0203c36:	0d85                	addi	s11,s11,1
ffffffffc0203c38:	3d7d                	addiw	s10,s10,-1
ffffffffc0203c3a:	0007851b          	sext.w	a0,a5
ffffffffc0203c3e:	dbe1                	beqz	a5,ffffffffc0203c0e <vprintfmt+0x200>
ffffffffc0203c40:	fa0cd9e3          	bgez	s9,ffffffffc0203bf2 <vprintfmt+0x1e4>
ffffffffc0203c44:	b7c5                	j	ffffffffc0203c24 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0203c46:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c4a:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0203c4c:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203c4e:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0203c52:	8fb9                	xor	a5,a5,a4
ffffffffc0203c54:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c58:	02d64563          	blt	a2,a3,ffffffffc0203c82 <vprintfmt+0x274>
ffffffffc0203c5c:	00002797          	auipc	a5,0x2
ffffffffc0203c60:	d3478793          	addi	a5,a5,-716 # ffffffffc0205990 <error_string>
ffffffffc0203c64:	00369713          	slli	a4,a3,0x3
ffffffffc0203c68:	97ba                	add	a5,a5,a4
ffffffffc0203c6a:	639c                	ld	a5,0(a5)
ffffffffc0203c6c:	cb99                	beqz	a5,ffffffffc0203c82 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203c6e:	86be                	mv	a3,a5
ffffffffc0203c70:	00000617          	auipc	a2,0x0
ffffffffc0203c74:	23060613          	addi	a2,a2,560 # ffffffffc0203ea0 <etext+0x2a>
ffffffffc0203c78:	85ca                	mv	a1,s2
ffffffffc0203c7a:	8526                	mv	a0,s1
ffffffffc0203c7c:	0d8000ef          	jal	ffffffffc0203d54 <printfmt>
ffffffffc0203c80:	b3c9                	j	ffffffffc0203a42 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203c82:	00002617          	auipc	a2,0x2
ffffffffc0203c86:	a3660613          	addi	a2,a2,-1482 # ffffffffc02056b8 <etext+0x1842>
ffffffffc0203c8a:	85ca                	mv	a1,s2
ffffffffc0203c8c:	8526                	mv	a0,s1
ffffffffc0203c8e:	0c6000ef          	jal	ffffffffc0203d54 <printfmt>
ffffffffc0203c92:	bb45                	j	ffffffffc0203a42 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203c94:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c96:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0203c9a:	00f74363          	blt	a4,a5,ffffffffc0203ca0 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0203c9e:	cf81                	beqz	a5,ffffffffc0203cb6 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0203ca0:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203ca4:	02044b63          	bltz	s0,ffffffffc0203cda <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0203ca8:	8622                	mv	a2,s0
ffffffffc0203caa:	8a5e                	mv	s4,s7
ffffffffc0203cac:	46a9                	li	a3,10
ffffffffc0203cae:	b541                	j	ffffffffc0203b2e <vprintfmt+0x120>
            lflag ++;
ffffffffc0203cb0:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203cb2:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203cb4:	bb5d                	j	ffffffffc0203a6a <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0203cb6:	000a2403          	lw	s0,0(s4)
ffffffffc0203cba:	b7ed                	j	ffffffffc0203ca4 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0203cbc:	000a6603          	lwu	a2,0(s4)
ffffffffc0203cc0:	46a1                	li	a3,8
ffffffffc0203cc2:	8a2e                	mv	s4,a1
ffffffffc0203cc4:	b5ad                	j	ffffffffc0203b2e <vprintfmt+0x120>
ffffffffc0203cc6:	000a6603          	lwu	a2,0(s4)
ffffffffc0203cca:	46a9                	li	a3,10
ffffffffc0203ccc:	8a2e                	mv	s4,a1
ffffffffc0203cce:	b585                	j	ffffffffc0203b2e <vprintfmt+0x120>
ffffffffc0203cd0:	000a6603          	lwu	a2,0(s4)
ffffffffc0203cd4:	46c1                	li	a3,16
ffffffffc0203cd6:	8a2e                	mv	s4,a1
ffffffffc0203cd8:	bd99                	j	ffffffffc0203b2e <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0203cda:	85ca                	mv	a1,s2
ffffffffc0203cdc:	02d00513          	li	a0,45
ffffffffc0203ce0:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0203ce2:	40800633          	neg	a2,s0
ffffffffc0203ce6:	8a5e                	mv	s4,s7
ffffffffc0203ce8:	46a9                	li	a3,10
ffffffffc0203cea:	b591                	j	ffffffffc0203b2e <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0203cec:	e329                	bnez	a4,ffffffffc0203d2e <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203cee:	02800793          	li	a5,40
ffffffffc0203cf2:	853e                	mv	a0,a5
ffffffffc0203cf4:	00002d97          	auipc	s11,0x2
ffffffffc0203cf8:	9bdd8d93          	addi	s11,s11,-1603 # ffffffffc02056b1 <etext+0x183b>
ffffffffc0203cfc:	b5f5                	j	ffffffffc0203be8 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cfe:	85e6                	mv	a1,s9
ffffffffc0203d00:	856e                	mv	a0,s11
ffffffffc0203d02:	08a000ef          	jal	ffffffffc0203d8c <strnlen>
ffffffffc0203d06:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0203d0a:	01a05863          	blez	s10,ffffffffc0203d1a <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0203d0e:	85ca                	mv	a1,s2
ffffffffc0203d10:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d12:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0203d14:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d16:	fe0d1ce3          	bnez	s10,ffffffffc0203d0e <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d1a:	000dc783          	lbu	a5,0(s11)
ffffffffc0203d1e:	0007851b          	sext.w	a0,a5
ffffffffc0203d22:	ec0792e3          	bnez	a5,ffffffffc0203be6 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203d26:	6a22                	ld	s4,8(sp)
ffffffffc0203d28:	bb29                	j	ffffffffc0203a42 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203d2a:	8462                	mv	s0,s8
ffffffffc0203d2c:	bbd9                	j	ffffffffc0203b02 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d2e:	85e6                	mv	a1,s9
ffffffffc0203d30:	00002517          	auipc	a0,0x2
ffffffffc0203d34:	98050513          	addi	a0,a0,-1664 # ffffffffc02056b0 <etext+0x183a>
ffffffffc0203d38:	054000ef          	jal	ffffffffc0203d8c <strnlen>
ffffffffc0203d3c:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d40:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0203d44:	00002d97          	auipc	s11,0x2
ffffffffc0203d48:	96cd8d93          	addi	s11,s11,-1684 # ffffffffc02056b0 <etext+0x183a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d4c:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d4e:	fda040e3          	bgtz	s10,ffffffffc0203d0e <vprintfmt+0x300>
ffffffffc0203d52:	bd51                	j	ffffffffc0203be6 <vprintfmt+0x1d8>

ffffffffc0203d54 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d54:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203d56:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d5a:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203d5c:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d5e:	ec06                	sd	ra,24(sp)
ffffffffc0203d60:	f83a                	sd	a4,48(sp)
ffffffffc0203d62:	fc3e                	sd	a5,56(sp)
ffffffffc0203d64:	e0c2                	sd	a6,64(sp)
ffffffffc0203d66:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203d68:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203d6a:	ca5ff0ef          	jal	ffffffffc0203a0e <vprintfmt>
}
ffffffffc0203d6e:	60e2                	ld	ra,24(sp)
ffffffffc0203d70:	6161                	addi	sp,sp,80
ffffffffc0203d72:	8082                	ret

ffffffffc0203d74 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203d74:	00054783          	lbu	a5,0(a0)
ffffffffc0203d78:	cb81                	beqz	a5,ffffffffc0203d88 <strlen+0x14>
    size_t cnt = 0;
ffffffffc0203d7a:	4781                	li	a5,0
        cnt ++;
ffffffffc0203d7c:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0203d7e:	00f50733          	add	a4,a0,a5
ffffffffc0203d82:	00074703          	lbu	a4,0(a4)
ffffffffc0203d86:	fb7d                	bnez	a4,ffffffffc0203d7c <strlen+0x8>
    }
    return cnt;
}
ffffffffc0203d88:	853e                	mv	a0,a5
ffffffffc0203d8a:	8082                	ret

ffffffffc0203d8c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203d8c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203d8e:	e589                	bnez	a1,ffffffffc0203d98 <strnlen+0xc>
ffffffffc0203d90:	a811                	j	ffffffffc0203da4 <strnlen+0x18>
        cnt ++;
ffffffffc0203d92:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203d94:	00f58863          	beq	a1,a5,ffffffffc0203da4 <strnlen+0x18>
ffffffffc0203d98:	00f50733          	add	a4,a0,a5
ffffffffc0203d9c:	00074703          	lbu	a4,0(a4)
ffffffffc0203da0:	fb6d                	bnez	a4,ffffffffc0203d92 <strnlen+0x6>
ffffffffc0203da2:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203da4:	852e                	mv	a0,a1
ffffffffc0203da6:	8082                	ret

ffffffffc0203da8 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203da8:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203daa:	0005c703          	lbu	a4,0(a1)
ffffffffc0203dae:	0585                	addi	a1,a1,1
ffffffffc0203db0:	0785                	addi	a5,a5,1
ffffffffc0203db2:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203db6:	fb75                	bnez	a4,ffffffffc0203daa <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203db8:	8082                	ret

ffffffffc0203dba <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203dba:	00054783          	lbu	a5,0(a0)
ffffffffc0203dbe:	e791                	bnez	a5,ffffffffc0203dca <strcmp+0x10>
ffffffffc0203dc0:	a01d                	j	ffffffffc0203de6 <strcmp+0x2c>
ffffffffc0203dc2:	00054783          	lbu	a5,0(a0)
ffffffffc0203dc6:	cb99                	beqz	a5,ffffffffc0203ddc <strcmp+0x22>
ffffffffc0203dc8:	0585                	addi	a1,a1,1
ffffffffc0203dca:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0203dce:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203dd0:	fef709e3          	beq	a4,a5,ffffffffc0203dc2 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203dd4:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203dd8:	9d19                	subw	a0,a0,a4
ffffffffc0203dda:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203ddc:	0015c703          	lbu	a4,1(a1)
ffffffffc0203de0:	4501                	li	a0,0
}
ffffffffc0203de2:	9d19                	subw	a0,a0,a4
ffffffffc0203de4:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203de6:	0005c703          	lbu	a4,0(a1)
ffffffffc0203dea:	4501                	li	a0,0
ffffffffc0203dec:	b7f5                	j	ffffffffc0203dd8 <strcmp+0x1e>

ffffffffc0203dee <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203dee:	ce01                	beqz	a2,ffffffffc0203e06 <strncmp+0x18>
ffffffffc0203df0:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203df4:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203df6:	cb91                	beqz	a5,ffffffffc0203e0a <strncmp+0x1c>
ffffffffc0203df8:	0005c703          	lbu	a4,0(a1)
ffffffffc0203dfc:	00f71763          	bne	a4,a5,ffffffffc0203e0a <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0203e00:	0505                	addi	a0,a0,1
ffffffffc0203e02:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e04:	f675                	bnez	a2,ffffffffc0203df0 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e06:	4501                	li	a0,0
ffffffffc0203e08:	8082                	ret
ffffffffc0203e0a:	00054503          	lbu	a0,0(a0)
ffffffffc0203e0e:	0005c783          	lbu	a5,0(a1)
ffffffffc0203e12:	9d1d                	subw	a0,a0,a5
}
ffffffffc0203e14:	8082                	ret

ffffffffc0203e16 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203e16:	a021                	j	ffffffffc0203e1e <strchr+0x8>
        if (*s == c) {
ffffffffc0203e18:	00f58763          	beq	a1,a5,ffffffffc0203e26 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0203e1c:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e1e:	00054783          	lbu	a5,0(a0)
ffffffffc0203e22:	fbfd                	bnez	a5,ffffffffc0203e18 <strchr+0x2>
    }
    return NULL;
ffffffffc0203e24:	4501                	li	a0,0
}
ffffffffc0203e26:	8082                	ret

ffffffffc0203e28 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e28:	ca01                	beqz	a2,ffffffffc0203e38 <memset+0x10>
ffffffffc0203e2a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e2c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e2e:	0785                	addi	a5,a5,1
ffffffffc0203e30:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e34:	fef61de3          	bne	a2,a5,ffffffffc0203e2e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203e38:	8082                	ret

ffffffffc0203e3a <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203e3a:	ca19                	beqz	a2,ffffffffc0203e50 <memcpy+0x16>
ffffffffc0203e3c:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203e3e:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203e40:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e44:	0585                	addi	a1,a1,1
ffffffffc0203e46:	0785                	addi	a5,a5,1
ffffffffc0203e48:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203e4c:	feb61ae3          	bne	a2,a1,ffffffffc0203e40 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203e50:	8082                	ret

ffffffffc0203e52 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203e52:	c205                	beqz	a2,ffffffffc0203e72 <memcmp+0x20>
ffffffffc0203e54:	962a                	add	a2,a2,a0
ffffffffc0203e56:	a019                	j	ffffffffc0203e5c <memcmp+0xa>
ffffffffc0203e58:	00c50d63          	beq	a0,a2,ffffffffc0203e72 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203e5c:	00054783          	lbu	a5,0(a0)
ffffffffc0203e60:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203e64:	0505                	addi	a0,a0,1
ffffffffc0203e66:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203e68:	fee788e3          	beq	a5,a4,ffffffffc0203e58 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e6c:	40e7853b          	subw	a0,a5,a4
ffffffffc0203e70:	8082                	ret
    }
    return 0;
ffffffffc0203e72:	4501                	li	a0,0
}
ffffffffc0203e74:	8082                	ret
