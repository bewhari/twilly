class Player < ActiveRecord::Base

  validates :name,  presence: true
  validates :phone_num, presence: true, uniqueness: true

  def create_player(name, phone_num)
    @player = Player.new(name: name, phone_num: phone_num)
    if @player.save
      return "New player"
    else
      return "Duplicate player"
    end
  end

end
