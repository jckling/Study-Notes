# Redis

Redis 是一个开源（BSD 许可）的内存数据结构存储，用作数据库、缓存、消息代理和流引擎。Redis 提供多种数据结构，例如字符串（strings）、哈希表（hashes）、列表（lists）、集合（sets）、支持范围查询的有序集合（sorted sets）、位图（bitmaps）、基数统计（hyperloglogs）、地理空间索引（geospatial indexes）和流（streams）。

Redis 内置了复制（replication）、Lua 脚本（Lua scripting）、LRU 淘汰（LRU eviction）、事务（transactions）和不同级别的磁盘持久性（on-disk persistence），并通过 Redis 哨兵（Sentinel）和 Redis 集群（Cluster）自动分区提供高可用性。

## NoSQL

非关系型数据库

数据库比较

| Name       | Type                                  | Data storage options                                         | Query types                                                  | Additional features                                          |
| ---------- | ------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Redis      | In-memory non-relational database     | Strings, lists, sets, hashes, sorted sets                    | Commands for each data type for common access patterns, with bulk operations, and partial transaction support | Publish/Subscribe, master/slave replication, disk persistence, scripting (stored procedures) |
| memcached  | In-memory key-value cache             | Mapping of keys to values                                    | Commands for create, read, update, delete, and a few others  | Multithreaded server for additional performance              |
| MySQL      | Relational database                   | Databases of tables of rows, views over tables, spatial and third-party extensions | SELECT, INSERT, UPDATE, DELETE, functions, stored procedures | ACID compliant (with InnoDB), master/slave and master/master replication |
| PostgreSQL | Relational database                   | Databases of tables of rows, views over tables, spatial and third-party extensions, customizable types | SELECT, INSERT, UPDATE, DELETE, built-in functions, custom stored procedures | ACID compliant, master/slave replication, multi-master replication (third party) |
| MongoDB    | On-disk non-relational document store | Databases of tables of schema-less BSON documents            | Commands for create, read, update, delete, conditional queries, and more | Supports map-reduce operations, master/slave replication, sharding, spatial indexes |

## 数据结构

### 简单动态字符串（simple dynamic string，SDS）

C 语言的字符串不足之处以及可以改进的地方：
- 获取字符串长度的时间复杂度为  O(N)；
- 字符串的结尾以 `\0` 字符标识，而且字符必须符合某种编码（比如 ASCII），只能保存文本数据；
- 字符串操作函数不高效且不安全，比如可能会发生缓冲区溢出，从而造成程序运行终止；

```c++
struct sdshdr {
    // 字符串长度
    int len;

    // 空闲字符长度
    int free;

    // 字符数组
    char[] buf;
};
```

优点
- 获取字符串长度 O(1) 时间复杂度
- 不会发生缓冲区溢出，先检查空间大小再决定是否自动扩容
- 节省内存空间，减少修改时的内存重分配次数
  - 空间预分配：小于 1M 成倍分配，大于则分配 1M
  - 惰性空间释放：不会立即回收多出来的字节，而是用 free 来记录未使用空间
- 可以保存任意二进制数据，并且是二进制安全的 
- 最大长度 512 M

### 双向链表

优点
- 双向：节点获取前驱或后继只需要 O(1) 时间复杂度
- 头指针、尾指针：获取头节点和尾节点只需要 O(1) 时间复杂度
- 无环：头指针的前驱和尾指针的后继指向 NULL
- 长度记录：获取链表长度只需要 O(1) 时间复杂度
- 多态：可保存不同类型的值

缺点
- 获取中间节点需要逐个遍历

### 压缩列表（ziplist）

优点
- 由连续内存块组成的顺序型数据结构实现
- 节约内存，针对不同 encoding 细化存储大小
- 获取第一个元素和最后一个元素只需要 O(1) 时间复杂度

- 缺点
  - 获取中间元素只能逐个查找 O(N)
  - 连锁更新：第一个节点的扩容导致后续所有节点的扩容（内存空间重新多次分配）

### 快速列表（quicklist）

双向链表 + 压缩列表，快表是一个链表，但每个元素是一个压缩列表

