# frozen_string_literal: true

require "spec_helper"

# Defined order matters: the first example writes, the second must not see it.
RSpec.describe "DatabaseCleaner isolation", order: :defined do
  it "writes a row inside the example" do
    expect(MyErp::DB.main[:cleaner_probe].count).to eq(0)

    MyErp::DB.main[:cleaner_probe].insert(value: "dirty")

    expect(MyErp::DB.main[:cleaner_probe].count).to eq(1)
  end

  it "starts the next example with a clean main database" do
    expect(MyErp::DB.main[:cleaner_probe].count).to eq(0)
  end

  it "writes a row in the tenant database" do
    expect(SPEC_TENANT_DB[:cleaner_probe].count).to eq(0)

    SPEC_TENANT_DB[:cleaner_probe].insert(value: "dirty")

    expect(SPEC_TENANT_DB[:cleaner_probe].count).to eq(1)
  end

  it "starts the next example with a clean tenant database" do
    expect(SPEC_TENANT_DB[:cleaner_probe].count).to eq(0)
  end
end
