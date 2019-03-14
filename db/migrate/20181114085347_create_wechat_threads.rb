class CreateWechatThreads < ActiveRecord::Migration[5.0]
  def change
    create_table :wechat_threads do |t|
      t.string :instance_key # 企业标识
      t.string :category # Chat/Group
      t.string :instance_thread_id # Server标识（话题标识，用户标识）
      t.string :wechat_openid # 方便私聊查询
      t.string :subject
      t.integer :last_message_id
      t.timestamps
    end
    
    add_index :wechat_threads, :instance_key
    add_index :wechat_threads, :instance_thread_id
    add_index :wechat_threads, :wechat_openid
  end
end
