@news.each do |category, news|
  json.set! category do
    json.partial! 'post', collection: news, as: :post
  end
end
