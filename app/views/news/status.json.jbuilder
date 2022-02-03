json.array!(@news) do |post|
  json.id post.uid
  json.(post, :url, :title, :time)
end