优点
- 规避潜在的连锁更新

缺点
- 没有解决连锁更新问题

### 紧凑列表（listpack）

优点
- 解决了连锁更新问题，不再记录上一节点的长度

### 哈希表/字典（dict）

哈希表
- 查询数据 O(1) 时间复杂度

缺点
  - 哈希冲突：链式哈希

### 整数集合（intset）

使用数组实现
- 有序、无重复
- 节约内存

缺点
- 只支持升级（upgrade）操作

### 跳跃表（skiplist）

基本思想：将有序链表中的一些节点分层，每一层都是一个有序链表。

优点
- 支持平均 O(logN)/最坏 O(N) 复杂度的节点查找，可以二分
- 支持随机操作
- 可以通过顺序操作来批量处理节点

相比红黑树/平衡树：
1. 性能考虑：插入速度非常快，不需要进行旋转等操作来维护平衡性；查找/插入/删除平均复杂度均为 O(logN)
2. 实现考虑：在复杂度与红黑树相同的情况下，跳跃表实现起来更简单，看起来也更加直观；
3. 支持无锁操作

## 数据类型

### 基本数据类型

| Structure type    | What it contains                                             | Structure read/write ability                                 |
| ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| STRING            | Strings, integers, or floating-point values                  | Operate on the whole string, parts, increment/ decrement the integers and floats |
| LIST              | Linked list of strings                                       | Push or pop items from both ends, trim based on offsets, read individual or multiple items, find or remove items by value |
| SET               | Unordered collection of unique strings                       | Add, fetch, or remove individual items, check membership, intersect, union, difference, fetch random items |
| HASH              | Unordered hash table of keys to values                       | Add, fetch, or remove individual items, fetch the whole hash |
| ZSET (sorted set) | Ordered mapping of string members to floating-point scores, ordered by score | Add, fetch, or remove individual values, fetch items based on score ranges or member value |

![](images/20220515133524.png)

#### String（字符串）

![](images/20220515154159.png)

常用场景
- 缓存
- 计数器：粉丝数、关注数
- session 共享

数据结构
- SDS

#### List（列表）

![](images/20220515154242.png)

常用场景
- 时间轴
- 粉丝列表、关注列表
- 消息队列

数据结构
- 双向链表 -> 快速列表
- 压缩列表：当列表只包含少量的列表项，且每个列表项都是小整数值或长度较短的字符串

#### Hash（哈希表）

![](images/20220515154401.png)

常用场景
- 缓存：比 string 更节省空间，用户信息、视频信息（经常变动的对象信息存储）

数据结构
- 哈希表（2 个）
- 压缩列表：当哈希表只包含少量的键值对，且每个键值对的键和值都是小整数值或长度较短的字符串

渐进式 rehash：避免集中消耗资源导致无法响应
- 缩容或扩容
- `负载因子=已保存节点数量/哈希表大小`
- 用户操作时（增删改查），顺便迁移数据

#### Set（无序集合）

![](images/20220515154323.png)

常用场景
- 标签
- 收藏
- 顶踩

数据结构
- 整数集合：只包含整数且数量不多
- 哈希表

#### ZSet（有序集合）

![](images/20220515154512.png)

常用场景
- 排行榜

数据结构
- 压缩列表
- 哈希表 + 跳跃表

### 扩展数据类型

#### BitMap（位图）

基于 String 基本类型实现，用于统计二值状态，将字节数组的每一位表示一个元素的二元状态。

常用场景
- 登录/未登录、打卡/未打卡、活跃/非活跃

#### HyperLogLog（基数统计）

基于 String 基本类型实现，用于统计计数，当集合元素数量非常多时，它计算基数所需的空间总是固定的。

常用场景
- 注册 IP 数、访问 IP 数、页面 UV、在线用户数、共同好友数

优点
- 节约内存

#### Geo（地理空间）

基于 Zset 有序集合基本类型实现，地理空间索引，使用 GeoHash 编码将经纬度转换为排序集合中的权重，支持查找给定地理半径内的位置。

#### Stream（流）

类似于仅附加日志，用于按事件发生的顺序记录事件。

