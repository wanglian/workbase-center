class WechatUser < ApplicationRecord
  has_many :contacts, class_name: 'WechatContact'
  validates :name, presence: :true
  validates :openid, presence: :true

  def self.auth(code, user_info={})
    openid = WechatClient.auth code
    if openid
      user = WechatUser.find_or_create_by openid: openid
      user.name = user_info[:name]
      user.icon = user_info[:icon]
      user.token = SecureRandom.hex
      user.save!

      return user
    end
    false
  end

  def add_contact(user)
    self.contacts.find_or_create_by user: user
  end

  def get_thread(key, id)
    thread = WechatThread.find_by instance_key: key, instance_thread_id: id
    instance = Instance.find_by app_key: key
    if instance && thread.blank?
      result = instance.query_thread id
      if result
        thread = WechatThread.create(
          instance_key:       key,
          category:           result["category"],
          instance_thread_id: result["id"],
          subject:            result["subject"]
        )

        result["members"].each do |member|
          # 区分用户类型：企业用户，外部企业用户，外部Email用户，微信用户
          # find_or_create user
          user = case member["type"]
          when "user"
            u = User.find_or_create_by(
              instance_id: instance.id,
              instance_user_id: member["id"],
            )
            u.card = {
              name:   member["name"],
              icon:   member["avatar"],
              mobile: member["mobile"],
            }
            u.email = member["email"]
            u.save
            u
          when "wechat"
            WechatUser.find_or_create_by openid: member["openid"]
          when "email"
            # TODO
          end
          thread.add_member(user) if user
        end

        thread.add_member self
      end
    end

    if thread && instance
      instance.send_join_thread thread.instance_thread_id, self
    end

    thread
  end

  def get_chat(key, id)
    user = User.find_by instance_user_id: id
    if user
      thread = WechatThread.find_or_create_by instance_key: key, category: 'Chat', wechat_openid: self.openid, instance_thread_id: id
      thread.add_member self
      thread.add_member user
      self.add_contact user
      thread
    else
      nil
    end
  end
end
