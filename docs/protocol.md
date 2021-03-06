# 对等网通讯协议设计

在构建软件之前，先定义通讯协议。

协议的目标是实现一个对等的人民网络 ：人人平等，无中心服务器，无人垄断数据。

## 身份秘钥

加入人民网络前，首先要生成身份秘钥。

身份秘钥是Ed25519密钥对。

我们用效率更高的blake3-512替换标准Ed25519算法中的sha512作为哈希函数，代码实现参见[ed25519-dalek-blake3](https://github.com/rmw-dart/ed25519-dalek-blake3/blob/master/src/blake3_512.rs)，更快是极客永恒的追求。

首次启动时，客户端会自动生成一个密钥对。

不同设备可以导入同一秘钥，也就是说，你的平板、手机、电脑可以同时在线。

如果身份秘钥丢失了，只能放弃原有的账户，重新生成一个新的身份。

所以，务必对秘钥做好备份。

在开放的对等网络里，攻击者可以伪造大量虚假节点身份，进而控制网络。

我们通过消耗一定的计算资源来提高攻击者的成本。

因此，我们规定公钥的字节码（uint8数组）必须 0、 0 开头。

传输公钥的时候，也不传输开头两个字节。

## 探测端口

假设有两个节点：A 和 B （一个节点就是一个在线的人民网设备）。

A要和B建立首次连接。

首先，A发送一个字节的UDP包进行PING，包的内容为 0x01 。

B收到了内容为 0x01 的UDP包，响应 0x02 标识自己在线。

这第一步，目的用来探测对方是否在线。

将探测在线的包设计的足够小、同时选用UDP作为底层通讯协议，是为了方便端口扫描、打洞、内网穿透，进而实现任意节点之间互联互通和大文件的分发。

协议设计中发送的包等于响应的包尺寸（发送1个字节，响应1个字节），可避免恶意节点伪造网络地址从事[UDP反射放大攻击](https://wikipedia.org/wiki/Denial-of-service_attack#Reflected_.2F_spoofed_attack)。

A把正在探测中节点的IP地址和端口放入带超时的缓存。

A收到B的响应后，首先检查缓存，确认B的IP地址和端口是否在探测中，如果不在就忽略（同样是为了避免放大攻击）。

超时缓存的代码实现上，我们使用修改版的[retainer](https://github.com/gcxfd/retainer)，与原实现相比，添加了获取创建超时时间的接口(expiration)，方便计算通讯延时。

在[udp/mod.rs](https://github.com/rmw-link/rust/blob/master/src/udp/mod.rs#L19)中定义了探测超时时间为3秒(`connecting.monitor(2, 0.5, Duration::from_secs(3))`)。

对于地球环境，3秒的超时足够了。如果将来用于地球-火星通讯，可以修改为1369秒超时（地球和火星最远距离为1342光秒）。

## 建立连接

A收到B的响应，然后A发送 0x03 + A的公钥给B（可以先尝试从这一步开始连接，超时后再去探测端口）。

为了避免日蚀攻击，B会响应 0x04 + xxhash3-128(A的端口+A的IP+A的公钥+B的公钥)。

A收到的后，会检测B是否在连接中的队列，如果是，响应 0x05 + A的公钥 + 签名(上一步的xxhash128+盐) + 盐，确保xxhash3-64（盐+上一步的 xxhash128）的二进制表示的开头有16个0 。

B收到后，校验盐，校验签名，然后响应 0x03 + B的公钥 + A的公钥的连接id(4字节) 。

连接id可以用xxhash32(私钥)生成。

A收到后，根据长度判断是第三步还是第六步，检测是否在连接中的队列，如果在

  检查连接id是否与已有的连接id冲突，如果冲突，告诉B一个新的连接id

  如果不冲突，从连接中的队列删除B，并记录B的公钥。

Ed25519的公钥和秘钥可以转换为X25519的公钥和秘钥。

参见:

  * [USING ED25519 SIGNING KEYS FOR ENCRYPTION](https://blog.filippo.io/using-ed25519-keys-for-encryption/)
  * [ed25519-dalek-blake3](https://github.com/rmw-dart/ed25519-dalek-blake3/commit/3ea98e4403942b328b1deedf322619622e4503a7)

所以，交换Ed25519公钥之后，就可以通过X25519协议生成秘钥([迪菲-赫尔曼密钥交换](https://zh.wikipedia.org/wiki/%E8%BF%AA%E8%8F%B2-%E8%B5%AB%E7%88%BE%E6%9B%BC%E5%AF%86%E9%91%B0%E4%BA%A4%E6%8F%9B))。

A收到B的公钥后，会加密请求一次B的根节点哈希, 0x04+加密的空包。（因为公钥不经常改变，所以二次连接可以直接尝试从这一步开始）。

B响应0x05+加密的根节点哈希。

当收到加密的根节点请求或响应时候连接才算真正建立，会加入心跳打洞的队列中去。

## 打洞心跳

由于UDP转换协议提供的“洞”不是绝对可靠的，多数NAT设备内部都有一个UDP转换的空闲状态计时器，如果在一段时间内没有UDP数据通信，NAT设备会关掉由“打洞”操作打出来的“洞”，做为应用程序来讲如果想要做到与设备无关，就最好在穿越NAT的以后设定一个穿越的有效期。很遗憾目前没有标准有效期，这个有效期与NAT设备内部的配置有关，最短的只有20秒左右。在这个有效期内，即使没有p2p数据包需要传输，应用程序为了维持该“洞”可以正常工作，也必须向对方发送“打洞”维持包。这个维持包是需要双方应用都发送的，只有一方发送不会维持另一方的会话正常工作。

所有，为了保证打洞有效，双方每19秒都向对方发一次心跳包(有些路由器UDP老化时间只有20秒)，包内容为空包。

### 加密解密

我们基于 [xxh3](https://crates.io/crates/twox-hash) 和 [blake3](https://crates.io/crates/blake3) 自定义了一个流加密算法，以方便将对每个UDP包单独加密。

加密流程 :

  1. 校验码 = xxh3::Hash64(原始内容) `// seed = 0`
  1. 流密码 = blake3(校验码+秘钥), 哈希输出长度=内容长度
  1. 加密内容 = 原始内容 异或 流密码
  1. 加密校验码 = xxh3::Hash64(加密内容+秘钥) 异或 校验码 `// seed = 181855_198662_19491001`
  1. 输出 = 加密校验码 + 加密内容

解密流程 :

  1. 校验码 = xxh3::Hash64(加密内容+秘钥) 异或 加密校验码 `// seed = 181855_198662_19491001`
  1. 流密码 = blake3(校验码+秘钥), 哈希输出长度=内容长度
  1. 解密内容 = 加密内容 异或 流密码
  1. 完整性效验 : 计算 xxh3::Hash64(解密内容) == 校验码 `// seed = 0`

代码实现参见 [xxblake3](https://docs.rs/crate/xxblake3)

## 发现彼此

## 对等网络

快慢表 Kademlia 网络

参考文献 : [一种针对P2P网络优化的Kademlia路由算法](/pdf/P2P-Kademlia.pdf)








