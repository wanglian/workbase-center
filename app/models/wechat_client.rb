class WechatClient
  WECHAT_AUTH_URL  = "https://api.weixin.qq.com/sns/jscode2session"
  WECHAT_TOKEN_URL = "https://api.weixin.qq.com/cgi-bin/token"
  WECHAT_QR_URL    = "https://api.weixin.qq.com/wxa/getwxacodeunlimit"
  WECHAT_APPID     = Settings.wechat.mini_appid
  WECHAT_SECRET    = Settings.wechat.mini_secret

  def self.auth(code)
    url = auth_url code
    logger.debug url
    response = JSON.parse RestClient.get(url).body
    logger.debug response
    response["openid"]
  end

  def self.get_token
    url = token_url
    response = JSON.parse RestClient.get(url).body
    logger.debug response
    response["access_token"]
  end

  def self.get_qrcode(page, params)
    url = qrcode_url get_token
    response = RestClient.post url, {
      page: page,
      scene: params,
      is_hyaline: true
    }.to_json

    # 错误返回json格式，正常返回二进制
    begin
      JSON.parse response.body
      logger.debug response
    rescue Exception => e
      return Base64.encode64(response.body)
    end
    false
  end

  def self.auth_url(code)
    generate_url WECHAT_AUTH_URL, {
      appid: WECHAT_APPID,
      secret: WECHAT_SECRET,
      js_code: code,
      grant_type: "authorization_code"
    }
  end

  def self.token_url
    generate_url WECHAT_TOKEN_URL, {
      appid: WECHAT_APPID,
      secret: WECHAT_SECRET,
      grant_type: 'client_credential'
    }
  end

  def self.qrcode_url(token)
    generate_url WECHAT_QR_URL, {
      access_token: token
    }
  end

  private
  def self.generate_url(base_url, params)
    params_string = params.map {|k, v|
      [k, v].join("=")
    }.join("&")
    [base_url, params_string].join("?")
  end

  def self.logger
    @@logger ||= Logger.new 'log/wechat.log'
  end
end
