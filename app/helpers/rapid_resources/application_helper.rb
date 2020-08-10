module RapidResources
  module ApplicationHelper
    def resource_index_actions(page)
      actions = []

      page.index_actions.each do |a_type, params|
        case a_type
        when :new
          actions << link_to(page.t(:new), page.new_url_params, class: 'btn btn-sm btn-success btn-resource-edit')
        when :helper
          html = send(params)# rescue nil
          actions << html if html
        end
      end
      actions
    end

    def resources_render_index_table_actions(page, items)
      actions = page.index_table_actions
      result = ''.html_safe
      actions.each do |act|
        if act.is_a?(Symbol)
          result << self.send(act, page, items) if self.respond_to?(act)
        end
      end

      result.blank? ? nil : content_tag(:div, result, class: 'index-table-actions')
    end

    def resource_index_item_actions(page, item)
      result = ''.html_safe
      item = item.is_a?(Hash) && item.key?(:record) ? item[:record] : item
      item_policy = page.resource_policy(item) || policy(item)

      page.actions.each do |action|
        case action
        when :edit
          result << link_to(page.t(:edit), page.item_action_link_params(:edit, item), class: 'btn btn-sm btn-success btn-edit', 'data-action' => 'edit') if item_policy.edit?
        when :show
          result << link_to(page.t(:view), page.item_action_link_params(:show, item), class: 'btn btn-sm btn-primary') if item_policy.show?
        when :destroy
          result << link_to(page.t(:delete), page.item_action_link_params(:destroy, item), class: 'btn btn-sm btn-danger', data: { method: 'DELETE', confirm: 'Delete?' }) if item_policy.destroy?
        else
          result << self.send(action.to_sym, item, page) if self.respond_to?(action.to_sym)
        end
        result << ' ' # spacing between buttons/content
      end
      result
    end

    def resource_header(page, field)
      content_tag :th, field.title, class: page.table_cell_css_class(field, header: true),
        'data-sort-by' => field.sortable ? field.sort_key : nil
    end

    def resource_field(page, item, field, idx)
      if field.is_a?(RapidResources::CollectionField) && (field.name == :idx || field.name == ':idx')
        return idx
      end
      return idx if [*field].first == :idx

      record = item.is_a?(Hash) ? item[:record] : item
      if Array === field
        field, options = field
        display_text = item.is_a?(Hash) && item.key?(field) ? item[field] : record.public_send(field) unless options.is_a?(Symbol)
        if options.is_a?(Symbol)
          send(options, record, field)
        elsif options.is_a?(Hash) && [:edit, :show].include?(options[:link_to])
          show_link = case options[:link_to]
          when :edit
             policy(record).edit?
           when :show
            policy(record).show?
          end
          if show_link
            link_to display_text, {action: options[:link_to], page.object_param => record.send(page.object_param)}
          else
            display_text
          end
        else
          display_text
        end
      elsif item.is_a?(Hash) && item.key?(field)
        item[field]
      elsif field.is_a?(RapidResources::CollectionField)
        if field.cell_helper_method
          send(field.cell_helper_method, record, field)
        else
          show_link = case field.link_to
          when :edit
            page.resource_policy(record).edit?
          when :show
            page.resource_policy(record).show?
          end

          display_text = if record.is_a?(Hash)
            record[field.name]
          elsif record
            record.public_send(field.name)
          else
            nil
          end

          if show_link
            link_to display_text, { action: field.link_to, page.object_param => (page.object_param == :id ? record.to_param : record.send(page.object_param)) }
          else
            display_text
          end
        end
      else
        record.public_send(field)
      end
    end

    def resource_table_row_css_class(page, item)
      row_class = page.table_row_css_class(item)
      return nil if row_class.blank?

      %Q- class="#{ERB::Util.html_escape(row_class)}"-.html_safe
    end

    def resource_form_options(item, page = nil, options = {})
      html_options = options.delete(:html) || {}
      f_options = {
        url: page.form_url(item),
        html: { class: resource_form_class(item, page.try(:form_css_class)) }.merge!(html_options),
        builder: ResourceFormBuilder,
        page: page,
      }.merge!(options)
      page.form_options(f_options)
    end

    def resource_form_class(item, additional_classes = nil)
      controller_class = controller_path.gsub('_', '-').split('/').join(' ') + '-form'
      [additional_classes, controller_class].compact.join(' ')
    end

    def resources_cancel_path(page, item)
      cp = page.cancel_path(item)
      if !params[:return_to].blank? && params[:return_to].starts_with?('/')
        params[:return_to]
      elsif cp.nil?
        url_for(action: :index)
      elsif cp.is_a?(Hash)
        url_for(cp)
      else
        cp
      end
    end

    def resource_additional_form_buttons(method_name, item)
      if Symbol === method_name
        if method(method_name).arity == 1
          send(method_name, item)
        else
          send(method_name)
        end
      end
    end

    def resource_form_cancel_tag(page, item)
      cancel_path = resources_cancel_path(page, item)
      return nil if cancel_path == :none

      link_to page.t(:'form_action.cancel'), cancel_path, class: 'btn btn-default btn-sm'
    end

    def resource_page_grid_component_tag(page)
      component_tag, component_type, options = page.grid_component
      if component_tag.present? && component_type.present?
        html_options = { 'data-is' => component_type, 'data-list-url' => url_for(page.grid_list_url) }.merge(options || {})
        content_tag :div, '', html_options
      else
        content_tag page.grid_component, '', 'data-list-url' => url_for(page.grid_list_url)
      end
    end
  end
end
