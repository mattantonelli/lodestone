env :PATH, ENV['PATH']
set :output, 'log/whenever.log'

every '5,15,25,35,45,55 * * * *' do
  %w(na eu de fr jp).each do |locale|
    rake "news:deliver[#{locale}]"
  end
end
