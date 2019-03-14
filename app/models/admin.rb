class Admin < ApplicationRecord
  has_many :instances
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

end
