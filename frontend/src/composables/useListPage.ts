// useListPage —— 列表页四件套 composable(对标旧仓 _list_kit + list_kit.js)。
// 旧仓四件套:筛选条件 / 列宽与显示偏好(grid prefs 持久化) / 导出 / 分页。
// 设计稿先行,骨架阶段只实现分页+筛选注入,P0 页面翻译时补列宽记忆与导出。
import { ref, reactive } from 'vue'

export interface ListQuery {
  page: number
  page_size: number
  keyword: string
  [key: string]: unknown
}

export interface ListResult<T> {
  items: T[]
  total: number
  page: number
  page_size: number
}

export function useListPage<T>(
  fetcher: (q: ListQuery) => Promise<ListResult<T>>,
  defaultQuery: Partial<ListQuery> = {},
) {
  const loading = ref(false)
  const rows = ref<T[]>([])
  const total = ref(0)
  const query = reactive<ListQuery>({
    page: 1,
    page_size: 20,
    keyword: '',
    ...defaultQuery,
  })

  async function load() {
    loading.value = true
    try {
      const r = await fetcher(query)
      rows.value = r.items
      total.value = r.total
    } finally {
      loading.value = false
    }
  }

  function search() {
    query.page = 1
    return load()
  }

  return { loading, rows, total, query, load, search }
}
