-- +=+=+=+=+=+=+=+=+
-- rate
-- +=+=+=+=+=+=+=+=+
-- id              ; the object id.
-- rate            ; total rate of object.
-- num_rates       ; total number of ratings.

#%include <config.pimpx>

CREATE TABLE rate(
	id			bigint 	NOT NULL default 1, 
	rate		bigint  NOT NULL default 0,
	total_votes	bigint	NOT NULL default 0,
	PRIMARY KEY(id),
	FOREIGN KEY("id") REFERENCES catalog(id)
);

#%print GRANT ALL ON rate TO %{DBUSER};


