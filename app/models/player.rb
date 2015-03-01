class Player < ActiveRecord::Base
  belongs_to :game

  validates :name,  presence: true
  validates :phone_num, presence: true, uniqueness: true

  def self.create_player(name, phone_num)
    @player = Player.new(name: name, phone_num: phone_num, game_id: nil, num: 0)

    if @player.save
      return @player
    end

  end

  def set_game_id(game_id)
    self.update_attribute("game_id", game_id)
  end

  def set_player_num(num)
    self.update_attribute("num", num)
  end

end
