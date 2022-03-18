## 配置
### 客户端
配置 `~/.gitmessage.txt` 模板文件，每次提交时默认使用该提交信息占位符
```
git config --global commit.template ~/.gitmessage.txt
```

配置 `~/.gitignore_global` 全局忽略，
```
git config --global core.excludesfile ~/.gitignore_global
```

着色配置
- 颜色：`normal`、`black`、`red`、`green`、`yellow`、`blue`、`magenta`、`cyan`、`white`
- 字体属性：`bold`、`dim`、`ul`、`blink`、`reverse`
```
color.ui			# 默认值 auto；可选 false、always
color.branch
color.diff
color.interactive
color.status
```

提交时自动地把回车换行（CRLF）转换成换行，检出时把换行转换成回车换行
```
git config --global core.autocrlf true
```

提交时转换为换行
```
git config --global core.autocrlf input
```

保留回车换行
```
git config --global core.autocrlf true
```

处理空白字符，`-` 表示关闭选项
- 行尾空格：`blank-at-eol`
- 文件底部空行：`blank-at-eof`
- tab 前的空格：`pace-before-tab`
- 以空格而非 tab 开头的行：`indent-with-non-tab`
- 行表头表示缩进的 tab：`tab-in-indent`
- 忽略行尾回车：`cr-at-eol`
```
git config --global core.whitespace \
    trailing-space,-space-before-tab,indent-with-non-tab,tab-in-indent,cr-at-eol
```

### 服务端

要求 Git 每次推送时都检查一致性，即确认每个对象的有效性以及 SHA-1 检验和是否保持一致
```
git config --system receive.fsckObjects true
```

禁用强制更新推送（force-push）
```
git config --system receive.denyNonFastForwards true
```

禁止通过推送删除分支和标签
```
git config --system receive.denyDeletes true
```

## 属性
让 Git 把所有 `pbxproj` 文件当成二进制文件，在项目根目录的 `.gitattributes` 文件中设置：
```
*.pbxproj binary
```

### 过滤器

使用过滤器实现关键字展开（keyword expansion），即文件提交或检出时的关键字替换。

