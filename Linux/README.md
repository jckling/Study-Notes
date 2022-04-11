## 用户与用户组

![](20220411105852.png)  

数字|权限
-|-
4|read(r)
2|write(w)
1|execute(x)

### chmod

对文件 f 添加用户组的写权限
```bash
chmod g+w f
```

删除其他用户的所有权限
```bash
chmod o= f
```

禁止所有用户写
```bash
chmod a-w f
```

将文件设置为 775 权限
```bash
chmod 775 f
```

递归将文件夹设置为 600 权限
```bash
chmod -R 600 d
```

### chown

设置文件所有者和所有组
```bash
chown user:group f
```

递归将目录及子目录中的文件所有者改为 user
```bash
chown -R user /d1/d2
```

### chgrp

设置文件所属组
```bash
chgrp group f
```

递归将目录及子目录中的文件所属组改为 group
```bash
chgrp -R group /d1/d2
```

### id

打印用户及群组信息
```bash
id
# or
id -a
```

打印特定用户的相关信息
```bash
id user
```

### finger

显示登录用户的信息
```bash
finger
```

显示特定用户的登录信息
```bash
finger user
```

### who/w/whoami

显示登录用户的信息
```bash
who
```

打印标题行
```bash
who -H
```

显示已登录用户及其活动
```bash
w
```

显示特定用户及其活动
```bash
w user
```

显示用户名
```bash
whoami
# or
id -un
```

### users

显示登录用户
```bash
users
```

### last

查看最近的登录信息
```bash
last
```

查看指定用户最近的登录信息
```bash
last user
```

查看最近几次重启操作
```bash
last reboot
```

### group*

显示用户所属组
```bash
groups
# or
id -Gn
```

添加组
```bash
groupadd group
```

删除组
```bash
groupdel group
```

修改组名称
```bash
groupmod -n newgroup group
```

### user*

添加用户
```bash
useradd user
```

添加系统用户
```bash
useradd -r user
#or
useradd --system user
```

添加用户并设置主目录
```bash
useradd -d /home/user user
# or
useradd --home-dir /home/user user
```

添加用户并设置用户组
```bash
useradd -g group1 group2 user
# or
useradd --group group1 group2 user
```

删除用户
```bash
userdel user
```

删除用户及其相关文件
```bash
userdel -r user
```

将用户添加到组中
```bash
usermod -G group user
# or
usermod -aG group user
```

修改用户名
```bash
usermod -l newuser user
```

### su/sudo

切换用户身份
```bash
su user
```

切换用户身份执行命令，完成后返回当前用户
```bash
su -c ls user
```

临时提升权限
```bash
sudo
```

使用 root 用户重新登录
```bash
sudo su -
# or
sudo -s
```

### passwd

用户信息：用户名、口令、ID、GID、描述、主目录，缺省 Shell
```
/etc/passwd
/etc/shadow
```

组信息：组名、口令、已创建时间、口令最短位数、用户口令、倒计时提醒、禁用天数、过期天数
```
/etc/group
/etc/gshadow
```

更改自己的密码
```bash
passwd
```

更改或创建其他用户的密码
```bash
passwd user
```

### ssh*

连接远程服务器
```bash
ssh user@host
```

指定端口
```bash
ssh -p port user@host
```

生成公私钥对
```bash
ssh-keygen
# or
ssh-keygen -t rsa
# or
ssh-keygen -m PEM -t rsa -b 4096
```

从私钥生成公钥
```bash
ssh-keygen -y -f id_rsa > id_rsa.pub
```

复制公钥到 `~/.ssh/authorized_keys`
```bash
ssh-copy-id user@host:port
#or
ssh-copy-id -i ~/.ssh/id_rsa.pub user@host
```

## 目录操作

### cd

切换到根目录
```bash
cd /
```

切换到用户主目录 `$HOME`
```bash 
cd
# or
cd ~
```

切换到上级目录
```bash
cd ..
```

切换到上两级目录
```bash
cd ../..
```

切换到指定目录
```bash
cd dir
```

### ls

`--color-auto`
- 蓝色：目录
- 绿色：可执行文件
- 白色：一般性文件，如文本文件，配置文件等
- 红色：压缩文件或归档文件
- 浅蓝色：链接文件
- 红色闪烁：链接文件存在问题
- 黄色：设备文件
- 青黄色：管道文件

列出当前目录可见文件
```bash
ls
```

显示详细信息
```bash
ls -l
```

以可读大小显示文件大小
```bash
ls -lh
```

列出当前目录所有文件（包括隐藏文件）
```bash
ls -a
```

按修改时间排序（最近修改的在最前面）
```bash
ls -t
```

显示 inode 信息
```bash
ls -i -l
```

单列输出
```bash
ls -1
```

单行输出（逗号分隔）
```bash
ls -m
```

### tree

显示第一级文件名
```bash
tree doop -L 1
```

显示完整的路径名称
```bash
tree doop -f -L 1
```

非树状结构列出
```bash
tree doop -i -L 1
```

### pwd

显示当前工作目录的绝对路径
```bash
pwd
```

显示软链接文件指向的文件
```bash
pwd -P
```

### mkdir/rmdir

创建目录
```bash
mkdir d
```

创建多个目录
```bash
mkdir d1 d2
```

创建目录及子目录
```bash
mkdir -p d3/d4
```

创建指定权限的目录（默认 775）
```bash
mkdir -m 700 d5
```

删除目录
```bash
rmdir d
```

删除子目录，若父目录为空，则也删除
```bash
rmdir -p d3/d4
```

## 文件操作

### touch

创建新的空文件
```bash
touch f
```

更改文件的时间
```bash
touch f
```

