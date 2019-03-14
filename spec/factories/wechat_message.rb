FactoryBot.define do
  factory :wechat_message do
    association :thread, factory: :wechat_thread, strategy: :build
    association :user, strategy: :build
    content { Faker::Lorem.paragraph }
  end
end
