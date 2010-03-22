class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      # Required Fields for normal email hangling
      t.string    :message_id
      t.string    :header_reply_to
      t.string    :header_recipient
      t.string    :header_from
      t.string    :header_subject
      t.string    :header_x_mailer, :default => "tmail"
      t.text      :body
      # This is for bouncing checking
      t.boolean   :email_bounced,           :default => false
      t.string    :bounced_action,          :limit => 20
      t.string    :bounced_status,          :limit => 20
      t.string    :bounced_remote_mta,      :limit => 80
      t.string    :bounced_diagnostic_code, :limit => 120
      # Dates
      t.datetime  :bounced_check_date
      t.datetime  :sent_date
      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
