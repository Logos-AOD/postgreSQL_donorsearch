-- Часть 1.
-- Определение регионов с наибольшим количеством зарегистрированных доноров
SELECT 
	donor_users.region AS donor_region,
	COUNT(id) AS count_id
FROM donorsearch.user_anon_data AS donor_users
GROUP BY 
	donor_region
ORDER BY 
	count_id DESC
LIMIT 10;

-- don_region 									|   count_id 
-- ---------------------------------------------+---------------
--     NULL  									|   100 574  
-- Россия, Москва								|	 37 819
-- Россия, Санкт-Петербург						|	 13 137
-- Россия, Татарстан, Казань					|	  6 610
-- Украина, Киевская область, Киев				|	  3 541
-- Россия, Новосибирская область, Новосибирск	|	  3 310
-- Россия, Свердловская область, Екатеринбург	|	  3 082
-- Россия, Башкортостан, Уфа					|	  3 014
-- Россия, Красноярский край, Красноярск		|	  2 346
-- Россия, Краснодарский край, Краснодар		|	  2 186

-- Из указанных донорами регионов проживания закономерно преобладают российские города-миллионики.
-- ТОП-3 лидеры: Москва - 37 819 доноров, Санкт-Петербург - 13 137, Казань - 6 610


-- Часть 2.
-- Динамика общего количества донаций в месяц за 2022 и 2023 годы
SELECT
	DATE_TRUNC('month', donor_don_an.donation_date)::date AS donation_month,
	COUNT(*) AS count_id
FROM donorsearch.donation_anon AS donor_don_an
WHERE
	EXTRACT(year FROM donor_don_an.donation_date) IN (2022, 2023)
GROUP BY 
	donation_month
ORDER BY
	donation_month;

-- 			donation_month 						|   count_id 	|
-- ---------------------------------------------+--------------------------------
-- 			2023-02-01							|	  1977		|
-- 			2022-02-01							|	  2109		|
-- 			2022-03-01							|	  3002		|
-- 			2022-04-01							|	  3223		|
-- 			2022-05-01							|	  2414		|
-- 			2022-06-01							|	  2792		|
--			2022-07-01							|	  2836		|
--			2022-08-01							|	  2987		|
-- 			2022-09-01							|	  3089		|
-- 			2022-10-01							|	  3265		|
-- 			2022-11-01							|	  3156		|
--			2022-12-01							|	  3303		|
--			2023-01-01							|	  2795		|
-- 			2023-02-01							|	  3056		|
-- 			2023-03-01							|	  3523		|
-- 			2023-04-01							|	  2951		|
-- 			2023-05-01							|	  2568		|
-- 			2023-06-01							|	  2651		|
--			2023-07-01							|	  2276		|
--			2023-08-01							|	  2433		|
-- 			2023-09-01							|	  2240		|
-- 			2023-10-01							|	  2117		|
-- 			2023-11-01							|	  1509		|


-- За 2022 и 2023 годы виден тренд на снижение количества донаций

-- Показатели донаций по месяцам с кумулятивной суммой, общей суммой, ми, макс и средней
WITH count_donation AS (
	SELECT DISTINCT 
		CAST(DATE_TRUNC('month', donor_don_an.donation_date) AS DATE) AS donation_month,
		COUNT(donor_don_an.donation_date) OVER(PARTITION BY CAST(DATE_TRUNC('month', donor_don_an.donation_date) AS DATE)) AS count_id
	FROM donorsearch.donation_anon AS donor_don_an
	WHERE
		EXTRACT(year FROM donor_don_an.donation_date) IN (2022, 2023)
),
-- Показатели донаций по месяцам
donation_sum AS (
	SELECT
		-- Месяцы донаций
		donation_month,
		-- Количество донаций по каждому месяцу
		count_id,
		-- Общее количество донаций в каждой строке
		SUM(count_id) OVER() AS sum_count_id,
		-- Накопленные суммы количества донаций на каждый месяц
		SUM(count_id) OVER(ORDER BY donation_month) AS sum_count_id_kum_month,
		min(count_id) OVER() AS min_count,
		max(count_id) OVER() AS max_count,
		round(avg(count_id) OVER() ::NUMERIC, 2) AS avg_count
	FROM count_donation
)
SELECT 
	*
FROM donation_sum;




-- Часть 3.
-- Наиболее активные доноры с зарегистрированными или подтвержденными донациями

-- Распределение пользователей по полу
SELECT distinct
	donor_users.gender,
	count(donor_users.id) over(PARTITION BY donor_users.gender) AS total_us_gen,
	count(donor_users.id) over() AS total_us,
	round(count(donor_users.id) over(PARTITION BY donor_users.gender)::NUMERIC / count(donor_users.id) over()::NUMERIC, 4) * 100 AS perc_gen
