CREATE TABLE folders (
    id      INTEGER PRIMARY KEY,
    name    STRING  NOT NULL,
    path    STRING  NOT NULL
	                UNIQUE,
    comment TEXT    DEFAULT NULL
);
CREATE TABLE files (
    id        INTEGER PRIMARY KEY,
    folder_id INTEGER NOT NULL
                      REFERENCES folders (id),
    name      STRING  NOT NULL,
    ext       STRING  NOT NULL,
    path      STRING  NOT NULL
                      DEFAULT (''),
    size      INTEGER NOT NULL,
    icon_idx  INTEGER NOT NULL,
    sha       STRING  NOT NULL,
	tags      STRING  NOT NULL,
	comment   STRING  DEFAULT NULL
);
CREATE INDEX idx_files_names ON files (
    name
);
CREATE INDEX idx_files_sha ON files (
    sha
);
CREATE UNIQUE INDEX idxFiles_path_name_ext ON files (
    folder_id,
    name,
    ext,
    path
);
