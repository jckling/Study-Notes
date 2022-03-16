## 引用

查看提交日志，显示简短且唯一的 SHA-1 值
```
git log --abbrev-commit --pretty=oneline
```

通过简短的 SHA-1 值获取提交
```
git show 1c002d
```

若提交是一个分支的顶端提交，那么可以在任何需要引用该提交的 Git 命令中直接使用该分支的名称。
- 查看分支的最后一次提交
```
git show topic1
```

查看分支指向的提交的 SHA-1
```
git rev-parse topic1
```
### 引用日志

引用日志（reflog）记录了最近几个月的 HEAD 和分支引用所指向的历史
```
git reflog
```

每当 HEAD 指向的位置发生了变化，Git 就会将这个信息存储到引用日志中。
引用日志只存在于本地仓库，新克隆仓库的时候，引用日志是空的。 

通过 reflog 数据来获取之前的提交历史，例如，获取 HEAD 在五次前的所指向的提交
```
git show HEAD@{5}
```

查看分支在一定时间前的位置，例如，查看 master 分支在昨天指向哪个提交
- `git show HEAD@{2.months.ago}` 这条命令只有在克隆了一个项目至少两个月时才会显示匹配的提交。
```
git show master@{yesterday}
```

以类似查看日志的输出格式查看引用日志
```
git log -g master
```

### 祖先引用
如果在引用的尾部加上一个 `^`， Git 会将其解析为该引用的上一个提交，例如，查看上一个提交
```
git show HEAD^
```

可以在 `^` 后面添加一个数字来指明想要哪一个父提交
- 只适用于合并的提交
```
# 第一父提交（合并时所在分支，master）
git show d921970^
# 第二父提交（所合并的分支，topic）
git show d921970^
```

`~` 同样是指向第一父提交，因此 `HEAD~` 和 `HEAD^` 是等价的。区别在于 `HEAD~2` 代表“第一父提交的第一父提交”，也就是“祖父提交”
```
git show HEAD~3
git show HEAD~~~
```

组合使用，获取之前引用的第二父提交
```
git show HEAD~3^2
```

### 提交区间
双点语法，选出在一个分支而不在另一个分支中的提交。

例如，选出在 experiment 分支中而不在 master 分支中的提交
```
git log master..experiment
```

