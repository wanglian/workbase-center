class WechatMessage < ApplicationRecord
  belongs_to :thread, class_name: "WechatThread", foreign_key: 'wechat_thread_id'
  belongs_to :user, polymorphic: true

  after_create :push_to_server

  private
  def push_to_server
    # 推送发自微信的消息
    if self.user_type == 'WechatUser'
      instance = Instance.find_by app_key: self.thread.instance_key
      instance.send_message self
    end
  end
end
