
DROP TABLE IF EXISTS public.shipping;

--shipping
CREATE TABLE public.shipping(
   ID serial ,
   shippingid                         BIGINT,
   saleid                             BIGINT,
   orderid                            BIGINT,
   clientid                           BIGINT,
   payment_amount                          NUMERIC(14,2),
   state_datetime                    TIMESTAMP,
   productid                          BIGINT,
   description                       text,
   vendorid                           BIGINT,
   namecategory                      text,
   base_country                      text,
   status                            text,
   state                             text,
   shipping_plan_datetime            TIMESTAMP,
   hours_to_plan_shipping           NUMERIC(14,2),
   shipping_transfer_description     text,
   shipping_transfer_rate           NUMERIC(14,3),
   shipping_country                  text,
   shipping_country_base_rate       NUMERIC(14,3),
   vendor_agreement_description      text,
   PRIMARY KEY (ID)
);
CREATE INDEX shippingid ON public.shipping (shippingid);
COMMENT ON COLUMN public.shipping.shippingid is 'id of shipping of sale';

select *
from shipping s 

-- create new modele
drop view if exists shipping_datamart;
drop table if exists public.shipping_info;
drop table if exists public.shipping_country_rates;
drop table if exists public.shipping_agreement;
drop table if exists public.shipping_transfer;
drop table if exists public.shipping_status;

-- create table shipping_country_rates
create table public.shipping_country_rates(
shipping_country_id serial,
shipping_country text,
shipping_country_base_rate numeric(14,2),
primary key (shipping_country_id) );

-- create table shipping_agreement
create table public.shipping_agreement(
	agreementid bigint,
	agreement_number text,
	agreement_rate numeric(14,3),
	agreement_commission numeric(14,3),
	primary key (agreementid));

-- create table shipping_transfer
create table public.shipping_transfer(
	shipping_type_id serial,
	transfer_type text,
	transfer_model text,
	shipping_transfer_rate numeric(14,3),
	primary key (shipping_type_id));

-- create table shipping_info
create table public.shipping_info(
	shippingid bigint,
	vendorid bigint,
	payment_amount numeric(14,2),
	shipping_plan_datetime timestamp,
	transfer_type_id bigint,
	shipping_country_id bigint,
	agreementid bigint,
	primary key (shippingid),
	foreign key (transfer_type_id) references shipping_transfer(shipping_type_id) on update cascade,
	foreign key (shipping_country_id) references shipping_country_rates(shipping_country_id) on update cascade,
	foreign key (agreementid) references shipping_agreement(agreementid) on update cascade
	);

-- create table shipping_status
create table public.shipping_status(
shippingid bigint,
status text,
state text,
shipping_start_fact_datetime timestamp,
shipping_end_fact_datetime timestamp,
primary key (shippingid)
);


-- migration

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

-- check migration public.shipping_status
-- select count(*) from public.shipping_status limit 10

create or replace view shipping_datamart as
select si.shippingid , si.vendorid , st.transfer_type, date_part('day',age(ss.shipping_end_fact_datetime,ss.shipping_start_fact_datetime)) as full_day_at_shipping,
	case when ss.shipping_end_fact_datetime > si.shipping_plan_datetime then 1 else 0 end is_delay, case when ss.status = 'finished' then 1 else 0 end is_shipping_finish,
	case when ss.shipping_end_fact_datetime > si.shipping_plan_datetime then date_part('day',age(ss.shipping_end_fact_datetime,si.shipping_plan_datetime)) else 0 end delay_day_at_shipping,
	si.payment_amount, (si.payment_amount * (scr.shipping_country_base_rate + sa.agreement_rate + st.shipping_transfer_rate)) as vat,
	(si.payment_amount * sa.agreement_commission) as profit
from public.shipping_info si
left join public.shipping_transfer st 
on si.transfer_type_id =st.shipping_type_id
left join public.shipping_status ss 
on si.shippingid=ss.shippingid 
left join public.shipping_country_rates scr 
on si.shipping_country_id = scr.shipping_country_id 
left join public.shipping_agreement sa 
on si.agreementid = sa.agreementid;

-- check create view shipping_datamart
-- select * from shipping_datamart limit 10
