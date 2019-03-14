class AddTimeToWechatUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :wechat_users, :time, :string
  end
end
