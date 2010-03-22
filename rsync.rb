# This is the class that deals with syncing the messages from server.
# all rsync methods will go here only.
class Rsync
  
  # fetch new messages from server to a local tmp folder.
  def self.sync_new
    DB_LOGGER.info("Synchronizing New messages folder...")
    `rsync -av --quiet #{REMOTE_USER}@#{REMOTE_SERVER}:#{REMOTE_NEW_FOLDER}/ #{NEW_FOLDER}/`
  end
  
  # fetch the old messages from server to a local tmp folder.
  def self.sync_cur
    DB_LOGGER.info("Synchronizing Old messages folder...")
    `rsync -av --quiet #{REMOTE_USER}@#{REMOTE_SERVER}:#{REMOTE_CUR_FOLDER}/ #{CUR_FOLDER}/`
  end
  
  # Delete the fetched messages 
  def self.delete(folder = "new")
    if folder == "new"
      `rm -rf #{NEW_FOLDER}`
    elsif folder == "cur"
      `rm -rf #{CUR_FOLDER}`
    else
      puts "wrong argument."
    end
  end
  
end
