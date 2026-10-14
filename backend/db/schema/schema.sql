-- PG16 初始 schema:由生产 SQLite DDL 直译(结构照抄不改,阶段 0 基线资产)。
-- 人工复核点见文件尾注释;对拍在 PG 上进行。
SET client_min_messages = warning;

-- 来源: SQLite 表 access_requests
CREATE TABLE access_requests (
    telegram_user_id  BIGINT PRIMARY KEY,
    username          TEXT NOT NULL DEFAULT '',
    display_name      TEXT NOT NULL DEFAULT '',
    status            TEXT NOT NULL DEFAULT 'pending',   -- 'pending'
    created_at        TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
);

-- 来源: SQLite 表 ai_parse_logs
CREATE TABLE ai_parse_logs (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source       TEXT NOT NULL,                       -- 'tg' / 'web'
    kind         TEXT NOT NULL,                       -- 'recap' / 'bunker' / 'bdn'
    input_type   TEXT NOT NULL,                       -- 'file' / 'TEXT'
    file_name    TEXT DEFAULT '',                     -- 上传文件名（文本类为空）
    file_sha     TEXT DEFAULT '',                     -- 文件字节 SHA-256（去重/追溯）
    file_size    BIGINT DEFAULT 0,                   -- 文件字节数
    input_text   TEXT DEFAULT '',                     -- 粘贴文本 或 文件提取文字
    result_json  TEXT DEFAULT '',                     -- 解析结果 JSON（成功时）
    ok           BIGINT NOT NULL DEFAULT 1,          -- 1 成功 / 0 失败
    error        TEXT DEFAULT '',                     -- 失败原因
    created_by   TEXT DEFAULT '',                     -- 操作人（可空）
    created_at   TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
);

-- 来源: SQLite 表 ais_refresh_log
CREATE TABLE ais_refresh_log (
            id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            finished_at  TEXT,
            vessels      BIGINT,
            with_data    BIGINT,
            seconds      DOUBLE PRECISION,
            failed_names TEXT
        );

-- 来源: SQLite 表 ap_invoice_links
CREATE TABLE ap_invoice_links (
            id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            ap_invoice_id  BIGINT NOT NULL,
            pay_request_id BIGINT NOT NULL,
            amount         DOUBLE PRECISION NOT NULL DEFAULT 0,   -- 本张请款单占用这张票多少（含税口径）
            created_at     TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        );

-- 来源: SQLite 表 ap_invoices
CREATE TABLE ap_invoices (
            id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            inv_no          TEXT,                 -- 系统编号 AP-INV-YYYYMMDD-NNN
            invoice_no      TEXT NOT NULL,        -- 对方发票号
            counterparty_id BIGINT NOT NULL,     -- 对手方（供应商）
            invoice_date    TEXT,
            due_date        TEXT,                 -- 付款到期日
            currency        TEXT DEFAULT 'USD',
            amount_excl_tax DOUBLE PRECISION DEFAULT 0,
            tax_rate        DOUBLE PRECISION,
            tax_amount      DOUBLE PRECISION DEFAULT 0,
            amount_incl_tax DOUBLE PRECISION DEFAULT 0,       -- ★ 可用池按含税算（用户 2026-09-07 定）
            biz_type        TEXT,                 -- bunker / cargo / 空=不指定
            entity          TEXT,                 -- 我方账套
            attachment_id   BIGINT,              -- → charge_attachments.id
            parse_status    TEXT,                 -- success / failed / manual
            parse_json      TEXT,                 -- AI 原始识别结果，留痕用
            status          TEXT DEFAULT 'active',-- active / voided
            notes           TEXT,
            created_by      TEXT,
            created_at      TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            updated_by      TEXT,
            updated_at      TEXT,
            voided_by       TEXT,
            voided_at       TEXT,
            void_reason     TEXT
        );

-- 来源: SQLite 表 app_settings
CREATE TABLE app_settings (
            key        TEXT PRIMARY KEY,
            value      TEXT,
            updated_at TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        );

-- 来源: SQLite 表 bdn_parse_cache
CREATE TABLE bdn_parse_cache (
    sha256      TEXT PRIMARY KEY,                      -- PDF 原始字节 SHA-256
    result_json TEXT NOT NULL,                         -- parse_bdn 返回的 JSON
    filename    TEXT,                                  -- 最近一次上传文件名（仅参考）
    size        BIGINT,                               -- 字节数（仅参考）
    hit_count   BIGINT NOT NULL DEFAULT 0,            -- 命中次数
    created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
);

-- 来源: SQLite 表 bunker_amendments
CREATE TABLE bunker_amendments (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            bunker_id   TEXT NOT NULL,
            patch_json  TEXT NOT NULL,
            before_json TEXT,
            reason      TEXT,
            applicant   TEXT,
            status      TEXT DEFAULT 'pending',
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            applied_at  TEXT
        );

-- 来源: SQLite 表 bunker_grades
CREATE TABLE bunker_grades (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code              TEXT UNIQUE NOT NULL,
    name              TEXT NOT NULL,
    sulphur_pct_max   DOUBLE PRECISION,
    viscosity_max_cst DOUBLE PRECISION,
    iso_spec          TEXT,
    notes             TEXT
, name_zh TEXT, aliases TEXT, category TEXT, default_pricing_basis TEXT, risk_instrument TEXT, biz_lines TEXT NOT NULL DEFAULT 'both', density_max DOUBLE PRECISION, flash_point_min DOUBLE PRECISION, is_active BIGINT NOT NULL DEFAULT 1, created_at TEXT, created_by TEXT, updated_at TEXT, updated_by TEXT);

-- 来源: SQLite 表 bunker_orders
CREATE TABLE bunker_orders (
    id                          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bunker_id                   TEXT UNIQUE NOT NULL,
    finance_id                  TEXT,
    created_date                TEXT NOT NULL DEFAULT (DATE('now')),
    direction                   TEXT NOT NULL,
    is_back_to_back             BIGINT NOT NULL DEFAULT 0,

    grade_id                    BIGINT NOT NULL REFERENCES bunker_grades(id),
    product                     TEXT,
    sulphur_pct_max             DOUBLE PRECISION,

    counterparty_id             BIGINT NOT NULL REFERENCES counterparties(id),
    physical_supplier_id        BIGINT REFERENCES counterparties(id),

    vessel_id                   BIGINT REFERENCES vessels(id),
    vessel_name                 TEXT,

    port_id                     BIGINT REFERENCES ports(id),
    port_desc                   TEXT,
    anchorage                   TEXT,

    trade_term                  TEXT,
    delivery_mode               TEXT CHECK (delivery_mode IN ('barge','pipeline','truck','ship-to-ship')),

    order_qty_kt                DOUBLE PRECISION,
    delivered_qty_kt            DOUBLE PRECISION,

    received_date               TEXT,
    sales_person                TEXT,
    requested_delivery_date     TEXT,
    actual_delivery_month       TEXT,
    actual_delivery_date        TEXT,

    requested_delivery_month    TEXT,
    etb                         TEXT,
    etd                         TEXT,
    delivery_started_at         TEXT,
    delivery_ended_at           TEXT,

    pricing_method              TEXT,
    pricing_method_desc         TEXT,
    pricing_basis               TEXT,
    premium                     DOUBLE PRECISION,
    basic_price                 DOUBLE PRECISION,
    final_price                 DOUBLE PRECISION,

    pricing_month               TEXT,
    pricing_from                TEXT,
    pricing_to                  TEXT,

    pricing_progress            DOUBLE PRECISION,
    inventory_desc              TEXT,
    market_price                DOUBLE PRECISION,
    mtm_price_diff              DOUBLE PRECISION,
    mtm_amount                  DOUBLE PRECISION,

    barging_fee                 DOUBLE PRECISION,
    other_charges               DOUBLE PRECISION,

    bdn_no                      TEXT,
    density_15c                 DOUBLE PRECISION,
    sulphur_pct_actual          DOUBLE PRECISION,
    sample_no                   TEXT,

    payment_terms               TEXT,
    currency                    TEXT DEFAULT 'USD',

    status                      TEXT DEFAULT 'draft'
                                CHECK (status IN ('draft','signed','nominated','loading','delivered','priced','invoiced','closed','cancelled')),
    confirmation_status         TEXT NOT NULL DEFAULT 'draft',
    confirmed_at                TEXT,
    notes                       TEXT,
    created_at                  TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TEXT DEFAULT CURRENT_TIMESTAMP
, grade TEXT, pricing_n_days BIGINT, pricing_fixed_date TEXT, laycan_from TEXT, laycan_to TEXT, imo TEXT, created_by TEXT, order_no TEXT, order_qty_min DOUBLE PRECISION, order_qty_max DOUBLE PRECISION, long_term_id BIGINT, bdn_qty DOUBLE PRECISION, actual_delivery_port TEXT, actual_delivery_location TEXT, delivery_notes TEXT, biz_order_no TEXT, manual_invoice_no TEXT, invoice_apply_status TEXT, invoice_applied_by TEXT, invoice_applied_at TEXT, is_delete BIGINT NOT NULL DEFAULT 0, deleted_by TEXT, deleted_at TEXT, delete_reason TEXT, location_id BIGINT, supply_source TEXT, not_deal_reason TEXT, lc_amount DOUBLE PRECISION, governing_law TEXT, dispute_resolution TEXT, pricing_remark TEXT, deal_remark TEXT, has_fx_exposure TEXT, trader TEXT, trade_entity TEXT, qty_tol_sign TEXT, qty_tol_value DOUBLE PRECISION, qty_tol_unit TEXT, pricing_product TEXT, pricing_date TEXT, pricing_quote_kind TEXT, pricing_uom TEXT, pricing_event TEXT, lc_no TEXT, delivery_closed BIGINT DEFAULT 0, mtm_enabled BIGINT, mtm_formula_type TEXT, mtm_basis TEXT, mtm_period_term TEXT, mtm_premium DOUBLE PRECISION, mtm_currency TEXT, mtm_uom TEXT, mtm_pricing_from TEXT, mtm_pricing_to TEXT, mtm_pricing_month TEXT, mtm_formula_desc TEXT, qty_uom TEXT, qty_density_15c DOUBLE PRECISION);

-- 来源: SQLite 表 bunker_price_rebase
CREATE TABLE bunker_price_rebase (
            id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            bunker_id     TEXT NOT NULL,
            basic_before  DOUBLE PRECISION,
            premium_before DOUBLE PRECISION,
            final_before  DOUBLE PRECISION,
            mops_col      TEXT,
            mops_date     TEXT,      -- 实际取价日（非交易日会早于订单日）
            order_date    TEXT,      -- 订单用的日期（接单日/录单日）
            basic_after   DOUBLE PRECISION,
            premium_after DOUBLE PRECISION,
            rebased_at    TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        );

