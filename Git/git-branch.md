在进行提交操作时，Git 会保存一个提交对象（commit object）。当使用 `git commit` 进行提交操作时，Git 会先计算每一个子目录（本例中只有项目根目录）的校验和， 然后在 Git 仓库中这些校验和保存为树对象。随后，Git 便会创建一个提交对象， 包含作者的姓名和邮箱、提交时输入的信息，以及指向这个树对象（项目根目录）的指针。 做些修改后再次提交，那么这次产生的提交对象会包含一个指向上次提交对象（父对象）的指针。

特殊指针 `HEAD`指向当前所在的本地分支，随着提交操作自动向前移动。

创建分支，但不切换到该分支
- 在当前的提交对象上创建一个指针
```
git branch testing
```

![](https://git-scm.com/book/en/v2/images/head-to-master.png)

查看各个分支当前所指的对象
```
git log --oneline --decorate
```

切换分支
- 分支切换会改变工作目录中的文件
- 分支实质上是包含所指对象校验和（长度为 40 的 SHA-1 值字符串）的文件
```
git checkout testing
```

创建分支，同时切换到该分支
```
 git checkout -b testing
```

![](https://git-scm.com/book/en/v2/images/head-to-testing.png)

在 testing 分支上提交后切换回 master 分支
```
echo "testing" >> README.md
git commit -a -m 'made a change'
git checkout master
```
![](https://git-scm.com/book/en/v2/images/checkout-master.png)

分叉，在 master 分支上提交
```
echo "master" >> README.md
git commit -a -m 'made another change'
```
![](https://git-scm.com/book/en/v2/images/advance-master.png)

查看分叉历史
```
git log --oneline --decorate --graph --all
```

分支合并，将 iss53 分支合并到 master 分支
- 三方合并：创建新提交（合并提交）
```
git checkout master
git merge iss53
```
![](https://git-scm.com/book/en/v2/images/basic-merging-1.png)
![](https://git-scm.com/book/en/v2/images/basic-merging-2.png)

删除分支
```
git branch -d iss53
```

合并冲突，使用 `git status` 查看冲突文件
- 冲突文件包含冲突解决标记，`=======` 区分两个分支中的内容
```
<<<<<<< HEAD:index.html
<div id="footer">contact : email.support@github.com</div>
=======
<div id="footer">
 please contact us at support@github.com
</div>
>>>>>>> iss53:index.html
```

打开文件解决冲突
```
<div id="footer">
please contact us at email.support@github.com
</div>
```

使用命令标记冲突已解决，完成合并提交
```
git add index.html
git commit
```

图形化工具解决冲突
```
git mergetool
```

查看每个分支的最后一次提交
- 当前 `HEAD` 指针所指的分支前有一个 `*` 符号
```
git branch -v
```

查看已合并到当前分支的分支
```
git branch --merged
```

查看未合并到当前分支的分支
- 删除未合并分支（有未合并内容）会失败
```
git branch --no-merged
```

查看未合并到 master 分支的分支
```
git branch --no-merged master
```

显示远程引用
- 远程引用是对远程仓库的引用（指针），包括分支、标签等。
```
git ls-remote <remote>		# 远程引用
git remote show <remote>	# 远程分支
```

远程分支以 `<remote>/<branch>` 的形式命名

克隆远程仓库
![](https://git-scm.com/book/en/v2/images/remote-branches-1.png)

修改本地分支，同时远程仓库的分支已被更新
![](https://git-scm.com/book/en/v2/images/remote-branches-2.png)

拉取远程仓库，并更新本地数据库
```
git fetch origin
```
![](https://git-scm.com/book/en/v2/images/remote-branches-3.png)

有多个远程仓库的情况
![](https://git-scm.com/book/en/v2/images/remote-branches-5.png)

设置跟踪分支，`git pull` 会自动识别
- 跟踪的分支被称为上游分支（upstream）
```
git checkout --track origin/serverfix
```

检出分支不存在且只有一个匹配的远程分支，则自动创建并跟踪
```
git checkout serverfix
```

本地分支与远程分支设置不同的名称
```
git checkout -b sf origin/serverfix
```

设置已有的本地分支跟踪一个刚刚拉取下来的远程分支，或者想要修改正在跟踪的上游分支
```
git branch --set-upstream-to origin/serverfix
git branch -u origin/serverfix
```

查看设置的所有跟踪分支
- 比对最后一次拉取的数据
```
git branch -vv
```

拉取数据并查看跟踪信息
```
git fetch --all; git branch -vv
```

`git pull` 在大多数情况下等于 `git fetch` + `git merge`

删除远程分支
```
git push origin --delete serverfix
```

检出 experiment 分支，变基（rebase）到 master 分支上
- 提取 C4 中引入的补丁和修改，然后再 C3 的基础上应用
```
git checkout experiment
git rebase master
```
![](https://git-scm.com/book/en/v2/images/basic-rebase-3.png)

切回 master 分支进行一次快进合并（fast-forward）
- 保持提交历史简洁
```
git checkout master
git merge experiment
```
![](https://git-scm.com/book/en/v2/images/basic-rebase-4.png)

选择在 client 分支但不在 server 分支中的修改，将其在 master 分支上重放
- 取出 client 分支，找出它从 server 分支分歧之后的补丁， 然后把这些补丁在 master 分支上重放一遍，让 client 看起来像直接基于 master 修改一样
```
git rebase --onto master server client
```
![](https://git-scm.com/book/en/v2/images/interesting-rebase-1.png)
![](https://git-scm.com/book/en/v2/images/interesting-rebase-2.png)

快进合并 master 分支
```
git checkout master
git merge client
```
![](https://git-scm.com/book/en/v2/images/interesting-rebase-3.png)

将 server 分支变基到 master 分支
```
git rebase master server
```
![](https://git-scm.com/book/en/v2/images/interesting-rebase-4.png)

快进合并 master 分支
```
git checkout master
git merge server
```

删除 client 分支与 server 分支
```
git branch -d client
git branch -d server
```
![](https://git-scm.com/book/en/v2/images/interesting-rebase-5.png)

变基准则：如果提交存在于你的仓库之外，而别人可能基于这些提交进行开发，那么不要执行变基。
