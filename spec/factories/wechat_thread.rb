FactoryBot.define do
  factory :wechat_thread do
    instance_key       { SecureRandom.hex }
    instance_thread_id { SecureRandom.hex }
    category           'Thread'
    subject            { Faker::Lorem.sentence }
  end
end
