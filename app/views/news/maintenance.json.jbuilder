json.array!(@news) do |post|
  json.id post.uid
  json.(post, :url, :title, :time)
  json.start post.start_time
  json.end post.end_time
end
