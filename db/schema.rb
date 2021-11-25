# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_11_25_150352) do

  create_table "webhooks", charset: "utf8", force: :cascade do |t|
    t.string "url"
    t.string "locale"
    t.boolean "topics"
    t.boolean "notices"
    t.boolean "maintenance"
    t.boolean "updates"
    t.boolean "status"
    t.boolean "developers"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["developers"], name: "index_webhooks_on_developers"
    t.index ["locale"], name: "index_webhooks_on_locale"
    t.index ["maintenance"], name: "index_webhooks_on_maintenance"
    t.index ["notices"], name: "index_webhooks_on_notices"
    t.index ["status"], name: "index_webhooks_on_status"
    t.index ["topics"], name: "index_webhooks_on_topics"
    t.index ["updates"], name: "index_webhooks_on_updates"
  end

end
