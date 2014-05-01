require "net/http"
require "nokogiri"
require "cgi"

class Courts
  BASE_URI = "http://webaccess.sftc.org"

  def self.get_suit_by_name(first, last)
    uri = self.get_uri_with_path("/Scripts/Magic94/mgrqispi94.dll")
    full_name = first ? "#{last}, #{first}" : last
    post_data = {
      'APPNAME' => 'WEB',
      'PRGNAME' => 'NamePicklist',
      'ARGUMENTS' => 'Name+Filter+{k}',
      'Name+Filter+{k}' => full_name
    }
    res = self.post_with_uri(uri, post_data)

    case res
    when Net::HTTPSuccess
      contents = []
      doc = Nokogiri::HTML(res.body)
      doc.css("td a").each do |e|
        contents << {
          content: e.content,
          suits: self.extract_suits(e['href'])
        }
      end
    end

    contents
  end

  def self.get_suit_by_last_name(last)
    self.get_suit_by_name(nil, last)
  end

  def self.extract_suits(uri)
    res = self.get_with_uri(uri)

    case res
    when Net::HTTPSuccess
      suits = []
      doc = Nokogiri::HTML(res.body)
      doc.css("tr").each_with_index do |e, i|
        next if i == 0
        suit = {}
        suit_attributes = [:suit_id, :name, :party_type, :suit_title, :filing_date]
        e.css("td").each_with_index do |el, j|
          suit_attribute = suit_attributes[j]
          suit[suit_attribute] = el.content
          if suit_attribute == :suit_id
            suit[:link] = BASE_URI + el.css("a")[0]["href"]
          end
        end
        suits << suit
      end
    end
    suits
  end

  def self.post_with_uri(uri, post_data)
    req = Net::HTTP::Post.new(uri)
    req.set_form_data(post_data)
    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
  end

  def self.get_with_uri(path)
    path, query = path.split("?")
    uri = self.get_uri_with_path(path)
    uri.query = URI::encode_www_form(CGI::parse(query))
    Net::HTTP.get_response(uri)
  end

  def self.get_uri_with_path(path)
    URI(BASE_URI + path)
  end
end
