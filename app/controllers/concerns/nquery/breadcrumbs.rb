# frozen_string_literal: true

module Nquery
  module Breadcrumbs
    extend ActiveSupport::Concern

    included do
      append_before_action :set_breadcrumbs, unless: :skip_breadcrumbs?
      helper_method :breadcrumbs
    end

    def set_breadcrumbs
      @breadcrumbs = build_breadcrumbs
    end

    def breadcrumbs
      @breadcrumbs || []
    end

  private

    def skip_breadcrumbs?
      auth_exempt? || controller_path == "nquery/home"
    end

    def build_breadcrumbs
      crumbs = [{ label: "Home", path: root_path }]

      case controller_path
      when "nquery/collections"
        append_section_breadcrumb(crumbs, "Collections", collections_path)

        case action_name
        when "show"
          append_resource_breadcrumb(crumbs, breadcrumb_collection)
        when "edit"
          append_resource_breadcrumb(crumbs, breadcrumb_collection, path: collection_path(breadcrumb_collection), link: true)
          append_terminal_breadcrumb(crumbs, "Edit")
        when "new"
          if breadcrumb_parent_collection
            append_resource_breadcrumb(
              crumbs,
              breadcrumb_parent_collection,
              path: collection_path(breadcrumb_parent_collection),
              link: true
            )
          end
          append_terminal_breadcrumb(crumbs, "New")
        end
      when "nquery/dashboards"
        append_section_breadcrumb(crumbs, "Dashboards", dashboards_path)

        case action_name
        when "show"
          append_resource_breadcrumb(crumbs, breadcrumb_dashboard)
        when "edit"
          append_resource_breadcrumb(crumbs, breadcrumb_dashboard, path: dashboard_path(breadcrumb_dashboard), link: true)
          append_terminal_breadcrumb(crumbs, "Edit")
        end
      when "nquery/collection/dashboards"
        append_section_breadcrumb(crumbs, "Collections", collections_path)
        append_resource_breadcrumb(
          crumbs,
          breadcrumb_parent_collection,
          path: collection_path(breadcrumb_parent_collection),
          link: true
        )
        append_terminal_breadcrumb(crumbs, "New dashboard")
      when "nquery/dashboard/charts"
        append_section_breadcrumb(crumbs, "Dashboards", dashboards_path)
        append_resource_breadcrumb(
          crumbs,
          breadcrumb_dashboard,
          path: dashboard_path(breadcrumb_dashboard),
          link: true
        )

        case action_name
        when "show"
          append_resource_breadcrumb(crumbs, breadcrumb_chart)
        when "edit", "embed"
          append_resource_breadcrumb(crumbs, breadcrumb_chart, path: dashboard_chart_path(breadcrumb_dashboard, breadcrumb_chart), link: true)
          append_terminal_breadcrumb(crumbs, action_name.titleize)
        when "new"
          append_terminal_breadcrumb(crumbs, "New chart")
        end
      when "nquery/queries"
        append_section_breadcrumb(crumbs, "Queries", nil)
        append_terminal_breadcrumb(crumbs, query_breadcrumb_label)
      when "nquery/charts"
        append_section_breadcrumb(crumbs, "Collections", collections_path)
        if breadcrumb_chart&.collection
          append_resource_breadcrumb(
            crumbs,
            breadcrumb_chart.collection,
            path: collection_path(breadcrumb_chart.collection),
            link: true
          )
        end

        case action_name
        when "show"
          append_resource_breadcrumb(crumbs, breadcrumb_chart)
        when "edit", "embed"
          append_resource_breadcrumb(crumbs, breadcrumb_chart, path: chart_path(breadcrumb_chart), link: true)
          append_terminal_breadcrumb(crumbs, action_name.titleize)
        when "new"
          append_terminal_breadcrumb(crumbs, "New chart")
        end
      when "nquery/imports"
        append_terminal_breadcrumb(crumbs, "Import CSV")
      when "nquery/admin/logs"
        append_section_breadcrumb(crumbs, "Logs", admin_logs_path)
      when "nquery/admin/users"
        append_section_breadcrumb(crumbs, "Users", admin_users_path)

        case action_name
        when "show"
          append_resource_breadcrumb(crumbs, breadcrumb_user)
        when "edit"
          append_resource_breadcrumb(crumbs, breadcrumb_user, path: admin_user_path(breadcrumb_user), link: true)
          append_terminal_breadcrumb(crumbs, "Edit user")
        when "new"
          append_terminal_breadcrumb(crumbs, "Invite user")
        end
      when "nquery/admin/groups"
        append_section_breadcrumb(crumbs, "Groups", admin_groups_path)

        case action_name
        when "show"
          append_resource_breadcrumb(crumbs, breadcrumb_group)
        when "edit"
          append_resource_breadcrumb(crumbs, breadcrumb_group, path: admin_group_path(breadcrumb_group), link: true)
          append_terminal_breadcrumb(crumbs, "Edit group")
        when "new"
          append_terminal_breadcrumb(crumbs, "New group")
        end
      when "nquery/admin/data_sources"
        append_section_breadcrumb(crumbs, "Data sources", admin_data_sources_path)

        case action_name
        when "edit"
          append_resource_breadcrumb(
            crumbs,
            breadcrumb_data_source,
            path: edit_admin_data_source_path(breadcrumb_data_source),
            link: true
          )
          append_terminal_breadcrumb(crumbs, "Edit data source")
        when "new"
          append_terminal_breadcrumb(crumbs, "New data source")
        end
      when "nquery/admin/permissions"
        append_section_breadcrumb(crumbs, "Permissions", by_group_admin_permissions_path)
      end

      mark_terminal_section!(crumbs)
      crumbs
    end

    def breadcrumb_collection
      @breadcrumb_collection ||= if @collection&.persisted?
                                   @collection
                                 elsif params[:id].present?
                                   Collection.find_by(id: params[:id])
                                 end
    end

    def breadcrumb_parent_collection
      @breadcrumb_parent_collection ||= if @parent_collection
                                        @parent_collection
                                      elsif @collection&.persisted?
                                        @collection
                                      elsif params[:collection_id].present?
                                        Collection.find_by(id: params[:collection_id])
                                      end
    end

    def breadcrumb_dashboard
      @breadcrumb_dashboard ||= if @dashboard&.persisted?
                                  @dashboard
                                elsif params[:dashboard_id].present?
                                  Dashboard.find_by(id: params[:dashboard_id])
                                elsif controller_path == "nquery/dashboards" && params[:id].present?
                                  Dashboard.find_by(id: params[:id])
                                end
    end

    def breadcrumb_chart
      @breadcrumb_chart ||= if @chart&.persisted?
                              @chart
                            elsif params[:id].present?
                              Chart.find_by(id: params[:id])
                            end
    end

    def breadcrumb_user
      @breadcrumb_user ||= @user || User.find_by(id: params[:id])
    end

    def breadcrumb_group
      @breadcrumb_group ||= @group || Group.find_by(id: params[:id])
    end

    def breadcrumb_data_source
      @breadcrumb_data_source ||= @data_source || DataSource.find_by(id: params[:id])
    end

    def query_breadcrumb_label
      case action_name
      when "new" then "New SQL query"
      when "edit" then "Edit query: #{@query&.name.presence || 'Untitled'}"
      else @query&.name.presence || "Query"
      end
    end

    def append_section_breadcrumb(crumbs, label, path)
      crumbs << { label: label, path: path, section: true }
    end

    def append_resource_breadcrumb(crumbs, resource, path: nil, link: false)
      return unless resource&.name.present?

      crumbs << { label: resource.name, path: link ? path : nil }
    end

    def append_terminal_breadcrumb(crumbs, label)
      crumbs << { label: label, path: nil }
    end

    def mark_terminal_section!(crumbs)
      last_crumb = crumbs.last
      return unless last_crumb[:section]

      last_crumb[:path] = nil
    end
  end
end
