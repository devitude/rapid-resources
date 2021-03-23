module RapidResources
  class AdditionalColumn
    attr_reader :id, :title
    attr_accessor :selected

    def initialize(id, title, selected: false)
      @id = id
      @title = title
      @selected = selected
    end

    def selected?
      @selected
    end

    def to_jsonapi
      {
        id: id,
        title: title,
        selected: selected,
      }
    end
  end
end