-- 来源: SQLite 表 bunker_purchase_links
CREATE TABLE bunker_purchase_links (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sell_bunker_id TEXT NOT NULL REFERENCES "_bunker_orders_pre_fid"(bunker_id),
    buy_bunker_id  TEXT NOT NULL REFERENCES "_bunker_orders_pre_fid"(bunker_id),
    used_qty_kt    DOUBLE PRECISION NOT NULL,
    created_at     TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 来源: SQLite 表 cargo_amendments
CREATE TABLE cargo_amendments (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            cargo_id    TEXT NOT NULL,
            patch_json  TEXT NOT NULL,      -- 要改成什么（只存改动的字段）
            before_json TEXT,               -- 改之前长什么样，供审批人对照
            reason      TEXT,
            applicant   TEXT,
            status      TEXT DEFAULT 'pending',   -- pending / applied / returned
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            applied_at  TEXT
        );

-- 来源: SQLite 表 cargo_orders
CREATE TABLE cargo_orders (
    id                          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cargo_id                    TEXT UNIQUE NOT NULL,
    finance_id                  TEXT,
    created_date                TEXT NOT NULL DEFAULT (DATE('now')),
    direction                   TEXT NOT NULL,
    is_back_to_back             BIGINT NOT NULL DEFAULT 0,

    commodity_id                BIGINT REFERENCES commodities(id),
    product                     TEXT,
    grade                       TEXT,

    counterparty_id             BIGINT NOT NULL REFERENCES counterparties(id),

    trade_term                  TEXT,

    sales_qty_kt                DOUBLE PRECISION,
    order_qty_min               DOUBLE PRECISION,
    order_qty_max               DOUBLE PRECISION,
    tolerance                   TEXT,
    delivered_qty_kt            DOUBLE PRECISION,

    cargo_phy_port_desc         TEXT,
    cargo_phy_port_id           BIGINT REFERENCES ports(id),
    port_details                TEXT,

    requested_delivery_month    TEXT,
    laycan_from                 TEXT,
    laycan_to                   TEXT,
    actual_delivery_month       TEXT,
    actual_delivery_from        TEXT,
    actual_delivery_to          TEXT,

    receiving_vessel            TEXT,

    pricing_method              TEXT,
    pricing_method_desc         TEXT,
    pricing_basis               TEXT,
    premium                     DOUBLE PRECISION,
    basic_price                 DOUBLE PRECISION,
    final_price                 DOUBLE PRECISION,

    pricing_month               TEXT,
    pricing_from                TEXT,
    pricing_to                  TEXT,

    inventory_desc              TEXT,
    payment_terms               TEXT,
    currency                    TEXT DEFAULT 'USD',

    status                      TEXT DEFAULT 'draft'
                                CHECK (status IN ('draft','signed','nominated','loading','delivered','priced','invoiced','closed','cancelled')),
    notes                       TEXT,
    created_at                  TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TEXT DEFAULT CURRENT_TIMESTAMP
, confirmation_status TEXT NOT NULL DEFAULT 'draft', confirmed_at TEXT, cargo_alt_port_desc TEXT, created_by TEXT, order_no TEXT, biz_order_no TEXT, pricing_fixed_date TEXT, pricing_n_days BIGINT, pricing_progress DOUBLE PRECISION, barging_fee DOUBLE PRECISION, other_charges DOUBLE PRECISION, physical_supplier_id BIGINT REFERENCES counterparties(id), received_date TEXT, etb TEXT, etd TEXT, delivery_started_at TEXT, delivery_ended_at TEXT, manual_invoice_no TEXT, invoice_apply_status TEXT, invoice_applied_by TEXT, invoice_applied_at TEXT, is_delete BIGINT NOT NULL DEFAULT 0, deleted_by TEXT, deleted_at TEXT, delete_reason TEXT, trade_entity TEXT, lc_no TEXT, tax_class TEXT, qty_uom TEXT, pricing_product TEXT, markup_amount DOUBLE PRECISION, lt_agreement_id BIGINT, location_id BIGINT, supply_source TEXT, contract_status TEXT, contract_approved_by TEXT, contract_approved_at TEXT, deal_date TEXT, trade_type TEXT, business_group TEXT, business_type TEXT, trader TEXT, transaction_code TEXT, contract_type TEXT, book_code TEXT, offline_contract_no TEXT, plan_code TEXT, market_chance TEXT, deal_code TEXT, is_internal_deal BIGINT DEFAULT 0, strategy TEXT, broker TEXT, counterparty_code TEXT, customer_material_no TEXT, material_code TEXT, qty_mode TEXT, qty_tolerance_op TEXT, qty_tolerance_val DOUBLE PRECISION, qty_tolerance_unit TEXT, unit_conv_rate DOUBLE PRECISION, unit_conv_from TEXT, unit_conv_to TEXT, ref_contract_qty DOUBLE PRECISION, ref_contract_unit TEXT, splittable_qty DOUBLE PRECISION, splittable_unit TEXT, contract_closed TEXT, over_short_option TEXT, settle_qty_basis TEXT, load_qty_req TEXT, load_port TEXT, discharge_port TEXT, allowed_load_hours DOUBLE PRECISION, allowed_disch_hours DOUBLE PRECISION, price_precision BIGINT, mtm_price DOUBLE PRECISION, exposure_qty DOUBLE PRECISION, other_price_adj DOUBLE PRECISION, mtm_formula_type TEXT, mtm_basis TEXT, mtm_premium DOUBLE PRECISION, mtm_currency TEXT, mtm_uom TEXT, mtm_period_term TEXT, mtm_pricing_month TEXT, mtm_pricing_from TEXT, mtm_pricing_to TEXT, mtm_formula_desc TEXT, mtm_enabled BIGINT DEFAULT 0, credit_terms TEXT, offset_flag TEXT, fin_voucher_no TEXT, lc_amount DOUBLE PRECISION, lc_amount_unit TEXT, governing_law TEXT, dispute_resolution TEXT, pricing_remark TEXT, deal_remark TEXT, has_fx_exposure TEXT, pricing_quote_kind TEXT, pricing_uom TEXT, pricing_date TEXT, delivery_closed BIGINT DEFAULT 0);

-- 来源: SQLite 表 cargo_pricing_events
CREATE TABLE cargo_pricing_events (
            cargo_id     TEXT PRIMARY KEY,
            event_type   TEXT,
            est_date     TEXT,
            actual_date  TEXT,
            days_n       BIGINT,
            days_rel     TEXT,
            d_normal     TEXT,
            d_saturday   TEXT,
            d_sunday     TEXT,
            d_holiday    TEXT,
            price_from   TEXT,
            price_to     TEXT,
            updated_at   TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        );

-- 来源: SQLite 表 cash_receipts
CREATE TABLE cash_receipts (
            id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            receipt_no      TEXT NOT NULL UNIQUE,   -- CM+YYYYMMDD-NNN，按天自增
            receipt_type    TEXT NOT NULL,          -- goods/advance/refund/deposit/other
            counterparty_id BIGINT,                -- 付款方（客商档案），可空：散户/内部往来
            payer_name      TEXT,                   -- 付款方名称（AI 从水单识别出来的原文）
            received_date   TEXT NOT NULL,          -- 到账日期
            currency        TEXT DEFAULT 'USD',
            amount          DOUBLE PRECISION NOT NULL,          -- 原币金额，可负（退回/冲正）
            method          TEXT,                   -- 电汇 / 支票 / 信用证 …
            bank_account    TEXT,                   -- 收款账户（我方）
            bank_ref        TEXT,                   -- 银行流水号 / 回单号
            biz_type        TEXT,                   -- bunker / cargo / 空
            entity          TEXT,                   -- 我方账套
            order_id        TEXT,                   -- 关联订单，选填
            fin_receipt_id  BIGINT,                -- → fin_receipts.id，货款核销后回填
            attachment_id   BIGINT,                -- → charge_attachments.id（水单）
            parse_status    TEXT,                   -- success / failed / manual
            parse_json      TEXT,                   -- AI 原始识别结果，留痕
            status          TEXT DEFAULT 'active',  -- active / voided
            notes           TEXT,
            created_by      TEXT,
            created_at      TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            updated_by      TEXT,
            updated_at      TEXT,
            voided_by       TEXT,
            voided_at       TEXT,
            void_reason     TEXT
        , payer_bank_name TEXT, payer_bank_account TEXT, payer_bank_currency TEXT);

-- 来源: SQLite 表 charge_adjust_requests
CREATE TABLE charge_adjust_requests (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            order_kind  TEXT NOT NULL,
            order_id    TEXT NOT NULL,
            line_ids    TEXT NOT NULL,          -- JSON 数组
            line_count  BIGINT DEFAULT 0,
            reason      TEXT NOT NULL,
            applicant   TEXT NOT NULL,
            status      TEXT NOT NULL DEFAULT 'pending',  -- pending/approved/returned
            flow_id     BIGINT,
            decision_note TEXT,
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            decided_at  TEXT
        );

-- 来源: SQLite 表 charge_attachments
CREATE TABLE charge_attachments (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            charge_id   BIGINT NOT NULL,
            kind        TEXT NOT NULL,        -- receipt_slip 收款水单 / vendor_invoice 对方发票
            file_name   TEXT NOT NULL,
            stored_path TEXT NOT NULL,
            size_bytes  BIGINT,
            uploaded_by TEXT,
            uploaded_at TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        , pay_request_id BIGINT, ap_invoice_id BIGINT, cash_receipt_id BIGINT, invoice_request_id BIGINT);

-- 来源: SQLite 表 charge_auto_suppress
CREATE TABLE charge_auto_suppress (
            order_kind     TEXT NOT NULL,
            order_id       TEXT NOT NULL,
            charge_item_id BIGINT NOT NULL,
            suppressed_by  TEXT,
            suppressed_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            PRIMARY KEY (order_kind, order_id, charge_item_id)
        );

-- 来源: SQLite 表 charge_invoices
CREATE TABLE charge_invoices (
            id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            invoice_no      TEXT NOT NULL UNIQUE,
            counterparty_id BIGINT NOT NULL,
            invoice_date    TEXT,
            currency        TEXT DEFAULT 'USD',
            amount_excl_tax DOUBLE PRECISION DEFAULT 0,
            tax_amount      DOUBLE PRECISION DEFAULT 0,
            amount_incl_tax DOUBLE PRECISION DEFAULT 0,
            line_count      BIGINT DEFAULT 0,
            notes           TEXT,
            status          TEXT DEFAULT 'issued',   -- issued / voided
            created_by      TEXT,
            created_at      TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            voided_by       TEXT,
            voided_at       TEXT,
            void_reason     TEXT
        , due_date TEXT, paid_usd DOUBLE PRECISION DEFAULT 0);

-- 来源: SQLite 表 charge_items
CREATE TABLE charge_items (
            id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            code          TEXT NOT NULL UNIQUE,   -- 英文码，接口与导出用
            name          TEXT NOT NULL,          -- 中文名，页面显示
            name_en       TEXT,
            basis         TEXT NOT NULL DEFAULT 'per_shipment',
            default_price DOUBLE PRECISION,                   -- 默认单价，可留空
            currency      TEXT DEFAULT 'USD',
            biz_scope     TEXT DEFAULT 'both',    -- bunker / cargo / both
            billable      BIGINT DEFAULT 0,      -- 默认是否向客户收取（进结算）
            auto_add      BIGINT DEFAULT 0,      -- 新单是否默认带出这一项
            sort          BIGINT DEFAULT 0,
            is_active     BIGINT DEFAULT 1,
            notes         TEXT,
            created_by    TEXT,
            created_at    TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            updated_by    TEXT,
            updated_at    TEXT
        , tax_rate DOUBLE PRECISION DEFAULT 0, cost_type TEXT DEFAULT 'variable', tax_code TEXT, sys_code TEXT);

-- 来源: SQLite 表 charge_pay_requests
CREATE TABLE charge_pay_requests (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            line_ids    TEXT NOT NULL,          -- JSON 数组（同 charge_adjust_requests）
            line_count  BIGINT DEFAULT 0,
            amount      DOUBLE PRECISION DEFAULT 0,         -- 申请时的含税合计（快照，便于审批人一眼看金额）
            currency    TEXT DEFAULT 'USD',
            reason      TEXT,
            applicant   TEXT NOT NULL,
            status      TEXT NOT NULL DEFAULT 'pending',  -- pending/approved/returned
            flow_id     BIGINT,
            decision_note TEXT,
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            decided_at  TEXT
        , req_no TEXT, counterparty_id BIGINT, payee_name TEXT, bank_name TEXT, bank_account_no TEXT, bank_swift TEXT, bank_address TEXT, bank_contact TEXT, biz_type TEXT, invoice_no TEXT, invoice_currency TEXT, invoice_amount DOUBLE PRECISION, due_date TEXT, entity TEXT, apply_type TEXT, pay_no TEXT, paid_date TEXT, paid_amount DOUBLE PRECISION, paid_by TEXT, paid_at TEXT, invoice_date TEXT, bank_phone TEXT, refund_source TEXT, refund_refs TEXT, refund_cn_no TEXT);

-- 来源: SQLite 表 charge_payments
CREATE TABLE charge_payments (
            id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            pay_no         TEXT,
            pay_request_id BIGINT,            -- 不走申请直接登记的可空
            charge_id      BIGINT NOT NULL,
            paid_date      TEXT,
            due_currency   TEXT,               -- 应付：费用行币种
            due_amount     DOUBLE PRECISION,               -- 应付：该行本次应付额
            pay_currency   TEXT,               -- 实付：银行实际出账币种
            pay_amount     DOUBLE PRECISION,               -- 实付：银行实际出账金额
            fx_rate        DOUBLE PRECISION,               -- 1 单位实付币 = ? 单位应付币
            fx_rate_date   TEXT,
            fx_source      TEXT,               -- mas | manual
            settled_amount DOUBLE PRECISION,               -- 折回应付币种、写进 execution_charges 的那个数
            fx_diff        DOUBLE PRECISION,               -- 折算尾差 = settled_amount − 折算原值
            bank_ref       TEXT,
            attachment_id  BIGINT,
            notes          TEXT,
            created_by     TEXT,
            created_at     TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            voided_by      TEXT, voided_at TEXT, void_reason TEXT
        );

-- 来源: SQLite 表 charge_settlement_funds
CREATE TABLE charge_settlement_funds (
            id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            settlement_id BIGINT NOT NULL,
            source_type   TEXT NOT NULL,                 -- receipt | credit
            receipt_id    BIGINT,                       -- cash_receipts.id
            currency      TEXT NOT NULL,                 -- 资金侧币种
            amount        DOUBLE PRECISION NOT NULL,                 -- 动用金额（资金币种）
            fx_rate       DOUBLE PRECISION,                          -- 资金币种 → 费用币种
            amount_conv   DOUBLE PRECISION NOT NULL                  -- 折成费用币种后的金额
        );

-- 来源: SQLite 表 charge_settlement_lines
CREATE TABLE charge_settlement_lines (
            id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            settlement_id BIGINT NOT NULL,
            charge_id     BIGINT NOT NULL,
            amount        DOUBLE PRECISION NOT NULL,                 -- 本次核销金额（费用币种）
            UNIQUE(settlement_id, charge_id)
        );

-- 来源: SQLite 表 charge_settlements
CREATE TABLE charge_settlements (
            id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            settle_no       TEXT NOT NULL UNIQUE,        -- HX+YYYYMMDD-NNN
            direction       TEXT NOT NULL DEFAULT 'ar',  -- 目前只做应收
            counterparty_id BIGINT,
            party_name      TEXT,
            settle_date     TEXT NOT NULL,
            currency        TEXT NOT NULL,               -- 费用侧币种（一单一种）
            total_amount    DOUBLE PRECISION NOT NULL DEFAULT 0,     -- 本次核销合计（费用币种）
            notes           TEXT,
            status          TEXT NOT NULL DEFAULT 'active',
            created_by      TEXT,
            created_at      TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            voided_by       TEXT, voided_at TEXT, void_reason TEXT
        );

-- 来源: SQLite 表 commodities
CREATE TABLE commodities (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product     TEXT NOT NULL,
    grade       TEXT,
    notes       TEXT,
    UNIQUE (product, grade)
);

-- 来源: SQLite 表 companies
CREATE TABLE companies (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            parent_id   BIGINT,
            name_zh     TEXT NOT NULL,
            name_en     TEXT NOT NULL,
            code        TEXT NOT NULL DEFAULT '',
            short_name  TEXT NOT NULL DEFAULT '',
            currency    TEXT NOT NULL DEFAULT '',
            sort        BIGINT NOT NULL DEFAULT 0,
            is_active   BIGINT NOT NULL DEFAULT 1,
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            created_by  TEXT
        , address_en TEXT, gst_reg_no TEXT, company_reg_no TEXT, logo_path TEXT, invoice_footer TEXT, gst_note TEXT);

-- 来源: SQLite 表 company_bank_accounts
CREATE TABLE company_bank_accounts (
            id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            company_id   BIGINT NOT NULL,
            currency     TEXT,
            account_name TEXT,
            bank_name    TEXT,
            bank_address TEXT,
            account_no   TEXT,
            swift        TEXT,
            is_default   BIGINT DEFAULT 0,
            is_active    BIGINT DEFAULT 1,
            sort         BIGINT DEFAULT 0,
            notes        TEXT,
            created_at   TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            created_by   TEXT,
            updated_at   TEXT,
            updated_by   TEXT
        );

-- 来源: SQLite 表 counterparties
CREATE TABLE counterparties (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code        TEXT UNIQUE NOT NULL,
    name        TEXT NOT NULL,
    short_name  TEXT,
    country     TEXT,
    notes       TEXT,
    created_at  TEXT DEFAULT CURRENT_TIMESTAMP
, credit_limit DOUBLE PRECISION NOT NULL DEFAULT 0, default_payment_terms TEXT, default_tax_rate DOUBLE PRECISION, created_by TEXT, infotech_contact_id BIGINT, infotech_contact_env TEXT, address TEXT, tax_reg_no TEXT, acra_uen TEXT, acra_status TEXT, acra_entity_type TEXT, acra_verified_at TEXT, sanctions_checked_at TEXT, sanctions_hit_count BIGINT, acra_ssic TEXT);

-- 来源: SQLite 表 counterparty_agents
CREATE TABLE counterparty_agents (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    counterparty_id BIGINT NOT NULL,
    seq             BIGINT NOT NULL DEFAULT 0,
    name            TEXT NOT NULL,
    contact         TEXT DEFAULT '',
    phone           TEXT DEFAULT ''
);

-- 来源: SQLite 表 counterparty_banks
CREATE TABLE counterparty_banks (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    counterparty_id BIGINT NOT NULL,
    seq             BIGINT NOT NULL DEFAULT 0,
    bank_name       TEXT NOT NULL,
    account_no      TEXT DEFAULT '',
    swift           TEXT DEFAULT '',
    currency        TEXT DEFAULT ''
);

-- 来源: SQLite 表 country_regions
CREATE TABLE country_regions (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code    TEXT NOT NULL,          -- ISO 3166-1 alpha-2，存大写
    country_name_cn TEXT,
    country_name_en TEXT,
    region_name_cn  TEXT,
    region_name_en  TEXT,
    region_code     TEXT,
    is_active       BIGINT DEFAULT 1,
    created_at      TEXT,
    created_by      TEXT,
    updated_at      TEXT,
    updated_by      TEXT
);

-- 来源: SQLite 表 cp_attachments
CREATE TABLE cp_attachments (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    draft_token     TEXT,
    req_id          BIGINT,
    counterparty_id BIGINT,
    original_name   TEXT NOT NULL,
    stored_path     TEXT NOT NULL,
    mime_type       TEXT DEFAULT '',
    file_size       BIGINT NOT NULL DEFAULT 0,
    uploaded_by     TEXT DEFAULT '',
    created_at      TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
);

-- 来源: SQLite 表 cp_change_approvers
CREATE TABLE cp_change_approvers (
            user_id     BIGINT NOT NULL,
            stage_code  TEXT NOT NULL,
            added_by    TEXT,
            added_at    TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            PRIMARY KEY (user_id, stage_code)
        );

-- 来源: SQLite 表 cp_change_requests
CREATE TABLE cp_change_requests (
            id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            action           TEXT NOT NULL CHECK (action IN ('create','update')),
            counterparty_id  BIGINT,                 -- update 必填；create 批准后回填新建 id
            counterparty_name TEXT NOT NULL,          -- 申请中的名称，列表展示用
            payload_json     TEXT NOT NULL,           -- 申请写入的字段值
            before_json      TEXT,                    -- 修改前的值，供审批人对比（create 为空）
            reason           TEXT,
            status           TEXT NOT NULL DEFAULT 'pending',   -- pending/approved/rejected
            current_stage    TEXT NOT NULL DEFAULT 'handler',
            applicant        TEXT,
            approver         TEXT,
            decision_note    TEXT,
            created_at       TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            decided_at       TEXT
        );

-- 来源: SQLite 表 cp_change_steps
CREATE TABLE cp_change_steps (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            req_id      BIGINT NOT NULL,
            seq         BIGINT NOT NULL,
            stage_code  TEXT NOT NULL,
            stage_name  TEXT NOT NULL,
            status      TEXT NOT NULL DEFAULT 'pending',  -- pending/approved/rejected/skipped
            decided_by  TEXT,
            decided_at  TEXT,
            note        TEXT
        );

-- 来源: SQLite 表 credit_appl_steps
CREATE TABLE credit_appl_steps (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            appl_id     BIGINT NOT NULL,
            seq         BIGINT NOT NULL,          -- 1/2/3
            stage_code  TEXT NOT NULL,             -- handler/deputy/gm
            stage_name  TEXT NOT NULL,
            status      TEXT NOT NULL DEFAULT 'pending', -- pending/approved/rejected/skipped
            decided_by  TEXT,
            decided_at  TEXT,
            note        TEXT
        );

-- 来源: SQLite 表 credit_applications
CREATE TABLE credit_applications (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_no            TEXT NOT NULL,                 -- 订单号(SO/PO)，1:1 关联订单
    biz_type            TEXT NOT NULL DEFAULT 'bunker',
    counterparty_id     BIGINT,
    counterparty_name   TEXT,
    pool_snapshot       DOUBLE PRECISION,                          -- 申请时盘子 H+I
    used_snapshot       DOUBLE PRECISION,                          -- 申请时已用占额
    order_amount        DOUBLE PRECISION,                          -- 本单预占
    over_amount         DOUBLE PRECISION,                          -- 超额缺口
    requested_increase  DOUBLE PRECISION,                          -- 申请提额(默认=超额)
    approved_increase   DOUBLE PRECISION,                          -- 批复提额
    reason              TEXT,                          -- 录单人说明
    decision_note       TEXT,                          -- 审批意见
    status              TEXT NOT NULL DEFAULT 'pending', -- pending/approved/rejected/cancelled
    applicant           TEXT,
    approver            TEXT,
    created_at          TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
    decided_at          TEXT
, current_stage TEXT DEFAULT 'handler');

-- 来源: SQLite 表 credit_approvers
CREATE TABLE credit_approvers (
    user_id   BIGINT PRIMARY KEY,
    added_by  TEXT,
    added_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
, stage_code TEXT);

-- 来源: SQLite 表 credit_change_requests
CREATE TABLE credit_change_requests (
            id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            credit_id        BIGINT NOT NULL,        -- credit_limits.id
            counterparty_name TEXT,                   -- 冗余，列表直接显示
            biz_type         TEXT,                    -- bunker / cargo
            payload_json     TEXT NOT NULL,           -- 申请后的字段值
            before_json      TEXT,                    -- 申请前快照
            reason           TEXT,
            status           TEXT NOT NULL DEFAULT 'pending',   -- pending/approved/rejected
            applicant        TEXT,
            decision_note    TEXT,
            created_at       TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            decided_at       TEXT
        );

-- 来源: SQLite 表 credit_import_batches
CREATE TABLE credit_import_batches (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    file_name       TEXT,
    total_rows      BIGINT,
    new_rows        BIGINT,
    changed_rows    BIGINT,
    unchanged_rows  BIGINT,
    missing_bunker  BIGINT,        -- 库里有、本次文件没出现（bunker 段），维持原值不动
    missing_cargo   BIGINT,        -- 同上（cargo 段）
    imported_by     TEXT,
    imported_at     TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
);

-- 来源: SQLite 表 credit_import_diffs
CREATE TABLE credit_import_diffs (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id            BIGINT NOT NULL REFERENCES credit_import_batches(id),
    credit_id           BIGINT,     -- 落库后回填 credit_limits.id
    biz_type            TEXT NOT NULL,
    buyer_name_en       TEXT NOT NULL,
    kind                TEXT NOT NULL,   -- new / changed / unchanged
    before_json         TEXT,            -- 导入前整行快照（kind=new 时为空）
    after_json          TEXT NOT NULL,   -- 本次解析出的值
    changed_fields_json TEXT             -- [{field,label,before,after}]，C/K 排最前
);

-- 来源: SQLite 表 credit_limits
CREATE TABLE credit_limits (
    id                       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    biz_type                 TEXT NOT NULL CHECK (biz_type IN ('bunker','cargo')),  -- Excel 分段
    buyer_name_en            TEXT NOT NULL,   -- A 买方英文名称
    country                  TEXT,            -- B 买方国家/地区
    approved_amount_usd      DOUBLE PRECISION,            -- C 批复金额（美元）
    limit_status             TEXT,            -- D 限额状态（有效/无效）
    effective_date           TEXT,            -- E 生效日期
    approval_date            TEXT,            -- F 批复日期
    applied_amount_usd       DOUBLE PRECISION,            -- G 申请金额（美元）
    credit_insurance_usd     DOUBLE PRECISION,            -- H 现有信保额度（美元）
    internal_credit_usd      DOUBLE PRECISION,            -- I 内部授信（美元）
    used_uninvoiced_usd      DOUBLE PRECISION,            -- J 已使用额度（美元）未开发票
    used_invoiced_usd        DOUBLE PRECISION,            -- K 已使用额度（美元）已开发票
    released_usd             DOUBLE PRECISION,            -- L 额度释放（收款）（美元）
    available_usd            DOUBLE PRECISION,            -- M 可使用额度（系统维护值 = H+I-J-K+L）
    available_usd_imported   DOUBLE PRECISION,            -- M 导入原值快照（对账用）
    remark1                  TEXT,            -- N REMARK（短标签）
    remark2                  TEXT,            -- O 第二 REMARK（补充说明）
    counterparty_id          BIGINT REFERENCES counterparties(id),  -- 软关联，可空
    source_row               BIGINT,         -- 源文件行号（审计）
    imported_at              TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
    updated_at               TEXT,
    updated_by               TEXT, mode TEXT DEFAULT 'credit', valid_from TEXT, valid_to TEXT,
    UNIQUE (biz_type, buyer_name_en)
);

-- 来源: SQLite 表 currencies
CREATE TABLE currencies (
            code       TEXT PRIMARY KEY,
            symbol     TEXT,
            country    TEXT,
            name       TEXT,
            is_active  BIGINT DEFAULT 1,
            sort       BIGINT DEFAULT 0,
            created_at TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            created_by TEXT,
            updated_at TEXT,
            updated_by TEXT
        );

-- 来源: SQLite 表 daily_positions
CREATE TABLE daily_positions (
                id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                pos_date   TEXT NOT NULL,
                biz        TEXT NOT NULL DEFAULT 'bunker',
                product    TEXT NOT NULL,
                note       TEXT,
                created_by TEXT,
                created_at TEXT,
                updated_by TEXT,
                updated_at TEXT, qty_t DOUBLE PRECISION NOT NULL DEFAULT 0,
                UNIQUE(pos_date, biz, product)
            );

-- 来源: SQLite 表 deleted_orders
CREATE TABLE deleted_orders (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_kind  TEXT NOT NULL CHECK (order_kind IN ('bunker','cargo')),
    order_id    TEXT NOT NULL,
    biz_no      TEXT,                                  -- 冗余业务单号，便于检索
    created_by  TEXT,                                  -- 原订单创建人，便于按人核对
    snapshot    TEXT NOT NULL,                         -- JSON：{order, attachments, deliveries}
    deleted_by  TEXT DEFAULT '',
    reason      TEXT DEFAULT '',
    deleted_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
);

-- 来源: SQLite 表 deliveries_voided
CREATE TABLE deliveries_voided (
            id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            delivery_id         BIGINT,          -- 原 order_deliveries.id
            order_kind          TEXT,
            order_id            TEXT,
            batch_no            TEXT,             -- 原 delivery_no
            row_json            TEXT NOT NULL,    -- 整行快照
            order_status_before TEXT,             -- 作废前订单状态，还原用
            reason              TEXT,
            voided_by           TEXT,
            voided_at           TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        );

-- 来源: SQLite 表 departments
CREATE TABLE departments (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        TEXT NOT NULL,
    parent_id   BIGINT,                          -- 上级部门（NULL=顶层）
    company_id  BIGINT,                          -- 预留：多公司实体
    sort        BIGINT NOT NULL DEFAULT 0,
    is_active   BIGINT NOT NULL DEFAULT 1,
    created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
    created_by  TEXT
, name_en TEXT NOT NULL DEFAULT '', description TEXT NOT NULL DEFAULT '');

-- 来源: SQLite 表 equasis_query_log
CREATE TABLE equasis_query_log (
            id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            query        TEXT,
            imo          TEXT,
            ok           BIGINT,
            msg          TEXT,
            queried_by   TEXT,
            queried_at   TEXT
        );

-- 来源: SQLite 表 exchange_rates
CREATE TABLE exchange_rates (  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  base TEXT NOT NULL DEFAULT 'USD',  quote TEXT NOT NULL DEFAULT 'SGD',  usd_per_sgd DOUBLE PRECISION NOT NULL,  effective_date TEXT NOT NULL,  note TEXT,  updated_at TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),  updated_by TEXT, rate DOUBLE PRECISION,  UNIQUE(base, quote, effective_date));

