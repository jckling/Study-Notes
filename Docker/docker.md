# Docker

> Docker is an open platform for developing, shipping, and running applications.

Docker 最初是 dotCloud 公司的内部项目，开源后公司更名为 Docker。
- [moby/moby](https://github.com/moby/moby)
- [dotCloud, Inc. is Becoming Docker, Inc.](https://www.docker.com/blog/dotcloud-is-becoming-docker-inc/)

Docker 使用 Go 语言进行开发，基于 Linux 内核的 cgroup、namespace，以及 [OverlayFS](https://docs.docker.com/storage/storagedriver/overlayfs-driver/) 类的 Union FS 等技术，对进程进行封装隔离，属于操作系统层面的虚拟化技术。由于隔离的进程独立于宿主和其它的隔离的进程，因此也称其为容器。

目前使用 [runc](https://github.com/opencontainers/runc) 和 [containerd](https://github.com/containerd/containerd) 实现。
- runc 是一个 Linux 命令行工具，根据 [OCI 容器运行时规范](https://github.com/opencontainers/runtime-spec) 创建和运行容器
- containerd 是一个守护程序，用于管理容器生命周期，提供了在一个节点上执行容器和管理镜像的最小功能集

Docker 在容器的基础上，进行了进一步的封装，从文件系统、网络互联到进程隔离等等，极大地简化了容器的创建和维护。

![](https://3503645665-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-M5xTVjmK7ax94c8ZQcm%2Fuploads%2Fgit-blob-6e94771ad01da3cb20e2190b01dfa54e3a69d0b2%2Fvirtualization.png?alt=media)

![](https://3503645665-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-M5xTVjmK7ax94c8ZQcm%2Fuploads%2Fgit-blob-5c1a41d44b8602c8f746e8929f484a701869ca25%2Fdocker.png?alt=media)

Docker 优势
- 对系统资源的利用率更高：不需要硬件虚拟和完整操作系统
- 更快的启动速度：相比虚拟机技术
- 一致的运行环境：确保运行环境一致性
- CI/CD：通过定制镜像（Dockerfile）实现持续集成和持续部署
- 易于迁移
- 易于维护和扩展：分层存储和镜像技术，复用

## 基本概念

### 镜像（Image）

> An image is a read-only template with instructions for creating a Docker container.

特殊的文件系统，除了提供容器运行时所需的程序、库、资源、配置等文件外，还包含了一些为运行时准备的配置参数（如匿名卷、环境变量、用户等）。镜像不包含任何动态数据，其内容在构建之后也不会被改变。

Dockerfile 中的每条指令都会在镜像中创建一个层，当更改 Dockerfile 并重构镜像时，仅重构那些已更改的层。这种分层架构使得镜像的复用、定制更为容易。

### 容器（Container）

> A container is a runnable instance of an image.

容器的实质是进程，但与直接在宿主执行的进程不同，容器进程运行于属于自己的独立的命名空间。因此容器可以拥有自己的 root 文件系统、网络配置、进程空间，甚至用户 ID 空间。

容器内的进程运行在一个隔离的环境里，用起来就像在独立于宿主的系统中操作。这种隔离特性使得容器封装的应用比直接运行在宿主机上的应用更加安全。

容器的存储不会被保存在镜像中，容器在镜像上创建了一个可写的容器层，如果需要持久存储则要使用数据卷或挂载目录，数据卷的生命周期独立于容器。

### 仓库（Repository）

仓库（Repository）是集中存放镜像的地方。注册服务器（Registry）是管理仓库的具体服务器，每个服务器上可以有多个仓库，而每个仓库下面有多个镜像。从这方面来看，仓库可以被认为是一个具体的项目或目录。例如，仓库地址 `docker.io/ubuntu` 中，`docker.io` 是注册服务器地址，`ubuntu` 是仓库名。

Registry 是集中存储和分发镜像的服务，一个 Docker Registry 中可以包含多个仓库（Repository），每个仓库可以包含多个标签（Tag），每个标签对应一个镜像。

通常，一个仓库会包含同一软件不同版本的镜像，而标签常用于对应该软件的各个版本。可以通过 `<仓库名>:<标签>` 的格式指定具体的镜像。如果不给出标签，将以 `latest` 作为默认标签，例如 `ubuntu:18.04`、`ubuntu:latest`。

最常用的 Registry 公开服务是官方的 [Docker Hub](https://hub.docker.com/)，也可以搭建私有的 Registry 服务，比如使用 [Docker Registry](https://hub.docker.com/_/registry/) 镜像构建，或第三方软件 [Harbor](https://github.com/goharbor/harbor) 等。

## 安装

- [Install Docker Engine](https://docs.docker.com/engine/install/)
- [Post-installation steps for Linux](https://docs.docker.com/engine/install/linux-postinstall/)

## 镜像

### 拉取

```bash
docker pull [OPTIONS] NAME[:TAG|@DIGEST]
```

默认从 Docker Hub（`docker.io`）拉取镜像，如果配置了 `registry-mirrors` 则也会尝试从配置的地址拉取。

```bash
$ docker pull ubuntu:18.04

18.04: Pulling from library/ubuntu
40dd5be53814: Pull complete
Digest: sha256:d21b6ba9e19feffa328cb3864316e6918e30acfd55e285b5d3df1d8ca3c7fd3f
Status: Downloaded newer image for ubuntu:18.04
docker.io/library/ubuntu:18.04
```

### 运行

```bash
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
```

参数说明
- `-i`：交互式操作
- `-t`：终端
- `--rm`：退出容器后删除容器
- `ubuntu:18.04`：镜像名称
- `bash`：命令

```bash
$ docker run -it --rm ubuntu:18.04 bash

root@c1df182e36a0:/# cat /etc/os-release
NAME="Ubuntu"
VERSION="18.04.6 LTS (Bionic Beaver)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 18.04.6 LTS"
VERSION_ID="18.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=bionic
UBUNTU_CODENAME=bionic
root@c1df182e36a0:/# exit
exit
```

### 列出

列出所有镜像：仓库名、标签、镜像 ID、创建时间、占用空间

```bash
$ docker image ls
REPOSITORY   TAG       IMAGE ID       CREATED      SIZE
ubuntu       18.04     c6ad7e71ba7d   5 days ago   63.2MB
neo4j        latest    8c32d2595194   9 days ago   584MB
```

Docker Hub 中显示的体积是压缩后的体积，镜像在下载和上传过程中是保持着压缩状态的。而 `docker image ls` 显示的是镜像下载到本地后，展开的各层所占空间的总和。

查看镜像、容器、数据卷所占用的空间

```bash
$ docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          2         0         647.1MB   647.1MB (100%)
Containers      0         0         0B        0B
Local Volumes   0         0         0B        0B
Build Cache     27        0         26.16MB   26.16MB
```

虚悬镜像（dangling image）：由于新旧镜像同名，旧镜像名称被取消，导致仓库名和标签均为 `<none>` 的镜像。

```bash
$ docker image ls -f dangling=true
```

删除虚悬镜像

```bash
$ docker image prune
WARNING! This will remove all dangling images.
Are you sure you want to continue? [y/N] y
Total reclaimed space: 0B
```

`docker image ls` 只会显示顶层镜像，查看中间层镜像需要加上 `-a` 参数。其中许多无标签的镜像都是中间层镜像，即其他镜像所依赖的镜像，不应该被删除。

```bash
$ docker image ls -a
```

根据仓库名列出镜像

```bash
$ docker image ls ubuntu
```

指定仓库名和标签，列出特定镜像

```bash
$ docker image ls ubuntu:18.04
```

过滤，列出在 `mongo:3.2` 之后建立的镜像

```bash
$ docker image ls -f since=mongo:3.2
```

只列出镜像 ID

```bash
$ docker image ls -q
c6ad7e71ba7d
8c32d2595194
```

列出镜像 ID 和仓库名，这里使用了 [Go 的模板语法](https://gohugo.io/templates/introduction/)。

```bash
$ docker image ls --format "{{.ID}}: {{.Repository}}"
c6ad7e71ba7d: ubuntu
8c32d2595194: neo4j
```

以表格形式等距显示镜像 ID、仓库名、标签

```bash
$ docker image ls --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}"
IMAGE ID       REPOSITORY   TAG
c6ad7e71ba7d   ubuntu       18.04
8c32d2595194   neo4j        latest
```

### 删除

```bash
docker image rm [OPTIONS] IMAGE [IMAGE...]
```

使用短 ID 删除

```bash
$ docker image rm c6ad
Untagged: ubuntu:18.04
Untagged: ubuntu@sha256:d21b6ba9e19feffa328cb3864316e6918e30acfd55e285b5d3df1d8ca3c7fd3f
Deleted: sha256:c6ad7e71ba7d4969784c76f57c4cc9083aa96bb969d802f2ea38f4aaed90ff93
Deleted: sha256:3e549931e0240b9aac25dc79ed6a6259863879a5c9bd20755f77cac27c1ab8c8
```

使用镜像名删除，不带标签默认删除 `latest`

```bash
docker image rm ubuntu
```

批量删除镜像

```bash
# 删除仓库名为 redis 的所有镜像
$ docker image rm $(docker image ls -q redis)

# 删除所有在 mongo:3.2 之前建立的镜像
$ docker image rm $(docker image ls -q -f before=mongo:3.2)
```

镜像的唯一标识是 ID 和摘要（DIGEST），而一个镜像可以有多个标签。`Untagged` 取消镜像标签，`Deleted` 删除镜像，从上层往下层删除，若层被其他镜像依赖则不会删除。

### 构建

用户通过 Docker Client 与 Docker Engine 交互（C/S 架构）。

> The build’s context is the set of files at a specified location `PATH` or `URL`.

`docker build` 指定上下文并打包给引擎，默认将上下文目录下名为 `Dockerfile` 的文件作为 Dockerfile，也可以使用参数 `-f` 指定。

```bash
$ docker build [OPTIONS] PATH | URL | -
```

从 URL 构建镜像

```bash
$ docker build -t hello-world https://github.com/docker-library/hello-world.git#master:amd64/hello-world
```

从压缩文件构建镜像

```bash
$ docker build http://server/context.tar.gz

# 从标准输入读取
$ docker build - < context.tar.gz
```

从标准输入读取 Dockerfile，没有上下文，不能执行 `COPY` 等指令

```bash
$ docker build - < Dockerfile

# or
$ cat Dockerfile | docker build -
```

可以使用 `.dockerignore` 排除文件和目录，语法同 `.gitignore`。

### 导入导出

保存镜像为归档文件，同名将会覆盖

```bash
$ docker save <image> > <filename>
$ docker save <image> -o <filename>
$ docker save <image> --output <filename>
```

保存镜像并压缩

```bash
$ docker save <image> | gzip > <filename>.tar.gz
```

加载镜像

```bash
$ docker load < <filename>.tar.gz
$ docker load -i <filename>.tar.gz
$ docker load --input <filename>.tar
```

迁移镜像

```bash
$ docker save <image> | bzip2 | pv | ssh <username>@<hostname> 'cat | docker load'
```

从压缩文件导入，可以是本地文件、目录或 URL。

```bash
docker import [OPTIONS] file|URL|- [REPOSITORY[:TAG]]
```

支持添加提交信息 `--message` 或 `-m`。

```bash
# 本地
$ docker import /path/to/exampleimage.tgz

# 输入流
$ cat exampleimage.tgz | docker import - exampleimagelocal:new
$ cat exampleimage.tgz | docker import --message "New image imported from tarball" - exampleimagelocal:new

# URL
$ docker import https://example.com/exampleimage.tgz
```

## Dockerfile

> A `Dockerfile` is a text document that contains all the commands a user could call on the command line to assemble an image. 

Dockerfile 是一个文本文件，包含指令（instruction），每条指令构建一层。

### FROM

> The `FROM` instruction initializes a new build stage and sets the Base Image for subsequent instructions. 

FROM 设置基础镜像，Dockerfile 必须以 `FROM` 指令开始，基础镜像可以是仓库中的任一镜像。Docker 还存在一个叫 `scratch` 的特殊镜像，表示一个空白的镜像，并不实际存在。

不以任何系统为基础，直接将可执行文件复制进镜像的做法并不罕见，对于 Linux 下静态编译的程序来说，并不需要有操作系统提供运行时支持，所需的一切库都已经在可执行文件里了，因此直接 `FROM scratch` 会让镜像体积更加小巧。使用 Go 语言开发的应用很多会以这种方式来制作镜像，这也是为什么有人认为 Go 是特别适合容器微服务架构的语言的原因之一。

### WORKDIR

> The `WORKDIR` instruction sets the working directory for any `RUN`, `CMD`, `ENTRYPOINT`, `COPY` and `ADD` instructions that follow it in the Dockerfile.

格式

```
WORKDIR /path/to/workdir
```

改变或创建工作目录，可用于切换路径，下面的指令实际会输出 `/a/b/c`。

```dockerfile
WORKDIR /a
WORKDIR b
WORKDIR c
RUN pwd
```

### RUN

> The `RUN` instruction will execute any commands in a new layer on top of the current image and commit the results. 

两种格式
- shell 格式：`RUN <command>`
- exec 格式：`RUN ["executable", "param1", "param2"]`

RUN 用于执行命令，会构建新的一层，因此经常使用 `&&` 串联操作减少不必要的层数，并结合 `rm` 进行清理。Union FS 有最大层数限制，比如 AUFS 最多不超过 127 层。

### COPY

> The `COPY` instruction copies new files or directories from `<src>` and adds them to the filesystem of the container at the path `<dest>`.

两种格式
- `COPY [--chown=<user>:<group>] <src>... <dest>`
- `COPY [--chown=<user>:<group>] ["<src>",... "<dest>"]`

将上下文中的内容复制到镜像的新的一层，使用通配符必须满足 Go 的 [filepath.Match](https://golang.org/pkg/path/filepath/#Match) 规则。

```dockerfile
COPY package.json /usr/src/app/
COPY hom* /mydir/
COPY hom?.txt /mydir/
```

使用 COPY 指令时，源文件的元数据会被保留，比如读、写、执行权限、文件变更时间等。可以使用 `--chown` 参数改变文件所属用户及用户组。

```dockerfile
COPY --chown=55:mygroup files* /somedir/
COPY --chown=bin files* /somedir/
COPY --chown=1 files* /somedir/
COPY --chown=10:11 files* /somedir/
```

如果源路径为文件夹，则会将文件夹中的内容复制到目标路径。目标路径可以是容器内的绝对路径，也可以是相对于工作目录的路径（`WORKDIR` 指定），如果目标路径不存在，则会自动进行创建。

指定多个源路径时，最后一个必须是 `/` 结尾的目标路径。

### ADD

> The `ADD` instruction copies new files, directories or remote file URLs from `<src>` and adds them to the filesystem of the image at the path `<dest>`.

两种格式
- `ADD [--chown=<user>:<group>] <src>... <dest>`
- `ADD [--chown=<user>:<group>] ["<src>",... "<dest>"]`

增强版的 COPY 指令。

源路径可以是 URL，下载的文件将具有 600 权限，并不支持身份验证（使用 `RUN wget/curl`）。

源路径可以是可识别的压缩文件（identity、gzip、bzip2、xz），则解压到目标路径，从 URL 下载的压缩文件不会被解压。

### CMD

> The main purpose of a `CMD` is to provide defaults for an executing container. 

三种格式
- exec 格式：`CMD ["executable","param1","param2"]`
- shell 格式：`CMD command param1 param2`
- `ENTRYPOINT` 的默认参数：`CMD ["param1","param2"]`

用于指定容器的启动命令，只能有一条 CMD 指令，如果有多条则执行最后一条。

### ENTRYPOINT

> An `ENTRYPOINT` allows you to configure a container that will run as an executable.

两种格式
- exec 格式：`ENTRYPOINT ["executable", "param1", "param2"]`
- shell 格式：`ENTRYPOINT command param1 param2`

指定 ENTRYPOINT 后，CMD 指令为其提供参数，否则在运行容器时指定，`docker run <image>` 之后的参数将作为 `ENTRYPOINT` 的附加参数，并覆盖使用 CMD 指定的参数。

exec 格式示例

```dockerfile
FROM ubuntu
ENTRYPOINT ["top", "-b"]
CMD ["-c"]
```

shell 格式示例

```dockerfile
FROM ubuntu
ENTRYPOINT exec top -b
```

将容器用作可执行程序时使用 `ENTRYPOINT`。

### ENV

> The ENV instruction sets the environment variable `<key>` to the value `<value>`. 

格式

```
ENV <key>=<value> ...
```

设置环境变量，之后的指令都可以用。

```dockerfile
ENV MY_NAME="John Doe"
ENV MY_DOG=Rex\ The\ Dog
ENV MY_CAT=fluffy

ENV MY_NAME="John Doe" MY_DOG=Rex\ The\ Dog \
    MY_CAT=fluffy
```

最终镜像也会保留环境变量，这可能会导致意想不到的副作用，因此只在构建镜像时使用的内容可以单独设置，或者使用 `ARG`。

```
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y ...
```

### ARG

> The `ARG` instruction defines a variable that users can pass at build-time to the builder with the `docker build` command using the `--build-arg <varname>=<value>` flag.

格式

```
ARG <name>[=<default value>]
```

有效范围：在 `FROM` 指令之前指定，那么只能用于 `FROM` 指令中；否则为定义及后续构建的那一层。

```dockerfile
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y ...
```

### VOLUME

> The `VOLUME` instruction creates a mount point with the specified name and marks it as holding externally mounted volumes from native host or other containers.

指定目录挂载为匿名卷

```dockerfile
VOLUME ["/data"]
VOLUME /var/log
VOLUME /var/log /var/db
```

运行容器时覆盖，将 `mydata` 命名卷挂载到 `/data` 目录

```bash
$ docker run -d -v mydata:/data <image>
```

### EXPOSE

> The `EXPOSE` instruction informs Docker that the container listens on the specified network ports at runtime.

格式

```
EXPOSE <port> [<port>/<protocol>...]
```

默认监听 TCP，也可以指定协议。

```dockerfile
EXPOSE 80
EXPOSE 80/tcp
EXPOSE 80/udp
```

指定端口映射，`-p <宿主端口>:<容器端口>`

```bash
$ docker run -p 80:80/tcp -p 80:80/udp <image>
```

### USER

> The `USER` instruction sets the user name (or UID) and optionally the user group (or GID) to use when running the image and for any `RUN`, `CMD` and `ENTRYPOINT` instructions that follow it in the Dockerfile.

两种格式
- `USER <user>[:<group>]`
- `USER <UID>[:<GID>]`

设置指令执行的用户和用户组，必须是已创建用户

```dockerfile
FROM microsoft/windowsservercore
# Create Windows user in the container
RUN net user /add patrick
# Set it for subsequent commands
USER patrick
```

### LABEL

> The `LABEL` instruction adds metadata to an image.

格式

```
LABEL <key>=<value> <key>=<value> <key>=<value> ...
```

镜像可以有一个或多个标签。

```dockerfile
LABEL "com.example.vendor"="ACME Incorporated"
LABEL com.example.label-with-value="foo"
LABEL version="1.0"
LABEL description="This text illustrates \
that label-values can span multiple lines."
```

单行指定多个标签。

```dockerfile
LABEL multi.label1="value1" multi.label2="value2" other="value3"

LABEL multi.label1="value1" \
      multi.label2="value2" \
      other="value3"
```

镜像将继承基础镜像的标签，如果有同名键则进行覆盖。

### SHELL

> The `SHELL` instruction allows the default shell used for the shell form of commands to be overridden.

格式

```
SHELL ["executable", "parameters"]
```

指定 `RUN`、`ENTRYPOINT`、`CMD` 指令的 shell，Linux 中默认为 `["/bin/sh", "-c"]`。

`SHELL` 指令可以出现多次，每次会覆盖前一次的设置。

```dockerfile
FROM microsoft/windowsservercore

# Executed as cmd /S /C echo default
RUN echo default

# Executed as cmd /S /C powershell -command Write-Host default
RUN powershell -command Write-Host default

# Executed as powershell -command Write-Host hello
SHELL ["powershell", "-command"]
RUN Write-Host hello

# Executed as cmd /S /C echo hello
SHELL ["cmd", "/S", "/C"]
RUN echo hello
```

### ONBUILD

> The `ONBUILD` instruction adds to the image a trigger instruction to be executed at a later time, when the image is used as the base for another build.

任何构建指令都可以注册为触发器，当镜像作为基础镜像时才会触发执行。

```dockerfile
ONBUILD ADD . /app/src
ONBUILD RUN /usr/local/bin/python-build --dir /app/src
```

### HEALTHCHECK

> The `HEALTHCHECK` instruction tells Docker how to test a container to check that it is still working.

两种格式
- 通过在容器内运行命令检查容器的健康状况：`HEALTHCHECK [OPTIONS] CMD command`
- 禁用任何从基础镜像继承的健康检查：`HEALTHCHECK NONE`

选项
- `--interval=DURATION` (default: `30s`)
- `--timeout=DURATION` (default: `30s`)
- `--start-period=DURATION` (default: `0s`)
- `--retries=N` (default: `3`)

和 `CMD`、`ENTRYPOINT` `一样，HEALTHCHECK` 只可以出现一次，如果写了多个那只有最后一个有效。

支持 shell 格式和 exec 格式的命令，返回值决定检查是否成功，成功返回 0，失败返回 1。每 5 分钟检查本地 Web 服务，3 秒没响应则视为失败。

```dockerfile
HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
```

健康检查的结果可以在 `docker container ls` 中查看。如果健康检查连续失败超过了重试次数，状态就会变为 `unhealthy`。

使用 `docker inspect` 可以查看健康检查命令的输出，包括 `stdout` 与 `stderr`。

```bash
$ docker inspect --format '{{json .State.Health}}' <container> | python -m json.tool
```

### STOPSIGNAL

> The `STOPSIGNAL` instruction sets the system call signal that will be sent to the container to exit.

格式

```
STOPSIGNAL signal
```

可以是信号名称或数字，默认为 `SIGTERM`。

```dockerfile
STOPSIGNAL SIGKILL
STOPSIGNAL 9
```

使用 `docker run` 和 `docker create` 的 `--stop-signal` 参数覆盖容器的的默认停止信号。

### 多阶段构建（multi-stage builds）

#### 建造者模式（Builder Pattern）

一个 Dockerfile 用于开发（包含构建应用程序所需的内容）和一个精简的用于生产的 Dockerfile，只包含应用程序以及运行所需的内容。

`Dockerfile.build`：

```dockerfile
# syntax=docker/dockerfile:1
FROM golang:1.16
WORKDIR /go/src/github.com/alexellis/href-counter/
COPY app.go ./
RUN go get -d -v golang.org/x/net/html \
  && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .
```

`Dockerfile`：

```dockerfile
# syntax=docker/dockerfile:1
FROM alpine:latest  
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY app ./
CMD ["./app"]  
```

`build.sh`：

```sh
#!/bin/sh
echo Building alexellis2/href-counter:build

docker build --build-arg https_proxy=$https_proxy --build-arg http_proxy=$http_proxy \  
    -t alexellis2/href-counter:build . -f Dockerfile.build

docker container create --name extract alexellis2/href-counter:build  
docker container cp extract:/go/src/github.com/alexellis/href-counter/app ./app  
docker container rm -f extract

echo Building alexellis2/href-counter:latest

docker build --no-cache -t alexellis2/href-counter:latest .
rm ./app
```

运行 `build.sh` 构建第一个镜像并创建容器复制内容，然后构建第二个镜像。

#### 多阶段构建

在 Dockerfile 中使用多个 `FROM` 语句，可以使用不同的基础镜像，并且每个都将开始构建的新阶段，可以选择将一个阶段的内容复制到另一个阶段。

`Dockerfile`：

```dockerfile
# syntax=docker/dockerfile:1
FROM golang:1.16
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html  
COPY app.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM alpine:latest  
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=0 /go/src/github.com/alexellis/href-counter/app ./
CMD ["./app"]  
```

只需要一个 Dockerfile 文件，并且只需要执行 `docker build`

```bash
$ docker build -t alexellis2/href-counter:latest .
```

默认情况下阶段没有名称，可以通过整数引用，第一个 `FROM` 从 0 开始，也可以使用 `AS` 命名阶段。

```dockerfile
# syntax=docker/dockerfile:1
FROM golang:1.16 AS builder
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html  
COPY app.go    ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM alpine:latest  
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /go/src/github.com/alexellis/href-counter/app ./
CMD ["./app"]  
```

只构建 `builder` 阶段的镜像，可以在调试、测试时使用。

```bash
$ docker build --target builder -t alexellis2/href-counter:latest .
```

可以从其他镜像中复制文件，如果没有则会进行拉取。

```dockerfile
COPY --from=nginx:latest /etc/nginx/nginx.conf /nginx.conf
```

使用前一个阶段作为新阶段，在 `FROM` 指令中指定阶段。

```dockerfile
# syntax=docker/dockerfile:1
FROM alpine:latest AS builder
RUN apk --no-cache add build-base

FROM builder AS build1
COPY source1.cpp source.cpp
RUN g++ -o /binary source.cpp

FROM builder AS build2
COPY source2.cpp source.cpp
RUN g++ -o /binary source.cpp
```

## 容器

### 启动

`docker run` 命令首先在指定的镜像上创建一个可写的容器层，然后使用指定的命令启动它。


输出 `Hello world` 之后种终止容器

```bash
$ docker run ubuntu:18.04 /bin/echo 'Hello world'
Hello world
```

启动 bash 终端交互
- `-t`：分配伪终端（pseudo-tty）并绑定到容器的标准输入
- `-i`：让容器的标准输入保持打开

```bash
$ docker run -t -i ubuntu:18.04 /bin/bash
root@b544371c0c76:/#
```

启动已终止容器

```bash
$ docker container start b544371c0c76
```

使用 `-d` 让容器在后台运行，并返回容器 ID。注意容器是否会长久运行，与 `docker run` 指定的命令有关，和 `-d` 参数无关。

```bash
$ docker run -d ubuntu:18.04 /bin/sh -c "while true; do echo hello world; sleep 1; done"
bb9425df1601169f2e41df18cbb790cb454195f061fbaa39b4d68dd236bc827a
```

获取容器的输出信息

```bash
$ docker container logs bb9425df
hello world
hello world
hello world
hello world
hello world
hello world
hello world
hello world
hello world
hello world
hello world
hello world
```

### 终止

对于只启动了一个终端的容器，用户通过 `exit` 命令或 `Ctrl+D` 退出终端时，所创建的容器立刻终止。

运行中的容器可以用容器 ID 或名称指定终止。

```bash
$ docker container stop bb9425df
bb9425df
```

启动终止的容器

```bash
$ docker container start bb9425df
bb9425df
```

终止运行中的容器并重启

```
$ docker container restart bb9425df
```

### 进入

进入后台运行的容器

```bash
docker exec -it bb9425df bash
```

也可以使用 `attach`，但是退出终端后会导致容器终止

```bash
docker attach bb9425df
```

### 导入导出

导出容器

```bash
$ docker export bb9425df > ubuntu.tar
```

导入为镜像

```bash
$ cat ubuntu.tar | docker import - test/ubuntu:v1.0
```

既可以使用 `docker load` 导入镜像存储文件到本地镜像库，也可以使用 `docker import` 导入容器快照文件到本地镜像库。区别在于，容器快照文件将丢弃所有历史记录和元数据信息（仅保存容器当时的快照状态），而镜像存储文件将保存完整记录，因此体积会更大。此外，从容器快照文件导入时可以重新指定标签等元数据信息。

### 删除

删除已终止的容器

```bash
$ docker container rm bb9425df
```

删除运行中的容器，终止并删除

```bash
$ docker container rm -f bb9425df
```

清除所有已终止的容器

```bash
$ docker container prune
WARNING! This will remove all stopped containers.
Are you sure you want to continue? [y/N] y
Deleted Containers:
c43f2e025b61776a2cb1ad2855a989251e589f7a5d70fd5e38abf94d6545c2c0

Total reclaimed space: 0B
```

## 数据

![](https://docs.docker.com/storage/images/types-of-mounts.png)

### 数据卷（volume）

由 Docker 创建和管理，主机文件系统的一部分。与挂载相比，有几个优点：
- 更容易备份或迁移
- 可以使用 Docker CLI 或 Docker API 管理
- 适用于 Linux 和 Windows 容器
- 可以在多个容器之间安全共享
- 卷驱动程序允许将卷存储在远程主机或云供应商上，对卷的内容进行加密，或添加其他功能
- 新卷的内容可以由容器预先填充

特点：
- 容器之间共享
- 对卷的修改立即生效
- 对卷的更新不影响镜像
- 生命周期独立于容器

创建数据卷

```bash
$ docker volume create my-vol
my-vol
```

查看所有卷

```bash
$ docker volume ls
DRIVER    VOLUME NAME
local     my-vol
```

查看卷信息

```bash
$ docker volume inspect my-vol
[
    {
        "CreatedAt": "2022-05-05T11:06:47Z",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/my-vol/_data",
        "Name": "my-vol",
        "Options": {},
        "Scope": "local"
    }
]
```

删除卷

```bash
$ docker volume rm my-vol
my-vol
```

启动挂载数据卷的容器，将数据卷 `myvol2` 挂载到容器的 `/app/` 中

```bash
$ docker run -d \
  --name devtest \
  --mount source=myvol2,target=/app \
  nginx:latest
```

使用 `-v` 参数也可以，还支持设置权限，只读 `ro`

```bash
$ docker run -d \
  --name devtest \
  -v myvol2:/app:ro \
  nginx:latest
```

查看数据卷挂载的信息，在 `Mounts` 小节中

```bash
$ docker inspect devtest
```

删除未使用的卷

```bash
docker volume prune
```

其他内容：
- 匿名卷（Dockerfile 中的 `VOLUME` 指令）
- 共享
- 卷驱动程序
- 备份、迁移

### 绑定挂载（bind mount）

将主机上的文件或目录挂载到容器中，与数据卷相比更加高效，但是功能有限，而且依赖于具有特定目录结构的主机文件系统。

挂载主机目录，`--mount` 由多个键值对组成
- `type` 可以是 `bind`、`volume` 或 `tmpfs`
- `source` 可以是主机文件或目录路径、数据卷
- `target` 是容器内的路径
- `readonly`
- `bind-propagation`

```bash
$ docker run -d \
  -it \
  --name devtest \
  --mount type=bind,source="$(pwd)"/target,target=/app \
  nginx:latest
```

同样，也可以使用 `-v` 参数，语法更加简短，由冒号 `:` 分隔的三个字段组成
- 主机文件或目录路径
- 容器内的路径
- （可选）逗号 `,` 分隔

```bash
$ docker run -d \
  -it \
  --name devtest \
  -v "$(pwd)"/target:/app \
  nginx:latest
```

使用 `--mount` 时必须确保主机上的文件或目录存在，`-v` 会自动创建。如果绑定到容器中的非空目录，则容器中的内容将会被覆盖。

使用绑定挂载的一个副作用是，可以通过容器中运行的进程更改主机文件系统，包括创建、修改或删除重要的系统文件或目录。

tmpfs 挂载是临时的，只保留在主机内存中，可以在容器的生命周期内使用，用于存储非持久状态或敏感信息。

## 网络

Docker 允许通过外部访问容器或容器互联的方式来提供网络服务。

Docker 的网络子系统是可插拔的，使用驱动程序。默认情况下存在几个驱动程序，并提供核心网络功能：
- `bridge`：默认
- `host`：使用主机网络
- `overlay`：将多个 Docker 守护进程连接在一起，用于 Swarm
- `ipvlan`：为运营商提供了对第二层 VLAN 标签的完全控制，对底层网络集成感兴趣的用户提供了 IPvlan L3 路由
- `macvlan`：为容器分配 MAC 地址
- `none`：禁用网络，通常与自定义网络驱动程序一同使用
- 网络插件

网络驱动总结
- 用户定义的 bridge 网络：多个容器在同一主机上通信
- host 网络：网络堆栈不与主机隔离
- overlay 网络：不同主机上的容器通信，或者多个应用程序使用 Swarm 服务一起工作
- 第三方网络插件：将 Docker 与专门的网络堆栈集成

启动 Docker 时会创建默认的 bridge 网络，所有启动的容器默认连接到该网络上。而用户定义的 bridge 网络相比该默认网络：
- 提供容器之间的自动 DNS 解析，默认网络只能通过 IP 地址相互访问
- 提供更好的隔离
- 运行时连接和断开
- 不同网络不同配置，连接到默认网络的容器将使用相同配置

使用 host 网络的容器不会会的自己的 IP 地址，可用于优化性能，因为不需要网络地址转换（NAT），仅适用于 Linux 主机。

### 外部访问容器

`-P` 随机端口映射，将容器暴露的所有端口映射到主机的任意端口

```bash
$ docker run -d -P nginx:alpine
```

`-p` 指定端口映射，`地址:主机端口:容器端口/协议类型`

```bash
$ docker run -d -p 80:80 nginx:alpine
```

指定多个端口映射

```bash
$ docker run -d \
    -p 80:80 \
    -p 443:443 \
    nginx:alpine
```

指定地址端口映射，将容器的 80 端口映射到 127.0.0.1 的 80 端口

```bash
$ docker run -d -p 127.0.0.1:80:80 nginx:alpine
```

映射到任意端口，将容器的 80 端口映射到 127.0.0.1 的任意端口

```bash
$ docker run -d -p 127.0.0.1::80 nginx:alpine
```

映射 udp 端口

```bash
$ docker run -d -p 127.0.0.1:80:80/udp nginx:alpine
```

查看端口映射配置

```
docker port CONTAINER [PRIVATE_PORT[/PROTO]]
```

### 容器互联

新建网络，`-d` 指定创建 bridge 类型的网络

```bash
$ docker network create -d bridge my-net
```

运行容器，并链接到 my-net 网络，此时两个容器可以相互 `ping`

```bash
# 终端 1
$ docker run -it --rm --name busybox1 --network my-net busybox sh

# 终端 2
$ docker run -it --rm --name busybox2 --network my-net busybox sh
```

运行时连接和断开

```bash
$ docker network connect my-net my-nginx
$ docker network disconnect my-net my-nginx
```

多个容器组网建议使用 Docker-Compose。

### 配置

默认情况下，容器会继承主机的 DNS 设置，即 `/etc/resolv.conf`。

配置所有容器的 DNS 需要修改 `/etc/docker/daemon.json` 配置文件
   
```json
{
  "dns" : [
    "114.114.114.114",
    "8.8.8.8"
  ]
}
```

只修改特定主机的 DNS 配置可以使用标志
- `--hostname=HOSTNAME`：设置容器的主机名
- `--dns=IP_ADDRESS`：添加 DNS 服务器
- `--dns-search=DOMAIN`：搜索域
- `--dns-opt=OPTION`：DNS 选项及其值的键值对

# 参阅

- [Docker — 从入门到实践](https://yeasy.gitbook.io/docker_practice/)
- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Use multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/)
- [Manage data in Docker](https://docs.docker.com/storage/)
- [Networking overview](https://docs.docker.com/network/)
- [Container networking](https://docs.docker.com/config/containers/container-networking/)
