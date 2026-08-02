# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe Nquery::Permissions::Resolver do
  it "identifies admin users" do
    admin = Nquery::User.find_by!(email: "admin@nquery.dev")
    resolver = described_class.new(admin)
    expect(resolver.admin?).to be true
  end

  describe "non-admin permissions" do
    let(:viewer_group) { Nquery::Group.create!(name: "Viewers", system_group: "custom") }
    let(:viewer) do
      Nquery::User.create!(email: "viewer@example.com", password: "password123").tap do |u|
        Nquery::GroupMembership.create!(user: u, group: viewer_group)
        u.ensure_all_users_membership!
      end
    end
    let(:collection) { Nquery::Collection.create!(name: "Shared", kind: "standard", parent: Nquery::Collection.roots.first) }
    let(:data_source) { Nquery::DataSource.find_by!(key: "main") }

    before do
      Nquery::CollectionPermission.create!(group: viewer_group, collection: collection, access_level: "view")
      Nquery::DataPermission.create!(group: viewer_group, data_source: data_source, permission_type: "view_data", access_level: "can_view")
      Nquery::DataPermission.create!(group: viewer_group, data_source: data_source, permission_type: "create_queries", access_level: "query_builder")
    end

    it "resolves collection access" do
      resolver = described_class.new(viewer)
      expect(resolver.collection_access(collection)).to eq(:view)
    end

    it "resolves data access" do
      resolver = described_class.new(viewer)
      expect(resolver.data_access(data_source)).to eq(:can_view)
      expect(resolver.data_access(data_source, permission_type: "create_queries")).to eq(:query_builder)
    end

    it "resolves application access" do
      Nquery::ApplicationPermission.create!(group: viewer_group, feature: "settings", access_level: "yes")
      resolver = described_class.new(viewer)
      expect(resolver.application_access("settings")).to eq(:yes)
    end

    it "detects when all users is more permissive than another group" do
      all_users = Nquery::Group.find_by!(system_group: "all_users")
      Nquery::CollectionPermission.find_or_create_by!(group: all_users, collection: collection) { |p| p.access_level = "curate" }
      resolver = described_class.new(viewer)
      expect(resolver.all_users_more_permissive?(viewer_group, collection: collection)).to be(true)
    end

    it "returns false when all users is not more permissive" do
      resolver = described_class.new(viewer)
      expect(resolver.all_users_more_permissive?(viewer_group, collection: collection)).to be(false)
    end

    it "returns false when no collection or data source is provided" do
      resolver = described_class.new(viewer)
      expect(resolver.all_users_more_permissive?(viewer_group)).to be(false)
    end

    it "uses default blocked access when no data permissions exist" do
      other_group = Nquery::Group.create!(name: "No perms", system_group: "custom")
      user = Nquery::User.create!(email: "noperms@example.com", password: "password123").tap do |u|
        Nquery::GroupMembership.create!(user: u, group: other_group)
      end
      resolver = described_class.new(user)
      expect(resolver.data_access(data_source, permission_type: "create_queries")).to eq(:no)
    end
  end
end
