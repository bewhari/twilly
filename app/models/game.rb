class Game < ActiveRecord::Base
  has_many :players



  def self.create_game(sel, board, turn, status)




    @game = Game.new(sel: sel, board: board, turn: turn, status: status)
    if @game.save
      return @game
    end
  end


  def set_status(status)
    self.update_attribute("status", status)
  end

  def set_turn(turn)
    self.update_attribute("turn", turn)
  end

end
