# Scheman
SQL schema parser.

## Usage
Create diff from 2 schema files.

```ruby
require "scheman"

before = <<-SQL
CREATE TABLE `table1` (
  `column1` INTEGER(11) NOT NULL AUTO INCREMENT,
  PRIMARY KEY (`column1`)
);

CREATE TABLE `table2` (
  `column1` INTEGER(11) NOT NULL AUTO INCREMENT,
  PRIMARY KEY (`column1`)
);
SQL

after = <<-SQL
CREATE TABLE `table1` (
  `column2` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`column1`)
);

CREATE TABLE `table3` (
  `column1` INTEGER(11) NOT NULL AUTO INCREMENT,
  PRIMARY KEY (`column1`)
);
SQL

puts Scheman::Diff.new(before: before, after: after, type: "mysql")
```

The result would be the following:

```sql
BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `table3` (
  `column1` INTEGER(11) NOT NULL AUTO INCREMENT,
  PRIMARY KEY (`column1`)
);

ALTER TABLE `table1` ADD COLUMN `column2` VARCHAR(255) NOT NULL;

ALTER TABLE `table1` DROP COLUMN `column1`;

DROP TABLE `table2`;

SET foreign_key_checks=1;

COMMIT;
```
