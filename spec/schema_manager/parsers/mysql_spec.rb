require "spec_helper"

describe SchemaManager::Parsers::Mysql do
  let(:instance) do
    described_class.new
  end

  describe ".parse" do
    subject do
      begin
        described_class.parse(str).to_hash
      rescue => exception
        puts exception.cause.ascii_tree rescue nil
        raise
      end
    end

    context "with full syntax" do
      let(:str) do
        <<-EOS.strip_heredoc
          # comment

          USE database_name;

          SET variable_name=value;

          DROP TABLE table_name;

          CREATE DATABASE database_name;

          CREATE TABLE `recipes` (
            `column1` INTEGER NOT NULL AUTO INCREMENT,
            `column2` VARCHAR(255) NOT NULL,
            PRIMARY KEY (`id`)
          );

          ALTER TABLE table_name ADD FOREIGN KEY (column_name) REFERENCES table_name (column_name);

          INSERT INTO table_name (column_name) VALUES ('value');

          DELIMITER //
        EOS
      end

      it "succeeds in parse" do
        should == [
          {
            database_name: "database_name",
          },
          {
            create_table: {
              name: "recipes",
              fields: [
                {
                  name: "column1",
                  type: "integer",
                  qualifiers: [
                    {
                      type: :not_null,
                    },
                    {
                      type: :auto_increment,
                    },
                  ],
                },
                {
                  name: "column2",
                  type: "varchar",
                  qualifiers: [
                    {
                      type: :not_null,
                    },
                  ],
                },
              ],
              constraints: [
                {
                  primary_key: "id",
                },
              ],
            },
          },
        ]
      end
    end

    context "with CREATE DATABASE" do
      let(:str) do
        "CREATE DATABASE database_name;"
      end

      it "succeeds in parse" do
        should == []
      end
    end

    context "with CREATE SCHEMA" do
      let(:str) do
        "CREATE SCHEMA database_name;"
      end

      it "succeeds in parse" do
        should == []
      end
    end

    context "with CREATE TABLE" do
      let(:str) do
        <<-EOS.strip_heredoc
          CREATE TABLE `recipes` (
            `column1` INTEGER NOT NULL AUTO INCREMENT,
            `column2` VARCHAR(255) NOT NULL,
            `column3` INTEGER NULL,
            `column4` INTEGER PRIMARY KEY,
            `column5` INTEGER UNSIGNED,
            `column6` VARCHAR(255) CHARACTER SET utf8,
            `column7` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci,
            `column8` INTEGER UNIQUE KEY,
            `column9` INTEGER KEY,
            PRIMARY KEY (`id`)
          );
        EOS
      end

      it "succeeds in parse" do
        should == [
          {
            create_table: {
              name: "recipes",
              fields: [
                {
                  name: "column1",
                  type: "integer",
                  qualifiers: [
                    {
                      type: :not_null,
                    },
                    {
                      type: :auto_increment,
                    },
                  ],
                },
                {
                  name: "column2",
                  type: "varchar",
                  qualifiers: [
                    {
                      type: :not_null,
                    },
                  ],
                },
                {
                  name: "column3",
                  type: "integer",
                  qualifiers: [
                    {
                      type: :null,
                    },
                  ],
                },
                {
                  name: "column4",
                  type: "integer",
                  qualifiers: [
                    {
                      type: :primary_key,
                    },
                  ],
                },
                {
                  name: "column5",
                  type: "integer",
                  qualifiers: [],
                },
                {
                  name: "column6",
                  type: "varchar",
                  qualifiers: [
                    {
                      type: :character_set,
                      value: "utf8",
                    },
                  ],
                },
                {
                  name: "column7",
                  type: "varchar",
                  qualifiers: [
                    {
                      type: :character_set,
                      value: "utf8",
                    },
                    {
                      type: :collate,
                      value: "utf8_general_ci",
                    },
                  ],
                },
                {
                  name: "column8",
                  type: "integer",
                  qualifiers: [
                    {
                      type: :unique_key,
                    },
                  ],
                },
                {
                  name: "column9",
                  type: "integer",
                  qualifiers: [
                    {
                      type: :key,
                    },
                  ],
                },
              ],
              constraints: [
                {
                  primary_key: "id",
                },
              ],
            },
          },
        ]
      end
    end
  end
end
