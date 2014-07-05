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
            `id` INTEGER NOT NULL AUTO INCREMENT,
            `name` VARCHAR(255) NOT NULL,
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
                  name: "id",
                  type: "integer",
                  qualifiers: [:not_null, :auto_increment],
                },
                {
                  name: "name",
                  type: "varchar",
                  qualifiers: [:not_null],
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
            `id` INTEGER NOT NULL AUTO INCREMENT,
            `name` VARCHAR(255) NOT NULL,
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
                  name: "id",
                  type: "integer",
                  qualifiers: [:not_null, :auto_increment],
                },
                {
                  name: "name",
                  type: "varchar",
                  qualifiers: [:not_null],
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
