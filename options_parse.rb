#!/usr/bin/env ruby

############################################################################
# This script only parses the command line options or config/database.yml
############################################################################


SCRIPT_VERSION="0.91"

class OptparseOptions

  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.rails_root = (ENV["RAILS_ROOT"] || File.join(File.dirname(__FILE__), ".."))
    options.encoding = "utf8"
    options.rails_env = (ENV["RAILS_ENV"] || "development")
    options.database_yml = "./config/database.yml"
    options.bounce_checker_yml = "./config/bounce_checker.yml"
    options.verbose = false

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: ruby ./bounce_checker [options]"

      opts.separator ""
      opts.separator "Specific options:"

      # Rails root
      opts.on("--rails_root RAILS_ROOT", String, 
          "Optional Rails Root to run script, if not give, use current dir.") do |rr|
        options.rails_root = rr
      end
      
      # Optional argument with keyword completion.
      opts.on("--rails_env RAILS_ENV", ["development", "production"],
          "Optional RAILS_ENV (development, production) default=dev") do |re|
        options.rails_env = re
      end

      opts.on("--database_yml path", String, 
          "Optional location of database.yml") do |dbc|
        options.database_yml = dbc
      end
      
      opts.on("--bounce_checker_yml path", String, 
          "Optional location of bounce_checker.yml ") do |bcc|
        options.bounce_checker_yml = bcc
      end
      
      # Boolean switch.
      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options.verbose = v
      end
      
      opts.separator ""
      opts.separator "Common options:"

      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

      # Another typical switch to print the version.
      opts.on_tail("--version", "Show version") do
        puts SCRIPT_VERSION
        exit
      end
    end

    opts.parse!(args)
    options
  end  # parse()

end  # class OptparseOptions

options = OptparseOptions.parse(ARGV)

# Load custom variables for this script
RAILS_ROOT = options.rails_root
RAILS_ENV = options.rails_env.to_s
DB_CONFIG_FILE = options.database_yml
CUSTOM_CONFIG_FILE = options.bounce_checker_yml
SAMPLE_CONFIG_FILE = CUSTOM_CONFIG_FILE + ".sample"
VERBOSE = options.verbose


# This is database configuration
# read from ./config/database.yml
if File.exist? CUSTOM_CONFIG_FILE
  config = YAML.load_file(CUSTOM_CONFIG_FILE)
else
  config = YAML.load_file(SAMPLE_CONFIG_FILE)
end


REMOTE = (config["remote"] || false)
REMOTE_MAILDIR = (config["remote_maildir"] || "/home/deploy/.maildir")
DELETE_NOT_FOUND = (config["delete_not_found"] || false)
DELTA_TIME = (config["delta_time"] || 10)
OLDER_THAN = (config["older_than"] || 30)
REMOTE_SERVER = (config["remote_server"] || "myserver.com")
REMOTE_USER = (config["remote_user"] || "deploy")
RD = rand(99999999).to_s


# This is database configuration
# read from RAILS_ROOT/config/database.yml
if File.exist? DB_CONFIG_FILE
  config = YAML.load_file(DB_CONFIG_FILE)
  DATABASE = {
    :adapter => config[RAILS_ENV]["adapter"],
    :database => config[RAILS_ENV]["database"],
    :username => config[RAILS_ENV]["username"],
    :password => config[RAILS_ENV]["password"],
    :host => config[RAILS_ENV]["host"],
    :port => config[RAILS_ENV]["port"],
    :socket => config[RAILS_ENV]["socket"],
    # this is read from bounce_checker.yml
    :table => config["table"]
  }
else
  puts "The database.yml file was not found: #{DB_CONFIG_FILE}..."
  exit
end


if REMOTE == true
  MAILDIR = (config["maildir"] || "/tmp/maildir") + RD
else
  MAILDIR = REMOTE_MAILDIR
end

NEW_FOLDER = MAILDIR + "/new"
CUR_FOLDER = MAILDIR + "/cur"
REMOTE_NEW_FOLDER = REMOTE_MAILDIR + "/new"
REMOTE_CUR_FOLDER = REMOTE_MAILDIR + "/cur"

if VERBOSE
  LOG_FILE = $stdout
else
  LOG_FILE = (config["log_file"] || 'sequel.log')
end

DB_LOGGER = Logger.new(LOG_FILE)
  
# Setup Sequel:
if DATABASE[:socket]
  SEQUEL_CONFIG = {
    :database => DATABASE[:database], 
    :loggers => [DB_LOGGER],
    :username => DATABASE[:username],
    :password => DATABASE[:password], 
    :socket => DATABASE[:socket]
  }
else
  SEQUEL_CONFIG = {
    :database => DATABASE[:database], 
    :loggers => [DB_LOGGER],
    :username => DATABASE[:username],
    :password => DATABASE[:password], 
    :host => DATABASE[:host],
    :port => DATABASE[:port]
  }
end


if VERBOSE
  pp options
  pp SEQUEL_CONFIG
  pp DATABASE
  puts "RAILS_ROOT:", RAILS_ROOT
  puts "RAILS_ENV:", RAILS_ENV
  puts "DB_CONFIG_FILE:", DB_CONFIG_FILE
  puts "CUSTOM_CONFIG_FILE:", CUSTOM_CONFIG_FILE
  puts "VERBOSE:", VERBOSE
  puts "REMOTE:", REMOTE
  puts "DB_LOGGER:", DB_LOGGER
  puts "MAILDIR:", MAILDIR
  puts "NEW_FOLDER:", NEW_FOLDER
  puts "CUR_FOLDER:", CUR_FOLDER
  puts "DELETE_NOT_FOUND:", DELETE_NOT_FOUND
  puts "DELTA_TIME:", DELTA_TIME
  puts "OLDER_THAN:", OLDER_THAN
end

