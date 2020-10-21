## 4 Process

首先了解一下程序的参数和默认值

```python
parser = OptionParser()
# 随机生成任务（指令或 I/O）
parser.add_option('-s', '--seed', default=0, help='the random seed', action='store', type='int', dest='seed')
# 提供更精细的控制
parser.add_option('-P', '--program', default='', help='more specific controls over programs', action='store', type='string', dest='program')
# 进程列表，指令数量:使用 CPU 的概率
parser.add_option('-l', '--processlist', default='', help='a comma-separated list of processes to run, in the form X1:Y1,X2:Y2,... where X is the number of instructions that process should run, and Y the chances (from 0 to 100) that an instruction will use the CPU or issue an IO', action='store', type='string', dest='process_list')
# I/O 长度
parser.add_option('-L', '--iolength', default=5, help='how long an IO takes', action='store', type='int', dest='io_length')
# 进程切换方式，默认为请求 I/O 后切换
parser.add_option('-S', '--switch', default='SWITCH_ON_IO', help='when to switch between processes: SWITCH_ON_IO, SWITCH_ON_END', action='store', type='string', dest='process_switch_behavior')
# IO 完成后的行为，默认不立即切换回该进程
parser.add_option('-I', '--iodone', default='IO_RUN_LATER', help='type of behavior when IO ends: IO_RUN_LATER, IO_RUN_IMMEDIATE', action='store', type='string', dest='io_done_behavior')
# 计算答案
parser.add_option('-c', help='compute answers for me', action='store_true', default=False, dest='solve')
# 打印统计结果
parser.add_option('-p', '--printstats', help='print statistics at end; only useful with -c flag (otherwise stats are not printed)', action='store_true', default=False, dest='print_stats')
(options, args) = parser.parse_args()

random_seed(options.seed)
```

1. 程序有四种状态
  - `RUNNING`：使用 CPU
  - `READY`：等待
  - `WAITING`：就绪
  - `DONE`：完成
2. 系统在当前进程完成或请求 I/O 时切换进程
3. I/O 完成后，请求 I/O 的进程将延迟运行（即不立即切换回它）

### 1

没有 I/O 操作，两个进程按顺序执行，CPU 利用率为 100%

- CPU 运行 5 条指令（进程0）
- CPU 运行 5 条指令（进程1）

```bash
./process-run.py -l 5:100,5:100 -c -p

# 输出
Time    PID: 0    PID: 1       CPU       IOs
  1    RUN:cpu     READY         1          
  2    RUN:cpu     READY         1          
  3    RUN:cpu     READY         1          
  4    RUN:cpu     READY         1          
  5    RUN:cpu     READY         1          
  6       DONE   RUN:cpu         1          
  7       DONE   RUN:cpu         1          
  8       DONE   RUN:cpu         1          
  9       DONE   RUN:cpu         1          
 10       DONE   RUN:cpu         1          

Stats: Total Time 10
Stats: CPU Busy 10 (100.00%)
Stats: IO Busy  0 (0.00%)
```

### 2

默认的设置是 I/O 请求之后再切换进程，而第一个进程没有 I/O ，所以第二个进程得等第一个进程完成后开始请求 I/O， 执行 I/O 时没有使用 CPU

- CPU 运行 4 条指令（进程0）
- CPU 发出 I/O 请求（进程1）
- 4 I/O（进程1）
- 1 完成（进程1）

```bash
./process-run.py -l 4:100,1:0 -c -p

# 输出
Time    PID: 0    PID: 1       CPU       IOs
  1    RUN:cpu     READY         1          
  2    RUN:cpu     READY         1          
  3    RUN:cpu     READY         1          
  4    RUN:cpu     READY         1          
  5       DONE    RUN:io         1          
  6       DONE   WAITING                   1
  7       DONE   WAITING                   1
  8       DONE   WAITING                   1
  9       DONE   WAITING                   1
 10*      DONE      DONE         1

Stats: Total Time 10
Stats: CPU Busy 6 (60.00%)
Stats: IO Busy  4 (40.00%)
```

### 3

第一个进程先发出 I/O 请求，然后切换进程，CPU 执行指令的同时进行 I/O 操作，两个进程同时运行

- CPU 发出 I/O 请求（进程0）
  - 切换进程
- CPU 运行 4 条指令（进程1），同时执行 I/O 操作
  - 4 I/O（进程0）
- 1 完成（进程0）

```bash
./process-run.py -l 1:0,4:100 -c -p

# 输出
Time    PID: 0    PID: 1       CPU       IOs
  1     RUN:io     READY         1          
  2    WAITING   RUN:cpu         1         1
  3    WAITING   RUN:cpu         1         1
  4    WAITING   RUN:cpu         1         1
  5    WAITING   RUN:cpu         1         1
  6*      DONE      DONE         1

Stats: Total Time 6
Stats: CPU Busy 6 (100.00%)
Stats: IO Busy  4 (66.67%)
```

