module Doku
  module PuzzleOnGrid
    Separators = %w{- + |}

    attr_accessor :initial_view

    def self.included(klass)
      klass.extend ClassMethods
    end

    def self.parse_grid_string(string)
      y = 0
      string.lines.each_with_index do |line, line_number|
        line.chomp!
        next if (line.chars.to_a - Separators).empty?

        x = 0
        line.chars.each_with_index do |char, char_number|
          next if Separators.include?(char)

          yield char, char_number, line_number, x, y

          x += 1
        end
        y += 1
      end
    end

    module ClassMethods
      def template
        raise "template not defined for #{self}" if !defined?(@template)
        @template
      end

      def glyph_chars
        raise "glyph_chars not defined for #{self}" if !defined?(@glyph_chars)
        @glyph_chars
      end
      
      def square(x, y)
        @square_index[x][y]
      end

      private

      def has_template(string)
        @template = string.freeze
        define_squares_from_template
      end

      def has_glyph_chars(chars)
        @glyph_chars = chars
      end

      def define_square_on_grid(x, y, line_number, char_number)
        square = SquareOnGrid.new
        square.x = x
        square.y = y
        square.line_number = line_number
        square.char_number = char_number

        @square_index ||= Hash.new({})
        @square_index[x] = {} unless @square_index.has_key?(x)
        @square_index[x][y] = square

        define_square square
      end

      # Using the template provided for the puzzle, this function
      # defines objects to represent each of the different squares.
      def define_squares_from_template
        PuzzleOnGrid.parse_grid_string(template) do |char, char_number, line_number, x, y|
          if char == '.'
            define_square_on_grid x, y, line_number, char_number
          end
        end
      end
    end

    def initialize(grid_string=nil)
      super()
      parse_initial_grid_string grid_string if grid_string
    end

    def glyph_chars
      self.class.glyph_chars
    end

    def glyph_char(glyph)
      raise ArgumentError, "Invalid glyph #{glyph}" unless glyphs.index glyph
      glyph_chars[glyphs.index glyph]
    end

    def glyph_parse(char)
      glyphs[glyph_chars.index char]
    end

    def parse_initial_grid_string(grid_string)
      PuzzleOnGrid.parse_grid_string(grid_string) do |char, char_number, line_number, x, y|
        square = self.class.square(x, y)

        if square.nil?
          raise "Line #{line_number}, character #{char_number}: Invalid character.  Expected space." if char != ' '
        elsif char == '.'
          # No glyph specified for this square.
        elsif glyph_chars.include?(char)
          self[square] = glyph_parse(char)
        else
          raise "Line #{line_number}, character #{char_number}: Invalid character.  Expected period (.) or glyph (#{glyph_chars})." if square.nil?
        end
      end
    end

    def to_grid_string
      lines = self.class.template.split("\n")
      each do |square, glyph|
        lines[square.line_number][square.char_number] = glyph_char glyph
      end
      lines.join "\n"
    end

    def set(x, y, glyph)
      square = self.class.square(x, y)
      raise ArgumentError, "Invalid coordinates #{x},#{y}." if square.nil?
      self[square] = glyph
    end

    def get(x, y)
      square = self.class.square(x, y)
      raise ArgumentError, "Invalid coordinates #{x},#{y}." if square.nil?
      self[square]
    end

    def to_s
      to_grid_string
    end
  end

  class SquareOnGrid
    attr_accessor :x
    attr_accessor :y
    attr_accessor :line_number
    attr_accessor :char_number

    def matches?(args)
      args.each do |property, values| 
        return false unless values === send(property)
      end
      return true
    end

    def to_s
      "Square(#@x, #@y)"
    end
  end
end