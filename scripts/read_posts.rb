require_relative './get_post'

require 'json'

filename = ARGV.first
raise ArgumentError, "Missing JSON" unless filename

posts = JSON.parse(IO.read(filename))

posts.each do |post|
  post_hash = post.first
  title = post_hash.first
  href  = post_hash.last

  puts href
end
