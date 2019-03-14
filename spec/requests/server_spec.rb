require 'rails_helper'

RSpec.describe "Server接口", :type => :request do
  let!(:instance)    { create :instance }
  let!(:user)        { create :user, instance: instance }
  let!(:wechat_user) { create :wechat_user }
  let!(:thread)      { create :wechat_thread, instance_key: instance.app_key }

  describe '接受server推送' do
    let(:cur_time) { Time.now.to_i }
    let(:headers) { {'Appkey' => instance.app_key, 'Curtime' => cur_time, 'Checksum' => Digest::SHA1.hexdigest("#{instance.app_secret}#{instance.app_key}#{cur_time}")} }

    context '消息' do
      it '认证失败' do
        params = {}
        post '/api/servers/message', headers: headers.merge({"Appkey" => "test"}), params: params
        expect(response.status).to eql 401
      end

      it '私聊消息' do
        params = {
          category: 'Chat',
          user_id:  user.instance_user_id,
          openid:   wechat_user.openid,
          content: 'test',
          type:    'text'
        }

        post '/api/servers/message', headers: headers, params: params

        expect(response).to have_http_status(:success)
        res = JSON.parse(response.body)
        expect(res["user_type"]).to eql 'user'
        expect(res["user_id"]).to eql user.instance_user_id
        expect(res["content"]).to eql params[:content]

      end

      it '话题消息' do
        params = {
          category:  'Group',
          user_id:   user.instance_user_id,
          thread_id: thread.instance_thread_id,
          content:   'group_test',
          type:      'text'
        }

        post '/api/servers/message', headers: headers, params: params

        expect(response).to have_http_status(:success)
        res = JSON.parse(response.body)
        expect(res["user_type"]).to eql 'user'
        expect(res["user_id"]).to eql user.instance_user_id
        expect(res["content"]).to eql params[:content]
      end
    end

    context '用户信息' do
      it 'success update card' do
        params = {
          id:     user.instance_user_id,
          name:   'test123',
          title:  'developer',
          mobile: '131313'
        }

        post '/api/servers/user', headers: headers, params: params

        expect(response).to have_http_status(:success)
        res = JSON.parse(response.body)
        expect(res["user_id"]).to eql user.instance_user_id
        expect(res["card"]["name"]).to eql params[:name]
        expect(res["card"]["title"]).to eql params[:title]
        expect(res["card"]["mobile"]).to eql params[:mobile]
      end

      it 'no user' do
        params = {
          id:     '1',
          email:  'test123@net263.com',
          name:   'test123',
          title:  'developer',
          mobile: '131313'
        }

        post '/api/servers/user', headers: headers, params: params

        expect(response).to have_http_status(:success)
        res = JSON.parse(response.body)
        expect(res["user_id"]).to eql params[:id]
      end
    end

    context '话题主题' do
      it 'success update subject' do
        params = {
          id:      thread.instance_thread_id,
          subject: '更新话题'
        }

        post '/api/servers/thread', headers: headers, params: params

        expect(response).to have_http_status(:success)
        res = JSON.parse(response.body)
        expect(res["id"]).to eql thread.instance_thread_id
        expect(res["subject"]).to eql params[:subject]
      end

      it 'error no thread' do
        params = {
          id:      '12',
          subject: '更新话题'
        }

        post '/api/servers/thread', headers: headers, params: params

        expect(response.status).to eql 404
      end
    end
  end
end