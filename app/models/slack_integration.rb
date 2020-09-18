class SlackIntegration < ApplicationRecord

  validates :channel, length: { minimum: 2 }
  validates :webhook_url, length: { minimum: 10 }
  validate :starts_with_hash
  after_destroy :remove_subscriptions

  def starts_with_hash
    if channel.to_s.split('').first != '#'
      errors.add(:channel, "must begin with #")
    end
  end

  include Rails.application.routes.url_helpers

  def subscriptions
    Subscription.where(watcher: self)
  end

  def watching
    subscriptions.map(&:watching)
  end

  def subscribe(watchable)
    # TODO: extract this. also in User
    Subscription.where(watcher: self, watching: watchable).first_or_create do |subscription|
      puts "#{self} subscribed to #{watchable}"
    end
  end

  def is_subscribed_to?(watchable)
    Subscription.where(watcher: self, watching: watchable).exists?
  end

  def send_notification(change)
    puts "slack_integration#send_notification #{self.channel}"

    page_url = change&.after&.page&.url
    page_domain = change&.after&.page&.domain.truncate(40)
    message = "VASP Website Monitoring: #{page_domain}"
    text = "#{page_url} changed!\nSee latest changes here: #{page_change_url(change)}"

    icon_url = URI.join(root_url, '/images/klaxon-logo-100px.png').to_s

    payload =  {
	    "message": message,
	    "description": text,
	    "responders": [
	        {"name": "PU_Security_RF_escalation", "type": "escalation"},
	    ],
	}   

    SlackNotification.perform(self.webhook_url, payload)
    return payload
  end

  def remove_subscriptions
    subscriptions.each do |s|
      s.destroy
    end
  end
end
