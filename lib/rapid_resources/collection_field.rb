module RapidResources
  class CollectionField
    attr_reader :name, :jsonapi_name, :title, :sortable, :link_to, :cell_helper_method, :css_class, :header_css_class
    attr_accessor :sorted
    attr_reader :type

    class << self
      def actions
        # fields << [:actions, :actions_column, header: false] if with_actions
        new(':actions', title: nil)
      end

      def idx
        new(':idx', title: '#')
      end
    end

    def initialize(name, jsonapi_name: nil, sortable: false, title: nil, link_to: nil, sorted: nil, cell_helper_method: nil, type: nil, css_class: nil, header_css_class: nil)
      @name = name
      @jsonapi_name = jsonapi_name
      @sortable = sortable
      @title = title
      @sorted = sorted
      @str_names = [name.to_s, jsonapi_name.to_s]
      @cell_helper_method = cell_helper_method
      @link_to = link_to
      @type = type
      @css_class = css_class
      @header_css_class = header_css_class
    end

    def match_name?(name)
      @str_names.include?(name.to_s)
    end

    def jsonapi_name
      @jsonapi_name.present? ? @jsonapi_name : @name
    end

    def to_jsonapi_column
      result = {
        name: jsonapi_name,
        title: title,
        sortable: sortable,
        sorted: sorted,
        cssClass: css_class,
      }
      result[:headerCssClass] = header_css_class if header_css_class.present?
      if type.present?
        result[:type] = type
      elsif link_to.present?
        result[:type] = 'link_to'
        result[:linkTo] = link_to
      end
      result
    end
  end

end
