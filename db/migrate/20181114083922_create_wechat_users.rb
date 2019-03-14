class CreateWechatUsers < ActiveRecord::Migration[5.0]
  def change
    # 微信用户
    create_table :wechat_users do |t|
      t.string :openid # 微信标识
      t.string :name # 默认为微信昵称
      t.string :icon # 用户头像url
      t.string :token # 小程序认证
      t.timestamps
    end
    
    add_index :wechat_users, :openid
    add_index :wechat_users, :token
  end
end
