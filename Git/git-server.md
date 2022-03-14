一个远程仓库通常只是一个裸仓库（bare repository）——即一个没有当前工作目录的仓库。因为该仓库仅仅作为合作媒介，不需要从磁盘检查快照；存放的只有 Git 的资料。简单的说，裸仓库就是工程目录内的 `.git` 子目录内容，不包含其他资料。

## 协议

Git 可以使用四种不同的协议来传输资料：本地协议（Local），HTTP 协议，SSH（Secure Shell）协议及 Git 协议。

### 本地协议
- 远程仓库就是同一主机上的另一个目录
  - 共享文件系统（例如，挂载的 NFS），使用路径作为 URL
```
git clone /srv/git/project.git			# 尝试使用硬链接（hard link）或直接复制
git clone file:///srv/git/project.git	# 网络传输（效率更低）
```
指定 `file://` 的主要目的是取得一个没有外部参考（extraneous references）或对象（object）的干净版本库副本——通常是在从其他版本控制系统导入后或一些类似情况需要这么做 。

添加本地仓库到现有 Git 仓库
- 之后可以通过新的远程仓库名 local_proj 从远程仓库推送和拉取更新
```
git remote add local_proj /srv/git/project.git
```

优点：
- 简单

缺点：
- 文件系统较难配置，不便于从多个位置访问
- 不保护仓库避免意外损坏

### HTTP 协议
- Git 1.6.6 引入的新版协议：智能 HTTP 协议（Smart）
- 之前的旧版协议：哑 HTTP 协议（Dumb）

```
git clone https://github.com/jckling/jckling.git
```

智能 HTTP 协议，运行方式和 SSH 及 Git 协议类似，只是运行在标准的 HTTP/S 端口上并且可以使用各种 HTTP 验证机制
- 比 SSH 协议简单，比如可以使用 HTTP 协议的用户名/密码授权，免去设置 SSH 公钥
- 支持像 `git://` 协议一样设置匿名服务， 也可以像 SSH 协议一样提供传输时的授权和加密

哑 HTTP 协议，把裸版本库当作普通文件来对待，提供文件服务
- 设置简单，`post-update` 挂钩会默认执行合适的命令（`git update-server-info`），来确保通过 HTTP 的获取和克隆操作正常工作

优点：
- 不同的访问方式只需要一个 URL 以及服务器只在需要授权时提示输入授权信息
- 可以在 HTTPS 协议上提供只读版本库的服务，在传输数据时可以加密数据
- 可以让客户端使用指定的 SSL 证书

缺点：
- 在一些服务器上，架设 HTTPS 协议的服务端会比 SSH 协议的棘手一些
- 如你在 HTTP 上使用需授权的推送，管理凭证会比使用 SSH 密钥认证麻烦一些

### SSH 协议
- 验证授权的网络协议
- 架设和使用都很容易

通过 SSH 协议克隆版本库，可以指定一个 `ssh://` 的 URL：
```
git clone ssh://[user@]server/project.git
```

或者使用一个简短的 scp 式的写法：
```
git clone [user@]server:project.git
```

如果不指定可选的用户名，那么 Git 会使用当前登录的用的名字。

优点：
- SSH 架设相对简单
- 通过 SSH 访问是安全的，所有传输数据都要经过授权和加密
- SSH 协议很高效，在传输前会尽量压缩数据
  - HTTPS 协议、Git 协议、本地协议

缺点：
- 不支持匿名访问 Git 仓库

### Git 协议
- 包含在 Git 里的一个特殊的守护进程，监听 9418 端口
- 类似于 SSH 服务，但访问无需任何授权

要让仓库支持 Git 协议，需要先创建一个 `git-daemon-export-ok` 文件
- Git 协议守护进程为这个库提供服务的必要条件

```
git clone git@github.com:jckling/jckling.git
```

优点：
- Git 协议是 Git 使用的网络传输协议里最快的
- 使用与 SSH 相同的数据传输机制，但是省去了加密和授权的开销

缺点 ：
- Git 协议也许也是最难架设的
- 缺乏授权机制
  - 通常不能通过 Git 协议推送
  -  一般的做法里，会同时提供 SSH 或者 HTTPS 协议的访问服务，只让少数几个开发者有推送（写）权限，其他人通过 `git://` 访问只有读权限
- 需要防火墙开放非标准端口 9418

## 搭建 Git

### SSH 协议

把现有仓库导出为裸仓库，即一个不包含当前工作目录的仓库
- 照惯例，裸仓库的目录名以 .git 结尾
```
git clone --bare my_project my_project.git
```

拷贝到 git.example.com 服务器的 `/srv/git` 目录下
```
scp -r my_project.git user@git.example.com:/srv/git
```

其他可通过 SSH 读取此服务器上 `/srv/git` 目录的用户可以克隆仓库
- 如果用户对 `/srv/git/my_project.git` 目录拥有可写权限，将自动拥有推送权限
```
git clone user@git.example.com:/srv/git/my_project.git
```

如果到该项目目录中运行 `git init` 命令，并加上 `--shared` 选项， 那么 Git 会自动修改该仓库目录的组权限为可写
- 不会摧毁任何提交、引用等内容
```
ssh user@git.example.com
cd /srv/git/my_project.git
git init --bare --shared
```