只更改文件的访问时间
```bash
touch -a f
```

### file
查看文件类型
```bash
file f
```

不显示文件名称
```bash
file -b f
```

显示 MIME 类别
```bash
file -i f
```

显示符号链接所指向的文件类型
```bash
file -L f
```

### stat

显示文件的状态信息
```bash
stat f
```

### cat

显示文件内容
```bash
cat f
```

合并显示多个文件
```bash
cat f1 f2 f3
```

附加行号
```bash
cat -n f
```

仅对非空行附加行号
```bash
cat -b f
```

压缩连续的空行
```bash
cat -s f
```

将 r1 的内容附加到 f2
```bash
cat file1 >> file2
```

### less

- `H`：帮助信息
- `B`：上一屏
- `Q`：退出

查看并分页文件
```bash
less file
```

相比 more：功能更丰富，可以往前或往后搜索，按需加载文件内容。

### more

- `Space`：下一屏
- `Enter`：下一行
- `H`：帮助信息
- `B`：上一屏
- `Q`：退出

查看并分页文件
```bash
more file
```

相比 less：功能较少，按页浏览文件，加载整个文件内容。

### head

显示文件的前 10 行
```bash
head f
```

显示多个文件的前 10 行
```bash
head f1 f2
```

显示前 5 行
```bash
head -n 5 f
```

不打印文件名
```bash
head -q f
```

总是打印文件名
```bash
head -v f
```

### tail

显示文件的最后 10 行
```bash
tail f
```

显示多个文件的最后 10 行
```bash
tail f1 f2
```

显示最后 5 行
```bash
tail -n 5 f
```

显示文件的第 20 行至末尾
```bash
tail -n + 20 
```

根据文件描述符追踪，当文件改名或删除时停止
```bash
tail -f f
# or
tail --follow=descriptor f
```

根据文件名追踪，并保持重试
```bash
tail -F f
# or
tail --follow=name --retry f
```

### cp

拷贝 f1 到 f2
```bash
cp f1 f2
```

拷贝到当前目录
```bash
cp f1 .
```

强制覆盖
```bash
cp -f f1 f2
```

递归拷贝目录 d1 到 d2
```bash
cp -r d1 d2
```

将目录 d1 下的 `.sh` 文件拷贝到 d2
```bash
cp d1 *.sh d2
```

### mv

重命名文件或目录
```bash
mv f1 f2
# or
mv d1/ d2/
```

移动文件到当前目录
```bash
mv /d1/d2/f .
```

移动目录
```bash
mv /d1/ ./
```

### rm

删除文件
```bash
rm f
```

删除多个文件
```bash
rm f1 f2
```

强制删除文件
```bash
rm -f f
```

递归删除文件夹
```bash
rm -r d
```

强制递归删除文件夹
```bash
rm -rf dir
```

### ln

创建符号链接（硬链接）
```bash
ln -s file link
```

创建符号链接（软链接）
```bash
ln -s file link
# or
ln -s directory link
```

### find

例如出当前目录及子目录下的所有文件和文件夹
```bash
find .
```

在 `/home` 目录下查找以 `.txt` 结尾的文件
```bash
find /home -name "*.txt"
```

忽略大小写
```bash
find /home -iname "*.txt"
```

在 `/home` 目录下查找不是 `.txt` 结尾的文件
```bash
find /home ! -name "*.txt"
```

在当前目录及子目录下查找所有以 `.txt` 和 `.pdf` 结尾的文件
```bash
find . -name "*.txt" -o -name "*.pdf"   # -o 表示 or
```

匹配文件路径或文件
```bash
find /usr/ -path "*local*"
```

基于正则表达式匹配文件
```bash
find . -regex ".*\(\.txt\|\.pdf\)$"
```

#### 根据文件类型搜索

- `f`：普通文件
- `l`：符号连接
- `d`：目录
- `c`：字符设备
- `b`：块设备
- `s`：套接字
- `p`：Fifo

搜索普通文件
```bash
find . -type f
```

#### 限制搜索深度

最大深度限制为 3
```bash
find . -maxdepth 3 -type f
```

搜索距离当前目录至少 2 个子目录的文件
```bash
find . -mindepth 2 -type f
```

#### 根据时间戳搜索
- 访问时间（-atime/天，-amin/分钟）：用户最近一次访问时间
- 修改时间（-mtime/天，-mmin/分钟）：文件最后一次修改时间
- 变化时间（-ctime/天，-cmin/分钟）：文件数据元（例如权限等）最后一次修改时间

搜索最近七天内被访问的所有文件
```bash
find . -type f -atime -7
```

搜索恰好七天前被访问的所有文件
```bash
find . -type f -atime 7
```

搜索七天之前内被访问的所有文件
```bash
find . -type f -atime +7
```

搜索访问时间超过 10 分钟的所有文件
```bash
find . -type f -amin +10
```

找出比 file.log 修改时间更长的所有文件
```bash
find . -type f -newer file.log
```

#### 根据文件大小搜索
- `b`：块（512 字节）
- `c`：字节
- `w`：字（2 字节）
- `k`：千字节
- `M`：兆字节
- `G`：吉字节

搜索大于 10KB 的文件
```bash
find . -type f -size +10k
```

搜索小于 10KB 的文件
```bash
find . -type f -size -10k
```

搜索等于 10KB 的文件
```bash
find . -type f -size 10k
```

#### 根据权限搜索

搜索出权限为 777 的文件
```bash
find . -type f -perm 777
```

搜索权限不是 644 的 php 文件
```bash
find . -type f -name "*.php" ! -perm 644
```

搜索用户 tom 拥有的所有文件
```bash
find . -type f -user tom
```

