class FixedCollection

  attr_reader :value

  def initialize(value, title_key = nil, title: nil)
    @value = value
    @title_key = title_key
    @title = title if title
  end

  def title
    return @title if @title

    @title_key.blank? ? '' : I18n.t(@title_key)
  end

  class << self
    def [](value)
      all.find { |s| s.value == value }
    end

    def all_ids
      @all_ids ||= all.map(&:value).freeze
    end

    def all
      @all ||= populate.freeze
    end

    def collection_items
      # can't use @collection_items ||= because on production it will cache the current language
      all.map{ |item| [item.title, item.value] }
    end

    def valid?(value)
      all_ids.include?(value)
    end

    def valid_or(value, or_value)
      all_ids.include?(value) ? value : or_value
    end

    # implemented in sub classes to populate collection with items
    def populate
      raise "Implement #{self}::populate()"
    end
  end

end