常用场景
- 支持多播的可持久化消息队列
- 实时通信、大数据分析、异地数据备份

## 持久化

### RDB

> Redis DataBase

内存快照，RDB 持久化是把当前进程数据生成快照保存到磁盘上，由于是某一时刻的快照，因此快照中的值要早于或者等于内存中的值。

核心思路：写时复制（copy-on-write），只有写入时才进行复制操作。

![](images/20220515170008.png)

#### 触发方式

手动触发
- `save` 命令：阻塞当前 Redis 服务器，直到 RDB 过程完成为止，对于内存占用比较大的实例会造成长时间阻塞，线上环境不建议使用
- `bgsave` 命令：Redis 进程执行 fork 操作创建子进程，RDB 持久化过程由子进程负责，完成后自动结束。阻塞只发生在 fork 阶段，一般时间很短


自动触发
- redis.conf 中配置 `save m n`，即 m 秒内有 n 次修改时
- 主从复制，从节点从主节点进行全量复制
- `debug reload` 命令：重新加载 Redis
- `shutdown` 命令：没有开启 AOF 持久化时

#### 配置

```sh
# 周期性执行条件的设置格式为
save <seconds> <changes>

# 默认的设置为：
save 900 1
save 300 10
save 60 10000

# 以下设置方式为关闭 RDB 快照功能
save ""

# 文件名称
dbfilename dump.rdb

# 文件保存路径
dir /home/work/app/redis/data/

# 如果持久化出错，主进程是否停止写入
stop-writes-on-bgsave-error yes

# 是否压缩
rdbcompression yes

# 导入时是否检查
rdbchecksum yes
```

#### 优缺点

优点
- 某个时间点的快照，默认使用 LZF 算法压缩，适用于备份，全量复制
- Redis 加载 RDB 文件恢复要远远快于 AOF

缺点
- 实时性，无法做到秒级的持久化
- 每次调用 `bgsave` 都要 fork 子进程，阻塞主进程或开销大
- RDB 文件是二进制的，不可读
- 版本兼容问题

### AOF

核心思路：写后日志，即先写内存再写日志

![](images/20220515165954.png)

#### 实现

AOF 日志记录 Redis 的每个写命令，步骤分为：命令追加（append）、文件写入（write）和文件同步（sync）。

三种写回策略

![](images/20220515165103.png)

#### 配置

```sh
# appendonly 参数开启 AOF 持久化
appendonly yes

# AOF 持久化的文件名，默认是 appendonly.aof
appendfilename "appendonly.aof"

# AOF 文件的保存位置和 RDB 文件的位置相同，都是通过 dir 参数设置的
dir ./

# 同步策略
# appendfsync always
appendfsync everysec
# appendfsync no

# aof 重写期间是否同步
no-appendfsync-on-rewrite no

# 重写触发配置
auto-aof-rewrite-percentage 100  # 文件大小差值
auto-aof-rewrite-min-size 64mb   # 重写时的文件大小

# 加载 aof 出错如何处理
aof-load-truncated yes

# 文件重写策略
aof-rewrite-incremental-fsync yes
```

#### AOF 重写

AOF 文件记录写命令，因此会随着时间增长。

通过创建新的 AOF 文件替换
- fork 子进程 `bgrewriteaof`，阻塞主进程
- 将内存拷贝给子进程
- 重写完毕后修改文件名替换

![](images/20220515165459.png)

重写时有新的输入写入
- 记录在旧文件和重写缓冲区
- 子进程完成重写后，再写入重写缓冲区的内容

重写期间发生宕机
- 重写文件未被替换，仍然使用旧文件

#### 优缺点

优点
- 避免额外的检查开销：记录日志时不用再检查命令
- 不阻塞当前的写操作

缺点
- 如果命令执行完成，写日志之前宕机了，会丢失数据
- 主线程写磁盘压力大，导致写盘慢，阻塞后续操作

### RDB + AOF 混合方式

内存快照以一定的频率执行，在两次快照之间，使用 AOF 日志记录这期间的所有命令操作。
- 快照不用很频繁地执行，这就避免了频繁 fork 对主线程的影响
- AOF 日志也只用记录两次快照间的操作，不需要记录所有操作了，因此就不会出现文件过大的情况了，也可以避免重写开销