过滤器由两个子过滤器组成：
1. smudge 过滤器会在文件被检出时触发
![](https://git-scm.com/book/en/v2/images/smudge.png)

2. clean 过滤器会在文件被暂存时触发
![](https://git-scm.com/book/en/v2/images/clean.png)

`.gitattributes` 文件会随着项目一起提交，而过滤器不会，所以过滤器有可能失效。 设计这些过滤器时，要注重容错性——它们在出错时应该能优雅地退出，从而不至于影响项目的正常运行。

### 归档
导出项目归档（archive）时，可以设置 Git 不导出某些文件和目录。例如，在 `.gitattributes` 文件中设置不导出 test 目录
```
test/ export-ignore
```

将 `git log` 的格式化和关键字展开处理应用到标记了 `export-subst` 属性的部分文件。

在项目中包含一个叫做 LAST_COMMIT 的文件， 并在运行 `git archive` 时自动向它注入最新提交的元数据。在 `.gitattributes` 中设置 LAST_COMMIT 文件
```
LAST_COMMIT export-subst
```
```
echo 'Last commit date: $Format:%cd by %aN$' > LAST_COMMIT
git add LAST_COMMIT .gitattributes
git commit -am 'adding LAST_COMMIT file for archives'
```

运行 `git archive` 之后，归档文件的内容会被替换
```
$ git archive HEAD | tar xCf ../deployment-testing -
$ cat ../deployment-testing/LAST_COMMIT
Last commit date: Tue Apr 21 08:38:48 2009 -0700 by Scott Chacon
```

可以用诸如提交信息或者任意的 `git notes` 进行替换，`git log` 还能做简单的字词折行
```
echo '$Format:Last commit: %h by %aN at %cd%n%+w(76,6,9)%B$' > LAST_COMMIT
git commit -am 'export-subst uses git log'\''s custom formatter
git archive @ | tar xfO - LAST_COMMIT
```

### 合并策略
database.xml 合并冲突时，保留并使用本地分支的数据。设置 `.gitattributes`：
```
database.xml merge=ours
```

然后定义虚拟的合并策略，起名为 `ours`
```
git config --global merge.ours.driver true
```

## 钩子
在特定动作发生时触发的自定义脚本
- 客户端钩子由诸如提交和合并这样的操作所调用
- 服务器端钩子作用于诸如接收被推送的提交这样的联网操作

钩子都被存储在 Git 目录下的 hooks 子目录中，即绝大部分项目中的 `.git/hooks`。
使用 `git init` 初始化仓库时，该目录下会放置一些示例脚本。
把一个正确命名（不带扩展名）且可执行的文件放入 `.git` 目录下的 hooks 子目录中，即可激活该钩子脚本。

注意：克隆仓库时，客户端钩子不会一起复制。

### 客户端
提交工作流钩子
- `pre-commit`：键入提交信息前运行。检查即将提交的快照。
  - 检查代码风格、尾随空白字符、文档等
  - 可以使用 `git commit --no-verify` 跳过
- `prepare-commit-msg`：启动提交信息编辑器前，默认信息被创建后运行。允许编辑提交者看到的默认信息
  - 接收选项：存有当前提交信息的文件的路径、提交类型、修补提交的提交的 SHA-1 校验
  - 对自动产生默认信息的提交，如提交信息模板、合并提交、压缩提交和修订提交等非常实用
- `commit-msg`：
  - 接收选项：存有当前提交信息的临时文件的路径
  - 在提交通过前验证项目状态或提交信息
- `post-commit`：整个提交过程完成后运行。一般用于通知。
  - 可以通过 `git log -1 HEAD` 获得最后一次的提交信息

电子邮件工作流钩子，由 `git am` 命令调用。如果需要通过电子邮件接收由 `git format-patch` 产生的补丁，也许用得上这些钩子。
- `applypatch-msg`
- `pre-applypatch`
- `post-applypatch`

其他钩子
- `pre-rebase`：变基之前运行
  - 可用于禁止对已经推送的提交变基
- `post-rewrite`：被替换提交记录的命令调用，例如 `git commit --amend` 和 `git rebase`
  - 参数：触发重写的命令，标准输入中接收的重写的提交记录
  - 类似 `post-checkout` 和 `post-merge`
- `post-checkout`：检出成功后运行
   - 调整工作目录
- `post-merge`：合并成功后运行
  - 恢复 Git 无法跟踪的工作区数据，验证某些在 Git 控制之外的文件是否存在
- `pre-push`：`git push` 运行期间， 更新了远程引用但尚未传送对象时被调用
  - 参数：远程分支名称和位置，标准输入中接收的一系列待更新的引用
  - 在推送开始之前，验证对引用的更新操作
- `pre-auto-gc`：垃圾回收前运行

### 服务器端
用于对项目强制执行各种类型的策略
- `pre-receive`：处理来自客户端的推送操作
  - 可用于阻止对引用进行非快进（non-fast-forward）的更新，或者对该推送所修改的所有引用和文件进行访问控制
- `update`：和 `pre-receive` 类似，不同在于它会为每一个准备更新的分支各运行一次
  - 参数：引用的名字（分支），推送前的引用指向的内容的 SHA-1 值，用户准备推送的内容的 SHA-1 值
  - 如果以非零值退出，只有相应的那一个引用会被拒绝，其余的依然会被更新
- `post-receive`：在整个过程完结后运行
  - 可以用来更新其他系统服务或者通知用户
  - 接受与 `pre-receive` 相同的标准输入数据
  - 用途包括给某个邮件列表发信，通知持续集成（continous integration）的服务器，更新问题追踪系统（ticket-tracking system），通过分析提交信息来决定某个问题（ticket）是否应该被开启，修改或者关闭
  - 无法终止推送进程，且客户端在它结束运行之前将保持连接状态
