require 'rails_helper'

RSpec.describe "小程序接口", :type => :request do

  describe '认证' do
    before(:each) do
      @code   = "test"
      @name   = 'test1'
      @openid = "openid"
      @url    = WechatClient.auth_url(@code)
    end

    it '成功' do
      stub_request(:get, @url).to_return(status: 200, body: {openid: @openid, errcode: 0}.to_json)

      post '/api/wechat/auth', params: {code: @code, name: @name}

      expect(response).to have_http_status(:success)
      result = JSON.parse response.body
      expect(result["openid"]).to eq @openid
      user = WechatUser.find_by openid: @openid
      expect(result["token"]).to eq user.token
    end

    it '失败' do
      stub_request(:get, @url).to_return(status: 200, body: {errcode: 1}.to_json)

      post '/api/wechat/auth', params: {code: @code, name: @name}

      expect(response).to have_http_status(400)
    end
  end

  describe '获取名片' do
    let!(:instance)    { create :instance }
    let!(:wechat_user) { create :wechat_user }

    it '认证失败' do
      get '/api/wechat/card', params: {id: "test", token: "unauthorized"}

      expect(response).to have_http_status(401)
    end

    it '成功' do
      user = create :user, instance: instance, name: 'test user'

      get '/api/wechat/card', params: {id: user.id, token: wechat_user.token}

      expect(response).to have_http_status(:success)
      result = JSON.parse response.body
      expect(result["id"]).to eq(user.instance_user_id)
      expect(result["cid"]).to eq(user.id)
      expect(result["type"]).to eq('user')
      expect(result["key"]).to eq(instance.app_key)
      expect(result["email"]).to eq(user.email)
      expect(result["name"]).to eq(user.name)
      contact = WechatContact.first
      expect(contact.wechat_user_id).to eq(wechat_user.id)
      expect(contact.user_type).to eq('User')
      expect(contact.user_id).to eq(user.id)
    end

    it '失败' do
      get '/api/wechat/card', params: {id: "test", token: wechat_user.token}

      expect(response).to have_http_status(404)
    end
  end

  describe '发起私聊' do
    let!(:instance)    { create :instance }
    let!(:wechat_user) { create :wechat_user }

    it '成功' do
      # 前提：企业用户已创建
      user = create :user, instance: instance, card: {name: 'test'}

      get '/api/wechat/chat', params: {key: instance.app_key, id: user.instance_user_id, token: wechat_user.token}

      expect(response).to have_http_status(:success)
      result = JSON.parse response.body
      expect(result["id"]).not_to be_nil
      expect(result["subject"]).to eq(user.name)
      expect(result["category"]).to eq('Chat')
      expect(result["members"].count).to eq(2)
    end

    it '企业用户不存在' do
      user = build :user, instance: instance, card: {name: 'test'}

      get '/api/wechat/chat', params: {key: instance.app_key, id: user.instance_user_id, token: wechat_user.token}

      expect(response).to have_http_status(404)
    end
  end

  describe '获取会话消息' do
    let!(:instance)    { create :instance }
    let!(:wechat_user) { create :wechat_user }
    let!(:thread)      { create :wechat_thread, instance_key: instance.app_key }
    let!(:user)        { create :user, instance: instance }
    let!(:message)     { create :wechat_message, thread: thread, user: user }

    it '不带时间戳' do
      get '/api/wechat/messages', params: {id: thread.id, token: wechat_user.token}

      expect(response).to have_http_status(:success)
      result = JSON.parse response.body
      expect(result["thread_id"]).to eq(thread.id)
      expect(result["messages"].count).to eq(1)
      m = result["messages"][0]
      expect(m["id"]).to eq(message.id)
      expect(m["user_type"]).to eq("user")
      expect(m["user_id"]).to eq(user.instance_user_id)
      expect(m["content"]).to eq(message.content)
    end

    it '带时间戳' do
      create :wechat_message, {thread: thread, user: user, created_at: 10.minutes.ago}

      get '/api/wechat/messages', params: {id: thread.id, token: wechat_user.token, time: 5.minutes.ago.to_i}

      expect(response).to have_http_status(:success)
      result = JSON.parse response.body
      expect(result["thread_id"]).to eq(thread.id)
      expect(result["messages"].count).to eq(1)
    end

    it '话题不存在' do
      get '/api/wechat/messages', params: {id: "noid", token: wechat_user.token}

      expect(response).to have_http_status(404)
    end
  end

  describe '发送消息' do
    let!(:instance)    { create :instance }
    let!(:wechat_user) { create :wechat_user }
    let!(:user)        { create :user, instance: instance }

    it '发私聊消息' do
      chat = wechat_user.get_chat instance.app_key, user.instance_user_id
      content = "test"
      messages_url = instance.messages_url
      stub_request(:post, messages_url).to_return(status: 200)

      post '/api/wechat/message', params: {id: chat.id, message: content, token: wechat_user.token}

      expect(response).to have_http_status(:success)
      result = JSON.parse response.body
      expect(result["id"]).not_to be_nil
      expect(result["created_at"]).not_to be_nil
      expect(result["content"]).to eq(content)
      expect(result["user_type"]).to eq("wechat")
      expect(result["user_id"]).to eq(wechat_user.openid)
    end

    it '发话题消息' do
      thread = create :wechat_thread, instance_key: instance.app_key
      thread.thread_users.create user: wechat_user
      thread.thread_users.create user: user
      content = "test"
      messages_url = instance.messages_url
      stub_request(:post, messages_url).to_return(status: 200)

      post '/api/wechat/message', params: {id: thread.id, message: content, token: wechat_user.token}

      expect(response).to have_http_status(:success)
      result = JSON.parse response.body
      expect(result["id"]).not_to be_nil
      expect(result["created_at"]).not_to be_nil
      expect(result["content"]).to eq(content)
      expect(result["user_type"]).to eq("wechat")
      expect(result["user_id"]).to eq(wechat_user.openid)
    end

    it '会话不存在' do
      post '/api/wechat/message', params: {id: 'noio', message: "test", token: wechat_user.token}
      expect(response).to have_http_status(404)
    end
  end

  describe '获取通信录' do
    let!(:instance)    { create :instance }
    let!(:wechat_user) { create :wechat_user }
    let!(:user)        { create :user, instance: instance }

    it '空' do
      get '/api/wechat/contacts', params: {token: wechat_user.token}

      expect(response).to have_http_status(:success)
      result = JSON.parse response.body
      expect(result.count).to eq(0)
    end

    it '仅企业用户' do
      wechat_user.add_contact user

      get '/api/wechat/contacts', params: {token: wechat_user.token}

      expect(response).to have_http_status(:success)
      result = JSON.parse response.body
      expect(result.count).to eq(1)
      u = result[0]
      expect(u["key"]).to eq(instance.app_key)
      expect(u["company"]).to eq(instance.company)
      expect(u["id"]).to eq(user.instance_user_id)
      expect(u["name"]).to eq(user.name)
      expect(u["email"]).to eq(user.email)
    end
  end

  describe '获取会话列表' do
    let!(:instance)    { create :instance }
    let!(:wechat_user) { create :wechat_user }
    let!(:user)        { create :user, instance: instance }

    it '空' do
      get '/api/wechat/threads', params: {token: wechat_user.token}

      expect(response).to have_http_status(:success)
      result = JSON.parse response.body
      expect(result.count).to eq(0)
    end

    it '话题' do
      thread = create :wechat_thread, instance_key: instance.app_key
      thread.thread_users.create user: wechat_user
      thread.thread_users.create user: user

      get '/api/wechat/threads', params: {token: wechat_user.token}

      expect(response).to have_http_status(:success)
      result = JSON.parse response.body
      expect(result.count).to eq(1)
      t = result[0]
      expect(t["id"]).not_to be_nil
      expect(t["category"]).to eq("Thread")
      expect(t["subject"]).to eq(thread.subject)
      expect(t["members"].count).to eq(2)
    end

    it '私聊' do
      chat = wechat_user.get_chat instance.app_key, user.instance_user_id

      get '/api/wechat/threads', params: {token: wechat_user.token}

      expect(response).to have_http_status(:success)
      result = JSON.parse response.body
      expect(result.count).to eq(1)
      t = result[0]
      expect(t["id"]).not_to be_nil
      expect(t["category"]).to eq("Chat")
      expect(t["subject"]).to eq(user.name)
      expect(t["members"].count).to eq(2)
    end
  end

  describe "获取数据" do
    let!(:instance)    { create :instance }
    let!(:wechat_user) { create :wechat_user }
    let!(:thread)      { create :wechat_thread, instance_key: instance.app_key }
    let!(:user)        { create :user, instance: instance }
    let!(:message)     { create :wechat_message, thread: thread, user: user }

    before(:each) do
      wechat_user.add_contact user
      thread.add_member wechat_user
    end

    context '不带时间戳' do
      it "微信用户没有时间戳：取全部数据" do
        # 干扰数据
        create :wechat_message

        get '/api/wechat/data', params: {token: wechat_user.token}

        expect(response).to have_http_status(:success)
        result = JSON.parse response.body
        expect(result["users"].count).to eq(1)
        expect(result["threads"].count).to eq(1)
        expect(result["messages"].count).to eq(1)
      end

      it "微信用户有时间戳：无未读消息" do
        wechat_user.update time: (Time.now + 2).to_i

        get '/api/wechat/data', params: {token: wechat_user.token}

        expect(response).to have_http_status(:success)
        result = JSON.parse response.body
        expect(result["users"].count).to eq(1)
        expect(result["threads"].count).to eq(1)
        expect(result["messages"].count).to eq(0)
      end

      it "微信用户有时间戳：有未读消息" do
        wechat_user.update time: (Time.now + 2).to_i
        create :wechat_message, {thread: thread, user: user, created_at: (Time.now + 5)}

        get '/api/wechat/data', params: {token: wechat_user.token}

        expect(response).to have_http_status(:success)
        result = JSON.parse response.body
        expect(result["users"].count).to eq(1)
        expect(result["threads"].count).to eq(1)
        expect(result["messages"].count).to eq(1)
      end
    end

    context '带时间戳' do
      it "有未读消息" do
         # 干扰数据
        create :wechat_message
        # 时间戳之前的thread/message
        thread1 = create :wechat_thread, {instance_key: instance.app_key, updated_at: 10.minutes.ago}
        thread1.add_member wechat_user
        create :wechat_message, {thread: thread1, user: user, created_at: 10.minutes.ago}

        get '/api/wechat/data', params: {token: wechat_user.token, time: 5.minutes.ago.to_i}

        expect(response).to have_http_status(:success)
        result = JSON.parse response.body
        expect(result["users"].count).to eq(1)
        expect(result["threads"].count).to eq(1)
        expect(result["messages"].count).to eq(1)
      end
    end

  end
end
