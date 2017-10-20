IF OBJECT_ID('dbo.pc_tariff_results_upd') IS NULL
BEGIN
    DECLARE @proc varchar(255)
    SELECT @proc = 'CREATE PROC dbo.pc_tariff_results_upd AS RETURN 0'
    EXEC (@proc)
END
GO

/*
<DESCRIPTION>
<NAME>
Обновление %% и кэшбэков по пластиковым картам 
в таблице pc_dwh_cashback_turnover
</NAME>
</DESCRIPTION>
*/
ALTER PROCEDURE dbo.pc_tariff_results_upd
    @month tinyint,
    @year smallint
    --@pc_id_table dbo.table_int READONLY
AS
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN
    DECLARE
        @rc             int,
        @err_msg        varchar(255),
        @today          date = GETDATE(),
        @calc_smonth   date,
        @calc_emonth   date,
        @trancount int
    
    IF @month < 1
        OR @month > 12
    BEGIN
        SET @err_msg = 'Неверное значение входного параметра @month'
        GOTO EXIT_ERROR
    END

    IF @year < 1753
        AND @year > 9999
    BEGIN
        SET @err_msg = 'Неверное значение входного параметра @year'
        GOTO EXIT_ERROR
    END

    SELECT
        @calc_smonth   = DATEFROMPARTS(@year, @month, 1),
        @calc_emonth   = EOMONTH(@calc_smonth)

    IF @today < @calc_smonth
    BEGIN
        SET @err_msg = 'Неверные значения входных параметров @year и @month'
        GOTO EXIT_ERROR
    END

--******************************************************************************
--выборка карт
--******************************************************************************
    CREATE TABLE #pc_data
    (
        pc_id int NOT NULL,                         --идентификатор карты
        pc_contract_id int NOT NULL,                --идентификатор контракта
        pc_type_id smallint NOT NULL,               --идентификатор типа карты
        account_id          int     NOT NULL,       --идентификатор счета
        without_cashback    tinyint NOT NULL,       --карта без кэшбека(1)/с кэшбеком(0)
        main_card tinyint NOT NULL,                 --основная(1)/дополнительная(0) карта
        tariff_obj_id int NOT NULL,                 --идентификатор типа тарифа
        oper_date_from smalldatetime NOT NULL,      --операции с
        oper_date_to smalldatetime NOT NULL,        --операции по
        pc_currency_id smallint NOT NULL,           --идентификатор валюты счета карты
        product_id int NOT NULL,                    --идентификатор продукта
        turn_amount money,                          --сумма оборота для начисления
        calc_amount money,                          --начисленная сумма %%
        was_accrued tinyint NOT NULL DEFAULT(0),    --признак "было начислено"
        cb_amount money,                            --сумма кэшбека
        cba_amount money                           --сумма кэшбека по акции
    )

    ALTER TABLE #pc_data
    ADD PRIMARY KEY
    (
        pc_id,
        account_id
    ) 

    CREATE INDEX ix_#pc_data_without_cashback 
    ON #pc_data
    (
        without_cashback
    )
    INCLUDE
    (
        pc_id
    )

    --вставка доходных карт
    INSERT INTO #pc_data
    (
        pc_id,
        pc_contract_id,
        pc_type_id,
        account_id,      
        without_cashback,
        main_card,
        tariff_obj_id,
        oper_date_from,
        oper_date_to,
        pc_currency_id,
        product_id,
        turn_amount,
        calc_amount,
        was_accrued,
        cb_amount,
        cba_amount
    )
    SELECT
        pc_id               = c.pc_id,
        pc_contract_id      = c.pc_contract_id,
        pc_type_id          = c.pc_type_id,
        account_id          = ac.account_id,
        without_cashback    = IIF(pl.pc_id IS NULL, 1, 0),
        main_card           = IIF(ppl.pc_parent IS NULL, 1, 0),
        tariff_obj_id       = p.obj_type_id,
        oper_date_from      = ac.oper_date_from,
        oper_date_to        = ac.oper_date_to,
        pc_currency_id      = ac.currency_id,
        product_id          = p.product_id,
        turn_amount         = pcd.turnover_sum,
        calc_amount         = pcd.charge_summa,
        was_accrued         = IIF(pcd.pc_contract_id IS NULL, 0, 1),
        cb_amount           = cb.cashback_sum,
        cba_amount          = cba.cashback_sum
    FROM (  
            SELECT
                h.pc_contract_id, 
                h.account_id,
                a.currency_id,
                oper_date_from = IIF(h.pc_date_from < @calc_smonth, @calc_smonth, DATEADD(day, 1, h.pc_date_from)),
                oper_date_to = IIF(h.pc_date_to IS NULL OR h.pc_date_to > @calc_emonth, @calc_emonth, h.pc_date_to)
            FROM dbo.pc_accounts_history h
                INNER JOIN dbo.accounts a
                    ON h.account_id = a.account_id 
            WHERE h.pc_date_from  <= @calc_emonth
                AND ISNULL(h.pc_date_to, @calc_smonth) >= @calc_smonth
                AND (
                        a.DateOfClosing IS NULL
                        OR a.DateOfClosing >= @calc_smonth
                    )
         ) ac
        INNER JOIN  (   
                        SELECT pc.pc_id,
                               pc.pc_contract_id,
                               pc.pc_type_id
                        FROM dbo.pc pc
                        WHERE pc.pc_date_from <= @calc_emonth
                           AND ISNULL(pc.pc_date_to, @calc_smonth) >= @calc_smonth
                           AND (
                                    action_closing_date IS NULL
                                    OR action_closing_date >= @calc_smonth
                               )
                           AND pc_id IN (1032733555, 646942304, 1052343738, 1004374331)
                    ) c
            ON ac.pc_contract_id = c.pc_contract_id
        INNER JOIN  (
                        SELECT obj_id
                        FROM dbo.objects 
                        WHERE obj_type_id = 371     --Пластик: Банковская карта
                            AND status_id != 2270   --убираем отклоненные
                    ) o
            ON o.obj_id = c.pc_id
        CROSS APPLY  (  
                        SELECT TOP(1)
                            pl.pc_id,
                            pl.product_id,
                            pt.product_tariff_id,
                            o.obj_type_id
                        FROM dbo.pc_prodlist pl
                            INNER JOIN dbo.pc_products pp
                                ON pl.product_id = pp.product_id
                            INNER JOIN dbo.pc_product_tariffes pt
                                ON pp.product_id = pt.product_id
                            INNER JOIN dbo.objects o
                                ON pt.product_tariff_id = o.obj_id
                        WHERE pl.pc_id = c.pc_id
                            AND pl.begin_date <= IIF(@calc_emonth > @today, @today, @calc_emonth) 
                            AND pt.from_date <= IIF(@calc_emonth > @today, @today, @calc_emonth) 
                            AND o.status_id = 110 --Сформирован
                        ORDER BY pl.begin_date DESC
                    ) p
        LEFT JOIN (
                      SELECT d.pc_id
                      FROM dbo.pc_prodlist d
                          INNER JOIN pc_ref_cash_back_tran_code_product jp
                              ON d.product_id = jp.product_id
                      WHERE jp.obj_id = 207
                      GROUP BY d.pc_id
                  ) pl
            ON c.pc_id = pl.pc_id
        LEFT JOIN dbo.pc_pc_linked ppl
            ON c.pc_id = ppl.pc_child
        LEFT JOIN   (
                        SELECT DISTINCT
                            cp.pc_contract_id,
                            cp.charge_summa,
                            cp.turnover_sum
                        FROM dbo.pc_product_charges pc
                            INNER JOIN dbo.pc_product_charges_pc cp
                                ON pc.product_charge_id = cp.product_charge_id
                            INNER JOIN dbo.pc_product_charges_data cd
                                ON cd.pc_charge_id = cp.pc_charge_id
                        WHERE CONVERT(date, pc.processing_period) = @calc_smonth
                            AND cd.tariff_row_id IS NOT NULL
                    )  pcd
            ON c.pc_contract_id = pcd.pc_contract_id
        LEFT JOIN   (
                        --кешбэк
                        SELECT 
                            cb.account_id,
                            cashback_sum = SUM(cb.cashback_sum)
                        FROM dbo.pc_cash_back_order bo
                            INNER JOIN dbo.pc_cash_back cb
                                ON bo.obj_id = cb.obj_id
                        WHERE begin_date >= @calc_smonth
                            AND end_date <= @calc_emonth
                            AND status_id = 2303 --Проведен
                            AND is_action = 0
                        GROUP BY cb.account_id
                    ) cb
            ON ac.account_id = cb.account_id
        LEFT JOIN   (
                        --кешбэк по акции
                        SELECT 
                            cb.account_id,
                            cashback_sum = SUM(cb.cashback_sum)
                        FROM dbo.pc_cash_back_order bo
                            INNER JOIN dbo.pc_cash_back cb
                                ON bo.obj_id = cb.obj_id
                        WHERE operation_date >= @calc_smonth
                            AND operation_date <= @calc_emonth
                            AND end_date <= @calc_emonth
                            AND status_id = 2303 --Проведен
                            AND is_action = 1
                        GROUP BY cb.account_id
                    ) cba 
            ON ac.account_id = cba.account_id

