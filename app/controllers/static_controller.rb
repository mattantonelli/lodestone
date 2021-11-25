class StaticController < ApplicationController
  def index
    # Set default categories
    %i(topics maintenance updates developers).each do |category|
      params[category] ||= '1'
    end
  end
end
