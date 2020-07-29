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
        format.xlsx do
          items, columns = grid_items
          xlsx_path = generate_xlsx_file(items, columns)
          send_file xlsx_path, filename: xlsx_filename, type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        end
        format.jsonapi do
          grid_list
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
      end
    end

    def create
      authorize_resource :create?

      result = save_resource(@resource, resource_params)
      return if response_rendered?

      if result.ok?
        save_response(:create)
      end

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
          if page.destroy_in_form && policy(@resource).destroy?
            begin
              json_data['deleteUrl'] = url_for(action: :destroy)
            rescue => ex
              OspUtils.capture_exception(ex)
            end
          end
          json_data.merge! get_additional_json_data
          render json: json_data #, formats: [:json]
        end
      end
    end

    def update
      authorize_resource :update?

      yield if block_given?

      result = save_resource(@resource, resource_params)
      return if response_rendered?

      if result.ok?
        save_response(:update)
      end

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

    def page_class
      nil
    end


    # FIXME: use ActionController::Metal.performed? instead
    def response_rendered?
      response_body
    end

    def page
      @page ||= begin
        page = init_page
        setup_page(page)
        page
      end
    end

    # FIXME: migrate all pages and get rid of extra_params
    def init_page(page_class: nil)
      page_class ||= self.page_class
      page_class.new(current_user, name: controller_path, url_helpers: self)
    end

    def setup_page(page)
    end

    def resource_params_name
      page.model_class.model_name.param_key
    end

    def resource_params
      params.require(resource_params_name).permit(page.permitted_attributes(@resource))
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

    def on_before_load_res; end

    def load_res
      run_callbacks :load_res do
        on_before_load_res
        load_resource
        load_additional_resources
      end
    end

    def load_items
      page.load_items(filter_params: params)
    end

    def load_resource
      single = false

      case params[:action]
      when *item_actions
        single = true
      when 'new', 'create'
        model = page.model_class
        @resource = respond_to?(:build_model, true) ? build_model : (model.respond_to?(:build_new) ? model.build_new : model.new)
      end

      if single
        @resource = load_current_resource
        instance_variable_set("@#{resource_var_name}".to_sym, @resource)
      end
    end

    def item_actions
      ['edit', 'update', 'destroy', 'show']
    end

    # in case a resource initializes it's model with some custom logick
    # def build_model; end

    def load_additional_resources; end

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
      page.model_class.model_name.singular.freeze
    end

    def load_current_resource
      model ||= page.model_class

      resource = if page.use_pundit_scope
        policy_scope(model)
      else
        model.respond_to?(:alive) ? model.alive : model
      end
      resource
        .where(model.primary_key => current_resource_id)
        .first!
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

    def save_response(action)
      respond_to do |format|
        format.html { redirect_to redirect_route(action) }
        format.json do
          json_data = {'status' => 'success'}
          json_data.merge! get_additional_json_data
          render json: json_data
        end
      end
    end

    def get_additional_json_data
      {}
    end

    def authorize_resource(query)
      case query
      when :index?
        authorize page.model_class, query
      else
        authorize @resource, query
      end
    end

    def save_resource(resource, params)
      # resource.update(resource_params)
      resource.assign_attributes(resource_params)
      # if resource.valid?(:form) && resource.save
      if resource.save
        Result.ok
      else
        Result.err
      end
    end

    def grid_items(grid_page: nil, grid_items: nil)
      grid_page ||= page
      grid_page.jsonapi = true

      filter_params = if params.key?(:filter)
        params
          .fetch(:filter, {})
          .permit(*grid_page.filter_params)
          .to_h
      else
        params
          .slice(*grid_page.filter_keys)
          .permit(*grid_page.filter_params)
          .to_h
      end

      grid_page.sort_param = params[:sort].to_s if params[:sort]
      grid_page.filter_args = filter_params#params.permit(*grid_page.filter_params).to_h
      grid_items ||= grid_page.load_items(filter_params: filter_params)

      return [grid_items, grid_page.collection_fields.dup]
    end

    # def grid_items(grid_page: nil, grid_items: nil)
    #   grid_page ||= page
    #   grid_page.jsonapi = true

    #   filter_params = params.permit(*grid_page.filter_params).to_h
    #   if filter_params.count.zero?
    #     filter_params = params.fetch(:filter, {}).permit(*grid_page.filter_params).to_h
    #   end

    #   sort_param = params[:sort].to_s.freeze

    #   transform_keys = grid_page.transform_jsonapi_keys

    #   columns = grid_page.collection_fields.map do |fld|
    #     field = [*fld].first

    #     field_name = transform_keys ? field.to_s.camelize(:lower) : field.to_s

    #     if fld.is_a?(Array) && fld.count > 1 && fld[1] == :idx_column
    #       { name: ':idx', title: '#', sortable: false, sorted: false }
    #     elsif fld.is_a?(Array) && fld.count > 1 && fld[1] == :actions_column
    #       { name: ':actions', title: '', sortable: false, sorted: false }
    #     elsif fld.is_a?(Array) && fld.count > 1 && fld[1] == :custom_column
    #       { name: field_name, title: grid_page.field_title(field), sortable: false, sorted: false, type: 'custom' }
    #     elsif fld.is_a?(Array) && fld.count > 1 && fld[1] == :link_to
    #       { name: field_name, title: grid_page.field_title(field), sortable: grid_page.column_sortable?(field), sorted: false, type: 'link_to' }
    #     else
    #       { name: field_name, title: grid_page.field_title(field), sortable: grid_page.column_sortable?(field), sorted: false }
    #     end
    #   end

    #   sort_arg = nil
    #   if sort_param.present?
    #     columns.each do |col|
    #       if sort_param == col[:name]
    #         col[:sorted] = 'asc'
    #         sort_arg = "#{col[:name]}:asc"
    #       elsif sort_param == "-#{col[:name]}"
    #         col[:sorted] = 'desc'
    #         sort_arg = "#{col[:name]}:desc"
    #       end
    #     end
    #   end

    #   unless sort_arg
    #     default_sort = grid_page.default_sort_arg
    #     if default_sort
    #       sort_col = default_sort[0].to_s
    #       col = columns.detect { |c| c[:name] == sort_col }
    #       if col
    #         col[:sorted] = default_sort[1].to_s
    #         sort_arg = default_sort.join(':')
    #       end
    #     end

    #     unless sort_arg
    #       col = columns.detect { |c| c[:sortable] }
    #       if col
    #         col[:sorted] = 'asc'
    #         sort_arg = "#{col[:name]}:asc"
    #       end
    #     end
    #   end

    #   filter_params[:sort] = sort_arg if sort_arg
    #   grid_items ||= grid_page.load_items(filter_params: filter_params)
    #   return [grid_items, columns]
    # end

    # def grid_list(grid_page: nil, grid_items: nil, jsonapi_include: nil, additional_meta: nil)
    #   grid_page ||= page

    #   grid_items, columns = grid_items(grid_page: grid_page, grid_items: grid_items)

    #   if grid_page.grid_paging && grid_items.respond_to?(:page)
    #     grid_items = grid_items.page params[:page]
    #     if per_page = grid_page.per_page
    #       grid_items = grid_items.per(per_page)
    #     end
    #     grid_items = grid_items.page(1) if grid_items.current_page > grid_items.total_pages
    #     paginator = Paginator.new(total_pages: grid_items.total_pages, current_page: grid_items.current_page, per_page: grid_items.current_per_page)
    #   end

    #   if grid_page.collection_actions.include?(:edit)
    #     # columns << { name: ':actions', title: '', sortable: false, sorted: false }
    #     columns << CollectionField.new(':actions', title: '', sortable: false)
    #   end

    #   filters = []
    #   (grid_page.grid_filters(params.permit(*grid_page.filter_params).to_h) || []).each do |filter|
    #     filters << filter
    #     # page_filters = page.grid_filters.dup || []
    #     # filters << 'text' if page_filters.include?(:text)
    #   end

    #   columns.map! do |col|
    #     if col.is_a?(CollectionField)
    #       col.to_jsonapi_column
    #     else
    #       col
    #     end
    #   end
    #   meta_fields = {
    #     columns: columns,
    #     filters: filters,
    #     pages: paginator&.pages,
    #     current_page: paginator&.current_page,
    #     total_pages: paginator&.total_pages,
    #     page_first_index: paginator&.first_idx_in_page || 1,
    #     header_actions: grid_page.grid_header_actions,
    #     additional_header_actions: grid_page.grid_additional_header_actions,
    #   }
    #   meta_fields.merge!(additional_meta) if additional_meta.is_a?(Hash)
    #   meta_fields = grid_page.grid_meta(meta_fields, self)

    #   jsonapi_index_response(grid_items,
    #     serializers: grid_page.grid_serializers,
    #     meta: grid_meta(meta_fields),
    #     links: grid_links(grid_page),
    #     render_fields: grid_page.grid_fields,
    #     expose: grid_page.grid_expose,
    #     jsonapi_include: jsonapi_include,
    #     )
    # end

    def grid_list(grid_page: nil, grid_items: nil, jsonapi_include: nil, additional_meta: nil)
      grid_page ||= page

      grid_items, columns = grid_items(grid_page: grid_page, grid_items: grid_items)

      total_items = 0
      if grid_page.grid_paging && grid_items.respond_to?(:page)
        grid_items = grid_items.page params[:page]
        if per_page = grid_page.per_page
          grid_items = grid_items.per(per_page)
        end
        total_items = grid_items.total_count
        grid_items = grid_items.page(1) if grid_items.current_page > grid_items.total_pages
        paginator = GridPaginator.new(total_pages: grid_items.total_pages, current_page: grid_items.current_page, per_page: grid_items.limit_value)
      end

      if grid_page.collection_actions.include?(:edit)
        columns << CollectionField.new(':actions', title: '', sortable: false)
      end

      meta_fields = {
        columns: columns.map(&:to_jsonapi_column),
        filters: grid_page.grid_filters.select {|f| f.visible }.map(&:to_jsonapi_filter),
        pages: paginator&.pages,
        current_page: paginator&.current_page,
        total_pages: paginator&.total_pages,
        total_items: total_items,
        page_first_index: paginator&.first_idx_in_page || 1,
        header_actions: grid_page.grid_header_actions,
        additional_header_actions: grid_page.grid_additional_header_actions,
      }
      meta_fields.merge!(additional_meta) if additional_meta.is_a?(Hash)

      # FIXME: grid_page grid_meta deprecated?
      meta_fields = grid_page.grid_meta(meta_fields)

      jsonapi_index_response(grid_items,
        serializers: grid_page.grid_serializers,
        meta: grid_meta(meta_fields),
        links: grid_links(grid_page),
        render_fields: grid_page.grid_fields,
        expose: grid_page.grid_expose,
        jsonapi_include: jsonapi_include || grid_page.grid_include,
        grid_page: grid_page,
        )
    end

    def jsonapi_index_response(items, serializers: {}, meta: nil, links: nil, expose: {}, render_fields: nil, jsonapi_include: nil, grid_page: nil)
      renderer = DefaultJsonapiRenderer.new

      jsonapi_options = {
        class: serializers,
        meta: meta,
        links: links,
        expose: {
          url_helpers: self,
          current_user: current_user,
        }.merge(expose || {})
      }
      grid_page ||= page
      jsonapi_options[:transform_keys] = true if grid_page.transform_jsonapi_keys
      jsonapi_options[:fields] = render_fields if render_fields
      jsonapi_options[:include] = jsonapi_include if jsonapi_include
      json_data = renderer.render(items, jsonapi_options)
      render json: json_data, type: 'application/vnd.api+json'
    end

    def grid_links(page)
      links = if page.index_actions.include?(:new)
        { new: url_for({ action: :new}) }
      else
        nil
      end

      page.grid_links(links)
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