--******************************************************************************
--расчет остатков и оборотов
--******************************************************************************
    CREATE TABLE #tmp 
    (
        id                  int IDENTITY (1, 1) PRIMARY KEY,
        pc_id               int,
        acc_debit           int,
        dt_oper             date,
        aa_code             varchar(7),
        doc_id              int,
        no_in_doc           int,
        pp_doc_id           int,
        product_id          int,
        acc_47423_id        int,
        pc_contract_id      int,
        tran_currency_id    int,
        tran_amount         money,
        acct_amount         money,
        koef                numeric(12, 5) DEFAULT(0),
        mcc_code            varchar(5),
        tran_code           varchar(3)
    )

    --вставка дебетовых транзакций
    INSERT INTO #tmp
    (
        pc_id,
        acc_debit, 
        dt_oper,
        tran_currency_id,
        tran_amount,
        acct_amount,
        doc_id,
        no_in_doc 
    )
    SELECT
        pc_id               = pd.pc_id,
        acc_debit           = t.acc_debit,
        dt_oper             = t.acc_tran_date,
        tran_currency_id    = ISNULL(t.acc_tran_currency_id, 2),
        tran_amount         = t.acc_tran_currency_sum,
        acct_amount         = t.acc_tran_currency_sum,
        doc_id              = t.doc_id,
        no_in_doc           = t.no_in_doc
    FROM #pc_data pd
        INNER JOIN dbo.acc_transactions t
            ON t.acc_debit = pd.account_id
    WHERE pd.tariff_obj_id != 863
        AND t.acc_tran_currency_sum != 0
        AND t.acc_tran_date >= pd.oper_date_from 
        AND t.acc_tran_date < DATEADD(mm, 1, pd.oper_date_to)

    CREATE INDEX ix_#tmp_dt_oper
    ON #tmp
    (
        dt_oper
    )
    INCLUDE
    (
        aa_code,
        pp_doc_id,
        acc_47423_id
    )
    
    CREATE INDEX ix_#tmp_pp_doc_id 
    ON #tmp
    (
        pp_doc_id
    )
    INCLUDE
    (
        id,
        product_id,
        tran_amount,
        acct_amount,
        koef
    )
    
    CREATE INDEX ix_#tmp_product_id
    ON #tmp
    (
        product_id,
        tran_code,
        dt_oper
    )
    INCLUDE
    (
        pc_id,
        tran_currency_id,
        tran_amount,
        mcc_code
    )
    
    -- обработка дополнительных карт
    DELETE #tmp
    FROM #tmp t
        INNER JOIN #pc_data p
            ON t.pc_id = p.pc_id
    WHERE p.main_card = 0
        AND NOT EXISTS  (   
                            SELECT 1
                            FROM dbo.pc_proc_card_data c
                                INNER JOIN dbo.objects_relations_2_trans r
                                    ON r.primary_object = c.pc_proc_card_data_id
                                        AND r.doc_id = t.doc_id
                                        AND r.no_in_doc = t.no_in_doc
                                        AND r.relation_type_id = 52
                            WHERE c.pc_id = p.pc_id
                        )
    
    -- обновляем информацию о транзакции
    UPDATE #tmp
    SET dt_oper     = ISNULL(dcs.doc_date, d.transaction_time),
        aa_code     = d.authorization_approval_code,
        tran_amount = IIF(d.fee_amount = t.acct_amount, d.fee_amount, d.transaction_amount),
        koef        = IIF(ptc.code_id IS NOT NULL, 1, t.koef),
        mcc_code    = d.merchant_category_code,
        tran_code   = d.code_transaction
    FROM #tmp t
        INNER JOIN #pc_data pc
            ON t.pc_id = pc.pc_id
        INNER JOIN dbo.objects_relations_2_trans r
            ON t.doc_id = r.doc_id
                AND t.no_in_doc = r.no_in_doc
        INNER JOIN dbo.pc_proc_card_data c
            ON r.primary_object = c.pc_proc_card_data_id
        INNER JOIN dbo.pc_proc_ucs_file_trans_data d
            ON c.pc_proc_card_data_id = d.pc_proc_card_data_id
        LEFT JOIN dbo.pc_transaction_codes ptc
            ON ptc.trans_code = d.code_transaction
        LEFT JOIN dbo.pcpos_transations ptr
                INNER JOIN dbo.objects_relations orl
                    ON orl.secondary_object = ptr.obj_id
                    AND orl.relation_type_id = 143
                INNER JOIN dbo.docs dcs
                    ON orl.primary_object = dcs.obj_id
            ON ptr.authorization_approval_code = d.authorization_approval_code
                AND ABS(DATEDIFF(HOUR, t.dt_oper, ISNULL(ptr.reply_time, ptr.request_time))) < 24
    WHERE r.relation_type_id = 52
        AND NOT EXISTS  (
                            SELECT 1
                            FROM dbo.acc_transactions tt
                                INNER JOIN accounts a
                                    ON a.account_id = tt.acc_debit
                            WHERE tt.doc_id = t.doc_id
                                AND tt.no_in_doc = t.no_in_doc
                                AND a.account_number LIKE '4581[57]%'
                        )
    
    --удаляем транзакции не в периоде
    DELETE #tmp
    WHERE dt_oper < @calc_smonth 
        OR dt_oper >= DATEADD(dd, 1, @calc_emonth )
    
    UPDATE #tmp
    SET product_id = c.product_id
    FROM #tmp t
        INNER JOIN  ( 
                        SELECT
                            pc_id,
                            product_id,
                            begin_date,
                            end_date =  MIN(begin_date) OVER (PARTITION BY pc_id ORDER BY begin_date ASC ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING)
                        FROM dbo.pc_prodlist
                    ) c
            ON t.pc_id = c.pc_id
                AND t.dt_oper >= c.begin_date
                AND (c.end_date IS NULL OR t.dt_oper < c.end_date)
    
    UPDATE t
    SET t.acc_47423_id = c.acc_47423_id,
        t.pc_contract_id = p.pc_contract_id
    FROM #tmp t
        INNER JOIN dbo.pc p
            ON p.pc_id = t.pc_id
        INNER JOIN dbo.pc_contract c
            ON c.pc_contract_id = p.pc_contract_id
    
    UPDATE t
    SET t.pp_doc_id = tr.primary_object
    FROM #tmp t
        INNER JOIN  ( 
                        SELECT DISTINCT dt_oper, aa_code
                        FROM #tmp 
                        WHERE aa_code IS NOT NULL
                    ) t1
            ON t.dt_oper = t1.dt_oper
                AND t.aa_code = t1.aa_code
        INNER JOIN  (
                        SELECT obj_id,
                            authorization_approval_code,
                            ISNULL(reply_time, request_time) AS date_time
                        FROM dbo.pcpos_transations 
                    ) pt
            ON pt.authorization_approval_code = t1.aa_code
                AND ABS(DATEDIFF(DAY, t1.dt_oper, pt.date_time)) <= 1
        INNER JOIN  (
                        SELECT primary_object,
                            secondary_object
                        FROM dbo.object_relation
                        WHERE relation_type_id = 143
                    ) tr
            ON tr.secondary_object = pt.obj_id
        INNER JOIN dbo.acc_transactions atr
            ON atr.doc_id = tr.primary_object
                AND atr.acc_debit = t.acc_47423_id
    
    UPDATE t
    SET t.pp_doc_id = rt.primary_object
    FROM #tmp t
        INNER JOIN  ( 
                        SELECT DISTINCT id, dt_oper, aa_code
                        FROM #tmp
                        WHERE aa_code IS NOT NULL
                    ) t1
            ON t.dt_oper = t1.dt_oper
                AND t.aa_code = t1.aa_code
        INNER JOIN  (
                        SELECT obj_id,
                            authorization_approval_code,
                            ISNULL(reply_time, request_time) AS date_time
                        FROM dbo.pcpos_transations 
                    ) pt
            ON pt.authorization_approval_code = t1.aa_code
                AND ABS(DATEDIFF(DAY, t1.dt_oper, pt.date_time)) <= 1
        INNER JOIN  (
                        SELECT tr_secondary_object  = tr.secondary_object,
                               rt_secondary_object  = rt.secondary_object,
                               primary_object       = rt.primary_object
                        FROM dbo.object_relation tr
                            INNER JOIN dbo.object_relation rt
                                ON tr.primary_object = rt.primary_object
                        WHERE tr.relation_type_id = 143
                            AND rt.relation_type_id = 3
                    ) rt
            ON rt.tr_secondary_object = pt.obj_id
        INNER JOIN dbo.acc_transactions atr
            ON atr.doc_id = rt.rt_secondary_object
                AND atr.acc_debit = t.acc_47423_id
    WHERE t.pp_doc_id IS NULL
    
    -- CyberPlat
    UPDATE t
    SET t.koef = ISNULL(kt.koef, t.koef),
        t.tran_amount = pd.sum_in_base_currency,
        t.acct_amount = pd.sum_in_base_currency
    FROM #tmp t
        INNER JOIN dbo.payment_documents pd
            ON pd.doc_id = t.pp_doc_id
                AND pd.source_id IN (7, 10)
        INNER JOIN dbo.docs dcs
            ON pd.doc_id = dcs.obj_id
                AND dcs.doc_status = 400
        INNER JOIN dbo.object_relation cr
            ON pd.doc_id = cr.secondary_object
        INNER JOIN dbo.cyberplat_payments cp
            ON cr.primary_object = cp.doc_id
        INNER JOIN dbo.cyberplat_operators co
            ON co.operator_id = cp.operator_id
        INNER JOIN pc_ref_lo_pay_koef_2_type kt
            ON co.pay_type_id = kt.pay_type_id
        INNER JOIN dbo.pc_ref_lo_pay_koef k
            ON kt.obj_id = k.obj_id
                AND dcs.doc_date >= k.begin_date
                AND (
                        k.end_date IS NULL
                        OR dcs.doc_date <= k.end_date
                    )
        INNER JOIN pc_ref_lo_pay_koef_product kp
            ON kp.obj_id = k.obj_id
                AND kp.product_id = t.product_id
    WHERE t.pp_doc_id IS NOT NULL
    
    -- Оплата ГИБДД
    UPDATE t
    SET t.koef = ISNULL(kt.koef, t.koef),
        t.tran_amount = pd.sum_in_base_currency,
        t.acct_amount = pd.sum_in_base_currency
    FROM #tmp t
        INNER JOIN dbo.payment_documents pd
            ON pd.doc_id = t.pp_doc_id
                AND (
                        pd.is_gibdd = 1
                        OR pd.budget_type_id = 2
                    )
        INNER JOIN dbo.docs AS dcs
            ON pd.doc_id = dcs.obj_id
                AND dcs.doc_status = 400
        INNER JOIN dbo.pc_ref_lo_pay_koef k
            ON dcs.doc_date >= k.begin_date
                AND (
                        k.end_date IS NULL
                        OR dcs.doc_date <= k.end_date
                    )
        INNER JOIN dbo.pc_ref_lo_pay_koef_2_type kt
            ON kt.obj_id = k.obj_id
                AND kt.pay_type_id = -100
        INNER JOIN dbo.pc_ref_lo_pay_koef_product kp
            ON k.obj_id = kp.obj_id
                AND kp.product_id = t.product_id
    WHERE t.pp_doc_id IS NOT NULL
    
    -- Повышающий/понижающий кэффициент платежей ЛО для расчета оборота по карте - ЮЛ (ТЗ T8852)
    UPDATE t
    SET t.koef = COALESCE(b.koef, k.koef, t.koef),
        t.tran_amount = pd.sum_in_base_currency,
        t.acct_amount = pd.sum_in_base_currency
    FROM #tmp t
        INNER JOIN dbo.payment_documents pd
            ON pd.doc_id = t.pp_doc_id
                AND pd.source_id IN (7, 10)     -- Канал поступления: ЛОКО Online, Мобильный банк
                AND (
                        pd.into_account_number LIKE '40[1-7]%'
                        OR pd.into_account_number LIKE '40802%'
                    )
        INNER JOIN dbo.docs dcs
            ON pd.doc_id = dcs.obj_id
                AND dcs.doc_status = 400
        INNER JOIN dbo.pc_ref_lo_pay_koef pk
            ON pk.begin_date <= dcs.doc_date
                AND (
                        pk.end_date IS NULL
                        OR pk.end_date >= dcs.doc_date
                    )
        INNER JOIN dbo.pc_ref_lo_pay_koef_2_type k
            ON k.obj_id = pk.obj_id
                -- Платежи ЮЛ
                AND k.pay_type_id = 12
        LEFT JOIN dbo.pc_ref_lo_pay_koef_4_business b
            ON b.obj_id = pk.obj_id
                AND (
                        b.tax_number = pd.payee_tax_number
                        OR EXISTS 
                        (
                            SELECT 1
                            FROM dbo.persons p
                            WHERE   p.subj_id = b.subj_id
                                AND p.tax_number = pd.payee_tax_number
                        )
                    )
    WHERE t.pp_doc_id IS NOT NULL
        AND NOT EXISTS  (                   -- Нет связи с "Платеж Cyberplat"
                       
                            SELECT 1
                            FROM dbo.objects_relations cr
                                INNER JOIN dbo.cyberplat_payments cp
                                    ON cr.primary_object = cp.doc_id
                            WHERE cr.secondary_object = pd.doc_id
                        )

    DECLARE 
        @period table
        (
            period_date date PRIMARY KEY
        )

    ;WITH cte_cnt AS
    (
        SELECT id
        FROM
            (VALUES(1), (2), (3), (4), (5), (6)) AS tmp(id)
    )
    INSERT INTO @period (period_date)
    SELECT DATEFROMPARTS(YEAR(@calc_smonth), MONTH(@calc_smonth), tmp.[day]) 
    FROM    (
                SELECT 
                    [day] = ROW_NUMBER() OVER (ORDER BY t1.id)
                FROM cte_cnt t1 
                    CROSS JOIN cte_cnt t2
            ) tmp
    WHERE tmp.[day] <= IIF(@calc_emonth > @today, DAY(@today), DAY(@calc_emonth))

    CREATE TABLE #pc_calc_data
    (
        id                  int IDENTITY(1, 1) PRIMARY KEY,
        operday             date,
        pc_id               int,
        pc_type_id          smallint,
        currency_id         int,
        account_balance     money,
        account_balance_min money,
        account_balance_max money,
        tran_amount         money,
        turn_amount         money,
        calc_amount         money,
        product_tariff_id   int
    )

    INSERT INTO #pc_calc_data
    (
        operday,
        pc_id,
        pc_type_id,
        account_balance,
        account_balance_min,
        account_balance_max,
        tran_amount,
        turn_amount,
        calc_amount,
        product_tariff_id,
        currency_id
    )
    SELECT
        operday             = ptd.period_date,
        pc_id               = ptd.pc_id,
        pc_type_id          = ptd.pc_type_id,
        account_balance     = COALESCE(pcd.base_summa, IIF(ptd.pc_currency_id = 2, aa.begin_rouble, aa.begin_currency)),
        account_balance_min = MIN(COALESCE(pcd.base_summa, IIF(ptd.pc_currency_id = 2, aa.begin_rouble, aa.begin_currency))) OVER (PARTITION BY ptd.pc_id),
        account_balance_max = MAX(COALESCE(pcd.base_summa, IIF(ptd.pc_currency_id = 2, aa.begin_rouble, aa.begin_currency))) OVER (PARTITION BY ptd.pc_id),
        tran_amount         = ISNULL(tmp.calc_amount, 0),
        turn_amount         = SUM(ISNULL(tmp.calc_amount, 0)) OVER (PARTITION BY ptd.pc_id ORDER BY ptd.period_date ASC),
        calc_amount         = ISNULL(pcd.calc_summa, 0.),
        product_tariff_id   = t.product_tariff_id,
        currency_id         = ptd.pc_currency_id
    FROM
        (
           SELECT 
                p.period_date,
                pd.pc_id,
                pd.pc_type_id,
                pd.account_id,
                pd.product_id,
                pd.pc_currency_id
            FROM @period p
                CROSS JOIN #pc_data pd
            WHERE p.period_date >= pd.oper_date_from
        ) ptd
        LEFT JOIN   (
                        SELECT
                            pt.product_id, 
                            cd.pc_account_id,
                            cd.charge_data,
                            cd.base_summa,
                            cd.calc_summa
                        FROM dbo.pc_product_charges_data cd
                            INNER JOIN dbo.pc_product_tariffes_data td
                                ON cd.tariff_row_id = td.tariff_row_id
                            INNER JOIN dbo.pc_product_tariffes pt
                                ON td.product_tariff_id = pt.product_tariff_id
                        WHERE cd.charge_data >=  @calc_smonth
                            AND cd.charge_data <= @calc_emonth
                            AND cd.tariff_row_id IS NOT NULL
                    )  pcd
            ON pcd.pc_account_id = ptd.account_id
                AND pcd.product_id = ptd.product_id
                AND pcd.charge_data = ptd.period_date
        LEFT JOIN dbo.accounts_amounts aa
            ON aa.account_id = ptd.account_id
                AND aa.operday = ptd.period_date
        LEFT JOIN   (
                        SELECT 
                            pc_id,
                            dt_oper,
                            calc_amount = SUM(ISNULL(acct_amount * koef, 0.))
                        FROM #tmp
                        WHERE koef != 0
                            AND acct_amount != 0
                        GROUP BY
                            pc_id,
                            dt_oper
                    ) tmp
            ON ptd.pc_id = tmp.pc_id
                AND ptd.period_date = tmp.dt_oper
        CROSS APPLY ( 
                        SELECT TOP(1) t.product_tariff_id
                        FROM dbo.pc_product_tariffes t
                        WHERE t.product_id = ptd.product_id 
                            AND t.from_date <= ptd.period_date
                            AND ISNULL(t.to_date, ptd.period_date) >= ptd.period_date
                            -- только действующие тарифы
                            AND EXISTS 
                            (
                                SELECT 1
                                FROM dbo.objects
                                WHERE obj_id = t.product_tariff_id
                                    AND status_id = 110
                            )
                        ORDER BY t.from_date ASC
                    ) t
    
    DECLARE 
         @koef float
     
    SET @koef = 0.01 / DATEDIFF(DAY, DATEFROMPARTS(YEAR(@calc_smonth), 1, 1), DATEFROMPARTS(YEAR(@calc_smonth) + 1, 1, 1))

    UPDATE upd
    SET upd.calc_amount         = IIF(  upd.account_balance <= 0,
                                        0., 
                                        CONVERT(money, ISNULL(ROUND(COALESCE(n.rate, 0.) * @koef * upd.account_balance, 2), 0))
                                     )
    FROM #pc_data pd
        INNER JOIN #pc_calc_data upd
            ON upd.pc_id = pd.pc_id
        INNER JOIN  (   
                        SELECT 
                            operday,
                            pc_id,
                            turn_amount = MAX(turn_amount) OVER(PARTITION BY pc_id)
                        FROM #pc_calc_data
                    ) d
            ON upd.operday = d.operday
                AND upd.pc_id = d.pc_id
        -- Тип по новой схеме расчет тарифа
        OUTER APPLY (
                        SELECT TOP(1) f.rate
                        FROM dbo.pc_product_tariffes_data f
                        WHERE f.product_tariff_id = upd.product_tariff_id
                            AND f.currency_id = upd.currency_id
                            AND f.pc_type_id = upd.pc_type_id
                            AND f.tariff_type_id = 1
                            AND f.sum_turnover <= d.turn_amount
                            AND f.limit_summa <= upd.account_balance_min 
                            AND f.max_rest >= upd.account_balance_max
                        ORDER BY f.limit_summa DESC, 
                            f.max_rest,
                            f.sum_turnover DESC
                    ) n
    WHERE pd.tariff_obj_id != 863
        AND pd.was_accrued = 0

    UPDATE upd
    SET upd.calc_amount         = IIF(  upd.account_balance <= 0,
                                        0., 
                                        CONVERT(money, ISNULL(ROUND(COALESCE(o.rate, 0.) * @koef * upd.account_balance, 2), 0))
                                     )
    FROM #pc_data pd
        INNER JOIN #pc_calc_data upd
            ON upd.pc_id = pd.pc_id
        OUTER APPLY (
                        SELECT TOP(1) f.rate
                        FROM dbo.pc_product_tariffes_data f
                        WHERE f.product_tariff_id = upd.product_tariff_id
                            AND f.tariff_type_id = 0
                            AND f.currency_id = upd.currency_id
                            AND f.limit_summa >= upd.account_balance_min
                        ORDER BY f.limit_summa
                    ) o
    WHERE pd.tariff_obj_id = 863
        AND pd.was_accrued = 0

    /*
    UPDATE upd
    SET upd.calc_amount         = IIF(  upd.account_balance/*d.account_balance*/ <= 0,
                                        0, 
                                        CONVERT(money, ISNULL(ROUND(COALESCE(n.rate, o.rate, 0.) * @koef * upd.account_balance /*d.account_balance*/, 2), 0))
                                     )
    FROM #pc_data pd
        INNER JOIN #pc_calc_data upd
            ON upd.pc_id = pd.pc_id
        INNER JOIN  (   
                        SELECT 
                            operday,
                            pc_id,
                            --pc_type_id,
                            --account_balance_min,
                            --account_balance_max,
                            --product_tariff_id,
                            --account_balance,
                            turn_amount = MAX(turn_amount) OVER(PARTITION BY pc_id)
                        FROM #pc_calc_data 
                    ) d
            ON upd.operday = d.operday
                AND upd.pc_id = d.pc_id
        -- Тип по новой схеме расчет тарифа
        OUTER APPLY (
                        SELECT TOP(1) f.rate
                        FROM dbo.pc_product_tariffes_data f
                        WHERE f.product_tariff_id = upd.product_tariff_id --d.product_tariff_id
                            AND f.currency_id = upd.currency_id
                            AND f.pc_type_id = upd.pc_type_id
                            AND f.tariff_type_id = 1
                            AND f.sum_turnover <= d.turn_amount
                            AND f.limit_summa <= upd.account_balance_min --d.account_balance_min
                            AND f.max_rest >= upd.account_balance_max --d.account_balance_max
                        ORDER BY f.limit_summa DESC, 
                            f.max_rest,
                            f.sum_turnover DESC
                    ) n
        --Тип по старой схеме расчет тарифа
        OUTER APPLY (
                        SELECT TOP(1) f.rate
                        FROM dbo.pc_product_tariffes_data f
                        WHERE f.product_tariff_id = upd.product_tariff_id --d.product_tariff_id
                            AND f.tariff_type_id = 0
                            AND f.currency_id = upd.currency_id
                            AND f.limit_summa >=  upd.account_balance_min --d.account_balance_min
                        ORDER BY f.limit_summa
                    ) o
        WHERE pd.was_accrued = 0
        */

