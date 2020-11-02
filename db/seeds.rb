puts '=== Seeding starting ==='

User.where(email: 'admin@leikir.io').destroy_all
User.create!(email: 'admin@leikir.io', password: 'password')

puts '=== Seeding ended ==='
