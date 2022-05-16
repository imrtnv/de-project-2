# Проект 2
**Цель - Оптимизировать хранилище, расширенные возможности в анализе данных**

**Задача - Создать новую модель данных , провести миграцию, сделать представление для аналитиков**

**Проект - Интернет-Магазин (тип не указан)**

Исходные данные - Таблица shipping (последовательность действий при доставке). Столбцы:
 - shippingid — уникальный идентификатор доставки;
 - saleid - уникальный идентификатор заказа. К одному заказу может быть привязано несколько строчек shippingid, то есть логов, с информацией о доставке;
 - vendorid - уникальный идентификатор вендора. К одному вендору может быть привязано множество saleid и множество строк доставки;
 - payment_amount - сумма платежа (то есть дублирующаяся информация);
 - shipping_plan_datetime - плановая дата доставки;
 - status - статус доставки в таблице shipping по данному shippingid. Может принимать значения in_progress — доставка в процессе, либо finished — доставка завершена;
 - state - промежуточные точки заказа, которые изменяются в соответствии с обновлением информации о доставке по времени state_datetime.
booked (пер. «заказано»);
fulfillment — заказ доставлен на склад отправки;
queued (пер. «в очереди») — заказ в очереди на запуск доставки;
transition (пер. «передача») — запущена доставка заказа;
pending (пер. «в ожидании») — заказ доставлен в пункт выдачи и ожидает получения;
received (пер. «получено») — покупатель забрал заказ;
returned (пер. «возвращено») — покупатель возвратил заказ после того, как его забрал;
 - state_datetime — время обновления состояния заказа;
 - shipping_transfer_description - строка со значениями transfer_type и transfer_model, записанными через :. Пример записи — 1p:car


Ход выполнения работы:
- Создание справочника стоимости доставки в страны shipping_country;
- Создание справочника тарифов доставки вендора по договору shipping_agreement;
- Создание справочника о типах доставки shipping_transfer;
- Создание таблицы shipping_info с уникальными доставками;
- Создание таблицы статусов о доставке shipping_status;
- Создание представления shipping_datamart для аналитиков.

shipping_datamart:
- shippingid
- vendorid
- transfer_type — тип доставки из таблицы shipping_transfer
- full_day_at_shipping — количество полных дней, в течение которых длилась доставка. Высчитывается как:shipping_end_fact_datetime-shipping_start_fact_datetime
- is_delay — статус, показывающий просрочена ли доставка. Высчитывается как: shipping_end_fact_datetime > shipping_end_plan_datetime → 1; 0
- is_shipping_finish — статус, показывающий, что доставка завершена. Если финальный status = finished → 1; 0
- delay_day_at_shipping — количество дней, на которые была просрочена доставка. Высчитыается как: shipping_end_fact_datetime > shipping_end_plan_datetime → shipping_end_fact_datetime − shipping_end_plan_datetime ; 0).
- payment_amount — сумма платежа пользователя
- vat — итоговый налог на доставку. Высчитывается как: payment_amount * ( shipping_country_base_rate + agreement_rate + shipping_transfer_rate) .
- profit — итоговый доход компании с доставки. Высчитывается как: payment_amount ∗ agreement_comission.


Данные изначальной таблицы лога shipping - src/shipping.csv

Новая модель данных - src/new_model.jpg

Скрипт создания таблицы shipping - src/create_table_shipping.sql

Скрипт создания новой модели данных - src/create_new_model.sql

Скрипт миграция данных для новой модели - src/script_migration.sql

Скрипт создания представления для аналитиков - src/create_view_shipping_datamart.sql

Общий скрипт проекта - src/project_2.sql

Примечание: Миграцию исходных данных делал через интерфейс dbeaver, подскажите как можно сделать командой чтобы подтянуть локальный файл? через copy и другие народные методы не получилось



