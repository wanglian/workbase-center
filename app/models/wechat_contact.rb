class WechatContact < ApplicationRecord
  belongs_to :wechat_user
  belongs_to :user, polymorphic: true
end
