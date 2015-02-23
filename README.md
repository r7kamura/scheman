# Scheman [![Build Status](https://travis-ci.org/r7kamura/scheman.svg?branch=master)](https://travis-ci.org/r7kamura/scheman)
SQL schema parser.

## Usage
Create diff from 2 schema files or input.

```sql
# before.sql
CREATE TABLE `table1` (
  `column1` INTEGER(11) PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `column2` DATETIME DEFAULT NOW()
);

CREATE TABLE `table2` (
  `column1` INTEGER(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`column1`)
);
```

```sql
# after.sql
CREATE TABLE `table1` (
  `column1` CHAR(11) NOT NULL AUTO_INCREMENT,
  `column2` DATETIME DEFAULT CURRENT_TIMESTAMP(),
  `column3` VARCHAR(255) NOT NULL DEFAULT "a",
  PRIMARY KEY (`column2`)
);

CREATE TABLE `table3` (
  `column1` INTEGER(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`column1`)
);
```

```sh
$ scheman diff --before before.sql --after after.sql
BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `table3` (
  `column1` INTEGER(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`column1`)
);

ALTER TABLE `table1` ADD COLUMN `column3` VARCHAR(255) NOT NULL DEFAULT "a",
  CHANGE COLUMN `column1` CHAR(11) NOT NULL AUTO_INCREMENT,
  DROP PRIMARY KEY,
  ADD PRIMARY KEY `column2`;

DROP TABLE `table2`;

SET foreign_key_checks=1;

COMMIT;
```

### STDIN
You can input schema data into `scheman diff` command via STDIN, instead of --before.
For instance, this interface is useful when you want to use `mysqldump` command to get your current schema.

```sh
$ mysqldump --no-data --compact db_name | scheman diff --after after.sql
```

### ./schema.sql
Scheman use `./schema.sql` as a default value of --after option.

```sh
$ mysqldump --no-data --compact db_name | scheman diff
```

### Pipes
Here is an example workflow of schema modification, using UNIX pipes.

```sh
$ vi schema.sql
$ mysqldump --no-data --compact db_name | scheman diff | mysql db_name
```

### Rails
[scheman-rails](https://github.com/r7kamura/scheman-rails) provides some rake tasks to use scheman with Rails.
