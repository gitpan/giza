
#%include <config.pimpx>

CREATE TABLE preferences (
	id			BIGINT			NOT NULL,
	cat_view	VARCHAR(255),
	cat_sort	VARCHAR(255),
	userlevel	VARCHAR(255)	DEFAULT 'novice',
	cat_active  VARCHAR(255)				NOT NULL DEFAULT 'on',
	cat_recommended VARCHAR(255)			NOT NULL DEFAULT 'off',
	notepad		TEXT
);

#%print GRANT ALL ON catalog TO %{DBUSER};
