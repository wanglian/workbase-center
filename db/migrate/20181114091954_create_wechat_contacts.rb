class CreateWechatContacts < ActiveRecord::Migration[5.0]
  def change
    create_table :wechat_contacts do |t|
      t.integer :wechat_user_id
      t.string  :user_type
      t.integer :user_id
      t.timestamps
    end
    
    add_index :wechat_contacts, :wechat_user_id
    add_index :wechat_contacts, [:user_type, :user_id]
  end
end
