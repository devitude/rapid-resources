module RapidResources
  class GridFilter
    # { name: 'filter_text', type: :text },
    TypeText = :text
    TypeDateRange = :daterange
    TypeAutocomplete = :autocomplete
    TypeList = :list

    attr_reader :name, :type, :title, :selected_value, :selected_title, :notice,
      :items, :autocomplete_url

    attr_accessor :filtered_value

    def initialize(name, type:, title: nil, &block)
      @name = name
      @type = type
      @title = title
      yield self if block_given?
    end

    def self.text(name, title: nil, &block)
      new(name, type: TypeText, title: title, &block)
    end

    def has_value?
      filtered_value.present?
    end

    def to_jsonapi_filter
      {
        name: name,
        title: title,
        type: type.to_s,
      }
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