![](https://git-scm.com/book/en/v2/images/double-dot.png)

查看即将推送到远程仓库的内容
- 在当前分支而不在远程 origin/master 分支中的提交
```
git log origin/master..HEAD

# 留空，默认为 HEAD
git log origin/master..
```

多点，允许在任意引用前加 `^` 或 `--not` 指明不希望提交被包含其中的分支
```
git log refA..refB
git log ^refA refB
git log refB --not refA
```

查看所有被 refA 或 refB 包含的但是不被 refC 包含的提交
```
git log refA refB ^refC
git log refA refB --not refC
```

三点语法，选出被两个引用 之一 包含但又不被两者同时包含的提交。

例如，查看 master 或者 experiment 中包含的但不是两者共有的提交
```
git log master...experiment
```

显示提交属于哪一侧的分支
```
git log --left-right master...experiment
```

## 交互式暂存
帮助拆分为若干提交等
```
$ git add -i

*** Commands ***
  1: status       2: update       3: revert       4: add untracked
  5: patch        6: diff         7: quit         8: help
What now>
```

## 贮藏与清理
切换分支，但是不想提交之前的工作，使用贮藏（stash）。可以在一个分支上保存一个贮藏，切换到另一个分支，然后尝试重新应用这些修改。
```
git stash
git stash push
```

查看贮藏的文件
```
git stash list
```

应用刚刚贮藏的工作
```
git stash apply
```

应用之前贮藏的工作
```
git stash apply stash@{2}
```

移除贮藏的工作
```
git stash drop stash@{0}
```

应用贮藏时，不会重新暂存之前暂存的文件，重新应用暂存的修改
```
git stash apply --index
```

贮藏所有已暂存的内容，同时保留在索引中
```
git stash --keep-index
```

默认情况下，`git stash` 只会贮藏已修改和暂存的已跟踪文件。 

贮藏任何未跟踪文件
- 如果要贮藏忽略的文件，使用 `--all` 或 `-a`
```
git stash -u
git stash --include-untracked
```

不贮藏所有修改过的任何东西， 交互式地提示哪些改动要贮藏、哪些改动要保存在工作目录中
```
git stash --patch
```

从贮藏创建分支，检出贮藏工作时所在的提交，重新在那应用工作，然后在应用成功后丢弃贮藏
```
git stash branch testchanges
```

清理工作目录，移除未被追踪的文件
```
git clean
```

移除未追踪的文件、空的子目录、被忽略的文件
- `-n`/`--dry-run`：查看将要被移除的文件
- `-d`：子目录
- `-x`：忽略的文件
```
git clean -n -d -x
```

交互式清理
```
git clean -x -i
```

其他选项：
- `-f`：强制删除
- `-f -f`：强制删除目录中存在克隆的其他仓库

## 签署
签署标签，将 `-a` 替换为 `-s`
```
git tag -s v1.5 -m 'my signed 1.5 tag'
```

验证标签，使用 GPG 验证签名
```
git tag -v v1.5
```

提交签署的标签，增加一个 `-S` 选项
```
git commit -a -S -m 'signed commit'
```

查看一条日志，并验证其签名
```
git log --show-signature -1
```

查看日志，验证任何找到的签名（`%G?`）
```
git log --pretty="format:%h %G? %aN  %s"
```

检查并拒绝没有可信 GPG 签名的提交
```
git merge --verify-signatures <branch>
```

签署自己生成的合并提交
```
git merge --verify-signatures -S <branch>
```

## 搜索
查找文件，匹配 `gmtime_r`
- `-n`/`--line-number`：显示匹配行的行号
```
git grep -n gmtime_r
```

仅输出文件包含多少匹配
```
git grep --count gmtime_r
git grep -c gmtime_r
```

显示匹配字符串所在的方法或函数
```
git grep --show-function gmtime_r *.c
git grep -p gmtime_r *.c
```

`--and` 确保多个匹配出现在同一文本
```
git grep --break --heading \
    -n -e '#define' --and \( -e LINK -e BUF_MAX \) v1.8.0
```

`git grep` 优点
- 速度快
- 不仅可以搜索工作目录，还可以搜索任意 Git 树

查找什么时候引入和修改 `ZLIB_BUF_MAX`
```
git log -S ZLIB_BUF_MAX --oneline
```

展示 zlib.c 文件中 git_deflate_bound 函数的变更
- `-L` 展示代码中一行或一个函数的历史
```
git log -L :git_deflate_bound:zlib.c
```

## 重写历史
修改最后一次提交
```
git commit --amend
```

修改最后一次提交的文件：
1. 修改文件
2. 暂存文件
3. `git commit --amend` 替换

修改最后一次提交的文件，但不修改提交信息
```
git commit --amend --no-edit
```

交互式修改多个提交信息，例如，修改最后三次提交
- 实际指定了以前的四次提交
- 反序显示
```
git rebase -i HEAD~3
```

将需要修改的提交 `pick` 改为 `edit`，然后执行
```
# 修改提交信息
git commit --amend
# 继续
git rebase --continue
```

重新排序，修改需要重新排序的提交的顺序即可

压缩提交，将需要压缩到一个提交的提交 `pick` 改为 `squash`

拆分提交，将需要拆分的提交 `pick` 改为 `edit`，然后执行
```
# 混合重置
git reset HEAD^
# 提交1
git add README
git commit -m 'updated README formatting'
# 提交2
git add lib/simplegit.rb
git commit -m 'added blame'
# 继续
git rebase --continue
```

`filter-branch`：通过脚本的方式批量修改提交，例如，全局修改邮箱地址
- 建议使用 [git-filter-repo](https://github.com/newren/git-filter-repo)

## 重置

Git 作为一个系统，是以它的一般操作来管理并操纵这三棵树的：
| 树                | 用途                                 |
| :---------------- | :----------------------------------- |
| HEAD              | 上一次提交的快照，下一次提交的父结点 |
| Index             | 预期的下一次提交的快照               |
| Working Directory | 沙盒                                 |

**HEAD**

当前分支引用的指针，总是指向该分支上的最后一次提交，即 HEAD 将是下一次提交的父结点。 通常可以将它看做该分支上的最后一次提交的快照。

查看 HEAD 快照实际的目录列表
- 这两个是底层命令，日常工作中并不使用
```
git cat-file -p HEAD
git ls-tree -r HEAD
```

**索引**

预期的下一次提交，我们也会将这个概念引用为 Git 的“暂存区”。

Git 将上一次检出到工作目录中的所有文件填充到索引区，它们看起来就像最初被检出时的样子。 之后将其中一些文件替换为新版本，接着通过 `git commit` 将它们转换为树来用作新的提交。

显示索引当前的样子
```
git ls-files -s
```

**工作目录**

通常也叫工作区。HEAD 和索引以一种高效但并不直观的方式，将其内容存储在 `.git` 文件夹中。 工作目录会将它们解包为实际的文件以便编辑。可以把工作目录当做沙盒，将修改提交到暂存区并记录到历史之前，可以随意更改。

查看工作目录
```
tree
```

**工作流程**

经典的 Git 工作流程是通过操纵这三个区域来以更加连续的状态记录项目快照的。
![](https://git-scm.com/book/en/v2/images/reset-workflow.png)

当检出一个分支时，它会修改 HEAD 指向新的分支引用，将索引填充为该次提交的快照，然后将索引的内容复制到工作目录中。

### 重置

1. 移动 HEAD
本质上是撤销了上一次 `git commit` 命令，将该分支移动回原来的位置，而不改变索引和工作目录。

`git reset 9e5e6a4`
- 使用 `reset --soft`，HEAD 将仅仅停在那儿
![](https://git-scm.com/book/en/v2/images/reset-soft.png)

2. 更新索引

指定 `--mixed` 选项（默认行为），撤销一上次提交，并取消暂存所有的东西。
![](https://git-scm.com/book/en/v2/images/reset-mixed.png)

3. 更新工作目录
危险指令：使用 `--hard` 撤销工作目录中的所有工作
![](https://git-scm.com/book/en/v2/images/reset-hard.png)

reset 命令会以特定的顺序重写这三棵树，在指定以下选项时停止：
1. 移动 HEAD 分支的指向 （若指定了 `--soft`，则到此停止）
2. 使索引看起来像 HEAD （若未指定 `--hard`，则到此停止）
3. 使工作目录看起来像索引

若指定了一个路径，`reset` 将会跳过第 1 步，并且将它的作用范围限定为指定的文件或文件集合。因为 HEAD 只是一个指针，无法让它同时指向两个提交中各自的一部分。但是索引和工作目录 可以部分更新，所以重置会继续进行第 2、3 步。

通过具体指定一个提交来拉取该文件的对应版本
- 把工作目录中的文件恢复到 v1 版本，运行 `git add` 添加它， 然后再将它恢复到 v3 版本（只是不用真的过一遍这些步骤）
- 如果现在运行 `git commit`，它就会记录一条“将该文件恢复到 v1 版本”的更改， 尽管实际并未在工作目录中拥有过
```
git reset eb43 -- file.txt
```
![](https://git-scm.com/book/en/v2/images/reset-path3.png)

另外，`reset` 命令也可以接受 `--patch` 选项来一块一块地取消暂存的内容，同 `git add`。

### 压缩
可以使用变基（`rebase`）也可以使用重置（`reset`）

```
# 将 HEAD 移动到想要保留的最近的提交
git reset --soft HEAD~2

# 合并之间的提交
git commit
```
![](https://git-scm.com/book/en/v2/images/reset-squash-r2.png)
![](https://git-scm.com/book/en/v2/images/reset-squash-r3.png)

### 检出
运行 `git checkout [branch]` 与运行 `git reset --hard [branch]` 非常相似，它会更新所有三棵树使其看起来像 `[branch]`，不过有两点重要的区别。

`checkout` 对工作目录是安全的，它会通过检查来确保不会将已更改的文件弄丢，它会在工作目录中先试着简单合并一下，这样所有还未修改过的文件都会被更新，而 `reset --hard` 则会不做检查就全面地替换所有东西。

`reset` 会移动 HEAD 分支的指向，而 `checkout` 会移动 HEAD 自身。
![](https://git-scm.com/book/en/v2/images/reset-checkout.png)

运行 `checkout` 的另一种方式就是指定一个文件路径，这会像 `reset` 一样不会移动 HEAD。类似 `git reset --hard [branch] file`。

此外，同 `git reset` 和 `git add` 一样，`checkout` 也接受 `--patch` 选项，允许选择一块一块地恢复文件内容。

### 总结

HEAD 一列中的 REF 表示该命令移动了 HEAD 指向的分支引用，而 HEAD 则表示只移动了 HEAD 自身。WD Safe 表示工作目录是否会被覆盖。
|                             | HEAD | Index | Workdir | WD Safe? |
| :-------------------------- | :--- | :---- | :------ | :------- |
| **Commit Level**            |      |       |         |          |
| `reset --soft [commit]`     | REF  | NO    | NO      | YES      |
| `reset [commit]`            | REF  | YES   | NO      | YES      |
| `reset --hard [commit]`     | REF  | YES   | YES     | **NO**   |
| `checkout <commit>`         | HEAD | YES   | YES     | YES      |
| **File Level**              |      |       |         |          |
| `reset [commit] <paths>`    | NO   | YES   | NO      | YES      |
| `checkout [commit] <paths>` | NO   | YES   | YES     | **NO**   |

## 高级合并

### 合并冲突
首先，在做一次可能有冲突的合并前尽可能保证工作目录是干净的。如果有正在做的工作，要么提交到一个临时分支要么储藏。 这使得你可以撤销在这里尝试做的任何事情 。如果在尝试一次合并时工作目录中有未保存的改动，下面的这些技巧可能会使你丢失那些工作。

退出合并，尝试恢复到运行合并前的状态
- 如果工作目录中有未储藏、未提交的修改时它不能完美处理
```
git merge --abort
```

忽略空白
```
# 完全忽略空白修改
git merge -Xignore-all-space whitespace
# 将一个空白字符与多个连续的空白字符视作等价
git merge -Xignore-space-change whitespace
```

将冲突文件的这些版本释放出一份拷贝
- `:1:hello.rb` 查找blob 对象 SHA-1 值
```
git show :1:hello.rb > hello.common.rb	# 分叉开始时的位置
git show :2:hello.rb > hello.ours.rb	# 我们的版本
git show :3:hello.rb > hello.theirs.rb	# 他们的版本（即将并入）
```

列出文件 blob 对象的 SHA-1 值
```
git ls-files -u
```

手动修复问题，重新合并
```
git merge-file -p \
    hello.ours.rb hello.common.rb hello.theirs.rb > hello.rb
```

比较合并结果与我们分支上的内容，即查看合并引入了什么
```
git diff --ours
```

比较合并结果与他们分支上的内容，`-b` 表示去除空白
```
git diff --theirs -b
```

查看文件在两边是如何改动的
```
git diff --base
```

清理手动合并创建的拷贝文件
```
git clean -f
```

检出冲突，查看 ours、theirs、base 版本
```
git checkout --conflict=diff3 hello.rb
```

留下一边的修改，丢弃另一边的修改
```
git checkout --ours
git checkout --theirs
```

获取合并中包含的每一个分支的所有独立提交的列表（三点语法）
```
git log --oneline --left-right HEAD...MERGE_HEAD
```

只显示任何一边接触了合并冲突文件的提交，`-p` 选项得到所有冲突文件的区别
```
git log --oneline --left-right --merge
```

在合并冲突后直接运行的 `git diff`  给出组合式差异
- 第一列显示 ours 分支与工作目录的文件区别（添加或删除）
- 第二列显示 theirs 分支与工作目录的拷贝区别
- `<<<<<<<` 与 `>>>>>>>` 行在工作拷贝中但是并不在合并的任意一边中
```
git diff
```

在合并后通过 `git log` 查看冲突是如何解决的
```
git log --cc -p -1
```

### 撤销合并
假设不小心将主题分支合并到 master 分支
![](https://git-scm.com/book/en/v2/images/undomerge-start.png)

修复引用，将分支移动到想要指向的地方（重置分支），缺点：重写历史
```
git reset --hard HEAD~
```

还原提交，撤销一个已存在提交的所有修改，`^M` 与 `C6` 有完全一样的内容
- `-m 1` 标记指出 mainline，即需要被保留下来的父节点（#1：C6）
```
git revert -m 1 HEAD
```
![](https://git-scm.com/book/en/v2/images/undomerge-revert.png)

在主题分支 topic 中增加工作然后再次合并，Git 只会引入被还原的合并之后的修改。
![](https://git-scm.com/book/en/v2/images/undomerge-revert2.png)

撤销之前的还原提交，然后再进行合并提交
- `M` 与 `^M` 抵消，`^^M` 合并了 C3 与 C4 的修改，C8 合并了 C7 的修改
```
git revert ^M
git merge topic
```
![](https://git-scm.com/book/en/v2/images/undomerge-revert3.png)

### 合并策略
上述合并模式都是 `recursive`

合并分支，有冲突则保留指定的分支
```
git merge -Xours topic
git merge -Xtheirs topic
```

合并文件，有冲突则保留指定的文件
```
git merge-file --ours
```

`ours` 策略：假合并，记录一个以两边分支作为父结点的新合并提交，并将当前分支的代码当作合并结果记录下来。
```
git merge -s ours topic
git diff HEAD HEAD~	# 空
```

当再次合并时从本质上欺骗 Git 认为那个分支已经合并过经常是很有用的。
例如，假设你有一个分叉的 release 分支并且在上面做了一些你想要在未来某个时候合并回 master 的工作。与此同时 master 分支上的某些 bugfix 需要向后移植回 release 分支。你可以合并 bugfix 分支进入 release 分支，同时也 `merge -s ours` 合并进 master 分支 （即使那个修复已经在那儿了）这样当你之后再次合并 release 分支时，就不会有来自 bugfix 的冲突。
```
*->*->*->*
 ->*--↑   
```

子树合并的思想是：有两个项目，其中一个映射到另一个项目的一个子目录，或者反过来。
- 类似子模块工作流
- 缺点：复杂

读取一个分支的根目录树到当前的暂存区和工作目录
- 切回 master 分支，将 rack_back 分支拉取到 master 分支中的 rack 子目录
```
git read-tree --prefix=rack/ -u rack_branch
```

当 rack_back 分支更新时，可以切换到该分支拉取上游更新
```
git checkout rack_branch
git pull
```

然后将更新合并到 master 分支
```
git checkout master
git merge --squash -s recursive -Xsubtree=rack rack_branch	# 递归合并
```

查看 rack 子目录与 rack_branch 分支的差异
```
git diff-tree -p rack_branch
```

查看 rack 子目录与其 master 分支的差异
```
git diff-tree -p rack_remote/master
```

## rerere
重用记录的解决方案（reuse recorded resolution, rerere），允许 Git 记住解决一个块冲突的方法， 在下一次看到相同冲突时自动地解决。

应用场景：
- 保证一个长期分支会干净地合并，但是又不想要一串中间的合并提交弄乱提交历史
- 维持一个变基的分支时，或将一个分支合并并修复了一堆冲突后想要用变基来替代合并
- 将一堆正在改进的主题分支合并到一个可测试的 HEAD

启用 rerere
```
git config --global rerere.enabled true
```

显示解决方案的当前状态，即开始解决前与解决后的样子
```
git rerere diff
```

查看冲突文件的之前、左边与右边版本
```
git ls-files -u
```

通过手动改为 `puts 'hola mundo'` 解决冲突，之后 rerere 会记住解决方案。
从本质上说，当 Git 看到一个 hello.rb 文件的一个块冲突中有 `“hello mundo”` 在一边与 `“hola world”` 在另一边，它会将其解决为 `“hola mundo”`
![](https://git-scm.com/book/en/v2/images/rerere2.png)

撤销合并，变基到 master  分支，自动执行冲突解决策略
```
git reset --hard HEAD^
git rebase master
```
![](https://git-scm.com/book/en/v2/images/rerere3.png)

重新恢复到冲突时的文件状态
```
git checkout --conflict=merge hello.rb
```

执行自动冲突解决，然后再继续变基
```
git rerere
git add hello.rb
git rebase --continue
```

## 调试
文件标注，显示任何文件中每行最后一次修改的提交记录。例如，查看 Makefile 中的每一行分别来自哪个提交和提交者，`-L` 限制第 69 到 82 行。
- 提交的部分 SHA-1 值
  - `^` 指出该文件自第一次提交后从未修改的行
- 作者名字
- 提交时间
- 行号
- 文件内容
```
git blame -L 69,82 Makefile
```

`-C` 找出文件中从别的地方复制过来的代码片段的原始出处。例如，将 `GITServerHandler.m` 拆分为数个文件，其中一个文件是 `GITPackUpload.m`。
```
git blame -C -L 141,153 GITPackUpload.m
```

对提交历史进行二分查找
```
git bisect start		# 启动
git bisect bad			# 当前所在提交有问题
git bisect good v1.0	# 已知的最后一次正常提交
```

Git 将检出中间的提交，人工执行测试，如果提交没问题，继续进行寻找
```
git bisect good
```

Git 将继续检出中间的提交，人工执行测试，如果提交是有问题的提交，记录信息
```
git bisect bad
```

现在 Git 拥有的信息已经可以确定引入问题的位置在哪里，它会告诉你第一个错误提交的 SHA-1 值并显示一些提交说明，以及哪些文件在那次提交里被修改过。
```
git bisect good
```

定位问题之后，需要重置 HEAD 指针到最开始的位置
```
git bisect reset
```

使用脚本测试（正常返回 0，不正常返回非 0）
```
git bisect start HEAD v1.0		# 设置查找范围（左右区间）
git bisect run test-error.sh	# 对每个提交执行脚本
```

## 子模块
子模块允许将一个 Git 仓库作为另一个 Git 仓库的子目录。它能将另一个仓库克隆到项目中，同时还保持提交的独立。

### 添加
添加子模块，使用想要跟踪的项目的相对或绝对 URL，默认会将子项目放到一个与仓库同名的目录中。
```
git submodule add https://github.com/chaconinc/DbConnector
```

`.gitmodules` 配置文件保存了项目 URL 与已经拉取的本地目录之间的映射。

本地执行 `git config submodule.DbConnector.url <私有URL>` 覆盖配置选项。


虽然 `DbConnector` 是工作目录中的一个子目录，但 Git 还是会将它视作一个子模块。不在那个目录中时，Git 并不会跟踪它的内容， 而是将它看作子模块仓库中的某个具体的提交。
```
git diff --cached DbConnector
```

查看差异输出
```
git diff --cached --submodule
```

提交时的输出信息显示`160000` 模式，这意味着将一次提交记作一项目录记录，而非将它记录成一个子目录或一个文件。

克隆一个含有子模块的项目，默认会包含该子模块目录，但其中没有任何文件
```
git clone https://github.com/chaconinc/MainProject
```

必须运行两个命令下载子模块的内容
```
git submodule init		# 初始化本地配置
git submodule update	# 从项目中抓取所有数据并检出父项目中列出的合适的提交
```

或者一个命令
```
git submodule update --init
git submodule update --init --recursive	# 检出任何嵌套的子模块
```

### 克隆
克隆时下载子模块，`--recurse-submodules` 自动初始化并更新仓库中的每一个子模块， 包括可能存在的嵌套子模块。
```
git clone --recurse-submodules https://github.com/chaconinc/MainProject
```

在子模块中查看新工作，可以进入到目录中运行 `git fetch` 与 `git merge`，合并上游分支来更新本地代码。
在主项目运行 `git diff --submodule` 可以看到子模块被更新的同时获得了一个包含新添加提交的列表。

设置 `git diff` 默认带上 `--submodule`
```
git config --global diff.submodule log
```

让 Git 进入子模块自动抓取并更新，默认检出 master 分支
```
git submodule update --remote	# 默认更新所有子模块
git submodule update --remote DbConnector	# 更新 DbConnector 子模块
```

设置子模块跟踪其他 stable 分支
```
git config -f .gitmodules submodule.DbConnector.branch stable
```

显示子模块的更新摘要
```
git config status.submodulesummary 1	# 配置
git status
```

查看子模块的提交日志
```
git diff				# 查看将要提交的提交日志
git log -p --submodule	# 查看提交之后的提交日志
```

更新项目中的子模块
```
git pull --recurse-submodules
```

如果子模块的 URL 发生改变
```
# 将新的 URL 复制到本地配置中			# 1
git submodule sync --recursive	   # 2
# 从新 URL 更新子模块				   #3
git submodule update --init --recursive	# 4
```

### 更新
同时跟踪/更新主项目和子模块
```
# 进入子模块并检出其相应的工作分支
cd DbConnector/
git checkout stable

# 更新子模块
cd ..
git submodule update --remote --merge	# 合并上游改动

# 修改子模块内容
cd DbConnector/
vim src/db.c
git commit -am 'unicode support'

# 将子模块的上游更新并入本地
cd ..
git submodule update --remote --rebase
```

检查子模块的改动是否推送
```
git push --recurse-submodules=check
```

尝试推送子模块改动，如果有子模块推送失败，则主项目也会推送失败
```
git push --recurse-submodules=on-demand
```

配置推送时自动检查/尝试
```
git config push.recurseSubmodules check
git config push.recurseSubmodules on-demand
```

子模块分叉，使用 `git diff` 查看相关信息（共有分支，上游提交）
```
cd DbConnector		# 进入子模块
git rev-parse HEAD	# 
git branch try-merge c771610	# 为上游提交创建新分支
git merge try-merge				# 合并
```

解决合并冲突后提交
```
# 解决冲突
vim src/main.c (1)
git add src/main.c
git commit -am 'merged our changes'

# 返回主项目
cd ..

# 检查 SHA-1 值
git diff

# 记录解决冲突的子模块
git add DbConnector

# 提交合并
git commit -m "Merge Tom's Changes"
```

如果子模块目录中存在着这样一个合并提交，它的历史中包含了的两边的提交，那么 Git 会建议将其作为一个可行的解决方案。也可以手动快进到该提交。
```
# 合并
cd DbConnector/
git merge 9fd905e

# 提交
cd ..
git add DbConnector
git commit -am 'Fast forwarded to a common submodule child'
```

### 遍历
保存所有子模块的工作进度
```
git submodule foreach 'git stash'
```

创建新分支，将所有子模块切过去，即生成主项目与所有子项目的改动的统一差异
```
git submodule foreach 'git checkout -b featureA'
```

查看差异
```
git diff; git submodule foreach 'git diff'
```

子模块相关别名设置，使用 `git supdate` 或  `git spush` 检查子模块依赖后推送
```
git config alias.sdiff '!'"git diff && git submodule foreach 'git diff'"
git config alias.spush 'push --recurse-submodules=on-demand'
git config alias.supdate 'submodule update --remote --merge'
```

在记录了子模块的不同提交的分支上切换，记得使用 `--recurse-submodules`
```
git checkout --recurse-submodules master
```

通过配置默认总是使用 `--recurse-submodules`（除了 `git clone`）
```
git config submodule.recurse true
```

### 转换
将子目录转换为子模块
```
# 取消暂存
git rm -r CryptoLibrary/

# 添加子模块
git submodule add https://github.com/chaconinc/CryptoLibrary
```

如果在一个分支下将子目录转换为子模块吗，尝试切换回文件还在子目录的分支时会出错
- 子模块的 Git 数据保存在顶级项目的 `.git` 目录中
```
# 强制切换
git checkout -f master

# 进入空目录
cd CryptoLibrary/

# 找回文件
git checkout .

# 多个子模块
git submodule foreach 'git checkout .'
```

## 打包

将 `git push` 命令所传输的所有内容打包成一个二进制文件，例如，将 master 分支打包为 repo.bundle 文件，同时增加 HEAD 引用（可以克隆）
```
git bundle create repo.bundle HEAD master
```

从 repo.bundle 文件中克隆仓库
```
git clone repo.bundle repo				# 有 HEAD 引用
git clone repo.bundle repo -b master	# 检出分支，无 HEAD 引用
```

打包在 master 分支也不再原始仓库中的提交
```
# 查看 SHA-1
git log --oneline master ^origin/master、

# 打包指定提交区间
git bundle create commits.bundle master ^9a466c5
```

检查打包文件，是否拥有共同的祖先
```
git bundle verify commits.bundle
```

查看打包文件中的分支（顶端）
```
git bundle list-heads commits.bundle
```

取出 master 分支到本地仓库的 other-master 分支
```
git fetch commits.bundle master:other-master
```

## 替换

将 5 个提交拆分为两个历史
```
# 从提交历史创建分支
git branch history c6e1e95

# 推送到新仓库的 master 分支
git remote add project-history https://github.com/schacon/project-history
git push project-history history:master
```
![](https://git-scm.com/book/en/v2/images/replace2.png)


创建基础提交（最初的提交对象），最后一个提交的父提交
- 基础提交包括如何重新组成整个历史的说明
```
echo 'get history from blah blah blah' | git commit-tree 9c68fdc^{tree}
```
![](https://git-scm.com/book/en/v2/images/replace3.png)

将剩下的提交（第四、第五个提交）变基到基础提交
```
git rebase --onto 622e88 9c68fdc
```
![](https://git-scm.com/book/en/v2/images/replace4.png)

获得原始的仓库
```
# 克隆基础提交的那个截断的仓库
git clone https://github.com/schacon/project

# 添加 project-history 历史版本库
git remote add project-history https://github.com/schacon/project-history

# 将 master 分支中的第四个提交替换为 project-history/master 分支中的“第四个”提交
git replace 81a708d c6e1e95
```
![](https://git-scm.com/book/en/v2/images/replace5.png)