搜索用户组 docker 拥有的所有文件
```bash
find . -type f -group docker
```

#### 示例

```bash
# 在 dir 中查找以 name 开头的文件
find /dir/ -name name*

# 在 dir 中查找用户 name 拥有的文件
find /dir/ -user name

# 在 dir 中查找不到 num 分钟前修改的文件
find /dir/ -mmin num

# 在 dir 中查找大于 100MB 的文件
find /dir/ -size +100M

# 删除当前目录下的 package-lock.json 文件
find .  -name "package-lock.json" -exec rm -rf {} \;

# 删除当前目录下的 node_modules 目录
find . -name 'node_modules' -type d -prune -exec rm -rf '{}' +
```

当前目录搜索包含 140.206.111.111 的文件
```bash
find . -type f -name "*" | xargs grep "140.206.111.111"
```

### grep

在文件中搜索模式
```bash 
grep pattern f
# or
grep "pattern" f
```

在多个文件中搜索模式
```bash
grep "pattern" f1 f2
```

统计匹配数量
```bash
grep -c "pattern" f
```

显示行号
```bash
grep -n "pattern" f
```

忽略大小写
```bash
grep -i "pattern" f
```

仅显示匹配部分
```bash
grep -o "pattern" f
```

打印不匹配模式的部分
```bash
grep -v "pattern" f
```

同时搜索多个模式
```bash
grep -e "p1" -e "p2" f
```

递归搜索当前目录
```bash
gerp "pattern" -r .
```

指定或排除文件
```bash
# 指定 .php 和 .html 文件
grep "pattern" -r . --include *.{php,html}

# 排除 README 文件
grep "pattern" -r . --excluce "README"

# 排除文件列表中的文件
grep "pattern" -r . --exclude-from f
```

显示匹配文本之前或之后的行
```bash
grep "pattern" -A 3     # 前 3 行
grep "pattern" -B 3     # 后 3 行
grep "pattern" -C 3     # 前后各 3 行
```

正则表达式
```bash
# 扩展正则表达式
grep -E "[1-9]+"
# or
egrep "[1-9]+"

# Perl 正则表达式
grep -P "(\d{3}\-){2}\d{4}" file_name
```

### sed

替换文本中的字符串，每行第一次出现的替换
```bash
sed 's/book/books/' f
```

全局替换
```bash
sed 's/book/books/g' f
```

从第 2 个匹配开始替换，并直接修改文件
```bash
sed -i 's/book/books/2g' f
```

删除空白行
```bash
sed '/^$/d' f
```

删除文件的第 2 行
```bash
sed '2d' f
```

删除文件的第 2 行至末尾
```bash
sed '2,$d' f
```

删除文件的最后一行
```bash
sed '$d' f
```

删除文件中所有以 test 开头的行
```bash
sed '/^test/d' f
```

将所有以 192.168.0.1 开头的行替换为 192.168.0.1localhost
```bash
sed 's/^192.168.0.1/&localhost/g' f
```

从文件读入
```bash
sed '/test/r f' filename
```

写入文件
```bash
sed -n '/test/w file' example
```

追加到后面
```bash
sed '/^test/a\this is a test line' f     # 追加到以 test 开头的行后面
sed -i '2a\this is a test line' f        # 追加到文件的第 2 行之后
```

追加到前面
```bash
sed '/^test/i\this is a test line' f     # 追加到以 test 开头的行前面
sed -i '2i\this is a test line' f        # 追加到文件的第 2 行之前
```

打印到第 10 行
```bash
sed '10q' f
```

打印第 5-7 行
```bash
sed -n '5,7p' f
```

打印奇偶数行
```bash
# 奇数行
sed -n 'p;n' f
sed -n '1~2p' f

# 偶数行
sed -n 'n;p' f
sed -n '2~2p' f
```

打印匹配串的下一行
```bash
grep -A 1 pattern f
sed -n '/pattern/{n;p}' f
awk '/pattern/{getline; print}' f
```

### awk

基本结构
```bash
awk 'BEGIN{ print "start" } pattern{ commands } END{ print "end" }' file
```

转义序列
```
\\ \自身
\$ 转义$
\t 制表符
\b 退格符
\r 回车符
\n 换行符
\c 取消换行
```

打印每行的最后一个字段
```bash
awk '{print $NF}' f
```

打印每行的倒数第二个字段
```bash
awk '{print $(NF-1)}' f
```

打印每行的第二和第三个字段
```bash
awk '{ print $2,$3 }' f
```

统计行数
```bash
END{ print NR }
```

通过监听端口查找进程 PID
```bash
netstat -ntpl | grep ":80" | awk '{printf $7}' | cut -d/ -f1
```

输出到文件
```bash
echo | awk '{printf("hello word!\n") > "datafile"}'
# or
echo | awk '{printf("hello word!\n") >> "datafile"}'
```

设置字段定界符
```bash
awk -F: '{ print $NF }' /etc/passwd
# or
awk 'BEGIN{ FS=":" } { print $NF }' /etc/passwd
```

支持多种运算与流程控制等丰富功能，是一种编程语言。

### tr

将输入字符由大写转换为小写
```bash
echo "HELLO WORLD" | tr 'A-Z' 'a-z'
```

删除数字
```bash
echo "hello 123 world 456" | tr -d '0-9'
```

将制表符转换为空格
```bash
cat f | tr '\t' ' '
```

### wc

统计行数
```bash
wc -l f
```

统计行数（`-l`）、字数（`-w`）、字节数（`-c`）
```bash
wc f
```

统计字符数
```bash
wc -m f
```

只打印统计信息，省略文件名输出
```bash
wc < f
```

### sort

