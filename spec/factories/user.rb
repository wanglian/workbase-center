FactoryBot.define do
  factory :user do
    instance_user_id { SecureRandom.hex }
    email            { Faker::Internet.email }
    association      :instance, strategy: :build
  end
end
