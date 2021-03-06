require 'tictactoe'
require 'facets'

Spec::Matchers.define :look_like do |string|
  match do |board|
    string.remove_spaces!
    board.display_string_with("\n") == string
  end
end

class String
  def remove_spaces!
    self.gsub!(/ /, '')
  end
end

module TicTacToe

  describe Position do
    before {@position = Position.new 1, 2}
    it "should have an x and a y" do
      @position.x.should == 1
      @position.y.should == 2
    end
  end

  class Board
    def self.setup string
      board = Board.new
      string.remove_spaces!
      string.each_with_index do |row, y|
        x = 0
        row.chomp!
        row.each_char do |symbol|
          board[x,y] = player(symbol)
          x += 1
        end
      end
      board
    end
    def self.player character
      case character
      when 'X', 'x' : :x
      when 'O', 'o' : :o
      when '.' : nil
      else raise "No player for #{character.inspect}"
      end
    end
  end

  describe Board do
    before {@board = Board.new}

    it "has nine cells" do
      count = 0
      @board.each {count += 1}
      count.should == 9
    end
    it "allows access each cell's contents (empty board)" do
      @board.each_with_index {|x, y, contents| contents.should == nil}
    end
    it "allows access each cell's contents (full board)" do
      @board = Board.setup <<-END
        XOX
        OXX
        OXO
      END
      result = ""
      @board.each do |contents| 
        contents.should_not be_nil
        result << contents.to_s
      end
      result.should == 'xoxoxxoxo'
    end
    it "allows access each cell's position" do
      positions = []
      @board.each_with_index {|x, y, contents| positions << [x, y]}
      expected = (0..2).to_a.product((0..2))
      positions.should include(*expected)
      positions.should have(9).items
    end
    it "can be setup from a 'string view'" do
      @board = Board.setup <<-END
        X..
        .X.
        ..X
      END
      @board.should look_like(<<-END)
        X..
        .X.
        ..X
      END
    end
    it "can detect three-in-a-row as diagonal" do
      @board = Board.setup <<-END
        ..X
        .X.
        X..
      END
      @board.should be_three_in_a_row(:x)
      row = @board.three_in_a_row?(:x)
      row.type.should == :diagonal
      row.cells.should == [[0,2], [1,1], [2,0]]
      row.line(4).should == [1.0, 11.0, 11.0, 1.0]
    end
    it "can detect three-in-a-row across" do
      @board = Board.setup <<-END
        ...
        XXX
        ...
      END
      row = @board.three_in_a_row?(:x)
      row.type.should == :across
      row.line(60).should == [15.0, 90.0, 165.0, 90.0]
    end
    it "can detect three-in-a-row down" do
      @board = Board.setup <<-END
        ..X
        ..X
        ..X
      END
      @board.should be_three_in_a_row(:x)
      row = @board.three_in_a_row?(:x)
      row.type.should == :down
      row.cells.should == [[2,0],[2,1],[2,2]]
      row.line(4).should == [10.0, 1.0, 10.0, 11.0]
    end
    it "won't detect a three-in-a-row when it isn't there" do
      @board = Board.setup <<-END
        ...
        ...
        ...
      END
      @board.should_not be_three_in_a_row(:x)
    end
    it "can detect a full board" do
      @board = Board.setup <<-END
        XOX
        OXX
        OXO
      END
      @board.should be_filled
    end
    it "won't detect a full board when it isn't full" do
      @board = Board.setup <<-END
        X..
        X..
        X..
      END
      @board.should_not be_filled
    end
  end

  describe Game do
    before {@game = Game.new}
    def board_should_be string
      string.remove_spaces!
      @game.board.display_string_with("\n").should == string
    end
    it "has a board" do
      @game.board.should be_a(Board)
    end
    it "allows you to move in the center" do
      @game.play :x, 1, 1
      @game.board[1, 1].should == :x
      board_should_be <<-END
        ...
        .X.
        ...
      END
    end
    it "allows you to move in the corner" do
      @game.play :x, 0, 2
      @game.board[0, 2].should == :x
      board_should_be <<-END
        ...
        ...
        X..
      END
    end
    it "alternates turns" do
      @game.play :x, 1, 1
      @game.whose_turn.should == :o
      @game.play :o, 0,0
      @game.whose_turn.should == :x
    end
    it "won't let you play when its not your turn" do
      lambda {@game.play :o, 1, 1}.should raise_error(NotYourTurn)
    end
    it "won't let you play in a space that is filled" do
      @game.play :x, 1, 1
      lambda {@game.play :o, 1, 1}.should raise_error(SpaceNotEmpty)
    end
    it "won't let you play when the game is over" do
      @game.play :x, 0, 0
      @game.play :o, 0, 1
      @game.play :x, 1, 0
      @game.play :o, 1, 1
      @game.play :x, 2, 0
      lambda {@game.play :o, 2, 1}.should raise_error(GameOver)
    end
    it "can tell if the game is over due to three-in-a-row" do
      @game.board = Board.setup <<-END
        ...
        .X.
        X..
      END
      @game.play :x, 2, 0
      @game.should be_over
      @game.result.should == "Three in a row. X wins."      
    end
    it "can tell if the game is over due to a scratch game" do
      @game.board = Board.setup <<-END
        XOX
        OX.
        OXO
      END
      @game.play :x, 2, 1
      @game.should be_over
      @game.result.should == "Scratch Game."            
    end

    describe "at start" do
      it "starts with X's turn" do
        @game.whose_turn.should == :x
      end
      it "has a blank board" do
        board_should_be <<-END
          ...
          ...
          ...
        END
      end
    end
  end
end
