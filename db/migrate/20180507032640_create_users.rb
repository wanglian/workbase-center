class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    # 企业用户
    create_table :users do |t|
      t.integer :instance_id
      t.string :email
      t.string :instance_user_id # 用户标识
      t.string :imid
      t.text   :card # 名片信息
      t.timestamps
    end
    
    add_index :users, :instance_id
    add_index :users, :email
  end
end