FROM donorsearch.user_anon_data AS donor_users;
	
-- 			gender								|   total_us_gen 	|	total_us	|	perc_gen	|
-- ---------------------------------------------+---------------------------------------------------|
-- 			NUll								|	  161 951		|	265 836		|	60.92		|
-- 			Женский								|	   54 933		|	265 836		|	20.66		|
--			Мужской								|	   48 952		|	265 836		|	18.41		|
-- В 60.92% случаев пользователи не указали свой пол

-- Стат показатели пользователей по полу без NULL
SELECT distinct
	donor_users.gender,
	count(donor_users.id) over(PARTITION BY donor_users.gender) AS total_us_gen,
	count(donor_users.id) over() AS total_us,
	round(count(donor_users.id) over(PARTITION BY donor_users.gender)::NUMERIC / count(donor_users.id) over()::NUMERIC, 4) * 100 AS perc_gen
FROM donorsearch.user_anon_data AS donor_users
WHERE 
	donor_users.gender IS NOT NULL;

-- 			gender								|   total_us_gen 	|	total_us	|	perc_gen	|
-- ---------------------------------------------+---------------------------------------------------|
-- 			Мужской								|		48 952		|	103 885		|	47.12		|
--			Женский								|		54 933		|	103 885		|	52.88		|
-- Женщин (54 933) на более чем 5% больше, чем мужчин(48 952) от общего количества пользователей , указавших свой пол.

-- Количество пользователей с подтвержденными донациями
SELECT
	CASE
		WHEN confirmed_donations = 0 THEN 'Не доноры'
		WHEN confirmed_donations > 0 THEN 'Доноры'
	END AS category_donor,
	count(donor_users.id) AS total_us,
	round(count(donor_users.id)::NUMERIC / (SELECT count(donor_users.id) AS total_us FROM donorsearch.user_anon_data AS donor_users), 4)*100 AS perc_don
FROM donorsearch.user_anon_data AS donor_users
GROUP BY 
	category_donor
UNION 
SELECT
	'All',
	count(donor_users.id) AS total_us,
	100
FROM donorsearch.user_anon_data AS donor_users
ORDER BY 
	category_donor desc;
-- Всего 38 637 пользователей были донорами хотя бы раз. Что составляет 14.53% от всех зарегистрированных пользователей.

-- Количество пользователей с подтвержденными донациями по полу
SELECT distinct
	donor_users.gender,
	count(donor_users.id) over(PARTITION BY donor_users.gender) AS total_us_gen,
	count(donor_users.id) over() AS total_us,
	round(count(donor_users.id) over(PARTITION BY donor_users.gender)::NUMERIC / count(donor_users.id) over()::NUMERIC, 4) * 100 AS perc_gen
FROM donorsearch.user_anon_data AS donor_users
WHERE 
	donor_users.gender IS NOT null	
	AND confirmed_donations > 0;
-- 			gender								|   total_us_gen 	|	total_us	|	perc_gen	|
-- ---------------------------------------------+---------------------------------------------------|
-- 			Женский								|		9 634		|	21 086		|	45.69		|
--			Мужской								|		11 452		|	21 086		|	54.31		|
-- Женщин (9 634) на 9% больше, чем мужчин(11 452) от общего количества пользователей , указавших свой пол и подтвержденными донациями.
	

-- Топ доноров по количеству донаций
SELECT
	confirmed_donations
FROM donorsearch.user_anon_data AS donor_users 
WHERE 
	confirmed_donations >= 200
ORDER BY 
	confirmed_donations DESC

-- Топ-1 по донациям - 361. Пол мужской. Выходец из региона  - Россия, Татарстан, Казань. 1957 года рождения.


-- Топ доноров по активности с отсечением количества донаций на донора больше 1
WITH confirmed_don AS (
	SELECT
		donor_users.id AS id_donor,
		count(donor_don_an.id) AS count_donat,
		min(donor_don_an.donation_date)::date AS first_donat,
		max(donor_don_an.donation_date)::date AS last_donat
	FROM donorsearch.user_anon_data AS donor_users 
	INNER JOIN donorsearch.donation_anon AS donor_don_an
		ON donor_users.id = donor_don_an.user_id
	WHERE 
		confirmed_donations >= 0
	GROUP BY 
		donor_users.id
	HAVING 
		count(donor_don_an.id) >= 2
	ORDER BY 
		count_donat desc
)
SELECT 
	*,
    ROUND(count_donat * 1.0 / NULLIF(EXTRACT(EPOCH FROM (last_donat::timestamp - first_donat::timestamp)) / (30 * 24 * 3600), 0), 2) AS avg_donations_per_month
FROM confirmed_don
-- Среднее количество донаций у самых активных доноров вращается вокруг 1. Вероятно данные персоны сдавали не только кровь.



