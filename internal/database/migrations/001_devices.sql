-- +goose up
CREATE TABLE devices (
  id TEXT NOT NULL PRIMARY KEY
);

-- +goose down
DROP TABLE devices;
