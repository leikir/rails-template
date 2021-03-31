puts '=== Seeding starting ==='

# User
User.where(email: 'admin@leikir.io').destroy_all
User.create!(email: 'admin@leikir.io', password: 'password')


# BACK OFFICE ADMIN
AdminUser.create!(
  email: 'admin@leikir.io',
  password: 'password',
  password_confirmation: 'password'
)


puts '=== Seeding ended ==='
