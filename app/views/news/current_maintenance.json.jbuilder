@maintenance.each do |type, news|
  json.set! type do
    json.partial! 'post', collection: news, as: :post
  end
end
