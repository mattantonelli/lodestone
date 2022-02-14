# == Schema Information
#
# Table name: news
#
#  id          :bigint(8)        not null, primary key
#  uid         :string(255)      not null
#  url         :string(255)      not null
#  title       :string(255)      not null
#  time        :datetime         not null
#  category    :string(255)      not null
#  locale      :string(255)      not null
#  sent        :boolean          default(FALSE)
#  image       :string(255)
#  description :text(65535)
#  start_time  :datetime
#  end_time    :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class News < ApplicationRecord
  validates_presence_of :uid, :url, :title, :time, :category, :locale

  Lodestone.categories.each do |category|
    scope category, -> { where(category: category) }
  end

  Lodestone.locales.each do |locale|
    scope locale, -> { where(locale: locale) }
  end

  scope :latest, -> { order(created_at: :desc).limit(20) }
  scope :sent,   -> { where(sent: true) }
  scope :unsent, -> { where(sent: false) }

  def embed
    link = URI.parse(Lodestone.category(category)['link'])
    link.host = "#{locale}.#{link.host}"

    if start_time.present? || end_time.present?
      text = formatted_duration
    else
      text = description
    end

    {
      author: {
        name: I18n.t("categories.#{category}"),
        url: link,
        icon_url: Lodestone.category(category)['icon']
      },
      title: title,
      description: text,
      url: url,
      color: Lodestone.category(category)['color'],
      thumbnail: {
        url: Lodestone.category(category)['thumbnail']
      },
      image: {
        url: image
      }
    }
  end

  def formatted_duration
    [start_time, end_time].compact.map { |time| "<t:#{time.to_i}>" }.join(' — ')
  end

  def self.metadata(locale:)
    NewsMeta.find_by(locale: locale)
  end
end
