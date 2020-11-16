module RapidResources
  class Engine < ::Rails::Engine
    isolate_namespace RapidResources

    config.autoload_paths << File.expand_path("../../", __FILE__)

    # autoload support
    config.to_prepare do
      require_dependency 'rapid_resources/utils'
      require_dependency 'rapid_resources/resources_controller'
      require_dependency 'rapid_resources/resource_page'
      require_dependency 'rapid_resources/resource_form_builder'
      require_dependency 'rapid_resources/form_field'
      require_dependency 'rapid_resources/field_row'
      require_dependency 'rapid_resources/resource_form'
      require_dependency 'rapid_resources/base_filter'
    end
  end
end
