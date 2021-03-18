class SlackNotification
  def self.perform(url, payload)
    url = "https://api.eu.opsgenie.com/v2/alerts"
    json = payload.to_json
    og_api = ENV['OG_API']
    request = HTTParty.post(url, body: json, headers: {'Content-Type' => "application/json", 'Authorization' => "GenieKey #{og_api}"})
    if request.code == 202
      request.body
    else
      puts "Error sending webhook to url=#{url} for payload=#{payload.to_json}"
      return false
    end
  end
end
