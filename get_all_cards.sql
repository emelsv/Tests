SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

    DECLARE
        @today date = '20170930', --GETDATE(),--,
        @calc_somonth date,
        @calc_eomonth date
    
    SELECT 
        @calc_somonth   = DATEFROMPARTS(YEAR(@today), MONTH(@today), 1),
        @calc_eomonth   = EOMONTH(@calc_somonth)

    --SELECT 
        --@today,
        --@calc_somonth,
        --@calc_eomonth

--**********************************************************************************************************************    
--выборка действующих пластиковых карт

     IF OBJECT_ID ('tempdb..#pc_data') IS NULL
        CREATE TABLE #pc_data
        (
            pc_id int NOT NULL,                     --идентификатор карты
            pc_contract_id int NOT NULL,            --идентификатор контракта
            pc_type_id smallint NOT NULL,           --идентификатор типа карты
            account_id int NOT NULL,                --идентификатор счета
            without_cashback tinyint NOT NULL,      --карта без кэшбека(1)/с кэшбеком(0)
            main_card tinyint NOT NULL,             --основная(1)/дополнительная(0) карта
            oper_date_from smalldatetime NOT NULL,  --операции с
            oper_date_to smalldatetime NOT NULL,    --операции по
            currency_id smallint NOT NULL           --идентификатор валюты
            CONSTRAINT PK_#pc_data PRIMARY KEY
            (
                pc_id,
                account_id
            ) 
        )
     ELSE
        TRUNCATE TABLE #pc_data;

    ;WITH cte_pc
    AS
    (
    SELECT
        pc_id       = c.pc_id,
        pc_contract_id = c.pc_contract_id,
        pc_type_id = c.pc_type_id,
        account_id  = ISNULL(ac.account_id, -1),
        without_cashback = IIF(pl.pc_id IS NULL, 1, 0),
        main_card = IIF(ppl.pc_parent IS NULL, 1, 0),
        oper_date_from = ac.oper_date_from,
        oper_date_to = ac.oper_date_to
    FROM (   
            SELECT pc.pc_id,
                   pc.pc_contract_id,
                   pc.pc_type_id
            FROM dbo.pc pc
                INNER JOIN  (
                                SELECT subj_id = u.subj_id
                                FROM dbo.co_users u
                                where parent_id IS NULL
                                UNION ALL
                                SELECT subj_id = l.customer_id
                                FROM dbo.ibc_logins l
                            ) l
                    ON pc.pc_holder = l.subj_id
                --LEFT JOIN dbo.pc_dwh_cashback_turnover d
                    --ON d.pc_id = pc.pc_id
                        --AND d.date_value = @calc_somonth
            WHERE pc.pc_date_from <= @calc_eomonth
               AND ISNULL(pc.pc_date_to, @calc_somonth) >= @calc_somonth
               --AND d.id IS NULL
               --AND ISNULL(pc.pc_no, '') <> ''
            GROUP BY pc.pc_id,
                   pc.pc_contract_id,
                   pc.pc_type_id
          ) c
          INNER JOIN dbo.objects o
            ON o.obj_id = c.pc_id
          OUTER APPLY (
                        SELECT
                            pc_contract_id, 
                            account_id,
                            oper_date_from = IIF(pc_date_from < @calc_somonth, @calc_somonth, pc_date_from),
                            oper_date_to = IIF(pc_date_to IS NULL OR pc_date_to > @calc_eomonth, @calc_eomonth, pc_date_to)
                        FROM dbo.pc_accounts_history
                        WHERE pc_date_from  <= @calc_eomonth
                            AND ISNULL(pc_date_to, @calc_somonth) >= @calc_somonth  
                            AND pc_contract_id = c.pc_contract_id
                     ) ac
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
    WHERE o.status_id = 717
    )
    INSERT INTO #pc_data
    SELECT  --TOP(1000) 
        pc.*,
        a.currency_id
    FROM cte_pc pc
        INNER JOIN dbo.accounts a
            ON pc.account_id = a.account_id 
    WHERE pc.account_id > 0
        AND pc.pc_id = 1004374331--1032737204 --1009174452
    
    --pc_id = 1032737204, 1009174452
    --pc_contract_id = 1009174453

