

```python
#
# MAIN PROGRAM
#
parser = OptionParser()
# 随机种子
parser.add_option('-s', '--seed',        default=0,     help='the random seed',                        action='store', type='int', dest='seed')
# 作业数量，默认为 3
parser.add_option('-j', '--job_num',     default=3,     help='number of jobs in the system',           action='store', type='int', dest='job_num')
# 作业最大长度，默认为 100
parser.add_option('-R', '--max_run',     default=100,   help='max run time of random-gen jobs',        action='store', type='int', dest='max_run')
# 
parser.add_option('-W', '--max_wset',    default=200,   help='max working set of random-gen jobs',     action='store', type='int', dest='max_wset')
# 作业列表，a:运行时间:作业长度
parser.add_option('-L', '--job_list',    default='',    help='provide a comma-separated list of job_name:run_time:working_set_size (e.g., a:10:100,b:10:50 means 2 jobs with run-times of 10, the first (a) with working set size=100, second (b) with working set size=50)', action='store', type='string', dest='job_list')
# 每个 CPU 都进行调度
parser.add_option('-p', '--per_cpu_queues', default=False, help='per-CPU scheduling queues (not one)', action='store_true',        dest='per_cpu_queues')
# 允许作业在哪些 CPU 上运行，a:0.1.2
parser.add_option('-A', '--affinity',    default='',    help='a list of jobs and which CPUs they can run on (e.g., a:0.1.2,b:0.1 allows job a to run on CPUs 0,1,2 but b only on CPUs 0 and 1', action='store', type='string', dest='affinity')
# CPU 数量，默认为 2
parser.add_option('-n', '--num_cpus',    default=2,     help='number of CPUs',                         action='store', type='int', dest='num_cpus')
# 时间片长度，默认为 10
parser.add_option('-q', '--quantum',     default=10,    help='length of time slice',                   action='store', type='int', dest='time_slice')
# 偷窥其他 CPU 的时间间隔，默认为 30
parser.add_option('-P', '--peek_interval', default=30,  help='for per-cpu scheduling, how often to peek at other schedule queue; 0 turns this off', action='store', type='int', dest='peek_interval')
# 填充缓存所需的时间，默认为 10
parser.add_option('-w', '--warmup_time', default=10,    help='time it takes to warm cache',            action='store', type='int', dest='warmup_time')
# 使用缓存加速多少，默认为 2
parser.add_option('-r', '--warm_rate', default=2,     help='how much faster to run with warm cache', action='store', type='int', dest='warm_rate')
# 缓存大小，默认为 100
parser.add_option('-M', '--cache_size',  default=100,   help='cache size',                             action='store', type='int', dest='cache_size')
# CPU 是否随机获取作业
parser.add_option('-o', '--rand_order',  default=False, help='has CPUs get jobs in random order',      action='store_true',        dest='random_order')
# 统计多少作业被调度
parser.add_option('-t', '--trace',       default=False, help='enable basic tracing (show which jobs got scheduled)',      action='store_true',        dest='trace')
# 统计每个作业还有多少剩余时间
parser.add_option('-T', '--trace_time_left', default=False, help='trace time left for each job',       action='store_true',        dest='trace_time_left')
# 跟踪缓存状态
parser.add_option('-C', '--trace_cache', default=False, help='trace cache status (warm/cold) too',     action='store_true',        dest='trace_cache')
# 跟踪调度状态
parser.add_option('-S', '--trace_sched', default=False, help='trace scheduler state',                  action='store_true',        dest='trace_sched')
# 计算答案
parser.add_option('-c', '--compute',     default=False, help='compute answers for me',                 action='store_true',        dest='solve')

(options, args) = parser.parse_args()

random_seed(options.seed)
```

### 1

### 2

### 3

### 4

### 5

### 6

### 7

### 8

### 9
