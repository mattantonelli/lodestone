env :PATH, ENV['PATH']
set :output, '/var/log/lodestone.log'

# TODO: Switch back to the %5 schedule when we are ready to go live
# every '5,15,25,35,45,55 * * * *' do
every '0,10,20,30,40,50 * * * *' do
  %w(na eu de fr jp).each do |locale|
    rake "news:deliver[#{locale}]"
  end
end
