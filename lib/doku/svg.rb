module Doku; end
module Doku::PuzzleOnGrid; end

module Doku::PuzzleOnGrid::Svg
  Style = <<END
line {
  stroke: #000;
  stroke-width: 1px;
}
text {
  dominant-baseline: central;
  text-anchor: middle;
  font-size: 24pt;
  font-family: sans-serif;
}
END

  SquareWidth = 40
  Margin = 3

  def to_svg
    require 'builder'

    max_x = squares.collect(&:x).max
    max_y = squares.collect(&:y).max

    width = (max_x+1)*SquareWidth + Margin*2
    height = (max_y+1)*SquareWidth + Margin*2

    xml_string = ""
    builder = Builder::XmlMarkup.new :target=>xml_string, :indent=>2
    builder.instruct!
    builder.declare! :DOCTYPE, :svg
    builder.svg(:xmlns => "http://www.w3.org/2000/svg",
                :'xmlns:xlink' => "http://www.w3.org/1999/xlink",
                :width => width, :height => height) do
      builder.defs do
        builder.style Style
      end

      builder.g :transform=>"translate(#{Margin}, #{Margin})" do
        (0..(max_x+1)).each do |x|
          builder.line :x1 => x*SquareWidth, :y1 => 0, :x2 => x*SquareWidth, :y2 => (max_y+1)*SquareWidth
        end

        (0..(max_y+1)).each do |y|
          builder.line :x1 => 0, :y1 => y*SquareWidth, :x2 => (max_x+1)*SquareWidth, :y2 => y*SquareWidth
        end

        each do |square, glyph|
          builder.text({:x => (square.x+0.5)*SquareWidth, :y => (square.y+0.5)*SquareWidth}, self.class.glyph_char(glyph))
        end
      end
    end

    xml_string
  end

end
