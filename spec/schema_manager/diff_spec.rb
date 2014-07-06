require "spec_helper"

describe SchemaManager::Diff do
  let(:instance) do
    described_class.new(args)
  end

  let(:args) do
    {
      before: before_schema,
      after: after_schema,
      type: type,
    }
  end

  let(:type) do
    "mysql"
  end

  let(:before_schema) do
    <<-EOS.strip_heredoc
      CREATE TABLE `table1` (
        `column1` INTEGER NOT NULL AUTO INCREMENT,
        PRIMARY KEY (`column1`)
      );

      CREATE TABLE `table2` (
        `column1` INTEGER NOT NULL AUTO INCREMENT,
        PRIMARY KEY (`column1`)
      );
    EOS
  end

  let(:after_schema) do
    <<-EOS.strip_heredoc
      CREATE TABLE `table1` (
        `column1` INTEGER NOT NULL AUTO INCREMENT,
        `column2` VARCHAR(255) NOT NULL,
        PRIMARY KEY (`column1`)
      );

      CREATE TABLE `table3` (
        `column1` INTEGER NOT NULL AUTO INCREMENT,
        PRIMARY KEY (`column1`)
      );
    EOS
  end

  describe "#to_s" do
    subject do
      instance.to_s
    end

    it "returns a diff in SQL" do
      should == <<-EOS.strip_heredoc
        BEGIN;

        SET foreign_key_checks=0;

        CREATE TABLE `table3` (
          `column1` INTEGER NOT NULL AUTO INCREMENT,
          PRIMARY KEY (`column1`)
        );

        DROP TABLE `table2`;

        SET foreign_key_checks=1;

        COMMIT;
      EOS
    end
  end
end
