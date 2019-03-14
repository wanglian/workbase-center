class AddQrCodeToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :qrcode, :text
  end
end
