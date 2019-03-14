# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181128151818) do

  create_table "admins", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "instances", force: :cascade do |t|
    t.string   "company"
    t.string   "server_url"
    t.string   "app_key"
    t.string   "app_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean  "state"
    t.index ["app_key"], name: "index_instances_on_app_key"
  end

  create_table "users", force: :cascade do |t|
    t.integer  "instance_id"
    t.string   "email"
    t.string   "instance_user_id"
    t.string   "imid"
    t.text     "card"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.text     "qrcode"
    t.index ["email"], name: "index_users_on_email"
    t.index ["instance_id"], name: "index_users_on_instance_id"
  end

  create_table "wechat_contacts", force: :cascade do |t|
    t.integer  "wechat_user_id"
    t.string   "user_type"
    t.integer  "user_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["user_type", "user_id"], name: "index_wechat_contacts_on_user_type_and_user_id"
    t.index ["wechat_user_id"], name: "index_wechat_contacts_on_wechat_user_id"
  end

  create_table "wechat_messages", force: :cascade do |t|
    t.integer  "wechat_thread_id"
    t.string   "user_type"
    t.integer  "user_id"
    t.text     "content"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["user_type", "user_id"], name: "index_wechat_messages_on_user_type_and_user_id"
    t.index ["wechat_thread_id"], name: "index_wechat_messages_on_wechat_thread_id"
  end

  create_table "wechat_thread_users", force: :cascade do |t|
    t.integer  "wechat_thread_id"
    t.string   "user_type"
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["user_type", "user_id"], name: "index_wechat_thread_users_on_user_type_and_user_id"
    t.index ["wechat_thread_id"], name: "index_wechat_thread_users_on_wechat_thread_id"
  end

  create_table "wechat_threads", force: :cascade do |t|
    t.string   "instance_key"
    t.string   "category"
    t.string   "instance_thread_id"
    t.string   "wechat_openid"
    t.string   "subject"
    t.integer  "last_message_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["instance_key"], name: "index_wechat_threads_on_instance_key"
    t.index ["instance_thread_id"], name: "index_wechat_threads_on_instance_thread_id"
    t.index ["wechat_openid"], name: "index_wechat_threads_on_wechat_openid"
  end

  create_table "wechat_users", force: :cascade do |t|
    t.string   "openid"
    t.string   "name"
    t.string   "icon"
    t.string   "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "time"
    t.index ["openid"], name: "index_wechat_users_on_openid"
    t.index ["token"], name: "index_wechat_users_on_token"
  end

end
