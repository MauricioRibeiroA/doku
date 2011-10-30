require_relative 'solver'
require 'set'

module Doku
  class Puzzle
    include SolvableWithDancingLinks

    attr_reader :glyph_state

    def initialize(glyph_state = {})
      @glyph_state = {}
      # We initialize glyph_state this way so that the data gets validated.
      glyph_state.each { |square, glyph| self[square] = glyph }
    end

    def initialize_copy(source)
      @glyph_state = @glyph_state.dup
    end

    def self.glyphs
      raise "glyphs not defined for #{self}" if !defined?(@glyphs)
      @glyphs
    end

    def self.squares
      raise "squares not defined for #{self}" if !defined?(@glyphs)
      @squares
    end

    def self.groups
      raise "groups not defined for #{self}" if !defined?(@groups)
      @groups
    end

    def glyphs
      self.class.glyphs
    end

    def squares
      self.class.squares
    end

    def groups
      self.class.groups
    end

    def [](square)
      raise IndexError, "Key must be a square in this puzzle." if !squares.include?(square)
      @glyph_state[square]
    end

    def []=(square, glyph)
      raise IndexError, "Key must be a square in this puzzle." if !squares.include?(square)
      raise ArgumentError, "Value must be a glyph in this puzzle or nil." if !glyph.nil? && !glyphs.include?(glyph)

      # Do NOT store nils as values in the hash, because it
      # will mess us up when comparing two puzzles and in #each
      if glyph == nil
        @glyph_state.delete square
      else
        @glyph_state[square] = glyph
      end
    end

    def each(&block)
      @glyph_state.each(&block)
    end

    def glyph_state_to_string(glyph_state)
      glyph_state.inspect
    end

    def hash
      @glyph_state.hash
    end

    def eql? (puzzle)
      self.class == puzzle.class and glyph_state == puzzle.glyph_state
    end

    alias == eql?

    def <= (puzzle)
      self.class == puzzle.class and glyph_state_subset_of?(puzzle)
    end

    def < (puzzle)
      self != puzzle and self <= puzzle
    end

    def >= (puzzle)
      puzzle <= self
    end

    def > (puzzle)
      puzzle < self
    end

    def filled?
      (squares - glyph_state.keys).empty?
    end

    def valid?
      groups.each do |group|
        gs = group.collect { |square| self[square] }
        gs.delete nil
        return false if gs.uniq.length != gs.length
      end
      return true
    end

    def solution?
      filled? and valid?
    end

    def solution_for?(puzzle)
      solution? and puzzle <= self
    end

    private

    def self.has_glyphs(glyphs)
      @glyphs = glyphs
    end

    def self.define_square(square)
      raise ArgumentError, "square should not be nil" if square.nil?
      @squares ||= []
      @squares << square
    end

    def self.has_squares(squares)
      raise ArgumentError, "list of squares should not contain nil" if squares.include? nil
      @squares = squares.uniq
    end

    def glyph_state_subset_of?(puzzle)
      glyph_state.each_pair do |square, glyph|
        return false if puzzle[square] != glyph
      end
      return true
    end

    def self.define_group(args)
      s = if args.is_a? Hash
            squares.select { |sq| sq.matches? args }
          else
            args.dup
          end

      raise ArgumentError, "Expected groups to be of size #{glyphs.size} but got one of size #{s.size}.  squares = #{s.inspect}" if s.size != glyphs.size 
      @groups ||= []
      @groups << Set.new(s)
    end

    # There are several ways to infer new groups from the ones
    # already defined, but here is one:
    #   Suppose A, B, and C are groups.
    #   If the A and B are disjoint and C is a subset of A+B, then
    #   (A+B)-C can be inferred as a group.
    # This function detects such triplets (A, B, C) with the added
    # condition that A-C and B-C are the same size.
    def self.infer_groups
      groups.each do |groupC|
        candidates = groups.select { |g| g.intersection(groupC).size == glyphs.size/2 }
        candidates.each do |groupA|
          candidates.each do |groupB|
            break if groupB == groupA

            g = groupA + groupB - groupC
            define_group g if g.size == glyphs.size and !groups.include?(g)
          end
        end
      end
    end

  end
end
