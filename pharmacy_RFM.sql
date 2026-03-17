-- 1) Анализ имеющихся данныъ, проверка наличия повторяющихся чеков.
select
	doc_id,
	count(*) as cnt
from bonuscheques b
group by 1
having count(*) > 1

-- 2) Дедупликация данных, приведение к формату "Одна строка - один чек"
with checks as (
	select 
		doc_id,
		card as customer_id,
		min(datetime) as dt,
		max(summ_with_disc) as amount
	from bonuscheques b 
	group by 1,2
	)
select *
from checks

-- 3) Определение единой даты отсчета, относительно которой будет считаться давность покупок.
with asof as (
    select
        max(datetime) as asof_date
    from bonuscheques b 
)
select *
from asof

-- 4.1) Составление базы для последующего анализа: когда клиент покупал в последний раз, как часто совершал покупки
-- какую сумму выручки принес бизнесу

with checks as (
    select
        doc_id,
        card as customer_id,
        min(datetime) as dt,
        max(summ_with_disc) as amount
    from bonuscheques b
    group by doc_id, card
),
asof as (
    select max(dt) as asof_date
    from checks c
)
select
	customer_id,
	max(dt) as most_recent_purchase_date,
	count(*) as frequency,
	sum(amount) as monetary
from checks c
group by 1

--4.2) Расчет базовых RFM - метрик

with checks as (
    select
        doc_id,
        card as customer_id,
        min(datetime) as dt,
        max(summ_with_disc) as amount
    from bonuscheques b
    group by doc_id, card
),
asof as (
    select max(dt) as asof_date
    from checks c
),
rfm_raw as (
select
	customer_id,
	max(dt) as most_recent_purchase_date,
	count(*) as frequency,
	sum(amount) as monetary
from checks c
group by 1
)
select
	r.customer_id,
	(a.asof_date - r.most_recent_purchase_date) AS recency_days,
	r.frequency,
	r.monetary,
	r.most_recent_purchase_date,
	a.asof_date
from rfm_raw r
cross join asof a


--5) Анализ распределения значений Recency для понимания поведения среднего клиента.
-- Проверка минимального, максимального и медианного значения Recency

select
    min(t.recency_days) as min_recency,
    max(t.recency_days) as max_recency,
    percentile_cont(0.5) within group (order by t.recency_days) as median_recency
from (
    with checks as (
        select
            doc_id,
            card as customer_id,
            min(datetime) as dt,
            max(summ_with_disc) as amount
        from bonuscheques b
        group by doc_id, card
    ),
    asof as (
        select max(dt) as asof_date
        from checks
    ),
    rfm_raw as (
        select
            customer_id,
            max(dt) as most_recent_purchase_date,
            count(*) as frequency,
            sum(amount) as monetary
        from checks
        group by 1
    )
    select
        r.customer_id,
        (a.asof_date - r.most_recent_purchase_date) as recency_days,
        r.frequency,
        r.monetary,
        r.most_recent_purchase_date,
        a.asof_date
    from rfm_raw r
    cross join asof a
) t

--6) Расчет перцентилей по Recency для определения оценочных порогов
select
    percentile_cont(0.25) within group (order by t.recency_days) as p25,
    percentile_cont(0.5) within group (order by t.recency_days) as p50,
    percentile_cont(0.75) within group (order by t.recency_days) as p75
from (
    with checks as (
        select
            doc_id,
            card as customer_id,
            min(datetime) as dt,
            max(summ_with_disc) as amount
        from bonuscheques b
        group by doc_id, card
    ),
    asof as (
        select max(dt) as asof_date
        from checks
    ),
    rfm_raw as (
        select
            customer_id,
            max(dt) as most_recent_purchase_date,
            count(*) as frequency,
            sum(amount) as monetary
        from checks
        group by 1
    )
    select
        r.customer_id,
        (a.asof_date - r.most_recent_purchase_date) as recency_days,
        r.frequency,
        r.monetary,
        r.most_recent_purchase_date,
        a.asof_date
    from rfm_raw r
    cross join asof a
    ) t
    
--7) Проверка распределения Frequency, расчет перцентилей, максимальных и минимальных значений
    
select
    min(frequency) as min_frequency,
    max(frequency) as max_frequency,
    percentile_cont(0.25) within group (order by frequency) as p25,
    percentile_cont(0.5) within group (order by frequency) as p50,
    percentile_cont(0.75) within group (order by frequency) as p75
