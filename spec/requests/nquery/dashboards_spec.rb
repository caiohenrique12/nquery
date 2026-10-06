# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Nquery::Dashboards", type: :request do
  let(:root_collection) { Nquery::Collection.roots.first }
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }

  def sign_in_as(user)
    sign_in_with_devise(email: user.email)
  end

  def sign_in_as_admin
    sign_in_as(admin)
  end

  def nested_dashboard_params(form)
    pairs = form.css("input[type=hidden], select").filter_map do |node|
      name = node["name"].to_s
      next unless name.start_with?("dashboard[")

      value = node.name == "select" ? node.at_css("option")["value"] : node["value"].to_s
      "#{CGI.escape(name)}=#{CGI.escape(value)}"
    end
    Rack::Utils.parse_nested_query(pairs.join("&"))
  end

  describe "GET /dashboards" do
    before { sign_in_as_admin }

    it "returns success" do
      get "/dashboards"

      expect(response).to have_http_status(:ok)
    end

    it "lists dashboards" do
      get "/dashboards"

      expect(response.body).to include("Executive overview")
      expect(response.body).to include('href="/dashboards/')
    end

    it "highlights dashboards in the sidebar" do
      get "/dashboards"

      expect(response.body).to include('class="nq-nav-link active" href="/dashboards"')
      expect(response.body).to include('<span aria-current="page">Dashboards</span>')
    end

    it "links to a top-level new dashboard form" do
      get "/dashboards"

      expect(response.body).to include("New dashboard")
      expect(response.body).to include('href="/dashboards/new"')
    end

    context "when the user lacks curate access" do
      let(:finance_group) { Nquery::Group.create!(name: "Finance", system_group: "custom") }
      let(:member) do
        Nquery::User.create!(email: "finance@example.com", password: "password123", confirmed_at: Time.current).tap do |user|
          Nquery::GroupMembership.create!(user: user, group: finance_group)
          user.ensure_all_users_membership!
        end
      end
      let(:restricted_collection) do
        Nquery::Collection.create!(
          name: "Finance",
          kind: "standard",
          parent: root_collection
        )
      end
      let!(:view_permission) do
        Nquery::CollectionPermission.create!(
          group: finance_group,
          collection: restricted_collection,
          access_level: "view"
        )
      end

      before { sign_in_as(member) }

      it "hides the top-level new link" do
        get "/dashboards"

        expect(response.body).not_to include('href="/dashboards/new"')
      end
    end

    context "when a dashboard is archived" do
      let!(:dashboard) do
        Nquery::Dashboard.create!(
          name: "Archived board",
          collection: root_collection,
          creator: admin
        )
      end

      before { dashboard.archive! }

      it "excludes it from the index" do
        get "/dashboards"

        expect(response.body).not_to include(dashboard.name)
      end
    end
  end

  describe "GET /dashboards/:id" do
    let!(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Ops overview",
        collection: root_collection,
        creator: admin
      )
    end

    before { sign_in_as_admin }

    it "returns success" do
      get "/dashboards/#{dashboard.id}"

      expect(response).to have_http_status(:ok)
    end

    it "renders archive and remove actions" do
      get "/dashboards/#{dashboard.id}"

      expect(response.body).to include("Archive")
      expect(response.body).to include("Remove")
      expect(response.body).to include("Embed")
      expect(response.body).to include("/dashboards/#{dashboard.id}/embed")
      expect(response.body).to include('class="nq-icon"')
      expect(response.body).to include("/dashboards/#{dashboard.id}/archive")
      expect(response.body).to include('data-turbo-confirm="Remove this dashboard?"')
    end

    it "renders parameter fields for every chart on the dashboard" do
      dashboard.update!(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )

      get "/dashboards/#{dashboard.id}"

      expect(response.body).to include('name="start_date"')
      expect(response.body).to include("2026-08-01")
      expect(response.body).to include("Edit parameters")
      expect(response.body).not_to include("wire=start_date")
    end

    it "hides a filter that is not connected to a chart" do
      data_source = Nquery::DataSource.find_by!(key: "main")
      chart = Nquery::Chart.create!(
        name: "Visible chart",
        query: Nquery::Query.create!(
          name: "Visible chart",
          statement: "SELECT {{end_date}} AS end_date",
          data_source: data_source,
          creator: admin,
          collection: root_collection
        ),
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "table" }
      )
      dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
      dashboard.update!(
        parameters: [
          { "name" => "start_date", "type" => "date", "default" => "2026-08-01", "chart_ids" => [] },
          { "name" => "end_date", "type" => "date", "default" => "" }
        ]
      )

      get "/dashboards/#{dashboard.id}"

      expect(response.body).not_to include('id="dashboard_filter_start_date"')
      expect(response.body).to include('id="dashboard_filter_end_date"')
      expect(response.body).to include("Edit parameters")

      get "/dashboards/#{dashboard.id}", params: { edit: "parameters" }

      expect(response.body).to include("wire=start_date")
      expect(response.body).to include("{{start_date}}")
    end

    it "asks for a chart variable before adding a filter" do
      get "/dashboards/#{dashboard.id}", params: { edit: "parameters" }

      expect(response.body).to include("No chart variables are waiting to be linked.")
      expect(response.body).to include("Add parameter")
      expect(response.body).to include('id="dashboard_parameter_name"')
      expect(response.body).not_to include("Variable name")
    end

    context "when a filter value is submitted while editing parameters" do
      before do
        dashboard.update!(
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
        )
      end

      it "keeps the parameter editor open" do
        get "/dashboards/#{dashboard.id}", params: { edit: "parameters", start_date: "2026-02-01" }

        document = Nokogiri::HTML(response.body)
        expect(document.at_css("#dashboard_parameter_name")).to be_present
        expect(document.at_css("#dashboard_filter_start_date")["value"]).to eq("2026-02-01")

        form = document.at_css("form.nq-dashboard-filter-bar")
        expect(form.at_css("input[type='hidden'][name='edit'][value='parameters']")).to be_present
        clear = document.css("a").find { |node| node.text.strip == "Clear" }
        expect(clear["href"]).to include("edit=parameters")
      end

      it "leaves edit off the filter form when parameters are not being edited" do
        get "/dashboards/#{dashboard.id}", params: { start_date: "2026-02-01" }

        document = Nokogiri::HTML(response.body)
        form = document.at_css("form.nq-dashboard-filter-bar")
        expect(form.at_css("input[name='edit']")).not_to be_present
        expect(document.at_css("#dashboard_parameter_name")).not_to be_present
        clear = document.css("a").find { |node| node.text.strip == "Clear" }
        expect(clear["href"]).not_to include("edit=")
      end
    end

    context "when a filter is removed while editing parameters" do
      before do
        dashboard.update!(
          parameters: [
            { "name" => "start_date", "type" => "date", "default" => "2026-08-01" },
            { "name" => "end_date", "type" => "date", "default" => "" }
          ]
        )
      end

      it "keeps the parameter editor open" do
        get "/dashboards/#{dashboard.id}", params: { edit: "parameters" }

        document = Nokogiri::HTML(response.body)
        item = document.css(".nq-dashboard-filter-list li").find { |node| node.at_css("code")&.text == "{{end_date}}" }
        form = item.at_css("form")
        expect(form.at_css("input[type='hidden'][name='edit'][value='parameters']")).to be_present

        patch "/dashboards/#{dashboard.id}", params: nested_dashboard_params(form).merge("edit" => "parameters")

        expect(response).to redirect_to("/dashboards/#{dashboard.id}?edit=parameters")
        expect(dashboard.reload.parameter_names).to eq(["start_date"])
      end

      it "keeps the wired filter when another filter is removed" do
        get "/dashboards/#{dashboard.id}", params: { edit: "parameters", wire: "start_date" }

        document = Nokogiri::HTML(response.body)
        item = document.css(".nq-dashboard-filter-list li").find { |node| node.at_css("code")&.text == "{{end_date}}" }
        form = item.at_css("form")
        expect(form.at_css("input[type='hidden'][name='wire'][value='start_date']")).to be_present

        patch "/dashboards/#{dashboard.id}", params: nested_dashboard_params(form).merge("edit" => "parameters", "wire" => "start_date")

        expect(response).to redirect_to("/dashboards/#{dashboard.id}?edit=parameters&wire=start_date")
        expect(dashboard.reload.parameter_names).to eq(["start_date"])
      end
    end

    it "adds a parameter from the dashboard editor" do
      dashboard.update!(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )

      get "/dashboards/#{dashboard.id}", params: { edit: "parameters" }

      form = Nokogiri::HTML(response.body).at_css("form.nq-dashboard-parameter-create")
      expect(form.at_css("input[name='dashboard[parameters][][name]'][value='start_date']")).to be_present
      expect(form.at_css("#dashboard_parameter_type option[value='boolean']").text).to eq("Boolean")

      patch "/dashboards/#{dashboard.id}", params: {
        dashboard: {
          name: dashboard.name,
          collection_id: root_collection.id,
          parameters: [
            { name: "start_date", type: "date", default: "2026-08-01" },
            { name: "active", type: "boolean", default: "true" }
          ]
        }
      }

      expect(response).to redirect_to("/dashboards/#{dashboard.id}?edit=parameters&wire=active")
      rows = dashboard.reload.parameter_definitions
      expect(rows.find { |row| row["name"] == "start_date" }).to include("type" => "date", "default" => "2026-08-01")
      created = rows.find { |row| row["name"] == "active" }
      expect(created).to include("type" => "boolean", "default" => "true")
      expect(created).not_to have_key("chart_ids")
    end

    it "links a variable declared on a chart" do
      data_source = Nquery::DataSource.find_by!(key: "main")
      chart = Nquery::Chart.create!(
        name: "Dated chart",
        query: Nquery::Query.create!(
          name: "Dated chart",
          statement: "SELECT {{start_date}} AS start_date",
          data_source: data_source,
          creator: admin,
          collection: root_collection,
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
        ),
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "table" }
      )
      dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)

      get "/dashboards/#{dashboard.id}", params: { edit: "parameters" }

      expect(response.body).to include("{{start_date}} · Date")
      expect(response.body).to include("Link filter")

      patch "/dashboards/#{dashboard.id}", params: {
        dashboard: {
          name: dashboard.name,
          collection_id: root_collection.id,
          parameters: [{ name: "start_date" }]
        }
      }

      expect(response).to redirect_to("/dashboards/#{dashboard.id}?edit=parameters&wire=start_date")
      linked = dashboard.reload.parameter_definitions.first
      expect(linked["type"]).to eq("date")
      expect(linked["default"]).to eq("2026-08-01")
      expect(linked["chart_ids"]).to eq([chart.id])
    end

    it "shows the chart variable type after the query changes" do
      data_source = Nquery::DataSource.find_by!(key: "main")
      query = Nquery::Query.create!(
        name: "Retyped chart",
        statement: "SELECT {{start_date}} AS start_date",
        data_source: data_source,
        creator: admin,
        collection: root_collection,
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )
      chart = Nquery::Chart.create!(
        name: "Retyped chart",
        query: query,
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "table" }
      )
      dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
      dashboard.update!(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )
      query.update!(parameters: [{ "name" => "start_date", "type" => "integer", "default" => "4" }])

      get "/dashboards/#{dashboard.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="dashboard_filter_start_date"')
      expect(response.body).to include('type="number"')
      expect(response.body).not_to include('type="date"')
      expect(dashboard.reload.parameter_definitions.first).to include("type" => "date", "default" => "2026-08-01")
    end

    it "keeps the stored type when linked charts disagree" do
      data_source = Nquery::DataSource.find_by!(key: "main")
      integer_query = Nquery::Query.create!(
        name: "Integer chart",
        statement: "SELECT {{start_date}} AS start_date",
        data_source: data_source,
        creator: admin,
        collection: root_collection,
        parameters: [{ "name" => "start_date", "type" => "integer", "default" => "4" }]
      )
      string_query = Nquery::Query.create!(
        name: "String chart",
        statement: "SELECT {{start_date}} AS start_date",
        data_source: data_source,
        creator: admin,
        collection: root_collection,
        parameters: [{ "name" => "start_date", "type" => "string", "default" => "north" }]
      )
      integer_chart = Nquery::Chart.create!(
        name: "Integer chart",
        query: integer_query,
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "table" }
      )
      string_chart = Nquery::Chart.create!(
        name: "String chart",
        query: string_query,
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "table" }
      )
      dashboard.dashboard_cards.create!(chart: integer_chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
      dashboard.dashboard_cards.create!(chart: string_chart, pos_x: 6, pos_y: 0, width: 6, height: 4)
      dashboard.update!(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )

      get "/dashboards/#{dashboard.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('type="date"')
      expect(response.body).not_to include('type="number"')
      expect(dashboard.reload.parameter_definitions.first).to include("type" => "date", "default" => "2026-08-01")
    end

    it "does not blank a stored date when removing another filter" do
      data_source = Nquery::DataSource.find_by!(key: "main")
      dated = Nquery::Query.create!(
        name: "SQL date only",
        statement: "SELECT {{start_date}} AS start_date",
        data_source: data_source,
        creator: admin,
        collection: root_collection
      )
      region = Nquery::Query.create!(
        name: "Region variable",
        statement: "SELECT {{region}} AS region",
        data_source: data_source,
        creator: admin,
        collection: root_collection,
        parameters: [{ "name" => "region", "type" => "string", "default" => "north" }]
      )
      dashboard.dashboard_cards.create!(
        chart: Nquery::Chart.create!(
          name: "SQL date only",
          query: dated,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        ),
        pos_x: 0,
        pos_y: 0,
        width: 6,
        height: 4
      )
      dashboard.dashboard_cards.create!(
        chart: Nquery::Chart.create!(
          name: "Region variable",
          query: region,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        ),
        pos_x: 6,
        pos_y: 0,
        width: 6,
        height: 4
      )
      dashboard.update!(
        parameters: [
          { "name" => "start_date", "type" => "date", "default" => "2026-08-01" },
          { "name" => "region", "type" => "string", "default" => "north" }
        ]
      )
      expect(dated.reload.parameters).to eq([])

      get "/dashboards/#{dashboard.id}", params: { edit: "parameters" }

      document = Nokogiri::HTML(response.body)
      item = document.css(".nq-dashboard-filter-list li").find { |node| node.at_css("code")&.text == "{{region}}" }
      patch "/dashboards/#{dashboard.id}", params: nested_dashboard_params(item.at_css("form"))

      expect(response).to redirect_to("/dashboards/#{dashboard.id}")
      kept = dashboard.reload.parameter_definitions.find { |row| row["name"] == "start_date" }
      expect(kept).to include("type" => "date", "default" => "2026-08-01")
      expect(dashboard.parameter_names).to eq(["start_date"])
    end

    it "does not blank a stored date when linking another filter" do
      data_source = Nquery::DataSource.find_by!(key: "main")
      dated = Nquery::Query.create!(
        name: "Unstored date",
        statement: "SELECT {{start_date}} AS start_date",
        data_source: data_source,
        creator: admin,
        collection: root_collection
      )
      region = Nquery::Query.create!(
        name: "Linkable region",
        statement: "SELECT {{region}} AS region",
        data_source: data_source,
        creator: admin,
        collection: root_collection,
        parameters: [{ "name" => "region", "type" => "string", "default" => "north" }]
      )
      dashboard.dashboard_cards.create!(
        chart: Nquery::Chart.create!(
          name: "Unstored date",
          query: dated,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        ),
        pos_x: 0,
        pos_y: 0,
        width: 6,
        height: 4
      )
      dashboard.dashboard_cards.create!(
        chart: Nquery::Chart.create!(
          name: "Linkable region",
          query: region,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        ),
        pos_x: 6,
        pos_y: 0,
        width: 6,
        height: 4
      )
      dashboard.update!(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )
      expect(dated.reload.parameters).to eq([])

      get "/dashboards/#{dashboard.id}", params: { edit: "parameters" }

      form = Nokogiri::HTML(response.body).at_css("form.nq-dashboard-filter-add")
      patch "/dashboards/#{dashboard.id}", params: nested_dashboard_params(form)

      expect(response).to redirect_to("/dashboards/#{dashboard.id}?edit=parameters&wire=region")
      kept = dashboard.reload.parameter_definitions.find { |row| row["name"] == "start_date" }
      expect(kept).to include("type" => "date", "default" => "2026-08-01")
    end

    it "renders chart card action menus" do
      dashboard = Nquery::Dashboard.find_by!(name: "Executive overview")
      chart = Nquery::Chart.find_by!(name: "Revenue by month")

      get "/dashboards/#{dashboard.id}"

      expect(response.body).to include('aria-label="Chart actions"')
      expect(response.body).to include('data-turbo-confirm="Archive this chart?"')
      expect(response.body).to include('data-turbo-confirm="Remove this chart?"')
      expect(response.body).to include("href=\"/dashboards/#{dashboard.id}/charts/#{chart.id}/edit\"")
      expect(response.body).to include("/dashboards/#{dashboard.id}/charts/#{chart.id}/archive")
      expect(response.body).not_to include("href=\"/charts/#{chart.id}\"")
    end

    context "when a card statement references a parameter" do
      let(:data_source) { Nquery::DataSource.find_by!(key: "main") }
      let!(:filtered_card) do
        query = Nquery::Query.create!(
          name: "Needs a date",
          statement: "SELECT 'hidden' AS label WHERE created_at >= {{start_date}}",
          data_source: data_source,
          creator: admin,
          collection: root_collection
        )
        chart = Nquery::Chart.create!(
          name: "Needs a date",
          query: query,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
      end
      let!(:plain_card) do
        query = Nquery::Query.create!(
          name: "Plain value",
          statement: "SELECT 'plain-value' AS label",
          data_source: data_source,
          creator: admin,
          collection: root_collection
        )
        chart = Nquery::Chart.create!(
          name: "Plain value",
          query: query,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        dashboard.dashboard_cards.create!(chart: chart, pos_x: 6, pos_y: 0, width: 6, height: 4)
      end

      it "does not render demo rows for an unresolved placeholder" do
        filtered_card
        plain_card

        get "/dashboards/#{dashboard.id}"

        expect(response.body).not_to include("Jan")
        expect(response.body).not_to include("1200")
        expect(response.body).to include("Enter a value for Start date.")
        expect(response.body).not_to include("This chart could not be loaded.")
        expect(response.body).to include("plain-value")
      end
    end

    context "when a bound statement fails" do
      let(:data_source) { Nquery::DataSource.find_by!(key: "main") }

      it "shows the load error instead of demo rows" do
        board = Nquery::Dashboard.create!(
          name: "Broken bound board",
          collection: root_collection,
          creator: admin,
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
        )
        query = Nquery::Query.create!(
          name: "Broken bound query",
          statement: "SELECT {{start_date}} AS start_date FROM missing_dashboard_table",
          data_source: data_source,
          creator: admin,
          collection: root_collection,
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
        )
        chart = Nquery::Chart.create!(
          name: "Broken bound chart",
          query: query,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        board.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)

        get "/dashboards/#{board.id}"

        expect(response.body).to include("This chart could not be loaded.")
        expect(response.body).not_to include("Jan")
        expect(response.body).not_to include("1200")
      end
    end

    context "when the dashboard has several cards" do
      let(:data_source) { Nquery::DataSource.find_by!(key: "main") }

      it "loads each card query with its data source" do
        2.times do |index|
          query = Nquery::Query.create!(
            name: "Preloaded query #{index}",
            statement: "SELECT #{index} AS label",
            data_source: data_source,
            creator: admin,
            collection: root_collection
          )
          chart = Nquery::Chart.create!(
            name: "Preloaded chart #{index}",
            query: query,
            collection: root_collection,
            creator: admin,
            visualization: { "type" => "table" }
          )
          dashboard.dashboard_cards.create!(chart: chart, pos_x: index * 6, pos_y: 0, width: 6, height: 4)
        end

        queries = []
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |event|
          next if event.payload[:cached] || event.payload[:name] == "SCHEMA"

          queries << event.payload[:sql]
        end
        get "/dashboards/#{dashboard.id}", params: { edit: "parameters" }
        ActiveSupport::Notifications.unsubscribe(subscriber)

        query_loads = queries.count { |sql| sql.match?(/\ASELECT/i) && sql.include?("nquery_queries") }
        data_source_loads = queries.count { |sql| sql.match?(/\ASELECT/i) && sql.include?("nquery_data_sources") }
        expect(query_loads).to eq(1)
        expect(data_source_loads).to eq(1)
      end
    end

    context "when the dashboard declares a date default" do
      let(:data_source) { Nquery::DataSource.find_by!(key: "main") }
      let!(:dated_dashboard) do
        Nquery::Dashboard.create!(
          name: "Dated board",
          collection: root_collection,
          creator: admin,
          parameters: [
            { "name" => "start_date", "type" => "date", "default" => "2026-08-01" }
          ]
        )
      end
      let!(:dated_card) do
        query = Nquery::Query.create!(
          name: "Bound by default",
          statement: "SELECT CASE WHEN {{start_date}} = '2026-08-01' THEN 'default-bound' ELSE 'query-string-bound' END AS label",
          data_source: data_source,
          creator: admin,
          collection: root_collection,
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
        )
        chart = Nquery::Chart.create!(
          name: "Bound by default",
          query: query,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        dated_dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
      end

      before { dated_card }

      it "renders the row bound to the saved default" do
        get "/dashboards/#{dated_dashboard.id}"

        expect(response.body).to include("default-bound")
        expect(response.body).not_to include("query-string-bound")
        expect(response.body).to include("start_date=")
      end

      it "drops the default when the filter is submitted blank" do
        get "/dashboards/#{dated_dashboard.id}", params: { start_date: "" }

        expect(response.body).to include("Enter a value for Start date.")
        expect(response.body).not_to include("This chart could not be loaded.")
        expect(response.body).not_to include("default-bound")
        expect(response.body).not_to include('value="2026-08-01"')
      end

      it "binds the saved date when the chart has no stored parameter" do
        bare = Nquery::Query.create!(
          name: "Placeholder only",
          statement: "SELECT CASE WHEN {{start_date}} = '2026-08-01' THEN 'default-bound' ELSE 'query-string-bound' END AS label",
          data_source: data_source,
          creator: admin,
          collection: root_collection
        )
        bare_chart = Nquery::Chart.create!(
          name: "Placeholder only",
          query: bare,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        board = Nquery::Dashboard.create!(
          name: "Placeholder board",
          collection: root_collection,
          creator: admin,
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
        )
        board.dashboard_cards.create!(chart: bare_chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
        expect(bare.reload.parameters).to eq([])

        get "/dashboards/#{board.id}"

        expect(response.body).to include("default-bound")
        expect(response.body).not_to include("query-string-bound")
        expect(response.body).not_to include("This chart could not be loaded.")
        expect(board.reload.parameter_definitions.first).to include("type" => "date", "default" => "2026-08-01")
      end

      it "applies the same parameter to every chart" do
        query = Nquery::Query.create!(
          name: "Second bound value",
          statement: "SELECT CASE WHEN {{start_date}} = '2026-08-01' THEN 'second-bound' ELSE 'second-miss' END AS label",
          data_source: data_source,
          creator: admin,
          collection: root_collection,
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
        )
        chart = Nquery::Chart.create!(
          name: "Second bound value",
          query: query,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        dated_dashboard.dashboard_cards.create!(chart: chart, pos_x: 6, pos_y: 0, width: 6, height: 4)

        get "/dashboards/#{dated_dashboard.id}"

        expect(response.body).to include("default-bound")
        expect(response.body).to include("second-bound")
        expect(response.body).not_to include("second-miss")
      end

      it "applies a uuid chosen in the filter bar" do
        uuid = "550e8400-e29b-41d4-a716-446655440000"
        uuid_dashboard = Nquery::Dashboard.create!(
          name: "Uuid board",
          collection: root_collection,
          creator: admin,
          parameters: [{ "name" => "customer_id", "type" => "uuid", "default" => "" }]
        )
        query = Nquery::Query.create!(
          name: "Bound by uuid",
          statement: "SELECT CASE WHEN {{customer_id}} = '#{uuid}' THEN 'uuid-bound' ELSE 'uuid-miss' END AS label",
          data_source: data_source,
          creator: admin,
          collection: root_collection,
          parameters: [{ "name" => "customer_id", "type" => "uuid", "default" => "" }]
        )
        chart = Nquery::Chart.create!(
          name: "Bound by uuid",
          query: query,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        uuid_dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)

        get "/dashboards/#{uuid_dashboard.id}", params: { customer_id: uuid.upcase }

        expect(response.body).to include("uuid-bound")
        expect(response.body).not_to include("uuid-miss")
      end

      it "does not apply a uuid filter that is not a uuid" do
        uuid_dashboard = Nquery::Dashboard.create!(
          name: "Invalid uuid board",
          collection: root_collection,
          creator: admin,
          parameters: [{ "name" => "customer_id", "type" => "uuid", "default" => "" }]
        )
        query = Nquery::Query.create!(
          name: "Blocked uuid",
          statement: "SELECT 'should-not-run' AS label WHERE {{customer_id}} = 'x'",
          data_source: data_source,
          creator: admin,
          collection: root_collection,
          parameters: [{ "name" => "customer_id", "type" => "uuid", "default" => "" }]
        )
        chart = Nquery::Chart.create!(
          name: "Blocked uuid",
          query: query,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        uuid_dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)

        get "/dashboards/#{uuid_dashboard.id}", params: { customer_id: "123" }

        expect(response.body).to include("Enter a UUID.")
        expect(response.body).to include("This chart could not be loaded.")
        expect(response.body).not_to include("should-not-run")
      end

      it "applies a boolean chosen in the filter bar" do
        board = Nquery::Dashboard.create!(
          name: "Boolean board",
          collection: root_collection,
          creator: admin,
          parameters: [{ "name" => "active", "type" => "boolean", "default" => "" }]
        )
        query = Nquery::Query.create!(
          name: "Bound by boolean",
          statement: "SELECT CASE WHEN {{active}} = 1 THEN 'boolean-on' ELSE 'boolean-off' END AS label",
          data_source: data_source,
          creator: admin,
          collection: root_collection,
          parameters: [{ "name" => "active", "type" => "boolean", "default" => "" }]
        )
        chart = Nquery::Chart.create!(
          name: "Bound by boolean",
          query: query,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        board.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)

        get "/dashboards/#{board.id}"

        expect(response.body).to include('name="active"')
        expect(response.body).to include(">True<")
        expect(response.body).to include(">False<")

        get "/dashboards/#{board.id}", params: { active: "false" }

        expect(response.body).to include("boolean-off")
        expect(response.body).not_to include("boolean-on")

        get "/dashboards/#{board.id}", params: { active: "true" }

        expect(response.body).to include("boolean-on")
        expect(response.body).not_to include("boolean-off")
      end

      it "does not apply a boolean filter that is not true or false" do
        board = Nquery::Dashboard.create!(
          name: "Invalid boolean board",
          collection: root_collection,
          creator: admin,
          parameters: [{ "name" => "active", "type" => "boolean", "default" => "" }]
        )
        query = Nquery::Query.create!(
          name: "Blocked boolean",
          statement: "SELECT 'should-not-run' AS label WHERE {{active}} = 1",
          data_source: data_source,
          creator: admin,
          collection: root_collection,
          parameters: [{ "name" => "active", "type" => "boolean", "default" => "" }]
        )
        chart = Nquery::Chart.create!(
          name: "Blocked boolean",
          query: query,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        board.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)

        get "/dashboards/#{board.id}", params: { active: "maybe" }

        expect(response.body).to include("Choose true or false.")
        expect(response.body).to include("This chart could not be loaded.")
        expect(response.body).not_to include("should-not-run")
      end

      it "applies a date chosen in the filter bar" do
        get "/dashboards/#{dated_dashboard.id}", params: { start_date: "2026-01-01" }

        expect(response.body).to include("query-string-bound")
        expect(response.body).not_to include("default-bound")
        expect(response.body).to include("2026-01-01")
      end
    end

    context "when a declared parameter has no default" do
      let(:data_source) { Nquery::DataSource.find_by!(key: "main") }
      let!(:undated_dashboard) do
        Nquery::Dashboard.create!(
          name: "Undated board",
          collection: root_collection,
          creator: admin,
          parameters: [
            { "name" => "start_date", "type" => "date", "default" => "" }
          ]
        )
      end
      let!(:undated_card) do
        query = Nquery::Query.create!(
          name: "Missing default",
          statement: "SELECT 'should-not-run' AS label WHERE {{start_date}} = '2026-08-01'",
          data_source: data_source,
          creator: admin,
          collection: root_collection
        )
        chart = Nquery::Chart.create!(
          name: "Missing default",
          query: query,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        undated_dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
      end

      before { undated_card }

      it "shows the load error" do
        get "/dashboards/#{undated_dashboard.id}"

        expect(response.body).to include("Enter a value for Start date.")
        expect(response.body).not_to include("This chart could not be loaded.")
        expect(response.body).not_to include("Jan")
        expect(response.body).not_to include("1200")
        expect(response.body).not_to include("should-not-run")
      end

      it "names every required parameter left blank" do
        board = Nquery::Dashboard.create!(
          name: "Blank values board",
          collection: root_collection,
          creator: admin,
          parameters: [
            { "name" => "label", "type" => "string", "default" => "hello" },
            { "name" => "qty", "type" => "integer", "default" => "3" }
          ]
        )
        query = Nquery::Query.create!(
          name: "Needs both values",
          statement: "SELECT {{label}} AS label, {{qty}} AS qty",
          data_source: data_source,
          creator: admin,
          collection: root_collection
        )
        chart = Nquery::Chart.create!(
          name: "Needs both values",
          query: query,
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        board.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)

        get "/dashboards/#{board.id}", params: { label: "", qty: "" }

        expect(response.body).to include("Enter values for Label and Qty.")
        expect(response.body).not_to include("This chart could not be loaded.")
        expect(response.body).not_to include("hello")
      end
    end

    context "when a parameter is linked to one chart" do
      let(:data_source) { Nquery::DataSource.find_by!(key: "main") }

      it "applies the parameter only to the linked chart" do
        board = Nquery::Dashboard.create!(
          name: "Linked board",
          collection: root_collection,
          creator: admin,
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
        )
        first = Nquery::Chart.create!(
          name: "First linked",
          query: Nquery::Query.create!(
            name: "First linked",
            statement: "SELECT CASE WHEN {{start_date}} = '2026-08-01' THEN 'first-bound' ELSE 'first-miss' END AS label",
            data_source: data_source,
            creator: admin,
            collection: root_collection,
            parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
          ),
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        second = Nquery::Chart.create!(
          name: "Second linked",
          query: Nquery::Query.create!(
            name: "Second linked",
            statement: "SELECT CASE WHEN {{start_date}} = '2026-08-01' THEN 'second-bound' ELSE 'second-miss' END AS label",
            data_source: data_source,
            creator: admin,
            collection: root_collection,
            parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
          ),
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        first_card = board.dashboard_cards.create!(chart: first, pos_x: 0, pos_y: 0, width: 6, height: 4)
        board.dashboard_cards.create!(chart: second, pos_x: 6, pos_y: 0, width: 6, height: 4)

        patch "/dashboards/#{board.id}/cards/#{first_card.id}/parameters", params: { parameter_names: [] }

        expect(response).to redirect_to("/dashboards/#{board.id}")
        expect(board.reload.parameter_definitions.first["chart_ids"]).to eq([second.id])

        get "/dashboards/#{board.id}"

        expect(response.body).to include("second-bound")
        expect(response.body).to include("Enter a value for Start date.")
        expect(response.body).not_to include("This chart could not be loaded.")
        expect(response.body).not_to include("first-bound")
        expect(response.body).not_to include('name="chart_ids[]"')
      end

      it "connects the selected filter from each chart" do
        board = Nquery::Dashboard.create!(
          name: "Wiring board",
          collection: root_collection,
          creator: admin,
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01", "chart_ids" => [] }]
        )
        ready = Nquery::Chart.create!(
          name: "Ready for wiring",
          query: Nquery::Query.create!(
            name: "Ready for wiring",
            statement: "SELECT {{start_date}} AS start_date",
            data_source: data_source,
            creator: admin,
            collection: root_collection
          ),
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        plain = Nquery::Chart.create!(
          name: "Plain for wiring",
          query: Nquery::Query.create!(
            name: "Plain for wiring",
            statement: "SELECT 'plain' AS label",
            data_source: data_source,
            creator: admin,
            collection: root_collection
          ),
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        board.dashboard_cards.create!(chart: ready, pos_x: 0, pos_y: 0, width: 6, height: 4)
        board.dashboard_cards.create!(chart: plain, pos_x: 6, pos_y: 0, width: 6, height: 4)

        get "/dashboards/#{board.id}", params: { wire: "start_date" }

        expect(response.body).to include("Column to filter on")
        expect(response.body).to include("Select...")
        expect(response.body).to include(">{{start_date}}<")
        expect(response.body).to include(%(value="#{ready.id}"))
        expect(response.body).not_to include(%(value="#{plain.id}"))
      end

      it "connects a filter only to charts whose query uses the variable" do
        board = Nquery::Dashboard.create!(
          name: "Connect board",
          collection: root_collection,
          creator: admin,
          parameters: [{ "name" => "customer_id", "type" => "uuid", "default" => "" }]
        )
        ready = Nquery::Chart.create!(
          name: "Ready chart",
          query: Nquery::Query.create!(
            name: "Ready chart",
            statement: "SELECT {{customer_id}} AS customer_id",
            data_source: data_source,
            creator: admin,
            collection: root_collection
          ),
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        plain = Nquery::Chart.create!(
          name: "Plain chart",
          query: Nquery::Query.create!(
            name: "Plain chart",
            statement: "SELECT 'plain' AS label",
            data_source: data_source,
            creator: admin,
            collection: root_collection
          ),
          collection: root_collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        board.dashboard_cards.create!(chart: ready, pos_x: 0, pos_y: 0, width: 6, height: 4)
        board.dashboard_cards.create!(chart: plain, pos_x: 6, pos_y: 0, width: 6, height: 4)

        patch "/dashboards/#{board.id}/parameters/customer_id/charts", params: { chart_ids: [ready.id, plain.id] }

        expect(response).to redirect_to("/dashboards/#{board.id}")
        expect(board.reload.parameter_definitions.first["chart_ids"]).to eq([ready.id])

        get "/dashboards/#{board.id}"

        expect(response.body).to include('name="customer_id"')
        expect(response.body).to include("Ready chart")
      end
    end

    context "when the dashboard is archived" do
      before { dashboard.archive! }

      it "shows an archived notice" do
        get "/dashboards/#{dashboard.id}"

        expect(response.body).to include("This dashboard is archived.")
      end

      it "shows an unarchive action" do
        get "/dashboards/#{dashboard.id}"

        expect(response.body).to include("Unarchive")
        expect(response.body).to include("/dashboards/#{dashboard.id}/unarchive")
        expect(response.body).not_to include("/dashboards/#{dashboard.id}/archive\"")
      end
    end
  end

  describe "GET /collections/:collection_id/dashboards/new" do
    before { sign_in_as_admin }

    it "returns success" do
      get "/collections/#{root_collection.id}/dashboards/new"

      expect(response).to have_http_status(:ok)
    end

    it "renders the new dashboard form" do
      get "/collections/#{root_collection.id}/dashboards/new"

      expect(response.body).to include("New dashboard")
    end
  end

  describe "GET /dashboards/new" do
    before { sign_in_as_admin }

    it "renders the new dashboard form" do
      get "/dashboards/new"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New dashboard")
      expect(response.body).to include("Collection")
    end

    context "when the user lacks curate access" do
      let(:finance_group) { Nquery::Group.create!(name: "Finance", system_group: "custom") }
      let(:member) do
        Nquery::User.create!(email: "finance@example.com", password: "password123", confirmed_at: Time.current).tap do |user|
          Nquery::GroupMembership.create!(user: user, group: finance_group)
          user.ensure_all_users_membership!
        end
      end
      let(:restricted_collection) do
        Nquery::Collection.create!(
          name: "Finance",
          kind: "standard",
          parent: root_collection
        )
      end
      let!(:view_permission) do
        Nquery::CollectionPermission.create!(
          group: finance_group,
          collection: restricted_collection,
          access_level: "view"
        )
      end

      before { sign_in_as(member) }

      it "redirects instead of rendering an empty form" do
        get "/dashboards/new"

        expect(response).to redirect_to("/dashboards")
        expect(flash[:alert]).to include("permission")
      end
    end

    context "when the user can curate a non-root collection" do
      let(:ops_group) { Nquery::Group.create!(name: "Ops", system_group: "custom") }
      let(:member) do
        Nquery::User.create!(email: "ops@example.com", password: "password123", confirmed_at: Time.current).tap do |user|
          Nquery::GroupMembership.create!(user: user, group: ops_group)
          user.ensure_all_users_membership!
        end
      end
      let(:ops_collection) do
        Nquery::Collection.create!(
          name: "Operations",
          kind: "standard",
          parent: root_collection
        )
      end
      let!(:curate_permission) do
        Nquery::CollectionPermission.create!(
          group: ops_group,
          collection: ops_collection,
          access_level: "curate"
        )
      end

      before { sign_in_as(member) }

      it "defaults the form to that collection" do
        get "/dashboards/new"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          %(selected="selected" value="#{ops_collection.id}">#{ops_collection.name})
        )
      end
    end
  end

  describe "POST /dashboards" do
    before { sign_in_as_admin }

    it "creates a dashboard" do
      expect {
        post "/dashboards", params: {
          dashboard: { name: "Ops overview", description: "Daily ops", collection_id: root_collection.id }
        }
      }.to change(Nquery::Dashboard, :count).by(1)

      dashboard = Nquery::Dashboard.find_by!(name: "Ops overview")
      expect(dashboard.collection).to eq(root_collection)
      expect(response).to redirect_to("/dashboards/#{dashboard.id}")
    end

    it "does not raise when a new filter has no type" do
      post "/dashboards", params: {
        dashboard: {
          name: "Untyped filter board",
          collection_id: root_collection.id,
          parameters: [{ name: "start_date" }]
        }
      }

      expect(response).not_to have_http_status(:internal_server_error)
    end

    it "renders errors when the name is blank" do
      post "/dashboards", params: {
        dashboard: { name: "", collection_id: root_collection.id }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not create when the collection is missing" do
      expect {
        post "/dashboards", params: { dashboard: { name: "No collection" } }
      }.not_to change(Nquery::Dashboard, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Collection must exist")
    end

    context "when the user lacks curate access" do
      let(:finance_group) { Nquery::Group.create!(name: "Finance", system_group: "custom") }
      let(:member) do
        Nquery::User.create!(email: "finance@example.com", password: "password123", confirmed_at: Time.current).tap do |user|
          Nquery::GroupMembership.create!(user: user, group: finance_group)
          user.ensure_all_users_membership!
        end
      end
      let(:restricted_collection) do
        Nquery::Collection.create!(
          name: "Finance",
          kind: "standard",
          parent: root_collection
        )
      end
      let!(:view_permission) do
        Nquery::CollectionPermission.create!(
          group: finance_group,
          collection: restricted_collection,
          access_level: "view"
        )
      end

      before { sign_in_as(member) }

      it "does not create a dashboard in a view-only collection" do
        expect {
          post "/dashboards", params: {
            dashboard: { name: "Forbidden", collection_id: restricted_collection.id }
          }
        }.not_to change(Nquery::Dashboard, :count)

        expect(response).to redirect_to("/")
        expect(flash[:alert]).to include("permission")
      end
    end
  end

  describe "GET /dashboards/:id/edit" do
    let!(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Editable board",
        collection: root_collection,
        creator: admin
      )
    end

    before { sign_in_as_admin }

    it "renders the edit form" do
      get "/dashboards/#{dashboard.id}/edit"

      expect(response).to have_http_status(:ok)
    end

    it "does not include parameter fields" do
      dashboard.update!(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )

      get "/dashboards/#{dashboard.id}/edit"

      expect(response.body).not_to include("dashboard[parameters]")
    end
  end

  describe "PATCH /dashboards/:id" do
    let!(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Editable board",
        collection: root_collection,
        creator: admin
      )
    end

    before { sign_in_as_admin }

    it "updates a dashboard" do
      patch "/dashboards/#{dashboard.id}", params: {
        dashboard: { name: "Updated board", description: "Updated", collection_id: root_collection.id }
      }

      expect(response).to redirect_to("/dashboards/#{dashboard.id}")
      expect(dashboard.reload.name).to eq("Updated board")
    end

    it "renders errors for invalid updates" do
      patch "/dashboards/#{dashboard.id}", params: {
        dashboard: { name: "", collection_id: root_collection.id }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "persists declared parameters" do
      patch "/dashboards/#{dashboard.id}", params: {
        dashboard: {
          name: dashboard.name,
          collection_id: root_collection.id,
          parameters: [
            { name: "start_date", type: "date", default: "2026-08-01" },
            { name: "end_date", type: "date", default: "" },
            { name: "", type: "date", default: "" }
          ]
        }
      }

      expect(response).to redirect_to("/dashboards/#{dashboard.id}")
      expect(dashboard.reload.parameter_names).to eq(%w[start_date end_date])
      expect(dashboard.parameters.first["default"]).to eq("2026-08-01")
    end

    it "opens chart linking after adding one filter" do
      patch "/dashboards/#{dashboard.id}", params: {
        dashboard: {
          name: dashboard.name,
          collection_id: root_collection.id,
          parameters: [{ name: "start_date", type: "date", default: "", chart_ids: [""] }]
        }
      }

      expect(response).to redirect_to("/dashboards/#{dashboard.id}?edit=parameters&wire=start_date")
      expect(dashboard.reload.parameter_definitions.first["chart_ids"]).to eq([])
    end

    it "does not save a parameter with a bad type" do
      patch "/dashboards/#{dashboard.id}", params: {
        dashboard: {
          name: dashboard.name,
          collection_id: root_collection.id,
          parameters: [{ name: "start_date", type: "float", default: "" }]
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Parameters must be string, integer, date, datetime, uuid, or boolean")
      expect(response.body).to include("Editable board")
      expect(response.body).not_to include("Edit dashboard:")
      expect(dashboard.reload.parameters).to eq([])
    end

    it "does not save a parameter with a bad default" do
      patch "/dashboards/#{dashboard.id}", params: {
        dashboard: {
          name: dashboard.name,
          collection_id: root_collection.id,
          parameters: [{ name: "start_date", type: "date", default: "2026-02-31" }]
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(dashboard.reload.parameters).to eq([])
    end

    context "when the user lacks curate access" do
      let(:finance_group) { Nquery::Group.create!(name: "Finance", system_group: "custom") }
      let(:member) do
        Nquery::User.create!(email: "finance-edit@example.com", password: "password123", confirmed_at: Time.current).tap do |user|
          Nquery::GroupMembership.create!(user: user, group: finance_group)
          user.ensure_all_users_membership!
        end
      end
      let(:restricted_collection) do
        Nquery::Collection.create!(
          name: "Finance edit",
          kind: "standard",
          parent: root_collection
        )
      end
      let!(:restricted_dashboard) do
        Nquery::CollectionPermission.create!(
          group: finance_group,
          collection: restricted_collection,
          access_level: "view"
        )

        Nquery::Dashboard.create!(
          name: "Finance dashboard",
          collection: restricted_collection,
          creator: member
        )
      end

      before { sign_in_as(member) }

      it "does not update the dashboard" do
        patch "/dashboards/#{restricted_dashboard.id}", params: {
          dashboard: {
            name: "Renamed",
            collection_id: restricted_collection.id,
            parameters: [{ name: "start_date", type: "date", default: "2026-08-01" }]
          }
        }

        expect(response).to redirect_to("/")
        expect(flash[:alert]).to include("permission")
        expect(restricted_dashboard.reload.name).to eq("Finance dashboard")
        expect(restricted_dashboard.parameters).to eq([])
      end
    end
  end

  describe "PATCH /dashboards/:id/update_layout" do
    let!(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Layout board",
        collection: root_collection,
        creator: admin
      )
    end
    let!(:card) do
      query = Nquery::Query.create!(
        name: "Layout query",
        statement: "SELECT 1 AS value",
        data_source: Nquery::DataSource.find_by!(key: "main"),
        creator: admin,
        collection: root_collection
      )
      chart = Nquery::Chart.create!(
        name: "Layout chart",
        query: query,
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "bar" }
      )
      dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
    end

    before { sign_in_as_admin }

    it "updates card layout positions" do
      patch "/dashboards/#{dashboard.id}/update_layout", params: {
        cards: { card.id => { x: 1, y: 2, w: 4, h: 3 } }
      }

      expect(response).to have_http_status(:ok)
      expect(card.reload.pos_x).to eq(1)
      expect(card.pos_y).to eq(2)
    end
  end

  describe "POST /collections/:collection_id/dashboards" do
    before { sign_in_as_admin }

    it "creates a dashboard" do
      expect {
        post "/collections/#{root_collection.id}/dashboards", params: {
          dashboard: { name: "Ops overview", description: "Daily ops" }
        }
      }.to change(Nquery::Dashboard, :count).by(1)

      dashboard = Nquery::Dashboard.find_by!(name: "Ops overview")
      expect(dashboard.collection).to eq(root_collection)
      expect(response).to redirect_to("/dashboards/#{dashboard.id}")
    end
  end

  describe "DELETE /dashboards/:id" do
    let!(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Temporary board",
        collection: root_collection,
        creator: admin
      )
    end

    before { sign_in_as_admin }

    it "destroys the dashboard" do
      expect {
        delete "/dashboards/#{dashboard.id}"
      }.to change(Nquery::Dashboard, :count).by(-1)

      expect(response).to redirect_to("/dashboards")
      expect(flash[:notice]).to eq("Dashboard removed.")
    end
  end

  describe "PATCH /dashboards/:id/archive" do
    let!(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Ops overview",
        collection: root_collection,
        creator: admin
      )
    end

    before { sign_in_as_admin }

    it "archives the dashboard" do
      patch "/dashboards/#{dashboard.id}/archive"

      expect(response).to redirect_to("/dashboards")
      expect(flash[:notice]).to eq("Dashboard archived.")
      expect(dashboard.reload.archived?).to be(true)
    end

    it "hides the dashboard from collection pages" do
      patch "/dashboards/#{dashboard.id}/archive"

      get "/collections/#{root_collection.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(dashboard.name)
    end

    context "when the user lacks curate access" do
      let(:finance_group) { Nquery::Group.create!(name: "Finance", system_group: "custom") }
      let(:member) do
        Nquery::User.create!(email: "finance@example.com", password: "password123", confirmed_at: Time.current).tap do |user|
          Nquery::GroupMembership.create!(user: user, group: finance_group)
          user.ensure_all_users_membership!
        end
      end
      let(:restricted_collection) do
        Nquery::Collection.create!(
          name: "Finance",
          kind: "standard",
          parent: root_collection
        )
      end
      let!(:restricted_dashboard) do
        Nquery::CollectionPermission.create!(
          group: finance_group,
          collection: restricted_collection,
          access_level: "view"
        )

        Nquery::Dashboard.create!(
          name: "Finance dashboard",
          collection: restricted_collection,
          creator: member
        )
      end

      before { sign_in_as(member) }

      it "denies access" do
        patch "/dashboards/#{restricted_dashboard.id}/archive"

        expect(response).to redirect_to("/")
        expect(flash[:alert]).to include("permission")
        expect(restricted_dashboard.reload.archived?).to be(false)
      end
    end
  end

  describe "PATCH /dashboards/:id/unarchive" do
    let!(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Ops overview",
        collection: root_collection,
        creator: admin
      )
    end

    before do
      dashboard.archive!
      sign_in_as_admin
    end

    it "unarchives the dashboard" do
      patch "/dashboards/#{dashboard.id}/unarchive"

      expect(response).to redirect_to("/dashboards/#{dashboard.id}")
      expect(flash[:notice]).to eq("Dashboard unarchived.")
      expect(dashboard.reload.archived?).to be(false)
    end
  end

  describe "PATCH /dashboards/:id/parameters/:name/charts" do
    context "when the user lacks curate access" do
      let(:finance_group) { Nquery::Group.create!(name: "Finance", system_group: "custom") }
      let(:member) do
        Nquery::User.create!(email: "finance-connect@example.com", password: "password123", confirmed_at: Time.current).tap do |user|
          Nquery::GroupMembership.create!(user: user, group: finance_group)
          user.ensure_all_users_membership!
        end
      end
      let(:restricted_collection) do
        Nquery::Collection.create!(
          name: "Finance connect",
          kind: "standard",
          parent: root_collection
        )
      end
      let!(:restricted_dashboard) do
        Nquery::CollectionPermission.create!(
          group: finance_group,
          collection: restricted_collection,
          access_level: "view"
        )

        Nquery::Dashboard.create!(
          name: "Finance dashboard",
          collection: restricted_collection,
          creator: member,
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01", "chart_ids" => [] }]
        )
      end

      before { sign_in_as(member) }

      it "does not connect the filter" do
        patch "/dashboards/#{restricted_dashboard.id}/parameters/start_date/charts", params: { chart_ids: [1] }

        expect(response).to redirect_to("/")
        expect(flash[:alert]).to include("permission")
        expect(restricted_dashboard.reload.parameter_definitions.first["chart_ids"]).to eq([])
      end
    end
  end

  describe "PATCH /dashboards/:id/cards/:id/parameters" do
    let(:data_source) { Nquery::DataSource.find_by!(key: "main") }

    context "when the user lacks curate access" do
      let(:finance_group) { Nquery::Group.create!(name: "Finance", system_group: "custom") }
      let(:member) do
        Nquery::User.create!(email: "finance-cards@example.com", password: "password123", confirmed_at: Time.current).tap do |user|
          Nquery::GroupMembership.create!(user: user, group: finance_group)
          user.ensure_all_users_membership!
        end
      end
      let(:restricted_collection) do
        Nquery::Collection.create!(
          name: "Finance cards",
          kind: "standard",
          parent: root_collection
        )
      end
      let!(:restricted_dashboard) do
        Nquery::CollectionPermission.create!(
          group: finance_group,
          collection: restricted_collection,
          access_level: "view"
        )

        Nquery::Dashboard.create!(
          name: "Finance dashboard",
          collection: restricted_collection,
          creator: member,
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
        )
      end
      let!(:card) do
        chart = Nquery::Chart.create!(
          name: "Finance chart",
          query: Nquery::Query.create!(
            name: "Finance chart",
            statement: "SELECT {{start_date}} AS start_date",
            data_source: data_source,
            creator: member,
            collection: restricted_collection
          ),
          collection: restricted_collection,
          creator: member,
          visualization: { "type" => "table" }
        )
        restricted_dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
      end

      before { sign_in_as(member) }

      it "does not change the chart parameters" do
        patch "/dashboards/#{restricted_dashboard.id}/cards/#{card.id}/parameters", params: { parameter_names: [] }

        expect(response).to redirect_to("/")
        expect(flash[:alert]).to include("permission")
        expect(restricted_dashboard.reload.parameter_definitions).to eq(
          [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
        )
      end
    end
  end
end
