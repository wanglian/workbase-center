class WechatThreadUser < ApplicationRecord
  belongs_to :user, polymorphic: true
end
