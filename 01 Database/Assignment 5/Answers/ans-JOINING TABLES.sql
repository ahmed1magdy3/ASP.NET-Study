

USE StackOverflow2010;


/*
Question 01 : 
	●  Write a query to display all users along with all post types 
*/
select u.DisplayName, pt.Type
from Users u
cross join PostTypes pt
;

/*
Question 02 : 
	●  Write a query to retrieve all posts along with their owner's  
	display name and reputation. Only include posts that have an owner.
*/
select u.DisplayName, u.Reputation, p.Title
from Users u
join Posts p on p.OwnerUserId = u.Id
;

/*
Question 03 : 
	●  Write a query to show all comments with their associated post 
	titles. Display the comment text, comment score, and post title.
*/

select p1.Title, p2.Body, p2.Score 'commentScore'
from Posts p1
join Posts p2 on p2.ParentId = p1.Id ;

/*
Question 04 : 
	●  Write a query to list all users and their badges (if any). 
	Include users even if they don't have badges. Show display name, 
	badge name, and badge date.
*/
select u.DisplayName, b.Name, b.Date
from Users u
left join Badges b on u.Id = b.UserId ;

/*
Question 05 : 
	●  Write a query to display all posts along with their comments (if 
	any). Include posts that have no comments. Show post title, post 
	score, comment text, and comment score. 
*/
select p1.Title ,p1.Score 'Post Score', p2.Body, p2.Score 'Comment Score'
from Posts p1
left join Posts p2 on p2.ParentId = p1.Id ;

/*
Question 06 : 
	●  Write a query to show all votes along with their corresponding 
	posts. Include all votes even if the post information is missing. 
	Display vote type ID, creation date, and post title. 
*/
select v.VoteTypeId, v.CreationDate, p.Title
from Votes v
left join Posts p on p.Id = v.PostId;


/*
Question 07 : 
	●  Write a query to find all answers (posts with ParentId) along with 
	their parent question. Show the answer title, answer score, 
	question title, and question score. 
*/
select p1.Title 'Question Title',p1.Score 'Question Score', p2.Body 'Answer Title', p2.Score 'Answer Score'
from Posts p1
join Posts p2 on p2.ParentId = p1.Id ;


/*
Question 08 : 
	●  Write a query to display all related posts using the PostLinks table. 
	Show the original post title, related post title, and link type ID. 
*/
select p.Title 'Original Post', po.Title 'Related Post', pl.LinkTypeId
from PostLinks pl
join Posts p on pl.PostId = p.Id  -- original
join Posts po on pl.RelatedPostId = po.Id  -- related
;



/*
Question 09 : 
	●  Write a query to show posts with their authors and the post type 
	name. Display post title, author display name, author reputation,  
	and post type. 
*/

select p.Title, u.DisplayName, u.Reputation, pt.Type
from Posts p
join Users u on u.Id = p.OwnerUserId
join PostTypes pt on pt.Id = p.PostTypeId
;

/*
Question 10 : 
	●  Write a query to retrieve all comments along with the post title, 
	post author, and the commenter's display name. 
*/
select u.DisplayName 'Author', p.Title 'Post Title' ,uc.DisplayName 'Comment Author',c.Body 'Comment' 
from Users u
join Posts p on p.OwnerUserId = u.Id    -- post's user
join Posts c on c.ParentId = p.Id       -- comment
join users uc on uc.Id = c.OwnerUserId  -- comment's user
;
/*
Question 11 :  
	●  Write a query to display all votes with post information and vote 
	type name. Show post title, vote type name, creation date, and bounty amount. 
*/
select p.Title, vt.Name 'Vote Type', v.CreationDate, v.BountyAmount
from Votes v
join VoteTypes vt on v.VoteTypeId = vt.Id
join Posts p on p.Id = v.PostId
;
/*
Question 12 : 
	● Write a query to show all users along with their posts and 
	comments on those posts. Include users even if they have no 
	posts or comments. Display user name, post title, and comment text. 
*/
select u.DisplayName 'User Name', p.Title 'Post Title' ,c.Body 'Comment' 
from Users u
left join Posts p on p.OwnerUserId = u.Id    -- post's user
join Posts c on c.ParentId = p.Id			 -- comment
;

/*
Question 13 : 
	●  Write a query to retrieve posts with their authors, post types, and 
	any badges the author has earned. Show post title, author name, 
	post type, and badge name. 
*/
select p.Title 'Post Title', u.DisplayName 'Author Name', pt.Type 'Post Type', b.Name 'Badge Name' 
from Posts p
join Users u on u.Id = p.OwnerUserId
join PostTypes pt on pt.Id = p.PostTypeId
join Badges b on b.UserId = u.Id
;
/*
Question 14 : 
	●  Write a query to create a comprehensive report showing:  
	post title, post author name, author reputation, comment text, 
	commenter name, vote type, and vote creation date. Include 
	posts even if they don't have comments or votes. Filter to only 
	show posts with a score greater than 5. 
*/
select p.Title 'Post Title', u.DisplayName 'Author Name', u.Reputation 'Author Reputation', c.Body 'Comment',
		uc.DisplayName 'Commenter Name', vt.Name 'Vote Type', v.CreationDate 'Vote Creation Date'
from posts p
left join posts c on c.ParentId = p.Id  -- comment
join Users u on u.Id = p.OwnerUserId  -- post's user
left join Users uc on uc.Id = c.OwnerUserId -- comments's user
left join Votes v on v.PostId = p.Id
left join VoteTypes vt on vt.Id = v.VoteTypeId
where p.Score > 5
;
