import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', name: 'login', component: () => import('../views/LoginView.vue') },
    {
      path: '/',
      // 骨架阶段:直接到 bunker 订单列表(路线 B 连旧 FastAPI 真实数据)
      redirect: '/orders/bunker',
    },
    {
      path: '/orders/bunker',
      name: 'bunker-orders',
      component: () => import('../views/BunkerOrdersView.vue'),
      meta: { title: '船加油订单' },
    },
  ],
})

router.afterEach((to) => {
  document.title = to.meta.title ? `${to.meta.title} · SingHai OMS v2` : 'SingHai OMS v2'
})

export default router
