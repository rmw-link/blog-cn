用
DiskCache
存储最近1048576个端口 - 秘钥


IP 端口 ping pong

ping 时间 签名


成功交换公钥之后，记录到数据库

kad

请求登记在线 时间
  不能解码
    告知登记ID
      能解码
        告知登记成功
      不能解码
        走交换秘钥流程
  能解码
    超过MSL*60
      回复新时间 签名 对方响应新时间
    else
      回复正确，更新在线时间

每个登记最后2层，不超过16个
每15分钟登记1次


首次连接的时间 - IP
失败次数 - IP


下次尝试连接时间 = 首次成功连接时间 越小越好
最近一次成功连接时间 越大越好


find key
响应
  是否有IP
  是否有更加靠近的节点

IP 端口

响应 IP列表



ip 首次成功连接时间 下次尝试连接时间 连续失败次数

# https://github.com/rusqlite/rusqlite

本地接口

创建一个频道


远程接口

列出频道的订阅者
存储频道的的订阅者
  每个频道最大存储1024个不同IP的订阅者，如果超过，会按照kad的规则过期

id - 频道
频道id - 订阅者数
频道id - 订阅更新时间 value::cluster
频道id - 订阅者IP
订阅更新时间 - 订阅者IP
频道id - 下次检测时间

https://docs.rs/sonyflake/0.1.1/src/sonyflake/sonyflake.rs.html#55-83

有新IP进入就写入，如果订阅者数大于2048就放弃写入，但是标记更新
每过5分钟就检测这5分钟有更新并且订阅数大于1024的频道，检测最后一个订阅更新时间是否还活着
如果已经死了，就删除

choose

kad

distance - ip
ip - distance



32*32

定时器


The range start..end contains all values with start <= x < end. It is empty if start >= end.

启动
如果没有种子节点，那么插入配置文件中的种子节点，重新启动
向数据库前1024个订阅者发出请求
失败的打分乘以2，成功的打分为当前时间
排名在2048之后的节点删除

定时器检测是否有成功的节点
如果没有，重复启动步骤
如果都订阅者，请求订阅者的主订阅频道
主订阅频道为更新信息，不可退订


每个人存2048个频道，如果超出，踢走距离最远的



启动

读取频道的kad种子
尝试连接
定期检查


频道
订阅者

频道id 订阅者id
choose

频道id 订阅者数



创建频道

  名称
  简介
  语言
  国家/地区
  标签(不超过7个)
  申请加入问答
    问题

  版本哈希
  更新时间
  签名
  公钥
  发布者的IP和端口

推送频道到kad网络

-> 公钥 频道公钥 时间 版本哈希 签名

记录24小时（每小时刷新一次）

----

K桶

编辑距离 1024 个




每个人有个频道的kad桶




订阅某个频道 频道公钥 订阅者公钥（同时记录，IP端口信息) (72小时之后自动超时）
获取频道订阅者列表 时间之后
更新频道信息


存储订阅
1024个节点
超过1024
有新订阅的时候
请求老的订阅
如果没响应，就移除，并加入新的订阅者到队列末尾


每个订阅者
以kad方式存储邻居订阅
128个邻居
有新邻居的时候，请求老邻居，如果没响应，移除并加入新邻居

获取之后进行推送





请求

指令 公钥

每个人存储其他订阅者的订阅

对于频道KEY的订阅
  IP 端口 最后在线时间

频道名称
频道简介
频道公钥
频道内容
  对签名的哈希
  时间
  内容
  内容类型
  上一条内容的签名的哈希
  签名

启动流程


kad
  is_empty
  boot(ip_seed_list)
  next(bucket_id)
    到了最后一个就返回none
  connected(ip,key)
  heartbeat(ip)
  expired 每20秒检测一次


启动

  数据库
    kad
      距离
        IP 端口 公钥


  快速连接
    CMD KEY 代表需要重新连接
    如果 在connecting状态
      回第一步ping
    否则
      发送 KEY 加密的公钥


https://docs.rs/async-std/1.9.0/async_std/task/fn.sleep.html

当没有节点的时候会一直运行boot
数据库只保留1024个

kad
  bucket
    [8]
      ip
      key
      last_time
    [candidate]

从数据库每个bucket读取128个节点，同时开始连接，也就是同时发出4096个请求
每个bucket维持8个连接

从第一个非空且不满8个的桶开始

如果bucket没满，搜索bucket


任何一个新来的节点（假设叫 A），需要先跟 DHT 中已有的任一节点（假设叫 B）建立连接。
A 随机生成一个散列值作为自己的 ID（对于足够大的散列值空间，ID 相同的概率忽略不计）
A 向 B 发起一个查询请求（协议类型 FIND_NODE），请求的 ID 是自己（通俗地说，就是查询自己）
B 收到该请求之后，（如前面所说）会先把 A 的 ID 加入自己的某个 K 桶中。
然后，根据 FIND_NODE 协议的约定，B 会找到【K个】最接近 A 的节点，并返回给 A。
（B 怎么知道哪些节点接近 A 捏？这时候，【用 XOR 表示距离】的算法就发挥作用啦）
A 收到这 K 个节点的 ID 之后，（仅仅根据这批 ID 的值）就可以开始初始化自己的 K 桶。
然后 A 会继续向刚刚拿到的这批节点发送查询请求（协议类型 FIND_NODE），如此往复（递归），直至 A 建立了足够详细的路由表。


接收到请求之后，也会来填桶，如果桶不满
每个桶有128个候选，候选不发心跳，只是备用

每有一个超时，就尝试补充一个新的


快速重连

请求
响应没有公钥


每19秒ping一次
超过60秒没ping，就丢弃重连

记录历史IP端口，连接时间
依次遍历
每次遍历20个

## ip_public
## public_ip
## 编辑距离
    最后连接时间
    ip



loop
  从配置文件读取IP，如果数据库不存在，就放到数据库，权重为当前时间

  从数据库读取ip地址 最多读取64个

  成功连接时间 IP
  按成功连接时间正序排

  连接成功写入数据库，权重为时间

  连接失败
    如果有连接成功
      if 权重 >= MAX/1.1
        删除
      else
        权重*=10%
    从数据库读取更多

  从 KAD 网络请求更多节点




# 接口

如果时间大于当前时间1分钟，就拒绝接收。

* 获取A的订阅频道列表
  * 参数
    * 订阅的起始时间
  * 返回
    * [ 订阅的频道公钥 订阅时间 ]

* 获取频道标题
  * 参数
    * 频道的公钥
  * 返回
    * 时间戳
    * 频道的标题
    * 频道对标题(标题+时间戳)的签名

* 获取频道的订阅者
  * 参数
    * 编辑距离
  * 返回
    * [公钥 信用分]
      * 积分计算公式
         * 推送成功一次 积分 = log(e**积分 + (t-1624596444)/7/24/3600))

