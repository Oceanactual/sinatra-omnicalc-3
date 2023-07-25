require "sinatra"
require "sinatra/reloader"
require "http"
require "json"
require "sinatra/cookies"

get("/") do
  @welcome = "Welcome to Omnicalc 3"
  erb(:welcome)
end

get("/umbrella") do
  erb(:umbrella_form)
end

post("/process_umbrella") do
  @user_location = params.fetch("user_loc")

  url_location = @user_location.gsub(" ","+")
  gmaps_url = "hold" #add address w/ url_location and do not forget to add the key
  
  @raw_response = HTTP.get(gmaps_url).to_s

  @parsed_response = JSON.parse(@raw_response)

  #@loc_hash = @parsed_response.dig("results", 0, )
  @latitude = @loc_hash.parse("lat")
  @longitude = @loc_hash.parse("lng")
  erb(:umbrella_results)

  cookies[last_location] = @user_location
  cookies[last_lat] = @latitude
end

get("/single_message") do
  erb(:single_ai)
end

post("/single_response") do 
  @gpt_key_local = ENV.fetch("GPT_KEY")
  @responses = params.fetch("message").to_s
  request_headers_hash = {
    "Authorization" => "Bearer #{ENV.fetch("GPT_KEY")}",
    "content-type" => "application/json"
  }
  
  request_body_hash = {
    "model" => "gpt-3.5-turbo",
    "messages" => [
      {
        "role" => "system",
        "content" => "You are a helpful assistant who talks like Shakespeare."
      },
      {
        "role" => "user",
        "content" => @responses
      }
    ]
  }

  request_body_json = JSON.generate(request_body_hash)

  raw_response = HTTP.headers(request_headers_hash).post(
    "https://api.openai.com/v1/chat/completions",
    :body => request_body_json
  ).to_s
  
  @parsed_response = JSON.parse(raw_response)
  @response_pure = @parsed_response.dig("choices", 0, "message", "content")
  
  erb(:single_ai_response)
end

get("/chat") do
  cookies.store("round", 0)
  erb(:chat_start)



end


post("/chat_conversation") do 

  @round = cookies.fetch("round").to_i

  @response_array = []
  @input_array = []
  @gpt_key_local = ENV.fetch("GPT_KEY")
  @responses_chat = params.fetch("chat").to_s
  request_headers_hash_chat = {
    "Authorization" => "Bearer #{ENV.fetch("GPT_KEY")}",
    "content-type" => "application/json"
  }
  
  request_body_hash_chat = {
    "model" => "gpt-3.5-turbo",
    "messages" => [
      {
        "role" => "system",
        "content" => "You are a creative dungeon master like matt mercer or brennan lee mulligan."
      },
      {
        "role" => "user",
        "content" => @responses_chat
      }
    ]
  }

  request_body_json_chat = JSON.generate(request_body_hash_chat)

  raw_response_chat = HTTP.headers(request_headers_hash_chat).post(
    "https://api.openai.com/v1/chat/completions",
    :body => request_body_json_chat
  )
  
  @parsed_response_chat = JSON.parse(raw_response_chat)
  @response_pure_chat = CGI.unescape(@parsed_response_chat.dig("choices", 0, "message", "content").to_s)

  cookies.store("user#{@round}", @responses_chat)
  cookies.store("response#{@round}", @response_pure_chat)
  @round = @round + 1
  cookies.store("round", @round)

  erb(:chat)
end