### 4

在 I/O 完成之后切换进程（而不是请求 I/O 后就切换），先执行第一个进程的 I/O 请求并等待 I/O 完成，完成后切换进程，执行 I/O 时没有使用 CPU

- CPU 发出 I/O 请求（进程0）
- 4 I/O 操作（进程0）
  - 完成后切换进程
- CPU 运行 4 条指令（进程1）

```bash
./process-run.py -l 1:0,4:100 -S SWITCH_ON_END -c -p

# 输出
Time    PID: 0    PID: 1       CPU       IOs
  1     RUN:io     READY         1          
  2    WAITING     READY                   1
  3    WAITING     READY                   1
  4    WAITING     READY                   1
  5    WAITING     READY                   1
  6*      DONE   RUN:cpu         1          
  7       DONE   RUN:cpu         1          
  8       DONE   RUN:cpu         1          
  9       DONE   RUN:cpu         1          

Stats: Total Time 9
Stats: CPU Busy 5 (55.56%)
Stats: IO Busy  4 (44.44%)
```

### 5

和 3 一样

- CPU 发出 I/O 请求（进程0）
  - 切换进程
- CPU 运行 4 条指令（进程1），同时执行 I/O 操作
  - 4 I/O（进程0）
- 1 完成（进程0）

```bash
./process-run.py -l 1:0,4:100 -S SWITCH_ON_IO -c -p

# 输出
Time    PID: 0    PID: 1       CPU       IOs
  1     RUN:io     READY         1          
  2    WAITING   RUN:cpu         1         1
  3    WAITING   RUN:cpu         1         1
  4    WAITING   RUN:cpu         1         1
  5    WAITING   RUN:cpu         1         1
  6*      DONE      DONE         1

Stats: Total Time 6
Stats: CPU Busy 6 (100.00%)
Stats: IO Busy  4 (66.67%)
```

### 6

进程 0 请求 I/O，然后切换进程，`IO_RUN_LATER` 表示 I/O 完成后不立即切换回该进程。因此，按顺序执行其他进程，然后再切换回进程 0

- CPU 发出 I/O 请求（进程0）
  - 切换进程
- CPU 运行 5 条指令（进程1），同时进行 I/O 操作
  - 4 I/O（进程0）
  - 1 完成，进程0切换至准备状态，还有 2 次 I/O 请求
- CPU 运行 5 条指令（进程2）
- CPU 运行 5 条指令（进程3）
  - 切换进程
- CPU 发出 I/O 请求（进程0）
- 4 I/O 操作（进程0）
- CPU 发出 I/O 请求（进程0）
- 4 I/O 操作（进程0）
- 1 完成（进程0）

```bash
./process-run.py -l 3:0,5:100,5:100,5:100 -S SWITCH_ON_IO -I IO_RUN_LATER -c -p

# 输出
Time    PID: 0    PID: 1    PID: 2    PID: 3       CPU       IOs
  1     RUN:io     READY     READY     READY         1          
  2    WAITING   RUN:cpu     READY     READY         1         1
  3    WAITING   RUN:cpu     READY     READY         1         1
  4    WAITING   RUN:cpu     READY     READY         1         1
  5    WAITING   RUN:cpu     READY     READY         1         1
  6*     READY   RUN:cpu     READY     READY         1          
  7      READY      DONE   RUN:cpu     READY         1          
  8      READY      DONE   RUN:cpu     READY         1          
  9      READY      DONE   RUN:cpu     READY         1          
 10      READY      DONE   RUN:cpu     READY         1          
 11      READY      DONE   RUN:cpu     READY         1          
 12      READY      DONE      DONE   RUN:cpu         1          
 13      READY      DONE      DONE   RUN:cpu         1          
 14      READY      DONE      DONE   RUN:cpu         1          
 15      READY      DONE      DONE   RUN:cpu         1          
 16      READY      DONE      DONE   RUN:cpu         1          
 17     RUN:io      DONE      DONE      DONE         1          
 18    WAITING      DONE      DONE      DONE                   1
 19    WAITING      DONE      DONE      DONE                   1
 20    WAITING      DONE      DONE      DONE                   1
 21    WAITING      DONE      DONE      DONE                   1
 22*    RUN:io      DONE      DONE      DONE         1          
 23    WAITING      DONE      DONE      DONE                   1
 24    WAITING      DONE      DONE      DONE                   1
 25    WAITING      DONE      DONE      DONE                   1
 26    WAITING      DONE      DONE      DONE                   1
 27*      DONE      DONE      DONE      DONE         1

Stats: Total Time 27
Stats: CPU Busy 19 (70.37%)
Stats: IO Busy  12 (44.44%)
```

