module RapidResources
  class ResourceResolver
    def initialize(controller_path, model_namespace: nil, model_class: nil, params_name: nil, page_class: nil)
      @controller_path = controller_path
      @model_namespace = model_namespace
      @model_class     = model_class
      @params_name     = params_name
      @page_class      = page_class
    end

    def params_name
      @params_name ||=  model_class.to_s.underscore.gsub('/', '_')
    end

    def model_name
      @model_name ||= @controller_path.split('/').last.singularize.camelize.freeze
    end

    def resource_var_name
      @resource_var_name ||= model_name.underscore.freeze
    end

    def model_class
      @model_class ||= begin
        model_namespace = ''
        model_namespace = "#{@model_namespace}::" if @model_namespace
        begin
          model_class = Object.const_get("#{model_namespace}#{model_name}")
        rescue NameError
          begin
            model_class = Object.const_get(model_name)
          rescue NameError
            raise unless model_name.include?('::')
            model_name = model_name.split('::').last
            model_class = Object.const_get(model_name)
          end
        end
        model_class
      end
    end

    def page(current_user, page_class: nil, url_helpers: nil)
      unless page_class
        @page_class ||= Object.const_get("#{@controller_path.singularize.camelize}Page")
        page_class = @page_class
      end
      page_class.new(current_user, name: @controller_path, model_class: self.model_class, url_helpers: url_helpers)
    end

  end
end
