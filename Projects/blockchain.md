# 实验室自主研发区块链

时间：2020.09 ~ 2021.01

项目地址：https://github.com/KKSKProject/CA

## 项目介绍

基于 Kademlia（P2P）网络，使用 Kafka 实现共识算法开发的联盟链，用于实现安全通信与防篡改账本。

<img src="images/20220426160320.png">

## 负责内容

为了保证进入区块链网络的节点是安全、有效的节点，参照 FISCO-BCOS 和 Fabric 的准入机制设计区块链的身份认证方案。

1. 国密算法应用
   
   1. 用 SM3 代替 SHA-256 等作为默认的密码杂凑算法
   2. 用 SM2 替代 ECDSA 签名算法
   3. 用 SM2 证书代替 RSA、ECDSA 证书

   哈希算法
   - 公钥的哈希值作为用户交易地址
   - 签名前对消息进行散列
   - 区块哈希值保证防篡改

   公钥密码算法
   - 公钥的哈希值作为用户交易地址
   - 公钥证书，私钥签名
   - TLS/SSL

2. 证书层级
   
   1. 链证书：一条区块链上，链证书有且仅有一个（root CA），安装在所有节点
   2. 机构证书：签发节点证书时附加在节点证书中，intermediate CA
   3. 节点 / SDK 证书：所有节点都向 intermediate CA 申请证书
   
   <details>
    <summary>架构</summary>
    <img src="images/20220426164618.jpg" width="60%">
   </details>

3. 入网流程

   1. 节点应内置链证书（即根 CA 证书）
   2. 管理员为节点生成一次性口令（OTP）
   3. 节点在本地生成密钥对，使用证书请求文件（CSR）与 OTP 请求 intermediate CA 签发证书
   4. Intermediate CA 验证 OTP 有效性后为其签发证书，同时发送自己的证书
   5. 节点验证 intermediate CA 的证书由根 CA 签发，存储证书
   6. 节点可以凭借证书进入区块链网络，与网路中的其他节点进行通信
   
   <details>
    <summary>时序图</summary>
    <img src="images/20220426164720.png" width="60%">
    <img src="images/20220426164805.png" width="60%">
   </details>

4. 容器化
   
   将区块链及证书颁发机构源码打包为 Docker 镜像，支持 Docker Compose 自动化部署。
   1. MySQL
   2. CA
   3. Vue
   4. ZooKeeper
   5. Kafka
   6. Bootstrap Node
   7. Order Node
   8. Storage Node

## 应用

1. 基于区块链的安全通信技术

    基于区块链的安全通信技术主要利用了区块链技术的开放性、防篡改以及可追溯性，通过加密消息上链，让去中心化的区块链作为中继的方式，实现 `节点 -> 区块链 -> 节点` 的消息传输。根据区块按固定时间间隔上链的特性，在消息的传输，即由发到收的过程会牺牲一部分及时性，但整体却很大程度上保障了通信的安全、容错性、防篡改以及可回溯性。

2. 区块链 + IoT

    创建共享交易的防篡改记录，物联网设备可跟踪关键设备，区块链提供了一个不可篡改的分类账，涵盖运营数据和由此产生的维护操作。第三方合作伙伴可以监控区块链，开展预防性维护，并将其工作记录在区块链上。利用区块链的不可篡改性、安全性，保证每笔交易的合规性。

## 问题解决

1. 证书何时颁发，如何颁发？
   
   - 节点初始化时安装链证书，节点启动前安装完毕，通常是直接拷贝；
   - 节点使用 OTP 与 CSR 请求 intermediate CA 签发证书，同时能够得到 intermediate CA 的证书。

2. 黑白名单
   
   FISCO-BCOS 黑白名单机制：
   > 底层实现 SSL 双向验证。节点在 handshake 过程中，通过对方提供的证书获取对方节点的 nodeID，检查该 nodeID 与节点配置的黑、白名单是否有关系。如果根据黑、白名单的配置，拒绝该关闭的 connection，继续后续流程。
   > 黑名单的优先级高于白名单。
   > FISCO BCOS 要求实现 SSL 双向认证。节点在 handshake 过程中，从对方节点提供的证书中获取对方节点的 nodeID，检查该 nodeID 是否在自身的 CA 黑名单。如存在，关闭该 connection，如不在，建立 session。
   > CA 黑名单机制也支持 SSL 单向认证的场景，作用时机是：节点在 session 建立后，可从 session 中获取对方节点的 nodeID 进行判断，如果 nodeID 在自身的 CA 黑名单中，将已建立的 session 断连。

   内容为节点 ID 列表，节点根据黑白名单决定是否建立连接，双向认证时关闭连接，或建立连接后再进行判断和连接关闭。

