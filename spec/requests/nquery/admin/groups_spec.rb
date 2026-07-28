# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe "Admin groups", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:analyst) { Nquery::User.find_by!(email: "analyst@nquery.dev") }
  let(:all_users_group) { Nquery::Group.find_by!(system_group: "all_users") }

  def sign_in_as_admin
    post "/login", params: { email: admin.email, password: "password123" }
  end

  describe "GET /admin/groups/:id" do
    it "shows group members and available users" do
      sign_in_as_admin
      group = Nquery::Group.find_by!(name: "Engineering")

      get "/admin/groups/#{group.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(analyst.email)
    end

    it "shows remove controls for custom groups" do
      sign_in_as_admin
      group = Nquery::Group.find_by!(name: "Engineering")

      get "/admin/groups/#{group.id}"

      expect(response.body).to include("Remove")
      expect(response.body).to include("remove_member")
      expect(response.body).to include(%(name="user_id" value="#{analyst.id}"))
      expect(response.body).to include("onsubmit=\"return confirm(")
      expect(response.body).to include("Remove #{analyst.name} from #{group.name}?")
    end

    it "does not show remove controls for the all users group" do
      sign_in_as_admin

      get "/admin/groups/#{all_users_group.id}"

      expect(response.body).not_to include("remove_member")
      expect(response.body).to include("automatically added to this group")
    end
  end

  describe "POST /admin/groups" do
    it "creates a custom group" do
      sign_in_as_admin

      expect {
        post "/admin/groups", params: { group: { name: "Finance", description: "Finance team" } }
      }.to change(Nquery::Group, :count).by(1)

      expect(response).to redirect_to("/admin/groups")
      expect(Nquery::Group.find_by!(name: "Finance").system_group).to eq("custom")
    end

    it "renders errors for invalid groups" do
      sign_in_as_admin

      post "/admin/groups", params: { group: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/groups/:id" do
    it "updates a group" do
      sign_in_as_admin
      group = Nquery::Group.create!(name: "Ops", system_group: "custom")

      patch "/admin/groups/#{group.id}", params: { group: { name: "Operations", description: "Ops team" } }

      expect(response).to redirect_to("/admin/groups")
      expect(group.reload.name).to eq("Operations")
    end

    it "renders errors for invalid updates" do
      sign_in_as_admin
      group = Nquery::Group.create!(name: "Ops", system_group: "custom")

      patch "/admin/groups/#{group.id}", params: { group: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /admin/groups/:id/add_member" do
    it "adds a user to the group" do
      sign_in_as_admin
      group = Nquery::Group.create!(name: "Ops", system_group: "custom")

      post "/admin/groups/#{group.id}/add_member", params: { user_id: analyst.id }

      expect(response).to redirect_to("/admin/groups/#{group.id}")
      expect(group.reload.users).to include(analyst)
    end
  end

  describe "DELETE /admin/groups/:id/remove_member" do
    it "removes a user from a custom group" do
      sign_in_as_admin
      group = Nquery::Group.find_by!(name: "Engineering")

      delete "/admin/groups/#{group.id}/remove_member", params: { user_id: analyst.id }

      expect(response).to redirect_to("/admin/groups/#{group.id}")
      expect(group.reload.users).not_to include(analyst)
    end

    it "removes a user via the remove button form on the group page" do
      sign_in_as_admin
      group = Nquery::Group.find_by!(name: "Engineering")

      get "/admin/groups/#{group.id}"

      form = Nokogiri::HTML(response.body).css("form").find { |node| node["action"]&.include?("remove_member") }
      expect(form).to be_present

      action = URI.parse(form["action"])
      hidden_params = form.css("input[type=hidden]").each_with_object({}) do |input, params|
        params[input["name"]] = input["value"]
      end
      query_params = Rack::Utils.parse_query(action.query)

      delete action.path, params: query_params.merge(hidden_params)

      expect(response).to redirect_to("/admin/groups/#{group.id}")
      expect(group.reload.users).not_to include(analyst)
    end

    it "rejects removing a user from the all users group" do
      sign_in_as_admin

      delete "/admin/groups/#{all_users_group.id}/remove_member", params: { user_id: analyst.id }

      expect(response).to redirect_to("/admin/groups/#{all_users_group.id}")
      expect(flash[:alert]).to include("cannot be removed")
      expect(all_users_group.reload.users).to include(analyst)
    end
  end
end
