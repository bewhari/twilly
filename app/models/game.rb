class Game < ActiveRecord::Base
  has_many :players

=begin
  def initialize(sel, data, turn, status)

    @board = nil
    if sel == 1
      @board = ConnectFour.new()
    end

    @state = nil

    @game = Game.new(sel: sel, data: data, turn: turn, status: status)
    if @game.save
      return @game
    end
  end
=end

  def get_state
    return @state
  end

  def set_status(status)
    self.update_attribute("status", status)
  end

  def set_turn(turn)
    self.update_attribute("turn", turn)
  end

  def update_board(input)

    game = self.attributes['sel']

    if game = 1 # tictactoe
      @board = Tictactoe.new
      @board.setBoard(self.attributes['data'])
      @board.setPlayer(self.attributes['turn'])

      extract = input.split(',').map(&:to_i)
      if extract.length != 2 or extract.include?(0)
        @state = 'ii'
      else
        @state = @board.play(extract[0], extract[1])
        case @state
          when false
            @state = 'im'
          when true
            self.update_attribute('data', @board.getBoard)
            self.set_turn(self.attributes['turn']%2 + 1)
          when 'win_lose'
            @state = self.attributes['turn']
          else #draw
            return
        end
      end


    elsif game = 2 # connectfour
      @board = ConnectFour.new
      @board.setBoard(self.attributes['data'])
      @board.setPlayer(self.attributes['turn'])

      extract = input.to_s.first.to_i
      if extract == 0
        @state = 'ii'
      else
        @state = @board.play(extract)
        case @state
          when false
            @state = 'im'
          when true
            self.update_attribute('data', @board.getBoard)
            self.set_turn(self.attributes['turn']%2 + 1)
          when 'win_lose'
            @state = self.attributes['turn']
          else #draw
            return
        end
      end
    end


  end

end








class Board
  attr_accessor :board
  attr_reader :rowSize, :colSize, :boardSize

  def initialize(colSize, rowSize)
    @colSize = colSize
    @rowSize = rowSize
    @boardSize = @rowSize * @colSize
    #@board = "0" * @boardSize
    @board = Array.new(@boardSize,0) # build empty board
  end

  # def dispBoard()
  #   (0..@boardSize-@rowSize).step(@rowSize) do |n|
  #     print "#{@board[n,rowSize]}\n"
  #   end
  #   puts
  # end

  def getBoard
    return @board.join
  end

  def setBoard(data)
    for i in 0..@boardSize-1
      @board[i] = data.to_s[i].to_i
    end
  end

  def get(m,n)
    return @board[index(m,n)]
  end

  def set(m, n, val)
    @board[index(m,n)] = val
  end

  def index(m,n)
    # need to check for out of bounds
    return (@rowSize * m + n)
  end
end

