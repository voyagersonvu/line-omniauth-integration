require "faraday"
require "json"
require "line/bot"

class LineNotifyService
  def initialize(user)
    @user = user
  end

  def send_message(text)
    return false if @user.uid.blank?

    request_body = {
      to: @user.uid,
      messages: [
        { type: "text", text: text }
      ]
    }

    Rails.logger.info("LINE: Preparing to send message to UID=#{@user.uid}, body=#{request_body}")

    begin
      # Production / normal SDK call
      response = LINE_V2_CLIENT.push_message(
        push_message_request: Line::Bot::V2::MessagingApi::PushMessageRequest.new(
          to: @user.uid,
          messages: [ Line::Bot::V2::MessagingApi::TextMessage.new(text: text) ]
        )
      )
      Rails.logger.info("LINE SDK response: #{response.inspect}")
      response
    rescue OpenSSL::SSL::SSLError => e
      Rails.logger.warn("LINE SDK SSL failed: #{e.class}: #{e.message}.")
      if Rails.env.development?
        # Dev-only fallback
        send_via_faraday_fallback(request_body)
      else
        raise
      end
    end
  end

  private

  # Dev-only fallback: POST directly and disable SSL verification
  def send_via_faraday_fallback(body)
    token = ENV.fetch("LINE_CHANNEL_ACCESS_TOKEN")

    conn = Faraday.new(url: "https://api.line.me", ssl: { verify: false }) do |f|
      f.request :json
      f.response :logger
      f.adapter Faraday.default_adapter
    end

    resp = conn.post("/v2/bot/message/push") do |req|
      req.headers["Content-Type"]  = "application/json"
      req.headers["Authorization"] = "Bearer #{token}"
      req.body = body.to_json
    end

    Rails.logger.info("LINE fallback response: #{resp.status} #{resp.body}")
    resp
  end
end
