require 'csv'

list = File.read("removed_broker_enrollment_id_list.txt")
ids = list.split("\n").map(&:strip)

CSV.open("gluedb_extract_results.csv", "wb") do |csv|
  csv << ["hbx_enrollment_id", "policy_eg_id", "member_id", "start_date", "outcome"]

  ids.each do |enrollment_id|
    policy = Policy.where("hbx_enrollment_ids" => enrollment_id).first
    if policy
      if policy.terminated?
        csv << [enrollment_id, policy.eg_id, "N/A", "N/A", "POLICY TERMINATED"]
      elsif policy.broker_id.blank?
        csv << [enrollment_id, policy.eg_id, "N/A", "N/A", "NO BROKER ON POLICY"]
      else
        people_ids_and_dates = {}
        policy.enrollees.each do |en|
          if !en.terminated?
            people_ids_and_dates[en.m_id] = en.coverage_start
          end
        end
        # policy.broker_id = nil
        policy.save!
        people_ids_and_dates.each_pair do |k,v|
          csv << [enrollment_id, policy.eg_id, k, v.strftime("%Y%m%d"), "OK - BROKER REMOVED"]
        end
      end
    else
      csv << [enrollment_id, "NOT FOUND", "N/A", "N/A", "POLICY NOT FOUND"]
    end
  end
end