-- 来源: SQLite 表 execution_charges
CREATE TABLE execution_charges (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            order_kind  TEXT,          -- bunker / cargo
            order_id    TEXT,
            seq         BIGINT DEFAULT 0,
            charge_type TEXT NOT NULL,          -- 费用项
            amount      DOUBLE PRECISION,
            currency    TEXT DEFAULT 'USD',
            payee       TEXT,                   -- 收款方 / 供应商
            charge_date TEXT,
            notes       TEXT,
            created_by  TEXT,
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        , billable BIGINT DEFAULT 0, charge_item_id BIGINT, qty DOUBLE PRECISION, unit_price DOUBLE PRECISION, uom TEXT, stage TEXT, tax_rate DOUBLE PRECISION, cost_type TEXT, counterparty_id BIGINT, charge_invoice_id BIGINT, direction TEXT, confirm_status TEXT DEFAULT 'draft', confirmed_by TEXT, confirmed_at TEXT, settled_amount DOUBLE PRECISION DEFAULT 0, settled_by TEXT, settled_at TEXT, settled_date TEXT, delivery_id BIGINT, charge_no TEXT, adjust_flow_id BIGINT, invoice_apply_status TEXT, invoice_applied_by TEXT, invoice_applied_at TEXT, vendor_invoice_no TEXT, vendor_invoice_date TEXT, vendor_invoice_title TEXT, vendor_invoice_amount DOUBLE PRECISION, receipted_by TEXT, receipted_at TEXT, pay_flow_id BIGINT, pay_request_id BIGINT, fin_id BIGINT, price_type TEXT, diff_of_charge_id BIGINT, adjust_doc_type TEXT, adjust_of_invoice_no TEXT, tax_code TEXT, source TEXT);

