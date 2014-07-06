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

  let(:before_schema) do
    <<-EOS.strip_heredoc
      CREATE TABLE `table1` (
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

      CREATE TABLE `table2` (
        `column1` INTEGER NOT NULL AUTO INCREMENT,
        PRIMARY KEY (`column1`)
      );
    EOS
  end

  let(:type) do
    "mysql"
  end

  describe ".new" do
    subject do
      instance
    end

    context "with invalid type argument" do
      let(:type) do
        "invalid"
      end

      it "raises SchemaManager::Errors::ParserNotFound" do
        expect { subject }.to raise_error(SchemaManager::Errors::ParserNotFound)
      end
    end

    context "with valid condition" do
      it "returns a SchemaManager::Diff" do
        should be_a SchemaManager::Diff
      end
    end
  end

  describe "#tables_to_create" do
    subject do
      instance.tables_to_create
    end

    context "with valid condition" do
      it "returns table definitions we need to create" do
        should == [
          {
            name: "table2",
            fields: [
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
            ],
            indices: [
              {
                column: "column1",
                name: nil,
                type: nil,
                primary: true,
              },
            ],
          }
        ]
      end
    end
  end

  describe "#to_s" do
    subject do
      instance.to_s
    end

    it "returns a String" do
      should be_a String
    end
  end
end