### 7

进程切换方式，默认为 `SWITCH_ON_IO` CPU 发出 I/O 请求后切换进程

I/O 完成后的行为，默认为 `IO_RUN_LATER` I/O 操作完成后不立即切换回该进程

50% 的概率使用 CPU 或请求 I/O

#### 7.1

- CPU 执行 1 条指令（进程0）
- CPU 发出 I/O 请求（进程0）
  - 切换进程
- CPU 执行 3 条指令（进程1），同时进行 I/O 操作
  - 3 I/O（进程0）
- 1 I/O（进程0），**这里执行 I/O 的同时占用了 CPU，开始迷惑.jpg**
- CPU 发出 I/O 请求（进程0）
- 4 I/O
- 1 完成

```bash
./process-run.py -s 1 -l 3:50,3:50 -c -p

# 输出
Time    PID: 0    PID: 1       CPU       IOs
  1    RUN:cpu     READY         1          
  2     RUN:io     READY         1          
  3    WAITING   RUN:cpu         1         1
  4    WAITING   RUN:cpu         1         1
  5    WAITING   RUN:cpu         1         1
  6    WAITING      DONE         1         1
  7*    RUN:io      DONE         1          
  8    WAITING      DONE                   1
  9    WAITING      DONE                   1
 10    WAITING      DONE                   1
 11    WAITING      DONE                   1
 12*      DONE      DONE         1

Stats: Total Time 12
Stats: CPU Busy 8 (66.67%)
Stats: IO Busy  8 (66.67%)
```

#### 7.2

- CPU 发出 I/O 请求（进程0）
  - 切换进程
- CPU 执行 1 条指令（进程1）
  - 1 I/O（进程0）
- CPU 发出 I/O 请求（进程1）
  - 1 I/O（进程0）
- 2 I/O
  - 进程0
  - 进程1
- CPU 发出 I/O 请求（进程0）
  - 1 I/O（进程1）
- 1 I/O
  - 进程0
  - 进程1
- CPU 发出 I/O 请求（进程1）
  - 1 I/O（进程0）
- 2 I/O
  - 进程0
  - 进程1
- CPU 执行 1 条指令（进程0）
  - 1 I/O（进程1）
- 1 I/O（进程1），**这里也执行 I/O 的同时占用了 CPU**
- 1 完成

```bash
./process-run.py -s 2 -l 3:50,3:50 -c -p

# 输出
Time    PID: 0    PID: 1       CPU       IOs
  1     RUN:io     READY         1          
  2    WAITING   RUN:cpu         1         1
  3    WAITING    RUN:io         1         1
  4    WAITING   WAITING                   2
  5    WAITING   WAITING                   2
  6*    RUN:io   WAITING         1         1
  7    WAITING   WAITING                   2
  8*   WAITING    RUN:io         1         1
  9    WAITING   WAITING                   2
 10    WAITING   WAITING                   2
 11*   RUN:cpu   WAITING         1         1
 12       DONE   WAITING         1         1
 13*      DONE      DONE         1

Stats: Total Time 13
Stats: CPU Busy 8 (61.54%)
Stats: IO Busy  11 (84.62%)
```

#### 7.3

- CPU 执行 1 条指令（进程0）
- CPU 发出 I/O 请求（进程0）
  - 切换进程
- CPU 发出 I/O 请求（进程1）
  - 1 I/O（进程0）
- 3 I/O
  - 进程0
  - 进程1
- CPU 执行 1 条指令（进程0）
  - 1 I/O（进程1）
- CPU 发出 I/O 请求（进程1）
- 4 I/O（进程1）
- 1 完成

```bash
./process-run.py -s 3 -l 3:50,3:50 -c -p

# 输出
Time    PID: 0    PID: 1       CPU       IOs
  1    RUN:cpu     READY         1          
  2     RUN:io     READY         1          
  3    WAITING    RUN:io         1         1
  4    WAITING   WAITING                   2
  5    WAITING   WAITING                   2
  6    WAITING   WAITING                   2
  7*   RUN:cpu   WAITING         1         1
  8*      DONE    RUN:io         1          
  9       DONE   WAITING                   1
 10       DONE   WAITING                   1
 11       DONE   WAITING                   1
 12       DONE   WAITING                   1
 13*      DONE   RUN:cpu         1          

Stats: Total Time 13
Stats: CPU Busy 6 (46.15%)
Stats: IO Busy  9 (69.23%)
```