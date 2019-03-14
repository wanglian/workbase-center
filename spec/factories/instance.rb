FactoryBot.define do
  factory :instance do
    server_url { Faker::Internet.url }
    company    { Faker::Company.name }
    app_key    {SecureRandom.hex 8}
    app_secret {SecureRandom.hex 8}
  end
end
