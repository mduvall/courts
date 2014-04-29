require "net/http"
require "nokogiri"

class Courts
  BASE_URI = "http://webaccess.sftc.org"

  def self.get_case_by_name(first, last)
    uri = URI(BASE_URI + "/Scripts/Magic94/mgrqispi94.dll")
    post_data = {
      'APPNAME' => 'WEB',
      'PRGNAME' => 'NamePicklist',
      'ARGUMENTS' => 'Name+Filter+{k}',
      'Name+Filter+{k}' => last
    }

    req = Net::HTTP::Post.new(uri)
    req.set_form_data(post_data)
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    case res
    when Net::HTTPSuccess
      contents = []
      doc = Nokogiri::HTML(res.body)
      doc.css("td a").each do |e|
        contents << {content: e.content, link: e['href']}
      end
    end

    contents
  end

  def self.get_case_by_last_name(last)
    self.get_case_by_name(nil, last)
  end

  def self.get_case_by_first_name(first)
    self.get_case_by_name(first, nil)
  end
end

Courts.get_case_by_name(nil, 'DuVall').each do |c|
  puts c[:content]
  puts "\t" + c[:link]
end
