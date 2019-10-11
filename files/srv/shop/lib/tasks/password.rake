namespace :workarea do
  namespace :admin do
    desc 'Generate a secure admin password'
    task password: :environment do
      password = SecureRandom.base64

      User.admins.each { |admin| admin.update!(password: password) }

      puts password
    end
  end
end
