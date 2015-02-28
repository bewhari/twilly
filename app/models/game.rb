class Game < ActiveRecord::Base
  has_many :players

  def self.create_game(type, board, turn, status)
    @game = Game.new(type: type, board: board, turn: turn, status: true)
    if @game.save
      return "New game created!"
    else
      return "Failed to create game :("
    end
  end

end