from (
    with checks as (
        select
            doc_id,
            card as customer_id,
            min(datetime) as dt,
            max(summ_with_disc) as amount
        from bonuscheques b
        group by doc_id, card
    ),
    asof as (
        select max(dt) as asof_date
        from checks
    ),
    rfm_raw as (
        select
            customer_id,
            max(dt) as most_recent_purchase_date,
            count(*) as frequency,
            sum(amount) as monetary
        from checks
        group by 1
    )
    select
        r.customer_id,
        (a.asof_date - r.most_recent_purchase_date) as recency_days,
        r.frequency,
        r.monetary,
        r.most_recent_purchase_date,
        a.asof_date
    from rfm_raw r
    cross join asof a
    ) t
    
--8) Проверка распределения Monetary, расчет перцентилей, максимальных и минимальных значений
    
select
    min(monetary) as min_monetary,
    max(monetary) as max_monetary,
    percentile_cont(0.25) within group (order by monetary) as p25,
    percentile_cont(0.5) within group (order by monetary) as p50,
    percentile_cont(0.75) within group (order by monetary) as p75
from (
    with checks as (
        select
            doc_id,
            card as customer_id,
            min(datetime) as dt,
            max(summ_with_disc) as amount
        from bonuscheques b
        group by doc_id, card
    ),
    asof as (
        select max(dt) as asof_date
        from checks
    ),
    rfm_raw as (
        select
            customer_id,
            max(dt) as most_recent_purchase_date,
            count(*) as frequency,
            sum(amount) as monetary
        from checks
        group by 1
    )
    select
        r.customer_id,
        (a.asof_date - r.most_recent_purchase_date) as recency_days,
        r.frequency,
        r.monetary,
        r.most_recent_purchase_date,
        a.asof_date
    from rfm_raw r
    cross join asof a
    ) t
    
--9) Финальный расчет RFM - метрик с оценками
with checks as(
	select
		doc_id,
		card as customer_id,
		min(datetime) as dt,
		max(summ_with_disc) as amount
	from bonuscheques
	group by doc_id, card
),
asof as (
	select 
		max(dt) as asof_date
		from checks
),
rfm_raw as (
	select 
	customer_id,
	max(dt) as most_recent_purchase_date,
	count(*) as frequency,
	sum(amount) as monetary
from checks
group by customer_id
)
select
	customer_id,
	(a.asof_date - r.most_recent_purchase_date) AS recency_days,
	case 
    	when (a.asof_date - r.most_recent_purchase_date) <= interval '29 days'  then 4
    	when (a.asof_date - r.most_recent_purchase_date) <= interval '87 days'  then 3
    	when (a.asof_date - r.most_recent_purchase_date) <= interval '182 days' then 2
    	else 1
  	end as r_score,
	r.frequency,
		case
			when r.frequency = 1 then 1
			when r.frequency between 2 and 5 then 2
			else 3
		end f_score,
	r.monetary,
	case
		when r.monetary <= 731 then 1
		when r.monetary <= 1586 then 2
		when r.monetary <= 3727.25 then 3
		else 4
	end as m_score
from rfm_raw r
cross join asof a

--11) Формирование RFM - сегментов на основании проставленных оценок.

with checks as(
	select
		doc_id,
		card as customer_id,
		min(datetime) as dt,
		max(summ_with_disc) as amount
	from bonuscheques
	group by doc_id, card
),
asof as (
	select 
		max(dt) as asof_date
	from checks
),
rfm_raw as (
	select 
		customer_id,
		max(dt) as most_recent_purchase_date,
		count(*) as frequency,
		sum(amount) as monetary
	from checks
	group by customer_id
),
rfm_scores as (
	select
	customer_id,
	(a.asof_date - r.most_recent_purchase_date) AS recency_days,
	case 
    	when (a.asof_date - r.most_recent_purchase_date) <= interval '29 days'  then 4
    	when (a.asof_date - r.most_recent_purchase_date) <= interval '87 days'  then 3
    	when (a.asof_date - r.most_recent_purchase_date) <= interval '182 days' then 2
    	else 1
  	end as r_score,
	r.frequency,
		case
			when r.frequency = 1 then 1
			when r.frequency between 2 and 5 then 2
			else 3
		end f_score,
	r.monetary,
	case
		when r.monetary <= 731 then 1
		when r.monetary <= 1586 then 2
		when r.monetary <= 3727.25 then 3
		else 4
	end as m_score,
	r.most_recent_purchase_date,
	a.asof_date
from rfm_raw r
cross join asof a
)
select
  	customer_id,
    r_score,
    f_score,
    m_score,
    case
        when r_score = 4 and f_score = 3 and m_score = 4
            then 'Champions'
        when f_score = 3 and m_score >= 3 and r_score >= 3
            then 'Loyal'
        when r_score = 4 and f_score in (1, 2) and m_score in (2, 3)
            then 'Potential Loyalists'
        when r_score in (1, 2) and f_score >= 2 and m_score >= 2
            then 'At Risk'
        when r_score = 1 and f_score = 1 and m_score = 1
            then 'Lost'
        else 'Other'
    end as segment
from rfm_scores