![](images/20220515170222.png)

### 恢复

AOF 实时性更强，因此优先加载 AOF 文件

![](images/20220515170321.png)

## 消息传递（发布/订阅）

消息队列有以下三种实现方式
1. List
2. Stream
3. Pub/Sub

> Redis 发布订阅（pub/sub）是一种消息通信模式：发送者（pub）发送消息，订阅者（sub）接收消息。

Redis 的 SUBSCRIBE 命令可以让客户端订阅任意数量的频道， 每当有新信息发送到被订阅的频道时， 信息就会被发送给所有订阅指定频道的客户端。

### 基于频道（Channel）

发布者可以向指定频道发送消息，订阅者可以订阅一个或者多个频道，所有订阅频道的订阅者都会收到消息。

![](images/20220515192849.png)

```sh
# 发布消息
publish channel message

# 订阅频道
subscribe channel1 [channel2 ...]

# 取消订阅
unsubscribe channel1 [channel2 ...]
```

底层使用哈希表实现，键是频道信息，值是订阅者链表。

![](images/20220515194303.png)

### 基于模式（Pattern）

当有信息发送到 tweet.shop.kindle 频道时，除了发送给 clientX 和 clientY 之外，还会发送给订阅 tweet.shop.* 模式的 client123 和 client256。

![](images/20220515193454.png)

```sh
# 发布消息
publish channel message

# 订阅模式
psubscribe c? b* d?*

# 退订
punsubscribe [pattern [pattern ...]]
```

注意：
- 如果客户端执行了 `subscribe c1` 和 `psubscribe c?*`，向 `c1` 发送消息时，客户端会收到两条，但类型不同：message、pmessage
- `punsubscribe *` 无法退订 `c*` 模式，必须使用 `punsubscribe c*` 退订
- `punsubscribe` 退订所有模式

底层使用 `pubsubPattern` 节点的链表实现，保存和模式有关的信息。

![](images/20220515194445.png)

## 事务

Redis 的事务就是一次性、顺序性、排他性地执行一个队列中的一系列命令。单条命令具有原子性，但是多条命令保证执行顺序、不保证执行的原子性。

### 命令

- `MULTI`：开启事务，将后续命令放入队列
- `EXEC`：执行事务中的所有操作命令
- `DISCARD`：取消事务
- `WATCH`：监视一个或多个 key，如果在事务执行前被修改，则事务被中断，不执行事务中的任何命令
- `UNWATCH`：取消监视

```sh
127.0.0.1:6379> set k1 v1
OK
127.0.0.1:6379> set k2 v2
OK
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379> set k1 11
QUEUED
127.0.0.1:6379> set k2 22
QUEUED
127.0.0.1:6379> EXEC
1) OK
2) OK
127.0.0.1:6379> get k1
"11"
127.0.0.1:6379> get k2
"22"
127.0.0.1:6379>
```

取消事务

```sh
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379> set k1 33
QUEUED
127.0.0.1:6379> set k2 34
QUEUED
127.0.0.1:6379> DISCARD
OK
```

事务执行步骤
1. 开启：以 `MULTI` 开始一个事务
2. 入队：将多个命令入队到事务队列中
3. 执行：由 `EXEC` 命令触发事务

### 错误处理

#### 语法错误（编译器错误）

在开启事务后，修改 k1 值为 11，k2 值为 22，但 k2 语法错误，导致事务提交失败，k1、k2 保留原值。

```sh
127.0.0.1:6379> set k1 v1
OK
127.0.0.1:6379> set k2 v2
OK
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379> set k1 11
QUEUED
127.0.0.1:6379> sets k2 22
(error) ERR unknown command `sets`, with args beginning with: `k2`, `22`, 
127.0.0.1:6379> exec
(error) EXECABORT Transaction discarded because of previous errors.
127.0.0.1:6379> get k1
"v1"
127.0.0.1:6379> get k2
"v2"
127.0.0.1:6379>
```

#### Redis 类型错误（运行时错误）

