module RapidResources
  class GridPaginator

    attr_reader :current_page, :total_pages, :max_pages, :per_page

    def initialize(total_pages:, current_page:, per_page:, max_pages: 10)
      @total_pages = total_pages.to_i
      @current_page = current_page.to_i
      @current_page = @total_pages if @current_page > @total_pages
      @per_page = per_page
      @max_pages = max_pages
    end

    def pages
      return [] if total_pages <= 0

      half_gap = (max_pages / 2).floor

      from_page = current_page - half_gap
      to_page = current_page + half_gap
      if from_page < 1
        to_page += from_page.abs + 1
        from_page = 1
        to_page = [to_page, total_pages].min
      elsif to_page > total_pages
        from_page -= to_page - total_pages
        to_page = total_pages
        from_page = [from_page, 1].max
      end

      from_page = 1 if from_page == 2
      to_page = total_pages if to_page + 1 == total_pages

      add_gaps = total_pages > max_pages

      pages = []
      pages << { type: :first, nr: first_page? ? nil : 1, current: false }
      pages << { type: :prev, nr: first_page? ? nil : current_page - 1, current: false }

      # check if should add a gap
      pages << { type: :gap, nr: nil, current: false } if add_gaps && from_page > 1

      (from_page..to_page).each do |page|
        pages << { type: :page, nr: page, current: page == current_page }
      end

      pages << { type: :gap, nr: nil, current: false } if add_gaps && to_page < total_pages
      pages << { type: :next, nr: last_page? ? nil : current_page + 1, current: false }
      pages << { type: :last, nr: last_page? ? nil : total_pages, current: false }
    end

    def first_page?
      current_page <= 1
    end

    def last_page?
      current_page >= total_pages
    end

    def first_idx_in_page
      (current_page - 1) * per_page + 1
    end

  end
end
