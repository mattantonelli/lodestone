class CreateNewsMeta < ActiveRecord::Migration[6.1]
  def change
    create_table :news_meta do |t|
      t.string :locale
      t.datetime :modified_at
      t.datetime :expires_at
    end

    add_index :news_meta, :locale

    Lodestone.locales.each do |locale|
      NewsMeta.create!(locale: locale, modified_at: Time.at(0), expires_at: Time.at(0))
    end
  end
end
