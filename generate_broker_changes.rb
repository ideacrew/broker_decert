require "nokogiri"

require "csv"

require "fileutils"

XMLNS = {
  "cv" => "http://openhbx.org/api/terms/1.0"
}

FileUtils.mkdir_p("./cv2")
FileUtils.rm_f(Dir.glob("./cv2/*.xml"))

# TODO: write reading code for enriched XML from GlueDB
policy_crossmap = {}

# Five steps here:
# 1. Replace policy ID
# 2. Remove all coverage end dates
# 3. Change event type to personnel update
# 4. Remove broker nodes (if any)
# 5. Change start dates to match policy
Dir.glob("./enroll_cv2/*.xml").each do |f_path|
  puts f_path
  data = File.read(f_path)
  doc = Nokogiri::XML(data) do |config|
    config.default_xml.noblanks
  end
  base_id = File.basename(f_path, ".xml")
  policy_node = doc.xpath("//cv:policy/cv:id/cv:id", XMLNS).first
  hbx_enrollment_id = policy_node.content.strip.split("#").last
  policy_id = policy_crossmap[hbx_enrollment_id]
  policy_node.content = policy_id
    broker_nodes = doc.xpath("//cv:policy/cv:broker", XMLNS).any?
    broker_nodes.each do |bn|
      bn.remove
    end
    doc.xpath("//cv:enrollment/cv:type", XMLNS).each do |node|
      node.content = "urn:openhbx:terms:v1:enrollment#change_member_communication_numbers"
    end
    doc.xpath("//cv:benefit/cv:end_date", XMLNS).each do |node|
      node.remove
    end
    doc.xpath("//cv:affected_member[contains(cv:is_subscriber, 'false')]", XMLNS).each do |node|
      node.remove
    end
    File.open("./cv2/#{hbx_enrollment_id}.xml", "wb") do |f|
      f.write doc.to_xml(indent: 2)
    end
  end
end
