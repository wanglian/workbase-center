class CreateInstances < ActiveRecord::Migration[5.0]
  def change
    create_table :instances do |t|
      t.string :company # 企业名称
      t.string :server_url # http(s)://xxx.com
      t.string :app_key # 企业标识
      t.string :app_secret

      t.timestamps
    end
    
    add_index :instances, :app_key
  end
end
