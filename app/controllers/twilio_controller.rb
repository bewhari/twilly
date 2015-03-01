class TwilioController < ApplicationController

  include TwilioHelper

  def send_sms
    message = params[:message]
    number = params[:number]
    account_sid = 'AC6dd2a8e741e05b7053a3231a17526669'
    auth_token = 'dbcbe0c84d3a88ac9993ccef4296ddb1'

    @client = Twilio::REST::Client.new account_sid, auth_token

    @message = @client.account.messages.create({
      :to => "+1"+"#{number}",
      :from => "+12246332067",
      :body => "#{message}"
    })

    redirect_to '/'
  end

  def receive_sms

=begin
    if @message_body == "Start"
      prompt
      @name = nil
    else
      if @name.nil?
        @name = @message_body
        @reply_message = "HERE"
      else
        @reply_message = "Parse function! Woohoo!"
      end
    end
=end

    #respond(params)

    #render 'receive_sms.xml.erb', :content_type => 'text/xml'

    #twiml = Twilio::TwiML::Response.new do |r|
    #  r.Message "I don't understand."
    #end
    #twiml.text

    message = params[:Body]
    from = params[:From]
    #city = params[:FromCity]
    #state = params[:FromState]

    player = Player.where(phone_num: from).first
    reply_message = ""

    if %w{ exit x q}.include?(message.to_s.downcase)
      if player == nil
        return
      elsif [0, nil].include?(player.attributes['game_id'])
        clear_player(player)
      else
        game = Game.where(id: player.attributes['game_id']).first
        other_player = Player.where(game_id: player.attributes['game_id'], num: (player.attributes['num']%2+1)).first
        if other_player == nil
          reply_message = 'Your game has been removed.'
          send_message(reply_message, from)
          clear_player(player)
          game.destroy
        else
          reply_message = 'You have forfeit the game. A shame...'
          send_message(reply_message, from)


          forfeit_message = 'Your opponent has forfeit the game. You win!'
          send_message(forfeit_message, other_player.attributes['phone_num'])
          prompt(other_player)
          clear_game(game, player, other_player)
        end
      end
      return
    end


    if player == nil

      # create player
      player = Player.create_player(message, from)

      reply_message = "Hello #{message}! Welcome to Twilly powered by Twilio. "
      send_message(reply_message, from)
    elsif player.attributes['game_id'] == nil
      reply_message = "Welcome back #{player.attributes['name']}! "
      send_message(reply_message, from)
    end


    player_game_id = player.attributes['game_id']

    if player_game_id == nil
      prompt(player)

    elsif player_game_id == 0  #player replied with game type
      sel = nil
      if %w{tictactoe tic-tac-toe}.include?(message.to_s.downcase) or message.to_s.to_i == 1
        reply_message = "Tic-Tac-Toe? Classic! "
        sel = 1
        data = '0' * 9
      elsif %w{connect\ four connectfour connect\ 4 connect4}.include?(message.to_s.downcase) or message.to_s.to_i == 2
        reply_message = "Connect Four? Sweet! "
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
          display_game(game, other_player)
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
              display_game(game, nil)

              reply_message = 'The game is a draw!'
              send_message(reply_message, from)
              send_message(reply_message, other_player_phone_num)

              clear_players(game, player, other_player)

            #player.set_game_id(nil)
            #player.set_player_num(0)
            #other_player.set_game_id(nil)
            #other_player.set_player_num(0)
            when 1..2
              display_game(game, nil)

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
              display_game(game, nil)

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




end
