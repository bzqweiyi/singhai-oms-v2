<script setup lang="ts">
// 船加油订单列表 —— 路线 B 首页面:连旧 FastAPI /api/bunker-orders 真实数据。
// 字段口径见旧仓 schemas.py BunkerOrderRow(docs/dto-blueprint.md)。
import { onMounted } from 'vue'
import { useListPage } from '../composables/useListPage'
import http from '../api/http'

interface BunkerOrderRow {
  order_no?: string
  biz_order_no?: string
  direction?: string
  counterparty_name?: string
  product?: string
  vessel_name?: string
  qty?: string
  delivered_qty?: string
  unit_price?: string
  order_value_usd?: number
  currency?: string
  workflow_status?: string
  invoice_status?: string
  inv_state?: string
}

// 旧系统返回 OrdersPageOut:{ok, items, page, page_size, total, total_pages, tab_counts}
const { loading, rows, total, query, load, search } = useListPage<BunkerOrderRow>(
  async (q) => {
    const { data } = await http.get('/bunker-orders', {
      params: {
        page: q.page,
        page_size: q.page_size,
        keyword: q.keyword || undefined,
        tab: '全部',
      },
    })
    return { items: data.items ?? [], total: data.total ?? 0, page: data.page, page_size: data.page_size }
  },
)

onMounted(load)
</script>

<template>
  <div class="page">
    <div class="toolbar">
      <el-input
        v-model="query.keyword"
        placeholder="搜索单号 / 客商 / 船名"
        style="width: 260px"
        clearable
        @keyup.enter="search"
        @clear="search"
      />
      <el-button type="primary" @click="search">查询</el-button>
    </div>

    <el-table v-loading="loading" :data="rows" stripe style="width: 100%">
      <el-table-column prop="order_no" label="订单号" min-width="140" />
      <el-table-column prop="direction" label="方向" width="80" />
      <el-table-column prop="counterparty_name" label="交易对手" min-width="160" show-overflow-tooltip />
      <el-table-column prop="product" label="油品" width="120" />
      <el-table-column prop="vessel_name" label="船名" min-width="140" show-overflow-tooltip />
      <el-table-column prop="qty" label="录单量" width="110" align="right" />
      <el-table-column prop="delivered_qty" label="已交货" width="110" align="right" />
      <el-table-column prop="unit_price" label="单价" width="110" align="right" />
      <el-table-column label="货值(USD)" width="130" align="right">
        <template #default="{ row }">
          {{ row.order_value_usd?.toLocaleString('en-US') ?? '' }}
        </template>
      </el-table-column>
      <el-table-column prop="workflow_status" label="状态" width="100" />
      <el-table-column prop="invoice_status" label="开票" width="100" />
      <el-table-column prop="inv_state" label="出入库" width="90" />
    </el-table>

    <el-pagination
      v-model:current-page="query.page"
      v-model:page-size="query.page_size"
      :total="total"
      :page-sizes="[10, 20, 50]"
      layout="total, sizes, prev, pager, next"
      style="margin-top: 12px; justify-content: flex-end"
      @current-change="load"
      @size-change="search"
    />
  </div>
</template>

<style scoped>
.page {
  padding: 16px 24px;
}
.toolbar {
  display: flex;
  gap: 8px;
  margin-bottom: 12px;
}
</style>
