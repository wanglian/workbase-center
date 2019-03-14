FactoryBot.define do
  factory :wechat_user do
    openid { SecureRandom.hex }
    name   { Faker::Name.name }
    icon   { Faker::Internet.url }
    token  { SecureRandom.hex }
  end
end
