require 'sinatra'
require 'line/bot'
require 'json'
require 'uri'
require 'net/http'

get '/' do
  "Hello world Web test"
  prefecture = "東京都"
  query = "prefecture=#{prefecture}"
  uri_string = URI::Generic.build(scheme: 'https', host: 'script.google.com', path: '/macros/s/AKfycbwH5nz9yLEWpt-E43Yff-O7i3gc-PV4NM1-d6SO3KEu/dev').to_s
  uri        = URI.parse(uri_string)
  results    = ''

  begin
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.get(uri.request_uri)
    end
    case response
    when Net::HTTPSuccess
      json    = response.body
      results = JSON.parse(json)
      p "OK"
      p results
    end
  rescue => e
  end

end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token  = ENV["LINE_CHANNEL_TOKEN"]
  }
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do
      'Bad Request'
    end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        if event.message['text'] =~ /(\s|　)/
          prefecture = $`
          query = "prefecture=#{prefecture}"
          uri_string = URI::Generic.build(scheme: 'https', host: 'script.google.com', path: '/macros/s/AKfycbwH5nz9yLEWpt-E43Yff-O7i3gc-PV4NM1-d6SO3KEu/dev', query: query).to_s
          uri        = URI.parse(uri_string)
          results    = ''

          begin
            response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
              http.get(uri.request_uri)
            end
            case response
            when Net::HTTPSuccess
              json    = response.body
              results = JSON.parse(json)
            end
          rescue => e
          end

          columns = []

          if results['rest'].nil?
            error_message = {
              type: 'text',
              text: '見つからなかったよ!'
            }
            client.reply_message(event['replyToken'], error_message)
          else
            results['data'].each_with_index do |result, index|
              hash = {}
              hash['title'] = result['name']
              columns[index]  = hash
            end
          end
        end

        message  = {
          type: 'text',
          text: event.message['text']
        }
        carousel = {
          type:     "template",
          altText:  "this is a carousel template",
          template: {
            type:    "carousel",
            columns: columns
          }
        }
        client.reply_message(event['replyToken'], carousel)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf       = Tempfile.open("content")
        tf.write(response.body)
      end
    when Line::Bot::Event::Postback
      if event['postback']['data'].include?('tel')
        tel    = event['postback']['data'].split('=')
        message = {
          type: 'text',
          text: tel[1]
        }
      end
      client.reply_message(event['replyToken'], message)
    end
  }

  "OK"
end
