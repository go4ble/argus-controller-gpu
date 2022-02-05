require 'nokogiri'

xml = `nvidia-smi.exe -q -x`

doc = Nokogiri::XML(xml)

product_names = doc.xpath('//gpu/product_name').map(&:content)
# => ["NVIDIA GeForce GTX 1060 6GB", "Tesla M40"]

fan_speeds = doc.xpath('//gpu/fan_speed').map(&:content)
# => ["0 %", "N/A"]

temperatures = doc.xpath('//gpu/temperature/gpu_temp').map(&:content)
# => ["40 C", "32 C"]

buffer = [0xAA, 0x02, 0x01, 0x53]
buffer.map { |b| b.to_s(16).rjust(2, '0') }
# => ["aa", "02", "01", "53"]
