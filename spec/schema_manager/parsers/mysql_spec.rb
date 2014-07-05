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

      CREATE database table_name;

      ALTER TABLE table_name ADD FOREIGN KEY (column_name) REFERENCES table_name (column_name);

      DELIMITER //
    EOS
  end

  describe "#parse" do
    subject do
      instance.parse(str)
    end

    it "returns a SchemaManager::Schema" do
      should be_a SchemaManager::Schema
    end
  end

  describe ".parse" do
    subject do
      described_class.parse(str) rescue puts $!.cause.ascii_tree
    end

    it "can parse MySQL syntax" do
      expect { subject }.not_to raise_error
    end
  end
end
