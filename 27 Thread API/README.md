## 27 Thread API

Ubuntu 18.04.5 安装 [Valgrind](https://valgrind.org/)

```bash
sudo apt install valgrind
```

使用 `valgrind` 调试多线程 C 程序
- `main-race.c`: A simple race condition
- `main-deadlock.c`: A simple deadlock
- `main-deadlock-global.c`: A solution to the deadlock problem
- `main-signal.c`: A simple child/parent signaling example
- `main-signal-cv.c`: A more efficient signaling via condition variables
- `common_threads.h`: Header file with wrappers to make code check errors and be more readable

直接使用 `Makefile` 编译所有程序，执行 `make` 即可

```
FLAGS = -Wall -pthread -g

all: main-race main-deadlock main-deadlock-global main-signal main-signal-cv

clean:
	rm -f main-race main-deadlock main-deadlock-global main-signal main-signal-cv

main-race: main-race.c common_threads.h
	gcc -o main-race main-race.c $(FLAGS)

main-deadlock: main-deadlock.c common_threads.h
	gcc -o main-deadlock main-deadlock.c $(FLAGS)

main-deadlock-global: main-deadlock-global.c common_threads.h
	gcc -o main-deadlock-global main-deadlock-global.c $(FLAGS)

main-signal: main-signal.c common_threads.h
	gcc -o main-signal main-signal.c $(FLAGS)

main-signal-cv: main-signal-cv.c common_threads.h
	gcc -o main-signal-cv main-signal-cv.c $(FLAGS)
```

### main-race.c

- 创建线程 p 调用函数 worker，worker 函数增加全局变量 balance 的值；
- 主线程 main 增加全局变量 balance 的值，然后等待线程 p ；
- 因此，全局变量 balance 的结果是不确定的

```c
#include <stdio.h>

#include "common_threads.h"

int balance = 0;

void* worker(void* arg) {
    balance++; // unprotected access 
    return NULL;
}

int main(int argc, char *argv[]) {
    pthread_t p;
    Pthread_create(&p, NULL, worker, NULL);
    balance++; // unprotected access
    Pthread_join(p, NULL);
    return 0;
}
```

使用 `valgrind` 的 [helgrind](https://www.valgrind.org/docs/manual/hg-manual.html) 工具进行调试
- 主线程和子线程对 `balance` 的写操作可能产生数据竞态

```bash
valgrind --tool=helgrind ./main-race

# 输出
==8688== Helgrind, a thread error detector
==8688== Copyright (C) 2007-2017, and GNU GPL'd, by OpenWorks LLP et al.
==8688== Using Valgrind-3.13.0 and LibVEX; rerun with -h for copyright info
==8688== Command: ./main-race
==8688== 
==8688== ---Thread-Announcement------------------------------------------
==8688== 
==8688== Thread #1 is the program's root thread
==8688== 
==8688== ---Thread-Announcement------------------------------------------
==8688== 
==8688== Thread #2 was created
==8688==    at 0x5182A2E: clone (clone.S:71)
==8688==    by 0x4E49EC4: create_thread (createthread.c:100)
==8688==    by 0x4E49EC4: pthread_create@@GLIBC_2.2.5 (pthread_create.c:797)
==8688==    by 0x4C36A27: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8688==    by 0x1087E2: main (main-race.c:14)
==8688== 
==8688== ----------------------------------------------------------------
==8688== 
==8688== Possible data race during read of size 4 at 0x309014 by thread #1
==8688== Locks held: none
==8688==    at 0x108806: main (main-race.c:15)
==8688== 
==8688== This conflicts with a previous write of size 4 by thread #2
==8688== Locks held: none
==8688==    at 0x10879B: worker (main-race.c:8)
==8688==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8688==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8688==    by 0x5182A3E: clone (clone.S:95)
==8688==  Address 0x309014 is 0 bytes inside data symbol "balance"
==8688== 
==8688== ----------------------------------------------------------------
==8688== 
==8688== Possible data race during write of size 4 at 0x309014 by thread #1
==8688== Locks held: none
==8688==    at 0x10880F: main (main-race.c:15)
==8688== 
==8688== This conflicts with a previous write of size 4 by thread #2
==8688== Locks held: none
==8688==    at 0x10879B: worker (main-race.c:8)
==8688==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8688==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8688==    by 0x5182A3E: clone (clone.S:95)
==8688==  Address 0x309014 is 0 bytes inside data symbol "balance"
==8688== 
==8688== 
==8688== For counts of detected and suppressed errors, rerun with: -v
==8688== Use --history-level=approx or =none to gain increased speed, at
==8688== the cost of reduced accuracy of conflicting-access information
==8688== ERROR SUMMARY: 2 errors from 2 contexts (suppressed: 0 from 0)
```

### main-deadlock.c

- 创建子线程 p1、p2 调用函数 worker
  - 参数为 0 时，worker 函数先申请 m1 锁，再申请 m2 锁
  - 参数为 1 时，worker 函数先申请 m2 锁，再申请 m1 锁
  - 两个锁都申请到之后，再释放锁
- 显然，可能产生死锁

```c
#include <stdio.h>

#include "common_threads.h"

pthread_mutex_t m1 = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t m2 = PTHREAD_MUTEX_INITIALIZER;

void* worker(void* arg) {
    if ((long long) arg == 0) {
	Pthread_mutex_lock(&m1);
	Pthread_mutex_lock(&m2);
    } else {
	Pthread_mutex_lock(&m2);
	Pthread_mutex_lock(&m1);
    }
    Pthread_mutex_unlock(&m1);
    Pthread_mutex_unlock(&m2);
    return NULL;
}

int main(int argc, char *argv[]) {
    pthread_t p1, p2;
    Pthread_create(&p1, NULL, worker, (void *) (long long) 0);
    Pthread_create(&p2, NULL, worker, (void *) (long long) 1);
    Pthread_join(p1, NULL);
    Pthread_join(p2, NULL);
    return 0;
}
```

使用 helgrind 进行调试
- 检测到不正确的获取锁的顺序

```bash
valgrind --tool=helgrind ./main-deadlock

# 输出
==8714== Helgrind, a thread error detector
==8714== Copyright (C) 2007-2017, and GNU GPL'd, by OpenWorks LLP et al.
==8714== Using Valgrind-3.13.0 and LibVEX; rerun with -h for copyright info
==8714== Command: ./main-deadlock
==8714== 
==8714== ---Thread-Announcement------------------------------------------
==8714== 
==8714== Thread #3 was created
==8714==    at 0x5182A2E: clone (clone.S:71)
==8714==    by 0x4E49EC4: create_thread (createthread.c:100)
==8714==    by 0x4E49EC4: pthread_create@@GLIBC_2.2.5 (pthread_create.c:797)
==8714==    by 0x4C36A27: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x1089E8: main (main-deadlock.c:24)
==8714== 
==8714== ----------------------------------------------------------------
==8714== 
==8714== Thread #3: lock order "0x30A040 before 0x30A080" violated
==8714== 
==8714== Observed (incorrect) order is: acquisition of lock at 0x30A080
==8714==    at 0x4C3403C: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x1088B6: worker (main-deadlock.c:13)
==8714==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8714==    by 0x5182A3E: clone (clone.S:95)
==8714== 
==8714==  followed by a later acquisition of lock at 0x30A040
==8714==    at 0x4C3403C: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x1088E5: worker (main-deadlock.c:14)
==8714==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8714==    by 0x5182A3E: clone (clone.S:95)
==8714== 
==8714== Required order was established by acquisition of lock at 0x30A040
==8714==    at 0x4C3403C: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x108858: worker (main-deadlock.c:10)
==8714==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8714==    by 0x5182A3E: clone (clone.S:95)
==8714== 
==8714==  followed by a later acquisition of lock at 0x30A080
==8714==    at 0x4C3403C: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x108887: worker (main-deadlock.c:11)
==8714==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8714==    by 0x5182A3E: clone (clone.S:95)
==8714== 
==8714==  Lock at 0x30A040 was first observed
==8714==    at 0x4C3403C: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x108858: worker (main-deadlock.c:10)
==8714==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8714==    by 0x5182A3E: clone (clone.S:95)
==8714==  Address 0x30a040 is 0 bytes inside data symbol "m1"
==8714== 
==8714==  Lock at 0x30A080 was first observed
==8714==    at 0x4C3403C: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x108887: worker (main-deadlock.c:11)
==8714==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8714==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8714==    by 0x5182A3E: clone (clone.S:95)
==8714==  Address 0x30a080 is 0 bytes inside data symbol "m2"
==8714== 
==8714== 
==8714== 
==8714== For counts of detected and suppressed errors, rerun with: -v
==8714== Use --history-level=approx or =none to gain increased speed, at
==8714== the cost of reduced accuracy of conflicting-access information
==8714== ERROR SUMMARY: 1 errors from 1 contexts (suppressed: 7 from 7)
```

### main-deadlock-global.c

在上一个程序的基础上增加了全局锁 g
- 先获取锁 g ，然后再获取锁 m1 和 m2
- 没有检查锁获取是否失败
  - 当获取全局锁失败时，和上一个程序一样产生死锁

```c
#include <stdio.h>

#include "common_threads.h"

pthread_mutex_t g = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t m1 = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t m2 = PTHREAD_MUTEX_INITIALIZER;

void* worker(void* arg) {
    Pthread_mutex_lock(&g);
    if ((long long) arg == 0) {
	Pthread_mutex_lock(&m1);
	Pthread_mutex_lock(&m2);
    } else {
	Pthread_mutex_lock(&m2);
	Pthread_mutex_lock(&m1);
    }
    Pthread_mutex_unlock(&m1);
    Pthread_mutex_unlock(&m2);
    Pthread_mutex_unlock(&g);
    return NULL;
}

int main(int argc, char *argv[]) {
    pthread_t p1, p2;
    Pthread_create(&p1, NULL, worker, (void *) (long long) 0);
    Pthread_create(&p2, NULL, worker, (void *) (long long) 1);
    Pthread_join(p1, NULL);
    Pthread_join(p2, NULL);
    return 0;
}
```

使用 helgrind 进行调试
- 检测到不正确的获取锁的顺序，m1 和 m2

```bash
valgrind --tool=helgrind ./main-deadlock-global

# 输出
==8717== Helgrind, a thread error detector
==8717== Copyright (C) 2007-2017, and GNU GPL'd, by OpenWorks LLP et al.
==8717== Using Valgrind-3.13.0 and LibVEX; rerun with -h for copyright info
==8717== Command: ./main-deadlock-global
==8717== 
==8717== ---Thread-Announcement------------------------------------------
==8717== 
==8717== Thread #3 was created
==8717==    at 0x5182A2E: clone (clone.S:71)
==8717==    by 0x4E49EC4: create_thread (createthread.c:100)
==8717==    by 0x4E49EC4: pthread_create@@GLIBC_2.2.5 (pthread_create.c:797)
==8717==    by 0x4C36A27: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x108A46: main (main-deadlock-global.c:27)
==8717== 
==8717== ----------------------------------------------------------------
==8717== 
==8717== Thread #3: lock order "0x30A080 before 0x30A0C0" violated
==8717== 
==8717== Observed (incorrect) order is: acquisition of lock at 0x30A0C0
==8717==    at 0x4C3403C: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x1088E5: worker (main-deadlock-global.c:15)
==8717==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8717==    by 0x5182A3E: clone (clone.S:95)
==8717== 
==8717==  followed by a later acquisition of lock at 0x30A080
==8717==    at 0x4C3403C: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x108914: worker (main-deadlock-global.c:16)
==8717==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8717==    by 0x5182A3E: clone (clone.S:95)
==8717== 
==8717== Required order was established by acquisition of lock at 0x30A080
==8717==    at 0x4C3403C: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x108887: worker (main-deadlock-global.c:12)
==8717==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8717==    by 0x5182A3E: clone (clone.S:95)
==8717== 
==8717==  followed by a later acquisition of lock at 0x30A0C0
==8717==    at 0x4C3403C: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x1088B6: worker (main-deadlock-global.c:13)
==8717==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8717==    by 0x5182A3E: clone (clone.S:95)
==8717== 
==8717==  Lock at 0x30A080 was first observed
==8717==    at 0x4C3403C: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x108887: worker (main-deadlock-global.c:12)
==8717==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8717==    by 0x5182A3E: clone (clone.S:95)
==8717==  Address 0x30a080 is 0 bytes inside data symbol "m1"
==8717== 
==8717==  Lock at 0x30A0C0 was first observed
==8717==    at 0x4C3403C: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x1088B6: worker (main-deadlock-global.c:13)
==8717==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8717==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8717==    by 0x5182A3E: clone (clone.S:95)
==8717==  Address 0x30a0c0 is 0 bytes inside data symbol "m2"
==8717== 
==8717== 
==8717== 
==8717== For counts of detected and suppressed errors, rerun with: -v
==8717== Use --history-level=approx or =none to gain increased speed, at
==8717== the cost of reduced accuracy of conflicting-access information
==8717== ERROR SUMMARY: 1 errors from 1 contexts (suppressed: 7 from 7)
```

### main-signal.c

- 创建线程 p 调用函数 worker，worker 改变全局变量 done 的值
- 主线程自旋等待，浪费资源

```c
int done = 0;

void* worker(void* arg) {
    printf("this should print first\n");
    done = 1;
    return NULL;
}

int main(int argc, char *argv[]) {
    pthread_t p;
    Pthread_create(&p, NULL, worker, NULL);
    while (done == 0)
	;
    printf("this should print last\n");
    return 0;
}
```

使用 helgrind 进行调试
- 主线程读取的数据和子线程修改的数据可能不同步，造成数据竞态

```bash
valgrind --tool=helgrind ./main-signal

# 输出
==8720== Helgrind, a thread error detector
==8720== Copyright (C) 2007-2017, and GNU GPL'd, by OpenWorks LLP et al.
==8720== Using Valgrind-3.13.0 and LibVEX; rerun with -h for copyright info
==8720== Command: ./main-signal
==8720== 
this should print first
==8720== ---Thread-Announcement------------------------------------------
==8720== 
==8720== Thread #2 was created
==8720==    at 0x5182A2E: clone (clone.S:71)
==8720==    by 0x4E49EC4: create_thread (createthread.c:100)
==8720==    by 0x4E49EC4: pthread_create@@GLIBC_2.2.5 (pthread_create.c:797)
==8720==    by 0x4C36A27: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8720==    by 0x1087DD: main (main-signal.c:15)
==8720== 
==8720== ---Thread-Announcement------------------------------------------
==8720== 
==8720== Thread #1 is the program's root thread
==8720== 
==8720== ----------------------------------------------------------------
==8720== 
==8720== Possible data race during write of size 4 at 0x309014 by thread #2
==8720== Locks held: none
==8720==    at 0x108792: worker (main-signal.c:9)
==8720==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8720==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8720==    by 0x5182A3E: clone (clone.S:95)
==8720== 
==8720== This conflicts with a previous read of size 4 by thread #1
==8720== Locks held: none
==8720==    at 0x108802: main (main-signal.c:16)
==8720==  Address 0x309014 is 0 bytes inside data symbol "done"
==8720== 
==8720== ----------------------------------------------------------------
==8720== 
==8720== Possible data race during read of size 4 at 0x309014 by thread #1
==8720== Locks held: none
==8720==    at 0x108802: main (main-signal.c:16)
==8720== 
==8720== This conflicts with a previous write of size 4 by thread #2
==8720== Locks held: none
==8720==    at 0x108792: worker (main-signal.c:9)
==8720==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8720==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8720==    by 0x5182A3E: clone (clone.S:95)
==8720==  Address 0x309014 is 0 bytes inside data symbol "done"
==8720== 
==8720== ----------------------------------------------------------------
==8720== 
==8720== Possible data race during write of size 1 at 0x5C531A5 by thread #1
==8720== Locks held: none
==8720==    at 0x4C3C546: mempcpy (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8720==    by 0x50ECA03: _IO_file_xsputn@@GLIBC_2.2.5 (fileops.c:1258)
==8720==    by 0x50E1AFE: puts (ioputs.c:40)
==8720==    by 0x108817: main (main-signal.c:18)
==8720==  Address 0x5c531a5 is 21 bytes inside a block of size 1,024 alloc'd
==8720==    at 0x4C30F2F: malloc (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8720==    by 0x50DF1FB: _IO_file_doallocate (filedoalloc.c:101)
==8720==    by 0x50EF3E8: _IO_doallocbuf (genops.c:365)
==8720==    by 0x50EE507: _IO_file_overflow@@GLIBC_2.2.5 (fileops.c:759)
==8720==    by 0x50ECA5C: _IO_file_xsputn@@GLIBC_2.2.5 (fileops.c:1266)
==8720==    by 0x50E1AFE: puts (ioputs.c:40)
==8720==    by 0x108791: worker (main-signal.c:8)
==8720==    by 0x4C36C26: ??? (in /usr/lib/valgrind/vgpreload_helgrind-amd64-linux.so)
==8720==    by 0x4E496DA: start_thread (pthread_create.c:463)
==8720==    by 0x5182A3E: clone (clone.S:95)
==8720==  Block was alloc'd by thread #2
==8720== 
this should print last
==8720== 
==8720== For counts of detected and suppressed errors, rerun with: -v
==8720== Use --history-level=approx or =none to gain increased speed, at
==8720== the cost of reduced accuracy of conflicting-access information
==8720== ERROR SUMMARY: 24 errors from 3 contexts (suppressed: 40 from 40)
```

### main-signal-cv.c

使用锁和条件变量修改 done 的值
- 主线程等待子线程完成后继续
- 子线程获取锁，修改 done 的值后更改条件变量，再释放锁
  - 唤醒主线程 `Pthread_cond_signal`
- 主线程等待条件满足，休眠并释放锁
  - 条件满足后自动获取锁 `Pthread_cond_wait`

```c
#include <stdio.h>

#include "common_threads.h"

// 
// simple synchronizer: allows one thread to wait for another
// structure "synchronizer_t" has all the needed data
// methods are:
//   init (called by one thread)
//   wait (to wait for a thread)
//   done (to indicate thread is done)
// 
typedef struct __synchronizer_t {
    pthread_mutex_t lock;
    pthread_cond_t cond;
    int done;
} synchronizer_t;

synchronizer_t s;

void signal_init(synchronizer_t *s) {
    Pthread_mutex_init(&s->lock, NULL);
    Pthread_cond_init(&s->cond, NULL);
    s->done = 0;
}

void signal_done(synchronizer_t *s) {
    Pthread_mutex_lock(&s->lock);
    s->done = 1;
    Pthread_cond_signal(&s->cond);
    Pthread_mutex_unlock(&s->lock);
}

void signal_wait(synchronizer_t *s) {
    Pthread_mutex_lock(&s->lock);
    while (s->done == 0)
	Pthread_cond_wait(&s->cond, &s->lock);
    Pthread_mutex_unlock(&s->lock);
}

void* worker(void* arg) {
    printf("this should print first\n");
    signal_done(&s);
    return NULL;
}

int main(int argc, char *argv[]) {
    pthread_t p;
    signal_init(&s);
    Pthread_create(&p, NULL, worker, NULL);
    signal_wait(&s);
    printf("this should print last\n");

    return 0;
}
```

使用 helgrind 进行调试
- 并没有问题

```bash
valgrind --tool=helgrind ./main-signal-cv

# 输出
==8725== Helgrind, a thread error detector
==8725== Copyright (C) 2007-2017, and GNU GPL'd, by OpenWorks LLP et al.
==8725== Using Valgrind-3.13.0 and LibVEX; rerun with -h for copyright info
==8725== Command: ./main-signal-cv
==8725== 
this should print first
this should print last
==8725== 
==8725== For counts of detected and suppressed errors, rerun with: -v
==8725== Use --history-level=approx or =none to gain increased speed, at
==8725== the cost of reduced accuracy of conflicting-access information
==8725== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 16 from 16)
```