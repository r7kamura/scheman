require "spec_helper"

describe SchemaManager::Parsers::Mysql do
  let(:instance) do
    described_class.new
  end

  describe ".parse" do
    subject do
      begin
        described_class.parse(str)
      rescue => exception
        puts exception.cause.ascii_tree
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

          ALTER TABLE table_name ADD FOREIGN KEY (column_name) REFERENCES table_name (column_name);

          INSERT INTO table_name (column_name) VALUES ('value');

          DELIMITER //
        EOS
      end
      it { should be_true }
    end

    context "with CREATE DATABASE" do
      let(:str) do
        "CREATE DATABASE database_name;"
      end
      it { should be_true }
    end

    context "with CREATE SCHEMA" do
      let(:str) do
        "CREATE SCHEMA database_name;"
      end
      it { should be_true }
    end
  end
end
