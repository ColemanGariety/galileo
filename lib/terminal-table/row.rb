module Terminal
  class Table
    class Row
      def wrap_cell(index, width)
        return if @cells.nil? or @cells[index].nil?
        @cells[index].wrap(width)
      end
    end
  end
end