每行按 ASCII 码比较，升序输出
```bash
sort f
```

忽略相同行
```bash
sort -u f
```

按第二列数字从小到大排序，分隔符 `:`
```bash
sort -nk 2 -t: f
```

按第三列数字从大到小排序
```bash
sort -nrk 3 -t: f
```

按第一列的第二个字母开始排序，分隔符 ` `
```bash
sort -t ' ' -k 1.2
```

按第一列的第二个字母排序，若相同，则按第三列进行排序（`,` 连接起止位置）
```bash
sort -t ' ' -k 1.2,1.2 -nrk 3,3 facebook.txt
```

### uniq

相邻行去重
```bash
uniq f
```

所有行去重
```bash
sort f | uniq
# or
sort -u f
```

统计各行在文件中的出现次数
```bash
sort f | uniq -c
```

找出重复的行
```bash
sort f | uniq -d
```

### diff/diffstat

- `a`：添加
- `d`：删除
- `c`：修改

比较文件 f1 与 f2
```bash
diff f1 f2
```

输出统计信息
```bash
diff f1 f2 | diff stat
```

### which

查找命令的绝对路径（PATH）
```bash
which pwd
```

### locate

查找和 `pwd` 相关的所有文件
```bash
locate pwd
```

查找 etc 目录下所有以 sh 开头的文件
```bash
locate /etc/sh
```

忽略大小写，查找当前目录下所有以 r 开头的文件
```bash
locate -i ./r
```

### whereis

查找和 `pwd` 相关的所有文件（二进制、源码、说明文档）
```bash
whereis pwd
```

只查找二进制文件
```bash
whereis -b pwd
```

只查找源码
```bash
whereis -s pwd
```

只查找说明文档
```bash
whereis -m pwd
```

### tar/gzip/gunzip/bzip2/bunzip2

创建未压缩的 tar 存档
```bash
tar -cf archive.tar d
# or
tar -cf archive.tar f1 f2
```

追加文件到存档
```bash
tar -rf archive.tar f3
```

更新存档中的文件
```bash
tar -uf archive.tar f1 f2
```

列出存档中的文件
```bash
tar -tf archive.tar
```

展开存档
```bash
tar -xf archive.tar
```

创建 gzip 压缩文件
```bash
tar -czf archive.tar.gz d
# or
gzip archive.tar
```

解压
```bash
tar -xzf archive.tar.gz
# or
gunzip archive.tar.gz
```

创建 bzip2 压缩文件
```bash
tar -cjf archive.tar.bz2 d
# or
bzip2 archive.tar
```

解压
```bash
tar -xjf archive.tar.bz2
# or
bunzip2 archive.tar.bz2
```

### scp

将文件复制到服务器目录下
```bash
scp f user@host:/tmp/
```

递归下载目录到本地目录
```bash
scp -r user@host:/tmp/ ~/
```

### rsync

将源目录同步到目标目录，`-a` 同步元信息
```bash
rsync -r source destination
# or
rsync -a source destination
```

同步目录下的文件到目录
```bash
rsync -a source/ destination
```

同步多个文件或目录
```bash
rsync -a source1 source2 destination
```

模拟执行
```bash
rsync -anv source/ destination
```

## 系统信息

### 整体

CPU 信息
```bash
cat /proc/cpuinfo
```

内存信息
```bash
cat /proc/meminfo
```

DNS 服务器配置
```bash
cat /etc/resolv.conf
```

内核与模块信息
```bash
# 显示系统信息
uname -r

# 显示内核发行信息
uname -a

# 显示加载的模块
lsmod

# 显示模块信息
modinfo module_name

# 加载模块
modprobe module_name

# 删除模块
modprobe --remove module_name
```

#### iostat

显示 I/O 设备和 CPU 使用情况
```bash
```

仅显示 CPU 使用情况
```bash
iostat -c
```

查看磁盘 I/O 的详细情况
```bash
iostat -x /dev/sda1
```

#### lnstat

显示系统的网络统计信息
```bash
lnstat
```

#### mpstat

CPU 统计信息（平均）
```bash
mpstat
```

每 3 秒产生 10 次统计报告
```bash
mpstat 3 10
```

指定 CPU 编号，每 2 秒产生 3 次统计报告
```bash
mpstat -P ALL 2 3
```

#### vmstat

虚拟内存统计信息
```bash
vmstat
```

每 3 秒产生 10 次统计报告
```bash
vmstat 3 10
```

#### netstat

列出所有端口，包括未监听的
```bash
netstat -a     # 列出所有端口
netstat -at    # 列出所有 TCP 端口
netstat -au    # 列出所有 UDP 端口                             
```

列出所有处于监听状态的端口
```bash
netstat -l        # 只显示监听端口
netstat -lt       # 只列出所有监听 TCP 端口
netstat -lu       # 只列出所有监听 UDP 端口
netstat -lx       # 只列出所有监听 UNIX 端口
```

显示每个协议的统计信息
```bash
netstat -s    # 显示所有端口的统计信息
netstat -st   # 显示 TCP 端口的统计信息
netstat -su   # 显示 UDP 端口的统计信息
```

显示网卡列表
```bash
netstat -i
```

显示 PID
```bash
netstat -p
```

不要解析域名
```bash
netstat -n
```

显示处于监听状态的端口
```bash
netstat -pnltu
```

通过正在监听的端口找到 PID
```bash
netstat -ntpl | grep ":80" | awk '{printf $7}' | cut -d/ -f1
```

#### atop

监视系统资源（CPU、内存、磁盘和网络）使用情况和进程运行情况
```bash
atop
```

#### iotop

监视磁盘 I/O 使用状况
```bash
iotop
```

#### iftop