3. 国密 TLS 兼容性
   
   主流浏览器并不支持国密 TLS，因此使用双证书服务器作为跳板。
   - [部署国密SSL证书，如何兼容国际主流浏览器？](https://developer.aliyun.com/article/705752)
   
   <img src="https://yqfile.alicdn.com/471d2616a277072113cd8759401fb68fc1d20d8d.jpeg">
   
   两种方案：
   1. 浏览器 <--(RSA)--> 网关 <--(SM2)--> 区块链网络（+ CA 服务器集群）
   2. 浏览器 <--(RSA)--> 网关 <--(SM2)--> 区块链网络，浏览器 <--(RSA)--> CA 服务器集群

## 技术细节

### HTTPS

HTTPS = HTTP + TLS / SSL
- 密钥协商（Diffie–Hellman）
  - 随机数、非对称
- 证书验证
  - 单向：客户端验证服务器证书的有效性
  - 双向：双方互相验证证书的有效性
- 生成会话密钥
  - 对称

相关材料
- [深入理解HTTPS工作原理](https://juejin.im/post/6844903830916694030)
- [HTTPS 详解一：HTTPS 原理图](https://segmentfault.com/a/1190000021494676)
- [HTTPS 详解二：SSL / TLS 工作原理和详细握手过程](https://segmentfault.com/a/1190000021559557)
- [The Illustrated TLS Connection](https://tls.ulfheim.net/)

### X.509 证书

证书链
- 根 CA：自签证书
- 中间 CA
- 节点证书

<img src="images/20220426175709.jpg" width="50%">

证书内容
- 版本
- 序列号
- 签名算法
- 颁发者
- 有效期
- 主体
- 主体公钥
- 颁发者 ID（可选）
- 主体 ID（可选）
- 扩展（可选）
- 数字签名

<img src="images/20220426175655.jpg" width="50%">

证书文件
- 使用 ASN.1（抽象语法标记）的 X.509 证书文件是字节数组，为了节约空间，通常使用 Base64 编码的 PEM 格式保存证书文件。
- 此外，还有 DER（辨别编码规则）二进制编码格式
- PEM 格式和 DER 格式可以相互转换

```
3a 20 63 65 72 74 6c 69  62 5c 6c 64 61 70 2e 63
70 70 28 32 31 33 31 29  3a 20 6c 64 61 70 65 72
```

PEM 格式：隐私增强型电子邮件格式（RFC1421），以下几种文件通常是 PEM 格式
- `.key`
- `.csr`
- `.crt`

```
PKCS#1 private key
-----BEGIN RSA PRIVATE KEY-----
MIIDBjCCAm8CAQAwcTERMA8GA1UEAxMIcXV1eC5jb20xDzANBgNVBAsTBkJyYWlu
czEWMBQGA1UEChMNRGV2ZWxvcE1lbnRvcjERMA8GA1UEBxMIVG9ycmFuY2UxEzAR
BgNVBAgTCkNhbGlmb3JuaWExCzAJBgNVBAYTAlVTMIGfMA0GCSqGSIb3DQEBAQUA
<...>
-----END RSA PRIVATE KEY-----

PKCS#8 private key
-----BEGIN PRIVATE KEY-----
MIIDBjCCAm8CAQAwcTERMA8GA1UEAxMIcXV1eC5jb20xDzANBgNVBAsTBkJyYWlu
czEWMBQGA1UEChMNRGV2ZWxvcE1lbnRvcjERMA8GA1UEBxMIVG9ycmFuY2UxEzAR
BgNVBAgTCkNhbGlmb3JuaWExCzAJBgNVBAYTAlVTMIGfMA0GCSqGSIb3DQEBAQUA
<...>
-----END PRIVATE KEY-----

csr
-----BEGIN NEW CERTIFICATE REQUEST-----
MIIDBjCCAm8CAQAwcTERMA8GA1UEAxMIcXV1eC5jb20xDzANBgNVBAsTBkJyYWlu
czEWMBQGA1UEChMNRGV2ZWxvcE1lbnRvcjERMA8GA1UEBxMIVG9ycmFuY2UxEzAR
BgNVBAgTCkNhbGlmb3JuaWExCzAJBgNVBAYTAlVTMIGfMA0GCSqGSIb3DQEBAQUA
<...>
-----END NEW CERTIFICATE REQUEST-----

crt
-----BEGIN CERTIFICATE-----
MIIEITCCA+CgAwIBAgIUKMmxmDbjbHqt+Yzwj5lflBxuQwEwCQYHKoZIzjgEAzAjMSEwHwYDVQQD
ExhUb2tlbiBTaWduaW5nIFB1YmxpYyBLZXkwHhcNMTIxMTE2MTgzODMwWhcNMTIxMTIzMTgzODMw
WjAtMSswKQYDVQQDHiIAYgBiADEANAAxADkAYQAyAGMAZgBjADEAZQAwADAAOAAAMIGfMA0GCSqG
<...>
-----END CERTIFICATE-----
```

证书吊销：OCSP 协议，未实现。
- 在线证书状态协议（Online Certificate Status Protocol）
- 向 CA 服务器请求验证证书有效性

### MySQL

1. JWT
   
   全称 JSON Web Token，用于实现管理员的登陆退出，记录登录信息。考虑使用 Redis 管理，未实现。

2. OTP
   
   全称 One-Time Password，作为节点入网申请证书的凭据，存在有效期。

<img src="images/20220426194927.png" width="60%">

### Golang 库

1. Echo
   
   用于搭建 CA 服务器

2. Zap + Lumberjack
   
   日志分级记录 + 滚动记录
   
3. Viper
   
   使用 yaml 文件管理数据库、服务器、证书、JWT 的配置信息

### 其他

共识算法
- 支持 PBFT、Raft

Postman
- 测试服务器接口

Vue
- 提供给管理员的界面
