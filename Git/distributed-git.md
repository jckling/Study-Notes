## 分布式工作流程

### 集中式工作流
- 非快进式（non-fast-forward）推送：合并再提交推送
![](https://git-scm.com/book/en/v2/images/centralized_workflow.png)

### 集成管理者工作流
Git 允许多个远程仓库存在，使得这样一种工作流成为可能：每个开发者拥有自己仓库的写权限和其他所有人仓库的读权限。这种情形下通常会有个代表“官方”项目的权威的仓库。要为这个项目做贡献，你需要从该项目克隆出一个自己的公开仓库，然后将自己的修改推送上去。接着你可以请求官方仓库的维护者拉取更新合并到主项目。维护者可以将你的仓库作为远程仓库添加进来，在本地测试你的变更，将其合并入他们的分支并推送回官方仓库。 

工作流程：
1. 项目维护者推送到主仓库
2. 贡献者克隆此仓库，做出修改
3. 贡献者将数据推送到自己的公开仓库
4. 贡献者给维护者发送邮件，请求拉取自己的更新
5. 维护者在自己本地的仓库中，将贡献者的仓库加为远程仓库并合并修改
6. 维护者将合并后的修改推送到主仓库

![](https://git-scm.com/book/en/v2/images/integration-manager.png)


### 主管与副主管工作流
被称为副主管（lieutenant）的各个集成管理者分别负责集成项目中的特定部分。所有这些副主管头上还有一位称为主管（dictator）的总集成管理者负责统筹。主管维护的仓库作为参考仓库，为所有协作者提供他们需要拉取的项目代码。

工作流程：
1. 普通开发者在自己的主题分支上工作，并根据 master 分支进行变基
  - 这里是主管推送的参考仓库的 master 分支
2. 副主管将普通开发者的主题分支合并到自己的 master 分支中
3. 主管将所有副主管的 master 分支并入自己的 master 分支中
4. 最后，主管将集成后的 master 分支推送到参考仓库中，以便所有其他开发者以此为基础进行变基

适用于复杂项目或需要多级管理的项目。

![](https://git-scm.com/book/en/v2/images/benevolent-dictator.png)

## 贡献
影响因素
- 活跃贡献者的数量
- 项目使用的工作流程
- 提交权限
- 可能包含的外部贡献方法

提交准则：https://github.com/git/git/blob/master/Documentation/SubmittingPatches
- 提交不应该包含任何空白错误（`git diff --check` 检查）
- 让每一个提交成为一个逻辑上的独立变更集
  - 拆分为每个问题一个提交，并且为每一个提交附带一个有用的信息（`git add --patch` 交互式暂存）
- 创建优质提交信息
  - 少于 50 个字符（25个汉字）的单行开始且简要地描述变更，接着是一个空白行，再接着是一个更详细的解释

私有小型团队
- 所有开发者都有仓库的推送权限
- 拉取-合并-提交
![](https://git-scm.com/book/en/v2/images/small-team-flow.png)

私有管理团队
- 只有特定开发者拥有仓库主分支的推送权限
- 引用规范
- 在分支上进行开发，最后合并到主分支
![](https://git-scm.com/book/en/v2/images/managed-team-3.png)
![](https://git-scm.com/book/en/v2/images/managed-team-flow.png)

派生的公开项目
- 没有权限直接更新项目的分支
- 克隆-分支-修改-提交-Fork / Fork-克隆-分支-修改-提交
  - 在分支上修改，避免提交不被接受时回退主分支
- 拉取请求（Pull Request）
![](https://git-scm.com/book/en/v2/images/public-small-1.png)

合并不干净时，可以尝试变基
```
git checkout featureA
git rebase origin/master
git push -f myfork featureA
```
![](https://git-scm.com/book/en/v2/images/public-small-2.png)

压缩 featureB 的改动，解决冲突、改变实现，推送到新分支
- `--squash` 接受被合并的分支上的所有工作，并将其压缩至一个变更集， 使仓库变成一个真正的合并发生的状态，而不会真的生成一个合并提交
- `--no-commit` 选项在默认合并过程中可以用来延迟生成合并提交
```
git checkout -b featureBv2 origin/master
git merge --squash featureB
git commit
git push myfork featureBv2
```

通过邮件的公开项目
- `git format-patch` 生成可邮寄的 mbox 格式文件
- `git imap-send` 发送邮件，需要配置 `~/.gitconfig` 文件
```
[imap]
  folder = "[Gmail]/Drafts"
  host = imaps://imap.gmail.com
  user = user@gmail.com
  pass = YX]8g76G_2^sFbd
  port = 993
  sslverify = false
```
- `git send-email` 通过 SMTP 发送邮件
```
[sendemail]
  smtpencryption = tls
  smtpserver = smtp.gmail.com
  smtpuser = user@gmail.com
  smtpserverport = 587
```

## 维护

在主题分支中工作
- 创建附带命名空间的主题分支
```
git branch sc/ruby_client master
git checkout -b sc/ruby_client master
```

应用补丁
- `git apply xxx.patch` 全部应用或全取消（apply all or abort all）
- `git apply --check xxx.patch` 检查补丁是否可以顺利应用
- `git am xxx.patch` 应用补丁
- `git am --resolved` 手动解决冲突后，暂存新文件，然后继续应用补丁
- `git am -3 xxx.patch` 三方合并

查看 contrib 分支所做的修改（对比和 master 分支的第一个公共祖先）
```
git merge-base contrib master
git diff 36c7db
# 更简洁的形式
git diff $(git merge-base contrib master)
# 或
git diff master...contrib
```

### 合并工作流
直接合并到 master 分支
![](https://git-scm.com/book/en/v2/images/merging-workflows-2.png)

合并到 develop 分支，再合并到 master 分支（快进合并）
- master 分支只会在一个非常稳定的版本发布时才会更新
- 所有的新代码会首先整合进入 develop 分支
![](https://git-scm.com/book/en/v2/images/merging-workflows-3.png)
![](https://git-scm.com/book/en/v2/images/merging-workflows-4.png)
![](https://git-scm.com/book/en/v2/images/merging-workflows-5.png)

### 大项目合并工作流
四个长期分支 + 多个贡献者/命名空间分支
- master 主分支
  - 始终进行快进合并
- next 分支
  - 安全的主题分支会被合并入 next 分支，之后该分支会被推送使得所有人都可以尝试整合到一起的特性
  - 偶尔会被变基
- 用于新工作的 pu（proposed updates）分支
  - 如果主题分支需要更多工作，它则会被并入 pu 分支，当它们完全稳定之后，会被再次并入 master 分支
  - 频繁变基
- 用于维护性向后移植工作（maintenance backports）的 maint 分支
![](https://git-scm.com/book/en/v2/images/large-merges-2.png)

### 变基与拣选工作流
将提交 `e43a6` 拉取到 `master` 分支
```
git cherry-pick e43a6
```
![](https://git-scm.com/book/en/v2/images/rebasing-2.png)

### Rerere
Rerere 是“重用已记录的冲突解决方案（reuse recorded resolution）”的意思。

当启用 rerere 时，Git 将会维护一些成功合并之前和之后的镜像，当 Git 发现之前已经修复过类似的冲突时， 便会使用之前的修复方案，而不需要干预。

```
git config --global rerere.enabled true
```

### 发布
1. 打标签
```
git tag -s v1.5 -m 'my signed 1.5 tag
```

2. 快照归档
```
git archive master --prefix='project/' | gzip > `git describe master`.tar.gz
git archive master --prefix='project/' --format=zip > `git describe master`.zip
```

### 修改日志
生成一份包含从上次发布之后项目新增内容的修改日志（changelog）类文档，例如，给出上次 v1.0.1 发布以来所有提交的总结
```
git shortlog --no-merges master --not v1.0.1
```
