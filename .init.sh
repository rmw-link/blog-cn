
if [ ! -e "node_modules" ]; then
yarn
fi

if [ ! -d "docs/.vuepress/public" ] ; then
git clone --depth=1 git@github.com:rmw-link/public.git docs/.vuepress/public
fi