实时流量监控
```bash
iftop           # 默认监控第一块网卡的流量
iftop -i eth1   # 监控e th1
iftop -n        # 显示 IP, 不进行 DNS 反解析
iftop -N        # 显示连接端口，不显示服务名称
iftop -F 192.168.1.0/24 or 192.168.1.0/255.255.255.0  # 显示某个网段进出封包流量
```

### 时间

#### uptime

- 系统当前时间
- 已运行时间
- 用户连接总数
- 系统平均负载（最近 1，5，15 分钟的平均负载）：特定时间间隔内运行队列中的平均进程数

显示系统运行时间及平均负载
```bash
uptime
```

#### date

显示系统日期与时间
```bash
date
```

格式化输出
```bash
date +"%Y-%m-%d"
```

输出昨天日期
```bash
date -d "1 day ago" +"%Y-%m-%d"
```

输出 2 秒后的时间
```bash
date -d "2 second" +"%Y-%m-%d %H:%M.%S"
```

格式转换
```bash
date -d "2009-12-12" +"%Y/%m/%d %H:%M.%S"

date -d "Dec 5, 2009 12:00:37 AM" +"%Y-%m-%d %H:%M.%S"
```

时间加减
```bash
date +%Y%m%d                   # 显示年月日
date -d "+1 day" +%Y%m%d       # 显示前一天的日期
date -d "-1 day" +%Y%m%d       # 显示后一天的日期
date -d "-1 month" +%Y%m%d     # 显示上一月的日期
date -d "+1 month" +%Y%m%d     # 显示下一月的日期
date -d "-1 year" +%Y%m%d      # 显示前一年的日期
date -d "+1 year" +%Y%m%d      # 显示下一年的日期
```

设置时间
```bash
date -s                         # 设置当前时间，只有root权限才能设置，其他只能查看
date -s 20120523                # 设置 20120523，具体时间会被设置为 00:00:00
date -s 01:01:01                # 设置具体时间，不更改日期
date -s "01:01:01 2012-05-23"   # 设置全部时间
date -s "01:01:01 20120523"     # 设置全部时间
date -s "2012-05-23 01:01:01"   # 设置全部时间
date -s "20120523 01:01:01"     # 设置全部时间
```

#### timedatectl

显示系统当前时间和日期
```bash
timedatectl
# or
timedatectl status
```

显示系统可用时区
```bash
timedatectl list-timezones
```

设置时区
```bash
timedatectl set-timezone "Europe/Amsterdam"
timedatectl set-timezone UTC
```

设置时间
```bash
timedatectl set-time "07:25:46"
```

设置日期
```bash
timedatectl set-time "2021-12-12"   # 时间默认为 00:00:00
# 同时设置
timedatectl set-time "2021-12-12 07:25:46"
```

NTP 时间同步
```bash
timedatectl set-ntp true    # 启用
timedatectl set-ntp false   # 禁用
```

#### cal

打印日历
```bash
cal
```

打印上一个月、当月、下一个月，总共三个月的日历
```bash
cal -3
```

显示天数
```bash
cal -j
```

#### time

- `real`：挂钟时间
- `user`：执行时间
- `sys`：CPU 时间

统计命令花费的时间
```bash
time ls
```

### 磁盘

#### df

显示分区（KB）挂载情况
```bash
df
```

使用 KB 以上单位显示
```bash
df -h
```

查看所有文件系统
```bash
df -a
```

查看系统空闲 inode
```bash
df -i
```

显示目录磁盘使用情况
```bash
df doop
```

#### du

查看指定目录下的文件所占空间
```bash
du ./*
```

显示总和大小
```bash
du -s .
```

显示当前目录下子目录的大小
```bash
du -sh ./*/
```

文件从大到小排序
```bash
du -sh * | sort -rh
```

所有文件和目录的磁盘使用情况
```bash
du -ah
```

当前目录的磁盘使用情况
```bash
du -sh
```

#### fdisk

显示磁盘分区、大小、类型
```bash
fdisk -l
```

交互式操作磁盘
- `m`：列出可执行命令
- `p`：当前磁盘分区情况
```bash
fdisk /dev/sda2
```

#### mkfs

将 sdb1 分区格式化为 ext2 格式
```bash
mkfs -t ext2 /dev/sdb1
```

将 sdb2 分区格式化为 ext3 格式
```bash
mkfs -t ext3 /dev/sdb2
```

#### mount

显示挂载情况
```bash
mount
```

将分区挂载到系统
```bash
mount /dev/sdb1 /web
```

以只读模式挂载
```bash
mount -o -ro /dev/sdb1 /web
```

自动挂载，修改 `/etc/fstab`

#### unmount

通过设备名卸载
```bash
umount -v /dev/sdb1
```

通过挂载点卸载
```bash
umount -v /web
```

延迟卸载
```bash
umount -vl /dev/sdb1
```

#### pv*

创建物理卷，将分区 sdb 6~9 转换为物理卷
```bash
pvcreate /dev/sdb{6,7,8,9}
```

删除物理卷
```bash
pvremove /dev/sdb2
```

修改物理卷属性
```bash
pvchange -x n /dev/sdb1    # 禁止分配指定物理卷上的PE
```

扫描所有磁盘的物理卷
```bash
pvscan
```

显示物理卷信息
```bash
pvdisplay /dev/sdb1
```

#### lv*

创建逻辑卷，创建大小为 200M 的逻辑卷
```bash
lvcreate -L 200M vg1000
```

删除逻辑卷
```bash
lvremove /dev/vg1000/lvol0
```

显示逻辑卷信息
```bash
lvdisplay /dev/vg1000/lvol0
```

