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

    respond(params)

    #render 'receive_sms.xml.erb', :content_type => 'text/xml'

    #twiml = Twilio::TwiML::Response.new do |r|
    #  r.Message "I don't understand."
    #end
    #twiml.text
  end




end
