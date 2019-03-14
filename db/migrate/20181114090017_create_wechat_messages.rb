class CreateWechatMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :wechat_messages do |t|
      t.integer :wechat_thread_id
      t.string  :user_type
      t.integer :user_id
      t.text    :content
      t.timestamps
    end
    
    add_index :wechat_messages, :wechat_thread_id
    add_index :wechat_messages, [:user_type, :user_id]
  end
end