扩展逻辑卷空间，增加 100M
```bash
lvextend -L +100M /dev/vg1000/lvol0
```

收缩逻辑卷空间，减少 100M
```bash
lvreduce -L -100M /dev/vg1000/lvol0
```

#### lsblk

- `NAME`：块设备名
- `MAJ:MIN`：主要和次要设备号
- `RM`：是否可移动设备。
- `SIZE`：容量大小
- `RO`：是否只读
- `TYPE`：是否为磁盘或磁盘上的一个分区
- `MOUNTPOINT`：挂载点

列出所有块设备
```bash
lsblk
```

列出所有块设备，包括空设备
```bash
lsblk -a
```

获取指定块设备的信息
```bash
lsblk -b /dev/sda2
# or
lsblk --bytes /dev/sda2
```

获取 SCSI 设备列表
```bash
lsblk -S
```

### 内存

#### free

- `total`：总数
- `used`：已使用
- `free`：空闲
- `shared`：废弃不用
- `buff/cache`：缓存
- `available`：可用
- `Swap`：交换分区

显示系统内存使用情况
```bash
free -b     # 以 Byte 为单位显示
free -k     # 以 KB 为单位显示
free -m     # 以 MB 为单位显示
free -g     # 以 GB 为单位显示
```

以总和的形式显示
```bash
free -t
```

### 网络

#### ip

显示网卡 IP 信息
```bash
ip a
# or
ip addr
# or
ip addr show
```

网卡 IP 地址设置
```bash
ip addr add 192.168.0.1/24 dev eth0     # 设置 eth0 网卡 IP 地址 192.168.0.1
ip addr del 192.168.0.1/24 dev eth0     # 删除 eth0 网卡 IP 地址
```

显示特定网卡信息
```bash
ip addr show dev eth0
```

显示网卡信息
```bash
ip link
# or
ip link show
# or
ip link list
```

显示网卡详细信息
```bash
ip -s link list
```

网卡配置
```bash
ip link set eth0 up              # 开启网卡
ip link set eth0 down            # 关闭网卡
ip link set eth0 promisc on      # 开启网卡的混合模式
ip link set eth0 promisc off     # 关闭网卡的混合模式
ip link set eth0 txqueuelen 1200 # 设置网卡队列长度
ip link set eth0 mtu 1400        # 设置网卡最大传输单元
```

显示路由信息
```bash
ip route
# or
ip route show
# or
ip route list
```

路由配置
```bash
ip route add default via 192.168.1.254   # 设置系统默认路由
ip route add 192.168.4.0/24 via 192.168.0.254 dev eth0 # 设置 192.168.4.0 网段的网关为 192.168.0.254，走 eth0 网卡

ip route add default via 192.168.0.254 dev eth0        # 设置默认网关为 192.168.0.254
ip route del 192.168.4.0/24   # 删除 192.168.4.0 网段的网关
ip route del default          # 删除默认路由
ip route delete 192.168.1.0/24 dev eth0 # 删除路由
```

显示邻居
```bash
ip neigh
# or
ip neigh show
# or
ip neigh list
```

#### iptables

命令基本结构
```bash
iptables -t 表名 <-A/I/D/R> 规则链名 [规则号] <-i/o 网卡名> -p 协议名 <-s 源IP/源子网> --sport 源端口 <-d 目标IP/目标子网> --dport 目标端口 -j 动作
```

规则链名包括五个钩子函数（hook functions）：
- INPUT 链 ：输入数据包
- OUTPUT 链 ：输出数据包
- FORWARD 链 ：转发数据包
- PREROUTING 链 ：用于目标地址转换（DNAT）
- POSTOUTING 链 ：用于源地址转换（SNAT）

表名包括：
- raw：高级功能
  - 例如网址过滤
- mangle：数据包修改（QOS），用于实现服务质量
  - PREROUTING，INPUT，FORWARD，OUTPUT，POSTROUTING
- nat：地址转换，用于网关路由器
  - 一般只能在 3 个链上：PREROUTING，OUTPUT，POSTROUTING
- filter：包过滤，用于防火墙规则
  - 一般只能在 3 个链上：INPUT，FORWARD，OUTPUT

动作包括：
- ACCEPT：接收数据包
- DROP：丢弃数据包
- REDIRECT：重定向、映射、透明代理
- SNAT：源地址转换
- DNAT：目标地址转换
- MASQUERADE：IP 伪装（NAT），用于 ADSL
- LOG：日志记录
- SEMARK: 添加 SEMARK 标记以供网域内强制访问控制（MAC）

```
                             ┏╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍┓
 ┌───────────────┐           ┃    Network    ┃
 │ table: filter │           ┗━━━━━━━┳━━━━━━━┛
 │ chain: INPUT  │◀────┐             │
 └───────┬───────┘     │             ▼
         │             │   ┌───────────────────┐
  ┌      ▼      ┐      │   │ table: nat        │
  │local process│      │   │ chain: PREROUTING │
  └             ┘      │   └─────────┬─────────┘
         │             │             │
         ▼             │             ▼              ┌─────────────────┐
┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅    │     ┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅      │table: nat       │
 Routing decision      └───── outing decision ─────▶│chain: PREROUTING│
┅┅┅┅┅┅┅┅┅┳┅┅┅┅┅┅┅┅┅          ┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅      └────────┬────────┘
         │                                                   │
         ▼                                                   │
 ┌───────────────┐                                           │
 │ table: nat    │           ┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅               │
 │ chain: OUTPUT │    ┌─────▶ outing decision ◀──────────────┘
 └───────┬───────┘    │      ┅┅┅┅┅┅┅┅┳┅┅┅┅┅┅┅┅
         │            │              │
         ▼            │              ▼
 ┌───────────────┐    │   ┌────────────────────┐
 │ table: filter │    │   │ chain: POSTROUTING │
 │ chain: OUTPUT ├────┘   └──────────┬─────────┘
 └───────────────┘                   │
                                     ▼
                             ┏╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍┓
                             ┃    Network    ┃
                             ┗━━━━━━━━━━━━━━━┛
```