-- Часть 4.
-- Оценить, как система бонусов влияет на зарегистрированные в системе донации.

-- Количество доноров и среднее количество донаций по участию в бонусной программе
WITH data_bonus AS (
	SELECT
		CASE 
			WHEN donor_us_bonus.user_bonus_count > 0 THEN 'Да'
			ELSE 'Нет'
		END AS part_bonus,
		donor_users.id AS id_donor,
		donor_users.confirmed_donations,
		COALESCE(donor_us_bonus.user_bonus_count, 0) AS user_bonus_count
	FROM donorsearch.user_anon_data AS donor_users 
	left join donorsearch.user_anon_bonus AS donor_us_bonus
		ON donor_users.id = donor_us_bonus.user_id
)
SELECT 
	coalesce(part_bonus, 'All') AS part_bonus,
	count(id_donor) AS count_donor,
    ROUND(AVG(confirmed_donations), 2) AS avg_donation,
    round(count(id_donor)::NUMERIC / (SELECT count(donor_users.id) FROM donorsearch.user_anon_data AS donor_users), 4)*100 AS perc_count
FROM data_bonus
GROUP BY ROLLUP (part_bonus)
ORDER BY
	CASE
		WHEN part_bonus IS NULL THEN 1
		ELSE 0
	END,
	part_bonus ASC;
		
--	|	part_bonus	|	count_donor			|	avg_donation	|	perc_count	|
---------------------------------------------------------------------------------
--	|	Да			|		21 108			|		13.90		|		7.94	|	
--	|	Нет			|		256 491			|		0.53		|		96.48	|
--	|	All			|		277 599			|					|				|
-- Участвуют в бонусной программе 21 108 доноров с почти 14 донаций в среднем. Всего 7.94% от общего числа доноров.
-- Не участвуют в бонусной программе 256 491 доноров с 0.5 донаций в среднем. Всего 96.48% от общего числа доноров.



-- Часть 5.
-- Активность доноров по каналам
WITH data_bonus AS (
	SELECT
		CASE 
			WHEN autho_vk is TRUE THEN 'VK'
			WHEN autho_ok is TRUE THEN 'Одноклассники'
			WHEN autho_tg is TRUE THEN 'Телеграм'
			WHEN autho_yandex is TRUE THEN 'Яндекс'
			WHEN autho_google is TRUE THEN 'Google'
			ELSE 'Other'
		END AS autho,
		donor_users.id AS id_donor,
		donor_users.confirmed_donations
	FROM donorsearch.user_anon_data AS donor_users 
)
SELECT 
	coalesce(autho, 'All') AS autho,
	count(id_donor) AS count_donor,
    ROUND(AVG(confirmed_donations), 2) AS avg_donation,
    round((count(id_donor)::NUMERIC / (SELECT count(donor_users.id) FROM donorsearch.user_anon_data AS donor_users)), 4)*100 AS perc_count
FROM data_bonus
GROUP BY ROLLUP (autho)
ORDER BY
	CASE
		WHEN autho IS NULL THEN 1
		ELSE 0
	END,
	autho ASC;
-- Лидер среди каналов - VK. 47.87% от всех каналов по количеству пользователей
-- Также 42.61% всех доноров пришли в программу не из представленных каналов.



-- Часть 6.
-- Сравнение однократных доноров со средней активностью повторных доноров.
WITH data_bonus AS (
	SELECT
		CASE 
			WHEN confirmed_donations = 1 THEN 'Однократные доноры'
			WHEN confirmed_donations > 1 THEN 'Многократные доноры'
			ELSE 'Не доноры'
		END AS category_donor,
		donor_users.id AS id_donor,
		donor_users.confirmed_donations
	FROM donorsearch.user_anon_data AS donor_users 
)
SELECT 
	coalesce(category_donor, 'All') AS autho,
	count(id_donor) AS count_donor,
    ROUND(AVG(confirmed_donations), 2) AS avg_donation,
    round((count(id_donor)::NUMERIC / (SELECT count(donor_users.id) FROM donorsearch.user_anon_data AS donor_users)), 4)*100 AS perc_donors,
    sum(confirmed_donations) AS total_con_donat,
    round((sum(confirmed_donations)::NUMERIC / (SELECT sum(confirmed_donations) FROM donorsearch.user_anon_data AS donor_users)), 4)*100 AS perc_con_donat
FROM data_bonus
GROUP BY ROLLUP (category_donor)
ORDER BY
	CASE
		WHEN category_donor IS NULL THEN 1
		ELSE 0
	END,
	category_donor ASC;
-- Количество однократных и многократных доноров примерно одинаково, но многократные доноры совершили в среднем более чем в 10 раз больше донаций,
-- что в сумме обеспечило 91.25% всех донаций.



