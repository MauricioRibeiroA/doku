require 'rubygems'
require 'doku'

puzzle = Doku::Sudoku.new <<END
...|..8|...
..7|.35|..9
5..|4.6|8..
---+---+---
...|..4|2..
4..|...|.37
8..|...|5..
---+---+---
.9.|.67|...
..3|...|1.5
...|...|..3
END

solution = puzzle.solve

puts solution
puts solution.get(7,8)