##### 示例

清空规则
```bash
iptables -F  # 清空所有的防火墙规则
iptables -X  # 删除用户自定义的空链
iptables -Z  # 清空计数
```

允许来自 192.168.1.0/24 网段的 ssh 连接
```bash
iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 22 -j ACCEPT
```

允许本地回环地址
```bash
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
```

配置默认规则
```bash
iptables -P INPUT DROP      # 不让进入
iptables -P FORWARD DROP    # 不允许转发
iptables -P OUTPUT ACCEPT   # 可以出去
```

配置白名单
```bash
iptables -A INPUT -p all -s 192.168.1.0/24 -j ACCEPT    # 允许内网机器访问
iptables -A INPUT -p all -s 192.168.140.0/24 -j ACCEPT  # 允许内网机器访问
iptables -A INPUT -p tcp -s 183.121.3.7 --dport 3380 -j ACCEPT # 允许 183.121.3.7 访问本机的 3380 端口
```

开启服务端口
```bash
iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT                   # 允许被 ping
iptables -A INPUT -s 127.0.0.1 -d 127.0.0.1 -j ACCEPT               # 允许本地回环接口
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT    # 允许已建立的或相关连的通行
iptables -A OUTPUT -j ACCEPT                     # 允许所有本机向外的访问
iptables -A INPUT -p tcp --dport 22 -j ACCEPT    # 允许访问 22 端口
iptables -A INPUT -p tcp --dport 80 -j ACCEPT    # 允许访问 80 端口
iptables -A INPUT -p tcp --dport 21 -j ACCEPT    # 允许 FTP 服务的 21 端口
iptables -A INPUT -p tcp --dport 20 -j ACCEPT    # 允许 FTP 服务的 20 端口
iptables -A INPUT -j reject       # 禁止其他未允许的规则访问
iptables -A FORWARD -j REJECT     # 禁止其他未允许的规则访问
```

屏蔽 IP
```bash
iptables -A INPUT -p tcp -m tcp -s 192.168.0.8 -j DROP  # 屏蔽主机，例如 192.168.0.8
iptables -I INPUT -s 123.45.6.7 -j DROP       # 屏蔽单个 IP
iptables -I INPUT -s 124.45.0.0/16 -j DROP    # 封 IP 段，从 123.45.0.1 到 123.45.255.254
```

网络转发，使用 210.14.67.127 转发内网网段
```bash
iptables -t nat -A POSTROUTING -s 192.168.188.0/24 -j SNAT --to-source 210.14.67.127
```

端口映射，2222 端口映射到内网主机 22 端口
```bash
iptables -t nat -A PREROUTING -d 210.14.67.127 -p tcp --dport 2222  -j DNAT --to-dest 192.168.188.115:22
```

字符串匹配
```bash
iptables -A INPUT -p tcp -m string --algo kmp --string "test" -j REJECT --reject-with tcp-reset
```

防止 SYN 泛洪
```bash
iptables -A INPUT -p tcp --syn -m limit --limit 5/second -j ACCEPT
```

保存规则
```bash
cp /etc/sysconfig/iptables /etc/sysconfig/iptables.bak # 改动前先备份
iptables-save > /etc/sysconfig/iptables
```

保存指定表的规则
```bash
iptables-save -t filter > iptables.bak
```

还原表配置
```bash
iptables-restore < iptables.bak
```

列出规则
```bash
iptables -L -t nat                  # 列出 nat 表的所有规则
iptables -L -t nat --line-numbers   # 编号
iptables -L INPUT                   # 列出 INPUR 链的所有规则
iptables -L -n -v                   # 详细信息
```

清除规则
```bash
iptables -F INPUT  # 清空指定链 INPUT 上面的所有规则
iptables -X INPUT  # 删除指定的链，这个链必须没有被其它任何规则引用，而且这条上必须没有任何规则。
                   # 如果没有指定链名，则会删除该表中所有非内置的链。
iptables -Z INPUT  # 把指定链，或表中的所有链上的计数器清零。
```

删除指定规则
```bash
iptables -L -n --line-numbers   # 查看规则编号
iptables -D INPUT 8             # 删除指定规则
```

#### ifconfig/ifup/ifdown

显示网络设备信息
```bash
ifconfig
```

显示所有网络设备信息，包括未启用的
```bash
ifconfig -a
```

显示特定网卡信息
```bash
ifconfig eth0
```

启动网卡
```bash
ifconfig eth0 up
# or
ifup eth0
```

关闭网卡
```bash
ifconfig eth0 down
# or
ifdown eth0
```

配置网卡
```bash
# IP 地址
ifconfig eth0 add 33ffe:3240:800:1005::2/64
ifconfig eth0 del 33ffe:3240:800:1005::2/64

# IP 地址、掩码、广播地址
ifconfig eth0 192.168.2.10
ifconfig eth0 192.168.2.10 netmask 255.255.255.0
ifconfig eth0 192.168.2.10 netmask 255.255.255.0 broadcast 192.168.2.255

# ARP 协议
ifconfig eth0 arp
ifconfig eth0 -arp

# 最大传输单元
ifconfig eth0 mtu 1500
```

#### ifstat

统计网络接口流量状态
```bash
ifstat
```

统计网络接口流量状态（包括回环接口）
```bash
ifstat -a
```

