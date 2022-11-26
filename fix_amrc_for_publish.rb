require "nokogiri"

require "fileutils"

XMLNS = {
  etf: "urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance"
}

FileUtils.mkdir_p("./out_files")
FileUtils.rm_f(Dir.glob("./out_files/*.xml"))

Dir.glob("./encoded_files/*.xml").each do |f_path|
  data = File.read(f_path)
  out_name = File.basename(f_path)
  doc = Nokogiri::XML(data) do |config|
    config.default_xml.noblanks
  end
  doc.xpath("//etf:Loop_2750[contains(etf:N1_ReportingCategory_2750/etf:N102__MemberReportingCategoryName,'ADDL MAINT REASON')]/etf:REF_ReportingCategoryReference_2750/etf:REF02__MemberReportingCategoryReferenceID", XMLNS).each do |node|
    node.content = "AGENT BROKER INFO"
  end
  File.open("./out_files/#{out_name}", "wb") do |f|
    f.write doc.to_xml(indent: 2)
  end
end
