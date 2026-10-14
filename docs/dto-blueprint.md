# DTO 蓝本(阶段 0 基线资产)

> 由旧仓 schemas.py AST 自动生成。规则:Python 字段名 snake_case → Go json tag 沿用
> 旧 API 的别名(alias);Optional→指针;宽松反序列化原则见 README 口径铁律 4。
> 翻译时逐字段核对,尤其 `Row` 基类的 extra="allow" 透传行为。

## OkListOut  (基类: BaseModel, Generic[T])
```go
type OkListOut struct {
	ok bool `json:"ok"`
	items []interface{} `json:"items"`
}
```

## OrdersPageOut  (基类: BaseModel, Generic[T])
```go
type OrdersPageOut struct {
	items []interface{} `json:"items"`
	page int64 `json:"page"`
	page_size int64 `json:"page_size"`
	total int64 `json:"total"`
	total_pages int64 `json:"total_pages"`
	tab_counts map[string]interface{} `json:"tab_counts"`
}
```

## ExecutionOut  (基类: OkListOut[T], Generic[T])
```go
type ExecutionOut struct {
	stats map[string]interface{} `json:"stats"`
}
```

## ArItemsOut  (基类: OkListOut[T], Generic[T])
```go
type ArItemsOut struct {
	page int64 `json:"page"`
	page_size int64 `json:"page_size"`
	total int64 `json:"total"`
	total_pages int64 `json:"total_pages"`
	sum_outstanding interface{} `json:"sum_outstanding"`
	sum_overdue interface{} `json:"sum_overdue"`
}
```

## ChargeLedgerOut  (基类: OkListOut[T], Generic[T])
```go
type ChargeLedgerOut struct {
	page int64 `json:"page"`
	page_size int64 `json:"page_size"`
	total int64 `json:"total"`
	total_pages int64 `json:"total_pages"`
	totals map[string]interface{} `json:"totals"`
	stages map[string]interface{} `json:"stages"`
	dir_counts map[string]interface{} `json:"dir_counts"`
}
```

## InventoryBalanceOut  (基类: OkListOut[T], Generic[T])
```go
type InventoryBalanceOut struct {
	summary map[string]interface{} `json:"summary"`
}
```

## CreditMonitorOut  (基类: OkListOut[T], Generic[T])
```go
type CreditMonitorOut struct {
	counts map[string]interface{} `json:"counts"`
	totals map[string]interface{} `json:"totals"`
}
```

## BunkerOrderRow  (基类: Row)
```go
type BunkerOrderRow struct {
	bunker_id interface{} `json:"bunker_id"`
	biz_order_no interface{} `json:"biz_order_no"`
	order_no interface{} `json:"order_no"`
	direction interface{} `json:"direction"`
	counterparty_name interface{} `json:"counterparty_name"`
	product interface{} `json:"product"`
	vessel_name interface{} `json:"vessel_name"`
	order_qty_kt interface{} `json:"order_qty_kt"`
	qty interface{} `json:"qty"`
	delivered_qty interface{} `json:"delivered_qty"`
	unit_price interface{} `json:"unit_price"`
	price interface{} `json:"price"`
	order_value_usd interface{} `json:"order_value_usd"`
	currency interface{} `json:"currency"`
	workflow_status interface{} `json:"workflow_status"`
	invoice_status interface{} `json:"invoice_status"`
	inv_state interface{} `json:"inv_state"`
	long_term_id interface{} `json:"long_term_id"`
}
```

## CargoOrderRow  (基类: Row)
```go
type CargoOrderRow struct {
	cargo_id interface{} `json:"cargo_id"`
	biz_order_no interface{} `json:"biz_order_no"`
	order_no interface{} `json:"order_no"`
	direction interface{} `json:"direction"`
	counterparty_name interface{} `json:"counterparty_name"`
	product interface{} `json:"product"`
	order_qty_kt interface{} `json:"order_qty_kt"`
	qty interface{} `json:"qty"`
	delivered_qty interface{} `json:"delivered_qty"`
	price interface{} `json:"price"`
	tolerance interface{} `json:"tolerance"`
	unit_price interface{} `json:"unit_price"`
	order_value_usd interface{} `json:"order_value_usd"`
	currency interface{} `json:"currency"`
	workflow_status interface{} `json:"workflow_status"`
	contract_status interface{} `json:"contract_status"`
	inv_state interface{} `json:"inv_state"`
}
```

