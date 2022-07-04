module RapidResources
  class FieldRow

    attr_reader :title, :html_options, :options, :fields_for

    def initialize(*fields, title: nil, html_options: nil, fields_for: nil, options: nil)
      @title = title
      @html_options = html_options
      @options = options || {}
      @fields_for = fields_for

      empty_cols = 0
      @fields = fields.map do |fld, col|
        empty_cols += 1 unless col
        [fld, col]
      end
      @empty_col_class = 'col'
      @empty_col_class = "col-md-#{12 / empty_cols}" if empty_cols == @fields.count && empty_cols > 0
    end

    def check_box_list?
      options[:check_box_list]
    end

    def params
      fld_params = @fields.map{|fld, col| fld.params}
      if fields_for
        [{ :"#{fields_for.first}_attributes" => fld_params.flatten }]
      else
        fld_params
      end
    end

    def validation_keys
      v_keys = []
      @fields.each {|fld, col| v_keys.concat(fld.validation_keys)}
      v_keys
    end

    def wrap_col
      options[:wrap_col]
    end

    def each_col
      return unless block_given?
      @fields.each do |field, col|
        col = col || field.wrap_col
        col = if col.is_a? Numeric
          "col-md-#{col}"
        elsif col == :auto
          'col-auto'
        elsif col.present?
          col
        else
          nil
        end

        col_class = if col == :none
          nil
        elsif col
          col
        elsif check_box_list?
          nil
        else
          @empty_col_class
        end

        yield field, col_class
      end
    end
  end
end
