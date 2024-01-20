require "faraday"

module SearchesHelper
  def search_valid?(input)
    words = input.strip.split

    # Questions must be at least 3 words long because of the structure of a question in English language
    return false unless words.length >= 3

    # Only save searches where the first word is at least 2 characters long for questions(Is it, Do you) and last word is at least 2 characters long so that questions doesn't end with single character
    words[-1].length >= 2 && words[0].length >= 2
  end

  def update_or_create_search(query, user)
    existing_search = Search.find_by(query: query.strip.downcase, user_id: user.id)

    if existing_search
      existing_search.update(count: existing_search.count + 1)
    else
      Search.create(query: query.strip.downcase, user:)
    end
  end

  def convert_queries_to_string(queries)
    queries.pluck(:query, :id).map { |s| "'{#{s[0]}},#{s[1]}'" }.join(",")
  end

  def filter_valid_queries_ids(queries, api_key)
    connection = Faraday.new(url: "https://api.openai.com/v1/chat/completions")

    res = connection.post do |req|
      req.headers["Content-Type"] = "application/json"
      req.headers["Authorization"] = "Bearer #{api_key}"
      req.body = {
        model: "gpt-3.5-turbo",
        messages: [
          {
            role: "system",
            content: "You're a grammar checker. I'll send you the inputs with their number in this format '{input},number' separated by commas. Your task is to filter everything that are not questions.If you can't read the sentence or words, simply ignore them. Send me the number of the grammatically correct questions that have objects by separating them by commas. If there is none, simply send back a empty space.",
          },
          {
            role: "user",
            content: queries.to_s,
          },
        ],
        temperature: 0.7,
      }.to_json
    end

    response = JSON.parse(res.body)
    response["choices"][0]["message"]["content"].split(",")
  end
end
