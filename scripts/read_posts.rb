require_relative './get_post'

require 'active_support/inflector'
require 'date'
require 'json'
require 'open-uri'
require 'nokogiri'
require 'reverse_markdown'

BASE_URL = "http://www.folklore.org/"

class PageContent
  attr_accessor :title, :href, :content
  def initialize(post)
    self.title = post.first
    self.href  = post.last
  end

  def doc
    @_doc ||= Nokogiri::HTML(open(BASE_URL+href))
  end

  def metadata
    unless @_metadata
      @_metadata = {}
      values = self.doc.css("span.story-view-value").map { |l| l.text }
      %w(author date characters topic summary).each_with_index do |item, index|
        if [2,3].include?(index)
          @_metadata[item] = values[index].squeeze(" ").split(", ")
        else
          @_metadata[item] = values[index]
        end
      end
      @_metadata
    else
      @_metadata
    end
  end

  def metadata_as_yaml
    unless @_metadata_as_yaml
      @_metadata_as_yaml = ""
      metadata.each do |k,v|
        k = "setting" if k == "date"
        if v.is_a? String
          @_metadata_as_yaml += "#{k}: #{v}\n"
        elsif v.is_a? Array
          @_metadata_as_yaml += "#{k}: #{v.join(', ')}\n"
        end
      end
      @_metadata_as_yaml += "title: #{self.title}\n"
      @_metadata_as_yaml += "layout: post\n"
      @_metadata_as_yaml
    else
      @_metadata_as_yaml
    end
  end

  def post_html
    self.doc.css("div.story-main-content")
  end

  def post_md
    @_post_md = ReverseMarkdown.convert(post_html.to_s)
    clean(@_post_md)
  end

  def content
    "---\n#{metadata_as_yaml}\n---\n\n#{post_md}"
  end

  def clean(md)
    links = md.scan(/\[.*\]\((StoryView.py\?project=.*\&story=(.*).txt)\)/)
    links.each do |orig, new|
      md.gsub!(orig, "/" + new.parameterize.gsub("_","-"))
    end

    md
  end
end

filename = ARGV.first
raise ArgumentError, "Missing JSON" unless filename

posts = JSON.parse(IO.read(filename))
pages = []

posts.each do |post|
  post_hash = post.first
  pages << PageContent.new(post_hash)
end

pages.each do |page|
  File.open("_posts/#{Date.today.strftime}-#{page.title.parameterize}.md", "w+") do |file|
    file.write(page.content)
  end
end