* 获取频道下一个更新哈希, 更新哈希是merkletree
  * 参数
    * 频道的公钥
    * 当前哈希 （如果为空，表示头开始）
  * 返回
    * 没更新 返回 空
      * 如果发现对方比自己新，反向请求对方来更新自己
    * 有更新（成功更新后，给对方节点信用加一）
      * 时间戳 (不能大于当前系统时间+100秒，不能小于前一个哈希的时间，否则忽略)
      * 哈希
      * 更新内容的大小
      * 文件名 不超过128个中文字符（或256个英文）
      * 频道对标题(时间戳+文件名+哈希+更新内容大小+上一个哈希)的签名

* 通过哈希获取merkletree
  * 参数
    * 哈希
    * offset
    * 位图
  * 返回值
    * 哈希
    * offset

// 每个文件如果大于1458176字节就有一个merkletree哈希文件
// 文件下载下来之后会做一次merkletree效验，如果有问题

* 通过哈希获取内容
  * 参数
    * 哈希
    * offset

  * 返回值
    * 哈希
    * offset

  下载进度的数据结构
    * 起始offset
    * 缺失的碎片
    * 结束offset

* 响应

  缺失 某个包
    会向另外一个终端请求
    直到遍历完所有终端


  拥塞控制

    上一秒收到的包数
    这一秒收到的包数
    当前请求包的速度 // 初始请求的包速度为 1024*1024 字节 (可配置？)

    if 如果这一秒收到的包数 >= 当前请求包的速度
      每秒请求的包数 = 请求包的速度*2 + 1
    else
      每秒请求的包数 = max(这一秒收到的包数,上一秒收到的包数)+1


  丢包重发

    * begin = 最后一个获得的包 - 当前请求包的速度 * 4(可配置？)
      if begin > 起始offset
        for i in 起始+1 to begin
          如果 not in 收到
            位图为1

        不超过1424字节
        不超过每秒请求的包数

    if 收到的包数 >= 请求的包数
      请求的包数 = 请求的包数+1
    else
      请求的包数 = max(1,请求的包数/2)


  请求流程
    * 最后一个碎片的offset

  收到响应
    * 如果碎片 = 开始+1
      n = 1
      -> 如果最后一个碎片 == n
        end -= 1
        continue
      -> 如果n > end
        丢弃
        break
      -> 检查是否开始+n的碎片
          如有
            ++n
            continue
      -> 开始+=n
          break


  1472-8(xxh3)-32(hash)-8(offset) = 1424

# https://doc.rust-lang.org/std/io/trait.Seek.html
# https://docs.rs/memmap/0.7.0/memmap/struct.MmapMut.html
# https://github.com/oconnor663/bao

频道更新哈希可以获取频道更新的目录

接口
  获取A的订阅列表，按A同步次数排序
  查找节点公钥


KAD网络设计

有64个桶，每个桶大小为8，当前一个桶被填满的时候，会分裂一下去填充下一个桶。

每个桶再保留32个作为候补，这样就有 32*8*16 = 4096个候补。

每个节点会与自己相近的32*8*16=2048个节点保持通讯
心跳包每19秒一次
UDP 空包的大小 = IP头(20) + UDP头(8) = 28
也就是理论上维持连接的带宽消耗为 2048/19*28 = 3242字节每秒
事实上应该没有这么多，因为不会32个bucket都填满

网络接口

FIND 公钥

  返回公钥编辑距离对应的kad桶和候补桶
  如果不足24个，从前后的桶取可用+候补的填充直到填满24个
  返回公钥+IP端口



# 数据库设计

表

0. id - 私钥
1. 公钥 - id
2. 登录时间 - 私钥id
3. 私钥id - 登录时间
4. 私钥id - 用户昵称(不超过32个字符)

10. id - 公钥
11. id - 公钥id + 前一个公钥id  // 我订阅的公钥
12. id -

// 公钥的订阅者
// 100. id - 可用的IPV4 & 端口
// 101. 最后成功连接的时间 - ipv4.id
// 102. ipv4.id - 最后成功连接时间
// 103. ipv4.id - 公钥id // 1-1
// 104. 公钥id - ipv4.id // 1-n

订阅A频道
广度遍历A的订阅者
  A按照Kad存储32*8*16=不超过4096个订阅者
不断迭代填充自己的K桶
检测更新
同步内容

为了防止攻击，每个订阅者订阅需要给A支付
