## 30 Condition Variables

直接使用 `Makefile` 编译所有程序，执行 `make` 即可
- `main-one-cv-while.c`: The producer/consumer problem solved with a single condition variable.
  - 一个条件变量和 while 语句
    - Mesa 语义
  - 多个消费者线程，消费缓冲区后，不一定唤醒生产者线程；可能产生所有线程都睡眠的情况
- `main-two-cvs-if.c`: Same but with two condition variables and using an if to check whether to sleep.
  - 两个条件变量和 `if` 语句
  - 可以正确唤醒消费者/生产者线程；`if` 语句可能导致获得锁时不是期望状态
- `main-two-cvs-while.c`: Same but with two condition variables and while to check whether to sleep. This is the correct version.
  - 两个条件变量和 `while` 语句
  - 可以正确唤醒消费者/生产者线程；可以获得期望状态
- `main-two-cvs-while-extra-unlock.c`: Same but releasing the lock and then reacquiring it around the fill and get routines.
  - 两个条件变量和 `while` 语句，多一次释放锁和获取锁的操作
  - 将临界区进行分割

遇到错误 `warning: cast from pointer to integer of different size` ，将以上四个文件中的 `(int) arg` 改为 `(intptr_t) arg` 即可
- [Warning: cast to/from pointer from/to integer of different size](https://stackoverflow.com/questions/21323628/warning-cast-to-from-pointer-from-to-integer-of-different-size)

```
BINARIES = main-two-cvs-while main-two-cvs-if main-one-cv-while main-two-cvs-while-extra-unlock
HEADERS = common.h common_threads.h main-header.h main-common.c pc-header.h

all: $(BINARIES)

clean:
	rm -f $(BINARIES)

main-one-cv-while: main-one-cv-while.c $(HEADERS)
	gcc -o main-one-cv-while main-one-cv-while.c -Wall -pthread

main-two-cvs-if: main-two-cvs-if.c $(HEADERS)
	gcc -o main-two-cvs-if main-two-cvs-if.c -Wall -pthread

main-two-cvs-while: main-two-cvs-while.c $(HEADERS)
	gcc -o main-two-cvs-while main-two-cvs-while.c -Wall -pthread

main-two-cvs-while-extra-unlock: main-two-cvs-while-extra-unlock.c $(HEADERS)
	gcc -o main-two-cvs-while-extra-unlock main-two-cvs-while-extra-unlock.c -Wall -pthread
```

每个程序都有以下参数
- `-l <number of items each producer produces>` 生产者生成的数据个数
- `-m <size of the shared producer/consumer buffer>` 缓冲区大小
- `-p <number of producers>` 生产者数量
- `-c <number of consumers>` 消费者数量
- `-P <sleep string: how producer should sleep at various points>` 生产者睡眠时长
- `-C <sleep string: how consumer should sleep at various points>` 消费者睡眠时长
- `-v [verbose flag: trace what is happening and print it]` 详细信息
- `-t [timing flag: time entire execution and print total time]` 打印耗时

给三个生产者设置睡眠时长： `sleep_string_for_p0:sleep_string_for_p1:sleep_string_for_p2`
- 每条语句中之间的休眠时长（秒）
- 默认为 0
- 设置时必须为所有生产者/消费者设置

### main-two-cvs-while

示例 main-two-cvs-while.c
- 每条语句（p0 ~ p6、c0 ~ c6）执行后都可以设置睡眠时长
- 这是正确的生产者/消费者方案

```c
void *producer(void *arg) {
    int id = (intptr_t) arg;
    // make sure each producer produces unique values
    int base = id * loops; 
    int i;
    for (i = 0; i < loops; i++) {   p0;
	Mutex_lock(&m);             p1;
	while (num_full == max) {   p2;
	    Cond_wait(&empty, &m);  p3;
	}
	do_fill(base + i);          p4;
	Cond_signal(&fill);         p5;
	Mutex_unlock(&m);           p6;
    }
    return NULL;
}
                                                                               
void *consumer(void *arg) {
    int id = (intptr_t) arg;
    int tmp = 0;
    int consumed_count = 0;
    while (tmp != END_OF_STREAM) { c0;
	Mutex_lock(&m);            c1;
	while (num_full == 0) {    c2;
	    Cond_wait(&fill, &m);  c3;
        }
	tmp = do_get();            c4;
	Cond_signal(&empty);       c5;
	Mutex_unlock(&m);          c6;
	consumed_count++;
    }

    // return consumer_count-1 because END_OF_STREAM does not count
    return (void *) (long long) (consumed_count - 1);
}
```

调用参数
- 生产者生成 3 个数据
- 缓冲区大小为 2
- 1 个生产者
- 1 个消费者

输出说明
- `NF` 表示缓冲区中的数据数量
- `P0` 表示生产者 0 ，`p0p1...` 表示将要执行的语句，源代码中已标出
- `C0` 表示消费者 0 ，`c0c1...` 表示将要执行的语句，源代码中已标出
- `[*---  --- ]` 表示缓冲区
  - `u` 表示消费者将要消费的数据（消费者指针）
  - `f` 表示生产者将要生成的数据（生产者指针）
  - `*` 表示消费者指针和生产者指针指向同一个位置
  - `0`、`1`、`2` 表示生成的数据的编号

```bash
./main-two-cvs-while -l 3 -m 2 -p 1 -c 1 -v -t

# 输出
 NF             P0 C0 
  0 [*---  --- ]    c0  <---- 消费者判断流未结束
  0 [*---  --- ] p0     <---- 生产者进入循环
  0 [*---  --- ]    c1  <---- 消费者获得锁 m
  0 [*---  --- ]    c2  <---- 消费者进入条件循环，等待信号量 fill，释放锁 m
  0 [*---  --- ] p1     <---- 生产者获得锁 m
  1 [u  0 f--- ] p4     <---- 生产者跳过条件循环（缓冲区未满），产生数据
  1 [u  0 f--- ] p5     <---- 生产者改变信号量 fill
  1 [u  0 f--- ] p6     <---- 生产者释放锁 m
  1 [u  0 f--- ]    c3  <---- 消费者获得锁 m
  0 [ --- *--- ]    c4  <---- 消费者消费数据
  0 [ --- *--- ] p0     <---- 生产者进入循环
  0 [ --- *--- ]    c5  <---- 消费者改变信号量 empty
  0 [ --- *--- ]    c6  <---- 消费者释放锁
  0 [ --- *--- ] p1     <---- 生产者获得锁
  0 [ --- *--- ]    c0  <---- 消费者进入条件循环，等待信号量 fill，释放锁 m
  1 [f--- u  1 ] p4     <---- 生产者跳过条件循环（缓冲区未满），产生数据
  1 [f--- u  1 ] p5     <---- 生产者改变信号量 fill
  1 [f--- u  1 ] p6     <---- 生产者释放锁 m
  1 [f--- u  1 ]    c1  <---- 消费者获得锁 m
  0 [*---  --- ]    c4  <---- 消费者消费数据
  0 [*---  --- ] p0     <---- 生产者进入循环
  0 [*---  --- ]    c5  <---- 消费者改变信号量 empty
  0 [*---  --- ]    c6  <---- 消费者释放锁
  0 [*---  --- ] p1     <---- 生产者获得锁 m
  0 [*---  --- ]    c0  <---- 消费者进入条件循环，等待信号量 fill，释放锁 m
  1 [u  2 f--- ] p4     <---- 生产者跳过条件循环（缓冲区未满），产生数据
  1 [u  2 f--- ] p5     <---- 生产者改变信号量 fill
  1 [u  2 f--- ] p6     <---- 生产者释放锁 m
  1 [u  2 f--- ]    c1  <---- 消费者获得锁 m
  0 [ --- *--- ]    c4  <---- 消费者消费数据
  0 [ --- *--- ]    c5  <---- 消费者改变信号量 empty
  1 [f--- uEOS ] [main: added end-of-stream marker] 流结束标记
  1 [f--- uEOS ]    c6  <---- 消费者释放锁
  1 [f--- uEOS ]    c0  <---- 消费者判断条件
  1 [f--- uEOS ]    c1  <---- 消费者跳过条件循环
  0 [*---  --- ]    c4  <---- 消费者消费数据
  0 [*---  --- ]    c5  <---- 消费者改变信号量 empty
  0 [*---  --- ]    c6  <---- 消费者释放锁

Consumer consumption:
  C0 -> 3               <---- 消费者 C0 总共消费 3 个数据

Total time: 0.00 seconds
```

调用参数
- 生产者生成 1 个数据
- 缓冲区大小为 2
- 1 个生产者
  - `p0` 语句后睡眠 1s ，这里是在 `c1c2` 执行后切换回 P0 后睡眠 1s，然后继续 `p1`
- 1 个消费者
  - 不睡眠

```bash
./main-two-cvs-while -l 1 -m 2 -p 1 -c 1 -P 1,0,0,0,0,0,0 -C 0 -v -t

# 输出
 NF             P0 C0 
  0 [*---  --- ]    c0  <---- 消费者判断流未结束
  0 [*---  --- ] p0     <---- 生产者进入循环
  0 [*---  --- ]    c1  <---- 消费者获得锁 m
  0 [*---  --- ]    c2  <---- 消费者进入条件循环，等待信号量 fill，释放锁 m
  0 [*---  --- ] p1     <---- 生产者获得锁 m
  1 [u  0 f--- ] p4     <---- 生产者跳过条件循环（缓冲区未满），产生数据
  1 [u  0 f--- ] p5     <---- 生产者改变信号量 fill
  1 [u  0 f--- ] p6     <---- 生产者释放锁 m
  1 [u  0 f--- ]    c3  <---- 消费者获得锁 m
  0 [ --- *--- ]    c4  <---- 消费者消费数据
  0 [ --- *--- ]    c5  <---- 消费者改变信号量 empty
  0 [ --- *--- ]    c6  <---- 消费者释放锁
  1 [f--- uEOS ] [main: added end-of-stream marker] 流结束标记
  1 [f--- uEOS ]    c0  <---- 消费者判断条件
  1 [f--- uEOS ]    c1  <---- 消费者跳过条件循环
  0 [*---  --- ]    c4  <---- 消费者消费数据
  0 [*---  --- ]    c5  <---- 消费者改变信号量 empty
  0 [*---  --- ]    c6  <---- 消费者释放锁

Consumer consumption:
  C0 -> 1               <---- 消费者 C0 总共消费 1 个数据

Total time: 1.00 seconds
```