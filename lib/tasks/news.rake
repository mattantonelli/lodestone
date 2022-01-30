namespace :news do
  desc 'Deliver the latest news to subscribed webhooks. (All categories are delivered by default.)'
  task :deliver, [:locale, :category] => [:environment] do |_, args|
    locale, category = args.values_at(:locale, :category)
    break abort('You must provide a locale.') unless locale.present?

    if category.present?
      deliver(locale: locale, category: category)
    else
      Lodestone.categories.each do |cat|
        deliver(locale: locale, category: cat)
      end
    end
  end

  private
  def deliver(locale:, category:)
    # Fetch the latest news from the Lodestone
    begin
      Lodestone.fetch(locale: locale, category: category)
    rescue OpenURI::HTTPError => e
      return log("Error contacting the Lodestone: #{e.to_s}")
    rescue RuntimeError => e
      # Lodestone is undergoing maintenance which results in a redirect
      return log("Error contacting the Lodestone: #{e.to_s}")
    rescue Exception => e
      log("Fatal error fetching news: #{e.to_s}")
      e.backtrace.first(5) { |line| log(line) }
      return
    end

    # Retrieve any unsent posts
    news = News.unsent.where(locale: locale, category: category)

    # And deliver them
    begin
      if news.present?
        log("Found #{news.count} new posts for #{locale.upcase} #{category.capitalize}")

        # Send up to 10 embeds per execution to reduce requests
        news.map(&:embed).each_slice(10).each do |embeds|
          Webhook.where(locale: locale, category => true).shuffle.each do |webhook|
            webhook.send_embeds(embeds)
          end
        end

        log("Delivery complete for #{locale.upcase} #{category.capitalize}")
      end
    rescue Exception => e
      log("Delivery failed for #{locale.upcase} #{category.capitalize}\n#{e.to_s}")
      e.backtrace.first(5) { |line| log(line) }
    ensure
      # Always mark the news as sent regardless of status to avoid infinitely sending
      # duplicate posts in the event of an error
      news.update_all(sent: true)
    end
  end

  def log(message)
    puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')}] #{message}"
  end
end
