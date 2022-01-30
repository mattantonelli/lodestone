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
    news = News.unsent.where(locale: locale, category: category)

    begin
      if news.present?
        puts "Delivering #{news.count} new posts to #{locale.upcase} #{category.capitalize}"

        # Send up to 10 embeds per execution to reduce requests
        news.map(&:embed).each_slice(10).each do |embeds|
          Webhook.where(locale: locale, category => true).shuffle.each do |webhook|
            webhook.send_embeds(embeds)
          end
        end

        puts "Delivery complete for #{locale.upcase} #{category.capitalize}"
      end
    rescue
      puts "Delivery failed\n#{e.inspect}"
    ensure
      # Always mark the news as sent regardless of status to avoid infinitely sending
      # duplicate posts in the event of an error
      news.update_all(sent: true)
    end
  end
end
