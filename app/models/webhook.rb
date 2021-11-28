# == Schema Information
#
# Table name: webhooks
#
#  id          :bigint(8)        not null, primary key
#  url         :string(255)      not null
#  locale      :string(255)      not null
#  topics      :boolean
#  notices     :boolean
#  maintenance :boolean
#  updates     :boolean
#  status      :boolean
#  developers  :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Webhook < ApplicationRecord
  validates_presence_of :url, :locale
end
