module TwilioHelper

  def respond(params)
    message = params[:Body]
    from = params[:From]
    city = params[:FromCity]
    state = params[:FromState]

    if %w{ exit quit }.include?(message.to_s.downcase)
      return
    end

    player = Player.where(phone_num: from).first
    reply_message = ""

    if player == nil

      # create player
      player = Player.create_player(message, from)

      reply_message = "Hello #{message}! Welcome to Twilly powered by Twilio. "
    elsif player.attributes['game_id'] == nil
      reply_message = "Welcome back #{player.attributes['name']}! "
    end

    player_game_id = player.attributes['game_id']

    if player_game_id == nil
      reply_message += 'What game would you like to play?'

      player.set_game_id(0)

      send_message(reply_message, from)

    elsif player_game_id == 0  #player replied with game type
      sel = nil
      if %w{tictactoe tic-tac-toe}.include?(message.to_s.downcase)
        reply_message = "Tic-Tac-Toe? Classic! "
        sel = 1
        data = '0' * 9
      elsif %w{connectfour connect4}.include?(message.to_s.downcase)
        reply_message = "ConnectFour? Sweet! "
        sel = 2
        data = '0' * 42
      else
        reply_message = "Sorry we don't support that game. Please try again."
      end

      if sel != nil
        game = Game.where(sel: sel, status: 1).first
        if game == nil
          game = Game.new(sel: sel, data: data, turn: 1, status: 1)
          game.save
          player.set_game_id(game.attributes['id'])
          player.set_player_num(1)
          reply_message += "Game created! Waiting for opponent..."
        else
          player.set_game_id(game.attributes['id'])
          player.set_player_num(2)
          game.set_status(2)
          other_player = Player.where(game_id: game.attributes['id']).first
          other_player_message = "Opponent found! You are playing against #{player.attributes['name']}. Your move."
          send_message(other_player_message, other_player.attributes['phone_num'])
          reply_message += "Joined game! You are playing against #{other_player.attributes['name']}. Opponent's move."
        end
      end

      send_message(reply_message, from)


    else #player is in a game
      game = Game.where(id: player_game_id).first
      game_id = game.attributes["id"]
      game_status = game.attributes["status"]
      game_turn = game.attributes["turn"]

      if game_status == 1
        reply_message = "Still waiting for an opponent... "
        send_message(reply_message, from)
      else
        other_player = Player.where(game_id: game_id, num: (player.attributes['num']%2+1)).first
        other_player_phone_num = other_player.attributes['phone_num']

        if game_turn == player.attributes["num"]
          game.update_board(message)

          state = game.get_state
          case state
            when 'ii'
              reply_message = 'Invalid input'
              send_message(reply_message, from)
            when 'im'
              reply_message = 'Invalid move'
              send_message(reply_message, from)
            when 'draw'
              display_game(game)

              reply_message = 'The game is a draw!'
              send_message(reply_message, from)
              send_message(reply_message, other_player_phone_num)

              clear_players(game, player, other_player)

              #player.set_game_id(nil)
              #player.set_player_num(0)
              #other_player.set_game_id(nil)
              #other_player.set_player_num(0)
            when 1..2
              display_game(game)

              win_message = 'You win! :)'
              lose_message = 'You lose... :('
              if player.attributes['num'] == state
                send_message(win_message, from)
                send_message(lose_message, other_player_phone_num)
              else
                send_message(lose_message, from)
                send_message(win_message, other_player_phone_num)
              end

              clear_players(game, player, other_player)

              #player.set_game_id(nil)
              #player.set_player_num(0)
              #other_player.set_game_id(nil)
              #other_player.set_player_num(0)
            else
              # continue play
              display_game(game)

              prompt_message = "It's your turn."
              #send_message(reply_message, from)
              #send_message(reply_message, other_player_phone_num)
              send_message(prompt_message, other_player_phone_num)
          end

        else
          reply_message = "It's not your turn!"
          send_message(reply_message, from)
        end
      end

    end

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

  def display_game(game)
    data = game.attributes['data']
    message = ''

    case game.attributes['sel']
      when 1 # tictactoe
        message += "Tic-tac-toe\n"
        max_per_line = 3
        empty_space = "\u25FB"                  # white square
        player_one_space = "\u2B55"#"\xF0\x9F\x94\xB5"
        player_two_space = "\u274C"#"\xF0\x9F\x94\xB4"
        row_label = ["\x31\xE2\x83\xA3",
                     "\x32\xE2\x83\xA3",
                     "\x33\xE2\x83\xA3"]
        col_label = ["\x31\xE2\x83\xA3",
                     "\x32\xE2\x83\xA3",
                     "\x33\xE2\x83\xA3"]

      when 2 # connectfour
        message += "ConnectFour\n"
        max_per_line = 7
        empty_space = "\u26AA"                  # white circle
        player_one_space = "\xF0\x9F\x94\xB5"   # blue circle
        player_two_space = "\xF0\x9F\x94\xB4"   # red circle
        row_label = ''
        col_label = ["\x31\xE2\x83\xA3",
                     "\x32\xE2\x83\xA3",
                     "\x33\xE2\x83\xA3",
                     "\x34\xE2\x83\xA3",
                     "\x35\xE2\x83\xA3",
                     "\x36\xE2\x83\xA3",
                     "\x37\xE2\x83\xA3"]
      else
        max_per_line = 10
        empty_space = ' '
        player_one_space = '1'
        player_two_space = '2'
    end

    count = 0
    for i in 0..data.length-1
      if !row_label.empty? and i%max_per_line == 0
        message += row_label[i/max_per_line]
      end

      if data[i] == '0'
        message += empty_space
      elsif data[i] == '1'
        message += player_one_space
      else
        message += player_two_space
      end

      count += 1

      if count == max_per_line
        message += "\n"
        count = 0
      end

    end

    if !row_label.empty?
      message += "\xF0\x9F\x86\x92"
    end

    for i in 0..max_per_line-1
      message += col_label[i]
    end


    Player.where(game_id: game.attributes['id']).find_each do |player|
      send_message(message.encode('utf-8'), player.attributes['phone_num'])
    end
  end

  def clear_players(game, player, other_player)
    player.set_game_id(nil)
    player.set_player_num(0)
    other_player.set_game_id(nil)
    other_player.set_player_num(0)

    game.destroy
  end

end
