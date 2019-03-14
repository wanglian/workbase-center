class AddStateToInstances < ActiveRecord::Migration[5.0]
  def change
    add_column :instances, :state, :boolean
  end
end
