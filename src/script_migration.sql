insert into public.shipping_country_rates (shipping_country,shipping_country_base_rate)
select distinct shipping_country, shipping_country_base_rate 
from shipping s;

-- check migration public.shipping_country_rates
-- select * from public.shipping_country_rates limit 10

insert into public.shipping_agreement (	agreementid, agreement_number, agreement_rate, agreement_commission)
select t.agreementid, t.agreement_number, t.agreement_rate, t.agreement_commission
from (select distinct (regexp_split_to_array(s.vendor_agreement_description,E'\\:'))[1]::bigint as agreementid,
		(regexp_split_to_array(s.vendor_agreement_description,E'\\:'))[2]::text as agreement_number,
		(regexp_split_to_array(s.vendor_agreement_description,E'\\:'))[3]::numeric(14,3) as agreement_rate,
		(regexp_split_to_array(s.vendor_agreement_description,E'\\:'))[4]::numeric(14,3) as agreement_commission
from shipping s) as t;

-- check migration public.shipping_agreement
-- select * from public.shipping_agreement limit 10

insert into public.shipping_transfer(transfer_type, transfer_model, shipping_transfer_rate)
select distinct (regexp_split_to_array(s.shipping_transfer_description, E'\\:'))[1]::text as transfer_type,
		(regexp_split_to_array(s.shipping_transfer_description, E'\\:'))[2]::text as transfer_model,
		shipping_transfer_rate 
from shipping s;

-- check migration public.shipping_transfer
-- select * from public.shipping_transfer limit 10

insert into public.shipping_info(shippingid, vendorid, payment_amount, shipping_plan_datetime, transfer_type_id, shipping_country_id, agreementid)
select distinct shippingid, vendorid, payment_amount, shipping_plan_datetime,st.shipping_type_id , scr.shipping_country_id, s_a.agreementid
from shipping s
left join public.shipping_transfer st
on (regexp_split_to_array(s.shipping_transfer_description, E'\\:'))[1]=st.transfer_type
and (regexp_split_to_array(s.shipping_transfer_description, E'\\:'))[2]=st.transfer_model
left join public.shipping_country_rates scr
on s.shipping_country=scr.shipping_country
left join public.shipping_agreement s_a
on (regexp_split_to_array(s.vendor_agreement_description,E'\\:'))[1]::bigint=s_a.agreementid;


-- check migration public.shipping_info
-- select * from public.shipping_info limit 10

insert into public.shipping_status (shippingid,status, state, shipping_start_fact_datetime, shipping_end_fact_datetime)
with cte_start as (select sh.shippingid, min(sh.state_datetime) as shipping_start_fact_datetime from shipping sh where sh.state ='booked' group by 1),
cte_end as (select sh2.shippingid, min(sh2.state_datetime) as shipping_end_fact_datetime from shipping sh2 where sh2.state ='recieved' group by 1)
select s.shippingid, s.status, s.state, cs.shipping_start_fact_datetime, ce.shipping_end_fact_datetime
from public.shipping s
inner join (select distinct s2.shippingid, max(s2.state_datetime) over(partition by s2.shippingid) as max_date from shipping s2) as t
on s.shippingid = t.shippingid
and s.state_datetime = t.max_date
left join cte_start cs
on s.shippingid=cs.shippingid
left join cte_end ce 
on s.shippingid=ce.shippingid;
