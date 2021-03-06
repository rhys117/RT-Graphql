class RT::User < RequestTrackerRecord
  has_many :tickets, class_name: 'Ticket', foreign_key: 'owner'
  has_many :reminders, class_name: 'Reminder', foreign_key: 'owner'
  has_many :group_members, class_name: 'GroupMember', foreign_key: :memberid
  has_many :groups, class_name: 'Group', through: :group_members

  alias_attribute :email, :emailaddress
  alias_attribute :real_name, :realname
  alias_attribute :organisation, :organization

  # Todo: Figure out if way to check passwords that have been processed with perl bcrypt.
  def authenticate(password:)
    if self.password[0..7] == '!bcrypt!'
      path = "#{Rails.root}/tmp/rt_cookies/#{id}/cookie"
      dirname = File.dirname(path)
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

      client = RT_Client.new(server: ENV.fetch('RT_HOST'),
                             user: name,
                             pass: password,
                             cookies: dirname)

      correct = !client.show(1).empty?
      FileUtils.rm_rf(dirname)
      correct
    else
      (Digest::MD5.hexdigest password) == self.password
    end
  end

  def tickets_not_resolved
    tickets.where.not(status: CLOSED_STATUSES)
  end

  def tickets_missing_reminder
    tickets_not_resolved.select { |ticket| ticket.no_reminder? }
  end

  private

  def password_digest
    self.password[8..-1]
  end
end