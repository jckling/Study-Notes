# 架构

Docker 使用客户端-服务器架构。Docker 客户端与 Docker 守护进程通信，后者负责构建、运行和分发 Docker 容器的繁重工作。

Docker 客户端和守护进程可以在同一个系统上运行，或者可以将 Docker 客户端连接到远程 Docker 守护进程。

Docker 客户端和守护进程使用 REST API，通过 UNIX 套接字或网络接口进行通信。

另一个 Docker 客户端是 Docker Compose，用于处理由一组容器组成的应用程序。

![](https://docs.docker.com/engine/images/architecture.svg)

## Docker 守护进程

Docker 守护进程（`dockerd`）监听 Docker API 请求并管理 Docker 对象，例如镜像、容器、网络和卷。守护进程还可以与其他守护进程通信，以管理 Docker 服务。

## Docker Client

Docker 客户端（`docker`）是许多 Docker 用户与 Docker 交互的主要方式。当运行 `docker run` 等命令时，客户端会将命令发送给 `dockerd`，由其执行这。`docker` 命令使用 Docker API。Docker 客户端可以与多个守护进程通信。

## Docker Desktop

Docker Desktop 是一个易于安装的应用程序，适用于 Mac 或 Windows 环境，用于构建和共享容器化应用程序和微服务。Docker Desktop 包括 Docker 守护进程（`dockerd`）、Docker 客户端 （`docker`）、Docker Compose、Docker Content Trust、Kubernetes 和 Credential Helper。

## Docker 注册服务

Docker 注册服务存储 Docker 镜像。Docker Hub 是一个任何人都可以使用的公共注册服务，并且 Docker 默认配置在 Docker Hub 上查找镜像。用户可以运行自己的私有注册服务。

当运行 `docker pull` 或 `docker run` 命令时，将从配置的注册服务拉取所需的镜像。当运行 `docker push` 命令时，将会把镜像推送到配置的注册服务。

## Docker 对象

使用 Docker 就是在创建和使用镜像、容器、网络、卷、插件和其他对象。

### 镜像

映像是一个只读模板，包含创建 Docker 容器的说明。通常，一个镜像是基于另一个镜像的，并进行了一些额外的定制。例如，可以构建一个基于 ubuntu 镜像的镜像，安装 Apache Web 服务器和用户自己的应用程序，以及应用程序运行所需的配置。

用户可以创建自己的镜像，也可以使用其他人创建并发布在注册服务的镜像。构建自己的镜像需要创建一个 Dockerfile，用简单的语法定义创建和运行镜像所需的步骤。Dockerfile 中的每条指令都会在镜像中创建一个层。当用户更改 Dockerfile 并重构镜像时，仅重构那些被改变的层。与其他虚拟化技术相比，这是使得镜像轻量、小巧和快速的部分原因。

### 容器

容器是镜像的可运行实例。用户可以使用 Docker API 或 CLI 来创建、启动、停止、移动或删除容器。用户可以将容器连接到一个或多个网络，为其附加存储，甚至可以根据容器的当前状态创建新镜像。

默认情况下，容器与其他容器、容器与主机都是相对隔离的。用户可以控制容器的网络、存储或其他底层子系统与其他容器或主机的隔离程度。

容器由其镜像以及用户在创建或启动时提供给的配置选项定义。当容器被移除时，任何未存储在持久存储中的状态更改都会消失。

### `docker run`

以下命令运行 ubuntu 容器，以交互方式连接到本地命令行会话，运行 `/bin/bash`

```bash
$ docker run -i -t ubuntu /bin/bash
```

假设使用默认的注册服务配置，即 Dockerhub
1. 如果本地没有 ubuntu 镜像，Docker 会从注册服务拉取镜像，同 `docker pull ubuntu`
2. Docker 创建新容器，同 `docker container create`
3. Docker 为容器分配读写文件系统，作为它的最后一层
   - 允许正在运行的容器在其本地文件系统中创建或修改文件和目录。
4. 因为没有指定任何网络选项，Docker 创建网络接口，将容器连接到默认网络并分配 IP 地址
   - 默认情况下，容器可以使用主机网络连接到外部网络
5. Docker 启动容器并执行 `/bin/bash`
   - 容器以交互方式运行并连接到终端（`-i` 和 `-t` 标志），可以用键盘提供输入，同时输出被记录到终端
6. 输入 `exit` 终止 `/bin/bash` 命令时，容器会停止但不会被删除，可以重新启动或删除

# 底层实现

Docker 是用 Go 编程语言编写的，并利用 Linux 内核的一些特性来提供其功能。Docker 使用 `namespace` 技术来提供隔离工作区（容器）。运行容器时，Docker 会为该容器创建一组命名空间。

这些命名空间提供了一层隔离。容器的每个方面都在单独的命名空间中运行，其访问权限仅限于该命名空间。

## 命名空间

Docker 引擎在 Linux 上使用以下命名空间
- `pid`（Process ID）：进程
- `net`（Networking）：网络，包括网络设备、IP、路由等
- `ipc`（InterProcess Communication）：IPC 资源，包括信号量、消息队列、共享内存等
- `mnt`（Mount）：文件系统挂载点
- `uts`（Unix Timesharing System）：主机名、域名
- `user`：用户、用户组

## 控制组

Linux 上的 Docker Engine 还依赖于控制组（`cgroups`）技术。控制组允许 Docker 引擎限制容器的可用硬件资源，例如，限制特定容器的可用内存。

## 联合文件系统

UnionFS（Uniton File System）是通过创建层来操作的文件系统，这使其非常轻量和快速。Docker 引擎使用 UnionFS 为容器提供构建层。Docker 引擎可以使用多种 UnionFS 变体，包括 AUFS、btrfs、vfs 和 DeviceMapper 等。

## 容器格式

Docker 引擎将命名空间、控制组和 UnionFS 组合到一个称为容器格式的包装器中。最初使用的是 `LXC`，后续使用 `libcontainer`，目前使用 `runc` 和 `containerd`。

## 网络

虚拟网络设备对（virtual Ethernet, veth）实现不同网络命名空间（network namespace）之间的通信，实际上通过 docker0 网桥连接。

# 安全

## 安全评估

评估 Docker 安全性时，主要考虑四个方面：
- 内核的内在安全性及其对命名空间和 cgroup 的支持
- Docker 守护进程本身的攻击面
- 容器配置文件中的漏洞，无论是默认的，还是由用户自定义的
- 内核的“加固”安全特性，以及它们如何与容器交互

### 内核命名空间

Docker 容器与 LXC 容器非常相似，具有相似的安全特性。当运行 `docker run` 启动容器时，Docker 会在后台为容器创建一组命名空间和控制组。

命名空间提供了第一种也是最直接的隔离形式，在容器中运行的进程无法看到或影响运行在另一个容器或主机系统中的进程。

每个容器都拥有自己的网络堆栈，这意味着一个容器无法获得对另一个容器的套接字或接口的特权访问。当然，如果主机系统进行了相应配置，那么容器可以通过各自的网络接口进行交互。当为容器指定公共端口或使用链接（`--link`）时，容器就可以相互通信了，可以根据配置限制通信策略。

从网络架构的角度来看，所有容器通过本地主机的网桥接口相互通信，就像使用通用以太网交换机连接的物理机器。

提供内核命名空间和私有网络的代码有多成熟？在内核版本 2.6.15 和 2.6.26 之间引入了内核命名空间，这意味着自 2008 年 7 月（2.6.26 版本发布日期）以来，命名空间代码已经在大量生产系统上进行了测试。命名空间的设计和灵感甚至更早，它实际上是为了重新实现 OpenVZ 的功能，以便合并到主流内核中。而 OpenVZ 最初是在 2005 年发布的，所以设计和实现都相当成熟。

### 控制组

控制组是 Linux 容器的另一个关键组成部分，实现资源审计和限制，提供了许多有用的指标，有助于确保每个容器获得公平的内存、CPU、磁盘 I/O 份额。更重要的是，确保单个容器无法通过耗尽资源使系统瘫痪。

虽然控制组对阻止一个容器访问或影响另一个容器的数据和进程方面没有发挥作用，但对抵御一些拒绝服务攻击至关重要。在多租户平台上尤其重要，例如公共或私有 PaaS，即使在某些应用程序出现异常时，也能保证一致的正常运行时间（和性能）。

控制组也已经存在了一段时间，代码始于 2006 年，最初被合并到内核 2.6.24 中。

### Docker 守护进程攻击面

使用 Docker 运行容器（和应用程序）意味着运行 Docker 守护进程。除非选择无根模式（`rootless`），否则守护进程需要 `root` 权限。

首先，应该只允许受信任的用户控制 Docker 守护进程。Docker 允许在 Docker 主机和容器之间共享目录，同时不需要限制容器的访问权限。这意味着可以启动一个容器，将主机的 `/` 目录映射到其中的 `/host` 目录，那么容器可以不受限地更改主机文件系统。这类似于虚拟化系统允许文件系统资源共享的方式，无法阻止用户与虚拟机共享根文件系统（甚至根块设备）。

例如，如果通过 Web 服务器调用 API 配置容器，应该要加倍​​小心地检查参数，确保恶意用户无法传递精心构造的参数使 Docker 创建任意容器。

出于这个原因，Docker 的 REST API 端点（由 Docker CLI 用于与 Docker 守护进程通信）在 Docker 0.5.2 中发生变化，现在使用 UNIX 套接字替代绑定在 127.0.0.1 上的 TCP 套接字，如果碰巧直接在本地机器上运行 Docker，后者容易受到跨站请求伪造攻击。用户可以使用传统的 UNIX 权限检查来限制对控制套接字的访问。

用户还可以通过 HTTP 公开 REST API，但必须注意上述安全隐患。即使有防火墙限制网络中其他主机对 REST API 端点的访问，该端点仍然可以从容器中访问，并且很容易导致权限提升。因此，必须使用 HTTPS 和证书保护 API 端点，同时建议确保只能从受信任的网络或 VPN 访问。

偏爱 SSH 的用户可以使用 `DOCKER_HOST=ssh://USER@HOST` 或 `ssh -L /path/to/docker.sock:/var/run/docker.sock`。

守护进程也可能受到其他输入的影响，例如，使用 `docker load` 从磁盘加载镜像，或使用 `docker pull` 从网络拉取镜像。从 Docker 1.3.2 开始，镜像在 Linux/Unix 平台上的 `chroot` 子进程中提取。从 Docker 1.10.0 开始，所有镜像都通过其内容的加密校验进行存储和访问，从而限制了攻击者与现有镜像发生碰撞的可能性。

最后，如果在服务器上运行 Docker，建议只在服务器上运行 Docker，并将所有其他服务移动到 Docker 控制的容器中。当然，保留管理工具（可能至少是 SSH 服务器）以及现有的监控/监督进程（例如 `NRPE` 和 `collectd`）是可以的。

### Linux 内核能力机制

默认情况下，Docker 启动的容器功能受限。这意味着什么？

能力机制将二进制 `root/non-root` 二分法转变为细粒度的访问控制系统。进程（如 Web 服务器）如果需要在低于 1024 的端口上绑定，不需要以 `root` 身份运行：它们可以被授予 `net_bind_service` 能力。还有许多其他功能，几乎适用于所有通常需要 `root` 权限的特定领域。

这对容器安全意义重大。

典型的服务器以 `root` 身份运行多个进程，包括 SSH 守护进程、`cron` 守护进程、日志守护进程、内核模块、网络配置工具等。容器则不同，因为几乎所有这些任务都由容器周围的基础设施处理：
- SSH 访问通常由运行在 Docker 主机上的单一服务器管理；
- `cron` 在通常应作为用户进程运行，专门为需要其调度服务的应用程序量身定制，而不是作为平台范围的设施；
- 日志管理通常也交给 Docker，或交给第三方服务，如 Loggly 或 Splunk；
- 硬件管理是无关的，这意味着永远不需要在容器中运行 `udevd` 或等效的守护进程；
- 网络管理发生在容器之外，尽可能地强制分离关注点，这意味着容器永远不需要执行 `ifconfig`、`route` 或 `ip` 命令（除非容器被专门设计为像路由器或防火墙一样工作）。

这意味着在大多数情况下，容器根本不需要“真正的” `root` 权限。因此，容器能够以较小的能力集运行，即容器中的 `root` 比真正的 `root` 拥有更少的权限。例如，它可以：
- 拒绝所有挂载操作；
- 拒绝访问原始套接字（防止数据包欺骗）；
- 拒绝访问某些文件系统操作，例如创建新设备节点、更改文件所有者或更改属性（包括不可变标志）；
- 拒绝模块加载；
- 和许多其他功能。

这意味着即使攻击者设法在容器内提权为 `root`，也很难造成严重破坏，或提权到主机。

这不会影响常规的 Web 应用，但大大减少了恶意用户的攻击媒介。默认情况下，Docker 会丢弃所需功能之外的所有功能，即允许列表而不是拒绝列表。你可以在Linux手册中看到可用能力的完整列表。

运行 Docker 容器的一个主要风险是，给予容器的一组默认功能和挂载可能提供不完整的隔离，无论是独立使用，还是与内核漏洞结合使用时。

Docker 支持添加和删除功能，允许使用非默认配置文件。这可能会使 Docker 通过移除功能变得更安全，或通过增添功能而变得不安全。用户的最佳实践是移除所有能力，除了进程明确需要的能力。

### Docker 内容信任签名验证

可以将 Docker 引擎配置为仅运行签名的镜像。Docker 内容信任的签名验证功能内置于 `dockerd` 二进制文件中。

这是在 Dockerd 配置文件中配置的。

要启用此功能，可以在 `daemon.json` 中配置 trustpinning，只能从被用户指定的根密钥签名的仓库拉取和运行。

这个功能为管理员提供了比以前使用 CLI 强制执行和验证镜像签名更多的洞察力。

### 其他内核安全功能

能力机制只是现代 Linux 内核提供的众多安全功能之一。也可以通过 Docker 来利用现有的知名系统，如 TOMOYO、AppArmor、SELinux、GRSEC 等。

虽然 Docker 目前只启用能力机制，但它不会干扰其他系统，这意味着有许多不同的方法可以加固 Docker 主机。例如：
- 可以用 GRSEC 和 PAX 运行内核，在编译时和运行时都增加了许多安全检查；由于地址随机化等技术，可以抵御许多漏洞。不需要特定于 Docker 的配置，因为这些安全功能适用于系统范围，与容器无关。
- 如果发行版附带 Docker 容器的安全模型模板，可以开箱即用。例如，Docker 官方发布了适用于 AppArmor 的模板，而 Red Hat 为 Docker 提供了 SELinux 策略。这些模板提供了额外的安全网（即使它与能力机制有很大重叠）。
- 可以使用访问控制机制自定义策略。

可以使用第三方工具来加固 Docker 容器，包括特殊的网络拓扑或共享文件系统，也有一些工具可以加固 Docker 容器，而不需要修改 Docker 本身。

从 Docker 1.10 开始，docker 守护进程直接支持用户命名空间，该功能允许将容器中的 `root` 用户映射到容器外的非 uid-0 用户，这有助于降低容器逃逸的风险。该功能是可用的，但默认情况下未启用。

### 总结

默认情况下，Docker 容器是相当安全的，特别是在容器内以非特权用户身份运行进程。

可以通过启用 AppArmor、SELinux、GRSEC 或其他适当的加固系统来增加额外的安全层。

## 安全加固

### 保护 Docker 守护进程套接字

默认情况下，Docker 通过非联网的 UNIX 套接字运行，也可以选择使用 SSH 或 TLS (HTTPS) 套接字进行通信。

#### SSH

注意：给定的 `USERNAME` 必须有权访问远程计算机上的 docker 套接字，参阅 [Manage Docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)。

以下示例创建了一个 `docker context`，使用 SSH 与 `host1.example.com` 主机上的 `dockerd` 守护进程连接，并作为远程计算机上的 `docker-user` 用户：

```bash
$ docker context create \
    --docker host=ssh://docker-user@host1.example.com \
    --description="Remote engine" \
    my-remote-engine
my-remote-engine
Successfully created context "my-remote-engine"
```

创建上下文后，使用 `docker context use` 切换 docker CLI 使用，并连接到远程引擎：

```bash
$ docker context use my-remote-engine
my-remote-engine
```

当然这个主机并不存在，因此使用 `docker info` 打印信息时会报错

```bash
$ docker info
Client:
 Context:    my-remote-engine
 Debug Mode: false
 Plugins:
  buildx: Docker Buildx (Docker Inc., v0.8.2)
  compose: Docker Compose (Docker Inc., v2.4.1)
  sbom: View the packaged-based Software Bill Of Materials (SBOM) for an image (Anchore Inc., 0.6.0)
  scan: Docker Scan (Docker Inc., v0.17.0)

Server:
ERROR: error during connect: Get "http://docker.example.com/v1.24/info": command [ssh -l docker-user -- host1.example.com docker system dial-stdio] has exited with exit status 255, please make sure the URL is valid, and Docker 18.09 or later is installed on the remote host: stderr=ssh: Could not resolve hostname host1.example.com: Name or service not known

errors pretty printing info
```

使用 `default` 上下文切换回默认（本地）守护进程：

```bash
$ docker context use default
default
```

或者，使用 `DOCKER_HOST` 环境变量临时切换 docker CLI，以使用 SSH 连接到远程主机。这不需要创建上下文，并且对于创建和不同引擎的临时连接很有用：

这里同样是显示报错信息~

```bash
$ export DOCKER_HOST=ssh://docker-user@host1.example.com
$ docker info
Client:
 Context:    default
 Debug Mode: false
 Plugins:
  buildx: Docker Buildx (Docker Inc., v0.8.2)
  compose: Docker Compose (Docker Inc., v2.4.1)
  sbom: View the packaged-based Software Bill Of Materials (SBOM) for an image (Anchore Inc., 0.6.0)
  scan: Docker Scan (Docker Inc., v0.17.0)

Server:
ERROR: error during connect: Get "http://docker.example.com/v1.24/info": command [ssh -l docker-user -- host1.example.com docker system dial-stdio] has exited with exit status 255, please make sure the URL is valid, and Docker 18.09 or later is installed on the remote host: stderr=ssh: Could not resolve hostname host1.example.com: Name or service not known

errors pretty printing info
```

为了获得最佳的 SSH 用户体验，请按如下方式配置 `~/.ssh/config`，以便在多次调用 docker CLI 时复用 SSH 连接：

```
ControlMaster     auto
ControlPath       ~/.ssh/control-%C
ControlPersist    yes
```

#### TLS (HTTP)

如果要通过 HTTP 而不是 SSH 访问 Docker，可以通过指定 `tlsverify` 标志并将 Docker 的 `tlscacert` 标志指向受信任的 CA 证书来启用 TLS (HTTPS)。

在守护模式下，只允许使用该 CA 签名的证书认证的客户端连接。在客户端模式下，只连接到具有该 CA 签名的证书的服务器。

**使用 OpenSSL 创建 CA、服务器和客户端密钥**

首先，在 Docker 守护进程的主机上，生成 CA 私钥和公钥：

```bash
# 公私钥
$ openssl genrsa -aes256 -out ca-key.pem 4096

# 证书
$ openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
```

创建服务器密钥和证书签名请求（CSR），确保 `Common Name` 与用于连接 Docker 的主机名匹配

```bash
# 公私钥
$ openssl genrsa -out server-key.pem 4096

# 证书签名请求
$ openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr
```

使用 CA 签署公钥证书：由于 TLS 连接可以通过 IP 地址和 DNS 域名进行，因此需要在创建证书时指定 IP 地址。例如，允许使用 `10.10.10.20` 和 `127.0.0.1` 进行连接：

```bash
$ echo subjectAltName = DNS:$HOST,IP:10.10.10.20,IP:127.0.0.1 >> extfile.cnf
```

将 Docker 守护进程密钥的扩展使用属性设置为仅用于服务器身份验证：

```bash
$  echo extendedKeyUsage = serverAuth >> extfile.cnf
```

生成签名证书

```bash
$ openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf
```

授权插件提供更细粒度的控制，补充双向 TLS 的身份验证。在 Docker 守护进程中运行的授权插件会收到用于连接 Docker 客户端的证书信息。

对于客户端身份验证，创建客户端密钥和证书签名请求：

```bash
# 公私钥
$ openssl genrsa -out key.pem 4096

# 证书签名请求
$ openssl req -subj '/CN=client' -new -key key.pem -out client.csr
```

为了让密钥适用于客户端身份验证，创建一个新的扩展配置文件：

```bash
$ echo extendedKeyUsage = clientAuth > extfile-client.cnf
```

生成签名证书

```bash
$ openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out cert.pem -extfile extfile-client.cnf
```

生成 `cert.pem` 和 `server-cert.pem` 后，可以安全地删除两个证书签名请求和扩展配置文件：

```bash
$ rm -v client.csr server.csr extfile.cnf extfile-client.cnf
```

默认的 `umask` 为 022，密钥对用户和用户组是全局可读和可写的。为保护密钥免受意外损坏，要移除其写入权限。按如下方式更改文件模式，使它们只能由用户读取：

```bash
$ chmod -v 0400 ca-key.pem key.pem server-key.pem
```

证书可以是全局可读的，但用户可能向删除写入权限以防止意外损坏：

```bash
$ chmod -v 0444 ca.pem server-cert.pem cert.pem
```

现在，可以让 Docker 守护进程只接受来自 CA 信任的证书的客户端连接：

```bash
$ dockerd \
    --tlsverify \
    --tlscacert=ca.pem \
    --tlscert=server-cert.pem \
    --tlskey=server-key.pem \
    -H=0.0.0.0:2376
```

要连接到 Docker 并验证其证书，提供客户端密钥、证书和受信任的 CA 进行连接：

```bash
$ docker --tlsverify \
    --tlscacert=ca.pem \
    --tlscert=cert.pem \
    --tlskey=key.pem \
    -H=$HOST:2376 version
```

注意：基于 TLS 的 Docker 应该在 TCP 的 2376 端口运行。

**默认安全**

如果想默认开启 Docker 客户端连接的保护，可以将文件移动到主目录中的 `.docker` 目录，并设置 `DOCKER_HOST` 和 `DOCKER_TLS_VERIFY` 变量，而不是在每次调用时传递 `-H=tcp://$ HOST:2376` 和 `--tlsverify`。

```bash
$ mkdir -pv ~/.docker
$ cp -v {ca,cert,key}.pem ~/.docker
$ export DOCKER_HOST=tcp://$HOST:2376 DOCKER_TLS_VERIFY=1
```

Docker 现在默认是安全连接的。

**其他模式**

如果不想启用完整的双向身份验证，可以通过混合标志以各种其他模式运行 Docker。

守护模式（daemon）
- `tlsverify`、`tlscacert`、`tlscert`、`tlskey`：验证客户端
- `tls`、`tlscert`、`tlskey`：不验证客户端

客户端模式（client）
- `tls`：基于公共/默认 CA 池验证服务器
- `tlsverify`、`tlscacert`：基于给定 CA 验证服务器
- `tls`、`tlscert`、`tlskey`：使用客户端证书验证，不根据给定 CA 对服务器验证
- `tlsverify`、`tlscacert`、`tlscert`、`tlskey`：使用客户端证书验证，并根据给定的 CA 对服务器验证

客户端将发送其客户端证书，因此只需将密钥放入 `~/.docker/{ca,cert,key}.pem`。或者，如果想将密钥存储在另一个位置，可以使用环境变量 `DOCKER_CERT_PATH` 指定该位置。

```bash
$ export DOCKER_CERT_PATH=~/.docker/zone1/
$ docker --tlsverify ps
```

**使用 curl 连接到安全的 Docker 端口**

使用 `curl` 测试 API 需要三个额外的命令行标志：

```bash
$ curl https://$HOST:2376/images/json \
  --cert ~/.docker/cert.pem \
  --key ~/.docker/key.pem \
  --cacert ~/.docker/ca.pem
```

### 使用证书验证仓库客户端

默认情况下，Docker 通过非联网的 Unix 套接字运行，并且必须启用 TLS 才能使 Docker 客户端和守护程序通过 HTTPS 安全通信。TLS 确保注册服务端点的真实性，并且与注册服务之间的通信流量是加密的。

本文演示了如何确保 Docker 注册服务器和 Docker 守护程序（注册服务器的客户端）之间的流量加密，并使用基于证书的客户端-服务器身份验证进行身份验证。

我们将向您展示如何为注册服务安装证书颁发机构（CA）根证书，以及如何设置客户端 TLS 证书进行验证。

#### 了解配置

通过在 `/etc/docker/certs.d` 下创建一个目录来配置自定义证书，该目录使用与注册中心主机名相同的名称（例如 `localhost`），所有 `*.crt` 文件都作为 CA 根目录添加到此目录。

注意：在 Linux 上，任何根证书颁发机构都会与系统默认值合并，包括主机的根 CA 集。如果在 Windows Server 上运行 Docker，或者在 Windows 上运行 Docker Desktop，仅在未配置自定义根证书时才使用系统默认证书。

一个或多个 `<filename>.key/cert` 对的存在向 Docker 表明访问指定仓库需要自定义证书。

注意：如果存在多个证书，则按字母顺序尝试。如果出现 4xx 级别或 5xx 级别的身份认证错误，Docker 将继续尝试下一个证书。

具有自定义证书的配置示例：

```
   /etc/docker/certs.d/        <-- Certificate directory
   └── localhost:5000          <-- Hostname:port
      ├── client.cert          <-- Client certificate
      ├── client.key           <-- Client key
      └── ca.crt               <-- Certificate authority that signed
                                   the registry certificate
```

#### 创建客户端证书

使用 OpenSSL 的 `genrsa` 和 `req` 命令，首先生成一对 RSA 密钥，然后创建证书。

```bash
# 公私钥
openssl genrsa -out client.key 4096

# 证书
$ openssl req -new -x509 -text -key client.key -out client.cert
```

注意：这些 TLS 命令仅在 Linux 上生成一套有效的证书，macOS 中的 OpenSSL 版本与 Docker 所需的证书类型不兼容。

#### 故障排除

Docker 守护进程将 `.crt` 文件解释为 CA 证书，将 `.cert` 文件解释为客户端证书。如果 CA 证书的扩展名是 `.cert`，那么 Docker 守护进程会记录以下错误消息：

```
Missing key KEY_NAME for client certificate CERT_NAME. CA certificates should use the extension .crt.
```

如果在访问 Docker 注册服务时不用端口号，则不要将端口添加到目录名称中。例如，在默认端口 443 上的注册中心配置，可以通过 `docker login my-https.registry.example.com` 访问：

```bash
   /etc/docker/certs.d/
   └── my-https.registry.example.com          <-- Hostname without port
      ├── client.cert
      ├── client.key
      └── ca.crt
```

### 使用受信的镜像

在网络系统之间传输数据时，信任是一个核心问题。特别是，当通过互联网等不受信任的媒介进行通信时，确保系统运行的所有数据的完整性和发布者是至关重要的。使用 Docker 引擎从公共或私有注册中心拉取或推送镜像（数据），内容信任能够验证通过任何渠道从注册中心接收的所有数据的完整性和发布者。

Docker 内容信任（Docker Content Trust, DCT）

### 杀毒软件

当杀毒软件扫描 Docker 使用的文件时，这些文件可能会被锁定，从而导致 Docker 命令挂起。

减少这些问题的一种方法是将 Docker 数据目录（Linux 上的 `/var/lib/docker`、Windows Server 上的 `%ProgramData%\docker`、Mac 上的 `$HOME/Library/Containers/com.docker.docker/`）添加到杀毒软件的排除列表。然而，这样做的代价是 Docker 镜像、容器的可写层或卷中的病毒或恶意软件不会被检测到。如果选择排除 Docker 数据目录，可能需要安排任务停止 Docker、扫描数据目录、重启 Docker。

### AppArmor 安全配置文件

AppArmor (Application Armor) 是一个 Linux 安全模块，用于保护操作系统及其应用程序免受安全威胁。为了使用它，系统管理员要将 AppArmor 安全配置文件与每个程序关联起来。Docker 期望找到加载和执行的 AppArmor 策略。

Docker 自动生成并加载 `docker-default` 的默认容器配置文件，Docker 二进制程序在 `tmpfs` 中生成此配置文件，然后将其加载到内核中。

注意：该配置文件用于容器，而不是 Docker 守护进程。

Docker 引擎守护进程的配置文件是存在的，但目前没有和 `deb` 包一起安装。如果对守护进程配置文件的源代码感兴趣，可以参阅 [contrib/apparmor](https://github.com/moby/moby/tree/master/contrib/apparmor)。

#### 理解策略

`docker-default` 配置文件是运行容器的默认配置。它具有适度的保护性，同时提供广泛的应用兼容性。该配置文件是从 [模板](https://github.com/moby/moby/blob/master/profiles/apparmor/template.go) 生成的。

运行一个容器时，默认使用 `docker-default` 策略，不过可以用 `--security-opt` 选项来覆盖。例如，指定默认策略：

```bash
$ docker run --rm -it --security-opt apparmor=docker-default hello-world
```

#### 加载和卸载配置文件

将新配置文件加载到 AppArmor：

```bash
apparmor_parser -r -W /path/to/your_profile
```

使用 `--security-opt` 运行自定义配置文件：

```bash
$ docker run --rm -it --security-opt apparmor=your_profile hello-world
```

从 AppArmor 卸载配置文件：

```bash
$ apparmor_parser -R /path/to/profile
```

#### 编写配置文件

AppArmor 中的文件通配语法与其他通配实现略有不同，建议查阅以下材料：
- [Quick Profile Language](https://gitlab.com/apparmor/apparmor/wikis/QuickProfileLanguage)
- [Globbing Syntax](https://gitlab.com/apparmor/apparmor/wikis/AppArmor_Core_Policy_Reference#AppArmor_globbing_syntax)

#### Nginx 示例配置文件

为 Nginx 创建自定义 AppArmor 配置文件

```
#include <tunables/global>


profile docker-nginx flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  network inet tcp,
  network inet udp,
  network inet icmp,

  deny network raw,

  deny network packet,

  file,
  umount,

  deny /bin/** wl,
  deny /boot/** wl,
  deny /dev/** wl,
  deny /etc/** wl,
  deny /home/** wl,
  deny /lib/** wl,
  deny /lib64/** wl,
  deny /media/** wl,
  deny /mnt/** wl,
  deny /opt/** wl,
  deny /proc/** wl,
  deny /root/** wl,
  deny /sbin/** wl,
  deny /srv/** wl,
  deny /tmp/** wl,
  deny /sys/** wl,
  deny /usr/** wl,

  audit /** w,

  /var/run/nginx.pid w,

  /usr/sbin/nginx ix,

  deny /bin/dash mrwklx,
  deny /bin/sh mrwklx,
  deny /usr/bin/top mrwklx,


  capability chown,
  capability dac_override,
  capability setuid,
  capability setgid,
  capability net_bind_service,

  deny @{PROC}/* w,   # deny write for all files directly in /proc (not in a subdir)
  # deny write to files not in /proc/<number>/** or /proc/sys/**
  deny @{PROC}/{[^1-9],[^1-9][^0-9],[^1-9s][^0-9y][^0-9s],[^1-9][^0-9][^0-9][^0-9]*}/** w,
  deny @{PROC}/sys/[^k]** w,  # deny /proc/sys except /proc/sys/k* (effectively /proc/sys/kernel)
  deny @{PROC}/sys/kernel/{?,??,[^s][^h][^m]**} w,  # deny everything except shm* in /proc/sys/kernel/
  deny @{PROC}/sysrq-trigger rwklx,
  deny @{PROC}/mem rwklx,
  deny @{PROC}/kmem rwklx,
  deny @{PROC}/kcore rwklx,

  deny mount,

  deny /sys/[^f]*/** wklx,
  deny /sys/f[^s]*/** wklx,
  deny /sys/fs/[^c]*/** wklx,
  deny /sys/fs/c[^g]*/** wklx,
  deny /sys/fs/cg[^r]*/** wklx,
  deny /sys/firmware/** rwklx,
  deny /sys/kernel/security/** rwklx,
}
```

1. 将自定义配置文件保存到 `/etc/apparmor.d/containers/docker-nginx`
   
   也可以保存到其他位置
   
2. 加载配置文件
   
   ```
   sudo apparmor_parser -r -W /etc/apparmor.d/containers/docker-nginx
   ```

3. 使用配置文件运行容器，以分离模式运行 Nginx
   
   ```
   $ docker run --security-opt "apparmor=docker-nginx" \
     -p 80:80 -d --name apparmor-nginx nginx
   ```

4. 连接到正在运行的容器
   
   ```
   $  docker container exec -it apparmor-nginx bash
   ```

5. 测试配置文件
   
   ```
   $ ping 8.8.8.8
   ping: Lacking privilege for raw socket.
   $ top
   bash: /usr/bin/top: Permission denied
   $ touch ~/thing
   touch: cannot touch 'thing': Permission denied
   $ sh
   bash: /bin/sh: Permission denied
   $ dash
   bash: /bin/dash: Permission denied
   ```

#### 调试 AppArmor

可以用 `dmesg` 来调试问题，并用 `aa-status` 检查加载的配置文件。

**使用 dmesg**

AppArmor 会向 `dmesg` 发送非常详细的消息。通常 AppArmor 发送的消息会像是这样：

```
[ 5442.864673] audit: type=1400 audit(1453830992.845:37): apparmor="ALLOWED" operation="open" profile="/usr/bin/docker" name="/home/jessie/docker/man/man1/docker-attach.1" pid=10923 comm="docker" requested_mask="r" denied_mask="r" fsuid=1000 ouid=0
```

`profile=/usr/bin/docker` 意味着用户已经加载了 `docker-engine`（Docker 引擎守护进程）配置文件

或者会像是这样：

```
[ 3256.689120] type=1400 audit(1405454041.341:73): apparmor="DENIED" operation="ptrace" profile="docker-default" pid=17651 comm="docker" requested_mask="receive" denied_mask="receive"
```

配置文件是 `docker-default`，默认情况下在容器上运行，除非在特权模式（`privileged`）下。上面的日志显示 apparmor 已拒绝容器中的 `ptrace`，这与预期完全一致。

**使用 aa-status**

`aa-status` 的输出结果会像是这样：

```bash
$ sudo aa-status
apparmor module is loaded.
14 profiles are loaded.
1 profiles are in enforce mode.
   docker-default
13 profiles are in complain mode.
   /usr/bin/docker
   /usr/bin/docker///bin/cat
   /usr/bin/docker///bin/ps
   /usr/bin/docker///sbin/apparmor_parser
   /usr/bin/docker///sbin/auplink
   /usr/bin/docker///sbin/blkid
   /usr/bin/docker///sbin/iptables
   /usr/bin/docker///sbin/mke2fs
   /usr/bin/docker///sbin/modprobe
   /usr/bin/docker///sbin/tune2fs
   /usr/bin/docker///sbin/xtables-multi
   /usr/bin/docker///sbin/zfs
   /usr/bin/docker///usr/bin/xz
38 processes have profiles defined.
37 processes are in enforce mode.
   docker-default (6044)
```

上面的输出显示，在各种容器 PID 上运行的 `docker-default` 配置文件处于 `enforce` 模式，这意味着 AppArmor 会在 `dmesg` 中主动阻止和审计 `docker-default` 配置文件范围之外的任何内容。

上面的输出还显示 `/usr/bin/docker`（Docker 引擎守护进程）配置文件正在以 `complain` 模式运行，这意味着 AppArmor 仅记录配置文件范围之外的 `dmesg` 活动。

### Seccomp 安全配置文件

安全计算模式（`seccomp`）是 Linux 内核特性，可以用它来限制容器内的可用操作。`seccomp()` 系统调用对调用进程的 seccomp 状态进行操作，可以用这个功能来限制应用程序的访问。

仅当 Docker 已使用 seccomp 构建并且内核配置为启用了 CONFIG_SECCOMP 时，此功能才可用。要检查您的内核是否支持 seccomp：

这个功能只有在 Docker 使用 seccomp 构建、内核被配置为启用 `CONFIG_SECCOMP` 时才可用。检查内核是否支持seccomp：

```bash
$ grep CONFIG_SECCOMP= /boot/config-$(uname -r)
```

注意：`seccomp` 配置文件需要 seccomp 2.2.1，这在 Ubuntu 14.04、Debian Wheezy 或 Debian Jessie 上不可用。

#### 传递容器配置文件

默认的 `seccomp` 配置文件为使用 seccomp 运行容器提供了合理的默认值，并禁用了 300 多个系统调用中的大约 44 个。它具有适度的保护性，同时提供广泛的应用兼容性。默认的 Docker 配置文件可以在这里找到：[moby/profiles/seccomp/default.json](https://github.com/moby/moby/blob/master/profiles/seccomp/default.json)。

实际上，配置文件是一个允许列表，默认拒绝对系统调用的访问，允许特定的系统调用。该配置文件通过定义 `SCMP_ACT_ERRNO` 的 `defaultAction` 工作，并且只对特定系统调用行为。`SCMP_ACT_ERRNO` 的作用是导致 `Permission Denied` 错误。接下来，配置文件定义了完全允许的系统调用的具体列表，因为它们的 `action` 被覆盖为 `SCMP_ACT_ALLOW`。最后，一些特定的规则是针对个别系统调用的，例如 `personality` 等，允许这些系统调用的变体与特的参数。

`seccomp` 对于以最低权限运行 Docker 容器非常有用，不建议更改默认的 `seccomp` 配置文件。

运行一个容器时，使用默认配置文件，不过可以用 `--security-opt` 选项来覆盖。例如，指定策略：

```bash
$ docker run --rm \
             -it \
             --security-opt seccomp=/path/to/seccomp/profile.json \
             hello-world
```

**被默认配置文件阻止的重要系统调用**

Docker 的默认 seccomp 配置文件是一个允许列表，它指定允许的调用。下表列出了由于不在允许列表中而被阻止的重要（但不是全部）系统调用。

[Significant syscalls blocked by the default profile](https://docs.docker.com/engine/security/seccomp/#significant-syscalls-blocked-by-the-default-profile)

#### 不使用默认 seccomp 配置文件运行

可以通过 `unconfined` 来运行没有默认 seccomp 配置文件的容器：

```bash
$ docker run --rm -it --security-opt seccomp=unconfined debian:jessie \
    unshare --map-root-user --user sh -c whoami
```

### 使用用户命名空间隔离容器

Linux 命名空间为正在运行的进程提供隔离，限制它们对系统资源的访问，而运行中的进程并不知道这些限制。

防止来容器内的权限提升攻击的最佳方法是，将容器的应用程序配置为以非特权身份运行。对于进程必须在容器内以 `root` 身份运行的容器，可以将此用户重新映射到 Docker 主机上的低权限用户。映射的用户被分配了一系列 UID，这些 UID 在命名空间中作为正常 UID 使用，范围从 0 到 65536 起作用，但在主机上没有任何权限。

#### 重映射

重新映射由两个文件处理：`/etc/subuid` 和 `/etc/subgid`。每个文件的工作原理相同，但一个与用户 ID 范围有关，另一个与组 ID 范围有关。例如，`/etc/subuid` 中的以下条目：

```
testuser:231072:65536
```

这意味着 `testuser` 被分配了一个从属用户 ID 范围，从 `231072` 开始的 65536 个整数。UID `231072` 在命名空间内（在本例中为容器内）映射为 UID `0`（`root`）。 UID `231073` 被映射为 UID `1`，以此类推。如果一个进程试图在命名空间之外提升权限，则该进程将作为主机上的非特权大编号 UID 运行，它甚至没有映射到一个真正的用户，这意味着该进程在主机系统上根本没有特权。

多个范围：通过在 `/etc/subuid` 或 `/etc/subgid` 文件中为同一用户或组添加多个不重叠的映射，可以为特定用户或组分配多个从属范围。在这种情况下，Docker 只使用前五个映射，这符合内核对 `/proc/self/uid_map` 和 `/proc/self/gid_map` 中只有五个条目的限制。

配置 Docker 使用 `userns-remap` 功能时，可以选择指定现有用户和组，也可以指定默认值 `default`。指定默认值则会创建一个用户和组 `dockremap`。

警告：某些发行版，例如 RHEL 和 CentOS 7.3，不会自动将新组添加到 `/etc/subuid` 和 `/etc/subgid` 文件中。在这种情况下，用户需要编辑这些文件并分配不重叠的范围。

范围不重叠非常重要，这样进程就无法在不同的命名空间中获得访问权限。在大多数 Linux 发行版上，系统实用程序会在用户添加或删除用户时管理范围。

这种重新映射对容器是透明的，但在容器需要访问 Docker 主机上的资源的情况下，会引入一些配置复杂性。例如，绑定挂载到系统用户无法写入的文件系统区域。从安全的角度来看，最好避免这些情况。

#### 先决条件

1. 从属 UID 和 GID 范围必须与现有用户关联。用户拥有 `/var/lib/docker/` 下的命名空间存储目录。如果不用现有用户，Docker 可以创建一个并使用它。如果用现有的用户名或用户 ID，它必须已经存在。通常，这意味着相关条目需要位于 `/etc/passwd` 和 `/etc/group` 中，但如果用不同的身份认证后端，则此要求可能会有所不同。
   
   可以使用 `id` 验证
   ```
   $ id testuser
   ```

2. 在主机上处理命名空间重新映射的方式是使用 `/etc/subuid` 和 `/etc/subgid` 两个文件。这些文件通常在添加或删除用户或组时自动管理，但在少数发行版（例如 RHEL 和 CentOS 7.3）上，可能需要手动管理。
   
   每个文件包含三个字段：用户的用户名或 ID，起始 UID 或 GID（在命名空间内被视为 UID 或 GID 0），用户可用的 UID 或 GID 的最大数量。例如，给定以下条目：

   ```
   testuser:231072:65536
   ```

   这意味着 `testuser` 启动的用户命名空间进程由主机 UID `231072`（在命名空间内看起来像 UID `0`）到 `296607`（231072 + 65536 - 1）拥有。这些范围不应重叠，以确保命名空间的进程无法访问彼此的命名空间。

   添加用户后，检查 `/etc/subuid` 和 `/etc/subgid` 中是否存在条目。如果没有，则需要手动添加，并注意避免重叠。

   如果要使用 Docker 自动创建的 `dockremap` 用户，那得在配置和重启 Docker 后检查这些文件中的 `dockremap` 条目。

3. 如果 Docker 主机上有任何非特权用户需要写入的位置，需要相应地调整这些位置的权限。使用 Docker 自动创建的 `dockremap` 用户也是如此，但要在配置和重启 Docker 后修改。

4. 启用 `userns-remap` 可以有效地屏蔽现有的镜像和容器层，以及 `/var/lib/docker/` 中的其他 Docker 对象。这是因为 Docker 需要调整这些资源的所有权，并存储在 `/var/lib/docker/` 的子目录中。
   
   最好在刚安装 Docker 时启用，而不是对现有的 Docker 启用该功能。反过来，如果禁用 `userns-remap`，则无法访问启用时创建的任何资源。

5. 检查用户命名空间的限制，确保用例是可行的。

#### 在守护进程中启用 userns-remap

可以使用 `--userns-remap` 标志启动 `dockerd`，或使用 `daemon.json` 配置文件配置守护进程。推荐使用 `daemon.json` 配置，如果使用标志，则参考以下命令：

```bash
$ dockerd --userns-remap="testuser:testuser"
```

1. 编辑 `/etc/docker/daemon.json`。假设文件之前是空的，以下条目使用名为 `testuser` 的用户和组启用 `userns-remap`。可以使用 ID 或名称。如果同时提供用户名和组名，用冒号 `:` 分隔。假设 `testuser` 的 UID 和 GID 为 `1001`：

   - `testuser`
   - `testuser:testuser`
   - `1001`
   - `1001:1001`
   - `testuser:1001`
   - `1001:testuser`

   ```
   {
      "userns-remap": "testuser"
   }
   ```
   
   注意：要使用 `dockremap` 用户并让 Docker 创建，将值设置为 `default`。

   保存文件并重启 Docker。

2. 如果使用 `dockremap` 用户，首先用 `id` 命令验证 Docker 是否使创建了它。

   ```bash
   $ id dockremap
   ```

   验证该条目已被添加到 `/etc/subuid` 和 `/etc/subgid`

   ```bash
   $ grep dockremap /etc/subuid
   $ grep dockremap /etc/subgid
   ```

   如果条目不存在，则需要以 `root` 身份编辑文件，分配一个起始 UID 和 GID，即起始 UID 和偏移量（在本例中为 `65536`），注意不要让范围有重叠。

3. 使用 `docker image ls` 命令验证以前的镜像是否不可用，输出应该是空的。
   
4. 从 `hello-world` 镜像启动一个容器。
   
   ```bash
   $ docker run hello-world
   ```

5. 验证 `/var/lib/docker/` 中存在以命名空间用户的 UID 和 GID 命名的命名空间目录，由 UID 和 GID 拥有，不是组或全局可读的。一些子目录仍归 `root` 所有，并具有不同的权限。
   
   ```bash
   $ sudo ls -ld /var/lib/docker/231072.231072/
   $ sudo ls -l /var/lib/docker/231072.231072/
   ```

   使用被重新映射的用户所拥有的目录，而不是直接位于 `/var/lib/docker/` 下的相同目录，未使用的版本（例如本例中的 `/var/lib/docker/tmp/`）可以被删除。启用 `userns-remap` 时 Docker 不会使用它们。

#### 禁用容器用户命名空间重映射

如果在守护进程上启用用户命名空间，则默认情况下，所有容器在启动时都启用用户命名空间。在某些情况下，例如特权容器，可能需要禁用特定容器的用户命名空间。

要禁用特定容器的用户命名空间，`docker container create`、`docker container run` 或 `docker container exec` 命令时添加 `--userns=host` 标志。

使用该标志时有一个副作用：不会为该容器启用用户的重新映射，但由于容器之间共享只读（镜像）层，容器文件系统的所有权仍将被重新映射。这意味着整个容器文件系统将属于 `--userns-remap` 守护进程配置中指定的用户（上面示例中的 `231072`）。这可能导致容器内的程序产生意外行为。例如执行 `sudo`（检查其二进制文件是否属于用户 `0`）或带有 `setuid` 标志的二进制文件。

#### 用户命名空间的限制

以下标准 Docker 功能与运行启用了用户命名空间的 Docker 守护进程不兼容：
- 与主机共享 PID 或 NET 命名空间（`--pid=host` 或 `--network=host`）
- 外部（卷或存储）驱动程序不知道或不能使用守护进程用户映射
- 运行 `docker run` 时使用 `--privileged` 模式标志，而不指定 `--userns=host`

用户命名空间是一个高级功能，需要与其他功能协调。例如，如果从主机挂载卷，则必须预先设置文件所有权，对卷内容进行读取或写入。

虽然用户命名空间容器进程中的 `root` 用户拥有容器内超级用户的许多预期特权，但 Linux 内核基于内部知识施加了限制，即这是一个用户命名空间的进程。一个值得注意的限制是无法使用 `mknod` 命令，由 `root` 用户在容器内创建设备的将会被拒绝。

### 以非 root 用户身份运行 Docker 守护进程

无根模式（`rootless`）允许以非 `root` 用户身份运行 Docker 守护进程和容器，以缓解守护进程和容器运行时中的潜在漏洞。

只要满足先决条件，无根模式即使在安装 Docker 守护进程期间也不需要根权限。

无根模式是在 Docker Engine v19.03 中作为实验性功能引入的，从 Docker Engine v20.10 开始成为正式功能。

#### 运作机制

无根模式在用户命名空间内执行 Docker 守护进程和容器。与 `userns-remap` 模式非常相似，在 `userns-remap` 模式下，守护进程本身以 `root` 权限运行，而在无根模式下，守护进程和容器都在没有 `root` 权限的情况下运行。

无根模式不使用具有 `SETUID` 位或文件能力机制的二进制文件，除了 `newuidmap` 和 `newgidmap`，它们是允许在用户命名空间中使用多个 UID/GID 所必需的。

#### 先决条件

- 必须在主机上安装 `newuidmap` 和 `newgidmap`，这些命令由大多数发行版上的 `uidmap` 包提供。
- `/etc/subuid` 和 `/etc/subgid` 应包含至少 65536 个用户的从属 UID/GID。在以下示例中，用户 `testuser` 有 65536 个从属 UID/GID（231072-296607）。

```bash
$ id -u
1001
$ whoami
testuser
$ grep ^$(whoami): /etc/subuid
testuser:231072:65536
$ grep ^$(whoami): /etc/subgid
testuser:231072:65536
```

#### 已知限制

- 仅支持以下存储驱动程序：
  - `overlay2`（使用内核 5.11 或更高版本，或 Ubuntu 风格的内核）
  - `fuse-overlayfs` （使用内核 4.18 或更高版本，并安装了 `fuse-overlayfs`）
  - `btrfs`（使用内核 4.18 或更高版本，或 `~/.local/share/docker` 使用 `user_subvol_rm_allowed` 挂载选项挂载）
  - `vfs`

- 只有在使用 cgroup v2 和 systemd 运行时才支持 cgroup

- 不支持以下功能：
  - AppArmor
  - Checkpoint
  - Overlay network
  - Exposing SCTP ports

- 要使用 `ping` 命令，参阅 [Routing ping packets](https://docs.docker.com/engine/security/rootless/#routing-ping-packets)

- 要公开特权 TCP/UDP 端口 (< 1024)，参阅 [Exposing privileged ports](https://docs.docker.com/engine/security/rootless/#exposing-privileged-ports)

- `IPAddress` 显示在 `docker inspect` 中，并在 RootlessKit 的网络命名空间中被命名，这意味着如果不进入网络命名空间（`nsenter`），主机就无法访问 IP 地址。

- 主机网络（`docker run --net=host`）也在 RootlessKit 中被命名

- 不支持 docker 数据根（data-root）的 NFS 挂载，该限制并非特定于无根模式

#### 安装与卸载

以非 root 用户身份运行 `dockerd-rootless-setuptool.sh install` 来设置守护进程：

```bash
$ dockerd-rootless-setuptool.sh install
```

如果 `dockerd-rootless-setuptool.sh` 不存在，可能需要手动安装 `docker-ce-rootless-extras` 包：

```bash
$ sudo apt-get install -y docker-ce-rootless-extras
```

卸载

```bash
$ dockerd-rootless-setuptool.sh uninstall
```

删除数据目录

```bash
$ rootlesskit rm -rf ~/.local/share/docker.
```

#### 使用方式

**守护进程**

建议使用 `systemd`，systemd 单元文件安装为 `~/.config/systemd/user/docker.service`。

使用 `systemctl --user` 管理守护进程的生命周期：

```bash
$ systemctl --user start docker
```

要在系统启动时启动守护进程，启用 systemd 服务和 `lingering`：

```bash
$ systemctl --user enable docker
$ sudo loginctl enable-linger $(whoami)
```

即使使用 `User=` 指令，也不支持将无根模式的 Docker 作为 systemd 范围的服务 (`/etc/systemd/system/docker.service`) 启动。

关于目录路径的备注：
- 默认情况下，套接字路径设置为 `$XDG_RUNTIME_DIR/docker.sock`，`$XDG_RUNTIME_DIR` 通常设置为 `/run/user/$UID`
- 默认情况下，数据目录设置为 `~/.local/share/docker`，数据目录不应位于 NFS 上
- 守护进程配置目录默认设置为 `~/.config/docker`，该目录与客户端使用的 `~/.docker` 不同

**客户端**

需要显式指定套接字路径或 CLI 上下文。

使用 `$DOCKER_HOST` 指定套接字路径：

```bash
$ export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
$ docker run -d -p 8080:80 nginx
```

使用 `docker context` 指定 CLI 上下文：

```bash
$ docker context use rootless
```

#### 最佳实践

[Best practices](https://docs.docker.com/engine/security/rootless/#best-practices)

#### 故障排除

[Troubleshooting](https://docs.docker.com/engine/security/rootless/#troubleshooting)

# 参阅

- [Docker architecture](https://docs.docker.com/get-started/overview/#docker-architecture)
- [底层实现](https://yeasy.gitbook.io/docker_practice/underly)
- [Docker security](https://docs.docker.com/engine/security/)
- [Docker security announcements](https://docs.docker.com/security/)
- [Docker security non-events](https://docs.docker.com/engine/security/non-events/)
- [capabilities(7) — Linux manual page](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [Access authorization plugin](https://docs.docker.com/engine/extend/plugins_authorization/)
- [Understanding and Securing Linux Namespaces](https://www.linux.com/news/understanding-and-securing-linux-namespaces/)
- [安全](https://yeasy.gitbook.io/docker_practice/security)