-- 来源: SQLite 表 export_tokens
CREATE TABLE export_tokens (
    token             TEXT PRIMARY KEY,
    kind              TEXT NOT NULL CHECK (kind IN ('cargo','bunker')),
    telegram_user_id  BIGINT,
    created_at        TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at        TEXT NOT NULL,
    used_at           TEXT
);

-- 来源: SQLite 表 exposure_alerts
CREATE TABLE exposure_alerts (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trade_id      TEXT,
    biz_type      TEXT NOT NULL,                    -- 'bunker' | 'cargo'
    order_id      TEXT NOT NULL,
    instrument    TEXT,                             -- 风险标的（计价基准归一）
    direction     TEXT,                             -- buy | sell
    order_qty_kt  DOUBLE PRECISION,                             -- 本单量(kt)
    net_kt        DOUBLE PRECISION,                             -- 成交后该标的净敞口(kt)
    position      TEXT,                             -- Long | Short | Flat
    threshold_kt  DOUBLE PRECISION,
    message       TEXT,
    status        TEXT NOT NULL DEFAULT 'pending',  -- pending | acknowledged
    created_at    TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
    acked_by      TEXT,
    acked_at      TEXT
, category TEXT NOT NULL DEFAULT 'exposure', message_en TEXT);

-- 来源: SQLite 表 fin_invoices
CREATE TABLE fin_invoices (  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  order_kind TEXT NOT NULL,  order_id TEXT NOT NULL,  fin_tab TEXT NOT NULL,  fin_id BIGINT,  invoice_no TEXT,  invoice_date TEXT,  source TEXT NOT NULL DEFAULT 'manual',  currency TEXT DEFAULT 'USD',  amount_excl_tax DOUBLE PRECISION,  amount_incl_tax DOUBLE PRECISION,  tax_rate DOUBLE PRECISION,  tax_amount DOUBLE PRECISION,  attachment_id BIGINT,  parse_status TEXT,  parse_json TEXT,  order_status_before TEXT,  issued_by TEXT,  created_at TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),  voided_at TEXT,  voided_by TEXT,  void_reason TEXT, it_trans_id BIGINT, it_invoice_no TEXT, it_status TEXT, it_pushed_at TEXT, it_error TEXT, it_response TEXT);

