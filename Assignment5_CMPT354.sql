CREATE TABLE Musician(
msin CHAR(5),
firstname VARCHAR(30),
lastname VARCHAR(30) NOT NULL,
birthdate DATE,
PRIMARY KEY(msin)
);

CREATE TABLE Artist(
artistname VARCHAR(30),
startDate DATE NOT NULL,
members INTEGER,
genre VARCHAR,
PRIMARY KEY(artistname)
);

CREATE TABLE Song(
isrc CHAR(14),
title VARCHAR(30),
songYear INTEGER,
artistname VARCHAR(30),
PRIMARY KEY(isrc),
FOREIGN KEY(artistname) REFERENCES Artist ON UPDATE CASCADE ON DELETE NO ACTION
);


CREATE TABLE Plays(
msin CHAR(5),
artistname VARCHAR(30),
share DECIMAL(18,3),
FOREIGN KEY(artistname) REFERENCES Artist ON UPDATE CASCADE ON DELETE NO ACTION,
FOREIGN KEY(msin) REFERENCES Musician ON DELETE CASCADE ON UPDATE NO ACTION
);


GO
CREATE FUNCTION checking()
RETURNS int
AS BEGIN
DECLARE @year int
SELECT @year = CAST(YEAR(arts.startdate) as int) FROM Artist arts
RETURN @year
END
GO;

CREATE TRIGGER trig1
ON plays
AFTER INSERT, UPDATE, DELETE
AS
IF EXISTS
(SELECT plys.artistname, SUM(plys.share) AS sumShare
FROM Plays plys
GROUP BY plys.artistname
HAVING SUM(plys.share)<> 1.0)
BEGIN
RAISERROR('Sum of shares is not 1',1,1)
END;


CREATE TRIGGER trig2
ON plays
AFTER INSERT, UPDATE, DELETE
AS
IF EXISTS
(SELECT arts.members, arts.artistname, COUNT(1) AS countt
FROM Plays plys, Artist arts
WHERE arts.artistname=plys.artistname
GROUP BY arts.artistname, arts.members
HAVING COUNT(1)<> arts.members)
BEGIN
ROLLBACK TRANSACTION
RAISERROR('Number of members is not correct',16,1)
END;

CREATE PROCEDURE spMusicianMoreThanOneArtist
As BEGIN
SELECT ms.lastname, ms.msin, plys.artistname, COUNT(plys.artistname) AS countt
FROM Musician ms, Plays plys
WHERE plys.msin=ms.msin
GROUP BY ms.msin,ms.lastname,plys.artistname
HAVING COUNT(plys.artistname) >= 2
ORDER BY plys.artistname, ms.lastname, ms.msin ASC
END;



CREATE PROCEDURE spSongsWithTheInTitle
@n int
AS BEGIN
SELECT ms.lastname, arts.artistname, COUNT(sng.isrc) AS countt
FROM Musician ms, Plays plys,Song sng, Artist arts
WHERE arts.artistname=plys.artistname AND sng.artistname = arts.artistname AND plys.msin=ms.msin
AND (sng.title NOT LIKE '%the') AND (sng.title LIke '%__the%')
GROUP BY arts.artistname, ms.lastname,sng.isrc
HAVING COUNT(sng.isrc) >= @n
END;