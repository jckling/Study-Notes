从根本上来讲 Git 是一个内容寻址（content-addressable）文件系统，并在此之上提供了一个版本控制系统的用户界面。

底层（plumbing）命令：能以 UNIX 命令行的风格连接在一起，或由脚本调用，来完成工作。更适合作为新工具的组件和自定义脚本的组成部分
上层（porcelain）命令：`checkout`、`branch`、`remote`等更友好的命令。

新初始化的 `.git` 目录的典型结构如下（工具版本 2.35.1）：
```bash
$ ls -F1
config		# 项目特有的配置选项
description	# 仅供 GitWeb 程序使用
HEAD		# 指向目前被检出的分支
hooks/		# 客户端或服务端的钩子脚本（hook scripts）
info/		# 包含全局性排除（global exclude）文件，放置不希望被记录在 .gitignore 文件中的忽略模式（ignored patterns）
objects/	# 存储所有数据内容
refs/		# 存储指向数据（分支、远程仓库和标签等）的提交对象的指针
# index 	# （尚未创建）保存暂存区信息
```

## Git 对象
Git 的核心部分是一个简单的键值对数据库（key-value data store）

创建一个测试用的仓库
- Git 对 `objects` 目录进行了初始化，并创建了 `pack` 和 `info` 子目录，但均为空。
```bash
$ git init test
Initialized empty Git repository in C:/Users/linki/Desktop/test/.git/
$ cd test
$ find .git/objects
.git/objects
.git/objects/info
.git/objects/pack
```

### 数据对象
底层命令 `git hash-object` 可将任意数据保存于 `.git/objects` 目录（即对象数据库），并返回指向该数据对象的唯一的键。
- `-w` 不要只返回键，还要将该对象写入数据库中
- `--stdin` 从标准输入读取内容，若不指定此选项，则须在命令尾部给出待存储文件的路径
- 输出一个长度为 40 个字符的校验和（SHA-1）
  - 将一个将待存储的数据外加一个头部信息（header）一起做 SHA-1 校验运算得到的校验和
```
$ echo 'test content' | git hash-object -w --stdin
d670460b4b4aece5915caf5c68d12f560a9fe3e4
```

Git 存储内容的方式：一个文件对应一条内容， 以该内容加上特定头部信息一起的 SHA-1 校验和为文件命名。校验和的前两个字符用于命名子目录，余下的 38 个字符用作文件名。
```
$ find .git/objects -type f
.git/objects/d6/70460b4b4aece5915caf5c68d12f560a9fe3e4
```

一旦将内容存储在了对象数据库中，那么可以通过 `cat-file` 命令从 Git 那里取回数据。
- `-p` 自动判断内容的类型
```bash
$ git cat-file -p d670460b4b4aece5915caf5c68d12f560a9fe3e4
test content
```

对文件进行版本控制
```bash
# 写入新文件
$ echo 'version 1' > test.txt
$ git hash-object -w test.txt
83baae61804e65cc73a7201a7252750c76066a30

# 写入新内容
$ echo 'version 2' > test.txt
$ git hash-object -w test.txt
1f7a7a472abf3dd9643fd615f6da379c4acb3e3a

# 查看记录的不同版本的数据
$ find .git/objects -type f
.git/objects/1f/7a7a472abf3dd9643fd615f6da379c4acb3e3a
.git/objects/83/baae61804e65cc73a7201a7252750c76066a30
.git/objects/d6/70460b4b4aece5915caf5c68d12f560a9fe3e4

# 取回第一个版本
$ git cat-file -p 83baae61804e65cc73a7201a7252750c76066a30 > test.txt
$ cat test.txt
version 1

# 取回第二个版本
$ git cat-file -p 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a > test.txt
$ cat test.txt
version 2
```

`git cat-file -t <SHA-1>` 可以让 Git 告知其内部存储的任何对象类型。
```bash
$ git cat-file -t 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a
blob
```

### 树对象
数据对象（blob object）：仅保存文件内容，没有保存文件名。
树对象（tree object）：解决文件名保存的问题，允许将多个文件组织到一起。

一个树对象包含了一条或多条树对象记录（tree entry），每条记录含有一个指向数据对象或者子树对象的 SHA-1 指针，以及相应的模式、类型、文件名信息。

查看最新的树对象
- `master^{tree}` 语法表示 master 分支上最新的提交所指向的树对象。
```
git cat-file -p master^{tree}
```