在开启事务后，修改 k1 值为 11，k2 值为 22，但将 k2 的类型误认为 List，在运行时检测类型错误，最终导致事务提交失败，此时事务并没有回滚，而是跳过错误命令继续执行，k1 值改变、k2 保留原值。

```sh
127.0.0.1:6379> set k1 v1
OK
127.0.0.1:6379> set k1 v2
OK
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379> set k1 11
QUEUED
127.0.0.1:6379> lpush k2 22
QUEUED
127.0.0.1:6379> EXEC
1) OK
2) (error) WRONGTYPE Operation against a key holding the wrong kind of value
127.0.0.1:6379> get k1
"11"
127.0.0.1:6379> get k2
"v2"
127.0.0.1:6379>
```

### 乐观锁

`WATCH` 命令可以为 Redis 事务提供 check-and-set(CAS) 行为。

如果在 `WATCH` 执行后， `EXEC` 执行前，有其他客户端修改了 mykey 的值，那么当前客户端的事务就会失败。程序需要做的就是不断重试这个操作，直到没有发生冲突为止。

```sh
WATCH mykey
val = GET mykey
val = val + 1
MULTI
SET mykey $val
EXEC
```

### 其他

Redis 不支持回滚
- Redis 命令只会因为语法错误而失败，这些错误应该在开发的过程中被发现，而不该出现在生产环境中。
- 因为不需要对回滚进行支持，所以 Redis 内部可以保持简单且快速。

#### ACID

原子性（Atomicity）：Redis 的事务是原子性的，所有命令，要么全部执行，要么全部不执行，而不是完全成功。
- 单条命令是原子执行（或者使用 Lua 脚本）
- 事务中命令入队时就报错，会放弃整个事务执行，保证原子性；
- 事务中命令入队时没报错，实际执行时报错，则部分命令执行成功部分失败，不保证原子性。

一致性（Consistency）：能够处理语法错误，终止事务
- 在命令执行错误或 Redis 发生故障的情况下，Redis 事务机制对一致性属性是有保证的。

隔离性（Isolation）：保证命令执行过程中不会被其他客户端命令打断
- 并发操作在 `EXEC` 命令前执行，隔离性保证要使用 `WATCH` 机制来实现，否则隔离性无法保证；
- 并发操作在 `EXEC` 命令后执行，隔离性可以保证。

持久性（Durability）：不保证持久性，RDB 和 AOF 持久化策略都是异步执行的

#### 其他实现方式

1. 基于 Lua 脚本，Redis 可以保证脚本内的命令一次性、按顺序地执行，但不提供事务运行错误的回滚，执行过程中如果部分命令运行错误，剩下的命令还是会继续运行完。

2. 基于中间标记变量，通过标记变量来标识事务是否执行完成，读取数据时先读取标记变量判断事务是否执行完成。需要额外写代码实现，比较繁琐。

## 事件

Redis 中的事件驱动库只关注网络 IO 和定时器。
- 文件事件（file event）：用于处理 Redis 服务器和客户端之间的网络 IO。
- 时间事件（time event）：处理定时操作，Redis 服务器中的一些操作（比如 `serverCron` 函数）需要在给定的时间点执行。

### 文件事件

### 时间事件

## 集群

### 主从复制

将一台 Redis 服务器的数据，复制到其他 Redis 服务器。前者称为主节点（master），后者称为从节点（slave）；数据的复制是单向的，只能由主节点到从节点。

主要作用
- 数据冗余：数据热备份
- 故障恢复：主节点宕机，可以由从节点提供服务
- 负载均衡：由主节点提供写服务，由从节点提供读服务，提高服务器并发
- 高可用：哨兵和集群的实现基础

读写分离
- 读：主节点、从节点都可读
- 写：写入主节点，主节点同步到从节点

#### 全量复制

当启动多个 Redis 实例时，它们相互之间就可以通过 `replicaof`（Redis 5.0 之前使用 `slaveof`）命令形成主库和从库的关系，之后会按照三个阶段完成数据的第一次同步。

1. 确立主从关系：将本机作为 `172.16.19.3` 的从库

```sh
replicaof 172.16.19.3 6379
```

