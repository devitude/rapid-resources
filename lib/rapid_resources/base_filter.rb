module RapidResources
  class BaseFilter
    include ActiveModel::Model

    # this should be extracted to some common filter module
    def self.define_attribute(name, type)
      attr_accessor name
      case type
      when :date
        define_method "#{name}=" do |value|
          if String === value
            value = (value.blank? ? nil : Date.strptime(value, '%d.%m.%Y')) rescue value
          end
          instance_variable_set("@#{name}".to_sym, value)
        end
      end
    end

    def filter_params
      {}
    end

    def apply_to(items, attributes)
      items
    end
  end
end