-- 来源: SQLite 表 fin_purchase_cargo
CREATE TABLE fin_purchase_cargo (
    id                                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    no_raw                            TEXT,   -- 原始 NO（不可靠，仅存档）
    supplier_name                     TEXT,   -- SUPPLIER NAME
    contract_ref                      TEXT,   -- CONTRACT REF
    product                           TEXT,   -- PRODUCT
    contract_date                     TEXT,   -- CONTRACT DATE
    purchase_qty_mt                   DOUBLE PRECISION,   -- PURCHASE QUANTITY （MTS/+-)
    incoterm                          TEXT,   -- INCOTERM
    loading_date                      TEXT,   -- LOADING DATE
    vessel                            TEXT,   -- VESSEL
    loading_qty_mt_provisional        DOUBLE PRECISION,   -- LOADING QUANTITY （MT)- PROVISIONAL
    loading_qty_mt_final              DOUBLE PRECISION,   -- LOADING QUANTITY （MT)- FINAL
    load_port                         TEXT,   -- LOAD PORT
    discharge_port                    TEXT,   -- DISCHARGE PORT
    purchase_invoice_number           TEXT,   -- PURCHASE INVOICE NUMBER
    purchase_invoice_date             TEXT,   -- PURCHASE INVOICE DATE
    payment_term                      TEXT,   -- PAYMENT TERM
    payment_due_date                  TEXT,   -- PAYMENT DUE DATE
    pricing_term                      TEXT,   -- PRICING TERM
    pricing_provisional_usd           DOUBLE PRECISION,   -- PRICING (PROVISIONAL) (USD)
    provisional_amount_usd            DOUBLE PRECISION,   -- PROVISIONAL AMOUNT (USD)
    provisional_amount_cny            DOUBLE PRECISION,   -- PROVISIONAL AMOUNT (CNY)
    pricing_final_usd                 DOUBLE PRECISION,   -- PRICING (FINAL) (USD)
    final_amount_usd                  DOUBLE PRECISION,   -- FINAL AMOUNT (USD)
    final_amount_cny                  DOUBLE PRECISION,   -- FINAL AMOUNT CNY)
    final_amount_usd_net_after_prov   DOUBLE PRECISION,   -- FINAL AMOUNT (USD) （NET AFTER DEDUCT PROV)
    final_amount_cny_net_after_prov   DOUBLE PRECISION,   -- FINAL AMOUNT (CNY) （NET AFTER DEDUCT PROV)
    -- 元数据 / 预留
    source_file                       TEXT,
    source_sheet                      TEXT,
    source_row                        BIGINT,
    raw_json                          TEXT,
    counterparty_id                   BIGINT REFERENCES counterparties(id),
    order_id                          TEXT,
    finance_id                        TEXT,
    imported_at                       TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
, source TEXT DEFAULT 'excel', status TEXT, order_biz TEXT, transferred_at TEXT, transferred_by TEXT, received_amount_usd DOUBLE PRECISION DEFAULT 0, last_received_date TEXT, payment_status TEXT, bl_date TEXT, voided_at TEXT, voided_by TEXT, void_reason TEXT, price_is_estimate BIGINT DEFAULT 0, pricing_days_have BIGINT, pricing_days_total BIGINT, delivery_nos TEXT, delivery_id BIGINT, discharge_date TEXT);

-- 来源: SQLite 表 fin_receipts
CREATE TABLE "fin_receipts" (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tab           TEXT NOT NULL CHECK (tab IN ('sales','purchase','charge')),  -- 应收/应付
    fin_id        BIGINT NOT NULL,      -- → fin_sales_cargo.id / fin_purchase_cargo.id
    amount_usd    DOUBLE PRECISION NOT NULL,         -- 本次收/付款（可负：冲正）
    received_date TEXT NOT NULL,         -- 收/付款日期（ISO）
    method        TEXT,                  -- 电汇 / 信用证 / …
    note          TEXT,
    created_at    TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
    created_by    TEXT
);

-- 来源: SQLite 表 fin_sales_cargo
CREATE TABLE fin_sales_cargo (
    id                              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    no_raw                          TEXT,   -- 原始 NO（月度手工流水，不可靠，仅存档）
    customer_name                   TEXT,   -- CUSTOMER NAME
    contract_ref                    TEXT,   -- CONTRACT REF
    product                         TEXT,   -- PRODUCT
    contract_date                   TEXT,   -- CONTRACT DATE
    sales_qty_mt                    DOUBLE PRECISION,   -- SALES QUANTITY （MTS/+-)
    incoterm                        TEXT,   -- INCOTERM
    loading_date                    TEXT,   -- LOADING DATE
    vessel                          TEXT,   -- VESSEL
    loading_qty_mt                  DOUBLE PRECISION,   -- LOADING QUANTITY （MT)
    load_port                       TEXT,   -- LOAD PORT
    discharge_port                  TEXT,   -- DISCHARGE PORT
    gst                             TEXT,   -- GST
    sales_invoice_number            TEXT,   -- SALES INVOICE NUMBER（手工）
    sales_invoice_number_system     TEXT,   -- SALES INVOICE NUMBER （SYSTEM)（系统开票预留）
    sales_invoice_date              TEXT,   -- SALES INVOICE DATE
    payment_due_date                TEXT,   -- PAYMENT DUE DATE
    payment_term                    TEXT,   -- PAYMENT TERM
    pricing_term                    TEXT,   -- PRICING TERM
    pricing_provisional_usd         DOUBLE PRECISION,   -- PRICING (PROVISIONAL) (USD)
    provisional_amount_usd          DOUBLE PRECISION,   -- PROVISIONAL AMOUNT (USD)
    provisional_amount_cny          DOUBLE PRECISION,   -- PROVISIONAL AMOUNT (CNY)
    pricing_final_usd               DOUBLE PRECISION,   -- PRICING (FINAL) (USD)
    final_amount_usd_excl_gst       DOUBLE PRECISION,   -- FINAL AMOUNT (USD)- EXCLUDE GST
    final_amount_cny_excl_gst       DOUBLE PRECISION,   -- FINAL AMOUNT (CNY)- EXCLUDE GST
    differential_amount_usd_wo_gst  DOUBLE PRECISION,   -- DIFFERENTIAL AMOUNT (USD) without GST
    differential_amount_usd_w_gst   DOUBLE PRECISION,   -- DIFFERENTIAL AMOUNT (USD) with GST
    final_amount_cny_net_after_prov DOUBLE PRECISION,   -- FINAL AMOUNT (CNY) （NET AFTER DEDUCT PROV)
    -- 元数据 / 预留
    source_file                     TEXT,
    source_sheet                    TEXT,
    source_row                      BIGINT,
    raw_json                        TEXT,
    counterparty_id                 BIGINT REFERENCES counterparties(id),
    order_id                        TEXT,
    finance_id                      TEXT,
    imported_at                     TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
, source TEXT DEFAULT 'excel', status TEXT, order_biz TEXT, transferred_at TEXT, transferred_by TEXT, received_amount_usd DOUBLE PRECISION DEFAULT 0, last_received_date TEXT, payment_status TEXT, bl_date TEXT, voided_at TEXT, voided_by TEXT, void_reason TEXT, price_is_estimate BIGINT DEFAULT 0, pricing_days_have BIGINT, pricing_days_total BIGINT, is_price_diff BIGINT DEFAULT 0, parent_fin_id BIGINT, charges_amount DOUBLE PRECISION DEFAULT 0, delivery_nos TEXT, delivery_id BIGINT, discharge_date TEXT);

-- 来源: SQLite 表 fin_voided_rows
CREATE TABLE fin_voided_rows (
            id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            tab        TEXT NOT NULL,          -- sales / purchase
            fin_id     BIGINT NOT NULL,
            snapshot   TEXT NOT NULL,          -- 作废时的整行 JSON
            reason     TEXT,
            voided_by  TEXT,
            voided_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        );

-- 来源: SQLite 表 flow_approvers
CREATE TABLE flow_approvers (
            biz_type    TEXT NOT NULL,
            stage_code  TEXT NOT NULL,
            user_id     BIGINT NOT NULL,
            added_by    TEXT,
            added_at    TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            PRIMARY KEY (biz_type, stage_code, user_id)
        );

-- 来源: SQLite 表 flow_instances
CREATE TABLE flow_instances (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            biz_type    TEXT NOT NULL,        -- cp_change / credit_appl
            biz_id      BIGINT NOT NULL,     -- 业务表主键
            title       TEXT NOT NULL,        -- 「客商变更-张三-2026-08-21」
            applicant   TEXT NOT NULL,
            status      TEXT NOT NULL DEFAULT 'pending',  -- pending/approved/returned/cancelled
            current_seq BIGINT NOT NULL DEFAULT 2,
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            updated_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            decided_at  TEXT
        , flow_no TEXT, biz_ref TEXT);

-- 来源: SQLite 表 flow_nodes
CREATE TABLE flow_nodes (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            instance_id BIGINT NOT NULL,
            seq         BIGINT NOT NULL,      -- 1 = 申请人发起
            name        TEXT NOT NULL,
            kind        TEXT NOT NULL,         -- submit / approve
            stage_code  TEXT,                  -- 审批人配置用；发起节点为空
            status      TEXT NOT NULL DEFAULT 'pending'   -- pending/done/returned
        );

-- 来源: SQLite 表 flow_records
CREATE TABLE flow_records (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            instance_id BIGINT NOT NULL,
            seq         BIGINT,
            node_name   TEXT,
            actor       TEXT,                  -- 处理人
            action      TEXT NOT NULL,         -- submit/approve/return/resubmit/comment
            note        TEXT,                  -- 意见
            receiver    TEXT,                  -- 接收人（下一节点候选，逗号分隔）
            source      TEXT,                  -- web / telegram
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        );

-- 来源: SQLite 表 inventory_allocations
CREATE TABLE inventory_allocations (
            id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            lot_id       BIGINT NOT NULL,     -- 入库批次
            out_move_id  BIGINT NOT NULL,     -- 出库单
            qty_mt       DOUBLE PRECISION NOT NULL,
            source       TEXT NOT NULL DEFAULT 'manual',   -- fifo / manual
            matched_by   TEXT,
            matched_at   TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            notes        TEXT
        );

-- 来源: SQLite 表 inventory_counts
CREATE TABLE inventory_counts (
            id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            count_date   TEXT NOT NULL,
            location_id  BIGINT NOT NULL,
            product      TEXT NOT NULL,
            measured_mt  DOUBLE PRECISION NOT NULL,      -- 实测
            gauge_basis  TEXT,               -- 用哪把尺子量的
            book_mt      DOUBLE PRECISION,               -- 录入当时的账面量（存下来，事后可复盘）
            diff_mt      DOUBLE PRECISION,
            diff_pct     DOUBLE PRECISION,
            verdict      TEXT,               -- gauge（计量差异，门槛内）/ explain（待解释）
            reason       TEXT,
            counted_by   TEXT,
            counted_at   TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            confirmed_by TEXT,
            confirmed_at TEXT, count_no TEXT, adjust_move_id BIGINT, diff_amount_usd DOUBLE PRECISION,
            UNIQUE(count_date, location_id, product)
        );

-- 来源: SQLite 表 inventory_lots
CREATE TABLE inventory_lots (
            id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            location_id       BIGINT NOT NULL,
            product           TEXT NOT NULL,
            qty_in_mt         DOUBLE PRECISION NOT NULL,        -- 入库量
            qty_left_mt       DOUBLE PRECISION NOT NULL,        -- 剩余量（出库时递减，第 4 段 FIFO 用）
            unit_cost_usd     DOUBLE PRECISION,                 -- USD/MT
            cost_basis        TEXT,                 -- 成本来源说明（采购单/人工填）
            source_order_kind TEXT,                 -- cargo / bunker
            source_order_id   TEXT,
            lot_date          TEXT,                 -- 入库日
            pool              TEXT NOT NULL DEFAULT 'cargo',   -- cargo / bunker（第 4 段划拨用）
            notes             TEXT,
            created_by        TEXT,
            created_at        TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        , zone_id BIGINT, source_lot_id BIGINT, origin_move_id BIGINT, pending BIGINT NOT NULL DEFAULT 0, contract_qty_mt DOUBLE PRECISION);

