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
    RSpec.configuration.root.join("spec/fixtures/example1.sql")
  end

  let(:after_schema) do
    RSpec.configuration.root.join("spec/fixtures/example2.sql")
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

  describe "#to_s" do
    subject do
      instance.to_s
    end

    it "returns a String" do
      should be_a String
    end
  end
end
