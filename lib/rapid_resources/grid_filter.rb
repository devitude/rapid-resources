module RapidResources
  class GridFilter
    # { name: 'filter_text', type: :text },
    TypeText = :text
    TypeDateRange = :daterange
    TypeAutocomplete = :autocomplete
    TypeList = :list

    attr_reader :name, :type, :title, :selected_value, :selected_title, :notice,
      :items, :autocomplete_url, :visible, :placeholder

    attr_accessor :filtered_value

    def initialize(name, type:, title: nil, selected_value: nil, selected_title: nil, notice: nil,
      items: nil, autocomplete_url: nil, visible: true, placeholder: nil, first_item_default: false,
      empty_title: nil, optional: nil, &block)
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

      if @type == TypeList
        @items ||= []
        @items.each { |item| item[:value] = item[:value].to_s }
        setup_list_items(first_item_default)
      end

      yield self if block_given?
    end

    class << self
      def text(name, title: nil, visible: true, placeholder: nil, &block)
        new(name, type: TypeText, title: title, visible: visible, placeholder: placeholder, &block)
      end

      def list(name, options = {})
        options = { type: TypeList }.merge(options)
        new(name, **options)
      end

      def autocomplete(name, options = {})
        options = { type: TypeAutocomplete }.merge(options)
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
# filters = [
#       {
#         name: 'filter_date',
#         type: :daterange,
#         title: 'Date',
#         selected_value: dates_str,
#         selected_title: dates_str.join(' - '),
#         notice: 'range can\'t be larger than 1 month'
#       }
#     ]

#     event_items = [
#       { type: 'item', value: '', title: 'All' },
#     ]

#     if filter_params[:filter_event]
#       event = policy_scope(Event).where(id: filter_params[:filter_event]).first
#     end

#     filters << {
#       name: 'filter_event',
#       type: :autocomplete,
#       title: 'Event',
#       selected_value: event&.id || '',
#       selected_title: event&.name_full || 'All',
#       items: event_items,
#       autocomplete_url: autocomplete_all_events_path
#     }

#     if current_user.is_any?(admin: true, pm: true)
#       ncp_items = [
#         { type: 'item', value: '', title: 'All' },
#       ]

#       if filter_params[:filter_ncp]
#         ncp = Ncp.active.where(id: filter_params[:filter_ncp]).first
#       end

#       # ncp_id = Ncp.active.where(id: filter_params[:filter_ncp]).select(:id).first&.id


#       filters << {
#         name: 'filter_ncp',
#         type: :autocomplete,
#         title: 'NCP',
#         selected_value: ncp&.id || '',
#         selected_title: ncp&.display_name || 'All',
#         items: ncp_items,
#         autocomplete_url: autocomplete_ncps_path
#       }
#     end


#     status_values = [
#       { type: 'item', value: '', title: 'Any' },
#       { type: 'separator' },
#     ]
#     status_values.concat ActivityDigestReportSectionType.all.map{ |t| { type: 'item', value: t.value, title: t.title } }
#     selected_status = ActivityDigestReportSectionType[filter_params[:filter_status]]

#     filters << {
#       name: 'filter_status',
#       type: :list,
#       title: 'Status',
#       selected_value: selected_status&.value || '',
#       selected_title: selected_status&.title || 'Any',
#       items: status_values
#     }
