namespace :news do
  desc 'Deliver the latest news to subscribed webhooks.'
  task :deliver, [:locale] => [:environment] do |_, args|
    locale = args[:locale]
    break abort('You must provide a locale.') unless locale.present?

    # Update the metadata with the current fetch time so we can set the proper API cache headers
    News.metadata(locale: locale).update(modified_at: Time.now.beginning_of_minute)

    # Fetch the latest news from the Lodestone
    begin
      Lodestone.fetch_all(locale: locale)
    rescue OpenURI::HTTPError => e
      abort log("Error contacting the Lodestone: #{e.to_s}")
    rescue RuntimeError => e
      # Lodestone is undergoing maintenance which results in a redirect
      abort log("Error contacting the Lodestone: #{e.to_s}")
    rescue StandardError => e
      log("Fatal error fetching news: #{e.to_s}")
      e.backtrace.first(5) { |line| log(line) }
      abort
    end

    # Retrieve any unsent posts and deliver them
    begin
      news = News.unsent.where(locale: locale).ordered

      # Always mark the news as sent regardless of status to avoid infinitely sending
      # duplicate posts in the event of an error. Update posts individually to avoid
      # modifying the Relation.
      news.each { |post| post.update(sent: true) }

      news.group_by(&:category).each do |category, news|
        log("Found #{news.count} new posts for #{locale.upcase} #{category.capitalize} (#{news.pluck(:uid).join(', ')})")

        # Send up to 10 embeds per execution to reduce requests
        news.map(&:embed).each_slice(10).each do |embeds|
          # Collect the webhooks where the news should be sent. Shuffle them for fairness, and take them in
          # slices so we can multithread them for faster execution. Each webhook has its own rate limit.
          Webhook.where(locale: locale, category => true).shuffle.each_slice(40) do |webhooks|
            threads = webhooks.map do |webhook|
              Thread.new do
                begin
                  webhook.send_embeds(embeds)
                rescue JSON::ParserError
                  log("Missed a delivery for #{locale.upcase} #{category.capitalize}. Discord server error.")
                rescue ArgumentError => e
                  log("Missed a delivery for #{locale.upcase} #{category.capitalize}. #{e.message}")
                rescue StandardError => e
                  log("Missed a delivery for #{locale.upcase} #{category.capitalize}")
                  log_exception(e)
                end
              end
            end

            # Wait for all of the threads before proceeding to the next slice
            threads.map(&:join)
          end
        end

        log("Delivery complete for #{locale.upcase} #{category.capitalize}")
      end
    rescue StandardError => e
      log("Delivery failed for #{locale.upcase} #{try(:category)&.capitalize}")
      log_exception(e)
    end
  end

  desc 'Cache the news for a given locale and optional category without delivering it.'
  task :cache, [:locale, :category, :pages] => [:environment] do |_, args|
    locale, category, pages = args.values_at(:locale, :category, :pages)
    break abort('You must provide a locale.') unless locale.present?

    # Cache the first page of posts by default
    # NOTE: This argument does not apply to the Developers' Blog
    pages ||= 1

    # If a category was provided, only fetch that one. Otherwise, fetch all categories.
    if category.present?
      categories = [category]
    else
      categories = Lodestone.categories
    end

    # Fetch the posts for each category and mark them as "sent"
    categories.each do |cat|
      posts = (1..pages.to_i).flat_map do |page|
        Lodestone.fetch_category(category: cat, locale: locale, page: page)
      end

      posts.each { |post| post.update!(sent: true) }
      puts "Cached #{posts.size} #{locale.upcase} #{cat.capitalize} posts"
    end

    # Update the metadata with the current fetch time so we can set the proper API cache headers
    News.metadata(locale: locale).update(modified_at: Time.now.beginning_of_minute)
  end

  desc 'Reset the news metadata cache'
  task reset_cache: :environment do
    Lodestone.locales.each do |locale|
      if meta = NewsMeta.find_by(locale: locale)
        meta.update!(modified_at: Time.now, expires_at: Time.now)
      else
        NewsMeta.create!(locale: locale, modified_at: Time.now, expires_at: Time.now)
      end
    end
  end

  def log(message)
    puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')}] #{message}"
  end

  def log_exception(exception)
    log(exception.inspect)
    exception.backtrace.first(5).each { |line| log(line) }
  end
end
