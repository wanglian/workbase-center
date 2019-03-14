class App < Base

  helpers do
    def authenticate_with_key!
      @instance = Instance.find_by app_key: params[:key]
      error!('auth fail', 401) unless @instance
    end

    def current_instance
      @instance
    end
  end

  resource :app do
    desc "app获取用户私有云地址"
    params do
      requires :email, type: String, desc: "用户邮箱", documentation: { param_type: 'query' }
    end
    get 'instance' do
      user = User.find_by email: params[:email]
      user.instance.server_url
    end

    desc "app获取联系人二维码"
    params do
      requires :id,  type: String, desc: "用户标识", documentation: { param_type: 'query' }
      requires :key, type: String, desc: "实例标识", documentation: { param_type: 'query' }
    end
    before do
      authenticate_with_key!
    end
    get 'user_qrcode' do
      user = User.find_or_create_by instance_user_id: params[:id], instance: current_instance
      present :qrcode, user.get_qrcode
    end
  end
end