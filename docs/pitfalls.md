# 坑清单(翻译口径时逐条核对)

> 阶段 0 基线资产。来源:CLAUDE.md 关键口径 + 各会话记忆文件的实战教训。
> 新出现的坑往这里追加,别散在聊天记录里。标注 ✅=翻译时必验,⚠️=已知陷阱。

## 数据口径

- ✅ **金额统一走 `_fin_invoice_amount`**:sales=`final_amount_usd_excl_gst` 缺则
  provisional;sales 拿的是 excl_gst,purchase 拿的是含税前 `final_amount_usd` 缺则 provisional。
- ✅ **授信盘子 M = H + I − J(待开票)− K(已开票)+ L(已收)− 在手预占**;在手预占
  须与 J 去重。credit_limits 是权威表。
- ✅ **cargo 的 `_kt` 列存千吨,bunker 的存吨,含义相反**——踩过两次。
- ✅ **账龄只算发票日 ≥ `AR_AGING_GO_LIVE` 的行**,规避历史失真逾期。
- ✅ **开票**:BL QUANTITY 取 `order_deliveries.bdn_qty`、CQ DATE 取 `bdn_date`;
  只有「已定价+已交货」可开;GST 默认 Out Of Scope(0.00)。
- ✅ **`fin_invoices.invoice_no` 不唯一且真会重号**:按发票号反查必须带
  `fin_tab + fin_id` 限定,否则串到别的订单。
- ⚠️ **费用与货款分离**:货款行不进订单费用清单;预结算不写 execution_charges,
  终结算才写回并同步货款行。
- ⚠️ **CN/DN 项目行话术按票样**:FINAL PRICE/LESS 与 PRICING ADJUSTMENT TO,
  一条差额摊成两行;原票号两层口径相反(行上快照 vs 申请单现算),别统一。
- ⚠️ **OT 是区间**:交足线=录单量−OT,状态/开票闸/交货校验共用 `order_qty_band`。
- ⚠️ **异币种付款**:金额框是实付币种、留空=折算付清、尾差 0.01 抹平、fx_diff 只记尾差。
- ⚠️ **汇率 rate=1 单位 quote 折多少 USD**(与 FX 市场惯例反向);MAS 月度抓取存
  `usd_per_sgd=1/sgd`。

## 状态机 / 流程

- ✅ 两条业务线(bunker/cargo)**同一套状态机**;状态没有「已完成」。
- ✅ **软删除过滤**:绝大多数查询加 `is_delete=0`,但**故意不加**的地方——
  单号分配(`_next_bunker_id`/`_next_cargo_id`,防重号)、`import_*` 去重、
  `_archive_*`/`purge_order`。照抄,别无脑全加。
- ⚠️ 订单列表「入库/出库」列:采购看 in、销售看 out、只算 posted 流水;订单表不存,纯派生。
- ⚠️ 出入库关联订单的准入闸:方向 + 交货中/交货完成 + 大货合同审核。
- ⚠️ 费用明细阶段页签四档口径,判定只在 `charge_stage_match` 一处。
- ⚠️ 开票申请(FIN-002/004):可开票项目是投影、占用派生,**部分开票挡死**,
  不新建第四条开票写路径。

## 前端 / 接口约定

- ⚠️ DTO 宽松反序列化:旧系统 `response_model` 曾静默裁字段(extra allow 教训);
  新系统多传不漏、缺字段显式 400。
- ⚠️ 导出列序 = 列表列序;导出按钮用边框按钮(全站 UI 一致性约定)。
- ⚠️ 币种下拉只认 `list_currencies()`;收窄值域必须加历史值兜底,否则静默改数据。
- ⚠️ 权限守卫按权限位不按角色写死(多角色 = 主角色 + extra_roles 取并集)。

## 工程教训

- ⚠️ Python 模块级同名函数后定义覆盖前定义(count_flow_todo 遮蔽事故)——Go 包内
  同名函数编译不过,天然免疫,但**注意包间循环依赖**。
- ⚠️ 加横切过滤/改共享口径前先做零差异回归(`tools/regress_snapshot.py` 对拍)。
- ⚠️ SQLite→PG 行为差异重点:大小写(引号)、隐式类型、锁与并发;对拍在 PG 上进行。
- ⚠️ 源库数据质量(SQLite 从不开约束,2026-10-14 生产副本实测):bunker_orders/
  trade_legs/user_activity_log 有悬空 FK;REAL 列里塞文本脏数据(OCR 残字
  "+1.00 (OCR partial)"、"N/A"、空串,cargo_orders 8/credit_limits 7/
  fin_purchase_cargo 2/fin_sales_cargo 15/order_deliveries 1 处)。Go 重写时
  凡 join 主数据表要容忍孤儿行,凡 float 解析要容忍脏文本——旧 Python 代码
  对此是静默放任的。