2. 三阶段
- 主从库间建立连接、协商同步
- 主库将所有数据同步给从库（RDB 文件）
- 主库把第二阶段执行过程中收到的写命令，再发送给从库

![](images/20220515204632.png)

#### 增量复制

全量复制时，若产生网络中断则需要重新执行三阶段。

增量复制使用环形缓冲区记录主从差异

![](images/20220515204957.png)

#### 其他

全量复制为什么使用 RDB 而不是 AOF？
- RDB 文件是经过压缩的二进制数据，体积小，因此传输和读写都相对更快
- AOF 同步策略选择不当会严重影响 Redis 性能

从库的从库
- 将主库生成 RDB 和传输 RDB 的压力，以级联的方式分散到从库上
![](images/20220515205527.png)

读写分离问题
- 延迟与不一致问题：主从复制的命令传播是异步的
- 故障切换问题：当主节点或从节点出现问题而发生更改时，需要及时修改应用程序读写 Redis 数据的连接

### 哨兵（Sentinel）机制

核心功能：主节点的自动故障转移。

实现功能
- 监控（Monitoring）：哨兵会不断地检查主节点和从节点是否运作正常。
- 自动故障转移（Automatic failover）：当主节点不能正常工作时，哨兵会开始自动故障转移操作，它会将失效主节点的某个从节点升级为新的主节点，并让其他从节点改为复制新的主节点。 
- 配置提供者（Configuration provider）：客户端在初始化时，通过连接哨兵来获得当前 Redis 服务的主节点地址。 
- 通知（Notification）：哨兵可以将故障转移的结果发送给客户端。

监控和自动故障转移功能，使得哨兵可以及时发现主节点故障并完成转移；而配置提供者和通知功能，则需要在与客户端的交互中才能体现。

#### 哨兵集群的组建

使用发布/订阅实现。在主从集群中，主库上有一个名为 `__sentinel__:hello` 的频道，不同哨兵就是通过它来相互发现，实现通信的。

哨兵 1 把自己的 IP（172.16.19.3）和端口（26579）发布到频道上，哨兵 2 和 3 订阅了该频道。

![](images/20220515211042.png)

#### 哨兵监控 Redis 库

哨兵 2 给主库发送 `INFO` 命令，主库收到这个命令后，就会把从库列表返回给哨兵。接着，哨兵就可以根据从库列表中的连接信息，和每个从库建立连接，并对从库进行持续监控。

![](images/20220515211439.png)

#### 主库下线的判定

- 主观下线：任何一个哨兵都可以监控，并作出 Redis 节点下线的判断
- 客观下线：有哨兵集群共同决定 Redis 节点是否下线

当某个哨兵（如下图中的哨兵 2）判断主库“主观下线”后，就会给其他哨兵发送 `is-master-down-by-addr` 命令。接着，其他哨兵会根据自己和主库的连接情况，做出 Y 或 N 的响应。如果赞成票数大于等于哨兵配置文件中的 `quorum` 配置项，则可以判定主库客观下线了。

![](images/20220515211850.png)

#### 哨兵集群的选举

Raft 分布式共识算法
- 半数以上的赞成票
- 票数大于等于哨兵配置文件中的 `quorum` 配置项

#### 新主库的选出

- 过滤掉不健康的（下线或断线），没有响应哨兵 `ping` 的从节点
- 选择 `salve-priority` 从节点优先级最高的（redis.conf）
- 选择复制偏移量最大，复制最完整的从节点

![](images/20220515212042.png)

#### 故障的转移

转移流程
- 将从节点升级为主节点
- 让其他从节点指向新的主节点
- 通知客户端主节点已更换
- 将原来的主节点变成从节点，指向新的主节点

### 集群（Cluster）分片

主从复制和哨兵机制保障了高可用，读写分离使得从节点扩展了主从的读并发能力，但是写能力和存储能力是没有扩展，上限即主节点的承载上限。面对海量数据必需要构建主节点集群，并保持高可用，即每个主节点还需要从节点，这就是分布式系统中典型的纵向扩展（集群分片技术）的体现。

#### 设计目标

#### 主要模块

