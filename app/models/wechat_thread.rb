class WechatThread < ApplicationRecord
  has_many :thread_users, class_name: 'WechatThreadUser', foreign_key: 'wechat_thread_id'
  has_many :messages, class_name: 'WechatMessage', foreign_key: 'wechat_thread_id'
  validates :instance_thread_id, presence: :true
  validates :category, presence: :true
  validates :instance_key, presence: :true

  def add_member(user)
    self.thread_users.find_or_create_by user: user
  end

  def add_message(user, content)
    self.messages.create content: content, user: user
  end

  def user
    case self.category
    when 'Chat'
      # 私聊：企业用户
      User.find_by instance_user_id: self.instance_thread_id
    else
      # 空
    end
  end

end
