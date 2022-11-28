require 'bunny'
require 'fileutils'

require_relative "./secrets"

connection = Bunny.new("amqp://#{AMQP_USER}:#{AMQP_PASSWORD}@#{AMQP_URI}")
connection.start

FileUtils.rm_f(Dir.glob("./enroll_cv2/*.xml"))
FileUtils.mkdir_p("./enroll_cv2")

chan = connection.create_channel
chan.prefetch(1)

queue = chan.queue("whatever", {durable: true})

di, props, payload = queue.pop(manual_ack: true)
while di
  policy_id = props.headers["policy_id"]
  File.open("enroll_cv2/#{policy_id}.xml", "w") do |f|
    f.write payload
  end
  chan.ack(di.delivery_tag, false)
  di, props, payload = queue.pop(manual_ack: true)
end

chan.close
