module.exports = {
  themeConfig:
    sidebar:[
      '/'
      '/log'
      # '/protocol'
      #      '/db'
     # '/stack'
    ]
    nav: [
      {
        text: '聊天室',
        rel:'chat'
        items: [
          {
            text: '网页版',
            link: 'https://rmw.zulipchat.com'
          }
          {
            text: '客户端',
            link: 'https://rmw.zulipchat.com/apps'
          }
        ]
      }
    ]

    search: false
  locales:
    '/':
      lang: 'zh-CN'
      title: '人民网络'
      description: '打到数据霸权 · 网络土地革命'
  plugins: {
    sitemap:
      hostname: 'https://rmw.link'
    'vuepress-plugin-awesome-gitalk': {
      #log: true
      enable: true
      root: "gitalk-container"
      maxRetryCount: 5
      defaultCheckMinutes: 500
      home: true
      ignorePaths:['']
      gitalk: {
        clientID: '0ffd59d6a7c2fda21cd7'
        clientSecret: '5ba1b626d7c351892cc728c5ce268b7c747af8ba'
        repo: 'blog-reply'
        owner: 'rmw-link'
        admin: ['gcxfd']
      }
    }
  }
}
