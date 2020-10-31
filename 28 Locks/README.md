## 28 Locks

首先了解一下程序的参数和默认值，大部分参数和 [26 Concurrency and Threads](https://github.com/jckling/Study-Notes/tree/ostep/26%20Concurrency%20and%20Threads) 相同

```python
parser = OptionParser()
# 随机种子，默认为 0
parser.add_option('-s', '--seed',      default=0,          help='the random seed',                  action='store',      type='int',    dest='seed')
# 线程数量，默认为 2
parser.add_option('-t', '--threads',   default=2,          help='number of threads',                action='store',      type='int',    dest='numthreads')
# 源程序
parser.add_option('-p', '--program',   default='',         help='source program (in .s)',           action='store',      type='string', dest='progfile')
# 中断间隔，默认为 50 条指令中断一次
parser.add_option('-i', '--interrupt', default=50,         help='interrupt frequency',              action='store',      type='int',    dest='intfreq')
# 控制线程运行顺序
parser.add_option('-P', '--procsched', default='',         help='control exactly which thread runs when',
                                                                                                    action='store',      type='string', dest='procsched')
# 随机中断
parser.add_option('-r', '--randints',  default=False,      help='if interrupts are random',         action='store_true',                dest='intrand')
# 设置寄存器的值
parser.add_option('-a', '--argv',      default='',
                  help='comma-separated per-thread args (e.g., ax=1,ax=2 sets thread 0 ax reg to 1 and thread 1 ax reg to 2); specify multiple regs per thread via colon-separated list (e.g., ax=1:bx=2,cx=3 sets thread 0 ax and bx and just cx for thread 1)',
                  action='store',      type='string', dest='argv')
# 加载代码的地址，默认为 1000
parser.add_option('-L', '--loadaddr',  default=1000,       help='address where to load code',       action='store',      type='int',    dest='loadaddr')
# 地址空间大小，默认为 128 KB
parser.add_option('-m', '--memsize',   default=128,        help='size of address space (KB)',       action='store',      type='int',    dest='memsize')
# 跟踪内存地址
parser.add_option('-M', '--memtrace',  default='',         help='comma-separated list of addrs to trace (e.g., 20000,20001)', action='store',
                  type='string', dest='memtrace')
# 跟踪寄存器
parser.add_option('-R', '--regtrace',  default='',         help='comma-separated list of regs to trace (e.g., ax,bx,cx,dx)',  action='store',
                  type='string', dest='regtrace')
# 跟踪条件
parser.add_option('-C', '--cctrace',   default=False,      help='should we trace condition codes',  action='store_true', dest='cctrace')
# 输出额外状态
parser.add_option('-S', '--printstats',default=False,      help='print some extra stats',           action='store_true', dest='printstats')
# 详细信息
parser.add_option('-v', '--verbose',   default=False,      help='print some extra info',            action='store_true', dest='verbose')
# 打印行标题的频率，默认不打印
parser.add_option('-H', '--headercount',default=-1,        help='how often to print a row header',  action='store',      type='int',    dest='headercount')
# 计算答案
parser.add_option('-c', '--compute',   default=False,      help='compute answers for me',           action='store_true', dest='solve')
(options, args) = parser.parse_args()
```

有以下五种形式的地址：
- `2000`：地址
- `(%cx)`：寄存器 cx 的内容
- `1000(%dx)`：1000 + 寄存器 dx 的内容
- `10(%ax,%bx)`：10 + 寄存器 ax 的内容 + 寄存器 bx 的内容
- `10(%ax,%bx,4)`：10 + 寄存器 ax 的内容 + 寄存器 bx 的内容*4

示例 [simple-race.s] 与 [26 Concurrency and Threads](https://github.com/jckling/Study-Notes/tree/ostep/26%20Concurrency%20and%20Threads) 中的相同。

### 1

查看汇编代码 flag.s 中的指令序列
- 变量 flag 作为锁
- 获取 flag 后进入临界区，修改变量 count
  - 将 flag 设置为 1
- 完成后释放锁
  - 将 flag 设置为 0
- bx 寄存器中的值控制循环次数

```
.var flag
.var count

.main
.top

.acquire
mov  flag, %ax      # get flag
test $0, %ax        # if we get 0 back: lock is free!
jne  .acquire       # if not, try again
mov  $1, flag       # store 1 into flag

# critical section
mov  count, %ax     # get the value at the address
add  $1, %ax        # increment it
mov  %ax, count     # store it back

# release lock
mov  $0, flag       # clear the flag now

# see if we're still looping
sub  $1, %bx
test $0, %bx
jgt .top	

halt
```

### 2

使用默认参数运行 flag.s ，两个线程
- bx 寄存器默认初始化为 0
- 每 50 条指令中断一次，因此两个线程按顺序执行，最终 count 的值为 2

```bash
./x86.py -p flag.s -R bx -M count,flag

# 输出
ARG seed 0                      <---- 随机种子
ARG numthreads 2                <---- 线程数量
ARG program flag.s              <---- 源程序
ARG interrupt frequency 50      <---- 中断频率
ARG interrupt randomness False  <---- 随机中断
ARG procsched                   <---- 线程执行时间
ARG argv                        <---- 指令参数
ARG load address 1000           <---- 代码加载地址
ARG memsize 128                 <---- 内存大小
ARG memtrace count,flag         <---- 跟踪内存
ARG regtrace bx                 <---- 跟踪寄存器
ARG cctrace True                <---- 跟踪条件语句
ARG printstats False            <---- 状态输出
ARG verbose False               <---- 详细信息


count  flag      bx   >= >  <= <  != ==        Thread 0                Thread 1         

    0     0       0   0  0  0  0  0  0  
    0     0       0   0  0  0  0  0  0  1000 mov  flag, %ax
    0     0       0   1  0  1  0  0  1  1001 test $0, %ax
    0     0       0   1  0  1  0  0  1  1002 jne  .acquire
    0     1       0   1  0  1  0  0  1  1003 mov  $1, flag
    0     1       0   1  0  1  0  0  1  1004 mov  count, %ax
    0     1       0   1  0  1  0  0  1  1005 add  $1, %ax
    1     1       0   1  0  1  0  0  1  1006 mov  %ax, count
    1     0       0   1  0  1  0  0  1  1007 mov  $0, flag
    1     0      -1   1  0  1  0  0  1  1008 sub  $1, %bx
    1     0      -1   0  0  1  1  1  0  1009 test $0, %bx
    1     0      -1   0  0  1  1  1  0  1010 jgt .top
    1     0      -1   0  0  1  1  1  0  1011 halt
    1     0       0   0  0  0  0  0  0  ----- Halt;Switch -----  ----- Halt;Switch -----  
    1     0       0   0  0  0  0  0  0                           1000 mov  flag, %ax
    1     0       0   1  0  1  0  0  1                           1001 test $0, %ax
    1     0       0   1  0  1  0  0  1                           1002 jne  .acquire
    1     1       0   1  0  1  0  0  1                           1003 mov  $1, flag
    1     1       0   1  0  1  0  0  1                           1004 mov  count, %ax
    1     1       0   1  0  1  0  0  1                           1005 add  $1, %ax
    2     1       0   1  0  1  0  0  1                           1006 mov  %ax, count
    2     0       0   1  0  1  0  0  1                           1007 mov  $0, flag
    2     0      -1   1  0  1  0  0  1                           1008 sub  $1, %bx
    2     0      -1   0  0  1  1  1  0                           1009 test $0, %bx
    2     0      -1   0  0  1  1  1  0                           1010 jgt .top
    2     0      -1   0  0  1  1  1  0                           1011 halt

```

之后的输出结果均省略参数部分。

### 3

使用 `-a` 参数，将两个线程的 bx 寄存器的值设置为 2 ，即各循环两次
- 最终 count 的值为 4

```bash
./x86.py -p flag.s -a bx=2,bx=2 -R bx -M count,flag -C -c

# 输出
count  flag      bx   >= >  <= <  != ==        Thread 0                Thread 1         

    0     0       2   0  0  0  0  0  0  
    0     0       2   0  0  0  0  0  0  1000 mov  flag, %ax
    0     0       2   1  0  1  0  0  1  1001 test $0, %ax
    0     0       2   1  0  1  0  0  1  1002 jne  .acquire
    0     1       2   1  0  1  0  0  1  1003 mov  $1, flag
    0     1       2   1  0  1  0  0  1  1004 mov  count, %ax
    0     1       2   1  0  1  0  0  1  1005 add  $1, %ax
    1     1       2   1  0  1  0  0  1  1006 mov  %ax, count
    1     0       2   1  0  1  0  0  1  1007 mov  $0, flag
    1     0       1   1  0  1  0  0  1  1008 sub  $1, %bx
    1     0       1   1  1  0  0  1  0  1009 test $0, %bx
    1     0       1   1  1  0  0  1  0  1010 jgt .top
    1     0       1   1  1  0  0  1  0  1000 mov  flag, %ax
    1     0       1   1  0  1  0  0  1  1001 test $0, %ax
    1     0       1   1  0  1  0  0  1  1002 jne  .acquire
    1     1       1   1  0  1  0  0  1  1003 mov  $1, flag
    1     1       1   1  0  1  0  0  1  1004 mov  count, %ax
    1     1       1   1  0  1  0  0  1  1005 add  $1, %ax
    2     1       1   1  0  1  0  0  1  1006 mov  %ax, count
    2     0       1   1  0  1  0  0  1  1007 mov  $0, flag
    2     0       0   1  0  1  0  0  1  1008 sub  $1, %bx
    2     0       0   1  0  1  0  0  1  1009 test $0, %bx
    2     0       0   1  0  1  0  0  1  1010 jgt .top
    2     0       0   1  0  1  0  0  1  1011 halt
    2     0       2   0  0  0  0  0  0  ----- Halt;Switch -----  ----- Halt;Switch -----  
    2     0       2   0  0  0  0  0  0                           1000 mov  flag, %ax
    2     0       2   1  0  1  0  0  1                           1001 test $0, %ax
    2     0       2   1  0  1  0  0  1                           1002 jne  .acquire
    2     1       2   1  0  1  0  0  1                           1003 mov  $1, flag
    2     1       2   1  0  1  0  0  1                           1004 mov  count, %ax
    2     1       2   1  0  1  0  0  1                           1005 add  $1, %ax
    3     1       2   1  0  1  0  0  1                           1006 mov  %ax, count
    3     0       2   1  0  1  0  0  1                           1007 mov  $0, flag
    3     0       1   1  0  1  0  0  1                           1008 sub  $1, %bx
    3     0       1   1  1  0  0  1  0                           1009 test $0, %bx
    3     0       1   1  1  0  0  1  0                           1010 jgt .top
    3     0       1   1  1  0  0  1  0                           1000 mov  flag, %ax
    3     0       1   1  0  1  0  0  1                           1001 test $0, %ax
    3     0       1   1  0  1  0  0  1                           1002 jne  .acquire
    3     1       1   1  0  1  0  0  1                           1003 mov  $1, flag
    3     1       1   1  0  1  0  0  1                           1004 mov  count, %ax
    3     1       1   1  0  1  0  0  1                           1005 add  $1, %ax
    4     1       1   1  0  1  0  0  1                           1006 mov  %ax, count
    4     0       1   1  0  1  0  0  1                           1007 mov  $0, flag
    4     0       0   1  0  1  0  0  1                           1008 sub  $1, %bx
    4     0       0   1  0  1  0  0  1                           1009 test $0, %bx
    4     0       0   1  0  1  0  0  1                           1010 jgt .top
    4     0       0   1  0  1  0  0  1                           1011 halt
```

### 4

使用 `-i` 参数，设置每 3 条指令中断一次
- 线程 0 对 count 值的更新没有及时写入，导致线程 1 读取了脏数据进行修改，最终 count 的值为错误的 1

```bash
./x86.py -p flag.s -i 3 -R bx -M count,flag -C -c

# 输出
count  flag      bx   >= >  <= <  != ==        Thread 0                Thread 1         

    0     0       0   0  0  0  0  0  0  
    0     0       0   0  0  0  0  0  0  1000 mov  flag, %ax
    0     0       0   1  0  1  0  0  1  1001 test $0, %ax
    0     0       0   1  0  1  0  0  1  1002 jne  .acquire
    0     0       0   0  0  0  0  0  0  ------ Interrupt ------  ------ Interrupt ------  
    0     0       0   0  0  0  0  0  0                           1000 mov  flag, %ax
    0     0       0   1  0  1  0  0  1                           1001 test $0, %ax
    0     0       0   1  0  1  0  0  1                           1002 jne  .acquire
    0     0       0   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    0     1       0   1  0  1  0  0  1  1003 mov  $1, flag
    0     1       0   1  0  1  0  0  1  1004 mov  count, %ax
    0     1       0   1  0  1  0  0  1  1005 add  $1, %ax
    0     1       0   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    0     1       0   1  0  1  0  0  1                           1003 mov  $1, flag
    0     1       0   1  0  1  0  0  1                           1004 mov  count, %ax
    0     1       0   1  0  1  0  0  1                           1005 add  $1, %ax
    0     1       0   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    1     1       0   1  0  1  0  0  1  1006 mov  %ax, count
    1     0       0   1  0  1  0  0  1  1007 mov  $0, flag
    1     0      -1   1  0  1  0  0  1  1008 sub  $1, %bx
    1     0       0   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    1     0       0   1  0  1  0  0  1                           1006 mov  %ax, count
    1     0       0   1  0  1  0  0  1                           1007 mov  $0, flag
    1     0      -1   1  0  1  0  0  1                           1008 sub  $1, %bx
    1     0      -1   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    1     0      -1   0  0  1  1  1  0  1009 test $0, %bx
    1     0      -1   0  0  1  1  1  0  1010 jgt .top
    1     0      -1   0  0  1  1  1  0  1011 halt
    1     0      -1   1  0  1  0  0  1  ----- Halt;Switch -----  ----- Halt;Switch -----  
    1     0      -1   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    1     0      -1   0  0  1  1  1  0                           1009 test $0, %bx
    1     0      -1   0  0  1  1  1  0                           1010 jgt .top
    1     0      -1   0  0  1  1  1  0                           1011 halt
```

### 5

查看汇编代码 test-and-set.s 中的指令序列，实现了测试并设置（test-and-set）
- `xchg` 交换值，原子操作
- 将 mutex 的值放入 ax 寄存器，测试是否为 0 （锁空闲）
  - 如果不是则进入临界区，修改 count 的值
  - 修改完毕释放锁
- bx 寄存器中的值控制循环次数

```
.var mutex
.var count

.main
.top	

.acquire
mov  $1, %ax        
xchg %ax, mutex     # atomic swap of 1 and mutex
test $0, %ax        # if we get 0 back: lock is free!
jne  .acquire       # if not, try again

# critical section
mov  count, %ax     # get the value at the address
add  $1, %ax        # increment it
mov  %ax, count     # store it back

# release lock
mov  $0, mutex

# see if we're still looping
sub  $1, %bx
test $0, %bx
jgt .top	

halt
```

### 6

使用默认参数运行 test-and-set.s ，两个线程，和 2 相同
- bx 寄存器默认初始化为 0
- 每 50 条指令中断一次，因此两个线程按顺序执行，最终 count 的值为 2

```bash
./x86.py -p test-and-set.s -R ax,bx -M count,mutex -C -c

# 输出
count mutex      ax    bx   >= >  <= <  != ==        Thread 0                Thread 1         

    0     0       0     0   0  0  0  0  0  0  
    0     0       1     0   0  0  0  0  0  0  1000 mov  $1, %ax
    0     1       0     0   0  0  0  0  0  0  1001 xchg %ax, mutex
    0     1       0     0   1  0  1  0  0  1  1002 test $0, %ax
    0     1       0     0   1  0  1  0  0  1  1003 jne  .acquire
    0     1       0     0   1  0  1  0  0  1  1004 mov  count, %ax
    0     1       1     0   1  0  1  0  0  1  1005 add  $1, %ax
    1     1       1     0   1  0  1  0  0  1  1006 mov  %ax, count
    1     0       1     0   1  0  1  0  0  1  1007 mov  $0, mutex
    1     0       1    -1   1  0  1  0  0  1  1008 sub  $1, %bx
    1     0       1    -1   0  0  1  1  1  0  1009 test $0, %bx
    1     0       1    -1   0  0  1  1  1  0  1010 jgt .top
    1     0       1    -1   0  0  1  1  1  0  1011 halt
    1     0       0     0   0  0  0  0  0  0  ----- Halt;Switch -----  ----- Halt;Switch -----  
    1     0       1     0   0  0  0  0  0  0                           1000 mov  $1, %ax
    1     1       0     0   0  0  0  0  0  0                           1001 xchg %ax, mutex
    1     1       0     0   1  0  1  0  0  1                           1002 test $0, %ax
    1     1       0     0   1  0  1  0  0  1                           1003 jne  .acquire
    1     1       1     0   1  0  1  0  0  1                           1004 mov  count, %ax
    1     1       2     0   1  0  1  0  0  1                           1005 add  $1, %ax
    2     1       2     0   1  0  1  0  0  1                           1006 mov  %ax, count
    2     0       2     0   1  0  1  0  0  1                           1007 mov  $0, mutex
    2     0       2    -1   1  0  1  0  0  1                           1008 sub  $1, %bx
    2     0       2    -1   0  0  1  1  1  0                           1009 test $0, %bx
    2     0       2    -1   0  0  1  1  1  0                           1010 jgt .top
    2     0       2    -1   0  0  1  1  1  0                           1011 halt
```

修改中断间隔，每 5 条指令中断一次
- 上下文切换次数增加，程序执行变慢
  - 线程 0 执行完毕切换到线程 1 ，执行 3 条语句后被中断，然后继续运行线程 1

```bash
./x86.py -p test-and-set.s -i 5 -R ax,bx -M count,mutex -C -c

# 输出
count mutex      ax    bx   >= >  <= <  != ==        Thread 0                Thread 1         

    0     0       0     0   0  0  0  0  0  0  
    0     0       1     0   0  0  0  0  0  0  1000 mov  $1, %ax
    0     1       0     0   0  0  0  0  0  0  1001 xchg %ax, mutex
    0     1       0     0   1  0  1  0  0  1  1002 test $0, %ax
    0     1       0     0   1  0  1  0  0  1  1003 jne  .acquire
    0     1       0     0   1  0  1  0  0  1  1004 mov  count, %ax
    0     1       0     0   0  0  0  0  0  0  ------ Interrupt ------  ------ Interrupt ------  
    0     1       1     0   0  0  0  0  0  0                           1000 mov  $1, %ax
    0     1       1     0   0  0  0  0  0  0                           1001 xchg %ax, mutex
    0     1       1     0   1  1  0  0  1  0                           1002 test $0, %ax
    0     1       1     0   1  1  0  0  1  0                           1003 jne  .acquire
    0     1       1     0   1  1  0  0  1  0                           1000 mov  $1, %ax
    0     1       0     0   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    0     1       1     0   1  0  1  0  0  1  1005 add  $1, %ax
    1     1       1     0   1  0  1  0  0  1  1006 mov  %ax, count
    1     0       1     0   1  0  1  0  0  1  1007 mov  $0, mutex
    1     0       1    -1   1  0  1  0  0  1  1008 sub  $1, %bx
    1     0       1    -1   0  0  1  1  1  0  1009 test $0, %bx
    1     0       1     0   1  1  0  0  1  0  ------ Interrupt ------  ------ Interrupt ------  
    1     1       0     0   1  1  0  0  1  0                           1001 xchg %ax, mutex
    1     1       0     0   1  0  1  0  0  1                           1002 test $0, %ax
    1     1       0     0   1  0  1  0  0  1                           1003 jne  .acquire
    1     1       1     0   1  0  1  0  0  1                           1004 mov  count, %ax
    1     1       2     0   1  0  1  0  0  1                           1005 add  $1, %ax
    1     1       1    -1   0  0  1  1  1  0  ------ Interrupt ------  ------ Interrupt ------  
    1     1       1    -1   0  0  1  1  1  0  1010 jgt .top
    1     1       1    -1   0  0  1  1  1  0  1011 halt
    1     1       2     0   1  0  1  0  0  1  ----- Halt;Switch -----  ----- Halt;Switch -----  
    2     1       2     0   1  0  1  0  0  1                           1006 mov  %ax, count
    2     0       2     0   1  0  1  0  0  1                           1007 mov  $0, mutex
    2     0       2    -1   1  0  1  0  0  1                           1008 sub  $1, %bx
    2     0       2    -1   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    2     0       2    -1   0  0  1  1  1  0                           1009 test $0, %bx
    2     0       2    -1   0  0  1  1  1  0                           1010 jgt .top
    2     0       2    -1   0  0  1  1  1  0                           1011 halt
```


### 7

使用 `-P` 参数控制线程运行
- 线程 0 先执行 4 条指令，然后线程 1 再执行 4 条指令，以此循环
- `xchg %ax, mutex` 交换 ax 寄存器和 mutex 的值
  - 线程 0 获得锁后，mutex 的值为 1 ，ax 的值为 0
  - 线程 1 请求锁时，mutex 的值为 1 ，ax 的值为 1 ，继续自旋等待

```bash
./x86.py -p test-and-set.s -P 00001111 -R ax,bx -M count,mutex -C -c

# 输出
count mutex      ax    bx   >= >  <= <  != ==        Thread 0                Thread 1         

    0     0       0     0   0  0  0  0  0  0  
    0     0       1     0   0  0  0  0  0  0  1000 mov  $1, %ax
    0     1       0     0   0  0  0  0  0  0  1001 xchg %ax, mutex
    0     1       0     0   1  0  1  0  0  1  1002 test $0, %ax
    0     1       0     0   1  0  1  0  0  1  1003 jne  .acquire
    0     1       0     0   0  0  0  0  0  0  ------ Interrupt ------  ------ Interrupt ------  
    0     1       1     0   0  0  0  0  0  0                           1000 mov  $1, %ax
    0     1       1     0   0  0  0  0  0  0                           1001 xchg %ax, mutex
    0     1       1     0   1  1  0  0  1  0                           1002 test $0, %ax
    0     1       1     0   1  1  0  0  1  0                           1003 jne  .acquire
    0     1       0     0   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    0     1       0     0   1  0  1  0  0  1  1004 mov  count, %ax
    0     1       1     0   1  0  1  0  0  1  1005 add  $1, %ax
    1     1       1     0   1  0  1  0  0  1  1006 mov  %ax, count
    1     0       1     0   1  0  1  0  0  1  1007 mov  $0, mutex
    1     0       1     0   1  1  0  0  1  0  ------ Interrupt ------  ------ Interrupt ------  
    1     0       1     0   1  1  0  0  1  0                           1000 mov  $1, %ax
    1     1       0     0   1  1  0  0  1  0                           1001 xchg %ax, mutex
    1     1       0     0   1  0  1  0  0  1                           1002 test $0, %ax
    1     1       0     0   1  0  1  0  0  1                           1003 jne  .acquire
    1     1       1     0   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    1     1       1    -1   1  0  1  0  0  1  1008 sub  $1, %bx
    1     1       1    -1   0  0  1  1  1  0  1009 test $0, %bx
    1     1       1    -1   0  0  1  1  1  0  1010 jgt .top
    1     1       1    -1   0  0  1  1  1  0  1011 halt
    1     1       0     0   1  0  1  0  0  1  ----- Halt;Switch -----  ----- Halt;Switch -----  
    1     1       1     0   1  0  1  0  0  1                           1004 mov  count, %ax
    1     1       2     0   1  0  1  0  0  1                           1005 add  $1, %ax
    2     1       2     0   1  0  1  0  0  1                           1006 mov  %ax, count
    2     0       2     0   1  0  1  0  0  1                           1007 mov  $0, mutex
    2     0       2    -1   1  0  1  0  0  1                           1008 sub  $1, %bx
    2     0       2    -1   0  0  1  1  1  0                           1009 test $0, %bx
    2     0       2    -1   0  0  1  1  1  0                           1010 jgt .top
    2     0       2    -1   0  0  1  1  1  0                           1011 halt
```

### 8

查看汇编代码 peterson.s 中的指令序列，实现了 Peterson 算法（针对两个线程）
- flag 数组大小为 2
  - 表示线程是否请求锁
- 全局变量 turn 和 count
- `lea flag, %fx` 将 flag 的地址放入 fx 寄存器
- `neg %cx` 对 cx 寄存器中的值取负
- 假设 bx 寄存器存储线程 ID ，self 表示线程 ID
- turn 表示当两个线程都请求锁时，应该是哪个线程进入临界区

```
# array of 2 integers (each size 4 bytes)
# load address of flag into fx register
# access flag[] with 0(%fx,%index,4)
# where %index is a register holding 0 or 1
# index reg contains 0 -> flag[0], if 1->flag[1]
.var flag   2     

# global turn variable
.var turn

# global count
.var count

.main

# put address of flag into fx
lea flag, %fx

# assume thread ID is in bx (0 or 1, scale by 4 to get proper flag address)
mov %bx, %cx   # bx: self, now copies to cx
neg %cx        # cx: - self
add $1, %cx    # cx: 1 - self

.acquire
mov $1, 0(%fx,%bx,4)    # flag[self] = 1
mov %cx, turn           # turn       = 1 - self

.spin1
mov 0(%fx,%cx,4), %ax   # flag[1-self]
test $1, %ax            
jne .fini               # if flag[1-self] != 1, skip past loop to .fini

.spin2                  # just labeled for fun, not needed
mov turn, %ax
test %cx, %ax           # compare 'turn' and '1 - self'
je .spin1               # if turn==1-self, go back and start spin again

# fall out of spin
.fini

# do critical section now
mov count, %ax
add $1, %ax
mov %ax, count

.release
mov $0, 0(%fx,%bx,4)    # flag[self] = 0


# end case: make sure it's other's turn
mov %cx, turn           # turn       = 1 - self
halt
```

### 9

使用默认参数执行
- 每 50 条指令中断一次，因此两个线程按顺序执行，最终 count 的值为 2 

```bash
./x86.py -p peterson.s -i 5 -R ax,bx,cx -M flag,turn,count -C -c

# 输出
 flag  turn count      ax    bx    cx   >= >  <= <  != ==        Thread 0                Thread 1         

    0     0     0       0     0     0   0  0  0  0  0  0  
    0     0     0       0     0     0   0  0  0  0  0  0  1000 lea flag, %fx
    0     0     0       0     0     0   0  0  0  0  0  0  1001 mov %bx, %cx
    0     0     0       0     0     0   0  0  0  0  0  0  1002 neg %cx
    0     0     0       0     0     1   0  0  0  0  0  0  1003 add $1, %cx
    1     0     0       0     0     1   0  0  0  0  0  0  1004 mov $1, 0(%fx,%bx,4)
    1     1     0       0     0     1   0  0  0  0  0  0  1005 mov %cx, turn
    1     1     0       0     0     1   0  0  0  0  0  0  1006 mov 0(%fx,%cx,4), %ax
    1     1     0       0     0     1   0  0  1  1  1  0  1007 test $1, %ax
    1     1     0       0     0     1   0  0  1  1  1  0  1008 jne .fini
    1     1     0       0     0     1   0  0  1  1  1  0  1012 mov count, %ax
    1     1     0       1     0     1   0  0  1  1  1  0  1013 add $1, %ax
    1     1     1       1     0     1   0  0  1  1  1  0  1014 mov %ax, count
    0     1     1       1     0     1   0  0  1  1  1  0  1015 mov $0, 0(%fx,%bx,4)
    0     1     1       1     0     1   0  0  1  1  1  0  1016 mov %cx, turn
    0     1     1       1     0     1   0  0  1  1  1  0  1017 halt
    0     1     1       0     0     0   0  0  0  0  0  0  ----- Halt;Switch -----  ----- Halt;Switch -----  
    0     1     1       0     0     0   0  0  0  0  0  0                           1000 lea flag, %fx
    0     1     1       0     0     0   0  0  0  0  0  0                           1001 mov %bx, %cx
    0     1     1       0     0     0   0  0  0  0  0  0                           1002 neg %cx
    0     1     1       0     0     1   0  0  0  0  0  0                           1003 add $1, %cx
    1     1     1       0     0     1   0  0  0  0  0  0                           1004 mov $1, 0(%fx,%bx,4)
    1     1     1       0     0     1   0  0  0  0  0  0                           1005 mov %cx, turn
    1     1     1       0     0     1   0  0  0  0  0  0                           1006 mov 0(%fx,%cx,4), %ax
    1     1     1       0     0     1   0  0  1  1  1  0                           1007 test $1, %ax
    1     1     1       0     0     1   0  0  1  1  1  0                           1008 jne .fini
    1     1     1       1     0     1   0  0  1  1  1  0                           1012 mov count, %ax
    1     1     1       2     0     1   0  0  1  1  1  0                           1013 add $1, %ax
    1     1     2       2     0     1   0  0  1  1  1  0                           1014 mov %ax, count
    0     1     2       2     0     1   0  0  1  1  1  0                           1015 mov $0, 0(%fx,%bx,4)
    0     1     2       2     0     1   0  0  1  1  1  0                           1016 mov %cx, turn
    0     1     2       2     0     1   0  0  1  1  1  0                           1017 halt
```

使用 `-i` 参数设置中断间隔，每 5 条指令中断一次
- 线程 1 对 ax 寄存器中的脏数据进行修改，导致 count 最终为错误的 1

```bash
./x86.py -p peterson.s -i 5 -R ax,bx,cx -M flag,turn,count -C -c

# 输出
 flag  turn count      ax    bx    cx   >= >  <= <  != ==        Thread 0                Thread 1         

    0     0     0       0     0     0   0  0  0  0  0  0  
    0     0     0       0     0     0   0  0  0  0  0  0  1000 lea flag, %fx
    0     0     0       0     0     0   0  0  0  0  0  0  1001 mov %bx, %cx
    0     0     0       0     0     0   0  0  0  0  0  0  1002 neg %cx
    0     0     0       0     0     1   0  0  0  0  0  0  1003 add $1, %cx
    1     0     0       0     0     1   0  0  0  0  0  0  1004 mov $1, 0(%fx,%bx,4)
    1     0     0       0     0     0   0  0  0  0  0  0  ------ Interrupt ------  ------ Interrupt ------  
    1     0     0       0     0     0   0  0  0  0  0  0                           1000 lea flag, %fx
    1     0     0       0     0     0   0  0  0  0  0  0                           1001 mov %bx, %cx
    1     0     0       0     0     0   0  0  0  0  0  0                           1002 neg %cx
    1     0     0       0     0     1   0  0  0  0  0  0                           1003 add $1, %cx
    1     0     0       0     0     1   0  0  0  0  0  0                           1004 mov $1, 0(%fx,%bx,4)
    1     0     0       0     0     1   0  0  0  0  0  0  ------ Interrupt ------  ------ Interrupt ------  
    1     1     0       0     0     1   0  0  0  0  0  0  1005 mov %cx, turn
    1     1     0       0     0     1   0  0  0  0  0  0  1006 mov 0(%fx,%cx,4), %ax
    1     1     0       0     0     1   0  0  1  1  1  0  1007 test $1, %ax
    1     1     0       0     0     1   0  0  1  1  1  0  1008 jne .fini
    1     1     0       0     0     1   0  0  1  1  1  0  1012 mov count, %ax
    1     1     0       0     0     1   0  0  0  0  0  0  ------ Interrupt ------  ------ Interrupt ------  
    1     1     0       0     0     1   0  0  0  0  0  0                           1005 mov %cx, turn
    1     1     0       0     0     1   0  0  0  0  0  0                           1006 mov 0(%fx,%cx,4), %ax
    1     1     0       0     0     1   0  0  1  1  1  0                           1007 test $1, %ax
    1     1     0       0     0     1   0  0  1  1  1  0                           1008 jne .fini
    1     1     0       0     0     1   0  0  1  1  1  0                           1012 mov count, %ax
    1     1     0       0     0     1   0  0  1  1  1  0  ------ Interrupt ------  ------ Interrupt ------  
    1     1     0       1     0     1   0  0  1  1  1  0  1013 add $1, %ax
    1     1     1       1     0     1   0  0  1  1  1  0  1014 mov %ax, count
    0     1     1       1     0     1   0  0  1  1  1  0  1015 mov $0, 0(%fx,%bx,4)
    0     1     1       1     0     1   0  0  1  1  1  0  1016 mov %cx, turn
    0     1     1       1     0     1   0  0  1  1  1  0  1017 halt
    0     1     1       0     0     1   0  0  1  1  1  0  ----- Halt;Switch -----  ----- Halt;Switch -----  
    0     1     1       0     0     1   0  0  1  1  1  0  ------ Interrupt ------  ------ Interrupt ------  
    0     1     1       1     0     1   0  0  1  1  1  0                           1013 add $1, %ax
    0     1     1       1     0     1   0  0  1  1  1  0                           1014 mov %ax, count
    0     1     1       1     0     1   0  0  1  1  1  0                           1015 mov $0, 0(%fx,%bx,4)
    0     1     1       1     0     1   0  0  1  1  1  0                           1016 mov %cx, turn
    0     1     1       1     0     1   0  0  1  1  1  0                           1017 halt
```

### 10

当中断间隔为每 4 条指令中断一次时
- 由于 count 的值被及时更新，线程 1 读取新数据，最终 count 的值为正确的 2
- 互斥
- 避免死锁

```bash
./x86.py -p peterson.s -i 4 -R ax,bx,cx -M flag,turn,count -C -c

# 输出
 flag  turn count      ax    bx    cx   >= >  <= <  != ==        Thread 0                Thread 1         

    0     0     0       0     0     0   0  0  0  0  0  0  
    0     0     0       0     0     0   0  0  0  0  0  0  1000 lea flag, %fx
    0     0     0       0     0     0   0  0  0  0  0  0  1001 mov %bx, %cx
    0     0     0       0     0     0   0  0  0  0  0  0  1002 neg %cx
    0     0     0       0     0     1   0  0  0  0  0  0  1003 add $1, %cx
    0     0     0       0     0     0   0  0  0  0  0  0  ------ Interrupt ------  ------ Interrupt ------  
    0     0     0       0     0     0   0  0  0  0  0  0                           1000 lea flag, %fx
    0     0     0       0     0     0   0  0  0  0  0  0                           1001 mov %bx, %cx
    0     0     0       0     0     0   0  0  0  0  0  0                           1002 neg %cx
    0     0     0       0     0     1   0  0  0  0  0  0                           1003 add $1, %cx
    0     0     0       0     0     1   0  0  0  0  0  0  ------ Interrupt ------  ------ Interrupt ------  
    1     0     0       0     0     1   0  0  0  0  0  0  1004 mov $1, 0(%fx,%bx,4)
    1     1     0       0     0     1   0  0  0  0  0  0  1005 mov %cx, turn
    1     1     0       0     0     1   0  0  0  0  0  0  1006 mov 0(%fx,%cx,4), %ax
    1     1     0       0     0     1   0  0  1  1  1  0  1007 test $1, %ax
    1     1     0       0     0     1   0  0  0  0  0  0  ------ Interrupt ------  ------ Interrupt ------  
    1     1     0       0     0     1   0  0  0  0  0  0                           1004 mov $1, 0(%fx,%bx,4)
    1     1     0       0     0     1   0  0  0  0  0  0                           1005 mov %cx, turn
    1     1     0       0     0     1   0  0  0  0  0  0                           1006 mov 0(%fx,%cx,4), %ax
    1     1     0       0     0     1   0  0  1  1  1  0                           1007 test $1, %ax
    1     1     0       0     0     1   0  0  1  1  1  0  ------ Interrupt ------  ------ Interrupt ------  
    1     1     0       0     0     1   0  0  1  1  1  0  1008 jne .fini
    1     1     0       0     0     1   0  0  1  1  1  0  1012 mov count, %ax
    1     1     0       1     0     1   0  0  1  1  1  0  1013 add $1, %ax
    1     1     1       1     0     1   0  0  1  1  1  0  1014 mov %ax, count
    1     1     1       0     0     1   0  0  1  1  1  0  ------ Interrupt ------  ------ Interrupt ------  
    1     1     1       0     0     1   0  0  1  1  1  0                           1008 jne .fini
    1     1     1       1     0     1   0  0  1  1  1  0                           1012 mov count, %ax
    1     1     1       2     0     1   0  0  1  1  1  0                           1013 add $1, %ax
    1     1     2       2     0     1   0  0  1  1  1  0                           1014 mov %ax, count
    1     1     2       1     0     1   0  0  1  1  1  0  ------ Interrupt ------  ------ Interrupt ------  
    0     1     2       1     0     1   0  0  1  1  1  0  1015 mov $0, 0(%fx,%bx,4)
    0     1     2       1     0     1   0  0  1  1  1  0  1016 mov %cx, turn
    0     1     2       1     0     1   0  0  1  1  1  0  1017 halt
    0     1     2       2     0     1   0  0  1  1  1  0  ----- Halt;Switch -----  ----- Halt;Switch -----  
    0     1     2       2     0     1   0  0  1  1  1  0                           1015 mov $0, 0(%fx,%bx,4)
    0     1     2       2     0     1   0  0  1  1  1  0  ------ Interrupt ------  ------ Interrupt ------  
    0     1     2       2     0     1   0  0  1  1  1  0                           1016 mov %cx, turn
    0     1     2       2     0     1   0  0  1  1  1  0                           1017 halt
```

### 11

查看汇编代码 ticket.s 中的指令序列，实现了获取并增加（tciket-and-add）
- `fetchadd %ax, ticket` 将 ticket 的值增加 ax 寄存器中的值，同时将 ticket 的旧值赋给 ax 寄存器
  - 返回旧值，并让值增加一（请求锁）
- ticket 旧值与 turn 比较，确定执行的线程（顺序）
- 进入临界区修改数据，完成后增加 ticket 的值（写一个线程）

使用 ticket 和 turn 确定当前执行的线程，确保所有的线程都可以抢到锁

```
.var ticket
.var turn
.var count

.main
.top	

.acquire
mov $1, %ax
fetchadd %ax, ticket  # grab a ticket 
.tryagain
mov turn, %cx         # check if it's your turn 
test %cx, %ax
jne .tryagain

# critical section
mov  count, %ax       # get the value at the address
add  $1, %ax          # increment it
mov  %ax, count       # store it back

# release lock
mov $1, %ax
fetchadd %ax, turn

# see if we're still looping
sub  $1, %bx
test $0, %bx
jgt .top	

halt
```

### 12

使用默认参数运行
- 每 50 条指令中断一次，因此两个线程按顺序执行，最终 count 的值为 2 
- ticket 和 turn 确定哪个线程执行
- 总共执行了 28 条指令

```bash
./x86.py -p ticket.s -R ax,bx,cx -M ticket,turn,count -C -c -S

#
icount ticket  turn count      ax    bx    cx   >= >  <= <  != ==        Thread 0                Thread 1         

     0     0     0     0       0     0     0   0  0  0  0  0  0  
     0     0     0     0       1     0     0   0  0  0  0  0  0  1000 mov $1, %ax
     1     1     0     0       0     0     0   0  0  0  0  0  0  1001 fetchadd %ax, ticket
     2     1     0     0       0     0     0   0  0  0  0  0  0  1002 mov turn, %cx
     3     1     0     0       0     0     0   1  0  1  0  0  1  1003 test %cx, %ax
     4     1     0     0       0     0     0   1  0  1  0  0  1  1004 jne .tryagain
     5     1     0     0       0     0     0   1  0  1  0  0  1  1005 mov  count, %ax
     6     1     0     0       1     0     0   1  0  1  0  0  1  1006 add  $1, %ax
     7     1     0     1       1     0     0   1  0  1  0  0  1  1007 mov  %ax, count
     8     1     0     1       1     0     0   1  0  1  0  0  1  1008 mov $1, %ax
     9     1     1     1       0     0     0   1  0  1  0  0  1  1009 fetchadd %ax, turn
    10     1     1     1       0    -1     0   1  0  1  0  0  1  1010 sub  $1, %bx
    11     1     1     1       0    -1     0   0  0  1  1  1  0  1011 test $0, %bx
    12     1     1     1       0    -1     0   0  0  1  1  1  0  1012 jgt .top
    13     1     1     1       0    -1     0   0  0  1  1  1  0  1013 halt
    14     1     1     1       0     0     0   0  0  0  0  0  0  ----- Halt;Switch -----  ----- Halt;Switch -----  
    14     1     1     1       1     0     0   0  0  0  0  0  0                           1000 mov $1, %ax
    15     2     1     1       1     0     0   0  0  0  0  0  0                           1001 fetchadd %ax, ticket
    16     2     1     1       1     0     1   0  0  0  0  0  0                           1002 mov turn, %cx
    17     2     1     1       1     0     1   1  0  1  0  0  1                           1003 test %cx, %ax
    18     2     1     1       1     0     1   1  0  1  0  0  1                           1004 jne .tryagain
    19     2     1     1       1     0     1   1  0  1  0  0  1                           1005 mov  count, %ax
    20     2     1     1       2     0     1   1  0  1  0  0  1                           1006 add  $1, %ax
    21     2     1     2       2     0     1   1  0  1  0  0  1                           1007 mov  %ax, count
    22     2     1     2       1     0     1   1  0  1  0  0  1                           1008 mov $1, %ax
    23     2     2     2       1     0     1   1  0  1  0  0  1                           1009 fetchadd %ax, turn
    24     2     2     2       1    -1     1   1  0  1  0  0  1                           1010 sub  $1, %bx
    25     2     2     2       1    -1     1   0  0  1  1  1  0                           1011 test $0, %bx
    26     2     2     2       1    -1     1   0  0  1  1  1  0                           1012 jgt .top
    27     2     2     2       1    -1     1   0  0  1  1  1  0                           1013 halt

STATS:: Instructions    28
STATS:: Emulation Rate  12.61 kinst/sec
```

使用 `-a` 参数设置两个线程各循环 1000 次
- 没有锁（没有轮到）的线程自旋等待，总共执行了 99463 条指令

```bash
./x86.py -p ticket.s -a bx=1000,bx=1000 -R ax,bx,cx -M ticket,turn,count -C -c -S > 2-1000.txt

# 输出
...

STATS:: Instructions    99463
STATS:: Emulation Rate  24.00 kinst/sec
```

[输出结果](threads-locks/2-1000.txt)

### 13

使用 `-t` 参数设置 5 个线程，各运行 1000 次
- 增加了 3 个线程，结果总共执行了 249148 条指令，说明线程花了更多的时间自旋等待

```bash
./x86.py -p ticket.s -t 5 -a bx=1000,bx=1000,bx=1000,bx=1000,bx=1000 -R ax,bx,cx -M ticket,turn,count -C -c -S > 5-1000.txt

# 输出
...

STATS:: Instructions    249148
STATS:: Emulation Rate  22.78 kinst/sec
```

[输出结果](threads-locks/5-1000.txt)

### 14

查看汇编代码 yield.s 中的指令序列
- 和 test-and-set.s 不同，没有锁的线程主动将 CPU 让给其他线程
  - 假设 `yield` 指令能够使一个线程将 CPU 的控制权交给另一个线程
- 避免了自旋等待

```
.var mutex
.var count

.main
.top	

.acquire
mov  $1, %ax        
xchg %ax, mutex     # atomic swap of 1 and mutex
test $0, %ax        # if we get 0 back: lock is free!
je .acquire_done    
yield               # if not, yield and try again
j .acquire
.acquire_done

# critical section
mov  count, %ax     # get the value at the address
add  $1, %ax        # increment it
mov  %ax, count     # store it back

# release lock
mov  $0, mutex

# see if we're still looping
sub  $1, %bx
test $0, %bx
jgt .top	

halt
```

使用默认参数运行 yield.s 和 test-and-set.s 都是按顺序执行，结果相同，不作演示。

当线程能够在中断前主动让出 CPU 时，yield.s 才会节省指令，如果刚中断再让出反而会使得执行的指令更多
- 使用 `-i` 参数指定每 7 条指令中断一次
- yield.s 总共执行 30 条指令，test-and-set.s 总共执行 32 条指令

```bash
# yield.s
./x86.py -p yield.s -i 7 -R ax,bx -M count,mutex -C -c -S

# 输出
icount count mutex      ax    bx   >= >  <= <  != ==        Thread 0                Thread 1         

     0     0     0       0     0   0  0  0  0  0  0  
     0     0     0       1     0   0  0  0  0  0  0  1000 mov  $1, %ax
     1     0     1       0     0   0  0  0  0  0  0  1001 xchg %ax, mutex
     2     0     1       0     0   1  0  1  0  0  1  1002 test $0, %ax
     3     0     1       0     0   1  0  1  0  0  1  1003 je .acquire_done
     4     0     1       0     0   1  0  1  0  0  1  1006 mov  count, %ax
     5     0     1       1     0   1  0  1  0  0  1  1007 add  $1, %ax
     6     1     1       1     0   1  0  1  0  0  1  1008 mov  %ax, count
     7     1     1       0     0   0  0  0  0  0  0  ------ Interrupt ------  ------ Interrupt ------  
     7     1     1       1     0   0  0  0  0  0  0                           1000 mov  $1, %ax
     8     1     1       1     0   0  0  0  0  0  0                           1001 xchg %ax, mutex
     9     1     1       1     0   1  1  0  0  1  0                           1002 test $0, %ax
    10     1     1       1     0   1  1  0  0  1  0                           1003 je .acquire_done
    11     1     1       1     0   1  1  0  0  1  0                           1004 yield
    12     1     1       1     0   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    12     1     0       1     0   1  0  1  0  0  1  1009 mov  $0, mutex
    13     1     0       1    -1   1  0  1  0  0  1  1010 sub  $1, %bx
    14     1     0       1    -1   0  0  1  1  1  0  1011 test $0, %bx
    15     1     0       1    -1   0  0  1  1  1  0  1012 jgt .top
    16     1     0       1    -1   0  0  1  1  1  0  1013 halt
    17     1     0       1     0   1  1  0  0  1  0  ----- Halt;Switch -----  ----- Halt;Switch -----  
    17     1     0       1     0   1  1  0  0  1  0                           1005 j .acquire
    18     1     0       1     0   1  1  0  0  1  0                           1000 mov  $1, %ax
    19     1     0       1     0   1  1  0  0  1  0  ------ Interrupt ------  ------ Interrupt ------  
    19     1     1       0     0   1  1  0  0  1  0                           1001 xchg %ax, mutex
    20     1     1       0     0   1  0  1  0  0  1                           1002 test $0, %ax
    21     1     1       0     0   1  0  1  0  0  1                           1003 je .acquire_done
    22     1     1       1     0   1  0  1  0  0  1                           1006 mov  count, %ax
    23     1     1       2     0   1  0  1  0  0  1                           1007 add  $1, %ax
    24     2     1       2     0   1  0  1  0  0  1                           1008 mov  %ax, count
    25     2     0       2     0   1  0  1  0  0  1                           1009 mov  $0, mutex
    26     2     0       2     0   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    26     2     0       2    -1   1  0  1  0  0  1                           1010 sub  $1, %bx
    27     2     0       2    -1   0  0  1  1  1  0                           1011 test $0, %bx
    28     2     0       2    -1   0  0  1  1  1  0                           1012 jgt .top
    29     2     0       2    -1   0  0  1  1  1  0                           1013 halt

STATS:: Instructions    30
STATS:: Emulation Rate  14.06 kinst/sec

# test-and-set.s
./x86.py -p test-and-set.s -i 7 -R ax,bx -M count,mutex -C -c -S

# 输出
icount count mutex      ax    bx   >= >  <= <  != ==        Thread 0                Thread 1         

     0     0     0       0     0   0  0  0  0  0  0  
     0     0     0       1     0   0  0  0  0  0  0  1000 mov  $1, %ax
     1     0     1       0     0   0  0  0  0  0  0  1001 xchg %ax, mutex
     2     0     1       0     0   1  0  1  0  0  1  1002 test $0, %ax
     3     0     1       0     0   1  0  1  0  0  1  1003 jne  .acquire
     4     0     1       0     0   1  0  1  0  0  1  1004 mov  count, %ax
     5     0     1       1     0   1  0  1  0  0  1  1005 add  $1, %ax
     6     1     1       1     0   1  0  1  0  0  1  1006 mov  %ax, count
     7     1     1       0     0   0  0  0  0  0  0  ------ Interrupt ------  ------ Interrupt ------  
     7     1     1       1     0   0  0  0  0  0  0                           1000 mov  $1, %ax
     8     1     1       1     0   0  0  0  0  0  0                           1001 xchg %ax, mutex
     9     1     1       1     0   1  1  0  0  1  0                           1002 test $0, %ax
    10     1     1       1     0   1  1  0  0  1  0                           1003 jne  .acquire
    11     1     1       1     0   1  1  0  0  1  0                           1000 mov  $1, %ax
    12     1     1       1     0   1  1  0  0  1  0                           1001 xchg %ax, mutex
    13     1     1       1     0   1  1  0  0  1  0                           1002 test $0, %ax
    14     1     1       1     0   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    14     1     0       1     0   1  0  1  0  0  1  1007 mov  $0, mutex
    15     1     0       1    -1   1  0  1  0  0  1  1008 sub  $1, %bx
    16     1     0       1    -1   0  0  1  1  1  0  1009 test $0, %bx
    17     1     0       1    -1   0  0  1  1  1  0  1010 jgt .top
    18     1     0       1    -1   0  0  1  1  1  0  1011 halt
    19     1     0       1     0   1  1  0  0  1  0  ----- Halt;Switch -----  ----- Halt;Switch -----  
    19     1     0       1     0   1  1  0  0  1  0                           1003 jne  .acquire
    20     1     0       1     0   1  1  0  0  1  0                           1000 mov  $1, %ax
    21     1     0       1     0   1  1  0  0  1  0  ------ Interrupt ------  ------ Interrupt ------  
    21     1     1       0     0   1  1  0  0  1  0                           1001 xchg %ax, mutex
    22     1     1       0     0   1  0  1  0  0  1                           1002 test $0, %ax
    23     1     1       0     0   1  0  1  0  0  1                           1003 jne  .acquire
    24     1     1       1     0   1  0  1  0  0  1                           1004 mov  count, %ax
    25     1     1       2     0   1  0  1  0  0  1                           1005 add  $1, %ax
    26     2     1       2     0   1  0  1  0  0  1                           1006 mov  %ax, count
    27     2     0       2     0   1  0  1  0  0  1                           1007 mov  $0, mutex
    28     2     0       2     0   1  0  1  0  0  1  ------ Interrupt ------  ------ Interrupt ------  
    28     2     0       2    -1   1  0  1  0  0  1                           1008 sub  $1, %bx
    29     2     0       2    -1   0  0  1  1  1  0                           1009 test $0, %bx
    30     2     0       2    -1   0  0  1  1  1  0                           1010 jgt .top
    31     2     0       2    -1   0  0  1  1  1  0                           1011 halt

STATS:: Instructions    32
STATS:: Emulation Rate  12.87 kinst/sec
```


### 15

查看汇编代码 test-and-test-and-set.s 中的指令序列
- 和 test-and-set.s 不同，先测试锁（mutex），然后再执行测试并设置
- 如果锁被占用，就不进行交换（将 mutex 的值设置为 1 并获得旧值），节省了一步交换 `xchg` ，但是指令序列变长了

```
.var mutex
.var count

.main
.top	

.acquire
mov  mutex, %ax
test $0, %ax
jne .acquire
mov  $1, %ax        
xchg %ax, mutex     # atomic swap of 1 and mutex
test $0, %ax        # if we get 0 back: lock is free!
jne .acquire        # if not, try again

# critical section
mov  count, %ax     # get the value at the address
add  $1, %ax        # increment it
mov  %ax, count     # store it back

# release lock
mov  $0, mutex

# see if we're still looping
sub  $1, %bx
test $0, %bx
jgt .top	

halt
```