## 32 Concurrency Bugs

直接使用 `Makefile` 编译所有程序，执行 `make` 即可
- `vector-deadlock.c`: This version blithely grabs the locks in a particular order (dst then src). By doing so, it creates an "invitation to deadlock", as one thread might call vector_add(v1, v2) while another concurrently calls vector_add(v2, v1).
  - 死锁
- `vector-global-order.c`: This version of vector_add() grabs the locks in a total order, based on address of the vector.
  - 基于地址获取锁
- `vector-try-wait.c`: This version of vector_add() uses pthread_mutex_trylock() to attempt to grab locks; when the try fails, the code releases any locks it may hold and goes back to the top and tries it all over again.
  - 尝试获取锁，失败后释放所有锁；重试
- `vector-avoid-hold-and-wait.c`: This version ensures it can't get stuck in a hold and wait pattern by using a single lock around lock acquisition.
  - 全局锁
- `vector-nolock.c`: This version doesn't even use locks; rather, it uses an atomic fetch-and-add to implement the vector_add() routine. Its semantics (as a result) are slightly different.
  - 无等待同步

```
ALL = vector-deadlock vector-global-order vector-try-wait vector-avoid-hold-and-wait vector-nolock
COMMON = vector-header.h main-common.c main-header.h common.h common_threads.h

all: $(ALL)

clean:
	rm -f $(ALL) *~

vector-deadlock: vector-deadlock.c $(COMMON)
	gcc -o vector-deadlock vector-deadlock.c -Wall -pthread -O

vector-global-order: vector-global-order.c $(COMMON)
	gcc -o vector-global-order vector-global-order.c -Wall -pthread -O

vector-try-wait: vector-try-wait.c $(COMMON)
	gcc -o vector-try-wait vector-try-wait.c -Wall -pthread -O

vector-avoid-hold-and-wait: vector-avoid-hold-and-wait.c $(COMMON)
	gcc -o vector-avoid-hold-and-wait vector-avoid-hold-and-wait.c -Wall -pthread -O

vector-nolock: vector-nolock.c $(COMMON)
	gcc -o vector-nolock vector-nolock.c -Wall -pthread -O
```

所有程序都使用的文件
- `common_threads.h`: The usual wrappers around many different pthread (and other) library calls, so as to ensure they are not failing silently
- `vector-header.h`: A simple header for the vector routines, mostly defining a fixed vector size and then a struct that is used per vector (vector_t)
- `main-header.h`: A number of global variables common to each different program
- `main-common.c`: Contains the main() routine (with arg parsing) that initializes two vectors, starts some threads to access them (via a worker() routine), and then waits for the many vector_add()'s to complete

每个程序都有以下参数
- `-d`：为多个线程生成死锁
- `-p`：每个线程请求不同的资源，允许并行
- `-n num_threads`：线程数量，默认为 2
- `-l loops`：每个线程请求的数量，默认为 1
- `-v`：详细信息
- `-t`：打印耗时

程序运行的输出有点微妙，直接分析下源代码...

### vector-deadlock

按顺序获得锁，但是当两个线程请求同样的锁而顺序不同时，将会产生死锁
- 例如，线程 0 请求 0,1，线程 1 请求 1,0

```c
void vector_add(vector_t *v_dst, vector_t *v_src) {
    Pthread_mutex_lock(&v_dst->lock);
    Pthread_mutex_lock(&v_src->lock);
    int i;
    for (i = 0; i < VECTOR_SIZE; i++) {
	v_dst->values[i] = v_dst->values[i] + v_src->values[i];
    }
    Pthread_mutex_unlock(&v_dst->lock);
    Pthread_mutex_unlock(&v_src->lock);
}
```

`-d` 查看产生死锁的条件
- 线程 0 请求 1,0
- 线程 1 请求 0,1

```bash
./vector-deadlock -d -v

# 输出
              ->add(1, 0)
              <-add(1, 0)
->add(0, 1)
<-add(0, 1)
Time: 0.00 seconds
```

### vector-global-order

每个线程都按照锁的地址顺序获得锁，因此不会产生死锁
- 简单易行

```c
void vector_add(vector_t *v_dst, vector_t *v_src) {
    if (v_dst < v_src) {
	Pthread_mutex_lock(&v_dst->lock);
	Pthread_mutex_lock(&v_src->lock);
    } else if (v_dst > v_src) {
	Pthread_mutex_lock(&v_src->lock);
	Pthread_mutex_lock(&v_dst->lock);
    } else {
	// special case: src and dst are the same
	Pthread_mutex_lock(&v_src->lock);
    }
    int i;
    for (i = 0; i < VECTOR_SIZE; i++) {
	v_dst->values[i] = v_dst->values[i] + v_src->values[i];
    }
    Pthread_mutex_unlock(&v_src->lock);
    if (v_dst != v_src) 
	Pthread_mutex_unlock(&v_dst->lock);
}
```

### vector-try-wait

每个线程尝试获取锁失败后，将已有的锁释放，并循环该过程
- 资源开销大
- 可能产生活锁

```c
void vector_add(vector_t *v_dst, vector_t *v_src) {
  top:
    if (pthread_mutex_trylock(&v_dst->lock) != 0) {
	goto top;
    }
    if (pthread_mutex_trylock(&v_src->lock) != 0) {
	retry++;
	Pthread_mutex_unlock(&v_dst->lock);
	goto top;
    }
    int i;
    for (i = 0; i < VECTOR_SIZE; i++) {
	v_dst->values[i] = v_dst->values[i] + v_src->values[i];
    }
    Pthread_mutex_unlock(&v_dst->lock);
    Pthread_mutex_unlock(&v_src->lock);
}
```

### vector-avoid-hold-and-wait

先获得全局锁，再获得其他的锁
- 限制并发

```c
// use this to make lock acquisition ATOMIC
pthread_mutex_t global = PTHREAD_MUTEX_INITIALIZER; 

void vector_add(vector_t *v_dst, vector_t *v_src) {
    // put GLOBAL lock around all lock acquisition...
    Pthread_mutex_lock(&global);
    Pthread_mutex_lock(&v_dst->lock);
    Pthread_mutex_lock(&v_src->lock);
    Pthread_mutex_unlock(&global);
    int i;
    for (i = 0; i < VECTOR_SIZE; i++) {
	v_dst->values[i] = v_dst->values[i] + v_src->values[i];
    }
    Pthread_mutex_unlock(&v_dst->lock);
    Pthread_mutex_unlock(&v_src->lock);
}
```

### vector-nolock

原子地增加变量的值

```c
// taken from https://en.wikipedia.org/wiki/Fetch-and-add
int fetch_and_add(int * variable, int value) {
    asm volatile("lock; xaddl %%eax, %2;"
		 :"=a" (value)                  
		 :"a" (value), "m" (*variable)  
		 :"memory");
    return value;
}

void vector_add(vector_t *v_dst, vector_t *v_src) {
    int i;
    for (i = 0; i < VECTOR_SIZE; i++) {
	fetch_and_add(&v_dst->values[i], v_src->values[i]);
    }
}
```