import { defineStore } from 'pinia'

// 骨架阶段:登录直接 POST 旧 FastAPI 的 /login(Form 表单),cookie 由浏览器携带。
// 旧系统 /login /logout 在 /api 前缀之外,这里用裸 fetch 不走 axios baseURL。
// Go 版登录域翻译后只换 endpoint,本 store 接口不变。
export const useAuthStore = defineStore('auth', {
  state: () => ({ loggedIn: false }),
  actions: {
    async login(username: string, password: string) {
      const body = new URLSearchParams({ username, password })
      const res = await fetch('/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString(),
        credentials: 'include',
      })
      if (!res.ok && res.redirected === false) throw new Error('login failed')
      this.loggedIn = true
    },
    async logout() {
      await fetch('/logout', { credentials: 'include' }).catch(() => {})
      this.loggedIn = false
    },
  },
})
