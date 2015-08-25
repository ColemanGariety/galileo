module Terminal
  class Table
    class Cell
      def wrap(width)
        @value.gsub!(/(.{1,#{width}})( +|$\n?)|(.{1,#{width}})/, "\\1\\3\n") if @value
      end
    end
  end
end
