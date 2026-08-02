# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Setup do
  before do
    Nquery.reset_configuration!
  end

  describe ".run!" do
    it "provisions groups, data sources, and permissions" do
      described_class.run!

      expect(Nquery::Group.pluck(:system_group)).to include("administrators", "all_users")
      expect(Nquery::DataSource.find_by!(key: "main").adapter).to eq("rails")
      expect(Nquery::Collection.find_by!(kind: "root")).to be_present
      expect(Nquery::DataPermission.count).to be_positive
    end

    it "is idempotent" do
      described_class.run!
      group_count = Nquery::Group.count
      data_source_count = Nquery::DataSource.count

      described_class.run!

      expect(Nquery::Group.count).to eq(group_count)
      expect(Nquery::DataSource.count).to eq(data_source_count)
    end

    it "does not create demo users or charts" do
      user_count = Nquery::User.count
      chart_count = Nquery::Chart.count

      described_class.run!

      expect(Nquery::User.count).to eq(user_count)
      expect(Nquery::Chart.count).to eq(chart_count)
    end

    it "seeds default permissions when groups are missing" do
      Nquery::ApplicationPermission.delete_all
      Nquery::DataPermission.delete_all
      Nquery::CollectionPermission.delete_all
      Nquery::GroupMembership.delete_all
      Nquery::Group.delete_all

      described_class.run!

      administrators = Nquery::Group.find_by!(system_group: "administrators")
      all_users = Nquery::Group.find_by!(system_group: "all_users")
      root = Nquery::Collection.find_by!(kind: "root")

      expect(administrators.name).to eq("Administrators")
      expect(all_users.name).to eq("All Users")
      expect(Nquery::CollectionPermission.find_by!(group: administrators, collection: root).access_level).to eq("curate")
      expect(Nquery::CollectionPermission.find_by!(group: all_users, collection: root).access_level).to eq("view")
      expect(Nquery::DataPermission.where(group: administrators).count).to be_positive
      expect(Nquery::ApplicationPermission.where(group: administrators).count).to eq(Nquery::ApplicationPermission::FEATURES.size)
    end
  end
end