从概念上讲，Git 内部存储的数据有点像这样：
![](https://git-scm.com/book/en/v2/images/data-model-1.png)

通常，Git 根据某一时刻暂存区（即 index 区域）所表示的状态创建并记录一个对应的树对象， 如此重复便可依次记录（某个时间段内）一系列的树对象。
因此，为创建一个树对象，首先需要通过暂存一些文件来创建一个暂存区。可以通过底层命令 `git update-index` 为一个单独文件创建一个暂存区。 

为 test.txt 的第一个版本创建暂存区
- `--add` 添加到暂存区
- `--cacheinfo` 文件位于 Git 数据库
- `100644` 文件模式，表示普通文件
  - `100755` 表示可执行文件；`120000` 表示符号链接
  - 这三种模式是 Git 文件（即数据对象）的所有合法模式，还有一些模式用于目录项和子模块
- SHA-1
- 文件名
```
git update-index --add --cacheinfo 100644 \
  83baae61804e65cc73a7201a7252750c76066a30 test.txt
```

`git write-tree` 将暂存区内容写入树对象
```bash
$ git write-tree
d8329fc1cc938780ffdd9f94e0d364e0ea74f579
$ git cat-file -p d8329fc1cc938780ffdd9f94e0d364e0ea74f579
100644 blob 83baae61804e65cc73a7201a7252750c76066a30      test.txt
```

查看对象类型，树对象
```
$ git cat-file -t d8329fc1cc938780ffdd9f94e0d364e0ea74f579
tree
```

将 test.txt 的第二个版本和新文件加入暂存区，然后写入新的树对象
```bash
$ echo 'new file' > new.txt
$ git update-index --add --cacheinfo 100644 \
  1f7a7a472abf3dd9643fd615f6da379c4acb3e3a test.txt
$ git update-index --add new.txt
$ git write-tree
0155eb4229851634a0f03eb265b69f5a2d56f341
$ git cat-file -p 0155eb4229851634a0f03eb265b69f5a2d56f341
100644 blob fa49b077972391ad58037050f2a75f74e3671e92      new.txt
100644 blob 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a      test.txt
```

将第一个树对象加入第二个树对象，使其成为新的树对象的一个子目录。调用  `git read-tree` 命令把树对象读入暂存区。
- `--prefix=bak` 将一个已有的树对象作为子树读入暂存区，创建 bak 子目录
```bash
$ git read-tree --prefix=bak d8329fc1cc938780ffdd9f94e0d364e0ea74f579
$ git write-tree
3c4e9cd789d88d8d89c1073707c3585e41b0e614
$ git cat-file -p 3c4e9cd789d88d8d89c1073707c3585e41b0e614
040000 tree d8329fc1cc938780ffdd9f94e0d364e0ea74f579      bak
100644 blob fa49b077972391ad58037050f2a75f74e3671e92      new.txt
100644 blob 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a      test.txt
```

![](https://git-scm.com/book/en/v2/images/data-model-2.png)

### 提交对象
提交对象（commit object）：保存 SHA-1 哈希值、时间戳、提交者等基本信息。

通过调用 `commit-tree` 命令创建一个提交对象，为此需要指定一个树对象的 SHA-1 值，以及该提交的父提交对象（如果有的话）。
- 由于创建时间和作者数据不同，会得到一个不同的散列值。
```bash
$ echo 'first commit' | git commit-tree d8329f
a579a25a1edc84d2655777bfc6414f0a772b6072
```

查看提交对象，格式很简单：先指定一个顶层树对象，代表当前项目快照； 然后是可能存在的父提交； 之后是作者/提交者信息（依据 `user.name` 和 `user.email` 配置设定，外加一个时间戳）； 留空一行，最后是提交注释。
```
git cat-file -p a579a25
```

创建两个提交对象，它们分别引用各自的上一个提交（作为其父提交对象）
```bash
$ echo 'second commit' | git commit-tree 0155eb -p a579a25
64698c63905940f841f5d198019a53a217bbe2dd
$ echo 'third commit'  | git commit-tree 3c4e9c -p 64698c6
f4673127637e853fb14a9efc66e1a1a0dd2baace
```

查看 Git 提交历史
```
git log --stat f46731
```

每次运行 `git add` 和 `git commit` 命令时，Git 所做的工作实质就是将被改写的文件保存为数据对象，更新暂存区，记录树对象，最后创建一个指明了顶层树对象和父提交的提交对象。

这三种主要的 Git 对象——数据对象、树对象、提交对象——最初均以单独文件的形式保存在 `.git/objects` 目录下。
```bash
$ find .git/objects -type f
.git/objects/01/55eb4229851634a0f03eb265b69f5a2d56f341	# tree 2
.git/objects/1f/7a7a472abf3dd9643fd615f6da379c4acb3e3a	# test.txt v2
.git/objects/3c/4e9cd789d88d8d89c1073707c3585e41b0e614	# tree 3
.git/objects/64/698c63905940f841f5d198019a53a217bbe2dd	# commit 2
.git/objects/83/baae61804e65cc73a7201a7252750c76066a30	# test.txt v1
.git/objects/a5/79a25a1edc84d2655777bfc6414f0a772b6072	# commit 1
.git/objects/d6/70460b4b4aece5915caf5c68d12f560a9fe3e4	# 'test content'
.git/objects/d8/329fc1cc938780ffdd9f94e0d364e0ea74f579	# tree 1
.git/objects/f4/673127637e853fb14a9efc66e1a1a0dd2baace	# commit 3
.git/objects/fa/49b077972391ad58037050f2a75f74e3671e92	# new.txt
```
注：图片中的哈希值与本地生成的不同
![](https://git-scm.com/book/en/v2/images/data-model-3.png)

### 对象存储
Git 首先会以识别出的对象的类型作为开头来构造一个头部信息，接着 Git 会在头部的第一部分添加一个空格，随后是数据内容的字节数，最后是一个空字节（null byte）。

Git 会将上述头部信息和原始数据拼接起来，并计算出这条新内容的 SHA-1 校验和。Git 会通过 zlib 压缩新内容。

Git 将确定待写入对象的路径（SHA-1 值的前两个字符作为子目录名称，后 38 个字符则作为子目录内文件的名称），然后将压缩过的内容写入对象。

所有的 Git 对象均以这种方式存储，区别仅在于类型标识：对象类型的头部信息以字符串 `commit` 或 `tree` 或 `blob` 开头。

## Git 引用
引用（references，或简写为 refs）：保存 SHA-1 值的文件，有一个简单的名字，可以用这个名字指针来替代原始的 SHA-1 值，保存在 `.git/refs` 目录下。

```bash
$ find .git/refs
.git/refs
.git/refs/heads
.git/refs/tags
```

创建一个新引用来帮助记忆最新提交所在的位置
```
git update-ref refs/heads/master f4673127637e853fb14a9efc66e1a1a0dd2baace
```

使用刚创建的 master 引用代替 SHA-1
```bash
$ git log --pretty=oneline master
f4673127637e853fb14a9efc66e1a1a0dd2baace (master) third commit
64698c63905940f841f5d198019a53a217bbe2dd second commit
a579a25a1edc84d2655777bfc6414f0a772b6072 first commit
```

Git 分支的本质：一个指向某一系列提交之首的指针或引用。 
当运行类似 `git branch <branch>` 这样的命令时，Git 实际上会运行 `update-ref` 命令， 取得当前所在分支最新提交对应的 SHA-1 值，并将其加入想要创建的任何新引用中。

在第二个提交上创建一个分支
```
git update-ref refs/heads/test 64698c6
```

查看分支
```bash
$ git log --pretty=oneline test
64698c63905940f841f5d198019a53a217bbe2dd (test) second commit
a579a25a1edc84d2655777bfc6414f0a772b6072 first commit
```

注：图片中的哈希值与本地生成的不同
![](https://git-scm.com/book/en/v2/images/data-model-4.png)

### HEAD 引用
HEAD 文件通常是一个符号引用（symbolic reference），指向目前所在的分支。所谓符号引用，表示它是一个指向其他引用的指针。
在某些罕见的情况下，HEAD 文件可能会包含一个 git 对象的 SHA-1 值。 当检出一个标签、提交或远程分支，使仓库变成“[分离 HEAD](https://git-scm.com/docs/git-checkout#_detached_head)”状态时，就会出现这种情况。

查看 HEAD 文件内容
- 本地使用 main 作为默认分支
```bash
$ cat .git/HEAD
ref: refs/heads/main
```

切换分支，Git 会更新 HEAD 文件
```bash
$ git checkout test
Switched to branch 'test'
$ cat .git/HEAD
ref: refs/heads/test
```

当执行 `git commit` 时，该命令会创建一个提交对象，并用 HEAD 文件中那个引用所指向的 SHA-1 值设置其父提交字段。

查看 HEAD 引用对应的值
```bash
$ git symbolic-ref HEAD
refs/heads/test
```

设置 HEAD 引用的值
```bash
$ git symbolic-ref HEAD refs/heads/main
$ cat .git/HEAD
ref: refs/heads/main
```

### 标签引用
标签对象（tag object）：类似于提交对象，它包含一个标签创建者信息、一个日期、一段注释信息，以及一个指针。存在两种类型的标签：附注标签和轻量标签。
主要的区别在于，标签对象通常指向一个提交对象，而不是一个树对象。它像是一个永不移动的分支引用——永远指向同一个提交对象，只不过给这个提交对象加上一个更友好的名字罢了。

对第二个提交创建轻量标签，只包含一个固定的引用
```
git update-ref refs/tags/v1.0 64698c63905940f841f5d198019a53a217bbe2dd
```

对第三个提交创建附注标签，Git 会创建一个标签对象，并记录一个引用来指向该标签对象，而不是直接指向提交对象
```
git tag -a v1.1 f4673127637e853fb14a9efc66e1a1a0dd2baace -m 'test tag'
```

查看标签对象的 SHA-1 值
```bash
$ cat .git/refs/tags/v1.1
0774aa518978949919fbd15738c01c089f4cc002
```

查看标签对象的内容，object 条目指向打了标签的那个提交对象的 SHA-1 值。
```
git cat-file -p 0774aa518978949919fbd15738c01c089f4cc002
```

注意：标签对象并非必须指向某个提交对象，可以对任意类型的 Git 对象打标签。

例如，在 Git 源码中，项目维护者将他们的 GPG 公钥添加为一个数据对象，然后对这个对象打了一个标签。通过执行以下命令来在 Git 源码仓库中查看公钥：
```
git clone https://github.com/git/git.git
cd git
git cat-file blob junio-gpg-pub
```

Linux 内核版本库同样有一个不指向提交对象的标签对象——首个被创建的标签对象所指向的是最初被引入版本库的那份内核源码所对应的树对象。

### 远程引用
远程引用（remote reference）

如果添加了一个远程版本库并对其执行过推送操作，Git 会记录下最近一次推送操作时每一个分支所对应的值，并保存在 `refs/remotes` 目录下。

例如，你可以添加一个叫做 origin 的远程版本库，然后把 master 分支推送上去
```bash
$ git remote add origin git@github.com:schacon/simplegit-progit.git
$ git push origin master
Counting objects: 11, done.
Compressing objects: 100% (5/5), done.
Writing objects: 100% (7/7), 716 bytes, done.
Total 7 (delta 2), reused 4 (delta 1)
To git@github.com:schacon/simplegit-progit.git
  a11bef0..ca82a6d  master -> master
```

查看 `refs/remotes/origin/master` 文件，可以发现 origin 远程版本库的 master 分支所对应的 SHA-1 值，就是最近一次与服务器通信时本地 master 分支所对应的 SHA-1 值：
```
$ cat .git/refs/remotes/origin/master
ca82a6dff817ec66f44342007202690a93763949
```

远程引用和分支（位于 `refs/heads` 目录下的引用）之间最主要的区别在于，远程引用是只读的。虽然可以 `git checkout` 到某个远程引用，但是 Git 并不会将 HEAD 引用指向该远程引用。Git 将这些远程引用作为记录远程服务器上各分支最后已知位置状态的书签来管理。

## 包文件
经过上面的一系列操作，目前仓库包含 11 个对象：四个数据对象，三个树对象，三个提交对象和一个标签对象。
```bash
$ find .git/objects -type f
.git/objects/01/55eb4229851634a0f03eb265b69f5a2d56f341	# tree 2
.git/objects/07/74aa518978949919fbd15738c01c089f4cc002	# tag
.git/objects/1f/7a7a472abf3dd9643fd615f6da379c4acb3e3a	# test.txt v2
.git/objects/3c/4e9cd789d88d8d89c1073707c3585e41b0e614	# tree 3
.git/objects/64/698c63905940f841f5d198019a53a217bbe2dd	# commit  2
.git/objects/83/baae61804e65cc73a7201a7252750c76066a30	# test.txt v1
.git/objects/a5/79a25a1edc84d2655777bfc6414f0a772b6072	# commit 1
.git/objects/d6/70460b4b4aece5915caf5c68d12f560a9fe3e4	# 'test content'
.git/objects/d8/329fc1cc938780ffdd9f94e0d364e0ea74f579	# tree 1
.git/objects/f4/673127637e853fb14a9efc66e1a1a0dd2baace	# commit 3
.git/objects/fa/49b077972391ad58037050f2a75f74e3671e92	# new.txt
```

Git 使用 zlib 压缩文件内容，下载并添加大文件到仓库中
```
curl https://raw.githubusercontent.com/mojombo/grit/master/lib/grit/repo.rb > repo.rb
git checkout master
git add repo.rb
git commit -m 'added repo.rb'
```

查看生成的树对象
```bash
$ git cat-file -p master^{tree}
100644 blob fa49b077972391ad58037050f2a75f74e3671e92    new.txt
100644 blob 033b4468fa6b2a9547a70d88d1bbe8bf3f9ed0d5    repo.rb
100644 blob 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a    test.txt
```

查看对象大小
```bash
$ git cat-file -s 033b4468fa6b2a9547a70d88d1bbe8bf3f9ed0d5
22044
```

修改大文件并提交
```bash
echo '# testing' >> repo.rb
git commit -am 'modified repo.rb a bit'
```

repo.rb 对应一个与之前完全不同的数据对象，虽然只加入一行新内容，Git 也会用一个全新的对象来存储新的文件内容。
```bash
$ git cat-file -p master^{tree}
100644 blob fa49b077972391ad58037050f2a75f74e3671e92    new.txt
100644 blob b042a60ef7dff760008df33cee372b945b6e884e    repo.rb
100644 blob 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a    test.txt
```

Git 最初向磁盘中存储对象时所使用的格式被称为“松散（loose）”对象格式。但是，Git 会时不时地自动将多个这些对象打包成一个称为“包文件（packfile）”的二进制文件，以节省空间和提高效率。Git 认为是悬空（dangling）的对象，不会将它们打包进新生成的包文件中。
当版本库中有太多的松散对象、用户手动执行 `git gc` 命令、用户向远程服务器执行推送时，Git 都会进行打包。

注：本地使用 main 默认分支，实验使用 master，存在冲突，因此后续使用书中的输出。
```bash
$ git gc
Counting objects: 18, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (14/14), done.
Writing objects: 100% (18/18), done.
Total 18 (delta 3), reused 0 (delta 0)
```

查看 objects 目录，大部分的对象都不见了，与此同时出现了一些新文件
```bash
$ find .git/objects -type f
.git/objects/bd/9dbf5aae1a3862dd1526723246b20206e5fc37
.git/objects/d6/70460b4b4aece5915caf5c68d12f560a9fe3e4
.git/objects/info/packs
.git/objects/pack/pack-978e03944f5c581011e6998cd0e9e30000905586.idx
.git/objects/pack/pack-978e03944f5c581011e6998cd0e9e30000905586.pack
```

包文件包含了刚才从文件系统中移除的所有对象的内容。索引文件包含了包文件的偏移信息，通过索引文件可以快速定位任意一个指定对象。 

Git 打包对象时，会查找命名及大小相近的文件，并只保存文件不同版本之间的差异内容。可以用 `git verify-pack` 查看包文件，观察它是如何节省空间的。
```bash
$ git verify-pack -v .git/objects/pack/pack-978e03944f5c581011e6998cd0e9e30000905586.idx
2431da676938450a4d72e260db3bf7b0f587bbc1 commit 223 155 12
69bcdaff5328278ab1c0812ce0e07fa7d26a96d7 commit 214 152 167
80d02664cb23ed55b226516648c7ad5d0a3deb90 commit 214 145 319
43168a18b7613d1281e5560855a83eb8fde3d687 commit 213 146 464
092917823486a802e94d727c820a9024e14a1fc2 commit 214 146 610
702470739ce72005e2edff522fde85d52a65df9b commit 165 118 756
d368d0ac0678cbe6cce505be58126d3526706e54 tag    130 122 874
fe879577cb8cffcdf25441725141e310dd7d239b tree   136 136 996
d8329fc1cc938780ffdd9f94e0d364e0ea74f579 tree   36 46 1132
deef2e1b793907545e50a2ea2ddb5ba6c58c4506 tree   136 136 1178
d982c7cb2c2a972ee391a85da481fc1f9127a01d tree   6 17 1314 1 \
  deef2e1b793907545e50a2ea2ddb5ba6c58c4506
3c4e9cd789d88d8d89c1073707c3585e41b0e614 tree   8 19 1331 1 \
  deef2e1b793907545e50a2ea2ddb5ba6c58c4506
0155eb4229851634a0f03eb265b69f5a2d56f341 tree   71 76 1350
83baae61804e65cc73a7201a7252750c76066a30 blob   10 19 1426
fa49b077972391ad58037050f2a75f74e3671e92 blob   9 18 1445
b042a60ef7dff760008df33cee372b945b6e884e blob   22054 5799 1463
033b4468fa6b2a9547a70d88d1bbe8bf3f9ed0d5 blob   9 20 7262 1 \
  b042a60ef7dff760008df33cee372b945b6e884e
1f7a7a472abf3dd9643fd615f6da379c4acb3e3a blob   10 19 7282
non delta: 15 objects
chain length = 1: 3 objects
.git/objects/pack/pack-978e03944f5c581011e6998cd0e9e30000905586.pack: ok
```

`033b4` 这个数据对象（即 repo.rb 文件的第一个版本）引用了数据对象 `b042a`，即该文件的第二个版本。命令输出内容的第三列显示的是各个对象在包文件中的大小，可以看到 `b042a` 占用了 22K 空间，而 `033b4` 仅占用 9 字节。第二个版本完整保存了文件内容，而原始的版本反而是以差异方式保存的——这是因为大部分情况下需要快速访问文件的最新版本。

## 引用规范
添加远程仓库
```
git remote add origin https://github.com/schacon/simplegit-progit
```

运行上述命令会在仓库中的 `.git/config` 文件中添加一个小节， 并在其中指定远程版本库的名称（origin）、URL 和一个用于获取操作的 引用规范（refspec）：
```
[remote "origin"]
        url = https://github.com/schacon/simplegit-progit
        fetch = +refs/heads/*:refs/remotes/origin/*
```

引用规范的格式由一个可选的 `+` 号和紧随其后的 `<src>:<dst>` 组成，其中 `<src>` 是一个模式（pattern），代表远程版本库中的引用；`<dst>` 是本地跟踪的远程引用的位置。`+` 号告诉 Git 即使在不能快进的情况下也要（强制）更新引用。

默认情况下，引用规范由 `git remote add origin` 命令自动生成，Git 获取服务器中 `refs/heads/` 下面的所有引用，并将它写入到本地的 `refs/remotes/origin/` 中。
所以，如果服务器上有一个 master 分支，可以在本地通过下面任意一种方式来访问该分支上的提交记录，Git 会把它们都扩展成 `refs/remotes/origin/master`
```
git log origin/master
git log remotes/origin/master
git log refs/remotes/origin/master
```

如果想让 Git 每次只拉取远程的 master 分支，而不是所有分支， 可以把（引用规范的）获取那一行修改为只引用该分支：
```
fetch = +refs/heads/master:refs/remotes/origin/master
```

若要将远程的 master 分支拉到本地的 origin/mymaster 分支，可以运行：
```
git fetch origin master:refs/remotes/origin/mymaster
```

拉取多个分支
- 对 master 分支的拉取操作被拒绝，因为它不是一个可以快进的引用，可以通过在引用规范之前指定 `+` 号来覆盖该规则
```bash
$ git fetch origin master:refs/remotes/origin/mymaster \
	 topic:refs/remotes/origin/topic
From git@github.com:schacon/simplegit
 ! [rejected]        master     -> origin/mymaster  (non fast forward)
 * [new branch]      topic      -> origin/topic
```

如果想在每次从 origin 远程仓库获取时都包括 master 和 experiment 分支，添加如下两行：
```
[remote "origin"]
	url = https://github.com/schacon/simplegit-progit
	fetch = +refs/heads/master:refs/remotes/origin/master
	fetch = +refs/heads/experiment:refs/remotes/origin/experiment
```

可以使用命名空间（或目录），获取特定分支
```
[remote "origin"]
	url = https://github.com/schacon/simplegit-progit
	fetch = +refs/heads/master:refs/remotes/origin/master
	fetch = +refs/heads/qa/*:refs/remotes/origin/qa/*
```

引用规范推送，让 `git push origin` 默认把本地 master 分支推送到远程 qa/master 分支
```
[remote "origin"]
	url = https://github.com/schacon/simplegit-progit
	fetch = +refs/heads/*:refs/remotes/origin/*
	push = refs/heads/master:refs/heads/qa/master
```

通过引用规范从远程服务器上删除引用。因为引用规范（的格式）是 `<src>:<dst>`，所以把 `<src>` 留空就意味着把远程版本库的 topic 分支定义为空值，也就是删除它。
```
git push origin :topic
```

或者使用更新的语法
```
git push origin --delete topic
```

## 传输协议
Git 可以通过两种主要的方式在版本库之间传输数据：“哑（dumb）”协议和“智能（smart）”协议。

### 哑协议
适用于搭建基于 HTTP 协议的只读版本库。但是，使用哑协议的版本库很难保证安全性和私有化，所以大多数 Git 服务器宿主（包括云端和本地）都会拒绝使用它。一般情况下都建议使用智能协议。

### 智能协议
需要在服务端运行一个进程，它可以读取本地数据，理解客户端有什么和需要什么，并为它生成合适的包文件。总共有两组进程用于传输数据，它们分别负责上传和下载数据。

#### 上传数据
为了上传数据至远端，Git 使用 `send-pack` 和 `receive-pack` 进程。运行在客户端上的 `send-pack` 进程连接到远端运行的 `receive-pack` 进程。

**SSH**
举例来说，在项目中使用命令 `git push origin master` 时, origin 是由基于 SSH 协议的 URL 所定义的。Git 会运行 `send-pack` 进程，通过 SSH 连接服务器，尝试通过 SSH 在服务端执行命令。
```bash
$ ssh -x git@server "git-receive-pack 'simplegit-progit.git'"
00a5ca82a6dff817ec66f4437202690a93763949 refs/heads/master report-status \
	delete-refs side-band-64k quiet ofs-delta \
	agent=git/2:2.1.1+github-607-gfba4028 delete-refs
0000
```

`git-receive-pack` 命令会立即为它所拥有的每一个引用发送一行响应。
在这个例子中，就只有 master 分支和它的 SHA-1 值。第一行响应中也包含了一个服务端能力的列表（这里是 `report-status`、`delete-refs` 和一些其它的，包括客户端的识别码）。每一行以一个四位的十六进制值开始，用于指明本行的长度。 下一行是 0000，表示服务端已完成了发送引用列表过程。

`send-pack` 进程会判断哪些提交记录是它所拥有但服务端没有的，然后告知 `receive-pack` 这次推送将会更新的各个引用。
举个例子，如果正在更新 master 分支，并且增加 experiment 分支，`send-pack` 的响应将会是像这样：
```
0076ca82a6dff817ec66f44342007202690a93763949 15027957951b64cf874c3557a0f3547bd83b3ff6 \
	refs/heads/master report-status
006c0000000000000000000000000000000000000000 cdfdb42577e2506715f8cfeacdbabc092bf63e8d \
	refs/heads/experiment
0000
```

第一行包括了客户端的能力。全为 0 的 SHA-1 值表示之前没有过这个引用，因为正要添加新的 experiment 引用。删除引用时，将会看到相反的情况：右边的 SHA-1 值全为 0。

然后，客户端会发送一个包含了所有服务端上所没有的对象的包文件。最终，服务端会响应一个成功（或失败）的标识。
```
000eunpack ok
```

**HTTP(S)**
上传过程在 HTTP 上几乎是相同的，除了握手阶段有一点小区别。连接是从下面这个请求开始的：
```
=> GET http://server/simplegit-progit.git/info/refs?service=git-receive-pack
001f# service=git-receive-pack
00ab6c5f0e45abd7832bf23074a333f739977c9e8188 refs/heads/master report-status \
	delete-refs side-band-64k quiet ofs-delta \
	agent=git/2:2.1.1~vmg-bitmaps-bugaloo-608-g116744e
0000
```

这完成了客户端和服务端的第一次数据交换。接下来客户端发起另一个请求，这次是一个 POST 请求，这个请求中包含了 `send-pack` 提供的数据。
```
=> POST http://server/simplegit-progit.git/git-receive-pack
```

这个 POST 请求的内容是 `send-pack` 的输出和相应的包文件。服务端在收到请求后相应地作出成功或失败的 HTTP 响应。

注意：HTTP 协议有可能会进一步用分块传输编码将数据包裹起来。

#### 下载数据
**SSH**
如果通过 SSH 使用抓取功能，`fetch-pack` 会像这样运行：
```
ssh -x git@server "git-upload-pack 'simplegit-progit.git'"
```

在 `fetch-pack` 连接后，`upload-pack` 会返回类似下面的内容：
```
00dfca82a6dff817ec66f44342007202690a93763949 HEAD multi_ack thin-pack \
	side-band side-band-64k ofs-delta shallow no-progress include-tag \
	multi_ack_detailed symref=HEAD:refs/heads/master \
	agent=git/2:2.1.1+github-607-gfba4028
003fe2409a098dc3e53539a9028a94b6224db9d6a6b6 refs/heads/master
0000
```

与 `receive-pack` 的响应相似，但是包含的能力不同，而且它还包含 HEAD 引用所指向内容（`symref=HEAD:refs/heads/master`），这样如果客户端执行的是克隆，它就会知道要检出什么。

此时，`fetch-pack` 进程查看它自己所拥有的对象，响应 “want” 和它需要的对象的 SHA-1 值。 它还会发送“have”和所有它已拥有的对象的 SHA-1 值。在列表的最后，它还会发送“done”以通知 `upload-pack` 进程可以开始发送它所需对象的包文件：
```
003cwant ca82a6dff817ec66f44342007202690a93763949 ofs-delta
0032have 085bb3bcb608e1e8451d4b2432f8ecbe6306e7e7
0009done
0000
```

**HTTP(S)**
抓取操作的握手需要两个 HTTP 请求。第一个是向和哑协议中相同的端点发送 GET 请求：
```
=> GET $GIT_URL/info/refs?service=git-upload-pack
001e# service=git-upload-pack
00e7ca82a6dff817ec66f44342007202690a93763949 HEAD multi_ack thin-pack \
	side-band side-band-64k ofs-delta shallow no-progress include-tag \
	multi_ack_detailed no-done symref=HEAD:refs/heads/master \
	agent=git/2:2.1.1+github-607-gfba4028
003fca82a6dff817ec66f44342007202690a93763949 refs/heads/master
0000
```

和通过 SSH 使用 `git-upload-pack` 非常相似，但是第二个数据交换则是一个单独的请求：
```
=> POST $GIT_URL/git-upload-pack HTTP/1.0
0032want 0a53e9ddeaddad63ad106860237bbf53411d11a7
0032have 441b40d833fdfa93eb2908e52742248faf0ee993
0000
```

## 维护与数据恢复
大约需要 7000 个以上的松散对象或超过 50 个的包文件才能让 Git 启动一次真正的 gc 命令。可以通过修改 `gc.auto` 与 `gc.autopacklimit` 的设置来改动这些数值。

gc 收集所有松散对象并将它们放置到包文件中，将多个包文件合并为一个大的包文件，移除与任何提交都不相关的陈旧对象；打包引用到一个单独的 `.git/packed-refs` 文件中。

如果更新了引用，Git 不会修改这个文件，而是向 `refs/heads` 创建一个新的文件。为了获得指定引用的正确 SHA-1 值，Git 会首先在 `refs` 目录中查找指定的引用，然后再到 `packed-refs` 文件中查找。所以，如果在 `refs` 目录中找不到一个引用，那么它或许在 `packed-refs` 文件中。

`^` 符号表示它上一行的标签是附注标签，`^` 所在的那一行是附注标签指向的那个提交。

### 数据恢复
查看引用日志
```
git reflog
```

查看日志
```
git log -g
```

通过创建新分支指向丢失的提交来恢复
```
git branch recover-branch <SHA-1>
```

如果丢失的提交不在日志中，可以通过 `git fsck` 检查数据库完整性
- `--full` 找出所有没有被其他对象所指向的对象
- `dangling commit` 即丢失的提交
```
git fsck --full
```

### 移除对象
**注意：该操作对提交历史的修改是破坏性的。** 
它会从必须修改或移除一个大文件引用最早的树对象开始重写每一次提交。如果在导入仓库后、任何人开始基于这些提交工作前执行这个操作，那么将不会有任何问题——否则， 必须通知所有的贡献者需要将其成果变基到新提交上。

查看数据库占用空间大小
```
git gc
```

快速查看占用空间大小
- `size-pack` 的数值指的是包文件以 KB 为单位计算的大小
```
git count-objects -v
```

找到待删除的大文件对象，按大小查看包中的文件
```bash
$ git verify-pack -v .git/objects/pack/pack-29…69.idx \
  | sort -k 3 -n \
  | tail -3
dadf7258d699da2c8d89b09ef6670edb7d5f91b4 commit 229 159 12
033b4468fa6b2a9547a70d88d1bbe8bf3f9ed0d5 blob   22044 5792 4977696
82c99a3e86bb1267b236a4b6eff7868d97489af1 blob   4975916 4976258 1438
```

列出所有提交的 SHA-1、数据对象的 SHA-1 和与它们相关联的文件路径
```bash
$ git rev-list --objects --all | grep 82c99a3
82c99a3e86bb1267b236a4b6eff7868d97489af1 git.tgz
```

查看哪些提交对大文件产生改动
```bash
$ git log --oneline --branches -- git.tgz
dadf725 oops - removed large tarball
7b30847 add git tarball
```

从过去所有的树中移除这个文件，重写 `7b30847` 提交之后的所有提交
- `--index-filter` 修改在暂存区或索引中的文件
- `git rm --cached` 从索引移除
  - `--ignore-unmatch` 如果尝试删除的模式不存在时，不提示错误
```bash
$ git filter-branch --index-filter \
  'git rm --ignore-unmatch --cached git.tgz' -- 7b30847^..
Rewrite 7b30847d080183a1ab7d18fb202473b3096e9f34 (1/2)rm 'git.tgz'
Rewrite dadf7258d699da2c8d89b09ef6670edb7d5f91b4 (2/2)
Ref 'refs/heads/master' was rewritten
```

在重新打包前需要移除任何包含指向那些旧提交的指针的文件：
```bash
$ rm -Rf .git/refs/original
$ rm -Rf .git/logs/
$ git gc
Counting objects: 15, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (11/11), done.
Writing objects: 100% (15/15), done.
Total 15 (delta 1), reused 12 (delta 0)
```

大文件还在松散对象中，并没有消失；但是它不会在推送或接下来的克隆中出现。完全移除：
```
git prune --expire now
```