-- 来源: SQLite 表 inventory_moves
CREATE TABLE inventory_moves (
            id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            move_no        TEXT UNIQUE,
            move_type      TEXT NOT NULL,           -- in / out / transfer / adjust
            location_id    BIGINT NOT NULL,        -- 转移时是「转出」库位
            to_location_id BIGINT,                 -- 仅转移
            product        TEXT NOT NULL,
            qty_mt         DOUBLE PRECISION NOT NULL,           -- 恒为正数，方向由 move_type 决定
            uom            TEXT NOT NULL DEFAULT 'MT',
            gauge_basis    TEXT,                    -- shore / ship / bdn / meter
            lot_id         BIGINT,
            order_kind     TEXT,
            order_id       TEXT,
            delivery_id    BIGINT,                 -- → order_deliveries.id（第 3 段 BDN 扣减用）
            status         TEXT NOT NULL DEFAULT 'posted',  -- pending / posted / reversed
            moved_at       TEXT NOT NULL,
            notes          TEXT,
            operated_by    TEXT,
            reverses_move_id   BIGINT,             -- 本条是哪条的红冲
            reversed_by_move_id BIGINT,            -- 本条被哪条红冲了
            created_at     TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        , zone_id BIGINT, unalloc_reason TEXT, source_party TEXT, vessel_name TEXT, bl_no TEXT, to_zone_id BIGINT);

-- 来源: SQLite 表 inventory_stocktake_lines
CREATE TABLE inventory_stocktake_lines (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            doc_id      BIGINT NOT NULL,
            lot_id      BIGINT NOT NULL,
            location_id BIGINT,
            product     TEXT,
            book_mt     DOUBLE PRECISION,                    -- 存下账面量：事后要能复盘「当时账上是多少」
            actual_mt   DOUBLE PRECISION,
            diff_mt     DOUBLE PRECISION,
            unit_cost_usd DOUBLE PRECISION,
            diff_amount_usd DOUBLE PRECISION,
            reason      TEXT,
            move_id     BIGINT                  -- 这一行生成的调整流水；差异为 0 时为空
        );

-- 来源: SQLite 表 inventory_stocktakes
CREATE TABLE inventory_stocktakes (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            doc_no      TEXT UNIQUE,
            count_date  TEXT NOT NULL,
            operator    TEXT,                    -- 盘点人（现场那个人，不一定是登录账号）
            notes       TEXT,
            gain_mt     DOUBLE PRECISION DEFAULT 0,
            loss_mt     DOUBLE PRECISION DEFAULT 0,
            gain_amt_usd DOUBLE PRECISION DEFAULT 0,
            loss_amt_usd DOUBLE PRECISION DEFAULT 0,
            created_by  TEXT,
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        , deleted_at TEXT, deleted_by TEXT, delete_reason TEXT);

-- 来源: SQLite 表 invoice_documents
CREATE TABLE invoice_documents (  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  order_kind TEXT NOT NULL DEFAULT 'bunker',  order_id TEXT NOT NULL,  invoice_no TEXT,  buyer_name TEXT,  payload_json TEXT,  pdf_path TEXT,  created_at TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),  created_by TEXT, request_id BIGINT, doc_type TEXT, template_code TEXT, template_version TEXT, file_hash TEXT, is_current BIGINT NOT NULL DEFAULT 1, source_type TEXT);

-- 来源: SQLite 表 invoice_request_allocations
CREATE TABLE invoice_request_allocations (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            request_id  BIGINT NOT NULL,
            item_key    TEXT NOT NULL,               -- '<source_type>:<source_id>'
            source_type TEXT NOT NULL,
            source_id   BIGINT NOT NULL,
            item_type   TEXT NOT NULL,
            order_kind  TEXT, order_id TEXT,
            source_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
            available_amount_at_request DOUBLE PRECISION NOT NULL DEFAULT 0,
            requested_quantity DOUBLE PRECISION,
            requested_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
            invoiced_quantity DOUBLE PRECISION,
            invoiced_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
            currency    TEXT,
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            created_by  TEXT
        );

-- 来源: SQLite 表 invoice_request_lines
CREATE TABLE invoice_request_lines (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            request_id  BIGINT NOT NULL,
            line_no     BIGINT NOT NULL DEFAULT 1,
            item_type   TEXT NOT NULL,               -- PRODUCT / FEE / ADJUSTMENT
            source_type TEXT NOT NULL,               -- COST_LINE / CHARGE
            source_id   BIGINT NOT NULL,
            item_code   TEXT, description TEXT,
            quantity    DOUBLE PRECISION, uom TEXT, unit_price DOUBLE PRECISION,
            pricing_method TEXT,                     -- QTY_X_PRICE / FIXED_AMOUNT ...
            amount_excl_tax DOUBLE PRECISION NOT NULL DEFAULT 0,
            tax_code    TEXT, tax_rate DOUBLE PRECISION, tax_amount DOUBLE PRECISION,
            amount_incl_tax DOUBLE PRECISION NOT NULL DEFAULT 0,
            currency    TEXT
        , desc_override TEXT);

-- 来源: SQLite 表 invoice_request_logs
CREATE TABLE invoice_request_logs (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            request_id  BIGINT NOT NULL,
            actor       TEXT, role TEXT,
            action      TEXT NOT NULL,
            old_status  TEXT, new_status TEXT,
            remark      TEXT,
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        );

-- 来源: SQLite 表 invoice_requests
CREATE TABLE invoice_requests (
            id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            request_no    TEXT NOT NULL,
            business_type TEXT NOT NULL,              -- bunker / cargo
            process_type  TEXT NOT NULL,              -- 见 IR_PROCESS_*
            invoice_type  TEXT NOT NULL DEFAULT 'FINAL_INVOICE',
            related_invoice_no TEXT,                  -- CN/DN 关联的原发票（本期不启用）
            order_kind    TEXT, order_id TEXT,        -- V1 合并范围 = 同一订单
            contract_ref  TEXT, vessel TEXT,
            legal_entity  TEXT,                       -- 记账主体名（暂为字符串，法人主数据未建）
            counterparty_id BIGINT, customer_name TEXT,
            currency      TEXT NOT NULL DEFAULT 'USD',
            requested_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
            item_count    BIGINT NOT NULL DEFAULT 0,
            merge_scope   TEXT NOT NULL DEFAULT 'SAME_ORDER',
            status        TEXT NOT NULL DEFAULT 'DRAFT',
            applicant     TEXT, applicant_role TEXT, applicant_dept TEXT,
            invoice_date  TEXT, payment_term TEXT, due_date TEXT,
            remark        TEXT,
            flow_id       BIGINT,                    -- Cargo 走审批流引擎；Bunker 为空
            finance_reviewer TEXT, finance_reviewed_at TEXT,
            submitted_at  TEXT, returned_at TEXT, return_reason TEXT,
            invoice_no    TEXT,                       -- 开票成功后回写；UNIQUE 见下
            issued_at     TEXT, issued_by TEXT,
            failure_code  TEXT, failure_message TEXT, failed_at TEXT,
            retry_count   BIGINT NOT NULL DEFAULT 0,
            last_retry_at TEXT, last_retry_by TEXT,
            created_at    TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            created_by    TEXT,
            updated_at    TEXT, updated_by TEXT,
            version       BIGINT NOT NULL DEFAULT 0
        , invoice_direction TEXT, billing_contact TEXT, billing_email TEXT, delivery_id BIGINT, tax_code TEXT, gst_treatment TEXT, gst_rate DOUBLE PRECISION, gst_amount DOUBLE PRECISION);