## ExecutionRow  (基类: Row)
```go
type ExecutionRow struct {
	biz interface{} `json:"biz"`
	order_key interface{} `json:"order_key"`
	order_no interface{} `json:"order_no"`
	exec_state interface{} `json:"exec_state"`
	exec_pct interface{} `json:"exec_pct"`
	order_qty interface{} `json:"order_qty"`
	qty_uom interface{} `json:"qty_uom"`
	delivered_qty interface{} `json:"delivered_qty"`
	pending_qty interface{} `json:"pending_qty"`
	batch_count interface{} `json:"batch_count"`
	last_delivery_date interface{} `json:"last_delivery_date"`
	missing []interface{} `json:"missing"`
	order_value_usd interface{} `json:"order_value_usd"`
}
```

## LtAgreementRow  (基类: Row)
```go
type LtAgreementRow struct {
	id interface{} `json:"id"`
	agreement_no interface{} `json:"agreement_no"`
	offline_no interface{} `json:"offline_no"`
	transaction_label interface{} `json:"transaction_label"`
	direction interface{} `json:"direction"`
	counterparty_id interface{} `json:"counterparty_id"`
	product interface{} `json:"product"`
	qty_lo interface{} `json:"qty_lo"`
	qty_hi interface{} `json:"qty_hi"`
	qty_uom interface{} `json:"qty_uom"`
	start_date interface{} `json:"start_date"`
	end_date interface{} `json:"end_date"`
	status interface{} `json:"status"`
	biz_group interface{} `json:"biz_group"`
}
```

## CreditMonitorRow  (基类: Row)
```go
type CreditMonitorRow struct {
	counterparty_id interface{} `json:"counterparty_id"`
	biz_type interface{} `json:"biz_type"`
	credit_insurance_usd interface{} `json:"credit_insurance_usd"`
	internal_credit_usd interface{} `json:"internal_credit_usd"`
	pool_usd interface{} `json:"pool_usd"`
	available_usd interface{} `json:"available_usd"`
	exposure_usd interface{} `json:"exposure_usd"`
	occupied_usd interface{} `json:"occupied_usd"`
	used_invoiced_usd interface{} `json:"used_invoiced_usd"`
	used_uninvoiced_usd interface{} `json:"used_uninvoiced_usd"`
	received_usd interface{} `json:"received_usd"`
	valid_from interface{} `json:"valid_from"`
	valid_to interface{} `json:"valid_to"`
	risk interface{} `json:"risk"`
}
```

## ArItemRow  (基类: Row)
```go
type ArItemRow struct {
	id interface{} `json:"id"`
	fin_id interface{} `json:"fin_id"`
	party interface{} `json:"party"`
	invoice_no interface{} `json:"invoice_no"`
	invoice_date interface{} `json:"invoice_date"`
	due_date interface{} `json:"due_date"`
	amount interface{} `json:"amount"`
	received interface{} `json:"received"`
	outstanding interface{} `json:"outstanding"`
	overdue_days interface{} `json:"overdue_days"`
	bucket interface{} `json:"bucket"`
	order_biz interface{} `json:"order_biz"`
	order_id interface{} `json:"order_id"`
}
```

## ChargeLedgerRow  (基类: Row)
```go
type ChargeLedgerRow struct {
	id interface{} `json:"id"`
	charge_no interface{} `json:"charge_no"`
	direction interface{} `json:"direction"`
	is_goods interface{} `json:"is_goods"`
	item_name interface{} `json:"item_name"`
	counterparty_id interface{} `json:"counterparty_id"`
	amount interface{} `json:"amount"`
	currency interface{} `json:"currency"`
	amount_sgd interface{} `json:"amount_sgd"`
	invoice_no interface{} `json:"invoice_no"`
	invoice_status interface{} `json:"invoice_status"`
	settle_status_key interface{} `json:"settle_status_key"`
	order_kind interface{} `json:"order_kind"`
	order_id interface{} `json:"order_id"`
}
```

## InventoryBalanceRow  (基类: Row)
```go
type InventoryBalanceRow struct {
	location_id interface{} `json:"location_id"`
	code interface{} `json:"code"`
	name interface{} `json:"name"`
	product interface{} `json:"product"`
	book_mt interface{} `json:"book_mt"`
	available_mt interface{} `json:"available_mt"`
	pending_in_mt interface{} `json:"pending_in_mt"`
	capacity_mt interface{} `json:"capacity_mt"`
	negative interface{} `json:"negative"`
}
```

## PriceRow  (基类: Row)
```go
type PriceRow struct {
	date interface{} `json:"date"`
	is_actual interface{} `json:"is_actual"`
}
```

## CounterpartyRow  (基类: Row)
```go
type CounterpartyRow struct {
	id interface{} `json:"id"`
	name interface{} `json:"name"`
	short_name interface{} `json:"short_name"`
	country interface{} `json:"country"`
	is_active interface{} `json:"is_active"`
}
```
