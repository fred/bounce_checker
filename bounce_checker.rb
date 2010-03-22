#!/usr/bin/env ruby

############################################################################
# Writen by Frederico de Souza Araujo
# fred.the.master@gmail.com
############################################################################

require 'rubygems'
require 'fileutils'
require 'sequel'
require 'logger'
require 'ftools'
require 'pathname'
require 'logger'
require 'yaml'
require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'


RUN_TIME = Time.now

require 'options_parse'
require 'maildir'
require 'email'
require 'rsync'


# check if the folders are there
# if not create them, 
# you must write access to the specified folders.
def check_folders
  DB_LOGGER.info("Check folders...")
  unless File.exist? NEW_FOLDER
    FileUtils.mkdir_p NEW_FOLDER
  end
  unless File.exist? CUR_FOLDER
    FileUtils.mkdir_p CUR_FOLDER
  end
  DB_LOGGER.info("Folders checked, Ok...")
end


# Create temp files for new messages
if REMOTE == true
  check_folders
  Rsync.sync_new
end

if VERBOSE
  DB_LOGGER.info("="*46)
  DB_LOGGER.info("Starting at: #{RUN_TIME}")
  DB_LOGGER.info("There are #{Maildir.list_new_messages.size} new messages since last check...\n")
  DB_LOGGER.info("There are #{Maildir.list_cur_messages.size} old messages since last check...\n")
  DB_LOGGER.info("Starting Database update")
end
# Run main script now
Email.check_new_emails

# Delete temp files from new folder
if REMOTE == true
  Rsync.delete("new")
  Rsync.delete("cur")
end
