
SELECT Id, Title, Score, ViewCount, CreationDate
FROM Posts
WHERE OwnerUserId = 22656 AND Score > 100
ORDER BY CreationDate DESC;



CREATE NONCLUSTERED INDEX IX_Popular_Posts 
ON Posts (OwnerUserId,Score DESC, CreationDate DESC) 
INCLUDE (Title,ViewCount)
WHERE Score > 100
;