--**********************************************************************************************************************    
    --расчет оборотов

    IF OBJECT_ID ('tempdb..#tmp') IS NULL
    BEGIN
        CREATE TABLE #tmp 
        (
            --id              int IDENTITY (1, 1) PRIMARY KEY,
            pc_id           int NOT NULL,
--            pc_info         varchar(255),
--            acc_credit      int,
            acc_debit       int,
            dt_oper         date NOT NULL,
            aa_code         char(6),
            --dt_treat        datetime,
            --[type]          tinyint,
            doc_id          int NOT NULL,
            no_in_doc       int NOT NULL,
            pp_doc_id       int,
            product_id      int,
            acc_47423_id    int,
            pc_contract_id  int,
--            tran_info       varchar(255),
            tran_cur_id     int,
--            tran_cur        varchar(3),
            tran_sum        money,
            acct_sum        money,
--            into_sum        money,
            koef            numeric(12, 5) DEFAULT(0),
            mcc_code        char(4),
            --calc_sum        AS CONVERT(money, acct_sum * koef)
            tran_code       char(2)
        )

    END
    ELSE
        TRUNCATE TABLE #tmp;

    --вставка транзакций
    INSERT INTO #tmp
    (
        pc_id,
--        acc_credit,
        acc_debit, 
        dt_oper,
        --dt_treat,
        tran_cur_id,
        --t_curr.c
        tran_sum,
        acct_sum,
        --into_sum,
        --[type],
        doc_id,
        no_in_doc 
    )
    /*
    SELECT
        pc_id = pd.pc_id,
        acc_credit = t.acc_credit,
        acc_debit = t.acc_debit,
        dt_oper = t.acc_tran_date,
        --dt_treat = IIF(t.acc_tran_status = 30, t.acc_tran_date, NULL),
        tran_cur_id = ISNULL(t.acc_tran_currency_id, 2),
        --t_curr.currency_s_name,
        tran_sum = t.acc_tran_currency_sum,
        acct_sum = IIF(t.acc_debit = pd.account_id, t.acc_tran_currency_sum, NULL), --NULL -- обработка проводок переноса
        into_sum = t.acc_tran_currency_sum,
        --[type] = 1,
        doc_id = t.doc_id,
        no_in_doc = t.no_in_doc
    FROM dbo.acc_transactions t
        INNER JOIN #pc_data pd
            ON t.acc_credit = pd.account_id
    WHERE t.acc_tran_currency_sum <> 0
        AND t.acc_tran_date >= pd.oper_date_from 
        AND t.acc_tran_date < DATEADD(dd, 1, pd.oper_date_to)
    UNION ALL
    */
    SELECT
        pc_id = pd.pc_id,
