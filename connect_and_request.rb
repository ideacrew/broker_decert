require 'bunny'

require_relative "./secrets"

# TODO: read in CSV
list = File.read("outstanding_list.txt")
ids = list.split("\n").map(&:strip)

connection = Bunny.new("amqp://#{AMQP_USER}:#{AMQP_PASSWORD}@#{AMQP_URI}")
connection.start

chan = connection.create_channel

chan.confirm_select

publish_exchange = chan.default_exchange

ids.each do |pol_id|
publish_exchange.publish(
  "",
  {
    :routing_key => "me0.pvt-2.q.enroll.policy_resource_listener",
    :reply_to => "whatever",
    :headers => {
      "policy_id" => pol_id
    }
  }
)
end

chan.wait_for_confirms

chan.close
