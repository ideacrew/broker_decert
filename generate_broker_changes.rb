require "nokogiri"

require "csv"

require "fileutils"

XMLNS = {
  "cv" => "http://openhbx.org/api/terms/1.0"
}

FileUtils.mkdir_p("./cv2")
FileUtils.rm_f(Dir.glob("./cv2/*.xml"))

# TODO: write reading code for enriched CSV from GlueDB

policy_lookups = {}

CSV.foreach("gluedb_extract_results.csv", headers: true) do |row|
  hbx_enrollment_id = row['hbx_enrollment_id']
  if policy_lookups.has_key?(hbx_enrollment_id)
    policy_lookups[hbx_enrollment_id][:members][row["member_id"]] = row["start_date"]
  else
    policy_lookups[hbx_enrollment_id] = {
      :eg_id => row["policy_eg_id"],
      :members => {
        row["member_id"] => row["start_date"]
      },
      :status => row["outcome"]
    }
  end
end

# Five steps here:
# 1. Replace policy ID
# 2. Remove all coverage end dates
# 3. Change event type to personnel update
# 4. Remove broker nodes (if any)
# 5. Change start dates to match policy
CSV.open("cv_encoding_results.csv", "wb") do |csv|
  csv << ["hbx_enrollment_id", "outcome"]
  Dir.glob("./enroll_cv2/*.xml").each do |f_path|
    base_id = File.basename(f_path, ".xml")
    data = File.read(f_path)
    if data == "" || data.nil?
      csv <<  [base_id, "Enrollment Payload was empty"]
      next
    end
    doc = Nokogiri::XML(data) do |config|
      config.default_xml.noblanks
    end
    policy_node = doc.xpath("//cv:policy/cv:id/cv:id", XMLNS).first
    hbx_enrollment_id = policy_node.content
    policy_id_entry = policy_lookups[hbx_enrollment_id]
    if policy_id_entry.nil?
      csv << [hbx_enrollment_id, "No policy found in CSV"]
      next
    end
    if policy_id_entry[:status] != "OK - BROKER REMOVED"
      csv << [hbx_enrollment_id, "Enrollment failed to remove broker from gluedb, reason: #{policy_id_entry[:status]}"]
      next
    end
    policy_id = policy_id_entry[:eg_id]
    policy_node.content = policy_id
    broker_nodes = doc.xpath("//cv:policy/cv:broker", XMLNS)
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
    doc.xpath("//cv:affected_member", XMLNS).each do |node|
      member_id_node = node.at_xpath(".//cv:member/cv:id/cv:id", XMLNS)
      member_id = node.content.split("#").last
      start_date_node = node.at_xpath(".//cv:benefit/cv:begin_date", XMLNS)
      start_date_node.content = policy_lookups[hbx_enrollment_id][:members][member_id]
    end
    doc.xpath("//cv:enrollees/cv:enrollee", XMLNS).each do |member_node|
      member_id_node = member_node.at_xpath(".//cv:member/cv:id/cv:id", XMLNS)
      member_id = member_id_node.content.split("#").last
      start_date_node = member_node.at_xpath("//cv:benefit/cv:begin_date", XMLNS)
      start_date_node.content = policy_lookups[hbx_enrollment_id][:members][member_id]
    end
    File.open("./cv2/#{hbx_enrollment_id}.xml", "wb") do |f|
      f.write doc.to_xml(indent: 2)
    end
    csv << [hbx_enrollment_id, "OK"]
  end
end