class CreateNews < ActiveRecord::Migration[6.1]
  def change
    create_table :news do |t|
      t.string :uid, null: false
      t.string :url, null: false
      t.string :title, null: false
      t.datetime :time, null: false
      t.string :locale, null: false
      t.string :category, null: false
      t.boolean :sent, default: false
      t.string :image
      t.text :description
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end
    add_index :news, :uid, unique: true
    add_index :news, :category
    add_index :news, :locale
    add_index :news, :sent
    add_index :news, :created_at
  end
end
