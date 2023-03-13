use casino
select * from preferences

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

-- determining most popular app games (ranking) (pt 1)

select favourite_game, 
count(favourite_game) as game_count,
rank() over (order by count(favourite_game) desc) as game_ranking 
from preferences
group by favourite_game

-- targeting clients: (i) using app less frequently than weekly (ii) whose income > 150k $ (pt 2)

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

-- participation in tournaments (pt 3)

select
distinct participation_slot_tournaments,
count(participation_slot_tournaments) as players_votes,
count(participation_slot_tournaments)*100/sum(count(participation_slot_tournaments)) over() as perc_votes
from preferences
group by participation_slot_tournaments
order by perc_votes desc

select
distinct participation_bingo_tournaments,
count(participation_bingo_tournaments) as players_votes,
count(participation_bingo_tournaments)*100/sum(count(participation_bingo_tournaments)) over() as perc_votes
from preferences
group by participation_bingo_tournaments
order by perc_votes desc


-- clients categories (pt 4)

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

-- clients' spending categories (pt 5)

select player_id,
format(([dining_spending_per_stay($)]/[overall_spending_per_stay($)]),'P') as dining_perc,
format(([gaming_spending_per_stay($)]/[overall_spending_per_stay($)]),'P') as gaming_perc,
format(([entertainment_spending_per_stay($)]/[overall_spending_per_stay($)]),'P') as entertainment_perc,
format(([casino_services_spending_per_stay($)]/[overall_spending_per_stay($)]),'P') as casino_services_perc
from spending
order by player_id desc

-- quick access to clients' subscription options (pt 6)

create procedure PlayerSubscr 
@FirstName nvarchar(50),
@LastName nvarchar(50),
@FBSubscr nvarchar(10) output,
@IGSubscr nvarchar(10) output,
@EmailSubscr nvarchar(10) output
as
begin
	select	@FBSubscr = fb_account_subscr,
			@IGSubscr = ig_account_subscr,
			@EmailSubscr = email_subscr 
			from preferences
			join player on preferences.player_id = player.player_id
			where first_name = @FirstName
			and last_name = @LastName
end 

declare @FB nvarchar(10), @IG nvarchar(10), @Email nvarchar(10)  
execute PlayerSubscr 'Omero', 'Ormerod', @FB out, @IG out, @Email out 
select @FB as fb_subscr, @IG as ig_subscr, @Email as email_subscr

