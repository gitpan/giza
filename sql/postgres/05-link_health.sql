-- +=+=+=+=++=
-- link_health
-- +=+=+=+=++=
-- id				; id to link object.
-- last_checked		; timestamp.
-- errorcount		; how many runs this link failed.
-- last_http_stat	; last http status code.

#%include <config.pimpx>

CREATE TABLE link_health(
	id				bigint		NOT NULL DEFAULT 1,
	last_checked	timestamp	NOT NULL DEFAULT CURRENT_TIMESTAMP,
	errorcount		int			NOT NULL DEFAULT 0,
	last_http_stat	int			NOT NULL DEFAULT 200,
	PRIMARY KEY(id),
	FOREIGN KEY("id") REFERENCES catalog(id)
);

#%print GRANT ALL ON link_health TO %{DBUSER};
