# 技术栈 & 参考资料

* [嵌入式数据库 sdb](https://docs.rs/crate/sdb)

## rust

* [通过例子学Rust](https://rustwiki.org/zh-CN/rust-by-example)
* [Rust返回引用的不同策略](https://colobu.com/2019/08/13/strategies-for-returning-references-in-rust/)
* [Rust的dbg!宏](http://chenyukang.github.io/2019/01/18/rust-dbg.html)
* [Rust的包装类型](https://blog.lxdlam.com/post/b63a9600/)
* [Rust程序设计语言](http://kaisery.github.io/trpl-zh-cn)
* [Rust高级编程](https://learnku.com/docs/nomicon/2018)

### 学习笔记

#### 堆栈和Box

rust 不能返回 unsized 的 trait，但是可以返回 Box<unsized trait>

比如如下：

```
pub fn key_iter<'a, T, K, V, P>(
  txn: &'a T,
  db: &Db_<K, V, P>,
  key: &'a K,
) -> Result<Box<dyn Iterator<Item = Result<(&'a K, &'a V), T::Error>> + 'a>, T::Error>
where
  T: LoadPage,
  K: 'a + PartialEq + Storable + ?Sized,
  V: 'a + Storable + ?Sized,
  P: 'a + BTreePage<K, V>,
{
  ...
  Ok(Box::new(
    if (xx) {
      KeyIter { cursor, txn, key }))
    } else {
      StopIter {} 
    }
  )
}
```

上面代码的真实场景是，某种情况下可以直接返回停止了的迭代器，某种情况下返回可以在真实数据上的迭代器，而K和V大小是未定义的（?Sized）。

这是因为Box<T>指向堆上的数据，参考 [使用Box <T>指向堆上的数据](https://kaisery.github.io/trpl-zh-cn/ch15-01-box.html#%E4%BD%BF%E7%94%A8box-t%E6%8C%87%E5%90%91%E5%A0%86%E4%B8%8A%E7%9A%84%E6%95%B0%E6%8D%AE)

Box没有性能损耗，除了堆比栈慢一点。不过，性能过早最优化是万恶之源。



