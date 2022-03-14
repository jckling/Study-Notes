## 版本控制系统（VCS）
本地版本控制系统：用某种简单的数据库来记录文件的历次更新差异
![](https://git-scm.com/book/en/v2/images/local.png)

集中化的版本控制系统（CVCS）：单一的集中管理服务器，保存所有文件的修订版本
- 单点故障
![](https://git-scm.com/book/en/v2/images/centralized.png)

分布式版本控制系统（DVCS）：客户端把代码仓库完整地镜像下来，包括完整的历史记录
![](https://git-scm.com/book/en/v2/images/distributed.png)

## 配置

有三个级别的配置，每个级别会覆盖上一个级别的配置。

1. `/etc/gitconfig` 文件: 包含系统上每一个用户及他们仓库的通用配置。 如果在执行 `git config` 时带上 `--system` 选项，那么它就会读写该文件中的配置变量。 
-  由于它是系统配置文件，因此需要管理员或超级用户权限来修改。
2. `~/.gitconfig` 或 `~/.config/git/config` 文件：只针对当前用户。可以传递 `--global` 选项让 Git 读写此文件，这会对系统上的**所有**仓库生效。
3. 当前使用仓库的 Git 目录中的 config 文件（即 `.git/config`）：针对该仓库。 可以传递 `--local` 选项让 Git 强制读写此文件，虽然默认情况下用的就是它。
   -  需要进入 Git 仓库中才能让该选项生效。

查看所有的配置及其所在的文件
```
git config --list --show-origin
```

设置用户名和邮件地址
```
git config --global user.name "John Doe"
git config --global user.email johndoe@example.com
```

设置初始化默认分支为 `main`
```
git config --global init.defaultbranch=main
```

列出所有配置文件中的配置（来自不同配置文件的相同项）
```
git config --list
```

列出用户名配置
```
git config user.name
```

查询用户名配置的原始值，返回哪一个配置文件最后设置了该值
```
git config --show-origin user.name
```

## 帮助

查看手册

```
git help <verb>
git <verb> --help

# linux
man git-<verb>
```

`-h` 获取简短的参考信息
```
git add -h
```

## 操作

### 基本操作
初始化本地仓库

```
git init
```

初始提交
```
echo "# tests" >> README.md
git add README.md
git commit -m "first commit"
```

克隆仓库（自动创建 jckling 的目录）
```
git clone https://github.com/jckling/jckling.git
```

克隆仓库并指定目录名为 profile
```
git clone https://github.com/jckling/jckling.git profile
```

![](https://git-scm.com/book/en/v2/images/lifecycle.png)

查看文件状态
```
git status
```

跟踪新文件，文件将处于暂存状态（staged）
- 创建新文件，未跟踪状态（untracked）
- 修改已跟踪文件，修改状态（modified）
```
git add README.md
```

查看文件状态，紧凑输出
- 新添加未跟踪：`??`
- 暂存状态：`A`
- 修改状态：`M`
- 左侧暂存区，右侧工作区（未暂存）
```
git status --short
git status -s
```

忽略文件 `.gitignore`
- 所有空行或者以 `#` 开头的行都会被 Git 忽略。
- 可以使用标准的 glob 模式匹配，它会递归地应用在整个工作区中。
- 匹配模式可以以（`/`）开头防止递归。
- 匹配模式可以以（`/`）结尾指定目录。
- 要忽略指定模式以外的文件或目录，可以在模式前加上叹号（`!`）取反。

示例：https://github.com/github/gitignore
```
# 忽略所有的 .a 文件
*.a

# 但跟踪所有的 lib.a，即便你在前面忽略了 .a 文件
!lib.a

# 只忽略当前目录下的 TODO 文件，而不忽略 subdir/TODO
/TODO

# 忽略任何目录下名为 build 的文件夹
build/

# 忽略 doc/notes.txt，但不忽略 doc/server/arch.txt
doc/*.txt

# 忽略 doc/ 目录及其所有子目录下的 .pdf 文件
doc/**/*.pdf
```

比较工作区和暂存区快照之间的差异，即修改后还没暂存的变化内容
```
git diff
```

查看已暂存，将要添加到下次提交的内容，比对已暂存文件与最后一次提交的文件差异
```
git diff --staged
git diff --cached
```

比较文件差异的外部 diff 工具
```
git difftool --tool-help
```

提交更新，即暂存区快照
```
# 弹出编辑器，设置提交信息
git commit
# 直接设置提交信息
git commit -m "first commit"
```

跳过使用暂存区，直接暂存+提交已跟踪文件，即省略 `git add`
```
git commit -a -m "second commit"
```

移除跟踪（从暂存区移除），同时删除文件
- 删除已修改或已暂存的文件，必须使用 `-f` 参数
```
git rm README.md
```

移除跟踪（从暂存区移除），同时保留文件
```
git rm --cached README.md
```

移除命令支持 `glob` 模式
```
# 删除 log/ 目录下扩展名为 .log 的所有文件
git rm log/\*.log
# 删除所有名字以 ~ 结尾的文件
git rm \*~
```

移动文件/重命名
```
git mv README.md README
# 实际执行三条命令
# mv README.md README
# git rm README.md
# git add README
```

### 提交历史

查看提交历史
```
git log
```

显示每次提交引入的差异（补丁），`-2` 表示只显示最近的两次提交
```
git log -p -2
```

显示简略统计信息
```
git log --stat
```

格式化显示信息
```
# 内置选项 oneline
git log --pretty=oneline
# 自定义格式
git log --pretty=format:"%h - %an, %ar : %s"
```

| 选项  | 说明                                          |
| :---- | :-------------------------------------------- |
| `%H`  | 提交的完整哈希值                              |
| `%h`  | 提交的简写哈希值                              |
| `%T`  | 树的完整哈希值                                |
| `%t`  | 树的简写哈希值                                |
| `%P`  | 父提交的完整哈希值                            |
| `%p`  | 父提交的简写哈希值                            |
| `%an` | 作者名字                                      |
| `%ae` | 作者的电子邮件地址                            |
| `%ad` | 作者修订日期（可以用 --date=选项 来定制格式） |
| `%ar` | 作者修订日期，按多久以前的方式显示            |
| `%cn` | 提交者的名字                                  |
| `%ce` | 提交者的电子邮件地址                          |
| `%cd` | 提交日期                                      |
| `%cr` | 提交日期（距今多长时间）                      |
| `%s`  | 提交说明                                      |

展示分支、合并历史
```
git log --pretty=format:"%h %s" --graph
```

`git log` 常用选项

| 选项              | 说明                                                         |
| :---------------- | :----------------------------------------------------------- |
| `-p`              | 按补丁格式显示每个提交引入的差异。                           |
| `--stat`          | 显示每次提交的文件修改统计信息。                             |
| `--shortstat`     | 只显示 --stat 中最后的行数修改添加移除统计。                 |
| `--name-only`     | 仅在提交信息后显示已修改的文件清单。                         |
| `--name-status`   | 显示新增、修改、删除的文件清单。                             |
| `--abbrev-commit` | 仅显示 SHA-1 校验和所有 40 个字符中的前几个字符。            |
| `--relative-date` | 使用较短的相对时间而不是完整格式显示日期（比如“2 weeks ago”）。 |
| `--graph`         | 在日志旁以 ASCII 图形显示分支与合并历史。                    |
| `--pretty`        | 使用其他格式显示历史提交信息。可用的选项包括 oneline、short、full、fuller 和 format（用来定义自己的格式）。 |
| `--oneline`       | `--pretty=oneline --abbrev-commit` 合用的简写。              |

限制输出长度
```
# 显示最近两周的提交
git log --since=2.weeks
# 显示特定日期范围内的提交
git log --since"2008-01-15" --until="2 years 1 day 3 minutes ago"
# 过滤作者
git log --author=jckling
```

显示添加或删除了特定字符串的提交
```
git log -S functionA
```

`git log` 常用限制选项

| 选项                  | 说明                                       |
| :-------------------- | :----------------------------------------- |
| `-<n>`                | 仅显示最近的 n 条提交。                    |
| `--since`, `--after`  | 仅显示指定时间之后的提交。                 |
| `--until`, `--before` | 仅显示指定时间之前的提交。                 |
| `--author`            | 仅显示作者匹配指定字符串的提交。           |
| `--committer`         | 仅显示提交者匹配指定字符串的提交。         |
| `--grep`              | 仅显示提交说明中包含指定字符串的提交。     |
| `-S`                  | 仅显示添加或删除内容匹配指定字符串的提交。 |


查看 jckling 在 2020.10.1 到 2021.11.1 之间，除了合并提交之外的哪些提交修改了 README.md 文件
```
git log --pretty="%h - %s" --author='jckling' --since="2020-10-01" \
   --before="2021-11-01" --no-merges -- README.md
```

### 撤销操作

重新提交，用新的提交替换旧的提交
- 将暂存区中的文件提交
```
git commit --amend
```

例如，提交后发现忘记暂存某些修改的文件
```
git commit -m 'initial commit'
git add forgotten_file
git commit --amend
```

取消暂存的文件
```
git reset HEAD README.md
```

撤销文件修改
```
git checkout -- README.md
```

### 远程仓库

查看远程仓库，克隆仓库的默认名称 `origin`
```
git remote
```

查看读写远程仓库使用的名称及其对应的 URL
```
git remote -v
```

添加远程仓库
```
git remote add <shortname> <url>
```

拉取远程仓库中的信息，不合并
```
git fetch <remote>
```

推送到远程仓库
```
git push <remote> <branch>
```

查看远程仓库
```
git remote show <remote>
```

修改远程仓库简写名
```
git remote rename origin og
```

移除远程仓库
```
git remote remove og
```

### 标签

列出已有标签
```
git tag
```

使用通配符列出标签
```
git tag -list "v1.8.5*"
git tag -l "v1.8.5*"
```

Git 支持两种标签
- 轻量标签（lightweight）：特定提交的引用，临时标签
- 附注标签（annotated）：可校验的完整对象

创建附注标签（`-a`），`-m` 指定存储在标签中的信息
```
git tag -a v1.4 -m "version 1.4"
```

查看标签信息与对应的提交信息
```
git show v1.4
```

创建轻量标签
```
git tag v1.4-lw
```

轻量标签只会显示提交信息
```
git show v1.4-lw
```

对历史提交打标签
```
git tag -a v1.2 9fceb02
```

推送特定标签（不区分轻量标签和注释标签）
```
git push <remote> <tagname>
```

推送所有标签（不区分轻量标签和注释标签）
```
git push origin --tags
```

删除标签
```
git tag -d v1.4-lw
```

删除远程仓库的标签
```
git push <remote> :refs/tags/<tagname>
# git push origin :refs/tags/v1.4-lw
git push origin --delete <tagname>
```

查看某个标签所指向的文件版本，此时会处于“分离头指针（detached HEAD）”的状态
```
git checkout v1.4
```

“分离头指针”状态下的修改与提交不会使标签产生变化，但新提交不属于任何分支，并且无法访问，除非使用确切的哈希值。
因此，如果需要进行修改，通常要创建一个新分支，例如 `v1.4.1`
```
git checkout -b v1.4.1 v1.4
```

### 别名

git 别名
```
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --' # 取消暂存
git config --global alias.last 'log -1 HEAD' # 查看最后一次提交
```
