module Terminal
  module AvaibableHeightTable
    def render
      adjust_widths
      super
    end
    alias_method :to_s, :render
  end

  class Table
    prepend AvaibableHeightTable

    private
    def wrap_column(index, new_width)
      @rows.each do |row|
        row.wrap_cell(index, new_width)
      end
    end

    def adjust_widths
      return if style.wrap == false or style.width.nil? or style.width > columns_width

      # Make a column index to column size mapping, then sort it
      current_index = -1
      total_column_widths = @column_widths.map { |s| current_index +=1; [current_index, s + cell_spacing] }
      total_column_widths = total_column_widths.sort_by { |a,b| b }

      packed_length = 0
      current_index = 0
      # Pack the smallest first, but make sure the remaining space is enough for
      # the rest of the columns to have at least style.wrap_minimum_width spaces
      # to wrap into.
      while (style.width - (packed_length + total_column_widths[current_index][1] + style.border_y.length)) >
            (style.wrap_minimum_width * (total_column_widths.size - current_index - 1)) do
        packed_length += total_column_widths[current_index][1]
        current_index += 1
      end

      # Calculate the remaining space and figure out how big to wrap the other columns to
      remaining_space = style.width - packed_length - style.border_y.length
      trim_to = (remaining_space / (total_column_widths.size - current_index)) - cell_spacing
      trim_to -= (1 + style.padding_left + style.padding_right)
      if trim_to < 1
        raise "Cannot fit a #{total_column_widths.size} column table in width #{style.width}."
      end

      # The remaining columns are then wrapped
      (current_index...total_column_widths.size).each do |i|
        wrap_column(total_column_widths[i][0], trim_to)
        @column_widths[total_column_widths[i][0]] = trim_to + cell_spacing
      end
    end
  end
end
