class Wechat < Base

  class AuthEntity < Grape::Entity
    expose :openid, :token
  end

  class UserEntity < Grape::Entity
    expose :type do |user|
      'user'
    end
    expose :company do |user|
      user.instance.company
    end
    expose :key do |user|
      user.instance.app_key
    end
    expose :id do |user|
      user.instance_user_id
    end
    expose :cid do |user|
      # center id
      user.id
    end
    expose :email
    expose :card, merge: true
  end

  class WechatUserEntity < Grape::Entity
    expose :type do |user|
      'wechat'
    end
    expose :name, :openid, :icon
  end

  class ThreadEntity < Grape::Entity
    expose :id, :category
    expose :subject do |thread|
      case thread.category
      when 'Chat'
        thread.user.name
      else
        thread.subject
      end
    end
    expose :members do |thread|
      thread.thread_users.map do |member|
        case member.user_type
        when 'User'
          UserEntity.represent member.user
        when 'WechatUser'
          WechatUserEntity.represent member.user
        else
          # TODO
        end
      end
    end
  end

  class MessageEntity < Grape::Entity
    expose :id, :content
    expose :threadId do |message|
      message.wechat_thread_id
    end
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
    expose :created_at do |message|
      message.created_at.to_i
    end
  end

  helpers do
    def authenticate_with_token!
      @user = WechatUser.find_by token: params[:token]
      error!('Auth failed', 401) unless @user
    end

    def current_user
      @user
    end
  end

  resource :wechat do
    desc "认证"
    params do
      requires :code, type: String, desc: "微信登录码", documentation: { param_type: 'query' }
      requires :name, type: String, desc: "用户昵称", documentation: { param_type: 'query' }
      optional :icon, type: String, desc: "头像URL", documentation: { param_type: 'query' }
    end
    post 'auth' do
      user = WechatUser.auth params[:code], {
        name: params[:name],
        icon: params[:icon]
      }

      if user
         # TEMP: 默认添加一个用户，并发送第一条消息
        chat = user.get_chat "cf583482629ac68d", "fLyTntRLo38RJsMxf" # net263 - Jenny
        if chat && chat.messages.count == 0
          chat.add_message chat.user, "欢迎使用企业沟通小程序！\n你可以直接在这里发送消息与我沟通，也可以通过扫描名片添加联系人开始沟通。"
        end
        present user, with: AuthEntity
      else
        error!('认证失败', 400)
      end
    end

    desc "获取名片"
    params do
      requires :id,    type: String, desc: "用户ID", documentation: { param_type: 'query' }
      requires :token, type: String, desc: "认证标识", documentation: { param_type: 'query' }
    end
    before do
      authenticate_with_token!
    end
    get 'card' do
      user = User.find_by id: params[:id]

      if user && user.card.present?
        # 添加到通信录
        current_user.add_contact user
        present user, with: UserEntity
      else
        error!('未找到名片信息', 404)
      end
    end

    # desc "获取名片"
    # params do
    #   requires :key,   type: String, desc: "企业标识", documentation: { param_type: 'query' }
    #   requires :id,    type: String, desc: "用户标识", documentation: { param_type: 'query' }
    # end
    # before do
    #   authenticate_with_token!
    # end
    # get 'card' do
    #   user = User.get_card params[:key], params[:id]
    #
    #   if user && user.card.present?
    #     # 添加到通信录
    #     current_user.add_contact user
    #     present user, with: UserEntity
    #   else
    #     error!('未找到名片信息', 404)
    #   end
    # end

    desc "获取话题"
    params do
      requires :key,   type: String, desc: "企业标识", documentation: { param_type: 'query' }
      requires :id,    type: String, desc: "话题标识", documentation: { param_type: 'query' }
      requires :token, type: String, desc: "认证标识", documentation: { param_type: 'query' }
    end
    before do
      authenticate_with_token!
    end
    get 'thread' do
      thread = current_user.get_thread params[:key], params[:id]
      if thread
        # 话题，参与者
        present thread, with: ThreadEntity
      else
        error!('未找到话题', 404)
      end
    end

    desc "发起私聊"
    params do
      requires :key,   type: String, desc: "企业标识", documentation: { param_type: 'query' }
      requires :id,    type: String, desc: "用户标识", documentation: { param_type: 'query' }
      requires :token, type: String, desc: "认证标识", documentation: { param_type: 'query' }
    end
    before do
      authenticate_with_token!
    end
    get 'chat' do
      chat = current_user.get_chat params[:key], params[:id]
      if chat
        present chat, with: ThreadEntity
      else
        error!('未创建私聊', 404)
      end
    end

    desc "获取会话消息"
    params do
      requires :id,    type: String, desc: "会话标识", documentation: { param_type: 'query' }
      optional :time,  type: String, desc: "时间戳", documentation: { param_type: 'query' }
      requires :token, type: String, desc: "认证标识", documentation: { param_type: 'query' }
    end
    before do
      authenticate_with_token!
    end
    get 'messages' do
      thread = WechatThread.find_by id: params[:id]
      if thread
        messages = WechatMessage.where(wechat_thread_id: params[:id]).order(:created_at)
        messages = messages.where("created_at >=?", Time.at(params[:time].to_i)) if params[:time].present?
        present :thread_id, thread.id
        present :messages,  messages, with: MessageEntity
        present :time,      Time.now.to_i
      else
        error!('会话不存在', 404)
      end
    end

    desc "发送消息"
    params do
      requires :id,      type: String, desc: "会话标识", documentation: { param_type: 'query' }
      requires :message, type: String, desc: "消息内容", documentation: { param_type: 'query' }
      requires :token,   type: String, desc: "认证标识", documentation: { param_type: 'query' }
    end
    before do
      authenticate_with_token!
    end
    post 'message' do
      thread = WechatThread.find_by id: params[:id]
      if thread
        message = thread.add_message current_user, params[:message]
        present message, with: MessageEntity
      else
        error!('会话不存在', 404)
      end
    end

    desc "获取通信录"
    params do
      requires :token, type: String, desc: "认证标识", documentation: { param_type: 'query' }
    end
    before do
      authenticate_with_token!
    end
    get 'contacts' do
      contacts = WechatContact.where(wechat_user_id: current_user.id)
      present contacts.collect(&:user), with: UserEntity
    end

    desc "获取会话列表"
    params do
      requires :token, type: String, desc: "认证标识", documentation: { param_type: 'query' }
    end
    before do
      authenticate_with_token!
    end
    get 'threads' do
      threads = WechatThread.joins(:thread_users).where(wechat_thread_users: {user_type: 'WechatUser', user_id: current_user.id})
      present threads, with: ThreadEntity
    end

    desc "获取数据"
    params do
      requires :token, type: String, desc: "认证标识", documentation: { param_type: 'query' }
      optional :time,  type: String, desc: "时间戳", documentation: { param_type: 'query' }
    end
    before do
      authenticate_with_token!
    end
    get 'data' do
      contacts = WechatContact.where(wechat_user_id: current_user.id).order(:created_at)
      threads = WechatThread.joins(:thread_users).where(wechat_thread_users: {user_type: 'WechatUser', user_id: current_user.id}).order("wechat_threads.updated_at")
      messages = WechatMessage.order("wechat_messages.created_at").joins(:thread).where(wechat_threads: {id: threads.collect(&:id)})

      time = params[:time]
      if time.present?
        t = Time.at(time.to_i)
        contacts = contacts.where("created_at >?", t)
        threads = threads.where("wechat_threads.updated_at > ?", t)
        messages = messages.where("wechat_messages.created_at >?", t)
      else
        time = current_user.time
        if time.present?
          t = Time.at(time.to_i)
          messages = messages.where("wechat_messages.created_at >?", t)
        end
      end

      last_time = Time.now.to_i
      current_user.update! time: last_time
      present :users,    contacts.collect(&:user), with: UserEntity
      present :threads,  threads, with: ThreadEntity
      present :messages, messages, with: MessageEntity
      present :time,     last_time
    end
  end
end
