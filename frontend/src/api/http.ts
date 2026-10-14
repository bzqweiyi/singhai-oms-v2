import axios from 'axios'

// 统一 HTTP 层:baseURL 走 vite 代理(开发)或同源(生产);
// withCredentials 携带旧系统 session cookie。
const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE || '/api',
  withCredentials: true,
  timeout: 30000,
})

export default http
