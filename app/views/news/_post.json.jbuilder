json.id post.uid
json.(post, :url, :title)
json.time post.time&.iso8601

if post.category == 'topics'
  json.(post, :image, :description)
end

if post.category == 'maintenance'
  json.start post.start_time&.iso8601
  json.end post.end_time&.iso8601
end

if post.category == 'developers'
  json.description post.description
end

# Display the post category for /feed
if @include_category
  json.category post.category
end

# Display current maintenance flag for /maintenance/current
if @include_current
  json.current post.start_time <= Time.now
end
