# This is the virtual maldir class
class Maildir
  attr_accessor :is_new, :is_old, :full_pathname, :file_name, 
    :message_id, :bounced_action, :email_bounced, :bounced_status, 
    :bounced_remote_mta, :bounced_diagnostic_code
    
  # the below 3 methods require gnu find, only found on Linux
  # a workaround for OSX and BSD:
  # -----------------------------------
  # # Get current time_stamp
  # ts=`date +%m%d%H%M`;export ts
  # ts=`expr $ts - 100`
  # # Create file with time_stamp
  # touch -t 0$ts check_flag
  # # Check for newer files than flag
  # find . -newer check_flag
  # # Remove time_stamp
  # rm check_flag
  # --------------------------------------------

  # check new messages that are newer than minutes
  # default is 1 days if minutes is not specified  
  def self.list_new_messages(minutes=1440)
    minutes += DELTA_TIME.to_i
    Dir.chdir "#{NEW_FOLDER}"
    list = `find ./ -type f -mmin -#{minutes}`
    list = list.split
    list
  end
  
  # check current messages that are newer than minutes
  # default is 1 days if minutes is not specified
  def self.list_cur_messages(minutes=1440)
    minutes += DELTA_TIME.to_i
    Dir.chdir "#{CUR_FOLDER}"
    list = `find ./ -type f -mmin -#{minutes}`
    list = list.split
    list
    # old style:
    #Dir.entries(CUR_FOLDER).reject {|f| File.directory? f}
  end
  
  # check if the file is a valid rfc822 message file
  # using the unix command "file"
  def valid_maildir_file
    mime_type = `file --raw --brief "#{self.full_pathname}"`.chomp
    p1 = Pathname.new(self.full_pathname)
    if (p1.ftype == "file" && p1.readable?) && ( mime_type.match("message|rfc822") )
      return mime_type.gsub("\t"," ")
    else
      false
    end
  end
  
  def valid?
    if self.valid_maildir_file
      true
    else
      false
    end
  end
  
  # check is it's new email, by looking at the folder location
  def is_new_mail?
    if Pathname.new(self.full_pathname).parent.to_s.match("\/new$")
      true
    else
      false
    end
  end
  
  # check is it's old email, by looking at the folder location
  def is_old_mail?
    if Pathname.new(self.full_pathname).parent.to_s.match("\/cur$")
      true
    else
      false
    end
  end
  
  # mark the email as read, by moving it to the 'cur' folder
  # also append :2:S to the end of filename 
  #   to conform with postfix standards
  def set_read
    if self.is_new_mail?
      File.mv("#{NEW_FOLDER}/#{self.file_name}", "#{CUR_FOLDER}/#{self.file_name}:2,S")
    end
  end
  
  # Bounced Diagnostic-Code: 
  # diagnostic code created by postfix.
  # Example: 
  # mail.bounced_diagnostic_code
  # > smtp; 550 sorry, mail to that recipient is not accepted (#5.7.1):
  def parse_diagnostic_code
    result = `grep -A1 "Diagnostic-Code" #{self.full_pathname}`.split("\n")
    a1 = result[0].to_s.gsub("Diagnostic-Code: smtp;","")
    a2 = result[1].to_s.lstrip
    bounced_diagnostic_code = a1 + a2
    return bounced_diagnostic_code
  end
  
  # Bounced Action:
  # what happened to the email, 
  # can be Failed, Delayed, Error, etc...
  def parse_bounced_action
    return `grep Action #{self.full_pathname} | cut -c 9-`.split("\n")[0]
  end

  # Bounced Status:
  # error status, ex: 550, 554, etc...
  def parse_bounced_status
    return `grep Status #{self.full_pathname} | cut -c 9-`.split("\n")[0]
  end

  # Bounced Remote-MTA:
  # there might be 1 or more lines, get the first one, 
  # which is the destination remote-mta for the original email
  def parse_bounced_remote_mta
    return `grep "Remote-MTA" #{self.full_pathname} | cut -c 18-`.split("\n")[0]
  end
  
  # Bounced Message-Id:
  # there will be 2 lines with Message-Id
  # we will get the second matching message-id,
  # which is the message-id of the original bounced email.
  def parse_message_id
    return `grep "Message-Id" #{self.full_pathname}`.split("\n")[1].to_s.gsub("Message-Id: ","")
  end
  
  # parse the message file and build a maildir object
  def self.build_maildir(filename,s)
    mail = Maildir.new
    mail.file_name = filename
    if s == "new"
      mail.full_pathname = "#{NEW_FOLDER}/#{filename}"
    elsif s == "old"
      mail.full_pathname = "#{CUR_FOLDER}/#{filename}"
    else
      return false
    end
    
    if mail.valid?
      mail.is_new = mail.is_new_mail?
      mail.is_old = mail.is_old_mail?
      mail.message_id = mail.parse_message_id
      mail.bounced_action = mail.parse_bounced_action
      mail.email_bounced = true
      mail.bounced_status = mail.parse_bounced_status
      mail.bounced_remote_mta = mail.parse_bounced_remote_mta
      mail.bounced_diagnostic_code = mail.parse_diagnostic_code
      return mail
    else
      return false
    end
  end
  
  # returns array of all messages, either new or old.
  def self.find_all(status = nil, date = nil)
    minutes = RUN_TIME - date
    minutes = (minutes/60).to_i
    DB_LOGGER.info("Looking for email files newer than: #{minutes} minutes")
    all = []
    if status == "new"
      s = "new"
      maildirs_list = Maildir.list_new_messages(minutes)
    end
    if status.match("old|cur")
      s = "old"
      maildirs_list = Maildir.list_cur_messages(minutes)
    end
    maildirs_list.each do |t|
      # build the maildir
      mail = Maildir.build_maildir(t,s)
      # it's a valid email file, add it to array
      if mail
        all << mail
      end
    end
    all
  end
  
end