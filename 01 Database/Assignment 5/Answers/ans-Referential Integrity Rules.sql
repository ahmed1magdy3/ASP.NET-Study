/*
Question 01 : 
● If a hotel is deleted from the Hotels table, what is the appropriate 
behavior for the rooms belonging to that hotel? Explain which 
foreign key rule you would choose and why And Represent Rule 
	- I choose ( Cascade )
	- Rule:  Deletes child rows when parent is deleted.
	- When a hotel is deleted then all related rooms in the Rooms table are also deleted automatically.
	- Why Cascade: To ensure that when a hotel is removed, all the rooms belonging to that hotel are also deleted.
	- It's make sense to me to ensure that no grabage in the database.



Question 02 : 
● When a room is deleted from the Rooms table, what should 
happen to the related records in Amenities? Which rule makes the 
most sense for this relationship, and why? And Represent Rule 
	- I choose ( Cascade )
	- Rule:  Deletes child rows when parent is deleted.
	- When a room is deleted then all related records in the Amenities table for that room are also deleted automatically.
	- Why Cascade: To ensure that when a room is removed,  the related amenities are removed, there’s no reason to keep the amenities for that room in the database.



Question 03 : 
● If a staff member’s ID changes, what impact should this have on 
the Services they are linked to? Which update rule is most 
suitable? And Represent Rule
	- I choose ( Cascade )
	- Rule:  Updates child rows when parent is updated.
	- When a staff member’s ID changes then all related records in the Services table will automatically update to reflect the new staff ID.
	- Why Cascade: To ensure that all related records in the Services table are updated with the new staff ID. This keeps data consistency intact without needing manual entry.


*/