-- Часть 7.
-- Записи на донацию
WITH data_plan_don AS (
	SELECT
		DISTINCT donor_don_pl.user_id,
		donor_don_pl.donation_date AS date_plan,
		donor_don_pl.donation_type
	FROM donorsearch.donation_plan AS donor_don_pl
),
data_actual AS (
    SELECT
		DISTINCT donor_don_an.user_id,
		donor_don_an.donation_date AS date_actual,
		donor_don_an.donation_type
	FROM donorsearch.donation_anon AS donor_don_an
),
data_plan_actual AS (
	SELECT 
		dpd.user_id,
		dpd.date_plan,
		da.date_actual,
		dpd.donation_type,
		CASE
			WHEN da.date_actual IS NOT NULL THEN 1
			ELSE 0
		END AS actualed
	FROM data_plan_don AS dpd
	LEFT JOIN data_actual AS da
		ON dpd.user_id = da.user_id
		AND dpd.donation_type = da.donation_type
		AND da.date_actual BETWEEN dpd.date_plan - 14 AND dpd.date_plan + 14
)
SELECT
	donation_type,
	count(*) AS count_plan,
	sum(actualed) filter (WHERE data_plan_actual.date_actual IS NOT null) AS count_actual,
	ROUND(sum(actualed) filter (WHERE data_plan_actual.date_actual IS NOT NULL)::numeric/NULLIF(COUNT(*), 0), 4)*100 AS convers_percent
FROM data_plan_actual
GROUP BY 
	donation_type
ORDER BY
	donation_type ASC;
--	|	donation_type	|	count_plan	|	count_actual	|	convers_percent	|
-----------------------------------------------------------------------------------------
--	|	Безвозмездно	|	23 721		|		8 202		|		34.58		|
--	|	Платно			|	3 359		|		 551		|		16.40		|
-- Окно для даты планирование - +- 14 дней. 
-- 34.58% всех доноров посетили запланированную донацию на безмозмездной основе.
-- 16.40% всех доноров посетили запланированную донацию на платной основе.




-- Выводы
-- Аналитический отчет по базе доноров

-- 1. Географическое распределение доноров

-- Лидеры по количеству зарегистрированных доноров:
-- Москва — 37 819 доноров
-- Санкт-Петербург — 13 137 доноров
-- Казань — 6 610 доноров

--Примечательно: значительная часть данных (100 574 записей) не содержит информации о регионе.

-- 2. Динамика донаций

-- Ключевые показатели:
-- Наблюдается общая тенденция к снижению количества донаций
-- Максимальное количество донаций в 2022 году — 3303 (декабрь)
-- Минимальное количество донаций в 2023 году — 1509 (ноябрь)
-- Средний показатель донаций в месяц — около 2700

-- 3. Демографический анализ

-- Распределение по полу:
-- Не указали пол — 60.92%
-- Женщины — 20.66%
-- Мужчины — 18.41%

-- Активные доноры:
-- Всего активных доноров — 38 637 (14.53% от всех зарегистрированных)
-- Среди активных доноров:
--  Женщины — 45.69%
--  Мужчины — 54.31%

-- 4. Анализ бонусных программ

-- Эффективность бонусов:
-- Участники программы — 21 108 доноров (7.94%) со средним показателем 13.9 донаций
-- Не участники — 256 491 донор (96.48%) со средним показателем 0.5 донаций

-- 5. Каналы привлечения

-- Лидеры по источникам:
-- VK — 47.87% всех пользователей
-- Прочие каналы — 42.61%

-- 6. Анализ активности доноров

-- Типы доноров:
-- Однократные доноры — обеспечивают 8.75% всех донаций
-- Многократные доноры — обеспечивают 91.25% всех донаций

-- 7. Эффективность планирования донаций

-- Конверсия запланированных донаций:
-- Безвозмездные — 34.58%
-- Платные — 16.40%

-- Выводы и рекомендации

-- 1. Географическое распределение:
--	  Необходимо усилить работу в регионах с низким охватом
--	  Оптимизировать работу в Москве как основном донорообразующем регионе

-- 2. Динамика активности:
--	  Требуется разработка мер по стимулированию донаций
-- 	  Важно выявить причины снижения активности

-- 3. Бонусная программа:
--	  Система бонусов показывает высокую эффективность
--	  Необходимо расширить охват участников программы

-- 4. Каналы привлечения:
--	  VK остается основным каналом коммуникации
--	  Требуется развитие альтернативных каналов

-- 5. Планирование донаций:
--	  Необходимо улучшить систему напоминаний
--	  Оптимизировать процесс планирования для повышения конверсии

-- 6. Демография:
--	  Важно работать над повышением прозрачности демографических данных
--	  Развивать программы привлечения новых доноров, особенно среди женщин





























