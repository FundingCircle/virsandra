require 'spec_helper'

class Company
  include Virsandra::Model

  attribute :id, SimpleUUID::UUID, :default => SimpleUUID::UUID.new
  attribute :name, String
  attribute :score, Fixnum
  attribute :founded, Fixnum
  attribute :founder, String

  table :companies
  key :id, :score
end


describe Virsandra::Model do

  let(:id) { SimpleUUID::UUID.new }
  let(:company) { Company.new(id: id, name: "Testco", score: 78)}

  it "has attributes" do
    company.attributes.should be_a Hash
  end

  it "selects keys" do
    company.key.should == {id: id, score: 78}
  end

  it "reads the configured table" do
    company.table.should == :companies
  end

  it "is valid with a key" do
    company.should be_valid
  end

  it "is invalid when a key element is nil" do
    company.id = nil
    company.should_not be_valid
  end

  it "is equivelent with the same model same attributes" do
    Company.new(id: id, name: 'x').should == Company.new(id: id, name: 'x')
  end

  it "is not equivelent with different attributes" do
    Company.new(id: id, name: 'x').should_not == Company.new(id: id, name: 'y')
  end

  it "is not equivelent to a different model" do
    Company.new(id: id, name: 'x').should_not == stub(attributes: {id: id, name: 'x'})
  end

  describe "finding an existing record" do
    before do
      Virsandra.execute("INSERT INTO companies (id, score, name, founded) VALUES (#{id.to_guid}, 101, 'Funky', 1990)")
    end

    it "can find a record from a key" do
      company = Company.find(id: id, score: 101)
      company.attributes.should == {id: id, score: 101, name: "Funky", founded: 1990, founder: nil}
    end

    it "raises an error with an incomplete key" do
      expect { Company.find(score: 11) }.to raise_error(ArgumentError)
    end

    it "raises an error with an over-specified key" do
      expect { Company.find(score: 11, id: id, name: 'Whatever') }.to raise_error(ArgumentError)
    end

    it "populates missing columns, keeping specified values" do
      attrs = {id: id, name: "Google", score: 101, founder: "Larry Brin"}

      company = Company.load(attrs)
      company.attributes.should == attrs.merge(founded: 1990)
    end
  end

  describe "saving a model" do
    before do
      Virsandra.execute("USE virtest")
      Virsandra.execute("TRUNCATE companies")
    end

    it "can be saved" do
      company = Company.new(id: id, score: 101, name: "Job Place")
      company.save
      Company.find(company.key).should == company
    end

    it "doesn't save when invalid" do
      company = Company.new(name: "Keyless Inc.")
      Virsandra::ModelQuery.should_not_receive(:new)
      company.save
    end
  end
end
