# 常用操作

查看远程仓库
```
git remote -v
```

拉取远程仓库
```
git pull
```

修改上一次未推送的提交信息
```
git commit --amend -m "new commit message"
```

从当前 HEAD 创建并切换分支
```
git checkout -b new_branch
```

切换分支后，删除分支
```
git branch -d old_branch
```

将文件恢复到上一次提交的状态
```
git checkout -- filename 
```

撤销上一次提交（保留修改）
```
git reset HEAD^
```

暂存当前修改，之后可以切换分支

```
git stash
```

应用暂存的的修改

```
git stash apply
```

丢弃暂存内容

```
git stash drop
```

查看简要日志信息
```
git log --oneline --decorate
```

查看简要日志信息以及分叉情况
```
git log --oneline --decorate --graph --all
```

# 相关链接

Git
- [Pro Git 第二版](https://git-scm.com/book/zh/v2)
- [A successful Git branching model](https://nvie.com/posts/a-successful-git-branching-model/)
- [Learn Git with Bitbucket Cloud](https://www.atlassian.com/git/tutorials/learn-git-with-bitbucket-cloud)

Github
- [Github Learning Lab](https://lab.github.com/)
- [how-to-use-github](https://github.com/xirong/my-git/blob/master/how-to-use-github.md)
- [GitHub Cheat Sheet](https://github.com/tiimgreen/github-cheat-sheet/blob/master/README.zh-cn.md)
