require 'crc'
require 'nokogiri'
require 'rubyserial'

# https://help.argusmonitor.com/CommunicationProtocol.html

SLEEP_DURATION = 100 / 1000 # 100ms

COMMAND_PROBE_DEVICE = [0xAA, 0x02, 0x01, 0x53]
COMMAND_GET_TEMP     = [0xAA, 0x02, 0x20, 0x2E]
COMMAND_GET_FAN_RPM  = [0xAA, 0x02, 0x30, 0xB3]

buffer = []

@serial = Serial.new('/dev/ttyS5', 57600)

def send(bytes)
  out = [0xC5, bytes.length + 1] + bytes
  crc8 = CRC.crc8_maxim(out.pack('c*'))
  out << crc8
  @serial.write(out.pack('c*'))
end

# TODO what is the query frequency and does nvidia-smi return fast enough?
loop do
  next_byte = @serial.getbyte
  buffer = [] if buffer.length > 10
  if next_byte.nil?
    sleep(SLEEP_DURATION)
  elsif next_byte == 0xAA
    # command start; reset buffer
    buffer = [0xAA]
  else
    buffer << next_byte
    # puts "b: #{buffer.map { |b| b.to_s(16).rjust(2, '0') }}"
    if buffer == COMMAND_PROBE_DEVICE
      device_id = 0x01
      temp_count = `nvidia-smi.exe -L | wc -l`.to_i
      fan_count = 0x00
      send([0x01, device_id, temp_count, fan_count])
      puts "Device probed: #{temp_count}"
    elsif buffer == COMMAND_GET_TEMP
      xml = Nokogiri::XML(`nvidia-smi.exe -q -x`)
      temperatures = xml.xpath('//gpu/temperature/gpu_temp').map(&:content).map(&:to_i)
      temperatures_scaled = temperatures.map { |t| t * 10 }
      temperature_bytes = temperatures_scaled.flat_map { |t| [t >> 8, t & 0xFF] }
      send([0x20, temperatures.length] + temperature_bytes)
    elsif buffer == COMMAND_GET_FAN_RPM
      send([0x30, 0x00]) # no fans
    end
  end
end
