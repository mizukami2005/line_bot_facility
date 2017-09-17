require 'sinatra'
require 'line/bot'

get '/' do
  "Hello world Web test"
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
        message  = {
          type: 'text',
          text: event.message['text']
        }
        carousel = {
          type:     "template",
          altText:  "this is a carousel template",
          template: {
            type:    "carousel",
            columns: [
                       {
                         thumbnailImageUrl: 'https://h-navi.jp/uploads/support_facility/157092/half_0fa2da42-6df4-4f2c-83fa-cab44ea7f95c.png',
                         title:             'でらいとわーくジュニア　かまたアフタースクール',
                         text:              '放課後等デイサービス',
                         actions:           [
                                              {
                                                type:  'uri',
                                                label: '詳しく見る',
                                                uri:   'https://h-navi.jp/support_facility/facilities/157092'
                                              }
                                            ]
                       },
                       {
                         thumbnailImageUrl: 'https://h-navi.jp/uploads/support_facility/157161/half_6737b4bc-23ec-4303-a74f-515a9f5deb06.png',
                         title:             '発達支援教室にじいろLabo池上',
                         text:              '放課後等デイサービス',
                         actions:           [
                                              {
                                                type:  'uri',
                                                label: '詳しく見る',
                                                uri:   'https://h-navi.jp/support_facility/facilities/157161'
                                              }
                                            ]
                       }
                     ]
          }
        }
        client.reply_message(event['replyToken'], carousel)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf       = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  }

  "OK"
end