#### 状态检测及维护

#### 故障恢复

#### 扩容与缩容

#### 其他

## 缓存问题

### 缓存穿透

缓存和数据库中都没有的数据

解决方法
1. 接口层增加校验：参数校验、权限校验
2. 设置有效期较短的 `key-null` 缓存
3. 布隆过滤器（bloomfilter）：快速判断一个 key 是否存在于某容器，不存在直接返回

### 缓存击穿

缓存中没有但数据库中有的数据

解决方法
1. 设置热点数据永不过期
2. 接口限流、熔断（降级）
3. 互斥锁

### 缓存雪崩

缓存中数据大量过期

解决方法
1. 设置随机过期时间，防止同一时间大量过期
2. 如果是分布式部署，则将热点数据均匀分散
3. 设置热点数据永不过期

### 缓存污染

缓存中只被访问一次或者几次的的数据，访问完毕后依然驻留在缓存中，消耗缓存空间。

解决方法：缓存淘汰策略
1. `noeviction`：不淘汰，默认策略
2. `volatile-random`：针对已过期数据，随机淘汰
3. `volatile-ttl`：优先淘汰过期时间早的
4. `volatile-lru`：最近最少使用，优先淘汰最近被访问时间戳早的
5. `volatile-lfu`：最近最不常用，优先淘汰访问次数少的，再淘汰最近被访问时间戳早的
6. `allkeys-random`：针对所有数据
7. `allkeys-lru`：
8. `allkeys-lfu`：

### 缓存与数据库一致性

从缓存中找到数据称为命中缓存，反之称为未命中缓存。应用最为广泛的是 Cache-Aside + Write-Around：
- 读：先读缓存，再读数据库，写入缓存
- 写：先写数据库，再让缓存失效

脏数据问题：读操作未命中缓存，从数据库读取并写入缓存，同时写操作修改了数据库中的数据，那么缓存中保存的就是脏数据。
- 发生概率低
- 使用两阶段提交（2PC）
- 使用共识算法（Paxos、Raft）

设计模式
1. Cache-Aside
2. Read-Through
3. Write-Through
4. Write-Around
5. Write-Back

#### Cache-Aside

应用直接去缓存中找数据，命中缓存则直接返回，如果未命中缓存，则需要先去数据库中查询数据，并将查询到的数据存储到缓存中。

![](images/20220515190250.png)

配合 Write-Around

#### Read-Through

应用和数据库之间不直接连接，通过缓存来更新数据。

![](images/20220515190409.png)

配合 Write-Through

#### Write-Through

先将数据写入到缓存中，然后由缓存将数据存入到数据库中。

![](images/20220515190523.png)

Read-Through + Write-Through

![](images/20220515190558.png)

#### Write-Around

不用缓存，直接写入数据库。

![](images/20220515190633.png)

Cache-Aside + Write-Around

![](images/20220515190658.png)

不用 Write-Through 的原因：Write-Through 会先更新缓存，如果此时刚好有另一个线程将数据库中的旧数据读取出来，覆盖缓存中的新数据，那么就造成了数据错误，使用 Write-Around 则不会出现这个问题。

Read-Through + Write-Around

常用于某些只需要写一次并且读多次的情况，比如聊天信息的写入和获取。

#### Write-Back

多次写入缓存后，再写入数据库，即批量写回。

![](images/20220515190907.png)

缺点是缓存出错则丢失这一批的数据。

#### 异步更新缓存



# 参阅

- [Redis 的数据结构总结](https://juejin.cn/post/6978430172152201247)
- [为了拿捏 Redis 数据结构，我画了 40 张图（完整版）](https://www.cnblogs.com/xiaolincoding/p/15628854.html)
- [Skip List--跳表（全网最详细的跳表文章没有之一）](https://www.jianshu.com/p/9d8296562806)
- [♥Redis教程 - Redis知识体系详解♥](https://pdai.tech/md/db/nosql-redis/db-redis-overview.html)
- [缓存的五种设计模式](https://xie.infoq.cn/article/49947a60376964f1c16369a8b)
- [Redis的ACID属性](https://juejin.cn/post/6970531814653820942)
