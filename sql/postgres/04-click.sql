-- +=+=+=+=+=+=+=+=+
-- click
-- +=+=+=+=+=+=+=+=+
-- id			; object id
-- accesses		; counter
-- acc_today	; counter
-- acc_yesterday; counter
-- timestamp	; last access

#%include <config.pimpx>

CREATE TABLE click(
	id				bigint		NOT NULL DEFAULT 1,
	accesses		bigint		NOT NULL DEFAULT 0,
	acc_today		bigint		NOT NULL DEFAULT 0,
	acc_yesterday	bigint		NOT NULL DEFAULT 0,
	timestamp		timestamp	NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY(id),
	FOREIGN KEY("id") REFERENCES catalog(id)
);

#%print GRANT ALL ON click TO %{DBUSER};

-- UPDATE click SET acc_yesterday=(SELECT acc_today FROM click where id=%d);
-- UPDATE click SET acc_today = 0;


