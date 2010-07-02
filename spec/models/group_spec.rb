require 'spec_helper'

describe Group do
  before(:each) do
    @good_opts = {:name => "SomeGroup",
      :description => "A random group"}
  end
  it "should accept valid parameters" do
    group = Group.create(@good_opts)
    group.should be_valid
  end
end

describe Group, "when created with blank parameters" do
  before(:each) do
    @group = Group.create
  end
  it "should require a name" do
    @group.should_not be_valid
    @group.errors[:name].should include("can't be blank")
  end
end
