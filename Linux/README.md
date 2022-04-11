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
