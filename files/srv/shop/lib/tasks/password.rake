namespace :workarea do
  namespace :admin do
    desc 'Generate a secure admin password'
    task password: :environment do
      password = SecureRandom.base64

      Workarea::User.admins.each { |admin| admin.update!(password: password) }

      puts "Log into /admin with email 'user@workarea.com' and password '#{password}'"
    end
  end
end
