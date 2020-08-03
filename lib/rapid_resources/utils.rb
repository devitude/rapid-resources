module RapidResources
  module Utils
    def self.js_json(data)
      result = { data: data}
      result = result.deep_transform_keys { |k| k.to_s.camelize(:lower) }
      result['data']
    end
  end
end
