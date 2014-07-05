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

          CREATE TABLE `table1` (
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
              name: "table1",
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
                  primary_key: {
                    column: "id",
                    type: nil,
                  },
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

    context "with NOT NULL field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER NOT NULL);"
      end

      it "succeeds in parse field qualifier" do
        subject[0][:create_table][:fields][0][:qualifiers][0][:type].should == :not_null
      end
    end

    context "with NULL field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER NULL);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:qualifiers][0][:type].should == :null
      end
    end

    context "with AUTO INCREMENT field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER AUTO INCREMENT);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:qualifiers][0][:type].should == :auto_increment
      end
    end

    context "with PRIMARY KEY field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER PRIMARY KEY);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:qualifiers][0][:type].should == :primary_key
      end
    end

    context "with UNSIGNED field type qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER UNSIGNED);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:qualifiers].should be_empty
      end
    end

    context "with CHARACTER SET field type qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` VARCHAR(255) CHARACTER SET utf8);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:qualifiers][0].should == {
          type: :character_set,
          value: "utf8",
        }
      end
    end

    context "with COLLATE field type qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` VARCHAR(255) COLLATE utf8_general_ci);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:qualifiers][0].should == {
          type: :collate,
          value: "utf8_general_ci",
        }
      end
    end

    context "with UNIQUE KEY field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER UNIQUE KEY);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:qualifiers][0][:type].should == :unique_key
      end
    end

    context "with UNIQUE INDEX field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER UNIQUE INDEX);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:qualifiers][0][:type].should == :unique_key
      end
    end

    context "with KEY field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER KEY);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:qualifiers][0][:type].should == :key
      end
    end

    context "with INDEX field qualifier" do
      let(:str) do
        "CREATE TABLE `table1` (`column1` INTEGER INDEX);"
      end

      it "succeeds in parse" do
        subject[0][:create_table][:fields][0][:qualifiers][0][:type].should == :key
      end
    end

    context "with PRIMARY KEY constraint" do
      let(:str) do
        <<-EOS.strip_heredoc
          CREATE TABLE `table1` (
            `column1` INTEGER,
            PRIMARY KEY (`column1`)
          );
        EOS
      end

      it "succeeds in parse" do
        subject[0][:create_table][:constraints][0].should == {
          primary_key: {
            column: "column1",
            type: nil,
          },
        }
      end
    end

    context "with PRIMARY KEY constraint with index type" do
      let(:str) do
        <<-EOS.strip_heredoc
          CREATE TABLE `table1` (
            `column1` INTEGER,
            PRIMARY KEY BTREE (`column1`)
          );
        EOS
      end

      it "succeeds in parse" do
        subject[0][:create_table][:constraints][0].should == {
          primary_key: {
            column: "column1",
            type: "btree",
          },
        }
      end
    end

    context "with CREATE TABLE" do
      let(:str) do
        <<-EOS.strip_heredoc
          CREATE TABLE `table1` (
            `column1` INTEGER NOT NULL AUTO INCREMENT,
            PRIMARY KEY (`column1`)
          );
        EOS
      end

      it "succeeds in parse" do
        should == [
          {
            create_table: {
              name: "table1",
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
              ],
              constraints: [
                {
                  primary_key: {
                    column: "column1",
                    type: nil,
                  },
                },
              ],
            },
          },
        ]
      end
    end
  end
end
