-- +=+=+=+=+=+=+=+=+
-- users
-- +=+=+=+=+=+=+=+=+
-- id			; user id
-- groups		; the groups this user is a member of

#%include <config.pimpx>

-- starts on 3, since we create 2 users.
CREATE SEQUENCE users_seq START 3;
-- starts on 1000, just because we'd like to :)
CREATE SEQUENCE groups_seq START 1000;

CREATE TABLE users(
	id			bigint 			NOT NULL DEFAULT nextval('users_seq'),
	username	varchar(255)	NOT NULL DEFAULT 0,
	password	varchar(255)	NOT NULL,
	groups		varchar(255)	NOT NULL DEFAULT 100,
	last_ip		inet,
	real_name 	varchar(255),
	comments	text,
	PRIMARY KEY(id)
);

CREATE TABLE groups(
	id			bigint			NOT NULL DEFAULT nextval('groups_seq'),
	name		varchar(255)	NOT NULL,
	password	varchar(255),
	PRIMARY KEY(id)
);

INSERT INTO users (id, username, password, groups, real_name)
	VALUES(
		1, 'root', 'LtT6lc9O$1$LtT6lc9O$lAwrMqVXlPzTm4SvB5N1L1', '1:100', 'superuser'
	);
INSERT INTO users (id, username, password, groups, real_name)
	VALUES(
		2, 'guest', 'keKzPf7a$1$keKzPf7a$ksAqL0jZgkS3mGxGHB0zr/', '300', 'guest user'
	);
INSERT INTO groups (id, name)
	VALUES(
		1, 'root'
	);
INSERT INTO groups (id, name)
	VALUES(
		100, 'users'
	);
INSERT INTO groups (id, name)
	VALUES(
		300, 'guests'
	);


#%print GRANT ALL ON users TO %{DBUSER};
#%print GRANT ALL ON groups TO %{DBUSER};
		

