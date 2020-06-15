module RapidResources
  class GridFilter
    # { name: 'filter_text', type: :text },
    TypeText = :text
    TypeDateRange = :daterange
    TypeAutocomplete = :autocomplete
    TypeList = :list

    attr_reader :name, :type, :title, :selected_value, :selected_title, :notice,
      :items, :autocomplete_url, :visible, :placeholder, :multi_select

    attr_accessor :filtered_value

    def initialize(name, type:, title: nil, selected_value: nil, selected_title: nil, notice: nil,
      items: nil, autocomplete_url: nil, visible: true, placeholder: nil, first_item_default: false,
      empty_title: nil, optional: nil, multi_select: nil, &block)
      @visible = visible
      @name = name
      @type = type
      @title = title
      @selected_value = selected_value
      @selected_title = selected_title
      @filtered_value = selected_value
      @notice = notice
      @items = items
      @autocomplete_url = autocomplete_url
      @placeholder = placeholder
      @empty_title = empty_title
      @optional = optional
      @multi_select = false

      @multi_select = (list? || autocomplete?) && multi_select == true

      if list?
        @items ||= []
        @items.each do |item|
          item[:value] = item[:value].to_s
        end
        setup_list_items(first_item_default)
      end

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

    def multiple?
       (list? || autocomplete?) && @multi_select
    end

    class << self
      def text(name, title: nil, visible: true, placeholder: nil, &block)
        new(name, type: TypeText, title: title, visible: visible, placeholder: placeholder, &block)
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
    end

    def has_value?
      filtered_value.present?
    end

    def filtered_date_range
      date_from, date_to = filtered_value.to_s.split(',')
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
      result = {
        name: name,
        title: title,
        type: type.to_s,
        placeholder: placeholder,
        selected_value: selected_value,
        selected_title: selected_title,
        notice: notice,
        items: items,
        autocomplete_url: autocomplete_url,
      }
      result[:empty_title] = @empty_title if @empty_title.present?
      result[:optional] = @optional unless @optional.nil?
      result[:multiple] = multiple?
      result
    end

    def setup_list_items(first_item_default)
      return if selected_title.present? && selected_value.present?

      # get selected item
      sel_value = selected_value.to_s
      sel_item = items.find { |item| item[:type] == 'item' && item[:value] == sel_value }
      if first_item_default
        sel_item ||= items.find { |item| item[:type] == 'item' } # use first item as selected one
      end

      @selected_value = sel_item&.[](:value)
      @selected_title = sel_item&.[](:title)
    end
  end
end
