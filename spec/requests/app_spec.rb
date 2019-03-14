require 'rails_helper'

RSpec.describe "APP", :type => :request do

  let!(:instance) { create :instance }
  let!(:user)     { create :user, instance: instance }

  describe 'APP接口' do

    context '获取联系人二维码' do

      it 'success' do
        params = {
          id:  user.instance_user_id,
          key: instance.app_key
        }
        token = 'test'
        token_url = WechatClient.token_url
        stub_request(:get, token_url).to_return(status: 200, body: {access_token: token}.to_json)
        qrcode_url = WechatClient.qrcode_url token
        stub_request(:post, qrcode_url).to_return(status: 200, body: 'qrcode')

        get '/api/app/user_qrcode', params: params
        expect(response.status).to eql 200
        user.reload
        expect(user.qrcode).not_to eql nil
      end

      it 'auth fail' do
        params = {
          id:  user.instance_user_id,
          key: 'wrong'
        }
        get '/api/app/user_qrcode', params: params
        expect(response.status).to eql 401
      end
    end
  end
end