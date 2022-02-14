# == Schema Information
#
# Table name: news_meta
#
#  id          :bigint(8)        not null, primary key
#  locale      :string(255)
#  modified_at :datetime
#  expires_at  :datetime
#
class NewsMeta < ApplicationRecord
  # The latest news is fetched every 10 minutes
  MAX_AGE = 600.freeze

  before_save :set_expires_at

  def max_age
    (expires_at - Time.now).to_i
  end

  private
  def set_expires_at
    self.expires_at = modified_at + MAX_AGE
  end
end
