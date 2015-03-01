module TwilioHelper

  def respond(params)
    message = params[:Body]
    from = params[:From]
    city = params[:FromCity]
    state = params[:FromState]

    player = Player.where(phone_num: from).first
    reply_message = ""

    if player == nil

      # create player
      player = Player.create_player(message, from)

      reply_message = "Hello #{message}! Welcome to Text Games powered by Twilio. "
    elsif player.attributes["game_id"] == nil
      reply_message = "Welcome back #{player.attributes["name"]}! "
    end

    player_game_id = player.attributes["game_id"]

    if player_game_id == nil
      reply_message += "What game would you like to play? "

      player.set_game_id(0)

    elsif player_game_id == 0  #player replied with game type
      if ["connectfour", "connect4"].include?(message.to_s.downcase)
        reply_message = "ConnectFour? Sweet! "
        game = Game.where(sel: 1, status: 1).first
        if game == nil
          game = Game.create_game(1, nil, 1, 1)
          player.set_game_id(game.attributes["id"])
          player.set_player_num(1)
          reply_message += "Game created! Waiting for opponent..."
        else
          player.set_game_id(game.attributes["id"])
          player.set_player_num(2)
          game.set_status(2)
          reply_message += "Joined game! Opponent's move. "
          other_player = Player.where(game_id: game.attributes["id"]).first
          other_player_message = "Opponent found! Game started. Your move. "
          send_message(other_player_message, other_player.attributes["phone_num"])
        end




      else
        reply_message = "Sorry we don't support that game. Please try again."
      end

    else #player is in a game
      game = Game.where(id: player_game_id).first
      game_status = game.attributes["status"]
      game_turn = game.attributes["turn"]

      if game_status == 1
        reply_message = "Still waiting for an opponent... "
      else
        if game_turn == player.attributes["num"]
          game.update_board(message)
          game.set_turn(game_turn == 1 ? 2 : 1)

          send_message(reply_message,
                       Player.where(game_id: game.attributes["id"],
                                    num: game.attributes["turn"]).first.attributes["phone_num"])

        else
          reply_message = "Not your turn. "
        end
      end
    end



    send_message(reply_message, from)
  end


  def send_message(message, to)
    account_sid = 'AC6dd2a8e741e05b7053a3231a17526669'
    auth_token = 'dbcbe0c84d3a88ac9993ccef4296ddb1'

    @client = Twilio::REST::Client.new account_sid, auth_token

    @message = @client.account.messages.create({
      :to => "#{to}",
      :from => "+12246332067",
      :body => "#{message}"
    })
  end

end
