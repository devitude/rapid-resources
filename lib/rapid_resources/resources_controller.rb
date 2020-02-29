module RapidResources
  module ResourcesController
    extend ActiveSupport::Concern

    # class << self
    #   [:before, :after, :around].each do |callback|
    #     define_method "#{callback}_load_res" do |*names, &blk|
    #       _insert_callbacks(names, blk) do |name, options|
    #         set_callback(:load_res, callback, name, options)
    #       end
    #     end
    #   end
    # end

    included do
      # append_view_path File.expand_path("../../views", __FILE__)

      # include ActiveSupport::Callbacks

      before_action :load_res
      helper_method :filter_params

      define_callbacks :load_res
    end

    # define_callbacks :load_res

    class_methods do
      def model_class
        nil
      end

      def page_class
        nil
      end

      # def before_load_res(*args, &block) # :nodoc:
      #   # set_options_for_callbacks!(args)
      #   set_callback(:before_load_res, :before, *args, &block)
      # end

      # def after_load_res(*args, &block) # :nodoc:
      #   # set_options_for_callbacks!(args)
      #   set_callback(:after_load_res, :before, *args, &block)
      # end

      # define_callbacks :load_res

      # def before_load_res(*names, &blk)
      #   _insert_callbacks(names, blk) do |name, options|
      #     set_callback(:load_res, :before, name, options)
      #   end
      # end

      # [:before, :after, :around].each do |callback|
      #   define_method "#{callback}_load_res" do |*names, &blk|
      #     _insert_callbacks(names, blk) do |name, options|
      #       set_callback(:load_res, callback, name, options)
      #     end
      #   end
      # end
    end

    def index
      authorize_resource :index?

      respond_to do |format|
        # format.xlsx do
        #   items, columns = grid_items
        #   xlsx_path = generate_xlsx_file(items, columns)
        #   send_file xlsx_path, filename: xlsx_filename, type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        # end
        format.jsonapi do
          grid_list
        end
        format.any do
          if page.index_html
            items = load_items
          else
            # index page is not a HTML table of items, don't load items
            items = []
          end

          if Rails.env.test?
            # probably should assign @items and @page for every request and not make them locals
            @items = items
            @page = page
          end

          yield if block_given?

          render locals: {
            items: items,
            page: page,
          } unless response_rendered?
        end
      end
    end

    def new
      authorize_resource :new?

      return if response_rendered?

      r_params = {
        locals: {
          item: @resource,
          page: page
        }
      }

      respond_to do |format|
        format.html { render r_params}
        format.json do
          @modal = true
          # @html = render_to_string(r_params.merge(layout: false, formats: [:html]))
          # render formats: [:json]
          json_data = {
            'html' => render_to_string(r_params.merge(layout: false, formats: [:html]))
          }
          json_data.merge! get_additional_json_data
          render json: json_data #, formats: [:json]
        end
        format.jsonapi do
          render_jsonapi_form
        end
      end
    end

    def create
      authorize_resource :create?

      result = save_resource(@resource, resource_params)
      if result.ok?
        save_response(:create)
        return
      end

      save_response(:create, false)
      return if response_rendered?

      r_params = {
        locals: {
          item: @resource,
          page: page
        }
      }

      respond_to do |format|
        format.html { render :new, r_params}
        format.json do
          if jsonapi_form?
            render_jsonapi_form(error: result)
          else
            @modal = true
            # @html = render_to_string(:new, r_params.merge(layout: false, formats: [:html]))
            # render :new, formats: [:json]
            json_data = {
              'html' => render_to_string(:new, r_params.merge(layout: false, formats: [:html]))
            }
            json_data.merge! get_additional_json_data
            render json: json_data #, formats: [:json]
          end
        end
        format.jsonapi do
          if jsonapi_form?
            render_jsonapi_form(error: result)
          else
            render_jsonapi_resource_error
          end
        end
      end
    end

    def show
      authorize_resource :show?

      yield if block_given?

      return if response_rendered?
      render locals: {
        item: @resource,
        page: page
      }
    end

    def edit
      authorize_resource :edit?

      yield if block_given?

      return if response_rendered?
      r_params = {
        locals: {
          item: @resource,
          page: page
        }
      }

      respond_to do |format|
        format.html { render r_params}
        format.json do
          @modal = true
          json_data = {
            'html' => render_to_string(r_params.merge(layout: false, formats: [:html]))
          }
          if page.form(@resource).show_destroy_btn && resource_action_permitted?(:destroy?)
            begin
              json_data['deleteUrl'] = url_for(action: :destroy)
            rescue => ex
              Utils.report_exception(ex)
            end
          end
          json_data.merge! get_additional_json_data
          render json: json_data #, formats: [:json]
        end
        format.jsonapi do
          render_jsonapi_form
        end
      end
    end

    def update
      authorize_resource :update?

      yield if block_given?

      result = save_resource(@resource, resource_params)
      if result.ok?
        save_response(:update)
        return
      end

      save_response(:update, false)

      return if response_rendered?

      r_params = {
        locals: {
          item: @resource,
          page: page
        }
      }

      respond_to do |format|
        format.html { render :edit, r_params}
        format.json do
          if jsonapi_form?
            render_jsonapi_form(error: result)
          else
            @modal = true
            # @html = render_to_string(:new, r_params.merge(layout: false, formats: [:html]))
            # render :new, formats: [:json]
            json_data = {
              'html' => render_to_string(:edit, r_params.merge(layout: false, formats: [:html]))
            }
            json_data.merge! get_additional_json_data
            render json: json_data #, formats: [:json]
          end
        end
        format.jsonapi do
          render_jsonapi_form(error: result)
        end
      end
    end

    def destroy
      authorize_resource :destroy?
      destroy_resource

      return if response_rendered?

      if request.xhr?
        head :no_content # this will show "no element found" error in Firefox console
      else
        redirect_to redirect_route(:destroy)
      end
    end

    protected

    def _prefixes
      # add resources
      super << 'resources'
    end

    def jsonapi_form?
      params[:jsonapi_form] == '1'
    end

    # FIXME: use ActionController::Metal.performed? instead
    def response_rendered?
      response_body
    end

    def resource_resolver
      @resource_resolver ||= ResourceResolver.new(controller_path,
        model_class: self.class.model_class,
        page_class: self.class.page_class)
    end

    def page
      @page ||= create_page
    end

    # FIXME: migrate all pages and get rid of extra_params
    def create_page(page_class: nil, resource: nil)
      page_class ||= self.class.page_class
      new_page = resource_resolver.page(current_user, page_class: page_class, resource: resource, url_helpers: self)
      if expose_items = page_expose
        new_page.expose(expose_items)
      end
      new_page
    end

    def page_expose
      nil
    end

    def setup_page(page)
    end

    def jsonapi_params_deserializer
      nil
    end

    def resource_params
      if request.format.jsonapi? && (deserializer = jsonapi_params_deserializer)
        resp = deserializer.call(params[:_jsonapi].to_unsafe_h)
        r_params = ActionController::Parameters.new(@resource_resolver.params_name => resp)
        r_params.require(@resource_resolver.params_name).permit(page.permitted_attributes(@resource))
      else
        params.require(@resource_resolver.params_name).permit(page.permitted_attributes(@resource))
      end
    end

    def filter_params(page)
      permitted_fields = []
      if form_fields = page.filter_form
        form_fields.each do |f|
          permitted_fields.concat f.params
        end
      end
      params.permit(filter: permitted_fields)[:filter]
    end

    # apply additional filter, can be used for nested resources
    def filter_index_items(items)
      items
    end

    def load_res
      run_callbacks :load_res do
        @page ||= create_page
        @resource ||= load_resource
        @page.resource = @resource
        instance_variable_set("@#{resource_var_name}".to_sym, @resource)
      end
    end

    def load_items
      page.load_items(filter_params: params)
    end

    def load_resource
      model = resource_resolver.model_class
      case params[:action]
      when *load_item_actions
        load_current_resource(model)
      when 'new', 'create'
        if respond_to?(:build_model, true)
          build_model
        elsif model.respond_to?(:build_new)
          model.build_new
        else
          model.new
        end
      else
        nil
      end
    end

    def load_item_actions
      ['edit', 'update', 'destroy', 'show']
    end

    # in case a resource initializes it's model with some custom logick
    # def build_model; end

    def index_route_url
      { action: :index }
    end

    def redirect_route(action = nil)
      index_route_url
    end

    def current_resource_id
      params[page.object_param]
    end

    def resource_var_name
      resource_resolver.resource_var_name
    end

    def load_current_resource(model = nil, resource_page = nil)
      model ||= resource_resolver.model_class
      resource_page ||= page

      resource = if resource_page.use_page_scope
        resource_page.default_scope
      else
        model.respond_to?(:alive) ? model.alive : model
      end
      resource.where(model.primary_key => current_resource_id).first!
    end

    def destroy_resource
      if object_type = page.oplog_object_type
        OperationLog.destroy_object(current_user, object_type, @resource.id, page.oplog_delete_description(@resource), request.ip) do |oplog|
          _do_destroy_resource(delete_operation_id: oplog.id)
        end
      else
        _do_destroy_resource()
      end
    end

    def save_response(action, saved = true)
      return unless saved

      respond_to do |format|
        format.html { redirect_to redirect_route(action) }
        format.json do
          if jsonapi_form?
            render jsonapi: @resource, expose: { url_helpers: self, current_user: current_user }, status: 201
          else
            json_data = {'status' => 'success'}
            json_data.merge! get_additional_json_data
            render json: json_data
          end
        end
        format.jsonapi do
          render_jsonapi_resource
        end
      end
    end

    def get_additional_json_data
      {}
    end

    def authorize_resource(query)
      nil
    end

    def resource_action_permitted?(action)
      false
    end

    def save_resource(resource, params)
      resource.assign_attributes(resource_params)
      if resource.valid?(:form) && resource.save
        Result.ok
      else
        Result.err
      end
    end

    def grid_items(grid_page: nil, grid_items: nil)
      grid_page ||= page

      filter_params = if params.key?(:filter)
        params.fetch(:filter, {}).permit(*grid_page.filter_params).to_h
      else
        params.permit(*grid_page.filter_params).to_h
      end

      grid_page.sort_param = params[:sort].to_s if params[:sort]
      grid_page.filter_args = filter_params#params.permit(*grid_page.filter_params).to_h
      grid_items ||= grid_page.load_items(filter_params: filter_params)

      return [grid_items, grid_page.collection_fields.dup]
    end

    def grid_list(grid_page: nil, grid_items: nil, jsonapi_include: nil, additional_meta: nil)
      grid_page ||= page

      grid_items, columns = grid_items(grid_page: grid_page, grid_items: grid_items)

      if grid_page.grid_paging && grid_items.respond_to?(:page)
        grid_items = grid_items.page params[:page]
        if per_page = grid_page.per_page
          grid_items = grid_items.per(per_page)
        end
        grid_items = grid_items.page(1) if grid_items.current_page > grid_items.total_pages
        paginator = GridPaginator.new(total_pages: grid_items.total_pages, current_page: grid_items.current_page, per_page: grid_items.current_per_page)
      end

      if grid_page.collection_actions.include?(:edit)
        columns << CollectionField.new(':actions', title: '', sortable: false)
      end

      meta_fields = {
        columns: columns.map(&:to_jsonapi_column),
        filters: grid_page.grid_filters.map(&:to_jsonapi_filter),
        pages: paginator&.pages,
        current_page: paginator&.current_page,
        total_pages: paginator&.total_pages,
        page_first_index: paginator&.first_idx_in_page || 1,
        headerActions: grid_page.grid_header_actions,
        additional_header_actions: grid_page.grid_additional_header_actions,
      }
      meta_fields.merge!(additional_meta) if additional_meta.is_a?(Hash)

      jsonapi_index_response(grid_items,
        serializers: grid_page.grid_serializers,
        meta: grid_meta(meta_fields),
        links: grid_links(grid_page),
        render_fields: grid_page.grid_fields,
        expose: grid_page.grid_expose,
        jsonapi_include: jsonapi_include,
        )
    end

    def jsonapi_index_response(items, serializers: {}, meta: nil, links: nil, expose: {}, render_fields: nil, jsonapi_include: nil)
      renderer = JSONAPI::Serializable::Renderer.new
      jsonapi_options = {
        class: serializers,
        meta: meta,
        links: links,
        expose: {
          url_helpers: self,
          current_user: current_user,
        }.merge(expose || {})
      }
      jsonapi_options[:fields] = render_fields if render_fields
      jsonapi_options[:include] = jsonapi_include if jsonapi_include
      json_data = renderer.render(items, jsonapi_options)
      render json: json_data, type: 'application/vnd.api+json'
    end

    def grid_links(page)
      { new: url_for({ action: :new}) } if page.index_actions.include?(:new)
    end

    def grid_meta(attributes)
      attributes
    end

    def xlsx_filename
      'items.xlsx'
    end

    def generate_xlsx_file(items, columns, sheet_name: 'Items')
      xlsx = Axlsx::Package.new do |package|
        package.workbook.use_shared_strings = true # otherwise file can not be read back by rubyXL
        package.workbook.add_worksheet(name: sheet_name) do |sheet|
          # add each item to table
        end
      end

      uid = current_user ? "-#{current_user.id}" : nil
      temp_path = Rails.root.join('tmp', "items-#{Time.now.to_f}#{uid}.xlsx")
      xlsx.serialize temp_path
      temp_path
    end

    def render_jsonapi_form(error: nil, form_id: nil, form_page: nil)
      form_page ||= page

      old_modal = @modal
      old_display_errors = form_page.display_form_errors
      @modal = true
      form_page.display_form_errors = false
      form_data = ResourceFormData.new(id: "frm-#{resource_resolver.model_name}") #(id: 'new-project')
      # form_data.submit_title = @resource.new_record? ? 'Create new project' : 'Save project' # page.t(@resource.persisted? ? :'form_action.update' : :'form_action.create')
      form_data.submit_title = form_page.t(@resource.persisted? ? :'form_action.update' : :'form_action.create')
      form_data.html = render_to_string(partial: 'form',
        formats: [:html],
        locals: {
          page: form_page,
          item: @resource,
          jsonapi_form: 1,
        })
      @modal = old_modal
      form_page.display_form_errors = old_display_errors

      if error.present?
        if error.is_a?(Result) && error.error.present?
          form_data.meta = { error: { message: "An error occured: #{error.error}"} }
        else
          form_data.meta = { error: { message: 'An error occured', details: @resource.error_messages.map(&:second) } }
        end
        render jsonapi: form_data, status: 422
      else
        render jsonapi: form_data, expose: { url_helpers: self, current_user: current_user }
      end
    end

    def render_jsonapi_resource
      render jsonapi: @resource, expose: { url_helpers: self, current_user: current_user }, status: 200
    end

    def render_jsonapi_resource_error
      render jsonapi_errors: @resource.errors, status: 422
    end

    def render_page(page, resource, template, options = {})
      return if response_rendered?
      render_options = {
        locals: {
          item: resource,
          page: page,
          action: template,
        }
      }.merge(options)
      render render_options
    end

    private

    def _do_destroy_resource(attrs = {})
      if page.soft_destroy
        @resource.update({is_deleted: true}.merge(attrs))
      else
        @resource.destroy
      end
    end

  end
end