显示时间与带宽
```bash
ifstat -tT
```

#### dig

显示 DNS 信息
```bash
dig www.baidu.com
```

指定 DNS 服务器查询
```bash
dig @8.8.8.8 www.baidu.com
```

反向查找
```bash
dig -x 8.8.8.8     # DNS 服务器
```

#### nslookup

查询域名信息
```bash
nslookup www.baidu.com
```

#### host

查找域名的 IP 地址
```bash
host www.baidu.com
```

显示详细的 DNS 信息
```bash
host -a www.baidu.com
```

#### hostname

显示主机名称
```bash
hostname
```

显示主机 IP 地址
```bash
hostname -i
```

显示主机的所有 IP 地址
```bash
hostname -I
```

临时更改主机名称
```bash
hostname newname
```

#### hostnamectl

查看主机名称和相关信息
```bash
hostnamectl
# or
hostnamectl status
```

永久更改主机名称
```bash
hostnamectl set-hostname newname
```

#### ping

测试主机之间网络的连通性（ICMP）
```bash
ping www.baidu.com
```

#### tcpdump

监听网卡
```bash
tcmpdump                    # 默认监听第一个网卡
tcpdump -i eth0             # 监听 eth0 网卡
```

过滤条件
```bash
tcpdump -i eth0 'port 80'           # 监听 eth0 经过 80 端口的流量
tcpdump -i eth0 src host hostname   # 监听 eth0 由 hostname 主机发来的流量
tcpdump -i eth0 dst host hostname   # 监听 eth0 发送到 hostname 主机的流量
tcpdump -i eth0 tcp port 23 and host 210.27.48.1    # 监听 eth0 经过 23 端口与 210.27.48.1 主机通信的流量
tcpdump -i eth0 udp port 123        # 监听 eth0 的 UDP 的流量
```

wireshark
tshark

### 进程

#### ps

默认列出与当前 shell 有关的进程
```bash
ps
```

显示详细信息
```bash
ps -l
```

列出所有正在运行的进程
```bash
ps -aux
```

树状显示进程的关系
```bash
ps -axjf
```

#### pstree

显示所有进程
```bash
pstree
```

显示详细信息
```bash
pstree -a
```

显示所有进程及其 PID
```bash
pstree -p
```

#### pidof

查找进程的 PID
```bash
pidof nginx
```

#### top

交互式查看系统进程情况
```bash
top
```

#### htop

比 top 更为友好
```bash
htop
```

#### pmap

进程的内存映射关系
```bash
pmap -x PID     # 显示扩展格式
pmap -d PID     # 显示设备格式
pmap PID1 PID2  # 显示多个进程的内存映射
```

#### lsof

列出进程打开的文件
```bash
lsof
```

列出指定进程打开的文件
```bash
lsof -p PID
```

获取端口对应进程的 PID
```bash
lsof -i:22 -P -t -sTCP:LISTEN
```

指定用户进程所打开的文件
```bash
lsof -u user
```

#### kill/pkill/killall

列出所有信号量
```bash
kill -l
```

常用信号量
```
HUP     1    终端挂断
INT     2    中断（同 Ctrl + C）
QUIT    3    退出（同 Ctrl + \）
KILL    9    强制终止
TERM   15    终止
CONT   18    继续（与STOP相反，fg/bg命令）
STOP   19    暂停（同 Ctrl + Z）
```

根据 PID 终止进程
```bash
kill -s SIGKILL PID
kill -s KILL PID
kill -n 9 PID
kill -9 PID
```

根据进程名终止一组同名进程
```bash
pkill nginx
# or
killall nginx
```

#### jobs/fg/bg

显示作业状态
```bash
jobs
```

显示作业 PID
```bash
jobs -l
```

只显示 PID
```bash
jobs -p
```

列出活动的作业
```bash
jobs -r
```

列出停止的作业
```bash
jobs -s
```

例如出最近更改状态的作业
```bash
jobs -n
```

将最近停止的工作调到前台运行
```bash
fg
```

将特定工作调到前台运行
```bash
fg %1
```

将最近停止的工作调到后台运行
```bash
bg
```

将特定工作调到后台运行
```bash
bg %1
```

## shell

- 标准输入：stdin (0)
- 标准输出：stdout (1)
- 标准错误：stderr (2)

```bash
# 运行 cmd1 然后运行 cmd2
cmd1 ; cmd2

# 如果 cmd1 成功则运行 cmd2
cmd1 && cmd2

# 如果 cmd1 不成功则运行 cmd2
cmd1 || cmd2

# 在子 shell 中运行 cmd（后台 background）
cmd&
```

### IO 重定向

标准输出：>
```bash
# cmd 的标准输出（stdout）写入文件
cmd > file

# 丢弃 cmd 的标准输出
cmd > /dev/null
```

标准输入：<
```bash
# 从文件输入 cmd
cmd < file

# cmd2 的输出作为 cmd1 的文件输入
cmd1 <(cmd2)
```

标准错误：2>
```bash
# cmd 的错误输出（stderr）写入文件
cmd 2> file
```

附加
- 标准输出：>>
- 标准输入：<<
- 标准错误：2>>
```bash
# 将标准输出附加到文件
cmd >> file
```

合并输出：>&
```bash
# 标准输出写入与标准错误相同的位置
cmd 1>&2

# 标准错误写入与标准输出相同的位置
cmd 2>&1
```

重定向输出和错误到文件：&>
```bash
# cmd 的每个输出到文件
cmd &> file
```

### 管道

重定向
```bash
# cmd1 的标准输出转到 cmd2
cmd1 | cmd2

# cmd1 的标准输出和标准错误转到 cmd2
cmd1 |& cmd2
```