class Boardgame
  attr_accessor :board_p1, :board_p2, :game_over, :player, :gravity, :diagonal, :board
  attr_reader :rowSize, :colSize, :boardSize, :winLen

  def initialize(colSize, rowSize, winLen)
    @colSize = colSize
    @rowSize = rowSize
    @boardSize = @rowSize * @colSize
    @winLen = winLen
    @board = Board.new(colSize,rowSize)
    @board_index = 0
    @game_over = 0
    @diagonal = 1
    @player = 1
    @vacant = @boardSize
  end

  def getBoard
    return @board.getBoard
  end

  def setBoard(data)
    @board.setBoard(data)
  end

  def setPlayer(player)
    @player = player
  end

  def setDiagonal(val)
    if val > 0 then @diagonal = 1
    else @diagonal = 0
    end
  end

  def validPlay(row, col)
    if (row < 1 or row > @colSize)
      return false
    elsif (col < 1 or col > @rowSize)
      return false
    elsif (@board.get(row-1,col-1) == 0)
      return true
    else
      return false
    end
  end

  def gameOver()
    if @vacant == 0
      return 'draw'
      #puts "Game Over. Draw!"
    else
      return 'win_lose'
      #puts "Game Over. Player #{@player} wins!"
    end
    #@game_over = 1
  end

  def play(row,col)
    if (!validPlay(row, col))
      return false
    else
      col = col - 1
      row = row - 1
      @board.set(row, col, @player)
      #@board.dispBoard()
      if (winCheck(row, col))
        return gameOver()
      end
      @vacant = @vacant - 1
      if (@vacant == 0)
        return gameOver()
      end
      #changePlayer()
      return true
    end
  end

  def changePlayer()
    if (@player == 1)
      @player = 2
    else
      @player = 1
    end
  end

  def changeBoard(n)
    if @numBoards > 0 & n < @numBoards
      @board_index = n
      @board = @boards[@board_index]
      return true
    else
      return false
    end
  end

  def winCheck(m,n)
    # generate paths to check for wins, ensuring not to go out of bounds
    shift = winLen - 1

    row_up_bound = m
    row_low_bound = m
    col_low_bound = n
    col_up_bound = n

    if (m >= shift) then (row_low_bound = row_low_bound - shift) end
    if (n >= shift) then (col_low_bound = col_low_bound - shift) end
    if (m < rowSize - shift) then (row_up_bound = row_up_bound + shift) end
    if (n < colSize - shift) then (col_up_bound = col_up_bound + shift) end

    #check win to top to bottom
    count = 0
    (row_low_bound..row_up_bound).each do |i|
      if @board.get(i,n) == @player
        count = count + 1
        if count == @winLen
          return true
        end
      else
        count = 0
      end
    end

    #check win left to right
    count = 0
    (col_low_bound..col_up_bound).each do |i|
      if @board.get(m, i) == @player
        count = count + 1
        if count == @winLen
          return true
        end
      else
        count = 0
      end
    end

    if (diagonal == 1)
      diag_left_low_edge = [m, n].min
      diag_left_low = [m - diag_left_low_edge, n - diag_left_low_edge]

      diag_right_up_edge = [@colSize - 1 - m, @rowSize - 1 - n].min
      diag_right_up = [m + diag_right_up_edge, n + diag_right_up_edge]

      diag_left_up_edge = [@colSize - 1 - m, n].min
      diag_left_up = [m + diag_left_up_edge, n - diag_left_up_edge]

      diag_right_low_edge = [m, @rowSize - 1 - n].min
      diag_right_low = [m - diag_right_low_edge, n + diag_right_low_edge]

      #check win diag low left to high right
      count = 0
      row_init = diag_left_low[0]
      (diag_left_low[1]..diag_right_up[1]).each do |col|
        if @board.get(row_init + col, col) == @player
          count = count + 1
          if count == @winLen
            return true
          end
        else
          count = 0
        end
      end

      #check win diag high left to low right
      count = 0
      row_init = diag_left_up[0]
      (diag_left_up[1]..diag_right_low[1]).each do |col|
        if @board.get(row_init - col, col) == @player
          count = count + 1
          if count == @winLen
            return true
          end
        else
          count = 0
        end
      end
    end
    return false
  end

  def get2Input()
    input = gets.chomp
    list = input.delete(' ').split(',').map(&:to_i) #convert to int
    return list
  end

  def game()
    while (@game_over == 0)
      list = get2Input()
      play(list[0], list[1])
    end
  end
end

class Tictactoe < Boardgame
  def initialize()
    super(3,3,3)
    setDiagonal(1)
  end
end

class ConnectFour < Boardgame
  def initialize()
    super(6,7,4)
    setDiagonal(1)
  end

  def play(col)
    if (validPlay(1, col) == false)
      return false
    else
      col = col - 1
      for m in (@colSize-1).downto(0)
        if @board.get(m, col) == 0 # fill first empty
          @board.set(m, col, @player)
          #@board.dispBoard()
          if (winCheck(m, col))
            return gameOver()
          end
          #changePlayer()
          return true
        end
      end
    end
  end

  def game()
    while(@game_over == 0)
      input = gets.to_i
      play(input)
    end
  end
end
