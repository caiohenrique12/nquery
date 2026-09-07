# frozen_string_literal: true

require "rails_helper"

RSpec.describe Nquery::DataSourcesHelper, type: :helper do
  include Nquery::Engine.routes.url_helpers

  before do
    helper.extend Nquery::Engine.routes.url_helpers
  end

  describe "#data_source_form_url" do
    context "when the data source is persisted" do
      it "returns the admin update path" do
        data_source = Nquery::DataSource.new(adapter: "postgresql")
        allow(data_source).to receive_messages(persisted?: true, to_param: "42")

        expect(helper.data_source_form_url(data_source)).to eq(admin_data_source_path(data_source))
      end
    end

    context "when the data source is new" do
      it "returns the admin collection path" do
        expect(helper.data_source_form_url(Nquery::DataSource.new)).to eq(admin_data_sources_path)
      end
    end
  end

  describe "#data_source_form_method" do
    context "when the data source is persisted" do
      it "returns patch" do
        data_source = Nquery::DataSource.new(adapter: "postgresql")
        allow(data_source).to receive(:persisted?).and_return(true)

        expect(helper.data_source_form_method(data_source)).to eq(:patch)
      end
    end

    context "when the data source is new" do
      it "returns post" do
        expect(helper.data_source_form_method(Nquery::DataSource.new)).to eq(:post)
      end
    end
  end
end
