module RapidResources
  class GridFilter
    # { name: 'filter_text', type: :text },
    TypeText = :text
    TypeDateRange = :daterange
    TypeAutocomplete = :autocomplete
    TypeList = :list
    TypeCustom = :custom

    attr_reader :name, :type, :title, :notice,
      :items, :autocomplete_url, :visible, :placeholder, :multi_select,
      :component_name

    def initialize(name, type:, title: nil, selected_value: nil, notice: nil,
      items: nil, autocomplete_url: nil, visible: true, placeholder: nil, first_item_default: false,
      empty_title: nil, optional: nil, multi_select: nil, component_name: nil, &block)
      @visible = visible

      @name = name
      @type = type
      @multi_select = (list? || autocomplete?) && multi_select == true

      @title = title
      self.selected_value = selected_value
      @notice = notice
      @items = items
      @autocomplete_url = autocomplete_url
      @placeholder = placeholder
      @empty_title = empty_title
      @optional = optional

      if list?
        @items ||= []
        @items.each do |item|
          item[:value] = item[:value].to_s
        end
        setup_list_items(first_item_default)
      end

      @component_name = component_name if custom?

      yield self if block_given?
    end

    def text?
      @type == TypeText
    end

    def list?
      @type == TypeList
    end

    def autocomplete?
      @type == TypeAutocomplete
    end

    def custom?
      @type == TypeCustom
    end

    def daterange?
      @type == TypeDateRange
    end

    def multiple?
      return true if daterange?
       (list? || autocomplete?) && @multi_select
    end

    class << self
      def text(name, options = {}, &block)
        options = { type: TypeText }.merge(options)
        new(name, **options, &block)
      end

      def list(name, options = {})
        options = { type: TypeList }.merge(options)
        new(name, **options)
      end

      def multi_list(name, options = {})
        options = { type: TypeList, multi_select: true }.merge(options)
        new(name, options)
      end

      def autocomplete(name, options = {})
        options = { type: TypeAutocomplete }.merge(options)
        new(name, **options)
      end

      def multi_autocomplete(name, options = {})
        options = { type: TypeAutocomplete, multi_select: true }.merge(options)
        new(name, **options)
      end

      def daterange(name, options = {})
        options = { type: TypeDateRange }.merge(options)
        new(name, **options)
      end

      def custom(name, component_name, options = {})
        options = { type: TypeCustom, component_name: component_name }.merge(options)
        new(name, **options)
      end
    end

    def selected_value
      @selected_value
    end

    def selected_value=(value)
      if multiple?
        @selected_value = value ? [*value] : []
      else
        @selected_value = [*value].first
      end
    end

    def has_value?
      # if selected value is an array, check if at least one item is present
      if selected_value.is_a?(Array)
        item = selected_value.detect { |v| v.present? }
        return item.present?
      end

      selected_value.present?
    end

    def selected_date_range
      date_from, date_to = if selected_value.is_a?(Array)
        selected_value
      else
        selected_value.to_s.split(',')
      end

      tz = ActiveSupport::TimeZone['Europe/Brussels']
            # date = tz.strptime(date, '%d/%m/%Y %H:%M') rescue new_date
      date_from = if date_from.present?
        tz.strptime(date_from, '%d/%m/%Y')&.to_date rescue nil
      else
        nil
      end

      date_to = if date_to.present?
        tz.strptime(date_to, '%d/%m/%Y')&.to_date rescue nil
      else
        nil
      end

      [date_from, date_to]
    end

    def to_jsonapi_filter
      if items.is_a?(Array)
        items = self.items.dup
        items.each { |item| item[:value] = item[:value].to_s }
      end

      result = {
        name: name,
        title: title,
        type: type.to_s,
        placeholder: placeholder,
        selected_value: [*selected_value].map(&:to_s),
        notice: notice,
        items: items,
        autocomplete_url: autocomplete_url,
      }
      result[:component_name] = @component_name if custom?
      result[:empty_title] = @empty_title if @empty_title.present?
      result[:optional] = @optional unless @optional.nil?
      result[:multiple] = multiple?
      result
    end

    def setup_list_items(first_item_default)
      return if selected_value.present?

      # get selected item
      sel_value = selected_value.to_s
      sel_item = items.find { |item| item[:type] == 'item' && item[:value] == sel_value }
      if first_item_default
        sel_item ||= items.find { |item| item[:type] == 'item' } # use first item as selected one
      end

      @selected_value = sel_item&.[](:value)
    end
  end
end