SSH 配置
- `authorized_keys`
- `git-shell`

### Git 协议

Git 守护进程
- `--reuseaddr` 选项允许服务器在无需等待旧连接超时的情况下重启
- `--base-path` 选项允许用户在未完全指定路径的条件下克隆项目
- 结尾路径将告诉 Git 守护进程从何处寻找仓库来导出
```
git daemon --reuseaddr --base-path=/srv/git/ /srv/git/
```

使用 `systemd`
- 在 `/etc/systemd/system/git-daemon.service` 中放置文件
- `systemctl enable git-daemon` 设置系统启动时运行
- `systemctl start git-daemon` 启动
- `systemctl stop git-daemon` 停止
```
[Unit]
Description=Start Git Daemon

[Service]
ExecStart=/usr/bin/git daemon --reuseaddr --base-path=/srv/git/ /srv/git/

Restart=always
RestartSec=500ms

StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=git-daemon

User=git
Group=git

[Install]
WantedBy=multi-user.target
```

设置无授权访问的仓库，创建 `git-daemon-export-ok` 文件
- 该文件将允许 Git 提供无需授权的项目访问服务
```
cd /path/to/project.git
touch git-daemon-export-ok
```

### 智能 HTTP 协议
一般通过 SSH 进行授权访问，通过 `git://` 进行无授权访问，使用 HTTP 协议可以同时实现这两种方式的访问。

设置 Smart HTTP 一般只需要在服务器上启用一个 Git 自带的名为 `git-http-backend` 的 CGI 脚本。
- 该 CGI 脚本将会读取由 `git fetch` 或 `git push` 命令向 HTTP URL 发送的请求路径和头部信息，来判断该客户端是否支持 HTTP 通信。 
  - 如果 CGI 发现该客户端支持智能（Smart）模式，它将会以智能模式与它进行通信
  - 否则它将会回落到哑（Dumb）模式下（因此可以对某些旧的客户端实现向下兼容）

使用 Apache 作为 CGI 服务器
- 启用 `mod_cgi`， `mod_alias` 和 `mod_env` 等 Apache 模块
```
sudo apt-get install apache2 apache2-utils
a2enmod cgi alias env
```

将 `/srv/git` 的用户组设置为 `www-data`
- 运行 CGI 脚本的 Apache 实例默认会以该用户的权限运行
```
chgrp -R www-data /srv/git
```

修改 Apache 配置文件
- 如果留空 `GIT_HTTP_EXPORT_ALL`，Git 将只对无授权客户端提供带 `git-daemon-export-ok` 文件的版本库，就像 Git 守护进程一样
```
SetEnv GIT_PROJECT_ROOT /srv/git
SetEnv GIT_HTTP_EXPORT_ALL
ScriptAlias /git/ /usr/lib/git-core/git-http-backend/
```

如果想让 Apache 允许 `git-http-backend` 请求并实现写入操作的授权验证，使用如下授权屏蔽配置即可
```
<Files "git-http-backend">
    AuthType Basic
    AuthName "Git Access"
    AuthUserFile /srv/git/.htpasswd
    Require expr !(%{QUERY_STRING} -strmatch '*service=git-receive-pack*' || %{REQUEST_URI} =~ m#/git-receive-pack$#)
    Require valid-user
</Files>
```

同时需要创建包含所有合法用户密码的 `.htpasswd` 文件，添加 schacon 用户
```
htpasswd -c /srv/git/.htpasswd schacon
```

### GitLab

[GitLab Docs](https://docs.gitlab.com/ee/)

用户指的是对应协作者的帐号
- 用户帐号主要包含登录数据的用户信息集合
- 每一个用户账号都有一个命名空间 ，即该用户项目的逻辑集合

移除用户
- 屏蔽（blocking）：阻止登录，保留命名空间
- 销毁（destroying）：删除用户及其命名空间（包括其中的所有项目）

组是一些项目的集合，连同关于多少用户可以访问这些项目的数据
- 每一个组都有一个项目命名空间（与用户一样）
- 每一个组都有许多用户与之关联，每一个用户对组中的项目以及组本身的权限都有级别区分
- 权限的范围从 “访客”（仅能提问题和讨论） 到 “拥有者”（完全控制组、成员和项目）

项目相当于 git 的版本库
- 每一个项目都属于一个用户或者一个组的单个命名空间
  - 如果这个项目属于一个用户，那么这个拥有者对所有可以获取这个项目的人拥有直接管理权
  - 如果这个项目属于一个组，那么该组中用户级别的权限也会起作用
- 每一个项目都有一个可视级别，控制着谁可以看到这个项目页面和仓库
  - 私有：拥有者明确授权
  - 内部：登录后可见
  - 公开：对所有人可见

在项目和系统级别上都支持钩子程序
- 当有相关事件发生时，GitLab 的服务器会执行一个包含描述性 JSON 数据的 HTTP 请求

### 第三方托管

https://git.wiki.kernel.org/index.php/GitHosting

目前最大的 Git 托管平台：[Github](https://git-scm.com/book/zh/v2/ch00/ch06-github)
