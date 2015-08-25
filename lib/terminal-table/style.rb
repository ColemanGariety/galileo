module Terminal
  class Table
    class Style
      @@defaults = {
        border_x: '-', border_y: '|', border_i: '+',
        padding_left: 1, padding_right: 1,
        width: nil, alignment: nil,
        wrap: true, wrap_minimum_width: 4
      }
      attr_accessor :wrap
      attr_accessor :wrap_minimum_width
    end
  end
end
