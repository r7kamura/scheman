require "spec_helper"

describe SchemaManager::Parsers::Mysql do
  let(:instance) do
    described_class.new
  end

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

  describe ".parse" do
    subject do
      begin
        described_class.parse(str)
      rescue => exception
        puts exception.cause.ascii_tree
        raise
      end
    end

    it "can parse MySQL syntax" do
      expect { subject }.not_to raise_error
    end
  end
end
