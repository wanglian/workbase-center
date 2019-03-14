class User < ApplicationRecord
  belongs_to :instance
  store :card, accessors: [:name, :title, :mobile, :icon], coder: JSON
  validates :email, presence: :true

  def self.get_card(key, id)
    instance = Instance.find_by app_key: key
    user = self.find_by instance_user_id: id, instance_id: instance.id

    if user.blank? || user.card.blank?
      result = instance.query_user id
      if result
        user = User.find_or_create_by instance_user_id: id, instance_id: instance.id
        user.email = result["email"]
        user.name  = result["name"]
        user.mobile  = result["mobile"]
        user.title  = result["title"]
        user.icon = result["icon"]
        user.save
      end
    end

    user
  end

  def get_qrcode
    unless self.qrcode
      qrcode = WechatClient.get_qrcode "pages/chat", "userId=#{self.id}"
      if qrcode
        self.qrcode = qrcode
        self.save!
      end
    end
    self.qrcode
  end
end
