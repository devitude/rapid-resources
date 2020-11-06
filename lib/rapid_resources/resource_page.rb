module RapidResources
  class ResourcePage

    include Pundit
    public :policy

    # include Rails.application.routes.url_helpers
    include RapidResources::Engine.routes.url_helpers

    DEFAULT_ORDER = nil

    SOFT_DESTROY = false

    OPLOG_OBJECT_TYPE = nil

    attr_reader :name, :sort_params, :current_user

    attr_accessor :return_to, :resource
    attr_accessor :jsonapi
    attr_accessor :filter_ids

    # fixme: get rid of model_class, name
    def initialize(current_user, name: nil, model_class: nil, resource: nil, url_helpers: nil)
      @name = name
      @model_class = model_class
      @current_user = current_user
      @sort_params = {}
      @sort_columns = []
      @resource = resource
      @url_helpers = url_helpers

      @filter_ids = []
    end

    # transform column names to camelLower
    def transform_column_names
      false
    end

    def new_item_actions_view
      false
    end

    def expose(items)
      # Rails.logger.info("EXPOSE : #{items}")
      return unless items.is_a?(Hash)
      items.each do |k,v|
        v_name = :"@#{k}"
        instance_variable_set(v_name, v)
      end
    end

    def model_class
      return @model_class if @model_class
      raise "Implement #model_class for #{self.class.name}"
    end

    def object_param
      :id
    end

    def oplog_object_type
      self.class::OPLOG_OBJECT_TYPE
    end

    def oplog_delete_description(resource)
      nil
    end

    def use_page_scope
      true
    end

    def additional_form_buttons; end

    def required_fields_context(resource); end

    def display_form_errors
      @display_form_errors = true if @display_form_errors.nil?
      @display_form_errors
    end

    def display_form_errors=(value)
      @display_form_errors = value
    end

    def resource_errors(resource, exclude_form_fields: false)
      errors = []
      error_messages = resource.error_messages
      error_messages.concat resource.additional_error_messages if resource.respond_to?(:additional_error_messages)
      if error_messages.count > 0
        f_fields = []
        form_fields(resource).each {|f| f_fields.concat(f.validation_keys) } if exclude_form_fields
        error_messages.each do |attribute, message|
          errors << message unless f_fields.include?(attribute)
        end
      end
      # errors.concat resource.additional_error_messages
      errors
    end

    # when true, return html page
    # when false, return vue grid component
    def index_html
      true
    end

    def grid_fields
      nil
    end

    def grid_paging
      true
    end

    def per_page
      nil
    end

    def grid_component
      ['div', 'Grid']
    end

    def grid_filters
      @grid_filters ||= init_grid_filters({})
    end

    def init_grid_filters(filter_params)
      []
    end

    def grid_serializers
      {}
    end

    def grid_expose
      {}
    end

    def grid_list_url
      { action: :index }
    end

    def index_actions
      [].freeze
    end

    def table_row_css_class(resource)
      nil
    end

    def table_cell_css_class(field, resource: nil, header: false)

      additional_class = nil
      field_name = if field.is_a?(CollectionField)
        additional_class = field.css_class
        field.name.to_s
      else
        [*field].first.to_s
      end

      classes = []
      classes << 'tight' if field == :idx
      if header && column_sortable?(field)
        classes << 'sortable'
        sort_field, sort_asc = sort_params[:field].to_s, sort_params[:asc]
        if sort_field == field_name
          classes << (sort_asc ? 'asc' : 'desc')
        end
      end
      classes << field_name
      classes << additional_class
      classes.select { |c| c.present? }.join ' '
    end

    def naming
      @naming ||= ActiveModel::Name.new(self.class)
    end

    def i18n_key
      @i18n_key ||= begin
        key = naming.i18n_key.to_s
        key.chomp!('_page')
        key
      end
    end

    def page_params
      pp = {}
      pp[:return_to] = return_to unless return_to.blank?
      pp
    end

    def t(key)
      defaults = [
        :"pages.base.#{key}",
        # key.to_s
      ]
      I18n.translate(:"pages.#{i18n_key}.#{key}", {
        count: 1,
        default: defaults,
        })
    end

    def column_sortable?(field_name)
      return field_name.sortable if field_name.is_a?(CollectionField)

      return false if field_name == :idx
      false
    end

    def sort_param(jsonapi: false)
      s_fields = @sort_columns.map do |sort_col|
        col_field = collection_fields.find { |f| f.sortable && f.name == col_name }
        if col_field
          "#{f.sorted == :desc ? '-' : ''}#{jsonapi ? col_field.jsonapi_name : col_field.name}"
        else
          nil
        end
      end
      s_fields.compact!
      s_fields.join(',')
    end

    def sort_param=(new_sort)
      sort_columns = new_sort.split(',')
      sort_columns.map! do |col_name|
        desc = col_name.starts_with?('-')
        col_name = col_name[1..-1] if desc
        col_name = col_name.underscore
        col_field = collection_fields.find { |f| f.sortable && f.match_name?(col_name) }
        col_field ? [col_field.name, desc] : nil
      end
      sort_columns.compact!

      # apply given sort to columns
      @sort_columns = []
      collection_fields.each do |cf|
        sort_col, sort_desc = sort_columns.find { |sc| sc[0] == cf.name }
        if sort_col
          @sort_columns << sort_col
          cf.sorted = sort_desc ? :desc : :asc
        else
          cf.sorted = nil
        end
      end
    end

    def collection_fields
      [].freeze
    end

    def json_fields
      [].freeze
    end

    def form_field(object, field_name)
      form(object).find {|field| field.name == field_name}
    end

    def permitted_attributes(object)
      permitted_fields = []
      if (form_tabs = form(object).tabs)
        form_tabs.each do |tab|
          tab[:fields].each do |f|
            permitted_fields.concat f.params.flatten
          end
        end
      end
      permitted_fields
    end


    def collection_actions
      [:edit].freeze
    end

    def collection_item_links
      {}
    end

    def actions
      collection_actions
    end

    def default_order
      self.class::DEFAULT_ORDER
    end

    def soft_destroy
      self.class::SOFT_DESTROY
    end

    def show_index_new
      true
    end

    def index_table_actions
      []
    end

    def index_table_class
      "table table-striped table-bordered table-hover table-sm resources-table #{@name.gsub(/[\/,_]/, '-')}-table"
    end

    def cancel_path(item); end
    def with_editor?
      false
    end

    def form_url(item)
      { action: item.persisted? ? :update : :create }
    end

    def form_options(options)
      options
    end

    def form(object)
      ResourceForm.new
    end

    def form_hide_buttons
      false
    end

    def form_fields(object)
      fields = []
      form(object).tabs.each do |tab|
        fields.concat tab[:fields]
      end
      fields
    end

    def form_buttons_partial(item)
      nil
    end

    def form_css_class
    end
    def additional_form_buttons; end

    def field_title(field)
      model_class.human_attribute_name(field)
    end

    def title_helper; end

    # def filter_items(items, filter)
    #   items
    # end

    def filter_params
      fparams = grid_filters.map do |filter|
        filter.multiple? ? { filter.name => [] } : filter.name
      end
      fparams << { filter_id: [] } # special filter to filter by selected items
      fparams
    end

    def filter_keys
      # grid_filters.map(&:name)
      result = filter_params.map { |fp| fp.is_a?(Hash) ? fp.keys : fp }
      result.flatten!
      result.compact!
      result.uniq!
      result
    end

    def default_scope
      model_class.all
    end

    def do_load_items(items)
      items
    end

    def load_items(filter_params: nil, scope: nil)
      # if use_page_scope
      #   items = policy_scope(scope || default_scope)
      # else
      #   items = scope || default_scope
      #   items = items.alive if items.respond_to? :alive
      # end
      items = scope || default_scope

      items = do_load_items(items)

      items = filter_items(items)

      items = order_items(items)

      items.is_a?(Array) ? items : items.all
    end

    def order_items(items)
      return items if items.is_a?(Array)

      # items = items.reorder('') # reset order to none
      order_fields = []

      @sort_columns.each do |col_name|
        col_field = collection_fields.find { |cf| cf.name == col_name }
        if col_field
          order_fields << [col_field.name, col_field.sorted]
        end
      end

      if order_fields.count.zero?
        # apply default order if set
        sort_field, sort_direction = default_order
        if sort_field
          order_fields << [sort_field, sort_direction]
          # mark default column ordered
          col_field = collection_fields.find { |cf| cf.sortable && cf.match_name?(sort_field) }
          col_field.sorted = sort_direction if col_field
        end
      end

      use_ordered = model_class.respond_to?(:ordered)
      if order_fields.count.positive?
        # apply specified order
        items = items.reorder('') # reset order to none
        order_fields.each do |col, direction|
          if use_ordered
            items = items.ordered(column: col, direction: direction == :desc ? :desc : :asc)
          else
            items = items.order(col => direction == :desc ? 'DESC' : 'ASC')
          end
        end
      elsif use_ordered
        # apply default order form model
        items = items.reorder('') # reset order to none
        items = items.ordered
      end

      if block_given?
        items = yield items, order_fields
      end

      items
    end

    def apply_id_filter(items)
      items = items.where(id: @filter_ids) if @filter_ids.count.positive?
      items
    end

    def apply_item_filter(items, filter)
      items
    end

    def apply_full_text_search(items, text)
      items.full_text_search(text)
    end

    # if true, then
    # full_text_search is handled manually in page
    def manual_text_filter?
      false
    end

    def filter_items(items)
      items = apply_id_filter(items)

      grid_filters.each do |filter|
        next unless filter.has_value?
        if !manual_text_filter? && filter.type == GridFilter::TypeText && items.respond_to?(:full_text_search)
          items = items.full_text_search(filter.selected_value)
          next # filter automatically handled, move to next
        end

        items = apply_item_filter(items, filter)
      end

      items
    end

    def item_action_link_params(action, item)
       { action: action, object_param => item.send(object_param) }
    end

    def filter_args=(filter_args)
      @filter_ids = []
      if filter_args && filter_args[:filter_id].is_a?(Array)
        @filter_ids = filter_args[:filter_id]
      end

      # reset grid filters if filter_args are passed
      @grid_filters = nil unless filter_args.nil?
      @grid_filters ||= init_grid_filters(filter_args || {})
    end

    def filter_args(with_defaults: true, as_str: false)
      {}
    end

    def default_sort_arg; end

    def grid_header_actions; end

    def grid_additional_header_actions; end

    def policy_class; end

    def policy_namespace; end

    protected

    def grid_list_filter(name, title, items, selected_value)
      # transform all item values to strings
      items = items.map do |item|
        case item[:type]
        when 'item'
          item = item.dup
          item[:value] = item[:value].to_s
        end
        item
      end

      # get selected item
      selected_value = selected_value.to_s
      selected_item = items.find { |item| item[:type] == 'item' && item[:value] == selected_value }
      unless selected_item
        selected_item = items.find { |item| item[:type] == 'item' } # use first item as selected one
      end

      {
        name: name,
        type: :list,
        title: title,
        selected_value: selected_item&.[](:value),
        selected_title: selected_item&.[](:title),
        items: items
      }
    end

    def grid_list_filter_value(filter, filter_value)
      return filter_value unless filter[:type] == :list

      filter_value = filter_value.to_s
      item = filter[:items].find { |item| item[:value] == filter_value }

      item&.[](:value) || nil
    end
  end
end