-- 来源: SQLite 表 long_term_agreements
CREATE TABLE long_term_agreements (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name              TEXT NOT NULL,
    counterparty_id   BIGINT REFERENCES counterparties(id),
    agreed_premium    DOUBLE PRECISION,
    monthly_price_cap DOUBLE PRECISION,
    total_qty         DOUBLE PRECISION,
    remaining_qty     DOUBLE PRECISION,
    is_active         BIGINT NOT NULL DEFAULT 1,
    created_at        TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 来源: SQLite 表 lt_agreement_charge_rates
CREATE TABLE lt_agreement_charge_rates (
            id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            agreement_id   BIGINT NOT NULL,
            seq            BIGINT DEFAULT 0,
            port           TEXT,                    -- 空 = 全部港口
            charge_item_id BIGINT NOT NULL,        -- charge_items.id
            unit_price     DOUBLE PRECISION,                    -- 按费用项的计费方式（按吨/按票/按小时…）
            currency       TEXT,
            free_hours     DOUBLE PRECISION,                    -- 按小时计费的免费时长（待时费/吹扫费）
            notes          TEXT
        );

-- 来源: SQLite 表 lt_agreement_ports
CREATE TABLE lt_agreement_ports (
            id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            agreement_id BIGINT NOT NULL,
            seq          BIGINT DEFAULT 0,
            port         TEXT NOT NULL,           -- 港口
            premium      DOUBLE PRECISION,                    -- 贴水
            min_qty      DOUBLE PRECISION,                    -- 最小值
            max_qty      DOUBLE PRECISION,                    -- 最大值
            markup       DOUBLE PRECISION                     -- 加价金额
        , port_kind TEXT);

-- 来源: SQLite 表 lt_agreements
CREATE TABLE lt_agreements (
            id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            agreement_no    TEXT UNIQUE,          -- 系统编号 LTA-YYYYMM-NNN
            -- ── 基本信息 ──
            name            TEXT NOT NULL,        -- 长约名称
            counterparty_id BIGINT,              -- 客户（关联客商档案）
            customer_name   TEXT,                 -- 冗余客户名，列表直接显示
            product         TEXT,                 -- 油品
            trade_entity    TEXT,                 -- 交易主体
            monthly_min     DOUBLE PRECISION,                 -- 月度下限值（吨）
            monthly_max     DOUBLE PRECISION,                 -- 月度上限值（吨）
            start_date      TEXT,                 -- 长约起
            end_date        TEXT,                 -- 长约止
            period_def      TEXT,                 -- 合约期定义
            -- ── 计价信息 ──
            pricing_method  TEXT,                 -- 计价方式
            pricing_basis   TEXT,                 -- 计价基准
            pricing_product TEXT,                 -- 计价品种
            currency        TEXT DEFAULT 'USD',
            calc_condition  TEXT,                 -- 计算条件
            pricing_unit    TEXT,                 -- 计价单位
            pricing_date    TEXT,                 -- 计价日期
            n_value         DOUBLE PRECISION,                 -- N 值（供油日前后 N 天等用）
            remark          TEXT,
            -- ── 状态与留痕 ──
            status          TEXT NOT NULL DEFAULT 'draft',   -- draft/submitted/active/expired/cancelled
            created_by      TEXT,
            created_at      TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            updated_by      TEXT,
            updated_at      TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            submitted_at    TEXT
        , gtc_terms TEXT, deal_date TEXT, trader TEXT, cp_type TEXT, load_port TEXT, discharge_port TEXT, trade_term TEXT, credit_term TEXT, ec_contract_name TEXT, offline_no TEXT, direction TEXT, broker TEXT, qty_mode TEXT, contract_qty DOUBLE PRECISION, qty_uom TEXT, qty_tol_sign TEXT, qty_tol_value DOUBLE PRECISION, qty_tol_unit TEXT, unit_conv_rate DOUBLE PRECISION, unit_conv_from TEXT, unit_conv_to TEXT, ref_contract_qty DOUBLE PRECISION, ref_contract_uom TEXT, close_flag TEXT, price_type TEXT, quote_kind TEXT, premium DOUBLE PRECISION, price_period_term TEXT, price_month TEXT, price_from TEXT, price_to TEXT, price_formula_desc TEXT, other_adjust DOUBLE PRECISION, calc_precision BIGINT, mtm_price DOUBLE PRECISION, exposure_desc TEXT, mtm_enabled BIGINT, mtm_price_type TEXT, mtm_basis TEXT, mtm_quote_kind TEXT, mtm_premium DOUBLE PRECISION, mtm_currency TEXT, mtm_unit TEXT, mtm_period_term TEXT, mtm_month TEXT, mtm_from TEXT, mtm_to TEXT, mtm_formula_desc TEXT, biz_type TEXT, qty_min DOUBLE PRECISION, qty_max DOUBLE PRECISION, fixed_price DOUBLE PRECISION, transaction_code TEXT, book TEXT, biz_group TEXT, lc_amount DOUBLE PRECISION, governing_law TEXT, dispute_resolution TEXT, pricing_remark TEXT, deal_remark TEXT, has_fx_exposure TEXT);

-- 来源: SQLite 表 lt_pricing_events
CREATE TABLE lt_pricing_events (
            agreement_id  BIGINT PRIMARY KEY,
            event_type    TEXT,      -- B/L、NOR、Discharge…
            est_date      TEXT,      -- Estimate event DATE
            actual_date   TEXT,      -- Actual event DATE
            window_mode   TEXT,      -- days_around / days_or / days_total / weeks
            -- days_around：事件日前后 N 天，且工作日/周六/周日/假日各自可配（3 格 = 前/后/顺延）
            days_n        BIGINT,
            days_rel      TEXT,      -- Around / Before / After
            d_normal      TEXT, d_saturday TEXT, d_sunday TEXT, d_holiday TEXT,   -- 逗号分隔 3 值
            -- days_or：X 天 或 Y 天
            days_or_a     TEXT, days_or_b TEXT,
            -- days_total：合计 N 天，从 X 起
            days_total    TEXT, days_total_unit TEXT,
            days_start    TEXT, days_start_unit TEXT, days_start_ref TEXT,
            -- weeks：共 N 周，事件前 M 周
            weeks_total   BIGINT, weeks_before BIGINT,
            price_from    TEXT, price_to TEXT,
            formula_desc  TEXT,
            updated_at    TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        );

-- 来源: SQLite 表 lt_pricing_fixings
CREATE TABLE lt_pricing_fixings (
            id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            agreement_id  BIGINT NOT NULL,
            seq           BIGINT DEFAULT 0,
            qty           DOUBLE PRECISION,      -- 数量
            uom           TEXT,      -- 单位
            fixed_price   DOUBLE PRECISION,      -- 固定价
            price_from    TEXT,      -- 计价期始
            price_to      TEXT,      -- 计价期末
            note          TEXT
        );

-- 来源: SQLite 表 number_rules
CREATE TABLE number_rules (
            code       TEXT PRIMARY KEY,
            prefix     TEXT,
            date_fmt   TEXT,
            seq_width  BIGINT,
            updated_at TEXT,
            updated_by TEXT
        );

-- 来源: SQLite 表 order_attachments
CREATE TABLE order_attachments (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_kind      TEXT NOT NULL CHECK (order_kind IN ('bunker','cargo')),
    order_id        TEXT NOT NULL,
    attach_type     TEXT NOT NULL,
    original_name   TEXT NOT NULL,
    stored_path     TEXT NOT NULL,
    mime_type       TEXT DEFAULT '',
    file_size       BIGINT NOT NULL DEFAULT 0,
    uploaded_by     TEXT DEFAULT '',
    created_at      TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
, delivery_id BIGINT, sha256 TEXT, draft_token TEXT);

-- 来源: SQLite 表 order_cost_lines
CREATE TABLE order_cost_lines (
            id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            order_kind   TEXT NOT NULL,          -- bunker / cargo
            order_id     TEXT NOT NULL,
            settle_id    BIGINT,                -- 引用的结算流水；价差行为空
            delivery_id  BIGINT,                -- 挂在哪一笔交货批次上
            line_kind    TEXT NOT NULL DEFAULT 'goods',   -- goods 货款 / diff 价差
            settle_type  TEXT,                   -- Final / Prepayment / Provisional
            qty_mt       DOUBLE PRECISION,                   -- 价差行为 0（只有金额）
            unit_price   DOUBLE PRECISION,
            amount       DOUBLE PRECISION,
            currency     TEXT,
            direction    TEXT, entity TEXT, counterparty TEXT,
            settle_uom   TEXT, percentage DOUBLE PRECISION, pricing_formula TEXT,
            tax_code     TEXT, tax_rate DOUBLE PRECISION, tax_amount DOUBLE PRECISION, amount_incl_tax DOUBLE PRECISION,
            voucher_no   TEXT, invoice_date TEXT, due_date TEXT,
            sign_status  TEXT, remark TEXT,
            status       TEXT NOT NULL DEFAULT 'draft',   -- draft/pushed/invoiced/void
            fin_table    TEXT, fin_id BIGINT,            -- 推送后挂上的台账行
            pushed_at    TEXT, pushed_by TEXT,
            created_at   TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            created_by   TEXT,
            voided_at    TEXT, voided_by TEXT, void_reason TEXT
        , invoice_attach_id BIGINT, ap_invoice_id BIGINT);

-- 来源: SQLite 表 order_deliveries
CREATE TABLE order_deliveries (
    id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    delivery_no           TEXT UNIQUE,                 -- 交货编号 DLV{YYYYMMDD}-NNN
    order_kind            TEXT NOT NULL CHECK (order_kind IN ('bunker','cargo')),
    order_id              TEXT NOT NULL,               -- 内部键（bunker_id / cargo 内部键）
    seq                   BIGINT NOT NULL DEFAULT 1,  -- 本单第几次交货
    delivered_qty_kt      DOUBLE PRECISION NOT NULL,               -- 本次交货量
    actual_delivery_date  TEXT,
    bdn_no                TEXT,
    bdn_qty               DOUBLE PRECISION,
    actual_delivery_port  TEXT,
    actual_delivery_location TEXT,
    delivery_ended_at     TEXT,
    delivery_notes        TEXT,
    operated_by           TEXT DEFAULT '',
    created_at            TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
, nomination_no TEXT, bdn_date TEXT, vessel_name TEXT, vessel_imo TEXT, bunker_tanker_name TEXT, alongside_at TEXT, commenced_pumping_at TEXT, completed_pumping_at TEXT, product_name TEXT, etd TEXT, gross_tonnage DOUBLE PRECISION, terminal TEXT, agent TEXT, ot_alternance TEXT, location_id BIGINT, zone_id BIGINT, survey_no TEXT, survey_qty DOUBLE PRECISION, doc_kind TEXT, discharge_port TEXT, voyage_no TEXT, surveyor TEXT, survey_basis TEXT, doc_extra_json TEXT);

-- 来源: SQLite 表 order_field_changes
CREATE TABLE order_field_changes (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_kind   TEXT NOT NULL,                 -- bunker / cargo
    order_id     TEXT NOT NULL,                 -- 业务单号(=bunker_id/cargo_id)
    field        TEXT NOT NULL,                 -- 数据库列名
    field_label  TEXT,                          -- 中文字段名(写入时快照)
    old_value    TEXT,                          -- 修改前(可读值)
    new_value    TEXT,                          -- 修改后(可读值)
    changed_by   TEXT,                          -- 操作人 username
    changed_at   TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
);

-- 来源: SQLite 表 order_settlements
CREATE TABLE order_settlements (
            id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            order_kind    TEXT NOT NULL,        -- bunker / cargo
            order_id      TEXT NOT NULL,
            kind          TEXT NOT NULL,        -- provisional=预结算 / final=终结算
            qty_mt        DOUBLE PRECISION,                 -- 结算数量(吨)，取 BDN 累计交货量
            unit_price    DOUBLE PRECISION,                 -- 结算单价
            goods_amount  DOUBLE PRECISION,                 -- 货款金额 = 数量 × 单价
            charges_amount DOUBLE PRECISION DEFAULT 0,      -- 并入本次结算的杂费(仅 billable)
            total_amount  DOUBLE PRECISION,                 -- 货款 + 杂费
            fin_table     TEXT,                 -- 写到哪张财务台账
            fin_id        BIGINT,              -- 对应财务台账行 id
            price_source  TEXT,                 -- manual / market(行情估算) / order(订单终价)
            notes         TEXT,
            settled_by    TEXT,
            settled_at    TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        , settle_type TEXT, direction TEXT, entity TEXT, counterparty TEXT, settle_uom TEXT, percentage DOUBLE PRECISION, currency TEXT, pricing_formula TEXT, tax_code TEXT, tax_rate DOUBLE PRECISION, tax_amount DOUBLE PRECISION, amount_incl_tax DOUBLE PRECISION, voucher_no TEXT, invoice_date TEXT, due_date TEXT, sign_status TEXT, remark TEXT, delivery_id BIGINT, signed_by TEXT, signed_at TEXT, voided_at TEXT, voided_by TEXT, void_reason TEXT, fx_rate DOUBLE PRECISION, orig_amount DOUBLE PRECISION);

-- 来源: SQLite 表 port_library
CREATE TABLE port_library (
        locode          TEXT PRIMARY KEY,
        name_en         TEXT NOT NULL,
        country_code    TEXT NOT NULL,
        source          TEXT,
        source_version  TEXT,
        imported_at     TEXT
    );

-- 来源: SQLite 表 ports
CREATE TABLE ports (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code        TEXT UNIQUE,
    name        TEXT NOT NULL,
    country     TEXT
, aliases TEXT, is_active BIGINT NOT NULL DEFAULT 1, created_at TEXT, created_by TEXT, updated_at TEXT, updated_by TEXT, name_cn TEXT);

-- 来源: SQLite 表 price_daily
CREATE TABLE price_daily (
    DATE       TEXT PRIMARY KEY,
    mops380    DOUBLE PRECISION,
    mops05     DOUBLE PRECISION,
    mopag180   DOUBLE PRECISION,
    brnswap    DOUBLE PRECISION,
    bunkerwire DOUBLE PRECISION,
    is_actual  BIGINT NOT NULL DEFAULT 1
, mgo DOUBLE PRECISION, source TEXT, updated_by TEXT, mops380_est DOUBLE PRECISION, mops05_est DOUBLE PRECISION, bunkerwire_est DOUBLE PRECISION, mgo_est DOUBLE PRECISION, price_phase TEXT, est_at TEXT, est_by TEXT, final_at TEXT, final_by TEXT, updated_at TEXT, naphtha DOUBLE PRECISION, naphtha_est DOUBLE PRECISION);

-- 来源: SQLite 表 pricing_bases
CREATE TABLE pricing_bases (
            code       TEXT PRIMARY KEY,
            name       TEXT,
            source     TEXT,
            biz_scope  TEXT DEFAULT 'both',
            price_col  TEXT,
            remark     TEXT,
            is_active  BIGINT DEFAULT 1,
            sort       BIGINT DEFAULT 0,
            created_at TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            created_by TEXT,
            updated_at TEXT,
            updated_by TEXT
        );

-- 来源: SQLite 表 pricing_units
CREATE TABLE pricing_units (
            code       TEXT PRIMARY KEY,
            name       TEXT,
            category   TEXT,
            remark     TEXT,
            is_active  BIGINT DEFAULT 1,
            sort       BIGINT DEFAULT 0,
            created_at TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            created_by TEXT,
            updated_at TEXT,
            updated_by TEXT
        );

-- 来源: SQLite 表 qa_history
CREATE TABLE qa_history (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL,                      -- 提问用户（各看各的）
    question    TEXT NOT NULL,                         -- 原始问题
    answer      TEXT NOT NULL,                         -- 模型回答（含 markdown）
    data_json   TEXT,                                  -- 命中工具的结构化结果 JSON
    tools       TEXT,                                  -- 调用的工具名，逗号分隔
    created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
, sqls TEXT, success BIGINT DEFAULT 0);

-- 来源: SQLite 表 recap_tokens
CREATE TABLE recap_tokens (
    token           TEXT PRIMARY KEY,
    whatsapp_from   TEXT NOT NULL,
    created_at      TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at      TEXT NOT NULL,
    used_at         TEXT,
    cargo_id        TEXT
, telegram_chat_id BIGINT, telegram_user_id BIGINT, bunker_id TEXT, kind TEXT NOT NULL DEFAULT 'cargo', b2b_counterparty_id BIGINT, b2b_price DOUBLE PRECISION, b2b_payload TEXT);

-- 来源: SQLite 表 role_data_scopes
CREATE TABLE role_data_scopes (
    role_code  TEXT NOT NULL,
    perm_key   TEXT NOT NULL,
    scope      TEXT NOT NULL DEFAULT 'all',   -- all=全部 / company=本公司 / dept=本部门 / own=本人
    PRIMARY KEY (role_code, perm_key)
);

-- 来源: SQLite 表 role_permissions
CREATE TABLE role_permissions (
            role_code TEXT NOT NULL,
            perm_key  TEXT NOT NULL,
            level     TEXT NOT NULL,
            PRIMARY KEY (role_code, perm_key, level)
        );

-- 来源: SQLite 表 roles
CREATE TABLE roles (
            code        TEXT PRIMARY KEY,
            name        TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            caps        TEXT NOT NULL DEFAULT '[]',
            rank        BIGINT NOT NULL DEFAULT 1,
            is_builtin  BIGINT NOT NULL DEFAULT 0,
            is_active   BIGINT NOT NULL DEFAULT 1,
            sort        BIGINT NOT NULL DEFAULT 0
        );

-- 来源: SQLite 表 so_buyers
CREATE TABLE so_buyers (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    buyer_name    TEXT NOT NULL UNIQUE,
    buyer_address TEXT,
    updated_at    TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
    updated_by    TEXT
);

-- 来源: SQLite 表 so_documents
CREATE TABLE so_documents (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bunker_id     TEXT NOT NULL,
    so_no         TEXT,
    buyer_name    TEXT,
    payload_json  TEXT,               -- 生成时的完整 SO 字段快照
    pdf_path      TEXT,
    created_at    TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
    created_by    TEXT
);

-- 来源: SQLite 表 storage_locations
CREATE TABLE storage_locations (
            id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            code                TEXT NOT NULL UNIQUE,
            name                TEXT,
            loc_type            TEXT NOT NULL DEFAULT 'shore_tank',
            port_id             BIGINT,          -- → ports.id
            vessel_id           BIGINT,          -- → vessels.id（泊船/浮仓）
            operator_cp_id      BIGINT,          -- → counterparties.id（码头方/船东）
            capacity_mt         DOUBLE PRECISION,
            gauge_tolerance_pct DOUBLE PRECISION DEFAULT 0.3, -- 盘点差异门槛：岸罐严、水上松
            active_from         TEXT,             -- 泊船临时充当储存的启用/停用窗口
            active_to           TEXT,
            notes               TEXT,
            is_delete           BIGINT NOT NULL DEFAULT 0,
            deleted_by          TEXT,
            deleted_at          TEXT,
            created_by          TEXT,
            created_at          TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            updated_at          TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        );

-- 来源: SQLite 表 storage_zones
CREATE TABLE storage_zones (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            location_id BIGINT NOT NULL,
            code        TEXT NOT NULL,        -- 罐号 / 舱位号
            name        TEXT,
            capacity_mt DOUBLE PRECISION,
            notes       TEXT,
            is_delete   BIGINT NOT NULL DEFAULT 0,
            created_by  TEXT,
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            UNIQUE(location_id, code)
        );

-- 来源: SQLite 表 tax_rates
CREATE TABLE tax_rates (
            id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            name        TEXT NOT NULL UNIQUE,
            rate        DOUBLE PRECISION NOT NULL DEFAULT 0,
            description TEXT,
            is_active   BIGINT DEFAULT 1,
            sort        BIGINT DEFAULT 0,
            created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            created_by  TEXT,
            updated_at  TEXT,
            updated_by  TEXT
        , code TEXT, tax_type TEXT NOT NULL DEFAULT 'output', nature TEXT NOT NULL DEFAULT 'rate', infotech_code TEXT, infotech_name TEXT);

-- 来源: SQLite 表 trade_legs
CREATE TABLE trade_legs (
    id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trade_id  TEXT NOT NULL REFERENCES trades(trade_id),
    biz_type  TEXT NOT NULL,                            -- 'bunker' | 'cargo'
    order_id  TEXT NOT NULL,                            -- bunker_id / cargo_id
    leg       TEXT NOT NULL,                            -- 'buy' | 'sell'
    qty_kt    DOUBLE PRECISION,
    UNIQUE(biz_type, order_id)
);

-- 来源: SQLite 表 trade_terms
CREATE TABLE trade_terms (
            id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            code       TEXT NOT NULL UNIQUE,
            name       TEXT,
            name_en    TEXT,
            sort       BIGINT DEFAULT 100,
            is_active  BIGINT NOT NULL DEFAULT 1,
            notes      TEXT,
            created_by TEXT,
            created_at TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
            updated_at TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
        , biz_type TEXT);

-- 来源: SQLite 表 trades
CREATE TABLE trades (
    id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trade_id              TEXT UNIQUE NOT NULL,          -- 业务号 T20260810-0001
    biz_type              TEXT NOT NULL,                 -- 'bunker' | 'cargo'
    is_back_to_back       BIGINT NOT NULL DEFAULT 0,
    grade                 TEXT,
    counterparty_sell_id  BIGINT REFERENCES counterparties(id),  -- 卖给谁
    counterparty_buy_id   BIGINT REFERENCES counterparties(id),  -- 从谁买
    qty_kt                DOUBLE PRECISION,                          -- 成交量（以主腿为准）
    status                TEXT NOT NULL DEFAULT 'open',  -- open|delivered|priced|closed|cancelled
    trade_date            TEXT,
    created_at            TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
    updated_at            TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai')
);

-- 来源: SQLite 表 user_activity_log
CREATE TABLE "user_activity_log" (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    BIGINT REFERENCES users(id) ON DELETE SET NULL,
    username   TEXT NOT NULL DEFAULT '',
    channel    TEXT NOT NULL DEFAULT 'web',   -- 'web' | 'telegram'
    action     TEXT NOT NULL,
    detail     TEXT NOT NULL DEFAULT '',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 来源: SQLite 表 user_grid_prefs
CREATE TABLE user_grid_prefs (
    user_id     BIGINT NOT NULL,                      -- 所属用户
    grid_key    TEXT NOT NULL,                         -- 表格标识（如 bunker / cargo）
    state_json  TEXT NOT NULL,                         -- 列顺序 JSON（仅顺序，不含列宽）
    updated_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
    PRIMARY KEY (user_id, grid_key)
);

-- 来源: SQLite 表 user_notice_snooze
CREATE TABLE user_notice_snooze (
    user_id     BIGINT NOT NULL,                      -- 所属用户
    notice_key  TEXT NOT NULL,                         -- 提醒标识（目前只有 price_entry）
    snooze_date TEXT NOT NULL,                         -- 静音生效的自然日（SGT，YYYY-MM-DD）
    created_at  TEXT DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'),
    PRIMARY KEY (user_id, notice_key)
);

-- 来源: SQLite 表 users
CREATE TABLE users (
        id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        username          TEXT UNIQUE NOT NULL,
        password_hash     TEXT NOT NULL,
        display_name      TEXT,
        role              TEXT NOT NULL DEFAULT 'cargo',
        is_active         BIGINT NOT NULL DEFAULT 1,
        telegram_user_id  BIGINT,
        created_at        TEXT DEFAULT CURRENT_TIMESTAMP,
        last_login_at     TEXT,
        department        TEXT NOT NULL DEFAULT '',
        position          TEXT NOT NULL DEFAULT '',
        email             TEXT NOT NULL DEFAULT '',
        notes             TEXT NOT NULL DEFAULT ''
    , password_enc TEXT, dept_id BIGINT, company_id BIGINT, chinese_name TEXT NOT NULL DEFAULT '', english_name TEXT NOT NULL DEFAULT '', mobile TEXT NOT NULL DEFAULT '', extra_roles TEXT NOT NULL DEFAULT '');

-- 来源: SQLite 表 vessel_ais
CREATE TABLE vessel_ais (
            name_key    TEXT PRIMARY KEY,
            vessel_name TEXT,
            shipid      TEXT,
            port        TEXT,
            eta         TEXT,
            updated_at  TEXT
        );

-- 来源: SQLite 表 vessel_equasis
CREATE TABLE vessel_equasis (
            imo               TEXT PRIMARY KEY,
            name              TEXT,
            flag              TEXT,
            call_sign         TEXT,
            mmsi              TEXT,
            gross_tonnage     BIGINT,
            deadweight        BIGINT,
            ship_type         TEXT,
            year_built        BIGINT,
            status            TEXT,
            owner             TEXT,
            manager           TEXT,
            class_society     TEXT,
            pandi_club        TEXT,
            inspections_json  TEXT,
            queried_by        TEXT,
            updated_at        TEXT
        );

-- 来源: SQLite 表 vessels
CREATE TABLE vessels (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    imo           TEXT UNIQUE,
    name          TEXT NOT NULL,
    flag          TEXT,
    vessel_type   TEXT,
    dwt           BIGINT,
    owner         TEXT,
    operator      TEXT,
    notes         TEXT
, is_tba BIGINT NOT NULL DEFAULT 0, mmsi TEXT, call_sign TEXT, gross_tonnage BIGINT, year_built BIGINT, status TEXT, class_society TEXT, pandi_club TEXT);

-- 来源: SQLite 表 view_tokens
CREATE TABLE view_tokens (
    token             TEXT PRIMARY KEY,
    telegram_user_id  BIGINT NOT NULL,
    created_at        TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at        TEXT NOT NULL
);

-- 来源: SQLite 表 web_sessions
CREATE TABLE "web_sessions" (
    token       TEXT PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at  TEXT NOT NULL,
    created_at  TEXT DEFAULT CURRENT_TIMESTAMP
);

-- ===== 人工复核清单 =====
-- ! DEFAULT (TIMESTAMP('now',...)) 已直译为 DEFAULT (now() AT TIME ZONE 'Asia/Shanghai'):
--   原意为「CST 本地时间字符串」,PG 直译为带时区的 timestamp;若应用层统一用 UTC 存、CST 展示,
--   切库时应改为 DEFAULT now() 并核对所有读写点(翻译任务,非本文件自动处理范围)。
-- ! SQLite 的 TEXT 时间列在 PG 侧建议逐步迁移为 TIMESTAMP(切换后再优化,阶段 0 照抄 TEXT)。
-- ! 113 张表多于 CLAUDE.md 所述「约 30 张主表」,其余为审批/日志/偏好等辅助表,以本文件为准。
