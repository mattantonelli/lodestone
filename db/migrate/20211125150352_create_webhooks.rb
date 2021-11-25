class CreateWebhooks < ActiveRecord::Migration[6.1]
  def change
    create_table :webhooks do |t|
      t.string :url
      t.string :locale
      t.boolean :topics
      t.boolean :notices
      t.boolean :maintenance
      t.boolean :updates
      t.boolean :status
      t.boolean :developers

      t.timestamps
    end
    add_index :webhooks, :locale
    add_index :webhooks, :topics
    add_index :webhooks, :notices
    add_index :webhooks, :maintenance
    add_index :webhooks, :updates
    add_index :webhooks, :status
    add_index :webhooks, :developers
  end
end