--        acc_credit = t.acc_credit,
        acc_debit = t.acc_debit,
        dt_oper = t.acc_tran_date,
        --dt_treat = IIF(t.acc_tran_status = 30, t.acc_tran_date, NULL),
        tran_cur_id = ISNULL(t.acc_tran_currency_id, 2),
        --t_curr.currency_s_name,
        tran_sum = t.acc_tran_currency_sum,
        acct_sum = t.acc_tran_currency_sum,
        --into_sum = IIF(t.acc_credit = pd.account_id, t.acc_tran_currency_sum, NULL), --NULL, -- обработка проводок переноса
        --[type] = 2,
        doc_id = t.doc_id,
        no_in_doc = t.no_in_doc
    FROM #pc_data pd
        INNER JOIN dbo.acc_transactions t
            ON t.acc_debit = pd.account_id
    WHERE t.acc_tran_currency_sum <> 0
        AND t.acc_tran_date >= pd.oper_date_from 
        AND t.acc_tran_date < DATEADD(mm, 1, pd.oper_date_to)

    /*
    CREATE INDEX ix_#tmp_pp_doc_id 
    ON #tmp
    (
        pp_doc_id
    )
    INCLUDE
    (
        pc_id,
        dt_oper,
        aa_code,
        doc_id,
        no_in_doc,
        acc_47423_id,
        acct_sum,
        koef
    )
    */

    -- обработка дополнительных карт
    DELETE #tmp
    FROM #tmp t
        INNER JOIN #pc_data p
            ON t.pc_id = p.pc_id
    WHERE p.main_card = 0
        AND NOT EXISTS (
            SELECT 1
            FROM dbo.pc_proc_card_data c
                INNER JOIN dbo.objects_relations_2_trans r
                    ON r.primary_object = c.pc_proc_card_data_id
                        AND r.doc_id = t.doc_id
                        AND r.no_in_doc = t.no_in_doc
                        AND r.relation_type_id = 52
            WHERE c.pc_id = p.pc_id
           )

    /*
    -- обработка проводок переноса
    UPDATE #tmp
    SET acct_sum = t.into_sum
    FROM #tmp t
    WHERE t.acct_sum IS NULL
        AND t.acc_debit IN (SELECT account_id FROM #pc_data)

    UPDATE #tmp
    SET into_sum = t.acct_sum
    FROM #tmp t
    WHERE t.into_sum IS NULL
        AND t.acc_credit IN (SELECT account_id FROM #pc_data)
    */

    -- обновляем информацию о транзакции
    UPDATE #tmp
    SET dt_oper   = ISNULL(dcs.doc_date, d.transaction_time),
        aa_code   = d.authorization_approval_code,
        tran_sum  = IIF(d.fee_amount = t.acct_sum, d.fee_amount, d.transaction_amount),
        pc_id = c.pc_id,
        koef = IIF (
                        EXISTS 
                        (
                            SELECT 1
                            FROM dbo.pc_transaction_codes
                            WHERE trans_code = d.code_transaction
                        ), 
                        1, 
                        t.koef
                    ),
        mcc_code = d.merchant_category_code,
        tran_code = d.code_transaction
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
        LEFT JOIN dbo.pcpos_transations ptr
                INNER JOIN dbo.objects_relations orl
                    ON orl.secondary_object = ptr.obj_id
                    AND orl.relation_type_id = 143
                INNER JOIN dbo.docs dcs
                    ON orl.primary_object = dcs.obj_id
            ON ptr.authorization_approval_code = d.authorization_approval_code
                AND ABS(DATEDIFF(HOUR, t.dt_oper, ISNULL(ptr.reply_time, ptr.request_time))) < 24
    WHERE r.relation_type_id = 52
        AND NOT EXISTS 
        (
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
    WHERE dt_oper < @calc_somonth 
        OR dt_oper >= DATEADD(dd, 1, @calc_eomonth )

    --определяем идентификатор продукта
    ;WITH cte AS (
        SELECT
            pp.pc_id,
            pp.product_id,
            pp.begin_date,
            end_date = (
                SELECT TOP(1) in_pp.begin_date
                FROM dbo.pc_prodlist in_pp
                WHERE in_pp.pc_id = pp.pc_id
                    AND in_pp.begin_date > pp.begin_date
                ORDER BY in_pp.begin_date
            )
        FROM dbo.pc_prodlist pp
    )
    UPDATE #tmp
    SET product_id = c.product_id
    FROM #tmp t
        INNER JOIN cte c
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

    -- см. pc_proc_ucs_tran_treat
    
    UPDATE t
    SET t.pp_doc_id = tr.primary_object
    FROM #tmp t
        INNER JOIN 
        (
            SELECT obj_id,
                authorization_approval_code,
                ISNULL(reply_time, request_time) AS date_time
            FROM dbo.pcpos_transations 
        ) pt
            ON pt.authorization_approval_code = t.aa_code
                AND ABS(DATEDIFF(DAY, t.dt_oper, pt.date_time)) <= 1
        INNER JOIN 
        (
            SELECT primary_object,
                secondary_object
            FROM dbo.object_relation
            WHERE relation_type_id = 143
        ) tr
            ON tr.secondary_object = pt.obj_id
        INNER JOIN dbo.acc_transactions atr
            ON atr.doc_id = tr.primary_object
                AND atr.acc_debit = t.acc_47423_id
    OPTION (LOOP JOIN)

    UPDATE t
    SET t.pp_doc_id = rt.primary_object
    FROM #tmp t
        INNER JOIN 
        (
            SELECT obj_id,
                authorization_approval_code,
                ISNULL(reply_time, request_time) AS date_time
            FROM dbo.pcpos_transations 
        ) pt
            ON pt.authorization_approval_code = t.aa_code
                AND ABS(DATEDIFF(DAY, t.dt_oper, pt.date_time)) <= 1
        INNER JOIN 
        (
            SELECT primary_object,
                secondary_object
            FROM dbo.object_relation
            WHERE relation_type_id = 143
        ) tr
            ON tr.secondary_object = pt.obj_id
        INNER JOIN 
        (
            SELECT primary_object,
                secondary_object
            FROM dbo.object_relation
            WHERE relation_type_id = 3
        ) rt
            ON rt.primary_object = tr.primary_object 
        INNER JOIN dbo.acc_transactions atr
            ON atr.doc_id = rt.secondary_object
                AND atr.acc_debit = t.acc_47423_id
    WHERE t.pp_doc_id IS NULL
    OPTION (LOOP JOIN)

    -- CyberPlat
    UPDATE t
    SET t.koef = ISNULL(kt.koef, t.koef),
        t.tran_sum = pd.sum_in_base_currency,
        t.acct_sum = pd.sum_in_base_currency
    FROM #tmp t
        INNER JOIN dbo.payment_documents pd
            ON pd.doc_id = t.pp_doc_id
                AND pd.source_id IN (7, 10)
        INNER JOIN dbo.docs AS dcs
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
                AND 
                (
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
        t.tran_sum = pd.sum_in_base_currency,
        t.acct_sum = pd.sum_in_base_currency
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
        t.tran_sum = pd.sum_in_base_currency,
        t.acct_sum = pd.sum_in_base_currency
    FROM #tmp t
        INNER JOIN dbo.payment_documents pd
            ON pd.doc_id = t.pp_doc_id
                AND pd.source_id IN (7, 10)     -- Канал поступления: ЛОКО Online, Мобильный банк
                AND (
                    pd.into_account_number LIKE '40[1-7]%'
                    OR pd.into_account_number LIKE '40802%'
                )
        INNER JOIN dbo.docs AS dcs
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
                AND 
                (
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
        AND NOT EXISTS                      -- Нет связи с "Платеж Cyberplat"
        (
            SELECT 1
            FROM dbo.objects_relations cr
                INNER JOIN dbo.cyberplat_payments cp
                    ON cr.primary_object = cp.doc_id
            WHERE cr.secondary_object = pd.doc_id
        )

    INSERT INTO #pc_data
    SELECT pc.*, a.currency_id
    FROM
        (
            SELECT 
                pc.pc_id,
                pc.pc_contract_id,
                pc.pc_type_id,
                account_id  = ac.account_id,
                without_cashback = IIF(pl.pc_id IS NULL, 1, 0),
                main_card = IIF(ppl.pc_parent IS NULL, 1, 0),
                oper_date_from = ac.oper_date_from,
                oper_date_to = ac.oper_date_to
            FROM (  SELECT DISTINCT t.pc_id
                    FROM #tmp t
                        LEFT JOIN #pc_data pd
                            ON t.pc_id = pd.pc_id
                    WHERE pd.pc_id IS NULL
                 ) p
                 INNER JOIN dbo.pc pc
                    ON p.pc_id = pc.pc_id
                 OUTER APPLY (
                                SELECT
                                    pc_contract_id, 
                                    account_id,
                                    oper_date_from = IIF(pc_date_from < @calc_somonth, @calc_somonth, pc_date_from),
                                    oper_date_to = IIF(pc_date_to IS NULL OR pc_date_to > @calc_eomonth, @calc_eomonth, pc_date_to)
                                FROM dbo.pc_accounts_history
                                WHERE pc_date_from  <= @calc_eomonth
                                    AND ISNULL(pc_date_to, @calc_somonth) >= @calc_somonth  
                                    AND pc_contract_id = pc.pc_contract_id
                             ) ac
                  LEFT JOIN (
                                SELECT d.pc_id
                                FROM dbo.pc_prodlist d
                                    INNER JOIN pc_ref_cash_back_tran_code_product jp
                                        ON d.product_id = jp.product_id
                                WHERE jp.obj_id = 207
                                GROUP BY d.pc_id
                            ) pl
                      ON pc.pc_id = pl.pc_id
                  LEFT JOIN dbo.pc_pc_linked ppl
                    ON pc.pc_id = ppl.pc_child
        ) pc
    INNER JOIN dbo.accounts a
        ON pc.account_id = a.account_id
    
    
    IF OBJECT_ID ('tempdb..#pc_turnover_data') IS NULL
        CREATE TABLE #pc_turnover_data 
        (
            pc_id int,
            pc_contract_id int,
            pc_type_id smallint,
            account_id int,
            currency_id smallint,
            product_id int--, 
            --turnover_amount money
        )
    ELSE
        TRUNCATE TABLE #pc_turnover_data;
    
    INSERT INTO #pc_turnover_data
    SELECT  
            t.pc_id,
            t.pc_contract_id,
            pd.pc_type_id,
            t.account_id,
            pd.currency_id,
            t.product_id--, 
            --t.turnover_amount
    FROM
        (
            SELECT DISTINCT
                pc_id,
                pc_contract_id,
                account_id = acc_debit,
                product_id--,
                --total_sum = SUM(ISNULL(acct_sum, 0)) OVER (PARTITION BY t.pc_contract_id),  -- [ВСЕГО_сумма_операций]
                --turnover_amount = SUM(ISNULL(calc_sum, 0)) OVER (PARTITION BY pc_contract_id)   -- [ВСЕГО_расчетная_сумма]        
            FROM #tmp
        ) t
        INNER JOIN #pc_data pd
            ON t.pc_id = pd.pc_id

--**********************************************************************************************************************
--расчет остатков счетов
    
    /*
    IF OBJECT_ID ('tempdb..#pc_account_balance') IS NULL
        CREATE TABLE #pc_account_balance
        (
            pc_id int NOT NULL,                     --идентификатор карты
            charge_date date NOT NULL,              --дата
            account_id int NOT NULL,                --идентификатор счета
            account_balance money NOT NULL,         --остаток счета
            min_account_balance money NOT NULL,     --минимальный остаток счета в периоде
            max_account_balance money NOT NULL,     --максимальный остаток счета в периоде
            rate numeric(12, 5) NOT NULL,           --основная(1)/дополнительная(0) карта
            calc_amount money NOT NULL,             --начисленная сумма на дату
            calc_amount_total money NOT NULL        --итоговая начисленная сумма за период
        )
     ELSE
        TRUNCATE TABLE #pc_account_balance;
    
    INSERT INTO #pc_account_balance
    SELECT
        pd.pc_id, 
        charge_data = CONVERT(date, t2a.charge_data, 104),
        t2a.account_id,
        t.base_summa,
        min_account_balance = MIN(t.base_summa) OVER (PARTITION BY pd.pc_id),
        max_account_balance = MAX(t.base_summa) OVER (PARTITION BY pd.pc_id),
        f.rate,
        t.calc_summa,
        calc_final = SUM(t.calc_summa) OVER (PARTITION BY pd.pc_id)
    FROM #pc_data pd
        INNER JOIN (
            SELECT DISTINCT 
                account_id = pc_account_id,
                charge_data
            FROM dbo.pc_product_charges_data
            WHERE charge_data >= @calc_somonth
                AND charge_data <= @calc_eomonth
         ) t2a
            ON pd.account_id = t2a.account_id
        CROSS APPLY (
                        SELECT TOP(1) t1.pc_charge_id
                        FROM dbo.pc_product_charges_data t1
                        WHERE t1.pc_account_id = pd.account_id
                            AND t1.charge_data = t2a.charge_data
                        ORDER BY 
                            ISNULL(t1.tariff_row_id, 0) DESC,    -- в приоритете данные с тарифом
                            t1.pc_charge_id DESC                 -- а среди них - последний расчёт
                    ) t2
        INNER JOIN dbo.pc_product_charges_data t
            ON t2.pc_charge_id = t.pc_charge_id
                AND t2a.charge_data = t.charge_data 
        LEFT JOIN dbo.pc_product_tariffes_data f
            ON t.tariff_row_id = f.tariff_row_id

    SELECT * FROM #pc_account_balance
    TRUNCATE TABLE #pc_account_balance
    */

    IF OBJECT_ID('tempdb..#pc_calc_data') IS NULL
        CREATE TABLE #pc_calc_data
        (
            operday             date    NOT NULL,
            pc_id               int     NOT NULL,
            pc_type_id          smallint,
            currency_id         int,
            account_balance     money,
            account_balance_min money,
            account_balance_max money,
            tran_amount         money,
            turn_amount         money,
            calc_amount         money,
            --over_amount         money,
            --rate                numeric(12, 5),
            --tariff_row_id       int,
            product_tariff_id   int,
            tariff_limit_summa  money,
            tariff_sum_turnover money,
            tariff_max_rest     money
            CONSTRAINT PK_#pc_calc_data PRIMARY KEY
            (
                operday,
                pc_id
            )
        )
    ELSE 
        TRUNCATE TABLE #pc_calc_data;
    
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
        product_tariff_id,
        currency_id
    )
    SELECT
        operday = aa.operday,
        ptd.pc_id,
        ptd.pc_type_id,
        account_balance = IIF(ptd.currency_id = 2, aa.begin_rouble, aa.begin_currency),
        account_balance_min = MIN(IIF(ptd.currency_id = 2, aa.begin_rouble, aa.begin_currency)) OVER (PARTITION BY ptd.pc_id),
        account_balance_max = MAX(IIF(ptd.currency_id = 2, aa.begin_rouble, aa.begin_currency)) OVER (PARTITION BY ptd.pc_id),
        tran_amount = ISNULL(tmp.calc_sum, 0),
        turn_amount = SUM(ISNULL(tmp.calc_sum, 0)) OVER (PARTITION BY ptd.pc_id ORDER BY operday ASC),
        --turn_amount_total = SUM(ISNULL(tmp.calc_sum, 0)) OVER (PARTITION BY ptd.pc_id),
        product_tariff_id = t.product_tariff_id,
        ptd.currency_id
    FROM  #pc_turnover_data ptd
        INNER JOIN dbo.accounts_amounts aa
            ON aa.account_id = ptd.account_id
--        LEFT JOIN #pc_account_balance ab
--            ON aa.operday = ab.charge_date
        LEFT JOIN 
        (
             SELECT 
                 account_id = acc_debit,
                 dt_oper,
                 calc_sum = SUM(/*calc_sum*/acct_sum * koef)
             FROM #tmp
             WHERE koef <> 0
             GROUP BY
                 acc_debit,
                 dt_oper
        ) tmp
            ON aa.account_id = tmp.account_id
                AND aa.operday = tmp.dt_oper
        OUTER APPLY ( 
                        SELECT TOP(1) t.product_tariff_id
                        FROM dbo.pc_product_tariffes t
                        WHERE t.product_id = ptd.product_id 
                            AND t.from_date <= aa.operday
                            AND ISNULL(t.to_date, aa.operday) >= aa.operday
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
    WHERE operday >= @calc_somonth
        AND operday <= @calc_eomonth
    
    DECLARE 
         @koef float
     
    SET @koef = 0.01 / DATEDIFF(DAY, DATEFROMPARTS(YEAR(@calc_somonth), 1, 1), DATEFROMPARTS(YEAR(@calc_somonth) + 1, 1, 1))

    UPDATE upd
    SET upd.calc_amount = IIF(d.account_balance <= 0, 0, CONVERT(money, ISNULL(ROUND(ISNULL(n.rate, o.rate) * @koef * d.account_balance, 2), 0))),
        upd.tariff_limit_summa = ISNULL(n.limit_summa, o.limit_summa),
        upd.tariff_sum_turnover = ISNULL(n.sum_turnover, o.sum_turnover),
        upd.tariff_max_rest = ISNULL(n.max_rest, o.max_rest)
    FROM #pc_calc_data upd
        INNER JOIN
            (SELECT operday,
                    pc_id,
                    pc_type_id,
                    turn_amount = MAX(turn_amount) OVER(PARTITION BY pc_id),
                    account_balance_min,
                    account_balance_max,
                    product_tariff_id,
                    account_balance
              FROM #pc_calc_data 
            ) d
            ON upd.operday = d.operday
                AND upd.pc_id = d.pc_id
        -- Тип по новой схеме расчет тарифа
        OUTER APPLY (
            SELECT TOP(1) f.rate, --f.tariff_row_id 
                f.limit_summa,
                f.sum_turnover,
                f.max_rest
            FROM dbo.pc_product_tariffes_data f
            WHERE f.product_tariff_id = d.product_tariff_id
                AND f.currency_id = upd.currency_id
                AND f.pc_type_id = upd.pc_type_id
                AND f.tariff_type_id = 1
                AND f.sum_turnover <= d.turn_amount
                AND f.limit_summa <= d.account_balance_min
                AND f.max_rest >= d.account_balance_max
            ORDER BY f.limit_summa DESC, 
                f.max_rest,
                f.sum_turnover DESC
        ) n
        --Тип по старой схеме расчет тарифа
        OUTER APPLY (
            SELECT TOP(1) f.rate, --f.tariff_row_id
                f.limit_summa,
                f.sum_turnover,
                f.max_rest
            FROM dbo.pc_product_tariffes_data f
            WHERE f.product_tariff_id = d.product_tariff_id
                AND f.tariff_type_id = 0
                AND f.currency_id = upd.currency_id
                AND f.limit_summa >= d.account_balance_min
            ORDER BY f.limit_summa
        ) o
--    WHERE d.account_balance > 0

--**********************************************************************************************************************
--расчет кэшбэков
    DECLARE 
        @trans_codes table
        (
            trans_code varchar(10)
        )
    
    INSERT INTO @trans_codes   
    SELECT DISTINCT tc.trans_code
    FROM dbo.pc_transaction_code_aplication tca 
        INNER JOIN dbo.pc_transaction_codes tc 
            ON tc.obj_id = tca.obj_id
    WHERE tca.type_aplication = 1   -- Начисление %
        AND tca.status_id > 0       -- В действии
        AND tca.from_date <= @calc_eomonth
        AND ISNULL(tca.to_date, @calc_eomonth) >= @calc_eomonth

    SELECT
        d.tran_code,
        d.mcc_code,
        d.tran_sum,
        account_amount_rub = d.tran_sum * ISNULL(r.rate_of_currency, 1), -- Сумма операции в рублях
        rate_of_currency = ISNULL(r.rate_of_currency, 1),
        d.pc_id,
        p.obj_id,
        p.min_operation_sum,
        p.min_sum,
        p.max_sum,
        beg_date = p.begin_date,
        p.end_date,
        p.action_name,
        currency_id = d.tran_cur_id
    --INTO #tmp_cb
    FROM #tmp d
        INNER JOIN @trans_codes tc
            ON d.tran_code = tc.trans_code
        INNER JOIN pc_ref_cash_back_tran_code_product_jnt pp
            ON pp.product_id = d.product_id
        INNER JOIN dbo.pc_ref_cash_back_tran_code_jnt p
            ON pp.obj_id = p.obj_id
        LEFT JOIN dbo.exchanges_rates r
            ON r.currency_id = d.tran_cur_id
                AND r.begin_date = @calc_eomonth
    WHERE p.begin_date <= d.dt_oper
        AND ISNULL(p.end_date, d.dt_oper) >= d.dt_oper
        --AND d.dt_oper BETWEEN @calc_somonth AND @calc_eomonth
        AND d.mcc_code NOT LIKE '%' + ISNULL(p.MCC_code_transaction_out, '-') + '%'
            -- По акциям за месяц - 1 также, как в текущем периоде
        --AND DATEDIFF(month, @calc_eomonth, @today) <= 1
        --AND p.action_name IS NOT NULL

--**********************************************************************************************************************
    SELECT * FROM #tmp
    SELECT * FROM #pc_turnover_data
    SELECT * FROM #pc_data
    SELECT * FROM #pc_calc_data
    --SELECT * FROM #pc_account_balance
    
    SELECT --*,
           DISTINCT pcd.pc_id,
           tariff_limit_summa,
           turn_amount_total = SUM(tran_amount) OVER (PARTITION BY pc_id),
           is_turnover = IIF(tariff_sum_turnover > (SUM(tran_amount) OVER (PARTITION BY pc_id)), 0, 1),
           is_min_summa = MIN(IIF(account_balance BETWEEN tariff_limit_summa AND tariff_max_rest, 1, 0)) OVER (PARTITION BY pc_id),
           calc_amount_total = SUM(calc_amount) OVER (PARTITION BY pc_id) 
    FROM #pc_calc_data pcd
    --ORDER BY pc_id, operday
    
    DROP TABLE #tmp
    DROP TABLE #pc_turnover_data
    DROP TABLE #pc_data
    --DROP TABLE #pc_account_balance
    DROP TABLE #pc_calc_data

/*          
SELECT * FROM dbo.pc WHERE pc_id IN (664987173)
SELECT * FROM dbo.subjects WHERE subj_id = 275732228
--EXEC dbo.pc_card_get 664987173--933352543-- 664408659
--EXECUTE object_actions_accessible 664408659, 371
*/

