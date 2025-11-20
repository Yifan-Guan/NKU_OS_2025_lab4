<h1 align="center" style="font-size: 44px"> 实验四：进程管理 </h1>

**小组成员：**

- 管一凡：2312307
- 周雨晴：2312313
- 欧一凡：2312826

**Github仓库地址：**https://github.com/Yifan-Guan/NKU_OS_2025_lab4.git

**说明：**

# 练习1：分配并初始化一个进程控制块

## 1.设计实现过程

alloc_proc 函数的目标是为即将创建的新进程（内核线程）分配一个进程控制块（struct proc_struct），并将其初始化到一个已知的、安全的“未初始化”状态。

- 成功分配内存后，使用 memset(proc, 0, sizeof(struct proc_struct)) 将整个结构体的内存块清零。
- 几个成员需要被设置为**特定的非零**初始值，以符合进程管理状态机的要求
  - 显式地将进程状态设置为 PROC_UNINIT（未初始化）
  - 将进程ID（PID）设置为一个无效值，用以表明该进程尚未被 get_pid() 分配一个有效的PID
  - 将页目录（pgdir）指向内核的页目录物理地址

## 2.说明proc_struct中和成员变量含义和在本实验中的作用

### 2.1 struct context context

- 变量含义

  - context中保存了进程执行的上下文，也就是几个关键的寄存器的值。这些寄存器的值用于在进程切换中还原之前进程的运行状态。
  - 与trapframe不同，它只保存内核态执行所需的最小寄存器集合。

- 作用

  - context 被 switch_to() 函数使用。

  - 当proc_run决定从进程A切换到进程B时，它会调用

    ```C
     switch_to(&A->context, &B->context)
    ```

  - switch_to 会：

    - 将当前CPU的寄存器保存到 A->context 中。
    - 从 B->context 中加载之前保存的寄存器到CPU。
    - 执行 ret 指令，跳转到 B->context 返回地址所指向的地址。

### 2.2 struct trapframe *tf

- 变量含义
  - tf里保存了进程的中断帧。
  - 当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中（这里需要保存的执行状态数量不同于上下文切换）。
  - 系统调用可能会改变用户寄存器的值，我们可以通过调整中断帧来使得系统调用返回特定的值。
- 作用
  - 对于一个新创建的内核线程，它还没有“执行现场”。因此，我们需要伪造一个 trapframe，并将其放置在该线程的内核栈顶。
  - 这个 tf 中预设了线程的入口点和参数。当线程第一次被调度并“从中断返回”时，它会从这个伪造的 tf 中恢复寄存器，从而跳转到 kernel_thread_entry 开始执行。

# 练习2：为新创建的内核线程分配资源

## 1.设计实现过程



## 2.ucore是否做到给每个新fork的线程一个唯一的id？

- ucore做到了给每个新fork的线程一个唯一的ID。

- 分析和理由：这是通过 get_pid() 函数实现的。get_pid() 函数的核心逻辑如下：
  - 它使用一个静态变量 last_pid 来记录上一次分配的PID。
  - 每次调用时，它将 last_pid 加 1（如果超过 MAX_PID 则回绕到 1）。
  - **关键点：** 它并不会立即返回这个新的 last_pid，而是会遍历 proc_list（全局进程链表），检查这个 last_pid是否已经被某个现存的进程所占用。
  - 如果 proc->pid == last_pid，说明这个PID已被占用，get_pid() 会继续增加 last_pid 并重复遍历检查过程。
  - 直到它找到了一个在 proc_list 中不存在的 pid，它才会返回这个 pid。

# 练习3：编写proc_run 函数

## 1.在本实验的执行过程中，创建且运行了几个内核线程？

- 创建并运行了 2 个内核线程
- 第一个线程
  - idleproc = alloc_proc()：分配了第一个进程控制块。
  - 这个进程被手动初始化为PID 0，命名为 "idle"，并被设置current（当前运行）进程。
  - 这个线程会执行 cpu_idle() 函数，它是操作系统的空闲线程。

- 第二个线程
  - int pid = kernel_thread(init_main, "Hello world!!", 0);：proc_init 接着调用 kernel_thread 来创建第二个内核线程。
  - initproc = find_proc(pid); set_proc_name(initproc, "init");：这个新线程（PID 1）被命名为 "init"，它将执行 init_main 函数。



















