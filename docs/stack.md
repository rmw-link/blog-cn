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

rust 不能返回 unsized 的 trait，但是可以返回 `Box<unsized trait>`

这是因为`Box<T>`指向堆上的数据，参考 [使用`Box <T>`指向堆上的数据](https://kaisery.github.io/trpl-zh-cn/ch15-01-box.html#%E4%BD%BF%E7%94%A8box-t%E6%8C%87%E5%90%91%E5%A0%86%E4%B8%8A%E7%9A%84%E6%95%B0%E6%8D%AE)。

堆上的数据，是运行时候根据数据类型，动态申请的内存 ; 而栈上的数据，是编译时候就明确数据类型的大小。

Box没有性能损耗，除了堆比栈慢一点。不过，性能过早最优化是万恶之源。

举一个实际工程中的例子：

下面代码([sdb/src/iter](https://github.com/rmw-link/sdb/blob/master/src/iter.rs))的场景是，某些时候会直接返回停止了的迭代器（StopIter），而K和V大小是未定义的（?Sized）。

```
pub fn key_iter<'a, T, K, V, P>(
  txn: &'a T,
  db: &Db_<K, V, P>,
  key: &K,
) -> Result<Box<dyn Iterator<Item = Result<(&'a K, &'a V), T::Error>> + 'a>, T::Error>
where
  T: LoadPage,
  K: 'a + PartialEq + Storable + ?Sized,
  V: 'a + Storable + ?Sized,
  P: 'a + BTreePage<K, V>,
{
  let mut cursor = Cursor::new(txn, db)?;

  match cursor.set(txn, key, None)? {
    Some((key_c, _)) => Ok(Box::new(KeyIter {
      cursor,
      txn,
      key: key_c,
    })),
    None => Ok(Box::new(StopIter::<T, K, V>(PhantomData {}))),
  }
}

pub struct StopIter<'a, T: LoadPage, K: PartialEq + Storable + ?Sized, V: Storable + ?Sized>(
  PhantomData<(&'a T, &'a K, &'a V)>,
);

impl<'a, T: LoadPage, K: PartialEq + Storable + ?Sized + 'a, V: Storable + ?Sized + 'a> Iterator
  for StopIter<'a, T, K, V>
{
  type Item = Result<(&'a K, &'a V), T::Error>;
  #[inline]
  fn next(&mut self) -> Option<Self::Item> {
    None
  }
}

pub struct KeyIter<
  'a,
  T: LoadPage,
  K: PartialEq + Storable + ?Sized,
  V: Storable + ?Sized,
  P: BTreePage<K, V>,
> {
  txn: &'a T,
  cursor: Cursor<K, V, P>,
  key: &'a K,
}

impl<
    'a,
    T: LoadPage,
    K: PartialEq + Storable + ?Sized + 'a,
    V: Storable + ?Sized + 'a,
    P: BTreePage<K, V> + 'a,
  > Iterator for KeyIter<'a, T, K, V, P>
{
  type Item = Result<(&'a K, &'a V), T::Error>;
  #[inline]
  fn next(&mut self) -> Option<Self::Item> {
    let entry = self.cursor.next(self.txn).transpose();
    match entry {
      Some(kv) => match kv {
        Ok((k, _)) => {
          if k == self.key {
            Some(kv)
          } else {
            None
          }
        }
        _ => Some(kv),
      },
      _ => entry,
    }
  }
}
```


#### `to_owned`

把数据从栈中复制到堆中，成为自己的数据。

一般就是转型为兄弟类型的数据，比如

* &str => String
* Path => PathBuf

#### `#![feature(decl_macro)]`

`macro_rules!`

声明的宏没法使用use，否则会出现reimported（当调用一个宏多次之后）

加入 #![feature(decl_macro)] 之后就可以使用 

类似这样的写法

```
#[macro_export]
pub macro repr($cls:ident) {
  use sdb::direct_repr;
  direct_repr!($cls);
}
```

参见 [声明性宏 2.0](https://github.com/rust-lang/rust/issues/39412)

#### 过程宏

过程宏就是自己解析语法树，输出代码。

过程宏必须是一个单独的包，可以用子包来实现。

参见 [sdb](https://github.com/rmw-link/sdb)




