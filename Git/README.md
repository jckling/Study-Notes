# 常用操作

查看远程仓库
```
git remote -v
```

拉取远程仓库
```
git pull
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

查看简要日志信息
```
git log --oneline --decorate
```

查看简要日志信息以及分叉情况
```
git log --oneline --decorate --graph --all
```
