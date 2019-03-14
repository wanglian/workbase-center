class Instance < ApplicationRecord
  has_many :users
  
  validates :company, presence: :true
  validates :server_url, presence: :true
  
  before_create :init_secret_key
  
  def base_url
    self.server_url + "/center/v1"
  end

  def query_user_url(id)
    base_url + "/rosters/" + id
  end

  def query_user(id)
    response = RestClient.get self.query_user_url(id)
    if response.code == 200
      return JSON.parse(response.body)
    end
    false
  rescue
    false
  end

  def query_thread_url(id)
    base_url + "/threads/" + id
  end

  def query_thread(id)
    response = RestClient.get self.query_thread_url(id)
    if response.code == 200
      return JSON.parse(response.body)
    end
  rescue
    false
  end

  def add_thread_member_url(id)
    base_url + "/threads/" + id + "/members"
  end

  def send_join_thread(thread_id, wechat_user)
    params = {
      wechat: {
        name: wechat_user.name,
        openId: wechat_user.openid
      }
    }
    response = RestClient.post self.add_thread_member_url(thread_id), params
    if response.code == 200
      return true
    end
  rescue
    false
  end

  def messages_url
    base_url + "/messages"
  end

  def send_message(message)
    thread = message.thread
    wechat_user = message.user
    params = {
      type: thread.category,
      id: thread.instance_thread_id,
      message: {
        content: message.content
      },
      wechat: {
        name:   wechat_user.name,
        openId: wechat_user.openid,
        avatar: wechat_user.icon
      }
    }

    response = RestClient.post self.messages_url, params
    logger.debug response
  rescue => e
    logger.debug e
  end

  private
  def init_secret_key
    self.app_key = SecureRandom.hex 8
    self.app_secret = Digest::SHA1.hexdigest("#{Time.now.to_i}")
  end
end
