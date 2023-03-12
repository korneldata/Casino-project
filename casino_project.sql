-- I. DATA CLEANING

--removing duplicate columns

alter table preferences
drop column first_name, last_name

--replacing 'seldom' with 'monthly' and 'often' with 'weekly'

select * from preferences

update preferences  
set using_casino_app = replace (using_casino_app, 'seldom', 'Monthly')

update preferences 
set using_casino_app = replace (using_casino_app, 'often', 'Weekly')

--correcting misspeling 'Backjack'

update preferences 
set favourite_game = replace (favourite_game, 'Backjack', 'Blackjack')

select * from preferences

-- unifying participation preferences

update preferences
set participation_slot_tournaments = replace(participation_slot_tournaments,'Very Likely','Likely')

update preferences
set participation_bingo_tournaments = replace(participation_bingo_tournaments,'Very Likely','Likely')

--removing null rows

delete from spending
where player_id is null
and first_name is null
and last_name is null
and spa is null
and shows is null
and tournament_slot is null
and concierge is null
and car_service is null
and shops is null
and laundry is null
and room_service is null
and restaurants is null
and [dining_spending_per_stay($)] is null
and [gaming_spending_per_stay($)] is null
and [entertainment_spending_per_stay($)] is null
and [casino_services_spending_per_stay($)] is null
and [overall_spending_per_stay($)] is null
and [avg_days per_stay] is null

--II. DATA MANIPULATION

-- determining most popular app game (ranking) pkt(3)

select favourite_game, 
count(favourite_game) as game_count,
rank() over (order by count(favourite_game) desc) as game_ranking 
from preferences
group by favourite_game

-- targeting clients (4)

select 
pl.player_id,
first_name,
last_name,
[annual_income($)],
using_casino_app
from preferences pr
join player pl
on pr.player_id = pl.player_id
where [annual_income($)] >= 150000 
and using_casino_app IN ('Monthly','Yearly','Once','Never')
order by [annual_income($)] desc

-- clients categories

with tiles
as (
select 
player_id,
[overall_spending_per_stay($)],
ntile(3) over(order by [overall_spending_per_stay($)] desc) as category
from spending
),
categories as 
(
select 
player_id,
[overall_spending_per_stay($)],
case
	when category = 1 then 'Platinium'
	when category = 2 then 'Silver'
	else 'Bronze'
	end as player_category 
from tiles
)
select * from categories 

-- clients spending categories

select player_id,
format(([dining_spending_per_stay($)]/[overall_spending_per_stay($)]),'P') as dining_perc,
format(([gaming_spending_per_stay($)]/[overall_spending_per_stay($)]),'P') as gaming_perc,
format(([entertainment_spending_per_stay($)]/[overall_spending_per_stay($)]),'P') as entertainment_perc,
format(([casino_services_spending_per_stay($)]/[overall_spending_per_stay($)]),'P') as casino_services_perc
from spending
order by player_id desc

