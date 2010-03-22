# This Class replicates the Message class withing our rails app.
class Email  
  # to replicate what we have in our ului rails database
  attr_accessor :email_bounced, :bounced_action, :bounced_status, 
  :bounced_remote_mta, :message_id, :bounced_diagnostic_code
  
  # Stablish Database Connection (Mysql)
  DB = Sequel.mysql(SEQUEL_CONFIG)
  
  # returns the last time the bounce script was run
  # it checks the database for the last message marked as bounced.
  # can use filter('bounced_check_date > ?', RUN_TIME) to check
  def self.latest_check
    last_date = DB[(DATABASE[:table]).to_sym].
      select(:bounced_check_date).
      reverse_order(:bounced_check_date).
      first
    if last_date && (last_date.kind_of? Hash)
      # it is already an object type of Time 
      return last_date[:bounced_check_date]
    else
      return nil
    end
  end
  
  # Find email in the database that match message_id
  def self.find_by_message_id(message_id)
    # find a match in the database and limit it to 1.
    # <Sequel::MySQL::Dataset: "SELECT * FROM `messages` WHERE (`message_id` = '<...>') LIMIT 1">
    DB[(DATABASE[:table]).to_sym].filter(:message_id => message_id)
  end
  
  # Count emails in the database that match message_id
  def self.count(message_id)
    DB[(DATABASE[:table]).to_sym].filter(:message_id => message_id).count
  end
  
  # not used yet.
  def build_email(maildir)
    self.email_bounced = maildir.email_bounced
    self.bounced_action = maildir.bounced_action
    self.bounced_status = maildir.bounced_status
    self.bounced_remote_mta = maildir.bounced_remote_mta
    self.message_id = maildir.message_id
    self.bounced_diagnostic_code = maildir.bounced_diagnostic_code
    self.bouced_check_time = RUN_TIME
  end
  
  # look in the database for a match then save it
  def self.sync_bounced_email(maildir) 
    result = 0
    
    # look for a match, by issuing a count(*) statement
    count = Email.count(maildir.message_id)
    
    # if found it, the case where count(*) > 0, update the database
    if count > 0
      email =  Email.find_by_message_id(maildir.message_id)
      result = email.update(:email_bounced => maildir.email_bounced,
        :bounced_action => maildir.bounced_action,
        :bounced_status => maildir.bounced_status,
        :bounced_remote_mta => maildir.bounced_remote_mta,
        :bounced_diagnostic_code => maildir.bounced_diagnostic_code,
        :bounced_check_date => RUN_TIME
      )
    end
    
    if result > 0
      DB_LOGGER.info("#{result} emails with Message-Id: #{maildir.message_id} were updated in database.")
    else
      DB_LOGGER.info("no email found with Message-Id: #{maildir.message_id}")
    end
    # return the number of emails saved
    return result
  end
  
  # search for new emails 
  def self.check_new_emails
    total = 0
    not_moved = 0
    latest_check = Email.latest_check
    DB_LOGGER.info("Last email match was found at: #{latest_check}")
    
    new_emails = Maildir.find_all("new", latest_check)
    new_emails.each do |t|
      # returns the number of recorded bounced emails
      result = Email.sync_bounced_email(t)
      total = total+result.to_i
      # mark the email as read, by moving to current folder
      if (result > 0) || (DELETE_NOT_FOUND)
        # mark email as read only if match 
        #  or if set in config to delete not found emails
        t.set_read
      else
        not_moved += 1
      end
    end
    DB_LOGGER.info("#{total} emails were updated and cleared out.")
    DB_LOGGER.info("#{not_moved} emails were kept in the new folder.")
    puts "[#{total},#{not_moved}]"
  end
  
end