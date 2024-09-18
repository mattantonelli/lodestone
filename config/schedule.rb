env :PATH, ENV['PATH']
set :output, 'log/whenever.log'

every '5,15,25,35,45,55 * * * *' do
  rake 'news:deliver_all'
end
