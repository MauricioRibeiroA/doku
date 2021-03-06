require 'backports' unless defined? require_relative
require_relative 'spec_helper'

describe Doku::DancingLinks::LinkMatrix do
  context "when created from scratch" do
    before do
      @m = Doku::DancingLinks::LinkMatrix.new
    end

    it "has no columns (i.e. it is empty)" do
      @m.columns.to_a.size.should == 0
      @m.should be_empty
    end
  end

  describe ".from_sets" do
    it "can create a matrix from a set of sets" do
      @m = Doku::DancingLinks::LinkMatrix.from_sets(
        Set.new([ Set.new([1, 2]), Set.new([2, 3]) ]) )
    end

    it "filters out duplicate column ids" do
      @m = Doku::DancingLinks::LinkMatrix.from_sets [ [1,2,2] ]
      @m.row([1,2,2]).nodes.to_a.size.should == 2
    end

  end

  describe "find_exact_cover" do
    it "can find one exact cover" do
      m = Doku::DancingLinks::LinkMatrix.from_sets [[1,2], [2,3], [3,4]]
      m.find_exact_cover.sort.should == [[1,2], [3,4]]
    end

    it "returns nil if there are no exact covers" do
      m = Doku::DancingLinks::LinkMatrix.from_sets [[1,2], [2,3]]
      m.find_exact_cover.should == nil
    end

    it "it finds the trivial exact cover for the trivial matrix" do
      Doku::DancingLinks::LinkMatrix.new.find_exact_cover.should == []
    end
  end

  describe "exact_covers" do
    it "returns an Enumerable" do
      Doku::DancingLinks::LinkMatrix.new.exact_covers.should be_a Enumerable
    end

    it "can find all exact covers" do
      m = Doku::DancingLinks::LinkMatrix.from_sets [[1,2], [2,3], [3,4], [4,1]]
      m.exact_covers.collect{|ec| ec.sort}.sort.should ==
        [ [ [1,2], [3,4] ],
          [ [2,3], [4,1] ] ]
    end

    it "it finds the trivial exact cover for the trivial matrix" do
      Doku::DancingLinks::LinkMatrix.new.exact_covers.to_a.should == [[]]
    end
  end

  describe "each_exact_cover" do
    it "does not yield if there are no exact covers" do
      m = Doku::DancingLinks::LinkMatrix.from_sets [[1,2], [2,3]]
      m.each_exact_cover { |ec| true.should == false }
    end

    it "finds the trivial exact cover for the trivial matrix" do
      already_yielded = false
      Doku::DancingLinks::LinkMatrix.new.each_exact_cover do |ec|
        ec.should == []
        already_yielded.should == false
        already_yielded = true
      end
    end
  end

  describe "each_exact_cover_recursive" do
    it "find the trivial cover for the trivial matrix" do
      Doku::DancingLinks::LinkMatrix.new.enum_for(:each_exact_cover_recursive).to_a.should == [[]]
    end

    it "works even if final(k) < max(k)" do
      # This makes sure we call collect on o[0...k] instead of on o.
      m = Doku::DancingLinks::LinkMatrix.from_sets [
          [1,2,     ],
          [  2,3,   ],
          [    3,4, ],
          [      4,5],
          [1,2,3,4,5] ]
      m.enum_for(:each_exact_cover_recursive).to_a.should == [[[1, 2, 3, 4, 5]]]
    end

    it "can find multiple solutions" do
      m = Doku::DancingLinks::LinkMatrix.from_sets({
        :a => [1,2,     ],
        :b => [    3,4,5],
        :c => [1,  3,  5],
        :d => [  2,  4, ],
      })
      solutions = m.enum_for(:each_exact_cover_recursive).to_a.collect { |s| s.sort }
      solutions.should include [:a, :b]
      solutions.should include [:c, :d]
    end
  end

  shared_examples_for "figure 3 from Knuth" do
    it "has 7 columns" do
      @m.columns.to_a.size.should == 7
    end

    it "has the expected columns" do
      @m.columns.collect(&:id).should == @universe
    end

    it "has the expected structure" do
      # This test is not exhaustive.
      columns = @m.columns.to_a
      columns[0].down.should_not == columns[0]
      columns[0].up.should_not == columns[0]
      columns[0].nodes.to_a.size.should == 2
      columns[0].up.up.should == columns[0].down
      columns[0].up.should == columns[0].down.down

      columns[0].down.right.up.should == columns[3]
      columns[3].down.left.up.should == columns[0]
      columns[0].down.down.right.up.up.should == columns[3]
      columns[0].down.down.right.right.right.down.down.should == columns[3]
      columns[2].up.right.down.should == columns[5]

      columns[6].down.down.down.left.up.left.down.left.down.down.should == columns[1]
    end

    it "every row has a reference to the column" do
      @m.columns.each do |column|
        column.nodes.each do |node|
          node.column.should == column
        end
      end
    end
  end

  context "given figure 3 from Knuth" do
    before do
      @universe = [1,2,3,4,5,6,7]
      @subsets = [[    3,  5,6  ],
                  [1,    4,    7],
                  [  2,3,    6  ],
                  [1,    4      ],
                  [  2,        7],
                  [      4,5,  7],
                 ]
      @m = Doku::DancingLinks::LinkMatrix.from_sets @subsets, @universe
    end

    it_should_behave_like "figure 3 from Knuth"

    it "can find an exact cover" do
      result = @m.find_exact_cover
      result.collect(&:sort).sort.should == [[1, 4], [2, 7], [3, 5, 6]]
    end

    # TODO: test this using a matrix that has multiple exact covers
    it "can find all exact covers" do
      @m.exact_covers.to_a.sort.should == [[[1, 4], [3, 5, 6], [2,7]]]
    end

    context "after running each_exact_cover" do
      before do
        # If we let each_exact_cover run all the way through, it restores
        # the matrix to its original state.
        @m.each_exact_cover { }
      end

      it_should_behave_like "figure 3 from Knuth"
    end

    context "with one row covered" do
      before do
        @m.column(@universe[3]).cover
      end

      it "has only 6 columns" do
        @m.columns.to_a.size.should == 6
      end

      # @m will now look like (minus means a covered element)
      # 0 0 1 - 1 1 0
      # - - - - - - -
      # 0 1 1 - 0 1 0
      # - - - - - - -
      # 0 1 0 - 0 0 1
      # - - - - - - -
      it "has the expected column sizes" do
        @universe.collect { |e| @m.column(e).size }.should == [0, 2, 2, 3, 1, 2, 1]
        @m.columns.collect { |c| c.size }.should == [0, 2, 2, 1, 2, 1]
      end

      it "has the expected structure" do
        columns = @m.columns.to_a

        # Column 0 is empty.
        columns[0].down.should == columns[0]
        columns[0].up.should == columns[0]
        columns[0].nodes.to_a.should be_empty

        columns[1].down.right.up.up.should == columns[2]
        columns[2].down.right.up.should == columns[3]
        columns[3].up.right.down.down.should == columns[4]
        columns[5].down.right.down.should == columns[1]

        columns[5].up.left.up.right.up.right.right.down.down.should == columns[4]
      end

      context "and then uncovered" do
        before do
          @m.column(@universe[3]).uncover          
        end

        it_should_behave_like "figure 3 from Knuth"
      end
    end
  end
end
