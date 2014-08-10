require 'json'
require 'nokogiri'
require 'open-uri'

BASE_URL = "http://www.folklore.org/"

doc = Nokogiri::HTML(open(BASE_URL + "index.py"))

pages = doc.css('div.index-bar a span.index-bar-item').map { |l| l.text.to_i }
max_index = (pages.uniq.sort.last - 1)

posts = []

(0..max_index).each do |num|
  index = num * 10
  page = Nokogiri::HTML(open(BASE_URL + "ProjectView.py?project=Macintosh&index=#{index}"))
  page.css('div.story-index-entry div a').each do |link|
    unless link['href'].include?("comments")
      posts << {link.text.strip => link['href'].gsub("&sortOrder=Sort+by+Date", "") }
    end
  end
end

File.write("posts.json", posts.to_json)
