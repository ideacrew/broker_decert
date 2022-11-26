require "nokogiri"

require "csv"

require "fileutils"
require "edi_codec"

EdiCodec::Configuration.source_exchange = "ME0"
EdiCodec::Configuration.exchange_fein = "016000001"

FileUtils.mkdir_p("./encoded_files")
FileUtils.rm_f(Dir.glob("./encoded_files/*.xml"))

Dir.glob("./cv2/*.xml").each do |f_path|
  data = File.read(f_path)
  edi_builder = EdiCodec::X12::BenefitEnrollment.new(data)
  x12_xml = edi_builder.call.to_xml
  f_name = File.basename(f_path)
  File.open("./encoded_files/#{f_name}", "wb") do |f|
    f.write x12_xml
  end
end
