// Package finance 财务域:转财务、开票管理、回款登记、应收账龄、台账、导出。
// 域划分与旧仓 routers/finance.py、routers/settlement.py、routers/charges.py 对应。
// 金额口径统一走 _fin_invoice_amount 的翻译(见 docs/pitfalls.md)。
package finance
