GrapeSwaggerRails.options.url      = 'api/swagger_doc'
GrapeSwaggerRails.options.app_url  = '/'
GrapeSwaggerRails.options.app_name = 'Center'
GrapeSwaggerRails.options.doc_expansion = 'full'
GrapeSwaggerRails.options.before_action do |request|
  authenticate_or_request_with_http_basic do |user_name, password|
    user_name == Settings.apidoc.user_name && password == Settings.apidoc.user_pass
  end
end
