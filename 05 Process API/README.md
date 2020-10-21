## 5 Process API

首先了解一下程序的参数和默认值

```python
parser = OptionParser()
# 随机种子
parser.add_option('-s', '--seed', default=-1, help='the random seed', action='store', type='int', dest='seed')
# 创建新进程的概率
parser.add_option('-f', '--forks', default=0.7, help='percent of actions that are forks (not exits)', action='store', type='float', dest='fork_percentage')
# 进程创建与退出列表
parser.add_option('-A', '--action_list', default='', help='action list, instead of randomly generated ones (format: a+b,b+c,b- means a fork b, b fork c, b exit)', action='store', type='string', dest='action_list')
# 进程创建与退出的次数，默认为 5
parser.add_option('-a', '--actions', default=5, help='number of forks/exits to do', action='store', type='int', dest='actions')
# 打印树形结构
parser.add_option('-t', '--show_tree', help='show tree (not actions)', action='store_true', default=False, dest='show_tree')
# 打印风格，默认的最好看【迫真
parser.add_option('-P', '--print_style', help='tree print style (basic, line1, line2, fancy)', action='store', type='string', default='fancy', dest='print_style')
# 只打印最终结果
parser.add_option('-F', '--final_only', help='just show final state', action='store_true', default=False, dest='just_final')
# 只退出叶子进程
parser.add_option('-L', '--leaf_only', help='only leaf processes exit', action='store_true', default=False, dest='leaf_only')
# 父进程退出后，转换为和父进程同级的进程（成为父进程所在级别的进程）
parser.add_option('-R', '--local_reparent', help='reparent to local parent', action='store_true', default=False, dest='local_reparent')
# 计算答案
parser.add_option('-c', '--compute', help='compute answers for me', action='store_true', default=False, dest='solve')

(options, args) = parser.parse_args()
```

使用 `fork()` 创建新进程，生成的进程结构很容易根据流程推导出来

### 1

进程 a 的进程树
- 进程 a 创建子进程 b
- 进程 a 创建子进程 c
- 子进程 b 创建子进程 d
- 子进程 b 的子进程 d 退出
- 进程 a 创建子进程 e

```bash
./fork.py -s 4 -t -c

# 输出（省略参数输出）
                           Process Tree:
                               a

Action: a forks b
                               a
                               └── b
Action: a forks c
                               a
                               ├── b
                               └── c
Action: b forks d
                               a
                               ├── b
                               │   └── d
                               └── c
Action: d EXITS
                               a
                               ├── b
                               └── c
Action: a forks e
                               a
                               ├── b
                               ├── c
                               └── e
```

### 2

关于 `-R` 参数的作用，父进程退出后，转换为和父进程同级的进程

> reparent to local parent

原始的进程树创建过程，不使用 `-R` 参数

```bash
./fork.py -A a+b,a+c,b+d,b+e,e+f,e- -c -t

# 输出（省略参数输出）
                           Process Tree:
                               a

Action: a forks b
                               a
                               └── b
Action: a forks c
                               a
                               ├── b
                               └── c
Action: b forks d
                               a
                               ├── b
                               │   └── d
                               └── c
Action: b forks e
                               a
                               ├── b
                               │   ├── d
                               │   └── e
                               └── c
Action: e forks f
                               a
                               ├── b
                               │   ├── d
                               │   └── e
                               │       └── f
                               └── c
Action: e EXITS
                               a
                               ├── b
                               │   └── d
                               ├── c
                               └── f    <---- 父进程 e 退出后， f 成为进程 a 的子进程
```

使用 `-R` 参数

```bash
./fork.py -A a+b,a+c,b+d,b+e,e+f,e- -c -t -R

# 输出（省略参数输出）
                           Process Tree:
                               a

Action: a forks b
                               a
                               └── b
Action: a forks c
                               a
                               ├── b
                               └── c
Action: b forks d
                               a
                               ├── b
                               │   └── d
                               └── c
Action: b forks e
                               a
                               ├── b
                               │   ├── d
                               │   └── e
                               └── c
Action: e forks f
                               a
                               ├── b
                               │   ├── d
                               │   └── e
                               │       └── f
                               └── c
Action: e EXITS
                               a
                               ├── b
                               │   ├── d
                               │   └── f    <---- 父进程 e 退出后， f 成为进程 e 这一级的进程
                               └── c
```