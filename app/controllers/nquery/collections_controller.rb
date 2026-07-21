# frozen_string_literal: true

module Nquery
  class CollectionsController < ApplicationController
    include Browsable

    before_action :set_collection, only: %i[show edit update destroy archive unarchive]
    before_action :set_parent_collection, only: %i[new create]
    before_action :authorize_collection_view!, only: %i[show]
    before_action :authorize_collection_curate!, only: %i[edit update destroy archive unarchive]
    before_action :authorize_parent_curate!, only: %i[new create]

    before_action :prevent_root_deletion, only: %i[destroy]
    before_action :prevent_root_archival, only: %i[archive]

    def index
      @collections = viewable_collections
    end

    def show
      load_collection_contents(@collection)
    end

    def new
      @collection = Collection.new(kind: "standard", parent: @parent_collection)
      @parent_collections = assignable_collections
    end

    def create
      @collection = Collection.new(collection_params.merge(kind: "standard", parent: @parent_collection))
      @parent_collections = assignable_collections

      if @collection.save
        redirect_to collection_path(@collection), notice: "Collection created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @parent_collections = assignable_collections.reject { |c| c.id == @collection.id }
    end

    def update
      @parent_collections = assignable_collections.reject { |c| c.id == @collection.id }
      if collection_params[:parent_id].present?
        parent = Collection.find_by(id: collection_params[:parent_id])
        authorize_collection_access!(parent, required: :curate) if parent
      end

      if @collection.update(collection_params)
        redirect_to collection_path(@collection), notice: "Collection updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @collection.destroy
      redirect_to collections_path, notice: "Collection deleted."
    end

    def archive
      @collection.archive!
      redirect_to collections_path, notice: "Collection archived."
    end

    def unarchive
      @collection.unarchive!
      redirect_to collection_path(@collection), notice: "Collection unarchived."
    end

    private

    def set_collection
      @collection = Collection.find(params[:id])
    end

    def set_parent_collection
      return if params[:collection_id].blank?

      @parent_collection = Collection.find(params[:collection_id])
    end

    def authorize_parent_curate!
      parent_id = params.dig(:collection, :parent_id)
      parent = @parent_collection || Collection.find_by(id: parent_id)
      return if parent.nil?

      authorize_collection_access!(parent, required: :curate)
    end

    def authorize_collection_view!
      authorize_collection_access!(@collection, required: :view)
    end

    def authorize_collection_curate!
      authorize_collection_access!(@collection, required: :curate)
    end

    def prevent_root_deletion
      return unless @collection.kind == "root"

      redirect_to collections_path, alert: "Root collections cannot be deleted."
    end

    def prevent_root_archival
      return unless @collection.kind == "root"

      redirect_to collections_path, alert: "Root collections cannot be archived."
    end

    def collection_params
      params.require(:collection).permit(:name, :parent_id)
    end
  end
end
