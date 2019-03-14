class CreateWechatThreadUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :wechat_thread_users do |t|
      t.integer :wechat_thread_id
      t.string  :user_type
      t.integer :user_id
      t.timestamps
    end
    
    add_index :wechat_thread_users, :wechat_thread_id
    add_index :wechat_thread_users, [:user_type, :user_id]
  end
end
