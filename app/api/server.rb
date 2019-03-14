class Server < Base

  class ThreadEntity < Grape::Entity
    expose :id do |thread|
      thread.instance_thread_id
    end
    expose :subject     
  end

  class UserEntity < Grape::Entity
    expose :user_id do |user|
      user.instance_user_id
    end
    expose :card
  end

  class WechatUserEntity < Grape::Entity
    expose :openid
  end

  class MessageEntity < Grape::Entity
    expose :id, :content
    expose :user_id do |message|
      case message.user_type
      when 'User'
        message.user.instance_user_id
      when 'WechatUser'
        message.user.openid
      else
        message.user.id
      end
    end
    expose :user_type do |message|
      case message.user_type
      when 'User'
        "user"
      when 'WechatUser'
        "wechat"
      else
        "Unsupported" # TODO
      end
    end
  end

  class InstanceEntity < Grape::Entity
    expose :app_key, :app_secret
  end

  HEADERS = {
    'Appkey' => {
      'description' => '平台开通实例key',
      'type' => 'string'
    },
    'Curtime' => {
      'description' => '当前服务器时间戳',
      'type' => 'string'
    },
    'Checksum' => {
      'description' => '加密 SHA1(AppSecret + Appkey + CurTime)',
      'type' => 'string'
    },
  }
  helpers do
    def authenticate_instance!
      app_key    = headers['Appkey']
      cur_time   = headers['Curtime']
      check_sum  = headers['Checksum']
      front_time = Time.now.to_i - 15
      last_time  = Time.now.to_i + 15
      if (cur_time.to_i >= front_time) && (cur_time.to_i <= last_time)
        @instance = Instance.find_by app_key: app_key
        return if @instance && check_auth(@instance, cur_time, check_sum)
      end
      error!('auth fail', 401)
    end

    def check_auth(instance, cur_time, check_sum)
      Digest::SHA1.hexdigest("#{instance.app_secret}#{instance.app_key}#{cur_time}") == check_sum
    end

    def current_instance
      @instance
    end
  end

  resource :servers do
    before { authenticate_instance! }
    desc "接受server推送消息", headers: HEADERS
    params do
      requires :category,  type: String, desc: "会话类型", documentation: { param_type: 'query' } # Chat/Group
      requires :user_id,   type: String, desc: "用户标识", documentation: { param_type: 'query' }
      optional :openid,    type: String, desc: "微信用户标识", documentation: { param_type: 'query' }
      optional :thread_id, type: String, desc: "话题标识", documentation: { param_type: 'query' }
      requires :content,   type: String, desc: "消息内容", documentation: { param_type: 'query' }
      optional :type,      type: String, desc: "消息类型", documentation: { param_type: 'query' }
    end
    post 'message' do
      status 200
      user = User.find_by instance_user_id: params[:user_id]
      message = case params[:category]
      when 'Chat'
        wechat_user = WechatUser.find_by openid: params[:openid]
        chat = wechat_user.get_chat current_instance.app_key, params[:user_id]
        chat.add_message user, params[:content]
      when 'Group'
        thread = WechatThread.find_by instance_thread_id: params[:thread_id]
        if thread
          thread.add_message user, params[:content]
        end
      end
      MessageEntity.represent message
    end

    desc "接受server推送用户", headers: HEADERS
    params do
      requires :id,     type: String, desc: "用户标识", documentation: { param_type: 'query' }
      optional :email,  type: String, desc: "Email", documentation: { param_type: 'query' }
      optional :name,   type: String, desc: "姓名", documentation: { param_type: 'query' }
      optional :title,  type: String, desc: "职位", documentation: { param_type: 'query' }
      optional :mobile, type: String, desc: "手机", documentation: { param_type: 'query' }
      optional :icon,   type: String, desc: "头像", documentation: { param_type: 'query' }
    end
    post 'user' do
      status 200
      user = User.find_or_create_by instance_user_id: params[:id], instance_id: current_instance.id
      user.email  = params[:email] if params[:email].present?
      user.name   = params[:name]
      user.title  = params[:title]
      user.mobile = params[:mobile]
      user.icon   = params[:icon]
      user.save!
      UserEntity.represent user
    end

    desc "修改话题主题", headers: HEADERS
    params do
      requires :id,      type: String, desc: "话题标识", documentation: { param_type: 'query' }
      requires :subject, type: String, desc: "主题", documentation: { param_type: 'query' }
    end
    post 'thread' do
      status 200
      thread = WechatThread.find_by instance_thread_id: params[:id], instance_key: current_instance.app_key
      if thread
        thread.update! subject: params[:subject]
        ThreadEntity.represent thread
      else
        error!('话题不存在', 404)
      end
    end
  end

end