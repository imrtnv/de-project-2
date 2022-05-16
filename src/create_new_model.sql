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
