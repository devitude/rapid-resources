module RapidResources
  class ResourcePage

    include Pundit
    # include Rails.application.routes.url_helpers
    include RapidResources::Engine.routes.url_helpers

    USE_PUNDIT_SCOPE = false

    SOFT_DESTROY = false

    OPLOG_OBJECT_TYPE = nil

    attr_reader :name, :current_user
    attr_accessor :return_to
    attr_accessor :jsonapi

    # fixme: get rid of model_class, name and action
    def initialize(current_user, name: nil, model_class: nil, url_helpers: nil)
      @name = name
      @model_class = model_class
      @current_user = current_user
      @url_helpers = url_helpers
    end

    def logger
      Rails.logger
    end

    def model_class
      return @model_class if @model_class
      raise "Implement #model_class for #{self.class.name}"
    end

    def object_param
      :id
    end

    def transform_jsonapi_keys
      false
    end

    def oplog_object_type
      self.class::OPLOG_OBJECT_TYPE
    end

    def oplog_delete_description(resource)
      nil
    end

    def use_pundit_scope
      self.class::USE_PUNDIT_SCOPE
    end

    def additional_form_buttons; end

    def required_fields_context(resource); end

    def display_form_errors
      true
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
      'grid'
    end

    # def init_grid_filters(filter_params = nil); end

    def grid_filters
      if respond_to?(:init_grid_filters)
        @grid_filters ||= init_grid_filters({})
      end

      @grid_filters || []
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

    def grid_meta(default_meta)
      default_meta
    end

    def grid_links(default_links)
      default_links
    end

    def grid_include
      nil
    end

    def render_index_actions_with_table
      false
    end

    def index_actions
      [].freeze
    end

    def table_row_css_class(resource)
      nil
    end

    def table_cell_css_class(field, resource: nil, header: false)
      field_name = field.name.to_s

      classes = []
      classes << 'tight' if field == :idx
      if header && field.sortable
        classes << 'sortable'
        classes << field.sorted.to_s if field.sorted
      end
      classes << field_name
      classes.join ' '
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
      false
    end

    def sorted_field
      collection_fields.detect { |cf| cf.sortable && !cf.sorted.nil? }
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
      if form_tabs = form_tabs(object)
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

    def collection_item_links(item)
      {}
    end

    def actions
      collection_actions
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

    def form_tabs(object)
      frm = form(object)
      frm.tabs
    end

    def form_fields(object)
      fields = []
      form_tabs(object).each do |tab|
        fields.concat tab[:fields]
      end
      fields
    end

    def form_buttons_partial(item)
      nil
    end

    def destroy_in_form
      false
    end

    def filter_form
      []
    end
    def filter_class; end

    def form_css_class
    end
    def additional_form_buttons; end

    def field_title(field)
      if field.is_a?(RapidResources::CollectionField)
        field.title
      else
        model_class.human_attribute_name(field)
      end
    end

    def title_helper; end

    # def filter_items(items, filter)
    #   items
    # end

    # def filter_params
    #   [:sort]
    # end
    def filter_params
      grid_filters.map do |filter|
        filter.multiple? ? { filter.name => [] } : filter.name
      end
    end

    def filter_keys
      # grid_filters.map(&:name)
      result = filter_params.map { |fp| fp.is_a?(Hash) ? fp.keys : fp }
      result.flatten!
      result.compact!
      result.uniq!
      result
    end

    def sort_param(jsonapi: false)
      s_fields = collection_fields.map do |cf|
        next unless cf.sortable

        s_name = col_field.sort_key
        if f.sorted == :desc
          "-#{s_name}"
        elsif f.sorted == :asc
          s_name
        else
          nil
        end
      end

      s_fields.compact!
      s_fields.join(',')
    end

    def sort_param=(new_sort)
      return if new_sort.blank?

      # unset sort for everything
      collection_fields.each { |cf| cf.sorted = nil }

      sort_columns = new_sort.split(',')
      sort_columns.each do |col_name|
        desc = col_name.starts_with?('-')
        col_name = col_name[1..-1] if desc
        if (col_field = collection_fields.find { |f| f.sortable && f.sort_key.to_s == col_name })
          col_field.sorted = desc ? :desc : :asc
        end
      end
    end

    def default_scope
      if use_pundit_scope || scope || default_scope
        items = policy_scope(scope || default_scope || model_class)
      else
        items = model_class.all
        items = items.alive if items.respond_to? :alive
      end
      items
    end

    def do_load_items(items)
      items
    end

    # def load_items(filter_params: nil, scope: nil)
    #   if use_pundit_scope || scope || default_scope
    #     items = policy_scope(scope || default_scope || model_class)
    #   else
    #     items = model_class.all
    #     items = items.alive if items.respond_to? :alive
    #   end

    #   items = do_load_items(items)

    #   # FIXME: order handling? Based on this, default order is always used?
    #   # items = filter_items(items, filter)
    #   if filter_params && filter_params[:sort]
    #     self.sort_params = filter_params[:sort]
    #     sp = sort_params
    #     if sp
    #       if model_class.respond_to?(:ordered)
    #         items = items.reorder('').ordered(column: sp[:field], direction: sp[:asc] ? :asc : :desc)
    #       else
    #         items = items.order("#{sp[:field]} #{sp[:asc] ? 'ASC' : 'DESC'}")
    #       end
    #     end
    #   end


    #   if default_order
    #     items = items.order(default_order)
    #   elsif model_class.respond_to? :ordered
    #     items = items.ordered
    #   end

    #   filter = filter_class.new if filter_class
    #   items = filter.apply_to(items, filter_params) if filter

    #   items.all
    # end

    #
    # Filter params should not be used and need to be removed
    #
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

      order_fields = []
      collection_fields.each do |cf|
        next unless cf.sortable
        if cf.sorted == :asc || cf.sorted == :desc
          order_fields << [cf.sort_key, cf.sorted]
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

      items
    end

    def apply_item_filter(items, filter)
      items
    end

    # if true, then
    # full_text_search is handled manually in page
    def manual_text_filter?
      false
    end

    def filter_items(items)
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
      o_param = object_param
       { action: action, o_param => (o_param == :id && item.respond_to?(:to_param) ? item.to_param : item.send(o_param)) }
    end

    def filter_args=(filter_args)
      if respond_to?(:init_grid_filters)
        # reset grid filters if filter_args are passed
        @grid_filters = nil unless filter_args.nil?
        @grid_filters ||= init_grid_filters(filter_args || {})
      else
        return unless filter_args.is_a?(Hash)

        filter_args.each do |fk, fv|
          fk = fk.to_sym
          filter = grid_filters.find { |gf| gf.name == fk }
          next unless filter
          filter.selected_value = fv
        end
      end
    end

    def filter_args(with_defaults: true, as_str: false)
      {}
    end

    def default_sort_arg; end

    def grid_header_actions; end

    def grid_additional_header_actions; end

    def new_url_params
      { action: :new }
    end

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