--******************************************************************************
--расчет расчет кэшбэков
--******************************************************************************
    DECLARE 
        @trans_codes table
        (
            trans_code varchar(3)
        )
    
    INSERT INTO @trans_codes (trans_code)  
    SELECT DISTINCT tc.trans_code
    FROM dbo.pc_transaction_code_aplication tca 
        INNER JOIN dbo.pc_transaction_codes tc 
            ON tc.obj_id = tca.obj_id
    WHERE tca.type_aplication = 1   -- Начисление %
        AND tca.status_id > 0       -- В действии
        AND tca.from_date <= @calc_emonth
        AND ISNULL(tca.to_date, @calc_emonth) >= @calc_emonth

    CREATE TABLE #pc_cashback_data
    (
        id                      int IDENTITY (1, 1) PRIMARY KEY,
        pc_id                   int,
        mcc_code                varchar(5),
        tran_code               varchar(3),
        tran_amount             money,
        tran_amount_rub         money,
        rate_of_currency        numeric(15, 5),
        obj_id                  int,
        min_operation_sum       money,
        min_sum                 money,
        max_sum                 money,
        begin_date              smalldatetime,
        end_date                smalldatetime,
        action_name             varchar(255),
        tran_currency_id        int,
        rate                    numeric(5, 2)
    )

    INSERT INTO #pc_cashback_data
    (
        pc_id,
        mcc_code,
        tran_code,
        tran_amount,
        tran_amount_rub,
        rate_of_currency,  
        obj_id,            
        min_operation_sum, 
        min_sum,           
        max_sum,           
        begin_date,        
        end_date,          
        action_name,       
        tran_currency_id,
        rate 
    )
    SELECT
        d.pc_id,
        d.mcc_code,
        d.tran_code,
        d.tran_amount,
        tran_amount_rub = d.tran_amount * ISNULL(r.rate_of_currency, 1), -- Сумма операции в рублях
        rate_of_currency = ISNULL(r.rate_of_currency, 1),
        p.obj_id,
        p.min_operation_sum,
        p.min_sum,
        p.max_sum,
        p.begin_date,
        p.end_date,
        p.action_name,
        d.tran_currency_id,
        pcp.rate
    FROM #pc_data pd
        INNER JOIN #tmp d
            ON d.pc_id = pd.pc_id
        INNER JOIN @trans_codes tc
            ON d.tran_code = tc.trans_code
        INNER JOIN pc_ref_cash_back_tran_code_product_jnt pp
            ON pp.product_id = d.product_id
        INNER JOIN dbo.pc_ref_cash_back_tran_code_jnt p
            ON pp.obj_id = p.obj_id
        INNER JOIN dbo.pc_ref_cash_back_tran_code_param_jnt pcp
            ON pcp.code_transaction = d.tran_code
                AND p.obj_id = pcp.obj_id
                AND (
                        pcp.MCC_code_transaction_in IS NULL
                        OR pcp.MCC_code_transaction_in = d.mcc_code
                    )
        LEFT JOIN dbo.exchanges_rates r
            ON r.currency_id = d.tran_currency_id
                AND r.begin_date = @calc_emonth
    WHERE pd.without_cashback = 0
        AND p.begin_date <= d.dt_oper
        AND ISNULL(p.end_date, d.dt_oper) >= d.dt_oper
        AND d.mcc_code NOT LIKE '%' + ISNULL(p.MCC_code_transaction_out, '-') + '%'
        AND (
                p.action_name IS NULL
                OR  (
                        -- По акциям за месяц - 1 также, как в текущем периоде
                        DATEDIFF(month, @calc_emonth, @today) <= 1 
                        AND p.action_name IS NOT NULL
                    )
            )

    CREATE TABLE #result
    (
        pc_id int PRIMARY KEY,
        limit_balance decimal(19, 2),
        turn_amount decimal(19, 2), 
        is_turnover tinyint, 
        is_min_balance tinyint,
        calc_amount decimal(19, 2), 
        cb_amount decimal(19, 2),
        cba_amount decimal(19, 2),
        was_accrued tinyint
    )

    INSERT INTO #result
    (
        pc_id,
        limit_balance,
        turn_amount, 
        is_turnover, 
        is_min_balance,
        calc_amount, 
        cb_amount,
        cba_amount,
        was_accrued
    )
    SELECT DISTINCT 
           pc_id            = pcd.pc_id,
           limit_balance    = IIF( pd.tariff_obj_id != 863,
                                   ISNULL(ca.limit_summa, 0.),
                                   0.
                                 ),
           turn_amount      = IIF(  pd.tariff_obj_id != 863,
                                    IIF(   pd.main_card = 1 AND pd.was_accrued = 1,
                                         pd.turn_amount,
                                         COALESCE(SUM(pcd.tran_amount) OVER (PARTITION BY pcd.pc_id), 0.)
                                       ),
                                    0.
                                 ),
           is_turnover      = IIF(  pd.tariff_obj_id != 863,
                                    IIF(  ca.sum_turnover > IIF(pd.main_card = 1 AND pd.was_accrued = 1,
                                          pd.turn_amount,
                                          COALESCE(SUM(pcd.tran_amount) OVER (PARTITION BY pcd.pc_id), 0.)), 0, 1
                                       ),
                                    0.
                                 ),
           is_min_balance   = IIF(  pd.tariff_obj_id != 863,
                                    MIN(IIF(pcd.account_balance BETWEEN ca.limit_summa AND ca.max_rest, 1, 0)) OVER (PARTITION BY pcd.pc_id),
                                    0.
                                 ),
           calc_amount      = IIF(  pd.main_card = 1,
                                    COALESCE(SUM(pcd.calc_amount) OVER (PARTITION BY pcd.pc_id), 0.),
                                    0.
                                 ),
           cb_amount        = IIF(  pd.main_card = 1,
                                    COALESCE(pd.cb_amount, cb.cb_amount, 0.),
                                    0.
                                 ) ,
           cba_amount       = IIF(  pd.main_card = 1,
                                    COALESCE(pd.cba_amount, cb.cba_amount, 0.),
                                    0.
                                 ),
           was_accrued = pd.was_accrued
    FROM #pc_data pd
        INNER JOIN #pc_calc_data pcd
            ON pcd.pc_id = pd.pc_id
                AND pcd.operday <= @today
        OUTER APPLY (   
                        SELECT TOP(1) limit_summa, max_rest, sum_turnover
                        FROM dbo.pc_product_tariffes_data t
                        WHERE product_tariff_id = pcd.product_tariff_id
                            AND currency_id = pcd.currency_id
                            AND pc_type_id = pcd.pc_type_id
                        ORDER BY rate DESC
                    ) ca
        LEFT JOIN   (
                        SELECT DISTINCT
                            pr.pc_id,
                            cb_amount = CONVERT(    decimal(19,2),
                                                    CASE 
                                                        WHEN pr.cb_tran_amount < pr.cb_min_sum
                                                            THEN pr.cb_min_sum
                                                        WHEN pr.cb_tran_amount > pr.cb_max_sum
                                                            THEN pr.cb_max_sum
                                                        ELSE pr.cb_tran_amount
                                                    END
                                               ),
                            cba_amount = CONVERT(   decimal(19,2), 
                                                    SUM(   CASE 
                                                                WHEN pr.cba_tran_amount < pr.cba_min_sum
                                                                    THEN pr.cba_min_sum
                                                                WHEN pr.cba_tran_amount > pr.cba_max_sum
                                                                    THEN pr.cba_max_sum
                                                                ELSE pr.cba_tran_amount
                                                            END
                                                        ) 
                                                        OVER (PARTITION BY pr.pc_id)
                                                )
                        FROM
                        (
                            SELECT 
                                tr.pc_id,
                                cb_turnover_amount = IIF(   tr.action_name IS NULL,
                                                            SUM(tran_amount_rub) OVER (PARTITION BY tr.pc_id),
                                                            0.
                                                        ),
                                cb_min_sum = IIF(   tr.action_name IS NULL,
                                                    IIF(    tr.tran_currency_id = 2,
                                                            MIN(tr.min_sum) OVER (PARTITION BY tr.pc_id), 
                                                            MIN(tr.min_sum) OVER (PARTITION BY tr.pc_id) / ISNULL(tr.rate_of_currency, 1.)
                                                       ), 
                                                    0.
                                                ),
                                cb_max_sum = IIF(   tr.action_name IS NULL,
                                                    IIF(    tr.tran_currency_id = 2,
                                                            MAX(tr.max_sum) OVER (PARTITION BY tr.pc_id),
                                                            MAX(tr.max_sum) OVER (PARTITION BY tr.pc_id) / ISNULL(tr.rate_of_currency, 1.)
                                                       ),
                                                    0.
                                                ),
                                cb_tran_amount = IIF(   tr.action_name IS NULL,
                                                        SUM(tr.tran_amount * tr.rate / 100.) OVER (PARTITION BY tr.pc_id, tr.tran_currency_id),
                                                        0.
                                                    ),
                                cba_turnover_amount = IIF(  tr.action_name IS NOT NULL,
                                                            SUM(tran_amount_rub) OVER (PARTITION BY tr.pc_id, tr.obj_id),
                                                            0.
                                                         ),
                                cba_min_sum = IIF(  tr.action_name IS NOT NULL,
                                                    IIF(    tr.tran_currency_id = 2,
                                                            MIN(tr.min_sum) OVER (PARTITION BY tr.pc_id, tr.obj_id), 
                                                            MIN(tr.min_sum) OVER (PARTITION BY tr.pc_id, tr.obj_id) / ISNULL(tr.rate_of_currency, 1.)
                                                       ), 
                                                    0.
                                                ),
                                cba_max_sum = IIF(   tr.action_name IS NOT NULL,
                                                     IIF(    tr.tran_currency_id = 2,
                                                             MAX(tr.max_sum) OVER (PARTITION BY tr.pc_id, tr.obj_id),
                                                             MAX(tr.max_sum) OVER (PARTITION BY tr.pc_id, tr.obj_id) / ISNULL(tr.rate_of_currency, 1.)
                                                        ),
                                                     0.
                                                 ),
                                cba_tran_amount = IIF(   tr.action_name IS NOT NULL,
                                                         SUM(tr.tran_amount * tr.rate / 100.) OVER (PARTITION BY tr.pc_id, tr.obj_id, tr.tran_currency_id),
                                                         0.
                                                     )
                            FROM #pc_cashback_data tr
                                INNER JOIN #pc_data pd
                                    ON tr.pc_id = pd.pc_id
                            WHERE pd.tariff_obj_id != 863
                        ) pr
                    ) cb
                        ON pd.pc_id = cb.pc_id

    /*
    SELECT @trancount = @@TRANCOUNT
    IF @trancount = 0
        BEGIN TRANSACTION

    ;MERGE dbo.pc_dwh_cashback_turnover AS trg
    USING #result AS src
    ON trg.pc_id = src.pc_id
        AND trg.date_value = @calc_smonth 
    WHEN MATCHED
        THEN UPDATE SET cashback_sum        = src.cb_amount, 
                        cashback_action_sum = src.cba_amount,
                        charge_summa        = src.calc_amount,
                        sum_turnover        = src.turn_amount,
                        is_min_sum          = src.is_min_balance,
                        is_turnover         = src.is_turnover,
                        min_summa           = src.limit_balance,
                        modify_datetime     = GETDATE(),
                        is_payed            = src.was_accrued
    WHEN NOT MATCHED BY TARGET THEN
        INSERT 
        (
            pc_id,
            date_value,
            cashback_sum,
            cashback_action_sum,
            charge_summa,
            sum_turnover,
            is_min_sum,
            is_turnover,
            min_summa,
            modify_datetime,
            is_payed
        )
        VALUES
        (
            src.pc_id,
            @calc_smonth,
            src.cb_amount,
            src.cba_amount,
            src.calc_amount,
            src.turn_amount,
            src.is_min_balance,
            src.is_turnover,
            src.limit_balance,
            GETDATE(),
            src.was_accrued
        );

    IF @@ERROR != 0
    BEGIN
        SET @err_msg = 'Ошибка обновления таблицы pc_dwh_cashback_turnover'
        GOTO EXIT_ERROR
    END

    IF @trancount = 0
        COMMIT TRANSACTION
    */
    
    --SELECT * FROM #pc_data
    --SELECT * FROM #tmp
    --SELECT * FROM #pc_calc_data
    --SELECT * FROM #pc_cashback_data
    SELECT * FROM #result
    RETURN 0

EXIT_ERROR:
    IF @trancount = 0
        ROLLBACK TRANSACTION

    SELECT @err_msg = 'pc_tariff_results_calc: ' + @err_msg
    EXEC dbo.sp_raiserror @err_msg
    
    RETURN 1
END