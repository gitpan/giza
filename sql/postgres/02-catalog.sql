
#%include <config.pimpx>

-- +=+=+=+=+=+=+=+=+
-- category_object
-- +=+=+=+=+=+=+=+=+
-- id			; the object id.
-- parent		; parent object.
-- active		; show this on the page? (0/1)
-- created		; timestamp
-- changed		; timestamp
-- owner		; id to user who owns this object
-- groupo		; id to owner group
-- revised_by	; id to user who last changed this object.
-- sort			; sort field for fine tuned sorts.
-- u_perms		; user permissions (r/w/l)
-- g_perms		; group permissions (r/w/l)
-- o_perms		; others permissions (r/w/l)
-- refs_to_us	; id of references to us separated by :
-- template		; path to object template.
-- type			; 'link', 'category', 'reference'....
-- name			; object name.
-- description	; object description.
-- keywords		; object keywords
-- data			; object data (link, reference etc)

-- Since we create the root catalog below, we must start on two.
CREATE SEQUENCE catalog_seq START 2;

CREATE TABLE catalog (
	id			BIGINT 		NOT NULL DEFAULT nextval('catalog_seq'),
	parent		BIGINT 		NOT NULL DEFAULT 1,
	active		INT 		NOT NULL DEFAULT 0,
	created		TIMESTAMP 	NOT NULL DEFAULT CURRENT_TIMESTAMP,
	changed		TIMESTAMP 	NOT NULL DEFAULT CURRENT_TIMESTAMP,
	owner		BIGINT 		NOT NULL DEFAULT 1,
	groupo		BIGINT 		NOT NULL DEFAULT 1,
	revised_by	BIGINT 		NOT NULL DEFAULT 1,
	recommended INT			NOT NULL DEFAULT 0,
	sort		BIGINT 		NOT NULL DEFAULT 0,
	mode		VARCHAR(4)	NOT NULL DEFAULT '0644',
	refs_to_us	BIGINT 		NOT NULL DEFAULT 0,
	template	TEXT,
	type		VARCHAR(255) NOT NULL DEFAULT 'link',
	name		VARCHAR(255) NOT NULL DEFAULT '',
	description	TEXT 		NOT NULL DEFAULT '',
	keywords	TEXT 		NOT NULL DEFAULT '',
	data		TEXT 		NOT NULL DEFAULT '',
	PRIMARY KEY(id),	
	FOREIGN KEY("owner") REFERENCES users(id)
);	

INSERT INTO catalog (id, parent, active, owner, groupo, revised_by, type, name, description, mode)
	VALUES(
		1, 0, 1, 1, 1, 1, 'catalog', 'root', 'This is giza2. Kiss my catalogue!', '0755'
	);

#%print GRANT ALL ON catalog TO %{DBUSER};
